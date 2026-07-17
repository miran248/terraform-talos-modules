# Hetzner Cloud apply

## Purpose

Create Hetzner Talos servers, SSH material, and firewalls from `hcloud-pool` and `talos-cluster` outputs.

## Ownership

- Own server lifecycle, Talos `user_data`, built-in API/KubeSpan rules, caller-supplied firewall rules, and node IP outputs.

## Local Contracts

- Match resources by stable pool node keys and respect nodes marked `removed`.
- Keep address-family-specific firewall sources consistent with pool `mode`.
- Return the node shape expected in `talos-apply.applies`.

## Work Guidance


## Verification

- Run `terraform fmt -check` in this directory.

## Child DOX Index

