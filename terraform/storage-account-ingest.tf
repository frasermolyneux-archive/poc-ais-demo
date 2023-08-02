resource "azurerm_resource_group" "ingest" {
  name     = format("rg-ingest-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_storage_account" "ingest" {
  name = format("sain%s", random_id.environment_id.hex)

  resource_group_name = azurerm_resource_group.ingest.name
  location            = azurerm_resource_group.ingest.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  // Public network access required to allow file to be added to storage account 
  public_network_access_enabled = true

  network_rules {
    default_action = "Allow"
  }
}
