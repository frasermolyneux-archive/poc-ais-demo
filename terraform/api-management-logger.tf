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

resource "azurerm_api_management_logger" "apim_eh_logger" {
  for_each = toset(var.locations)

  name = azurerm_eventhub_namespace.eh[each.value].name

  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_api_management.apim.resource_group_name

  resource_id = azurerm_eventhub_namespace.eh[each.value].id

  eventhub {
    name              = azurerm_eventhub.appinsights_custom_events[each.value].name
    connection_string = azurerm_eventhub_authorization_rule.appinsights_custom_events_apim[each.value].primary_connection_string
  }
}
