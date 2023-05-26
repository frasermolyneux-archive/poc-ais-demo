environment      = "poc"
primary_location = "uksouth"
locations        = ["uksouth", "ukwest"]
subscription_id  = "ecc74148-1a84-4ec7-99bb-d26aba7f9c0d"

address_spaces = {
  "uksouth" = "10.0.0.0/16",
  "ukwest"  = "10.1.0.0/16"
}

subnets = {
  "uksouth" = {
    "endpoints" = "10.0.1.0/24",
    "app_01"    = "10.0.2.0/24",
    "app_02"    = "10.0.3.0/24",
    "app_03"    = "10.0.4.0/24",
    "app_04"    = "10.0.5.0/24",
    "app_05"    = "10.0.6.0/24",
    "app_06"    = "10.0.7.0/24"
  },
  "ukwest" = {
    "endpoints" = "10.1.1.0/24",
    "app_01"    = "10.1.2.0/24",
    "app_02"    = "10.1.3.0/24",
    "app_03"    = "10.1.4.0/24",
    "app_04"    = "10.1.5.0/24",
    "app_05"    = "10.1.6.0/24",
    "app_06"    = "10.1.7.0/24"
  }
}

tags = {
  Environment = "poc",
  Workload    = "proof-of-concept",
  DeployedBy  = "GitHub-Terraform",
}
