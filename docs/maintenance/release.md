# Release contracts

- `.github/workflows/release.yaml` runs Release Please on `main` with the `terraform-module` strategy and repository manifest.
- Use Conventional Commit subjects. `fix:` and `feat:` drive semantic versions; use `type!:` for breaking changes.
- Every repository-owned module source reference must include `# x-release-please-version` and appear as a generic `extra-file` in `.github/release-please-config.json`.
- Public interface changes require synchronized module READMEs, examples, and pinned release references.
- Release Please owns the release PR, `CHANGELOG.md`, `vMAJOR.MINOR.PATCH` tag, and GitHub Release. Do not create or push release tags manually.
- Review and merge the generated Release Please PR to publish; ordinary implementation work commits locally and never pushes unless explicitly requested.
