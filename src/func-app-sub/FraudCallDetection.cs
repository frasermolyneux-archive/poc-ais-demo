using Azure.Messaging.ServiceBus;
using Company.Abstractions.Models;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

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
        public async Task RunFraudCallDetection([EventHubTrigger("fraud-call-detection", Connection = "eventhub_connection_string")] string[] input, FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("FraudCallDetection");

            var customDimensions = new Dictionary<string, object>()
            {
                {"InterfaceId", "ID_FraudCallDetection" }
            };

            using (logger.BeginScope(customDimensions))
            {
                foreach (string message in input)
                {
                    // The service bus client will automatically track as a dependency to application insights
                    await using (var client = new ServiceBusClient(configuration["servicebus_connection_string"]))
                    {
                        FraudCallDetetectionData? messageData;
                        try
                        {
                            messageData = JsonConvert.DeserializeObject<FraudCallDetetectionData>(message);
                        }
                        catch (Exception ex)
                        {
                            logger.LogError(ex, $"Exception deserializing fraud call detection payload");
                            continue;
                        }

                        if (messageData == null)
                        {
                            logger.LogError($"Failed to deserialize fraud call detection payload");
                            continue;
                        }

                        var sender = client.CreateSender("fraud_call_detections");
                        await sender.SendMessageAsync(new ServiceBusMessage(message));

                        EventTelemetry eventTelemetry = new("FraudCallDetectionInInterface");
                        eventTelemetry.Properties.Add("InterfaceId", "ID_FraudCallDetection");
                        eventTelemetry.Properties.Add("CallingIMSI", messageData.CallingIMSI);
                        eventTelemetry.Properties.Add("CalledIMSI", messageData.CalledIMSI);
                        eventTelemetry.Properties.Add("MSRN", messageData.MSRN);
                        telemetryClient.TrackEvent(eventTelemetry);
                    };
                }

                MetricTelemetry metricTelemetry = new()
                {
                    Name = "FraudCallDetectionBatch",
                    Sum = input.Count()
                };

                metricTelemetry.Properties.Add("InterfaceId", "ID_FraudCallDetection");
                telemetryClient.TrackMetric(metricTelemetry);
            }
        }
    }
}
