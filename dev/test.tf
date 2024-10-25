data "hcloud_image" "dev3_v1_8_1_amd64" {
  with_selector = "name=talos,version=v1.8.1,arch=amd64"
}
data "hcloud_datacenter" "dev3_nuremberg" {
  name = "nbg1-dc3"
}
data "hcloud_datacenter" "dev3_helsinki" {
  name = "hel1-dc2"
}

locals {
  dev3_patches_zitadel = <<-EOF
    machine:
      nodeLabels:
        app: zitadel
  EOF

  image_id = data.hcloud_image.dev3_v1_8_1_amd64.id
}

module "dev3_gcp_wif" {
  source = "../modules/gcp-wif"

  name     = "dev3-wif"
  location = "EUROPE-WEST3"

  service_accounts = [
    { subject = "cert-manager:cert-manager", name = "cert-manager", roles = ["roles/dns.admin"] },
    { subject = "external-dns:external-dns", name = "external-dns", roles = ["roles/dns.admin"] },

    { subject = "external-secrets:external-secrets", name = "external-secrets", roles = [
      "roles/iam.serviceAccountTokenCreator",
      "roles/secretmanager.admin",
      # "roles/secretmanager.secretAccessor",
    ] },
  ]
}

module "dev3_nuremberg_pool" {
  source = "../modules/hcloud-pool"

  prefix     = "dev3-nbg"
  datacenter = data.hcloud_datacenter.dev3_nuremberg.name

  control_planes = [
    { server_type = "cx22", image_id = local.image_id },
    # { server_type = "cx22", image_id = local.image_id },
    # { server_type = "cx22", image_id = local.image_id },
  ]
  workers = [
    # { server_type = "cx22", image_id = local.image_id, patches = [local.dev3_patches_zitadel] },
    # { server_type = "cx22", image_id = local.image_id, patches = [local.dev3_patches_zitadel] },
    # { server_type = "cx22", image_id = local.image_id, patches = [local.dev3_patches_zitadel] },
  ]
}

module "dev3_helsinki_pool" {
  source = "../modules/hcloud-pool"

  prefix     = "dev3-hel"
  datacenter = data.hcloud_datacenter.dev3_helsinki.name

  workers = [
    { server_type = "cx22", image_id = local.image_id },
    # { server_type = "cx22", image_id = local.image_id },
  ]
}

module "dev3_talos_cluster" {
  source = "../modules/talos-cluster"

  name               = "dev3"
  endpoint           = "dev3.dev.248.sh"
  talos_version      = "v1.8.1"
  kubernetes_version = "v1.31.1"

  pools = [
    module.dev3_nuremberg_pool,
    module.dev3_helsinki_pool,
  ]

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
    # control_planes = [
    #   yamlencode({
    #     cluster = {
    #       externalCloudProvider = {
    #         manifests = [
    #           "https://raw.githubusercontent.com/miran248/terraform-talos-modules/v1.3.0/manifests/talos-ccm.yaml",
    #         ]
    #       }
    #     }
    #   }),
    # ]
    control_planes = flatten([
      module.dev3_gcp_wif.patches.control_planes,
    ])
  }
}

module "dev3_hcloud_apply" {
  for_each = merge([for pool in [
    module.dev3_nuremberg_pool,
    module.dev3_helsinki_pool,
  ] : { "${pool.prefix}" = pool }]...)
  source = "../modules/hcloud-apply"

  cluster = module.dev3_talos_cluster
  pool    = each.value
}

module "dev3_talos_apply" {
  source = "../modules/talos-apply"

  cluster = module.dev3_talos_cluster
}

module "dev3_gcp_wif_apply" {
  source = "../modules/gcp-wif-apply"

  identities = module.dev3_gcp_wif
  cluster    = module.dev3_talos_cluster
  apply      = module.dev3_talos_apply
}

resource "google_dns_record_set" "dev3_talos_ipv6" {
  name         = "${module.dev3_talos_cluster.name}.${data.google_dns_managed_zone.this.dns_name}"
  managed_zone = data.google_dns_managed_zone.this.name
  type         = "AAAA"
  ttl          = 300

  rrdatas = module.dev3_talos_cluster.public_ips6.control_planes
}

# outputs
output "talos_config" {
  value     = module.dev3_talos_cluster.talos_config
  sensitive = true
}
