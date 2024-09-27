data "hcloud_image" "dev106_v1_8_0_amd64" {
  with_selector = "name=talos,version=v1.8.0,arch=amd64"
}

data "hcloud_datacenter" "dev106_nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_location" "dev106_nuremberg" {
  name = "nbg1"
}
data "hcloud_datacenter" "dev106_helsinki" {
  name = "hel1-dc2"
}
data "hcloud_location" "dev106_helsinki" {
  name = "hel1"
}

locals {
  dev106_patches_zitadel = <<-EOF
    machine:
      nodeLabels:
        app: zitadel
  EOF
}

module "dev106_talos_cluster" {
  source = "../modules/talos-cluster"

  name     = "dev106"
  endpoint = "dev106.dev.248.sh"

  features = {
    ip6 = true
  }

  patches = {
    common = [
      yamlencode({
        cluster = {
          externalCloudProvider = {
            enabled = true
            manifests = [
              "https://raw.githubusercontent.com/miran248/terraform-talos-modules/refs/heads/main/manifests/talos-cloud-controller-manager.yaml",
              # "https://raw.githubusercontent.com/miran248/terraform-talos-modules/refs/tags/v1.0.0/manifests/talos-cloud-controller-manager.yaml",
            ]
          }
          # allowSchedulingOnControlPlanes = true
          network = {
            cni = {
              name = "custom"
              urls = [
                "https://raw.githubusercontent.com/miran248/terraform-talos-modules/v1.0.0/manifests/cilium-ip6.yaml",
              ]
            }
          }
          extraManifests = [
            "https://raw.githubusercontent.com/miran248/terraform-talos-modules/refs/tags/v1.0.0/manifests/hcloud-csi.yaml",
          ]
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
          kubelet = {
            # talos-ccm
            extraArgs = {
              cloud-provider             = "external"
              rotate-server-certificates = true
            }
          }
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
    control_planes = [
      yamlencode({
        machine = {
          features = {
            # talos ccm
            kubernetesTalosAPIAccess = {
              enabled = true
              allowedRoles = [
                "os:reader",
              ]
              allowedKubernetesNamespaces = [
                "kube-system",
              ]
            }
          }
        }
      })
    ]
  }
}

module "dev106_nuremberg_pool_1" {
  source = "../modules/node-pool"

  cluster = module.dev106_talos_cluster

  zone = 1

  nodes = {
    control_planes = [
      { server_type = "cx22" },
      { server_type = "cx22" },
      { server_type = "cx22" },
    ]
    workers = [
      { server_type = "cx22", patches = [local.dev106_patches_zitadel] },
      { server_type = "cx22", patches = [local.dev106_patches_zitadel] },
      # { server_type = "cx22", patches = [local.dev106_patches_zitadel] },
    ]
  }
}
module "dev106_helsinki_pool_1" {
  source = "../modules/node-pool"

  cluster = module.dev106_talos_cluster

  zone = 2

  nodes = {
    # control_planes = [
    #   { server_type = "cx22" },
    # ]
    workers = [
      { server_type = "cx22" },
    ]
  }
}

module "dev106_nuremberg_network_1" {
  source = "../modules/hcloud-network"

  datacenter = data.hcloud_datacenter.dev106_nuremberg
  location   = data.hcloud_location.dev106_nuremberg

  cluster = module.dev106_talos_cluster
  pool    = module.dev106_nuremberg_pool_1
}
module "dev106_helsinki_network_1" {
  source = "../modules/hcloud-network"

  datacenter = data.hcloud_datacenter.dev106_helsinki
  location   = data.hcloud_location.dev106_helsinki

  cluster = module.dev106_talos_cluster
  pool    = module.dev106_helsinki_pool_1
}

module "dev106_talos_config" {
  source = "../modules/talos-config"

  cluster = module.dev106_talos_cluster
  networks = [
    module.dev106_nuremberg_network_1,
    module.dev106_helsinki_network_1,
  ]

  talos_version      = "v1.8.0"
  kubernetes_version = "v1.31.1"
}

module "dev106_nuremberg_1" {
  source = "../modules/hcloud-servers"

  datacenter = data.hcloud_datacenter.dev106_nuremberg
  location   = data.hcloud_location.dev106_nuremberg
  image_id   = data.hcloud_image.dev106_v1_8_0_amd64.id

  cluster = module.dev106_talos_cluster
  pool    = module.dev106_nuremberg_pool_1
  network = module.dev106_nuremberg_network_1
  config  = module.dev106_talos_config

  depends_on = [
    module.dev106_nuremberg_network_1,
    module.dev106_talos_config,
  ]
}
module "dev106_helsinki_1" {
  source = "../modules/hcloud-servers"

  datacenter = data.hcloud_datacenter.dev106_helsinki
  location   = data.hcloud_location.dev106_helsinki
  image_id   = data.hcloud_image.dev106_v1_8_0_amd64.id

  cluster = module.dev106_talos_cluster
  pool    = module.dev106_helsinki_pool_1
  network = module.dev106_helsinki_network_1
  config  = module.dev106_talos_config

  depends_on = [
    module.dev106_helsinki_network_1,
    module.dev106_talos_config,
  ]
}

resource "google_dns_record_set" "dev106_talos_ipv6" {
  name         = "${module.dev106_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = module.dev106_talos_config.public_ips6.control_planes

  depends_on = [
    module.dev106_nuremberg_network_1,
  ]
}

# module "dev106_talos_apply" {
#   source = "../modules/talos-apply"

#   cluster = module.dev106_talos_cluster
#   config  = module.dev106_talos_config

#   depends_on = [
#     module.dev106_nuremberg_1,
#     module.dev106_helsinki_1,
#   ]
# }

# outputs
output "dev106_talos_config" {
  value     = module.dev106_talos_config.talos_config
  sensitive = true
}
output "dev106_talos_config_raw" {
  value     = module.dev106_talos_config
  sensitive = true
}
