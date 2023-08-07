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

variable "function_apps" {
  type = map(object({
    role                = string,
    link_to_apim        = optional(bool, false)
    apim_api_definition = optional(string, "")
  }))
}

variable "logic_apps" {
  type = map(object({
    role = string
  }))
}

variable "tags" {
  default = {}
}
