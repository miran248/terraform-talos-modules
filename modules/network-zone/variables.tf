variable "cloud" {
  type        = number
  description = "defines second octet, 10.cc._._"

  validation {
    condition     = var.cloud >= 1 && var.cloud <= 15
    error_message = "must be between 1 and 15, inclusive"
  }
}
variable "region" {
  type        = number
  description = "defines first two digits of the third octet, 10._.rr_._"

  validation {
    condition     = var.region >= 1 && var.region <= 24
    error_message = "must be between 1 and 24, inclusive"
  }
}
variable "zone" {
  type        = number
  description = "defines last digit of the third octet, 10._.__z._"

  validation {
    condition     = var.zone >= 1 && var.zone <= 9
    error_message = "must be between 1 and 9, inclusive"
  }
}
