using Azure.Messaging.ServiceBus;
using Company.Abstractions.Models;
using Company.Functions.Sub.Extensions;
using Company.Telemetry;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Company.Functions.Sub
{
    public class ID_VTB01
    {
        private readonly IConfiguration configuration;
        private readonly IScopedTelemetryClient scopedTelemetryClient;

        public ID_VTB01(IConfiguration configuration, IScopedTelemetryClient scopedTelemetryClient)
        {
            this.configuration = configuration;
            this.scopedTelemetryClient = scopedTelemetryClient;
        }

        [FunctionName("ID_VTB01")]
        public async Task RunID_VTB01([ServiceBusTrigger("vtb01", Connection = "servicebus_connection_string")] ServiceBusReceivedMessage myQueueItem, Int32 deliveryCount, DateTime enqueuedTimeUtc, string messageId, ILogger logger)
        {
            scopedTelemetryClient.SetAdditionalProperty("InterfaceId", "ID_VTB01");

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
                {"TollId", myQueueItem.ApplicationProperties["TollId"].ToString() ?? "FailedToGetFromApplicationProperties"},
                {"LicensePlate", myQueueItem.ApplicationProperties["LicensePlate"].ToString() ?? "FailedToGetFromApplicationProperties"}
            };

            scopedTelemetryClient.SetAdditionalProperties(messageCustomDimensions);

            var operation = scopedTelemetryClient.Client.StartOperation<DependencyTelemetry>("VTB01_CustomDependency");
            operation.Telemetry.Type = "HTTP";
            try
            {
                EventTelemetry eventTelemetry = new EventTelemetry("VTB01_Processed");
                scopedTelemetryClient.TrackEvent(eventTelemetry);
            }
            catch (Exception e)
            {
                scopedTelemetryClient.Client.TrackException(e);
                throw;
            }
            finally
            {
                scopedTelemetryClient.Client.StopOperation(operation);
            }
        }
    }
}