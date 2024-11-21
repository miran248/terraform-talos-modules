@build:
  mkdir -p .build/manifests
  just build-helm manifests/argocd
  just build-helm manifests/cilium
  just build-helm manifests/gcp-wif-webhook
  just build-helm manifests/hcloud-ccm
  just build-helm manifests/hcloud-csi
  just build-helm manifests/iperf
  just build-helm manifests/talos-ccm

build-helm NAME:
  kustomize build --enable-helm {{ NAME }} > .build/{{ NAME }}.yaml
