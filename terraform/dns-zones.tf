// Create the private DNS zones for the private link resources that the Function App and Storage will use
resource "azurerm_private_dns_zone" "azurewebsites" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.rg[var.primary_location].name
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg[var.primary_location].name
}

resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.rg[var.primary_location].name
}

resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.rg[var.primary_location].name
}

resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.rg[var.primary_location].name
}

resource "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg[var.primary_location].name
}

// Link the private DNS zones to the virtual network to enable private link DNS zone resolution
resource "azurerm_private_dns_zone_virtual_network_link" "azurewebsites" {
  for_each = toset(var.locations)

  name                  = format("link-azurewebsites-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  resource_group_name   = azurerm_resource_group.rg[var.primary_location].name
  private_dns_zone_name = azurerm_private_dns_zone.azurewebsites.name
  virtual_network_id    = azurerm_virtual_network.apps[each.value].id
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  for_each = toset(var.locations)

  name                  = format("link-blob-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  resource_group_name   = azurerm_resource_group.rg[var.primary_location].name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.apps[each.value].id
}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  for_each = toset(var.locations)

  name                  = format("link-table-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  resource_group_name   = azurerm_resource_group.rg[var.primary_location].name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.apps[each.value].id
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue" {
  for_each = toset(var.locations)

  name                  = format("link-queue-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  resource_group_name   = azurerm_resource_group.rg[var.primary_location].name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.apps[each.value].id
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  for_each = toset(var.locations)

  name                  = format("link-file-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  resource_group_name   = azurerm_resource_group.rg[var.primary_location].name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = azurerm_virtual_network.apps[each.value].id
}
