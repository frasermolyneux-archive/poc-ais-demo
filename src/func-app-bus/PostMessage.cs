using Company.Abstractions.Models;
using Company.Telemetry;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Company.Functions.Bus
{
    public class PostMessage
    {
        private readonly IScopedTelemetryClient scopedTelemetryClient;

        public PostMessage(IScopedTelemetryClient scopedTelemetryClient)
        {
            this.scopedTelemetryClient = scopedTelemetryClient;
        }

        [FunctionName("PostVehicleTollBoothMessage")]
        [return: ServiceBus("vehicle_toll_booth", Connection = "servicebus_connection_string")]
        public string RunPostVehicleTollMessage([HttpTrigger] dynamic input, ILogger logger)
        {
            scopedTelemetryClient.SetAdditionalProperty("InterfaceId", "ID_VehicleTollBooth");

            VehicleTollBoothData? messageData;
            try
            {
                messageData = JsonConvert.DeserializeObject<VehicleTollBoothData>(input);
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
                    {"TollId", messageData.TollId.ToString()},
                    {"LicensePlate", messageData.LicensePlate},
                    {"Tag", messageData.Tag.ToString()}
            };

            scopedTelemetryClient.SetAdditionalProperties(messageCustomDimensions);

            logger.LogInformation($"Vehicle with licence plate {messageData.LicensePlate} has passed through toll {messageData.TollId}");

            EventTelemetry eventTelemetry = new EventTelemetry("VehicleTollBoothInInterface");
            scopedTelemetryClient.TrackEvent(eventTelemetry);

            return input.Text;
        }
    }
}
