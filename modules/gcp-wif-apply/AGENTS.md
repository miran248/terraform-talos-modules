# GCP workload identity apply

After `talos-apply` provides a reachable API and credentials, fetch OIDC discovery documents and publish matching JWKS/OpenID configuration to the configured GCS bucket.

Keep temporary TLS files isolated by cluster under the root's `.terraform` directory, with private permissions. OIDC reads must tolerate transient API/load-balancer startup failures with bounded retries. Verify concurrent TLS clients and startup retries with `python3 modules/gcp-wif-apply/tests/run.py` from the repository root; Google is mocked and all HTTP traffic stays local.
