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

- The metadata and user-data services have IPv4 (`169.254.42.42`) and IPv6 (`fd00:42::42`) endpoints. Bound attempts against an unreachable family and retain the attempted URL in errors. Pass bare `ErrNoConfigSource` for missing/empty user data: wrapping it in `retry.ExpectedError` delays maintenance mode by the download retry budget.
- Preserve DHCP ownership of IPv4 addresses and routes, including legacy NAT instances. A nonempty gateway does not establish routed mode, and `provisioning_mode` describes address provisioning rather than NAT mode. The SDK intentionally omits deprecated `routed_ip_enabled`; see [Scaleway SDK issue #3247](https://github.com/scaleway/scaleway-sdk-go/issues/3247).
- Preserve legacy `public_ip` in external node addresses when `public_ips_v4` is absent. Malformed entries should be logged and skipped while keeping the rest of the platform network configuration.
- Scaleway's [routed IPv6 uses SLAAC](https://www.scaleway.com/en/docs/instances/how-to/useflexips/), not DHCPv6. Talos's kernel `accept_ra=2` setting allows router advertisements to supply routes and MTU while forwarding is enabled. Adding a DHCP6 operator just to obtain DNS is not equivalent to AWS's platform setup.
- Talos does not consume RA DNS options, so IPv6-only metadata needs an explicit IPv6 resolver spec instead of its IPv4 DNS defaults. Once DNS works, the default `time.cloudflare.com` time server is IPv6-capable; no platform-specific NTP override is needed. See [Scaleway's RA DNS explanation](https://www.scaleway.com/en/docs/instances/troubleshooting/fix-dns-routed-ipv6-only-debian-bullseye/) and [Cloudflare NTP usage](https://developers.cloudflare.com/time-services/ntp/usage/).

## Build recovery

- Docker Desktop can report filesystem I/O errors when the host disk fills. Check host free space as well as `docker system df`; an unresponsive API does not alone establish a source/build failure.
- Cache cleanup, when authorized, should target disposable Go/build caches and preserve containers, volumes, credentials, and authored source. Recheck Docker health after a restart before retrying a failed build.
