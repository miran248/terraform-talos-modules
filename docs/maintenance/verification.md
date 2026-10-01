# Verification matrix

Choose checks from the changed area. Validation must not apply infrastructure or mutate a cluster unless explicitly requested.

## Terraform

- All Terraform: `terraform fmt -check -recursive .`
- Modules only: `terraform fmt -check -recursive modules`
- One module/caller: run `terraform fmt -check` in that directory.
- Talos machine endpoint changes: `python3 modules/talos-apply/tests/run.py` (mocked plans; no live infrastructure).
- Workload identity discovery changes: `python3 modules/gcp-wif-apply/tests/run.py` (real local TLS/HTTP requests, mocked Google; requires OpenSSL).
- Run `terraform validate` only from an initialized module or caller and only when provider availability permits. Never substitute `apply` for validation.

## Talos YAML and local recipes

- Parse every changed YAML document under `modules/talos-cluster/patches/` or `local/patches/` with an available YAML parser.
- After a local `justfile` change, run `just --list` in `local/`.

## Kubernetes manifests

- One component: `kustomize build --enable-helm manifests/<component>`.
- Cross-component/root build: `just build`.
- Live networking/Gateway release checks, only against the intended development clusters: run `just verify-ipv6-direct` and `just verify-ipv4` in `dev/`.

## Packer

- Template formatting: `packer fmt -check .` in `packer/`.
- Run `packer validate .` only when plugins and variables are available; do not build or publish.
- After a Packer `justfile` change, run `just --list` in `packer/`.

## Release references

- Verify every repository module source annotation and its matching generic `extra-file` entry when release references change.
- Confirm `git diff --check`, relevant tests/checks, a Conventional Commit, and a clean worktree before handoff.
