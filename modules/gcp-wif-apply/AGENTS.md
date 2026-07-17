# GCP workload identity apply

## Purpose

Fetch OIDC discovery documents from a bootstrapped cluster and publish them to the GCS bucket created by `gcp-wif`.

## Ownership

- Own temporary TLS client files, authenticated discovery requests, and GCS object publication.

## Local Contracts

- Run only after `talos-apply` provides a reachable API endpoint and client credentials.
- Treat generated CA, certificate, and key files as sensitive transient artifacts.
- Publish both JWKS and OpenID configuration with content that matches the configured issuer.

## Work Guidance


## Verification

- Run `terraform fmt -check` in this directory.

## Child DOX Index

