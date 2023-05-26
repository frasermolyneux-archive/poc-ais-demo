resource "azurerm_log_analytics_workspace" "law" {
  name = format("la-%s-%s-%s", random_id.environment_id.hex, var.environment, var.primary_location)

  location            = var.primary_location
  resource_group_name = azurerm_resource_group.rg[var.primary_location].name

  sku = "PerGB2018"

  retention_in_days = 30
}
