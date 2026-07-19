# Local Talos cluster

## Purpose

Create, patch, and destroy a disposable Docker-backed Talos cluster for local experimentation.

## Ownership

- Own local Talos machine patches, node counts, and `talosctl cluster` recipes.

## Local Contracts

- `.talos/`, `talos-config`, and `kube-config` are generated local state and credentials.
- Keep common and control-plane patch responsibilities separated.
- Use Kubernetes built-in node CIDR allocation; the local workflow does not deploy an external cloud controller.
- Use `talosctl patch machineconfig` for updates to running local nodes.
- Keep the Docker workflow compatible with the stable Talos CLI; Docker clusters have one control plane.
- Destructive recipes must target the named local Docker cluster only.

## Work Guidance


## Verification

- Use `just list` to verify recipe parsing after editing the justfile.

## Child DOX Index
