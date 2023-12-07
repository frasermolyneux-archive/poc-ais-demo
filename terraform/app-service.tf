resource "azurerm_resource_group" "app" {
  for_each = toset(var.locations)

  name     = format("rg-app-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_service_plan" "app" {
  for_each = toset(var.locations)

  name = format("sp-app-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.app[each.value].name
  location            = azurerm_resource_group.app[each.value].location

  os_type  = "Linux"
  sku_name = "P1v2"
}

resource "azurerm_monitor_diagnostic_setting" "app_svcplan" {
  for_each = toset(var.locations)

  name = azurerm_log_analytics_workspace.law.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  target_resource_id = azurerm_service_plan.app[each.value].id

  metric {
    category = "AllMetrics"
  }
}

resource "azurerm_linux_web_app" "app" {
  for_each = toset(var.locations)

  name = format("app-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.app[each.value].name
  location            = azurerm_resource_group.app[each.value].location
  service_plan_id     = azurerm_service_plan.app[each.value].id

  virtual_network_subnet_id = azurerm_subnet.app_03[each.value].id

  https_only = true

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = azurerm_application_insights.ai[each.value].instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = azurerm_application_insights.ai[each.value].connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    "location"                                   = each.value
    "servicebus_connection_string"               = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/app-%s-%s-%s-%s/)", azurerm_key_vault.kv[each.value].name, random_id.environment_id.hex, var.environment, each.value, azurerm_servicebus_namespace.sb[each.value].name)
  }

  site_config {
    vnet_route_all_enabled = true

    ftps_state = "Disabled"

    application_stack {
      dotnet_version = "7.0"
    }

    ip_restriction {
      action      = "Allow"
      service_tag = "AzureFrontDoor.Backend"

      headers {
        x_azure_fdid = [azurerm_cdn_frontdoor_profile.fd.resource_guid]
      }

      name     = "RestrictToFrontDoor"
      priority = 1000
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

// This is required as when the app service is created 'basic auth' is set as disabled which is required for the SCM deploy.
resource "azapi_update_resource" "app" {
  for_each = toset(var.locations)

  type        = "Microsoft.Web/sites/basicPublishingCredentialsPolicies@2022-09-01"
  resource_id = format("%s/basicPublishingCredentialsPolicies/scm", azurerm_linux_web_app.app[each.value].id)

  body = jsonencode({
    properties = {
      allow = true
    }
  })

  depends_on = [
    azurerm_linux_web_app.app,
  ]
}

resource "azurerm_monitor_diagnostic_setting" "app" {
  for_each = toset(var.locations)

  name = azurerm_log_analytics_workspace.law.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  target_resource_id = azurerm_linux_web_app.app[each.value].id

  metric {
    category = "AllMetrics"
  }

  enabled_log {
    category = "AppServiceAntivirusScanAuditLogs"
  }

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceFileAuditLogs"
  }

  enabled_log {
    category = "AppServiceAuditLogs"
  }

  enabled_log {
    category = "AppServiceIPSecAuditLogs"
  }

  enabled_log {
    category = "AppServicePlatformLogs"
  }
}
