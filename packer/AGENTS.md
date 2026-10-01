# Talos image builds

Own Hetzner/Scaleway Packer templates, conversion/upload flow, temporary paths, and operator docs. Keep architecture, Talos version/tag, schematic, registry names, and `scaleway-image` expectations aligned.

Prefer explicit variables for environment-specific paths, buckets, usernames, and tags. Preserve cleanup of temporary image material after successful builds.

Never commit tokens, image payloads, or temporary output. Builds/publication are billable external side effects, not routine validation. Run `packer fmt -check .`; validate only with available plugins/variables; run `just --list` after justfile edits.

Before changing image workflows, read [operations contracts](../docs/maintenance/operations.md); for custom Talos builds, also read [the Talos fork guide](../docs/maintenance/talos-fork.md).
