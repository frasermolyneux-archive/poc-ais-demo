locals {
  web_apps = [for web_app in azurerm_linux_web_app.app : {
    name                = web_app.name
    resource_group_name = web_app.resource_group_name
  }]

  func_apps = [
    for role in var.func_app_roles : {
      key = role
      instances = [for func_app in local.func_apps_instances : {
        name                = azurerm_linux_function_app.func[func_app.key].name
        resource_group_name = azurerm_linux_function_app.func[func_app.key].resource_group_name
      } if func_app.role == role]
    }
  ]

  func_app_map = { for item in local.func_apps :
    keys(item)[0] => values(item)[0]
  }

  logic_apps = [for logic_app in azurerm_logic_app_standard.logic : {
    name                = logic_app.name
    resource_group_name = logic_app.resource_group_name
  }]
}

output "web_apps" {
  value = local.web_apps
}

output "func_apps" {
  value = local.func_app_map
}

output "logic_apps" {
  value = local.logic_apps
}
