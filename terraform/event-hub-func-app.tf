resource "azurerm_eventhub_namespace_authorization_rule" "func" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name                = each.value.app_name
  namespace_name      = azurerm_eventhub_namespace.eh[each.value.location].name
  resource_group_name = azurerm_resource_group.eh[each.value.location].name

  listen = true
  send   = true
  manage = false
}

resource "azurerm_key_vault_secret" "func_eh" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name         = format("%s-%s", each.value.app_name, azurerm_eventhub_namespace.eh[each.value.location].name)
  value        = azurerm_eventhub_namespace_authorization_rule.func[each.key].primary_connection_string
  key_vault_id = azurerm_key_vault.kv[each.value.location].id

  depends_on = [
    azurerm_role_assignment.kv_sp,
  ]
}
