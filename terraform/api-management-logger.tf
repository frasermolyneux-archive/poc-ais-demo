resource "azurerm_api_management_logger" "apim_ai_logger" {
  for_each = toset(var.locations)

  name = azurerm_application_insights.ai[each.value].name

  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_api_management.apim.resource_group_name

  resource_id = azurerm_application_insights.ai[each.value].id

  application_insights {
    instrumentation_key = azurerm_application_insights.ai[each.value].instrumentation_key
  }
}
