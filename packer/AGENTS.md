# Talos image builds

Own Hetzner/Scaleway Packer templates, conversion/upload flow, temporary paths, and operator docs. Keep architecture, Talos version/tag, schematic, registry names, and `scaleway-image` expectations aligned.

Never commit tokens, image payloads, or temporary output. Builds/publication are billable external side effects, not routine validation. Run `packer fmt -check .`; validate only with available plugins/variables; run `just --list` after justfile edits.
