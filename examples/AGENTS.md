# Examples

## Purpose

Provide copyable Terraform compositions for minimal, multi-region, multi-cloud, Scaleway load-balancer, Talos CCM, and encrypted direct-routing deployments.

## Ownership

- Own example topology, module wiring, explanatory comments, and the optional lifecycle helper.

## Local Contracts

- Examples must use documented public module interfaces and pinned release references.
- Keep credentials and generated client configuration out of source control.
- Prefer realistic complete compositions over test-only shortcuts.
- Keep the encrypted direct-routing example aligned with the tested IPv6-only KubeSpan endpoint filter, PodCIDR route, and pod-to-node-pool policy-routing rules.

## Work Guidance

- Update affected examples with every breaking or meaningfully changed module interface.

## Verification

- Run `terraform fmt -check` in this directory.

## Child DOX Index
