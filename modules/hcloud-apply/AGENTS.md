# Hetzner Cloud apply

Create Talos servers, SSH material, and firewalls from pool and cluster outputs. Match stable node keys, omit `removed` nodes, and keep built-in/caller firewall sources consistent with pool address family.

Return the normalized node shape expected by `talos-apply.applies`; keep Talos `user_data` and credentials sensitive. Verify with `terraform fmt -check` in this directory.
