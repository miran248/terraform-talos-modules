# Scaleway image

Register an existing object-storage Talos qcow2 as zone-scoped snapshot and image resources. Image build/upload belongs to `packer/`; preserve zone and resource IDs expected by pool callers.

Verify with `terraform fmt -check` in this directory. Do not build, upload, or publish as validation.
