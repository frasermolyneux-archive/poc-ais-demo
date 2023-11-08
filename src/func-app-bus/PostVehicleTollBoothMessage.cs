using Azure.Messaging.ServiceBus;
using Company.Abstractions.Models;
using Company.Functions.Bus.Extensions;
using Company.Telemetry;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Company.Functions.Bus
{
    public class PostVehicleTollBoothMessage
    {
        private readonly IScopedTelemetryClient scopedTelemetryClient;

        public PostVehicleTollBoothMessage(IScopedTelemetryClient scopedTelemetryClient)
        {
            this.scopedTelemetryClient = scopedTelemetryClient;
        }

        [FunctionName("PostVehicleTollBoothMessage")]
        [return: ServiceBus("vehicle_toll_booth", Connection = "servicebus_connection_string")]
        public async Task<ServiceBusMessage> RunPostVehicleTollMessage([HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req, ILogger logger)
        {
            scopedTelemetryClient.SetAdditionalProperty("InterfaceId", "ID_VehicleTollBooth");

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

            EventTelemetry eventTelemetry = new EventTelemetry("VehicleTollBoothInInterface");
            scopedTelemetryClient.TrackEvent(eventTelemetry);

            var message = new ServiceBusMessage(JsonConvert.SerializeObject(messageData))
            {
                MessageId = messageCustomDimensions["MessageId"]
            }.WithCustomProperties(messageCustomDimensions);

            return message;
        }
    }
}
