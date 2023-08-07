resource "azurerm_servicebus_namespace_authorization_rule" "func" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name         = each.value.app_name
  namespace_id = azurerm_servicebus_namespace.sb[each.value.location].id

  listen = true
  send   = true
  manage = false
}

resource "azurerm_key_vault_secret" "func_sb" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name         = format("%s-%s", each.value.app_name, azurerm_servicebus_namespace.sb[each.value.location].name)
  value        = azurerm_servicebus_namespace_authorization_rule.func[each.key].primary_connection_string
  key_vault_id = azurerm_key_vault.kv[each.value.location].id

  depends_on = [
    azurerm_role_assignment.kv_sp,
  ]
}
