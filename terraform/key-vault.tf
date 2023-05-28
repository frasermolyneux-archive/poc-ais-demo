resource "azurerm_resource_group" "kv" {
  for_each = toset(var.locations)

  name     = format("rg-kv-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_key_vault" "kv" {
  for_each = toset(var.locations)

  name                = format("kv%s%s", lower(random_string.location[each.value].result), var.environment)
  location            = azurerm_resource_group.kv[each.value].location
  resource_group_name = azurerm_resource_group.kv[each.value].name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  soft_delete_retention_days = 7

  enable_rbac_authorization = true
  purge_protection_enabled  = true

  sku_name = "standard"

  // Public access enabled for deployment and demo purposes - should be disabled in production
  public_network_access_enabled = true
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_role_assignment" "kv_sp" {
  for_each = toset(var.locations)

  scope                = azurerm_key_vault.kv[each.value].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_demo" {
  for_each = toset(var.locations)

  scope                = azurerm_key_vault.kv[each.value].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = "3270dd31-29ac-486d-8a16-e9179660c8d7"
}

resource "azurerm_role_assignment" "app" {
  for_each = toset(var.locations)

  scope                = azurerm_key_vault.kv[each.value].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app[each.value].identity[0].principal_id
}

resource "azurerm_role_assignment" "func" {
  for_each = toset(var.locations)

  scope                = azurerm_key_vault.kv[each.value].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.func[each.value].identity[0].principal_id
}

resource "azurerm_role_assignment" "logic" {
  for_each = toset(var.locations)

  scope                = azurerm_key_vault.kv[each.value].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_logic_app_standard.logic[each.value].identity[0].principal_id
}

resource "azurerm_key_vault_secret" "kv_example" {
  for_each = toset(var.locations)

  name         = "my-super-secret"
  value        = random_string.location[each.value].result
  key_vault_id = azurerm_key_vault.kv[each.value].id

  depends_on = [
    azurerm_role_assignment.kv_sp
  ]
}

resource "azurerm_private_endpoint" "kv" {
  for_each = toset(var.locations)

  name = format("pe-%s-vault", azurerm_key_vault.kv[each.value].name)

  resource_group_name = azurerm_resource_group.kv[each.value].name
  location            = azurerm_resource_group.kv[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["vault"].id
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-vault", azurerm_key_vault.kv[each.value].name)
    private_connection_resource_id = azurerm_key_vault.kv[each.value].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}
