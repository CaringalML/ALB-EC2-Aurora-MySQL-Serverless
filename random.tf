# Random string generator for resource uniqueness
resource "random_string" "suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}