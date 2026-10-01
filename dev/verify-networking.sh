#!/usr/bin/env bash
set -euo pipefail
family=${1:?usage: verify-networking.sh ipv4|ipv6}
case ${family} in
  ipv4) service_api=https://10.96.0.1:443/version; pod_cidr=10.244.0.0/16; routing='Network: Tunnel [vxlan]   Host: BPF' ;;
  ipv6) service_api=https://[fc00::1]:443/version; pod_cidr=fc00:1::/96; routing='Network: Native   Host: BPF' ;;
  *) echo "unsupported address family: ${family}" >&2; exit 2 ;;
esac
kubeconfig=${KUBECONFIG:-../kube-config-${family}}
talosconfig=${TALOSCONFIG:-../talos-config-${family}}
probe_namespace=direct-routing-smoke
probe_pod=worker-network-probe
export KUBECONFIG=${kubeconfig}
export TALOSCONFIG=${talosconfig}
readiness_timeout=${NETWORK_READY_TIMEOUT:-900}
if [[ ! ${readiness_timeout} =~ ^[0-9]+$ ]] || (( readiness_timeout < 900 )); then
  echo "NETWORK_READY_TIMEOUT must be at least 900 seconds" >&2
  exit 2
fi
observe_endpoints() {
  kubectl --request-timeout=10s -n kube-system get pods -l k8s-app=cilium \
    -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,PHASE:.status.phase >&2 || true
  kubectl --request-timeout=10s get ciliumendpoints -A -o json | \
    jq -c '[.items[].status.state // "unknown"] | group_by(.) | map({state: .[0], count: length})' >&2 || true
}
wait_for_network() {
  local readiness_deadline=$((SECONDS + readiness_timeout))
  local next_observation=${SECONDS}
  until "$@"; do
    if (( SECONDS >= next_observation )); then
      echo "$(date -u +%FT%TZ) Waiting for: $*" >&2
      observe_endpoints
      next_observation=$((SECONDS + 60))
    fi
    if (( SECONDS >= readiness_deadline )); then
      echo "Network readiness deadline exceeded: $*" >&2
      return 1
    fi
    sleep 10
  done
}
cleanup() {
  kubectl delete pod "${probe_pod}" --ignore-not-found --wait=false >/dev/null 2>&1 || true
  kubectl delete namespace "${probe_namespace}" --ignore-not-found --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT
worker=$(kubectl get nodes -o json | jq -r '[.items[] | select(.metadata.labels["node-role.kubernetes.io/control-plane"] == null) | .metadata.name][0] // empty')
if [[ -z ${worker} ]]; then
  echo "no worker node found" >&2
  exit 1
fi
node_ips=()
while IFS= read -r node_ip; do
  node_ips+=("${node_ip}")
done < <(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP") | .address')
control_plane_ips=()
while IFS= read -r node_ip; do
  control_plane_ips+=("${node_ip}")
done < <(kubectl get nodes -o json | jq -r '.items[] | select(.metadata.labels["node-role.kubernetes.io/control-plane"] != null) | .status.addresses[] | select(.type == "InternalIP") | .address')
expected_nodes=${#node_ips[@]}
echo "Checking Cilium health from every node"
health_ready() {
  local health
  health=$(kubectl -n kube-system exec "$1" -- cilium-health status) || return
  grep -Fq "${expected_nodes}/${expected_nodes} reachable" <<<"${health}"
}
while IFS= read -r pod; do
  # A Ready agent can still have an empty/stale first health sweep.
  wait_for_network health_ready "${pod}"
  status=$(kubectl -n kube-system exec "${pod}" -- cilium-dbg status)
  grep -Fq "${routing}" <<<"${status}"
done < <(kubectl -n kube-system get pods -l k8s-app=cilium -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
echo "Checking KubeSpan peers"
for node_ip in "${node_ips[@]}"; do
  peer_status=$(talosctl -n "${node_ip}" get kubespanpeerstatus)
  peer_count=$(awk 'NR > 1 && $0 ~ /[[:space:]]up[[:space:]]/ { count++ } END { print count + 0 }' <<<"${peer_status}")
  [[ ${peer_count} -eq $((expected_nodes - 1)) ]]
  routing_rules=$(talosctl -n "${node_ip}" get routingrules -o yaml)
  source_count=$(grep -Fc "src: ${pod_cidr}" <<<"${routing_rules}")
  [[ ${source_count} -eq ${expected_nodes} ]]
done
echo "Checking ${family} API, DNS, and public egress from ${worker}"
kubectl run "${probe_pod}" \
  --image=curlimages/curl:8.16.0 \
  --restart=Never \
  --overrides="$(jq -nc --arg node "${worker}" --arg name "${probe_pod}" '{spec:{nodeName:$node,securityContext:{seccompProfile:{type:"RuntimeDefault"}},containers:[{name:$name,image:"curlimages/curl:8.16.0",command:["sleep","86400"],securityContext:{allowPrivilegeEscalation:false,runAsNonRoot:true,runAsUser:100,capabilities:{drop:["ALL"]}}}]}}')" >/dev/null
kubectl wait --for=condition=Ready "pod/${probe_pod}" --timeout="${readiness_timeout}s" >/dev/null
probe_curl() {
  kubectl exec "${probe_pod}" -- curl -gksS --connect-timeout 5 --max-time 15 "$@"
}
wait_for_network probe_curl -o /dev/null "${service_api}"
for node_ip in "${control_plane_ips[@]}"; do
  if [[ ${family} == ipv6 ]]; then node_ip="[${node_ip}]"; fi
  wait_for_network probe_curl -o /dev/null "https://${node_ip}:6443/version"
done
if [[ ${family} == ipv6 ]]; then
  wait_for_network probe_curl -o /dev/null https://[2606:4700:4700::1111]:443
else
  wait_for_network probe_curl -o /dev/null https://1.1.1.1:443
fi
wait_for_network probe_curl -o /dev/null https://ipv4.google.com
wait_for_network kubectl exec "${probe_pod}" -- getent hosts kubernetes.default.svc.cluster.local >/dev/null
if [[ ${family} == ipv6 ]]; then
  nat64_host=$(kubectl exec "${probe_pod}" -- getent hosts ipv4.google.com)
  grep -q ':' <<<"${nat64_host}"
fi
echo "Checking Gateway API data plane"
kubectl create namespace "${probe_namespace}" >/dev/null
kubectl apply -f - >/dev/null <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: echo
  namespace: ${probe_namespace}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: echo
  template:
    metadata:
      labels:
        app: echo
    spec:
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: echo
          image: registry.k8s.io/e2e-test-images/agnhost:2.53
          args: ["netexec", "--http-port=8080"]
          ports:
            - containerPort: 8080
          securityContext:
            allowPrivilegeEscalation: false
            runAsNonRoot: true
            runAsUser: 1000
            capabilities:
              drop: ["ALL"]
---
apiVersion: v1
kind: Service
metadata:
  name: echo
  namespace: ${probe_namespace}
spec:
  selector:
    app: echo
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: smoke
  namespace: ${probe_namespace}
spec:
  gatewayClassName: cilium
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: smoke
  namespace: ${probe_namespace}
spec:
  parentRefs:
    - name: smoke
  rules:
    - backendRefs:
        - name: echo
          port: 80
EOF
kubectl -n "${probe_namespace}" rollout status deployment/echo --timeout="${readiness_timeout}s" >/dev/null
kubectl -n "${probe_namespace}" wait --for=condition=Programmed gateway/smoke --timeout="${readiness_timeout}s" >/dev/null
gateway_ip=$(kubectl -n "${probe_namespace}" get gateway smoke -o jsonpath='{.status.addresses[0].value}')
if [[ ${family} == ipv6 ]]; then gateway_ip="[${gateway_ip}]"; fi
wait_for_network curl -gfsS --connect-timeout 5 --max-time 10 \
  -o /dev/null "http://${gateway_ip}/hostname"
echo "${family} networking and Gateway verification passed"
