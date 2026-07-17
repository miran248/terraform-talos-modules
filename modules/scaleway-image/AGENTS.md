# Scaleway image

## Purpose

Register a Talos qcow2 object from Scaleway Object Storage as a bootable snapshot and instance image.

## Ownership

- Own bucket/object lookup and zone-scoped snapshot/image registration.

## Local Contracts

- The source object must already exist; image building and upload belong to `packer/`.
- Preserve zone and resource IDs used by `scaleway-pool` callers.

## Work Guidance


## Verification

- Run `terraform fmt -check` in this directory.

## Child DOX Index

