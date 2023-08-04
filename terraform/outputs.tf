locals {
  web_apps = [for web_app in azurerm_linux_web_app.app : {
    name                = web_app.name
    resource_group_name = web_app.resource_group_name
  }]

  func_apps = [
    for func_app in local.func_apps_instances : {
      role                = func_app.role
      name                = azurerm_linux_function_app.func[func_app.key].name
      resource_group_name = azurerm_linux_function_app.func[func_app.key].resource_group_name
    }
  ]

  logic_apps = [
    for logic_app in local.logic_apps_instances : {
      role                = logic_app.role
      name                = azurerm_logic_app_standard.logic[logic_app.key].name
      resource_group_name = azurerm_logic_app_standard.logic[logic_app.key].resource_group_name
    }
  ]
}

output "web_apps" {
  value = local.web_apps
}

output "func_apps" {
  value = local.func_apps
}

output "logic_apps" {
  value = local.logic_apps
}
