using Azure.Messaging.ServiceBus;
using Company.Abstractions.Models;
using func_app_sub.Extensions;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using System.Diagnostics;

namespace func_app_sub
{
    public class FraudCallDetection
    {
        private readonly IConfiguration configuration;
        private readonly TelemetryClient telemetryClient;

        public FraudCallDetection(IConfiguration configuration, TelemetryConfiguration telemetryConfiguration)
        {
            this.configuration = configuration;
            this.telemetryClient = new TelemetryClient(telemetryConfiguration);
        }

        [Function("FraudCallDetection")]
        public async Task RunFraudCallDetection([EventHubTrigger("fraud-call-detection", Connection = "eventhub_connection_string", IsBatched = false)] string input)
        {
            var customDimensions = new Dictionary<string, string>()
            {
                {"InterfaceId", "ID_FraudCallDetection"}
            };

            FraudCallDetetectionData? messageData;
            try
            {
                messageData = JsonConvert.DeserializeObject<FraudCallDetetectionData>(input);
            }
            catch (Exception ex)
            {
                telemetryClient.TrackException(new ExceptionTelemetry(ex).WithCustomProperties(customDimensions));
                throw;
            }

            if (messageData == null)
            {
                var customException = new Exception("Message was null after deserialization attempt");
                telemetryClient.TrackException(customException, customDimensions);
                throw customException;
            }

            var messageCustomDimensions = new Dictionary<string, string>()
                {
                    {"InterfaceId", "ID_FraudCallDetection"},
                    // Generate a message ID, this will be the application identifier for the message through the platform providing correlation.
                    // If the payload contained a usable message Id we could use that.
                    {"MessageId", Guid.NewGuid().ToString()},
                    {"CallingIMSI", messageData.CallingIMSI},
                    {"CalledIMSI", messageData.CalledIMSI},
                    {"MSRN", messageData.MSRN}
                };

            // The service bus client will automatically track as a dependency to application insights, add additional properties to the current activity.
            Activity.Current?.WithCustomProperties(messageCustomDimensions);

            await using (var client = new ServiceBusClient(configuration["servicebus_connection_string"]))
            {
                telemetryClient.TrackTrace(new TraceTelemetry($"The message originated from {messageData.SwitchNum}").WithCustomProperties(messageCustomDimensions));

                var sender = client.CreateSender("fraud_call_detections");
                await sender.SendMessageAsync(new ServiceBusMessage(input)
                {
                    MessageId = messageCustomDimensions["MessageId"]
                }.WithCustomProperties(messageCustomDimensions));

                EventTelemetry eventTelemetry = new EventTelemetry("FraudCallDetectionInInterface").WithCustomProperties(messageCustomDimensions);
                telemetryClient.TrackEvent(eventTelemetry);
            };
        }
    }
}