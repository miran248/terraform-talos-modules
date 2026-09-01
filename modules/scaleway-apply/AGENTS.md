# Scaleway apply

Create Talos instances, ephemeral volumes, and security groups from pool and cluster outputs. Match stable keys, omit `removed` nodes, and return the normalized shape expected by `talos-apply.applies`.

Rules without `ip_range` are IPv4-only; explicitly select the pool family for IPv6-wide rules. Keep `user_data` and credentials sensitive. Verify with `terraform fmt -check` here.
