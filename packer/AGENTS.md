# Talos image builds

## Purpose

Build or register official and custom Talos images for Hetzner Cloud and Scaleway.

## Ownership

- Own Packer templates, build recipes, image conversion/upload flow, temporary build paths, and operator documentation.

## Local Contracts

- Never commit cloud tokens, registry tokens, image payloads, or temporary build output.
- Keep architecture, Talos version/tag, schematic, registry image names, and downstream `scaleway-image` expectations aligned.
- Cloud and registry recipes have billable/external side effects; do not run them as routine validation.

## Work Guidance

- Prefer explicit variables for environment-specific paths, buckets, usernames, and tags.
- Preserve cleanup of temporary image material after successful builds.

## Verification

- Run `packer fmt -check .` for Packer template changes.
- Run `packer validate .` only when required plugins and variables are available.
- Use `just --list` to verify recipe parsing after editing the justfile.

## Child DOX Index

