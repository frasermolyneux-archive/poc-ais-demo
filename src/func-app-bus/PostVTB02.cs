using Azure.Messaging.ServiceBus;
using Company.Abstractions.Models;
using Company.Functions.Bus.Extensions;
using Company.Telemetry;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Company.Functions.Bus
{
    public class PostVTB02
    {
        private readonly IConfiguration configuration;
        private readonly IScopedTelemetryClient scopedTelemetryClient;

        public PostVTB02(IConfiguration configuration, IScopedTelemetryClient scopedTelemetryClient)
        {
            this.configuration = configuration;
            this.scopedTelemetryClient = scopedTelemetryClient;
        }

        [FunctionName("PostVTB02")]
        public async Task<IActionResult> RunPostVTB02([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req, ILogger logger)
        {
            scopedTelemetryClient.SetAdditionalProperty("InterfaceId", "ID_VTB02");

            var messageId = req.Headers["MessageId"].FirstOrDefault() ?? Guid.NewGuid().ToString();
            scopedTelemetryClient.SetAdditionalProperty("MessageId", messageId);

            string requestBody = string.Empty;
            using (StreamReader streamReader = new StreamReader(req.Body))
            {
                requestBody = await streamReader.ReadToEndAsync();
            }

            VehicleTollBoothData? messageData;
            try
            {
                messageData = JsonConvert.DeserializeObject<VehicleTollBoothData>(requestBody);
            }
            catch (Exception ex)
            {
                logger.LogError($"Error deserializing vehicle toll booth event: {ex.Message}");
                throw;
            }

            if (messageData is null)
            {
                logger.LogError($"Unable to deserialize vehicle toll booth event: {requestBody}");
                throw new Exception("Unable to deserialize vehicle toll booth event");
            }

            var messageCustomDimensions = new Dictionary<string, string>()
            {
                {"MessageId", messageId},
                {"TollId", messageData.TollId.ToString()},
                {"LicensePlate", messageData.LicensePlate},
                {"Tag", messageData.Tag.ToString()}
            };

            scopedTelemetryClient.SetAdditionalProperties(messageCustomDimensions);

            logger.LogInformation($"Vehicle with licence plate {messageData.LicensePlate} has passed through toll {messageData.TollId}");

            await using (var client = new ServiceBusClient(configuration["servicebus_connection_string"]))
            {
                var sender = client.CreateSender("vtb02");
                await sender.SendMessageAsync(new ServiceBusMessage(JsonConvert.SerializeObject(messageData))
                {
                    MessageId = messageCustomDimensions["MessageId"]
                }.WithCustomProperties(messageCustomDimensions));

                EventTelemetry eventTelemetry = new EventTelemetry("VTB02_InInterface");
                scopedTelemetryClient.TrackEvent(eventTelemetry);
            };

            return new OkResult();
        }
    }
}
