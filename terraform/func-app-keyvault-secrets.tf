resource "azurerm_key_vault_secret" "functionapp_host_key" {
  for_each = toset(var.locations)

  name  = format("%s-hostkey", azurerm_linux_function_app.func[each.value].name)
  value = data.azurerm_function_app_host_keys.func[each.value].primary_key

  key_vault_id = azurerm_key_vault.kv[each.value].id
}
