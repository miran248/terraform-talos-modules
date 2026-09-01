# Verification matrix

Choose checks from the changed area. Validation must not apply infrastructure or mutate a cluster unless explicitly requested.

## Agent assets

- `python3 -m unittest discover -s .agents/tests -p 'test_*.py' -v`
- Start a fresh trusted Hermes session in the repository and preload the exact project skill name `terraform-talos-modules`; aliases are not supported.

## Terraform

- All Terraform: `terraform fmt -check -recursive .`
- Modules only: `terraform fmt -check -recursive modules`
- One module/caller: run `terraform fmt -check` in that directory.
- Run `terraform validate` only from an initialized module or caller and only when provider availability permits. Never substitute `apply` for validation.

## Talos YAML and local recipes

- Parse every changed YAML document under `modules/talos-cluster/patches/` or `local/patches/` with an available YAML parser.
- After a local `justfile` change, run `just --list` in `local/`.

## Kubernetes manifests

- One component: `kustomize build --enable-helm manifests/<component>`.
- Cross-component/root build: `just build`.
- Live IPv6 direct-routing release check, only against the intended development cluster: run `just verify-ipv6-direct` in `dev/`.

## Packer

- Template formatting: `packer fmt -check .` in `packer/`.
- Run `packer validate .` only when plugins and variables are available; do not build or publish.
- After a Packer `justfile` change, run `just --list` in `packer/`.

## Release references

- Verify every repository module source annotation and its matching generic `extra-file` entry when release references change.
- Confirm `git diff --check`, relevant tests/checks, a Conventional Commit, and a clean worktree before handoff.
