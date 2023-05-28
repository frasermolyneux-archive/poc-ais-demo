resource "azurerm_resource_group" "logic" {
  for_each = toset(var.locations)

  name     = format("rg-logic-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_service_plan" "logic" {
  for_each = toset(var.locations)

  name = format("sp-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

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
  for_each = toset(var.locations)

  name = format("salg%s", lower(random_string.location[each.value].result))

  resource_group_name = azurerm_resource_group.logic[each.value].name
  location            = azurerm_resource_group.logic[each.value].location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "logic_sa_blob_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-blob", azurerm_storage_account.logic[each.value].name)

  resource_group_name = azurerm_resource_group.logic[each.value].name
  location            = azurerm_resource_group.logic[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["blob"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-blob", azurerm_storage_account.logic[each.value].name)
    private_connection_resource_id = azurerm_storage_account.logic[each.value].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "logic_sa_table_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-table", azurerm_storage_account.logic[each.value].name)

  resource_group_name = azurerm_resource_group.logic[each.value].name
  location            = azurerm_resource_group.logic[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["table"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-table", azurerm_storage_account.logic[each.value].name)
    private_connection_resource_id = azurerm_storage_account.logic[each.value].id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "logic_sa_queue_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-queue", azurerm_storage_account.logic[each.value].name)

  resource_group_name = azurerm_resource_group.logic[each.value].name
  location            = azurerm_resource_group.logic[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["queue"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-queue", azurerm_storage_account.logic[each.value].name)
    private_connection_resource_id = azurerm_storage_account.logic[each.value].id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "logic_sa_file_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-file", azurerm_storage_account.logic[each.value].name)

  resource_group_name = azurerm_resource_group.logic[each.value].name
  location            = azurerm_resource_group.logic[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["file"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-file", azurerm_storage_account.logic[each.value].name)
    private_connection_resource_id = azurerm_storage_account.logic[each.value].id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

resource "azurerm_logic_app_standard" "logic" {
  for_each = toset(var.locations)

  name = format("logic-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.logic[each.value].name
  location            = azurerm_resource_group.logic[each.value].location

  storage_account_name       = azurerm_storage_account.logic[each.value].name
  storage_account_access_key = azurerm_storage_account.logic[each.value].primary_access_key
  app_service_plan_id        = azurerm_service_plan.logic[each.value].id

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"     = "node"
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
  }

  depends_on = [
    azurerm_private_endpoint.logic_sa_blob_pe,
    azurerm_private_endpoint.logic_sa_table_pe,
    azurerm_private_endpoint.logic_sa_queue_pe,
    azurerm_private_endpoint.logic_sa_file_pe
  ]
}