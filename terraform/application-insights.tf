resource "azurerm_resource_group" "ai" {
  for_each = toset(var.locations)

  name     = format("rg-ai-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_application_insights" "ai" {
  for_each = toset(var.locations)

  name = format("ai-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.ai[each.value].name
  location            = azurerm_resource_group.ai[each.value].location

  workspace_id = azurerm_log_analytics_workspace.law.id

  application_type = "web"
}