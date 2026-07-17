# Hetzner Cloud pool

## Purpose

Allocate one Hetzner primary IP per Talos node and a placement group without creating servers.

## Ownership

- Own node naming, IPv4/IPv6 mode validation, pool/node patch aggregation, IP allocation, and placement metadata.
- Export the normalized pool shape consumed by `talos-cluster` and `hcloud-apply`.

## Local Contracts

- `mode` is single-stack `ipv4` or `ipv6`; all emitted addresses and CIDRs must match it.
- Preserve node keys and `removed` semantics so downstream modules can drain or omit nodes predictably.
- Keep pool output structure compatible with the shared `pools` input in `talos-cluster`.

## Work Guidance


## Verification

- Run `terraform fmt -check` in this directory.

## Child DOX Index

