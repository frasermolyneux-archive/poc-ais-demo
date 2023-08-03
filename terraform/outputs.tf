locals {
  web_apps = [for web_app in azurerm_linux_web_app.app : {
    name                = web_app.name
    resource_group_name = web_app.resource_group_name
  }]

  logic_apps = [for logic_app in azurerm_logic_app_standard.logic : {
    name                = logic_app.name
    resource_group_name = logic_app.resource_group_name
  }]
}

output "web_apps" {
  value = local.web_apps
}

output "func_apps" {
  for_each = { for role in var.func_app_roles : each.key => each }

  value = [for each in local.func_apps : {
    name                = azurerm_linux_function_app.func[each].name
    resource_group_name = azurerm_linux_function_app.func[each].resource_group_name
  } if each.value.role == each]
}

output "logic_apps" {
  value = local.logic_apps
}
