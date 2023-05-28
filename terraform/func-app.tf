resource "azurerm_resource_group" "func" {
  for_each = toset(var.locations)

  name     = format("rg-func-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)
  location = each.value

  tags = var.tags
}

resource "azurerm_service_plan" "func" {
  for_each = toset(var.locations)

  name = format("sp-func-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.func[each.value].name
  location            = azurerm_resource_group.func[each.value].location

  os_type  = "Linux"
  sku_name = "P1v2"
}

resource "azurerm_monitor_diagnostic_setting" "func_svcplan" {
  for_each = toset(var.locations)

  name = azurerm_log_analytics_workspace.law.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  target_resource_id = azurerm_service_plan.func[each.value].id

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_storage_account" "func" {
  for_each = toset(var.locations)

  name = format("safn%s", lower(random_string.location[each.value].result))

  resource_group_name = azurerm_resource_group.func[each.value].name
  location            = azurerm_resource_group.func[each.value].location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "func_sa_blob_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-blob", azurerm_storage_account.func[each.value].name)

  resource_group_name = azurerm_resource_group.func[each.value].name
  location            = azurerm_resource_group.func[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["blob"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-blob", azurerm_storage_account.func[each.value].name)
    private_connection_resource_id = azurerm_storage_account.func[each.value].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "func_sa_table_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-table", azurerm_storage_account.func[each.value].name)

  resource_group_name = azurerm_resource_group.func[each.value].name
  location            = azurerm_resource_group.func[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["table"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-table", azurerm_storage_account.func[each.value].name)
    private_connection_resource_id = azurerm_storage_account.func[each.value].id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "func_sa_queue_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-queue", azurerm_storage_account.func[each.value].name)

  resource_group_name = azurerm_resource_group.func[each.value].name
  location            = azurerm_resource_group.func[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["queue"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-queue", azurerm_storage_account.func[each.value].name)
    private_connection_resource_id = azurerm_storage_account.func[each.value].id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_endpoint" "func_sa_file_pe" {
  for_each = toset(var.locations)

  name = format("pe-%s-file", azurerm_storage_account.func[each.value].name)

  resource_group_name = azurerm_resource_group.func[each.value].name
  location            = azurerm_resource_group.func[each.value].location

  subnet_id = azurerm_subnet.endpoints[each.value].id

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      azurerm_private_dns_zone.dns["file"].id,
    ]
  }

  private_service_connection {
    name                           = format("pe-%s-file", azurerm_storage_account.func[each.value].name)
    private_connection_resource_id = azurerm_storage_account.func[each.value].id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

resource "azurerm_linux_function_app" "func" {
  for_each = toset(var.locations)

  name = format("fa-%s-%s-%s", random_id.environment_id.hex, var.environment, each.value)

  resource_group_name = azurerm_resource_group.func[each.value].name
  location            = azurerm_resource_group.func[each.value].location

  storage_account_name       = azurerm_storage_account.func[each.value].name
  storage_account_access_key = azurerm_storage_account.func[each.value].primary_access_key
  service_plan_id            = azurerm_service_plan.func[each.value].id

  virtual_network_subnet_id = azurerm_subnet.app_01[each.value].id

  site_config {
    vnet_route_all_enabled = true

    application_stack {
      dotnet_version = "7.0"
    }
  }

  // This is required to prevent the `WEBSITE_CONTENTSHARE` and `WEBSITE_CONTENTAZUREFILECONNECTIONSTRING` being added as these app settings aren't required for Linux apps on Elastic Premium.
  content_share_force_disabled = true

  app_settings = {
    https_only = true
  }

  depends_on = [
    azurerm_private_endpoint.func_sa_blob_pe,
    azurerm_private_endpoint.func_sa_table_pe,
    azurerm_private_endpoint.func_sa_queue_pe,
    azurerm_private_endpoint.func_sa_file_pe
  ]
}
