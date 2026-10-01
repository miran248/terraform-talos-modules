# Talos apply

Apply machine configuration, bootstrap Talos, perform controlled upgrades, and retrieve sensitive Kubernetes credentials from normalized cloud nodes.

Preserve control-plane-before-worker phases without custom Terraform CLI parallelism, plus static host patches, drain behavior, and installer-image upgrades. Machine operations must connect directly to each node IP: maintenance mode ignores proxy routing metadata, so a shared endpoint can configure the wrong node. Verify with `terraform fmt -check` and `python3 tests/run.py` in this directory.
