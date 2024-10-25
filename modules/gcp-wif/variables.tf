variable "name" {
  type        = string
  description = "name of the google workload identity pool"
}
variable "location" {
  type        = string
  description = "location of the google object store bucket"
}

variable "service_accounts" {
  type = list(object({
    subject = string
    name    = string
    roles   = list(string)
  }))
  description = "list of existing kubernetes service accounts (subjects, format `namespace:name`) to be created on google"
}
