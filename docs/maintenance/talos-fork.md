# Custom Talos fork

Keep Talos-specific contribution, platform, and build quirks in this repository. The Talos fork carries the upstream patch; this reference carries the local operating knowledge.

## Refresh and publish

1. Inspect the Talos checkout's instructions, staged/unstaged work, PR review threads, and linked issue. Preserve its original commit and uncommitted work before rebasing; keep local tool configuration out of the upstream patch.
2. Fetch upstream before measuring divergence. Confirm the requested baseline: current PR base branch or a stable backport. Rebase the feature commits, restore saved work, and map every reviewer concern to code, a regression test, or a sourced explanation.
3. Run focused tests and repository lint checks, then commit the source used for the build. Check Docker, available disk space, and registry access before invoking the recipes in [packer/README.md](../../packer/README.md). Override `TALOS_SRC` when the checkout is not the sibling `talos` directory.
4. Use a fresh image tag and align installer-base, imager, installer, Scaleway object name, and both dev installer references. Record the source revision and published digests; check the qcow2 and verify the uploaded object before handing off dev configuration.
5. Treat Git push, image publication, and live deployment as separate actions, honoring the session's authorization for each. Prepare both address-family configurations and report build/check results separately from live cluster results.

## Contribution checks

- External Talos contributions require a DCO sign-off (`git commit -s`). GPG signing is reserved for Sidero employees; the GPG signature/identity policy in `.conform.yaml` targets the `siderolabs` organization. Report those employee-only results separately from applicable conformance checks.
- Run the repository's custom golangci-lint, which includes Talos plugins, when checking the platform patch. Focused race tests and package lint are useful evidence, but do not label them as the full `make unit-tests` or `make lint` suite.
- Refresh the PR description after implementation changes. Check only acceptance items actually verified, and distinguish local tests, image builds, and live boot results.

## Scaleway IPv6

Context: [Talos issue #13475](https://github.com/siderolabs/talos/issues/13475) and [PR #13752](https://github.com/siderolabs/talos/pull/13752).

- The metadata and user-data services have IPv4 (`169.254.42.42`) and IPv6 (`fd00:42::42`) endpoints. Bound attempts against an unreachable family and retain the attempted URL in errors. Assume provider JSON and gateway values are well formed: decode metadata after a successful download and retain ordinary parse-error handling. Endpoint failover handles download failures. Pass bare `ErrNoConfigSource` for missing/empty user data: wrapping it in `retry.ExpectedError` delays maintenance mode by the download retry budget.
- Preserve DHCP ownership of IPv4 addresses and routes, including legacy NAT instances. A nonempty gateway does not establish routed mode, and `provisioning_mode` describes address provisioning rather than NAT mode. The SDK intentionally omits deprecated `routed_ip_enabled`; see [Scaleway SDK issue #3247](https://github.com/scaleway/scaleway-sdk-go/issues/3247).
- Preserve legacy `public_ip` in external node addresses when `public_ips_v4` is absent. Log and skip malformed addresses or prefixes while keeping the rest of the platform network configuration. Use legacy IPv6 metadata when no modern entry is usable.
- Scaleway's [routed IPv6 uses SLAAC](https://www.scaleway.com/en/docs/instances/how-to/useflexips/), not DHCPv6. Talos's kernel `accept_ra=2` setting allows router advertisements to supply routes and MTU while forwarding is enabled. Adding a DHCP6 operator just to obtain DNS is not equivalent to AWS's platform setup.
- Talos does not consume RA DNS options, so usable IPv6 metadata needs an explicit IPv6 resolver spec, including on dual-stack nodes: an advertised IPv4 address does not establish IPv4 connectivity. Talos merges these resolvers with DHCP-provided IPv4 DNS; explicit machine DNS settings override both. Once DNS works, the default `time.cloudflare.com` time server is IPv6-capable; no platform-specific NTP override is needed. See [Scaleway's RA DNS explanation](https://www.scaleway.com/en/docs/instances/troubleshooting/fix-dns-routed-ipv6-only-debian-bullseye/) and [Cloudflare NTP usage](https://developers.cloudflare.com/time-services/ntp/usage/).

### Why the patch retains local helpers

The reuse review of Talos fork commit `a28c4aa448df89d2c03e457498a9dc835dae7073` checked the existing Talos utilities and pinned dependencies. The patch already uses `download.Download`, `go-retry`, and standard-library IP parsing; its local helpers supply the remaining platform behavior. Revisit these decisions when the shared implementations change.

- **Address and netmask parsing:** Talos's platform-internal `address.IPPrefixFrom` overlaps with the local parser, but does not reject noncontiguous masks or consistently reject a mask from the wrong address family. It also defaults an empty mask and can return an invalid prefix without an error. The Scaleway parser deliberately rejects these inputs so malformed metadata can be logged and skipped. Reusing the shared helper safely would require strengthening its contract and testing existing callers, expanding this platform patch's scope.
- **Endpoint alternation:** `download.WithEndpointFunc` and `retry.WithAttemptTimeout` provide endpoint selection and per-attempt timeouts. However, the download helper formats errors with its original endpoint argument, even after the callback selects another URL. The pinned `go-retry` implementation also replaces deadline-exceeded errors with a generic timeout, losing wrapped URL context. The local wrapper bounds each family's download and attaches the actual endpoint to the resulting error, remembers the successful family, and returns bare `ErrNoConfigSource` immediately. Consolidation remains possible after shared diagnostics are improved; it is not a behavior-preserving substitution today.
- **Scaleway SDK metadata client:** `MetadataAPI` in `scaleway-sdk-go v1.0.0-beta.37` already probes both families and retrieves user data, but uses background contexts and changes the global HTTP client timeout. Its probe can dereference a nil response after a transport error, and its user-data reader does not map HTTP status codes to Talos's missing-configuration semantics. Retain Talos's downloader rather than adopt this client for boot-time configuration retrieval.
- **External-address deduplication:** The helper uses standard-library `slices.Contains` for these small address lists, preserving insertion order without a separate map. DHCP4 enablement follows advertised IPv4 presence independently of address parsing, so malformed public addresses are skipped without disabling DHCP recovery. IPv6 DNS fallback still follows usable addresses.

Any later consolidation should retain the existing Scaleway metadata fixtures and HTTP-server tests as its verification seams: malformed-mask rejection, preservation of valid entries, endpoint failover and successful-family reuse, bounded attempts, cancellation, actual-URL diagnostics, and immediate missing/empty-user-data handling. The focused Scaleway package tests passed during the review; that does not establish live boot behavior or full lint/conformance results.

## Client compatibility during development

The Talos 0.12.0 Terraform provider rejects an in-place Kubernetes upgrade on
Talos `1.15.0-alpha.0-dev.1` with `compatibility with version ... is not supported`.
Its [Talos libraries are pinned to 1.14.0](https://github.com/siderolabs/terraform-provider-talos/blob/v0.12.0/go.mod),
whose compatibility table predates Talos 1.15. A client built from the
current fork recognizes that version; check its upgrade plan with
`talosctl upgrade-k8s --dry-run --to <version>` using the explicit development
Talos and Kubernetes configs. Record a client-driven upgrade separately from
provider-driven provisioning. Fresh bootstrap and in-place upgrade exercise
different paths; a successful bootstrap does not establish provider upgrade support.

The provider's cluster `Read` operation retains the recorded Kubernetes version
instead of discovering it from the cluster. A client-driven upgrade therefore
does not reconcile that Terraform attribute, and a normal apply can retry the
unsupported upgrade. For a disposable iteration, record the discrepancy and
validate the desired version in the next fresh bootstrap; do not treat a refresh
as proof that provider state matches the running version. Targeted machine-only
changes may be tested separately after reviewing their complete plan.

## Build recovery

- Docker Desktop can report filesystem I/O errors when the host disk fills. Check host free space as well as `docker system df`; an unresponsive API does not alone establish a source/build failure.
- Cache cleanup, when authorized, should target disposable Go/build caches and preserve containers, volumes, credentials, and authored source. Recheck Docker health after a restart before retrying a failed build.
