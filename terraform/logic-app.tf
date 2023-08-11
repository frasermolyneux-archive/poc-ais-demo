locals {
  logic_apps_instances = flatten([
    for location in var.locations : [
      for logic_app in var.logic_apps : {
        key          = format("logic-%s-%s-%s", logic_app.role, var.environment, location)
        app_name     = format("logic-%s-%s-%s-%s", logic_app.role, random_id.environment_id.hex, var.environment, location)
        storage_name = format("sala%s%s", logic_app.role, lower(random_string.location[location].result))
        role         = logic_app.role
        location     = location
      }
    ]
  ])
}

resource "azurerm_resource_group" "logic" {
  for_each = toset(var.locations)

  name     = format("rg-logic-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_service_plan" "logic" {
  for_each = toset(var.locations)

  name = format("sp-logic-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.logic[each.value].name
  location            = azurerm_resource_group.logic[each.value].location

  os_type  = "Windows"
  sku_name = "WS1"
}

resource "azurerm_monitor_diagnostic_setting" "logic_svcplan" {
  for_each = toset(var.locations)

  name = azurerm_log_analytics_workspace.law.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  target_resource_id = azurerm_service_plan.logic[each.value].id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_storage_account" "logic" {
  for_each = { for each in local.logic_apps_instances : each.key => each }

  name = each.value.storage_name

  resource_group_name = azurerm_resource_group.logic[each.value.location].name
  location            = azurerm_resource_group.logic[each.value.location].location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"


  // Public network access must be enabled for the demo as the GitHub Actions runner is not network connected.
  public_network_access_enabled = true

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_private_endpoint" "logic_sa_blob_pe" {
  for_each = { for each in local.logic_apps_instances : each.key => each }

  name = format("pe-%s-blob", azurerm_storage_account.logic[each.key].name)

  resource_group_name = azurerm_resource_group.logic[each.value.location].name
  location            = azurerm_resource_group.logic[each.value.location].location

  subnet_id = azurerm_subnet.endpoints[each.value.location].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["blob"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-blob", azurerm_storage_account.logic[each.key].name)
    private_connection_resource_id = azurerm_storage_account.logic[each.key].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "logic_sa_table_pe" {
  for_each = { for each in local.logic_apps_instances : each.key => each }

  name = format("pe-%s-table", azurerm_storage_account.logic[each.key].name)

  resource_group_name = azurerm_resource_group.logic[each.value.location].name
  location            = azurerm_resource_group.logic[each.value.location].location

  subnet_id = azurerm_subnet.endpoints[each.value.location].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["table"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-table", azurerm_storage_account.logic[each.key].name)
    private_connection_resource_id = azurerm_storage_account.logic[each.key].id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "logic_sa_queue_pe" {
  for_each = { for each in local.logic_apps_instances : each.key => each }

  name = format("pe-%s-queue", azurerm_storage_account.logic[each.key].name)

  resource_group_name = azurerm_resource_group.logic[each.value.location].name
  location            = azurerm_resource_group.logic[each.value.location].location

  subnet_id = azurerm_subnet.endpoints[each.value.location].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["queue"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-queue", azurerm_storage_account.logic[each.key].name)
    private_connection_resource_id = azurerm_storage_account.logic[each.key].id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "logic_sa_file_pe" {
  for_each = { for each in local.logic_apps_instances : each.key => each }

  name = format("pe-%s-file", azurerm_storage_account.logic[each.key].name)

  resource_group_name = azurerm_resource_group.logic[each.value.location].name
  location            = azurerm_resource_group.logic[each.value.location].location

  subnet_id = azurerm_subnet.endpoints[each.value.location].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["file"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-file", azurerm_storage_account.logic[each.key].name)
    private_connection_resource_id = azurerm_storage_account.logic[each.key].id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

resource "azurerm_storage_share" "logic" {
  for_each = { for each in local.logic_apps_instances : each.key => each }

  name                 = each.key
  storage_account_name = azurerm_storage_account.logic[each.key].name
  quota                = 50
}

resource "azurerm_logic_app_standard" "logic" {
  for_each = { for each in local.logic_apps_instances : each.key => each }

  name = each.value.app_name

  version = "~4"

  resource_group_name = azurerm_resource_group.logic[each.value.location].name
  location            = azurerm_resource_group.logic[each.value.location].location

  storage_account_name       = azurerm_storage_account.logic[each.key].name
  storage_account_access_key = azurerm_storage_account.logic[each.key].primary_access_key
  storage_account_share_name = azurerm_storage_share.logic[each.key].name
  app_service_plan_id        = azurerm_service_plan.logic[each.value.location].id

  virtual_network_subnet_id = azurerm_subnet.app_02[each.value.location].id

  https_only = true

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.ai[each.value.location].instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.ai[each.value.location].connection_string
    "FUNCTIONS_WORKER_RUNTIME"              = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"          = "~16"
    "WEBSITE_CONTENTOVERVNET"               = "1"
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
    "servicebus_connection_string"          = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/%s/)", azurerm_key_vault.kv[each.value.location].name, azurerm_key_vault_secret.logic_sb[each.key].name),
  }

  site_config {
    vnet_route_all_enabled = true

    use_32_bit_worker_process = false

    ftps_state = "Disabled"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_private_endpoint.logic_sa_blob_pe,
    azurerm_private_endpoint.logic_sa_table_pe,
    azurerm_private_endpoint.logic_sa_queue_pe,
    azurerm_private_endpoint.logic_sa_file_pe
  ]
}

resource "azurerm_monitor_diagnostic_setting" "logic" {
  for_each = { for each in local.logic_apps_instances : each.key => each }

  name = "diagnostic-to-log-analytics"

  target_resource_id         = azurerm_logic_app_standard.logic[each.key].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  //enabled_log {
  //  category = "WorkflowRuntime"

  //  retention_policy {
  //    enabled = false
  //  }
  //}

  //enabled_log {
  //  category = "FunctionAppLogs"

  //  retention_policy {
  //    enabled = false
  //  }
  //}
}
