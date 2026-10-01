# Local Talos cluster

Own the disposable named Docker Talos cluster, separate common/control-plane patches, node counts, and `talosctl cluster` recipes. `.talos/`, `talos-config`, and `kube-config` are generated credentials/state.

Keep the Docker workflow compatible with the stable Talos CLI and Docker clusters to one control plane. Use built-in node CIDR allocation, let Talos choose API advertise addresses, and use `talosctl patch machineconfig` for running nodes. Destructive recipes target only the named local cluster. Run `just --list` after justfile edits and parse changed patch YAML.

Before changing local-cluster workflows, read [operations contracts](../docs/maintenance/operations.md); for network changes, also read [networking contracts](../docs/maintenance/networking.md).
