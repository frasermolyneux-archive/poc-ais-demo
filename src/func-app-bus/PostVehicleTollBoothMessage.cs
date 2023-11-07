using Company.Abstractions.Models;
using Company.Telemetry;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
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
        public string RunPostVehicleTollMessage([HttpTrigger] HttpRequest req, [FromBody] VehicleTollBoothData messageData, ILogger logger)
        {
            scopedTelemetryClient.SetAdditionalProperty("InterfaceId", "ID_VehicleTollBooth");

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

            return JsonConvert.SerializeObject(messageData);
        }
    }
}
