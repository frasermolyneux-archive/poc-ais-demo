resource "azurerm_resource_group" "sb" {
  for_each = toset(var.locations)

  name     = format("rg-sb-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_servicebus_namespace" "sb" {
  for_each = toset(var.locations)

  name = format("sb-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.sb[each.value].name
  location            = azurerm_resource_group.sb[each.value].location
  tags                = var.tags

  sku      = "Standard"
  capacity = 0

  public_network_access_enabled = true // Required for demo
  minimum_tls_version           = "1.2"
}

//resource "azurerm_private_endpoint" "sb" {
//  for_each = toset(var.locations)
//
//  name = format("pe-%s-servicebus", azurerm_servicebus_namespace.sb[each.value].name)
//
//  resource_group_name = azurerm_resource_group.sb[each.value].name
//  location            = azurerm_resource_group.sb[each.value].location
//
//  subnet_id = azurerm_subnet.endpoints[each.value].id
//
//  private_dns_zone_group {
//    name = "default"
//    private_dns_zone_ids = [
//      azurerm_private_dns_zone.dns["servicebus"].id,
//    ]
//  }
//
//  private_service_connection {
//    name                           = format("pe-%s-namespace", azurerm_servicebus_namespace.sb[each.value].name)
//    private_connection_resource_id = azurerm_servicebus_namespace.sb[each.value].id
//    subresource_names              = ["namespace"]
//    is_manual_connection           = false
//  }
//}

resource "azurerm_servicebus_queue" "fcd01" {
  for_each = toset(var.locations)

  name         = "fcd01"
  namespace_id = azurerm_servicebus_namespace.sb[each.value].id
}

resource "azurerm_servicebus_queue" "vtb01" {
  for_each = toset(var.locations)

  name         = "vtb01"
  namespace_id = azurerm_servicebus_namespace.sb[each.value].id
}

resource "azurerm_servicebus_queue" "vtb02" {
  for_each = toset(var.locations)

  name         = "vtb02"
  namespace_id = azurerm_servicebus_namespace.sb[each.value].id
}

resource "azurerm_monitor_diagnostic_setting" "sb" {
  for_each = toset(var.locations)

  name = "diagnostic-to-log-analytics"

  target_resource_id         = azurerm_servicebus_namespace.sb[each.value].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  metric {
    category = "AllMetrics"
  }

  enabled_log {
    category = "OperationalLogs"
  }

  enabled_log {
    category = "VNetAndIPFilteringLogs"
  }

  enabled_log {
    category = "RuntimeAuditLogs"
  }

  enabled_log {
    category = "ApplicationMetricsLogs"
  }
}
