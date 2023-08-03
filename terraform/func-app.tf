locals {
  func_apps_instances = flatten([
    for location in var.locations : [
      for role in var.func_app_roles : {
        key          = format("fa-%s-%s-%s-%s", role, random_id.environment_id.hex, var.environment, location)
        storage_name = format("safn%s%s", role, lower(random_string.location[location].result))
        role         = role
        location     = location
      }
    ]
  ])
}

resource "azurerm_resource_group" "func" {
  for_each = toset(var.locations)

  name     = format("rg-func-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_service_plan" "func" {
  for_each = toset(var.locations)

  name = format("sp-func-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.func[each.value].name
  location            = azurerm_resource_group.func[each.value].location

  os_type  = "Linux"
  sku_name = "P1v2"
}

resource "azurerm_monitor_diagnostic_setting" "func_svcplan" {
  for_each = toset(var.locations)

  name = azurerm_log_analytics_workspace.law.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  target_resource_id = azurerm_service_plan.func[each.value].id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_storage_account" "func" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name = each.value.storage_name

  resource_group_name = azurerm_resource_group.func[each.value.location].name
  location            = azurerm_resource_group.func[each.value.location].location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  public_network_access_enabled = false

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_private_endpoint" "func_sa_blob_pe" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name = format("pe-%s-blob", azurerm_storage_account.func[each].name)

  resource_group_name = azurerm_resource_group.func[each.value.location].name
  location            = azurerm_resource_group.func[each.value.location].location

  subnet_id = azurerm_subnet.endpoints[each.value.location].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["blob"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-blob", azurerm_storage_account.func[each].name)
    private_connection_resource_id = azurerm_storage_account.func[each].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "func_sa_table_pe" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name = format("pe-%s-table", azurerm_storage_account.func[each].name)

  resource_group_name = azurerm_resource_group.func[each.value.location].name
  location            = azurerm_resource_group.func[each.value.location].location

  subnet_id = azurerm_subnet.endpoints[each.value.location].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["table"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-table", azurerm_storage_account.func[each].name)
    private_connection_resource_id = azurerm_storage_account.func[each].id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "func_sa_queue_pe" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name = format("pe-%s-queue", azurerm_storage_account.func[each].name)

  resource_group_name = azurerm_resource_group.func[each.value.location].name
  location            = azurerm_resource_group.func[each.value.location].location

  subnet_id = azurerm_subnet.endpoints[each.value.location].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["queue"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-queue", azurerm_storage_account.func[each].name)
    private_connection_resource_id = azurerm_storage_account.func[each].id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "func_sa_file_pe" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name = format("pe-%s-file", azurerm_storage_account.func[each].name)

  resource_group_name = azurerm_resource_group.func[each.value.location].name
  location            = azurerm_resource_group.func[each.value.location].location

  subnet_id = azurerm_subnet.endpoints[each.value.location].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["file"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-file", azurerm_storage_account.func[each].name)
    private_connection_resource_id = azurerm_storage_account.func[each].id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

resource "azurerm_linux_function_app" "func" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name = each

  resource_group_name = azurerm_resource_group.func[each.value.location].name
  location            = azurerm_resource_group.func[each.value.location].location

  storage_account_name       = azurerm_storage_account.func[each].name
  storage_account_access_key = azurerm_storage_account.func[each].primary_access_key
  service_plan_id            = azurerm_service_plan.func[each.value.location].id

  virtual_network_subnet_id = azurerm_subnet.app_01[each.value.location].id

  https_only = true

  site_config {
    always_on = true

    application_insights_key               = azurerm_application_insights.ai[each.value.location].instrumentation_key
    application_insights_connection_string = azurerm_application_insights.ai[each.value.location].connection_string

    vnet_route_all_enabled = true

    ftps_state = "Disabled"

    application_stack {
      use_dotnet_isolated_runtime = true
      dotnet_version              = "7.0"
    }
  }

  // This is required to prevent the `WEBSITE_CONTENTSHARE` and `WEBSITE_CONTENTAZUREFILECONNECTIONSTRING` being added as these app settings aren't required for Linux apps on Elastic Premium.
  content_share_force_disabled = true

  app_settings = {
    "servicebus_connection_string" = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/fa-%s-%s-%s-%s/)", azurerm_key_vault.kv[each.value.location].name, random_id.environment_id.hex, var.environment, each.value.location, azurerm_servicebus_namespace.sb[each.value.location].name),
    "ingest_connection_string"     = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/%s/)", azurerm_key_vault.kv[each.value.location].name, azurerm_key_vault_secret.ingest_connection_string[each.value.location].name)
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_private_endpoint.func_sa_blob_pe,
    azurerm_private_endpoint.func_sa_table_pe,
    azurerm_private_endpoint.func_sa_queue_pe,
    azurerm_private_endpoint.func_sa_file_pe
  ]
}

data "azurerm_function_app_host_keys" "func" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name                = azurerm_linux_function_app.func[each].name
  resource_group_name = azurerm_resource_group.func[each.value.location].name
}

resource "azurerm_monitor_diagnostic_setting" "func" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name = "diagnostic-to-log-analytics"

  target_resource_id         = azurerm_linux_function_app.func[each].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "FunctionAppLogs"

    retention_policy {
      enabled = false
    }
  }
}
