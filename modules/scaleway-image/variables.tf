variable "zone" {
  type        = string
  description = "scaleway zone"
}

variable "bucket" {
  type        = string
  description = "scaleway bucket name"
}
variable "object" {
  type        = string
  description = "scaleway qcow2 file path"
}
variable "name" {
  type        = string
  description = "scaleway snapshot and image name"
}
