resource "azurerm_servicebus_namespace_authorization_rule" "func" {
  for_each = toset(var.locations)

  name         = azurerm_linux_function_app.func[each.value].name
  namespace_id = azurerm_servicebus_namespace.sb[each.value].id

  listen = true
  send   = true
  manage = false
}

resource "azurerm_key_vault_secret" "func_sb" {
  for_each = toset(var.locations)

  name         = format("%s-%s", azurerm_linux_function_app.func[each.value].name, azurerm_servicebus_namespace.sb[each.value].name)
  value        = azurerm_servicebus_namespace_authorization_rule.func[each.value].primary_connection_string
  key_vault_id = azurerm_key_vault.kv[each.value].id

  depends_on = [
    azurerm_role_assignment.kv_sp,
  ]
}
