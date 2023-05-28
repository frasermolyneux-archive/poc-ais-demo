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

  sku      = "Premium"
  capacity = 1

  public_network_access_enabled = false
  minimum_tls_version           = "1.2"
}

resource "azurerm_private_endpoint" "sb" {
  for_each = toset(var.locations)

  name = format("pe-%s-servicebus", azurerm_servicebus_namespace.sb[each.value].name)

  resource_group_name = azurerm_resource_group.sb[each.value].name
  location            = azurerm_resource_group.sb[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["servicebus"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-namespace", azurerm_servicebus_namespace.sb[each.value].name)
    private_connection_resource_id = azurerm_servicebus_namespace.sb[each.value].id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }
}

resource "azurerm_servicebus_queue" "random_queue" {
  for_each = toset(var.locations)

  name         = "random_queue"
  namespace_id = azurerm_servicebus_namespace.sb[each.value].id
}

resource "azurerm_servicebus_queue" "random_queue" {
  for_each = toset(var.locations)

  name         = "from_website"
  namespace_id = azurerm_servicebus_namespace.sb[each.value].id
}
