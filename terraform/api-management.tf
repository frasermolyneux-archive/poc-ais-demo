resource "azurerm_resource_group" "apim" {
  name     = format("rg-apim-%s-%s-%s", random_id.environment_id.hex, var.environment, var.primary_location)
  location = var.primary_location

  tags = var.tags
}

resource "azurerm_api_management" "apim" {
  name = format("apim-%s-%s-%s", random_id.environment_id.hex, var.environment, var.primary_location)

  location            = azurerm_resource_group.apim.location
  resource_group_name = azurerm_resource_group.apim.name

  publisher_name  = "Fraser Molyneux"
  publisher_email = "fmolyneux@microsoft.com"

  sku_name = "Consumption_0"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_named_value" "tenent_id" {
  name = "tenant-id"

  resource_group_name = azurerm_resource_group.apim.name

  api_management_name = azurerm_api_management.apim.name

  display_name = "tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_api_management_named_value" "tenent_login_url" {
  name = "tenant-login-url"

  resource_group_name = azurerm_resource_group.apim.name

  api_management_name = azurerm_api_management.apim.name

  display_name = "tenant-login-url"
  value        = "https://login.microsoftonline.com/"
}

// Consumption SKU does not support collection of resource logs - PoC Limitation

//resource "azurerm_monitor_diagnostic_setting" "apim" {
//  name               = "diagnostic-to-log-analytics"
//
//  target_resource_id = azurerm_api_management.apim.id
//  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
//
//  enabled_log {
//    //
//  }
//
//  metric {
//    //
//  }
//}
