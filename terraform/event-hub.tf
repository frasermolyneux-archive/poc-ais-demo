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

  sku      = "Premium"
  capacity = 1
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
