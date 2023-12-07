resource "azurerm_api_management_api" "funcapp_api" {
  for_each = { for each in local.func_apps_instances_apim : each.key => each if each.role == "bus" }

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
    content_value  = file(format("../ServiceBusApi.openapi_json.json"))
  }
}

resource "azurerm_api_management_api_policy" "funcapp_backend" {
  for_each = { for each in local.func_apps_instances_apim : each.key => each if each.role == "bus" }

  api_name            = azurerm_api_management_api.funcapp_api[each.key].name
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  xml_content = <<XML
<policies>
  <inbound>
      <base/>
      <set-backend-service backend-id="${azurerm_api_management_backend.funcapp_backend[each.key].name}" />
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

resource "azurerm_api_management_api_operation_policy" "vtb01_operation_policy" {
  for_each = { for each in local.func_apps_instances_apim : each.key => each if each.role == "bus" }

  api_name            = azurerm_api_management_api.funcapp_api[each.key].name
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name
  operation_id        = "PostVTB01"

  xml_content = <<XML
<policies>
  <inbound>
      <base/>
      <set-variable name="requestData" value="@((JObject)context.Request.Body.As<JObject>(preserveContent: true))" />
      <set-variable name="messageId" value="@(Guid.NewGuid().ToString())" />
      <set-header name="InterfaceId" exists-action="override">
          <value>ID_VTB01</value>
      </set-header>
      <set-header name="MessageId" exists-action="override">
          <value>@((string)context.Variables["messageId"])</value>
      </set-header>
      <set-header name="TollId" exists-action="override">
          <value>@((string)((JObject)context.Variables["requestData"])["TollId"])</value>
      </set-header>
      <set-header name="LicensePlate" exists-action="override">
          <value>@((string)((JObject)context.Variables["requestData"])["LicensePlate"])</value>
      </set-header>
      <trace source="API Management">
        <message>
          @{
              var requestBody = (JObject)context.Request.Body.As<JObject>(preserveContent: true);
              var tollId = requestBody["TollId"] != null ? (string)requestBody["TollId"] : "InvalidTollId";
              var licensePlate = requestBody["LicensePlate"] != null ? (string)requestBody["LicensePlate"] : "InvalidLicensePlate";
      
              var customDimensions = new Dictionary<string, string>() {
                  {"InterfaceId", "ID_VTB01"},
                  {"MessageId", (string)context.Variables["messageId"]},
                  {"TollId", tollId},
                  {"LicensePlate", licensePlate}
              };

              var json = new JObject();
              json.Add("OperationId", context.RequestId);
              json.Add("ServiceId", context.Deployment.ServiceId);
              json.Add("ServiceName", context.Deployment.ServiceName);
              json.Add("EventName", context.Operation.Name);
              json.Add("CustomDimensions", JObject.FromObject(customDimensions));
              return json.ToString();
          }
        </message>
        <metadata name="InterfaceId" value="ID_VTB01"/>
        <metadata name="MessageId" value="@((string)context.Variables["messageId"])"/>
        <metadata name="TollId" value="@((string)((JObject)context.Variables["requestData"])["TollId"])"/>
        <metadata name="LicensePlate" value="@((string)((JObject)context.Variables["requestData"])["LicensePlate"])"/>
      </trace>
  </inbound>
  <backend>
      <forward-request />
  </backend>
  <outbound>
    <base/>
    <set-header name="InterfaceId" exists-action="override">
        <value>ID_VTB01</value>
    </set-header>
    <set-header name="TollId" exists-action="override">
        <value>@((string)((JObject)context.Variables["requestData"])["TollId"])</value>
    </set-header>
    <set-header name="LicensePlate" exists-action="override">
        <value>@((string)((JObject)context.Variables["requestData"])["LicensePlate"])</value>
    </set-header>
  </outbound>
  <on-error />
</policies>
XML
}

resource "azurerm_api_management_api_operation_policy" "vtb02_operation_policy" {
  for_each = { for each in local.func_apps_instances_apim : each.key => each if each.role == "bus" }

  api_name            = azurerm_api_management_api.funcapp_api[each.key].name
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name
  operation_id        = "PostVTB02"

  xml_content = <<XML
<policies>
  <inbound>
      <base/>
      <set-variable name="requestData" value="@((JObject)context.Request.Body.As<JObject>(preserveContent: true))" />
      <set-variable name="messageId" value="@(Guid.NewGuid().ToString())" />
      <set-header name="InterfaceId" exists-action="override">
          <value>ID_VTB02</value>
      </set-header>
      <set-header name="MessageId" exists-action="override">
          <value>@((string)context.Variables["messageId"])</value>
      </set-header>
      <set-header name="TollId" exists-action="override">
          <value>@((string)((JObject)context.Variables["requestData"])["TollId"])</value>
      </set-header>
      <set-header name="LicensePlate" exists-action="override">
          <value>@((string)((JObject)context.Variables["requestData"])["LicensePlate"])</value>
      </set-header>
      <trace source="API Management">
        <message>
          @{
              var requestBody = (JObject)context.Request.Body.As<JObject>(preserveContent: true);
              var tollId = requestBody["TollId"] != null ? (string)requestBody["TollId"] : "InvalidTollId";
              var licensePlate = requestBody["LicensePlate"] != null ? (string)requestBody["LicensePlate"] : "InvalidLicensePlate";
      
              var customDimensions = new Dictionary<string, string>() {
                  {"InterfaceId", "ID_VTB02"},
                  {"MessageId", (string)context.Variables["messageId"]},
                  {"TollId", tollId},
                  {"LicensePlate", licensePlate}
              };

              var json = new JObject();
              json.Add("OperationId", context.RequestId);
              json.Add("ServiceId", context.Deployment.ServiceId);
              json.Add("ServiceName", context.Deployment.ServiceName);
              json.Add("EventName", context.Operation.Name);
              json.Add("CustomDimensions", JObject.FromObject(customDimensions));
              return json.ToString();
          }
        </message>
        <metadata name="InterfaceId" value="ID_VTB02"/>
        <metadata name="MessageId" value="@((string)context.Variables["messageId"])"/>
        <metadata name="TollId" value="@((string)((JObject)context.Variables["requestData"])["TollId"])"/>
        <metadata name="LicensePlate" value="@((string)((JObject)context.Variables["requestData"])["LicensePlate"])"/>
      </trace>
  </inbound>
  <backend>
      <forward-request />
  </backend>
  <outbound>
    <base/>
    <set-header name="InterfaceId" exists-action="override">
        <value>ID_VTB02</value>
    </set-header>
    <set-header name="TollId" exists-action="override">
        <value>@((string)((JObject)context.Variables["requestData"])["TollId"])</value>
    </set-header>
    <set-header name="LicensePlate" exists-action="override">
        <value>@((string)((JObject)context.Variables["requestData"])["LicensePlate"])</value>
    </set-header>
  </outbound>
  <on-error />
</policies>
XML
}

resource "azurerm_api_management_api_diagnostic" "funcapp_api_diagnostic" {
  for_each = { for each in local.func_apps_instances_apim : each.key => each if each.role == "bus" }

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

  frontend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
      "InterfaceId",
      "TollId",
      "LicensePlate"
    ]
  }

  frontend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
      "InterfaceId",
      "TollId",
      "LicensePlate"
    ]
  }

  backend_request {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "accept",
      "origin",
      "InterfaceId",
      "TollId",
      "LicensePlate"
    ]
  }

  backend_response {
    body_bytes = 32
    headers_to_log = [
      "content-type",
      "content-length",
      "origin",
      "InterfaceId",
      "TollId",
      "LicensePlate"
    ]
  }
}
