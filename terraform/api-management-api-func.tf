resource "azurerm_api_management_named_value" "funcapp_host_key_named_value" {
  for_each = toset(var.locations)

  name                = azurerm_key_vault_secret.functionapp_host_key[each.value].name
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  display_name = azurerm_key_vault_secret.functionapp_host_key[each.value].name

  secret = true

  value_from_key_vault {
    secret_id = azurerm_key_vault_secret.functionapp_host_key[each.value].id
  }

  depends_on = [
    azurerm_role_assignment.apim
  ]
}
