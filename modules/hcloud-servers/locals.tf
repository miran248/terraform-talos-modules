locals {
  ids = merge([for key, server in hcloud_server.this : { "${key}" = server.id }]...)
}
