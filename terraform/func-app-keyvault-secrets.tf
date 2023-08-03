resource "azurerm_key_vault_secret" "functionapp_host_key" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name  = format("%s-hostkey", azurerm_linux_function_app.func[each].name)
  value = data.azurerm_function_app_host_keys.func[each].primary_key

  key_vault_id = azurerm_key_vault.kv[each.value.location].id
}
