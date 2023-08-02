resource "azurerm_resource_group" "ingest" {
  name     = format("rg-ingest-%s-%s-%s", random_id.environment_id.hex, var.environment, var.primary_location)
  location = var.primary_location

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

// Create a container named 'files-in' for the storage account
resource "azurerm_storage_container" "files-in" {
  name                  = "files-in"
  storage_account_name  = azurerm_storage_account.ingest.name
  container_access_type = "private"
}
