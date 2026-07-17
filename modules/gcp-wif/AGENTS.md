# GCP workload identity

## Purpose

Create GCP Workload Identity Federation, OIDC storage, service accounts, IAM bindings, and Talos OIDC issuer patches.

## Ownership

- Own the identity pool/provider, discovery bucket access, signing key, subject mappings, project roles, and control-plane patches.

## Local Contracts

- Kubernetes subjects use `namespace:name` and must map consistently into provider conditions and IAM membership.
- Keep bucket issuer URLs synchronized with generated Talos API server patches.
- Expose only the identifiers required by `gcp-wif-apply` and cluster composition.

## Work Guidance


## Verification

- Run `terraform fmt -check` in this directory.

## Child DOX Index

