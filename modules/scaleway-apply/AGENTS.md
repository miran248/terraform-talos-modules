# Scaleway apply

## Purpose

Create Scaleway Talos instances, ephemeral volumes, and security groups from pool and cluster outputs.

## Ownership

- Own instance lifecycle, Talos `user_data`, local volumes, built-in API/KubeSpan rules, caller-supplied inbound rules, and node IP outputs.

## Local Contracts

- Match resources by stable pool node keys and respect nodes marked `removed`.
- Scaleway rules without `ip_range` are IPv4-only; explicitly use the pool family for IPv6-wide rules.
- Return the node shape expected in `talos-apply.applies`.

## Work Guidance


## Verification

- Run `terraform fmt -check` in this directory.

## Child DOX Index

