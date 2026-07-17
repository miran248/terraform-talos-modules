# Talos apply

## Purpose

Apply machine configurations, bootstrap Talos, perform controlled upgrades, and retrieve Kubernetes client credentials.

## Ownership

- Own the control-plane-before-worker lifecycle, static host patches from actual cloud IPs, bootstrap, and kubeconfig retrieval.

## Local Contracts

- Consume normalized nodes from every apply module without cloud-specific branching.
- Maintain control-plane ordering and use `terraform apply -parallelism=1` for deterministic rolling operations.
- Preserve drain and installer-image behavior during Talos upgrades.
- Keep all Kubernetes credentials sensitive.

## Work Guidance


## Verification

- Run `terraform fmt -check` in this directory.

## Child DOX Index

