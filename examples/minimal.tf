data "hcloud_image" "v1_9_5_amd64" {
  with_selector = "name=talos,version=v1.9.5,arch=amd64"
}
data "hcloud_datacenter" "nuremberg" {
  name = "nbg1-dc3"
}

locals {
  image_id = data.hcloud_image.v1_9_5_amd64.id
}

module "nuremberg_pool" {
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-pool?ref=v3.2.1"

  prefix     = "nbg"
  datacenter = data.hcloud_datacenter.nuremberg.name

  control_planes = [
    { server_type = "cx22", image_id = local.image_id },
  ]
  workers = [
    { server_type = "cx22", image_id = local.image_id },
  ]
}

module "talos_cluster" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-cluster?ref=v3.2.1"

  name               = "example"
  endpoint           = "k.example.com"
  talos_version      = "v1.9.5"
  kubernetes_version = "v1.32.2"

  pools = [
    module.nuremberg_pool,
  ]

  patches = {
    common = [
      yamlencode({
        cluster = {
          network = {
            cni = {
              name = "none"
            }
          }
          inlineManifests = [
            {
              name     = "hcloud-secret",
              contents = <<-EOF
                apiVersion: v1
                kind: Secret
                metadata:
                  name: hcloud
                  namespace: kube-system
                stringData:
                  token: ${var.hcloud_token}
                type: Opaque
              EOF
            },
          ]
        }
        machine = {
          network = {
            nameservers = [
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
  }
}

module "hcloud_apply" {
  for_each = { for pool in [
    module.nuremberg_pool,
  ] : pool.prefix => pool }
  source = "github.com/miran248/terraform-talos-modules//modules/hcloud-apply?ref=v3.2.1"

  cluster = module.talos_cluster
  pool    = each.value
}

module "talos_apply" {
  source = "github.com/miran248/terraform-talos-modules//modules/talos-apply?ref=v3.2.1"

  cluster = module.talos_cluster
}

resource "google_dns_record_set" "talos_ipv6" {
  name         = "k.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = module.talos_cluster.public_ips6.control_planes
}

# outputs
output "talos_config" {
  value     = module.talos_cluster.talos_config
  sensitive = true
}
