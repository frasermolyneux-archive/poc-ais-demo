resource "azurerm_servicebus_namespace_authorization_rule" "logic" {
  for_each = toset(var.locations)

  name         = azurerm_logic_app_standard.logic[each.value].name
  namespace_id = azurerm_servicebus_namespace.sb[each.value].id

  listen = true
  send   = true
  manage = false
}

resource "azurerm_key_vault_secret" "logic_sb" {
  for_each = toset(var.locations)

  name         = format("%s-%s", azurerm_logic_app_standard.logic[each.value].name, azurerm_servicebus_namespace.sb[each.value].name)
  value        = azurerm_servicebus_namespace_authorization_rule.logic[each.value].primary_connection_string
  key_vault_id = azurerm_key_vault.kv[each.value].id

  depends_on = [
    azurerm_role_assignment.kv_sp,
  ]
}
