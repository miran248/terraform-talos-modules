# packer

Builds Talos images for each cloud provider. Custom images are published at `ghcr.io/<username>/talos-installer-base`, `ghcr.io/<username>/talos-imager` and `ghcr.io/<username>/talos-installer`.

## prerequisites

- [just](https://github.com/casey/just)
- [packer](https://www.packer.io)
- [docker](https://www.docker.com) (dev recipes only)
- [rclone](https://rclone.org) configured with a `scaleway` remote (Scaleway recipes only)
- `HCLOUD_TOKEN` set in environment (Hetzner recipes)
- ghcr.io authenticated for dev recipes (`write:packages` scope required): `echo $GITHUB_TOKEN | docker login ghcr.io -u <username> --password-stdin`

## hcloud

Builds a Talos snapshot on Hetzner Cloud from the official factory image:

```shell
> HCLOUD_TOKEN=... just hcloud
```

### custom image

Use a custom imager from `ghcr.io/<username>/talos-imager` to build a snapshot with your own Talos build. If the tag you need is already published, run the imager directly to produce the raw image:

```shell
> docker run --rm -v /dev:/dev -v $(pwd)/_out/images:/out --privileged ghcr.io/<username>/talos-imager:<tag> hcloud --arch amd64
```

To build from source and push a new tag:

```shell
> HCLOUD_TOKEN=... just hcloud-dev
```

1. Runs the imager to produce `hcloud-amd64.raw.zst`
2. Uploads the image to a temporary Hetzner server via packer and creates a snapshot

## scaleway

Streams the official Talos image from factory.talos.dev, converts it to qcow2 and uploads to a Scaleway Object Storage bucket. The image is then registered as a bootable instance image by the [scaleway-image](../modules/scaleway-image) module:

```shell
> just scaleway
```

### custom image

Use a custom imager from `ghcr.io/<username>/talos-imager` to build a qcow2 with your own Talos build. If the tag you need is already published, run the imager directly:

```shell
> docker run --rm -v /dev:/dev -v $(pwd)/_out/images:/out --privileged ghcr.io/<username>/talos-imager:<tag> scaleway --arch amd64
```

To build from source and push a new tag:

```shell
> just scaleway-dev
```

1. Runs the imager to produce `scaleway-amd64.raw.zst`
2. Converts to qcow2 and uploads to the Scaleway bucket

## dev recipes

The dev recipes build from a local Talos source tree. Run them in order:

```shell
> just imager-dev           # builds and publishes talos-installer-base and talos-imager
> just installer-dev        # builds and publishes talos-installer (used as installer_image during upgrades)
> just hcloud-dev           # builds hcloud snapshot using talos-imager
> just scaleway-dev         # builds scaleway qcow2 using talos-imager
```

`installer-dev`, `hcloud-dev` and `scaleway-dev` can be run independently once `imager-dev` has been run for the current tag. Packages are private by default — set visibility to public manually in the GitHub UI after the first push.

## configuration

Edit the following variables at the top of `justfile` to match your environment:

| variable | description |
|---|---|
| `TALOS_SRC` | path to local Talos source tree |
| `DEV_IMAGE_TAG` | tag for the dev build (e.g. `v1.14.0-alpha.1-dev.7`) |
| `USERNAME` | GitHub username for pushing to `ghcr.io/<username>/talos-*` |
| `SCALEWAY_BUCKET` | Scaleway Object Storage bucket name for qcow2 uploads |
| `SCALEWAY_VERSION` | Talos version for the official Scaleway image |
| `SCALEWAY_SCHEMATIC` | Talos factory schematic ID |
