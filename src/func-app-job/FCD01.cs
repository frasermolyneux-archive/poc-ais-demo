using Company.Abstractions.Models;
using Company.Telemetry;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Company.Functions.Job
{
    public class FCD01
    {
        private readonly IScopedTelemetryClient scopedTelemetryClient;

        public FCD01(IScopedTelemetryClient scopedTelemetryClient)
        {
            this.scopedTelemetryClient = scopedTelemetryClient;
        }

        [FunctionName("FCD01_Transform")]
        public async Task<IActionResult> RunFCD01_Transform([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req, ILogger logger)
        {
            var messageId = req.Headers["x-ms-client-tracking-id"];
            scopedTelemetryClient.SetAdditionalProperty("InterfaceId", "ID_FCD01");
            scopedTelemetryClient.SetAdditionalProperty("MessageId", messageId);

            string requestBody = string.Empty;
            using (StreamReader streamReader = new(req.Body))
            {
                requestBody = await streamReader.ReadToEndAsync();
            }

            FraudCallDetetectionData? messageData;
            try
            {
                messageData = JsonConvert.DeserializeObject<FraudCallDetetectionData>(requestBody);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Exception deserializing input");
                throw;
            }

            if (messageData == null)
            {
                var customException = new Exception("Message was null after deserialization attempt");
                logger.LogError(customException, "Message was null after deserialization attempt");
                throw customException;
            }

            var messageCustomDimensions = new Dictionary<string, string>()
                {
                    {"CallingIMSI", messageData.CallingIMSI},
                    {"CalledIMSI", messageData.CalledIMSI},
                    {"MSRN", messageData.MSRN}
                };

            scopedTelemetryClient.SetAdditionalProperties(messageCustomDimensions);

            var originalServiceType = messageData.ServiceType;
            switch (originalServiceType)
            {
                case "b":
                    messageData.ServiceType = "Bravo";
                    break;
                case "V":
                    messageData.ServiceType = "Victor";
                    break;
                case "S":
                    messageData.ServiceType = "Sierra";
                    break;
                default:
                    break;
            }

            if (originalServiceType != messageData.ServiceType)
            {
                logger.LogInformation($"Service type has changed from {originalServiceType} to {messageData.ServiceType}");
            }
            else
            {
                logger.LogInformation("Service type has been left with the original value");
            }

            EventTelemetry eventTelemetry = new EventTelemetry("FCD01_Transformed");
            scopedTelemetryClient.TrackEvent(eventTelemetry);

            return new OkObjectResult(messageData);
        }
    }
}
