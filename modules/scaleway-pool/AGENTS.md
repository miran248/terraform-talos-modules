# Scaleway pool

## Purpose

Allocate routed Scaleway IPs and a placement group for Talos nodes without creating instances.

## Ownership

- Own node naming, IPv4/IPv6 mode validation, patch aggregation, routed IPs, and placement metadata.
- Export the normalized pool shape consumed by `talos-cluster` and `scaleway-apply`.

## Local Contracts

- `mode` is single-stack `ipv4` or `ipv6`; allocated addresses must match it.
- Preserve node keys and `removed` semantics across downstream modules.
- Keep output structure compatible with the shared `pools` input in `talos-cluster`.

## Work Guidance


## Verification

- Run `terraform fmt -check` in this directory.

## Child DOX Index

