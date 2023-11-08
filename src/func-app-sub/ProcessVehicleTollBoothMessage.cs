using Azure.Messaging.ServiceBus;
using Company.Abstractions.Models;
using Company.Functions.Sub.Extensions;
using Company.Telemetry;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Company.Functions.Sub
{
    public class ProcessVehicleTollBoothMessage
    {
        private readonly IConfiguration configuration;
        private readonly IScopedTelemetryClient scopedTelemetryClient;

        public ProcessVehicleTollBoothMessage(IConfiguration configuration, IScopedTelemetryClient scopedTelemetryClient)
        {
            this.configuration = configuration;
            this.scopedTelemetryClient = scopedTelemetryClient;
        }

        [FunctionName("ProcessVehicleTollBoothMessage")]
        public async Task RunProcessVehicleTollBoothMessage([ServiceBusTrigger("vehicle_toll_booth", Connection = "servicebus_connection_string")] ServiceBusReceivedMessage myQueueItem, Int32 deliveryCount, DateTime enqueuedTimeUtc, string messageId, ILogger logger)
        {
            scopedTelemetryClient.SetAdditionalProperty("InterfaceId", "ID_VehicleTollBooth");

            VehicleTollBoothData? messageData;
            try
            {
                messageData = JsonConvert.DeserializeObject<VehicleTollBoothData>(myQueueItem.Body.ToString());
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
                        {"MessageId", myQueueItem.MessageId},
                        {"TollId", messageData.TollId.ToString()},
                        {"LicensePlate", messageData.LicensePlate}
                    };

            scopedTelemetryClient.SetAdditionalProperties(messageCustomDimensions);

            EventTelemetry eventTelemetry = new EventTelemetry("VehicleTollBoothMessageProcessed");
            scopedTelemetryClient.TrackEvent(eventTelemetry);
        }
    }
}