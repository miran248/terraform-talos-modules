# Local Talos cluster

Own the disposable named Docker Talos cluster, separate common/control-plane patches, node counts, and `talosctl cluster` recipes. `.talos/`, `talos-config`, and `kube-config` are generated credentials/state.

Use built-in node CIDR allocation, let Talos choose API advertise addresses, and use `talosctl patch machineconfig` for running nodes. Destructive recipes target only the named local cluster. Run `just --list` after justfile edits and parse changed patch YAML.
