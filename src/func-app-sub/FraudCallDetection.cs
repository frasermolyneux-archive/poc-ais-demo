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
    public class FraudCallDetection
    {
        private readonly IConfiguration configuration;
        private readonly IScopedTelemetryClient scopedTelemetryClient;

        public FraudCallDetection(IConfiguration configuration, IScopedTelemetryClient scopedTelemetryClient)
        {
            this.configuration = configuration;
            this.scopedTelemetryClient = scopedTelemetryClient;
        }

        [FunctionName("FraudCallDetection")]
        public async Task RunFraudCallDetection([EventHubTrigger("fraud-call-detection", Connection = "eventhub_connection_string")] string input, ILogger logger)
        {
            scopedTelemetryClient.SetAdditionalProperty("InterfaceId", "ID_FCD01");

            FraudCallDetetectionData? messageData;
            try
            {
                messageData = JsonConvert.DeserializeObject<FraudCallDetetectionData>(input);
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
                    {"MessageId", Guid.NewGuid().ToString()},
                    {"CallingIMSI", messageData.CallingIMSI},
                    {"CalledIMSI", messageData.CalledIMSI},
                    {"MSRN", messageData.MSRN}
                };

            scopedTelemetryClient.SetAdditionalProperties(messageCustomDimensions);

            await using (var client = new ServiceBusClient(configuration["servicebus_connection_string"]))
            {
                logger.LogInformation($"The message originated from {messageData.SwitchNum}");

                var sender = client.CreateSender("fcd01");
                await sender.SendMessageAsync(new ServiceBusMessage(input)
                {
                    MessageId = messageCustomDimensions["MessageId"]
                }.WithCustomProperties(messageCustomDimensions));

                EventTelemetry eventTelemetry = new EventTelemetry("FCD01_InInterface");
                scopedTelemetryClient.TrackEvent(eventTelemetry);
            };

        }
    }
}