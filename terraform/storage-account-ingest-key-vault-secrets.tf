resource "azurerm_key_vault_secret" "ingest_connection_string" {
  for_each = toset(var.locations)

  name  = format("%s-connectionstring", azurerm_storage_account.ingest.name)
  value = azurerm_storage_account.ingest.primary_connection_string

  key_vault_id = azurerm_key_vault.kv[each.value].id
}
