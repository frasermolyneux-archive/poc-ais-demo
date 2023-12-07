locals {
  func_apps_instances_apim = flatten([
    for location in var.locations : [
      for func_app in var.function_apps : {
        key                 = format("fa-%s-%s-%s", func_app.role, var.environment, location)
        app_name            = format("fa-%s-%s-%s-%s", func_app.role, random_id.environment_id.hex, var.environment, location)
        location            = location
        role                = func_app.role
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
