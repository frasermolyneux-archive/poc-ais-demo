resource "azurerm_servicebus_namespace_authorization_rule" "logic" {
  for_each = { for each in local.logic_apps_instances : each.key => each }

  name         = azurerm_logic_app_standard.logic[each.key].name
  namespace_id = azurerm_servicebus_namespace.sb[each.value.location].id

  listen = true
  send   = true
  manage = false
}

resource "azurerm_key_vault_secret" "logic_sb" {
  for_each = { for each in local.logic_apps_instances : each.key => each }

  name         = format("%s-%s", azurerm_logic_app_standard.logic[each.key].name, azurerm_servicebus_namespace.sb[each.value].name)
  value        = azurerm_servicebus_namespace_authorization_rule.logic[each.key].primary_connection_string
  key_vault_id = azurerm_key_vault.kv[each.value.location].id

  depends_on = [
    azurerm_role_assignment.kv_sp,
  ]
}
