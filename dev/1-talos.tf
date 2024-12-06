locals {
  dev5_patches_zitadel = <<-EOF
    machine:
      nodeLabels:
        app: zitadel
  EOF

  image_id = data.hcloud_image.v1_8_3_amd64.id
}

module "dev5_nuremberg_pool" {
  source = "../modules/hcloud-pool"

  prefix     = "dev5-nbg"
  datacenter = data.hcloud_datacenter.nuremberg.name

  # cidr             = "192.168.1.0/24"
  # load_balancer_ip = "192.168.1.5"

  control_planes = [
    { server_type = "cx22", image_id = local.image_id },
    { server_type = "cx22", image_id = local.image_id },
    { server_type = "cx22", image_id = local.image_id },
  ]
  # workers = [
  #   { server_type = "cx22", image_id = local.image_id, patches = [local.dev5_patches_zitadel] },
  #   # { server_type = "cx22", image_id = local.image_id, patches = [local.dev5_patches_zitadel] },
  #   # { server_type = "cx22", image_id = local.image_id, patches = [local.dev5_patches_zitadel] },
  # ]
}

module "dev5_helsinki_pool" {
  source = "../modules/hcloud-pool"

  prefix     = "dev5-hel"
  datacenter = data.hcloud_datacenter.helsinki.name

  workers = [
    { server_type = "cx22", image_id = local.image_id },
    # { server_type = "cx22", image_id = local.image_id },
  ]
}

locals {
  pools = [
    module.dev5_nuremberg_pool,
    # module.dev5_helsinki_pool,
  ]
}

module "dev5_talos_cluster" {
  source = "../modules/talos-cluster"

  name               = "dev5"
  endpoint           = "dev5.dev.248.sh"
  talos_version      = "v1.8.3"
  kubernetes_version = "v1.31.3"

  pools = local.pools

  patches = {
    common = [
      yamlencode({
        cluster = {
          network = {
            cni = {
              name = "none"
              # name = "custom"
              # urls = [
              #   "https://raw.githubusercontent.com/miran248/terraform-talos-modules/95c41f61ca0801479fd713d6c26810b8bdfcbb9d/manifests/cilium.yaml",
              # ]
            }
          }
          # extraManifests = [
          #   "https://raw.githubusercontent.com/miran248/terraform-talos-modules/95c41f61ca0801479fd713d6c26810b8bdfcbb9d/manifests/hcloud-csi.yaml",
          # ]
        }
        machine = {
          network = {
            nameservers = [
              # "2a01:4ff:ff00::add:2", # hetzner
              # "2a01:4ff:ff00::add:1", # hetzner
              "2a00:1098:2b::1",      # https://nat64.net
              "2a00:1098:2c::1",      # https://nat64.net
              "2a01:4f8:c2c:123f::1", # https://nat64.net
            ]
          }
          time = {
            servers = [
              "/dev/ptp0",
            ]
          }
        }
      }),
    ]
    control_planes = flatten([
      module.gcp_wif.patches.control_planes,
      yamlencode({
        cluster = {
          allowSchedulingOnControlPlanes = true
          # externalCloudProvider = {
          #   manifests = [
          #     "https://raw.githubusercontent.com/miran248/terraform-talos-modules/v1.3.0/manifests/talos-ccm.yaml",
          #   ]
          # }
        }
      }),
    ])
  }
}

module "dev5_hcloud_apply" {
  for_each = { for pool in local.pools : pool.prefix => pool }
  source   = "../modules/hcloud-apply"

  cluster = module.dev5_talos_cluster
  pool    = each.value
}

module "dev5_talos_apply" {
  source = "../modules/talos-apply"

  cluster = module.dev5_talos_cluster
}

module "dev5_gcp_wif_apply" {
  source = "../modules/gcp-wif-apply"

  identities = module.gcp_wif
  cluster    = module.dev5_talos_cluster
  apply      = module.dev5_talos_apply
}

resource "google_dns_record_set" "dev5_talos_ipv6" {
  name         = "${module.dev5_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = module.dev5_talos_cluster.public_ips6.control_planes
}

# outputs
output "talos_config" {
  value     = module.dev5_talos_cluster.talos_config
  sensitive = true
}
