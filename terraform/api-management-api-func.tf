resource "azurerm_api_management_named_value" "funcapp_host_key_named_value" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name = azurerm_key_vault_secret.functionapp_host_key[each.key].name

  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  display_name = azurerm_key_vault_secret.functionapp_host_key[each.key].name

  secret = true

  value_from_key_vault {
    secret_id = azurerm_key_vault_secret.functionapp_host_key[each.key].id
  }

  depends_on = [
    azurerm_role_assignment.apim
  ]
}

resource "azurerm_api_management_backend" "funcapp_backend" {
  for_each = { for each in local.func_apps_instances : each.key => each }

  name = each.key

  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  protocol    = "http"
  title       = each.key
  description = each.key
  url         = format("https://%s/api", azurerm_linux_function_app.func[each.key].default_hostname)

  tls {
    validate_certificate_chain = true
    validate_certificate_name  = true
  }

  credentials {
    query = {
      "code" = format("{{${azurerm_api_management_named_value.funcapp_host_key_named_value[each.key].name}}}")
    }
  }
}

resource "azurerm_api_management_api" "bus_api" {
  for_each = { for each in local.func_apps_instances : each.key => each if each.role == "bus" }

  name = "servicebus-api"

  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  revision     = "1"
  display_name = "Service Bus API"
  description  = "API for Service Bus via Function App"
  path         = "servicebus-api"
  protocols    = ["https"]

  subscription_required = true

  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file("../ServiceBusApi.openapi_json.json")
  }
}

resource "azurerm_api_management_api_diagnostic" "bus_api_diagnostic" {
  for_each = { for each in local.func_apps_instances : each.key => each if each.role == "bus" }

  identifier = "applicationinsights"

  api_name = azurerm_api_management_api.bus_api[each.key].name

  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  api_management_logger_id = azurerm_api_management_logger.apim_ai_logger[each.value.location].id

  sampling_percentage = 100

  always_log_errors = true
  log_client_ip     = true

  verbosity = "information"

  http_correlation_protocol = "W3C"
}
