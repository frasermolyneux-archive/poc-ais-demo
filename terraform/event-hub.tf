resource "azurerm_resource_group" "eh" {
  for_each = toset(var.locations)

  name     = format("rg-eh-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_eventhub_namespace" "eh" {
  for_each = toset(var.locations)

  name = format("eh-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.eh[each.value].name
  location            = azurerm_resource_group.eh[each.value].location

  tags = var.tags

  zone_redundant = true

  sku      = "Premium"
  capacity = 1

  public_network_access_enabled = true

  network_rulesets = [
    {
      default_action                 = "Allow"
      ip_rule                        = []
      public_network_access_enabled  = true
      trusted_service_access_enabled = true
      virtual_network_rule           = []
    }
  ]

}

resource "azurerm_private_endpoint" "eh" {
  for_each = toset(var.locations)

  name = format("pe-%s-servicebus", azurerm_eventhub_namespace.eh[each.value].name)

  resource_group_name = azurerm_resource_group.eh[each.value].name
  location            = azurerm_resource_group.eh[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["servicebus"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-namespace", azurerm_eventhub_namespace.eh[each.value].name)
    private_connection_resource_id = azurerm_eventhub_namespace.eh[each.value].id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }
}

resource "azurerm_eventhub" "eh_business_notifications" {
  for_each = toset(var.locations)

  name = "business-notifications"

  namespace_name      = azurerm_eventhub_namespace.eh[each.value].name
  resource_group_name = azurerm_resource_group.eh[each.value].name

  partition_count   = 2
  message_retention = 1
}

resource "azurerm_eventhub" "eh_business_notifications_batch" {
  for_each = toset(var.locations)

  name = "business-notifications-batch"

  namespace_name      = azurerm_eventhub_namespace.eh[each.value].name
  resource_group_name = azurerm_resource_group.eh[each.value].name

  partition_count   = 2
  message_retention = 1
}

resource "azurerm_eventhub" "eh_fraud_call_detection" {
  for_each = toset(var.locations)

  name = "fraud-call-detection"

  namespace_name      = azurerm_eventhub_namespace.eh[each.value].name
  resource_group_name = azurerm_resource_group.eh[each.value].name

  partition_count   = 2
  message_retention = 1
}
