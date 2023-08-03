variable "environment" {
  default = "dev"
}

variable "primary_location" {
  default = "uksouth"
}

variable "locations" {
  default = ["uksouth", "ukwest"]
}

variable "subscription_id" {}

variable "address_spaces" {}

variable "subnets" {}

variable "func_app_roles" {
  default = ["sub1", "pub1"]
}

variable "logic_app_roles" {
  default = ["sub1", "pub1"]
}

variable "tags" {
  default = {}
}
