resource "azurerm_eventhub_authorization_rule" "func" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name           = azurerm_linux_function_app.func[each.key].name
  namespace_name = azurerm_eventhub_namespace.ech[each.value.location].name

  eventhub_name       = azurerm_eventhub.eh_business_notifications[each.value.location].name
  resource_group_name = azurerm_resource_group.eh[each.value.location].name

  listen = true
  send   = false
  manage = false
}

resource "azurerm_key_vault_secret" "func_eh" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name         = format("%s-%s", azurerm_linux_function_app.func[each.key].name, azurerm_eventhub.eh_business_notifications[each.value.location].name)
  value        = azurerm_eventhub_authorization_rule.func[each.key].primary_connection_string
  key_vault_id = azurerm_key_vault.kv[each.value.location].id

  depends_on = [
    azurerm_role_assignment.kv_sp,
  ]
}
