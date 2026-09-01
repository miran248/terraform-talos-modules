# GCP workload identity apply

After `talos-apply` provides a reachable API and credentials, fetch OIDC discovery documents and publish matching JWKS/OpenID configuration to the configured GCS bucket.

Treat temporary CA, certificate, and key files as sensitive transient artifacts. Verify with `terraform fmt -check` in this directory.
