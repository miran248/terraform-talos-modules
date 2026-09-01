# GCP workload identity

Own Workload Identity Federation, OIDC storage, service accounts, IAM, signing keys, and Talos issuer patches.

Subjects use `namespace:name`; keep provider conditions, IAM membership, issuer URLs, and exported identifiers aligned. Expose only values required by `gcp-wif-apply` and composition. Verify with `terraform fmt -check` here.
