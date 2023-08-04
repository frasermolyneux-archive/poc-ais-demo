locals {
  web_apps = [for web_app in azurerm_linux_web_app.app : {
    name                = web_app.name
    resource_group_name = web_app.resource_group_name
  }]

  //func_apps = [
  //  for role in var.func_app_roles : {
  //    key = role
  //    instances = [for func_app in local.func_apps_instances : {
  //      name                = azurerm_linux_function_app.func[func_app.key].name
  //      resource_group_name = azurerm_linux_function_app.func[func_app.key].resource_group_name
  //    } if func_app.role == role]
  //  }
  //]

  func_apps = [
    for func_app in local.func_apps_instances : {
      role                = func_app.role
      name                = azurerm_linux_function_app.func[func_app.key].name
      resource_group_name = azurerm_linux_function_app.func[func_app.key].resource_group_name
    }
  ]

  //logic_apps = [
  //  for role in var.logic_app_roles : {
  //    key = role
  //    instances = [for logic_app in local.logic_apps_instances : {
  //      name                = azurerm_logic_app_standard.logic[logic_app.key].name
  //      resource_group_name = azurerm_logic_app_standard.logic[logic_app.key].resource_group_name
  //    } if logic_app.role == role]
  //  }
  //]

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
  //value = { for item in local.func_apps : "${item.key}" => item }
  value = local.func_apps
}

output "logic_apps" {
  //value = { for item in local.logic_apps : "${item.key}" => item }
  value = local.logic_apps
}
