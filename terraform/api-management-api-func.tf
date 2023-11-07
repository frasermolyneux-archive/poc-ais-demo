locals {
  func_apps_instances_apim = flatten([
    for location in var.locations : [
      for func_app in var.function_apps : {
        key                 = format("fa-%s-%s-%s", func_app.role, var.environment, location)
        app_name            = format("fa-%s-%s-%s-%s", func_app.role, random_id.environment_id.hex, var.environment, location)
        location            = location
        apim_api_definition = func_app.apim_api_definition
      } if func_app.link_to_apim == true
    ]
  ])
}


resource "azurerm_api_management_named_value" "funcapp_host_key_named_value" {
  for_each = { for each in local.func_apps_instances_apim : each.key => each }

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
  for_each = { for each in local.func_apps_instances_apim : each.key => each }

  name = each.value.app_name

  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  protocol    = "http"
  title       = each.value.app_name
  description = each.value.app_name
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

resource "azurerm_api_management_api" "funcapp_api" {
  for_each = { for each in local.func_apps_instances_apim : each.key => each }

  name = each.value.app_name

  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  revision     = "1"
  display_name = each.value.app_name
  description  = each.value.app_name
  path         = each.value.app_name
  protocols    = ["https"]

  subscription_required = true

  subscription_key_parameter_names {
    header = "Ocp-Apim-Subscription-Key"
    query  = "subscription-key"
  }

  import {
    content_format = "openapi+json"
    content_value  = file(format("../%s", each.value.apim_api_definition))
  }
}

resource "azurerm_api_management_api_policy" "funcapp_backend" {
  for_each = { for each in local.func_apps_instances_apim : each.key => each }

  api_name            = azurerm_api_management_api.funcapp_api[each.key].name
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  xml_content = <<XML
<policies>
  <inbound>
      <base/>
      <set-backend-service backend-id="${azurerm_api_management_backend.funcapp_backend[each.key].name}" />
      <log-to-eventhub logger-id="${azurerm_api_management_logger.apim_eh_logger[each.value.location].name}">
        @{
            return new JObject(
                new JProperty("EventName", context.Operation.Name),
                new JProperty("AdditionalProperties", new Dictionary<string, string>(){
                  {"EventTime", DateTime.UtcNow.ToString()},
                  {"ServiceName", context.Deployment.ServiceName}
                })
            ).ToString();
        }
      </log-to-eventhub>
  </inbound>
  <backend>
      <forward-request />
  </backend>
  <outbound>
      <base/>
  </outbound>
  <on-error />
</policies>
XML
}

resource "azurerm_api_management_api_diagnostic" "funcapp_api_diagnostic" {
  for_each = { for each in local.func_apps_instances_apim : each.key => each }

  identifier = "applicationinsights"

  api_name = azurerm_api_management_api.funcapp_api[each.key].name

  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  api_management_logger_id = azurerm_api_management_logger.apim_ai_logger[each.value.location].id

  sampling_percentage = 100

  always_log_errors = true
  log_client_ip     = true

  verbosity = "information"

  http_correlation_protocol = "W3C"
}
