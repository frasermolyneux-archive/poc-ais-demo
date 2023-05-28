locals {
  web_apps = [for web_app in azurerm_linux_web_app.app : {
    name                = web_app.name
    resource_group_name = web_app.resource_group_name
  }]

  func_apps = [for func_app in azurerm_linux_function_app.func : {
    name                = func_app.name
    resource_group_name = func_app.resource_group_name
  }]
}

output "web_apps" {
  value = local.web_apps
}

output "func_apps" {
  value = local.func_apps
}
