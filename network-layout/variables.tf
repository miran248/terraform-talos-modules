variable "size" {
  type        = string
  description = "network size"
  default     = "md"

  validation {
    condition     = contains(["xs", "sm", "md", "lg", "xl"], var.size)
    error_message = "must be xs, sm, md, lg or xl"
  }
}
