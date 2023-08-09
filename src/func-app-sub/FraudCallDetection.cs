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
        public async Task RunFraudCallDetection([EventHubTrigger("fraud-call-detection", Connection = "eventhub_connection_string")] string[] input, FunctionContext executionContext)
        {
            Activity.Current?.AddBaggage("InterfaceId", "ID_FraudCallDetection");

            var customDimensions = new Dictionary<string, string>()
            {
                {"InterfaceId", "ID_FraudCallDetection"}
            };

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
                        telemetryClient.TrackException(new ExceptionTelemetry(ex).WithCustomProperties(customDimensions));
                        continue;
                    }

                    if (messageData == null)
                    {
                        telemetryClient.TrackException(new Exception("Message was null after deserialization attempt"), customDimensions);
                        continue;
                    }

                    var messageCustomDimensions = new Dictionary<string, string>()
                    {
                        {"InterfaceId", "ID_FraudCallDetection"},
                        {"CallingIMSI", messageData.CallingIMSI},
                        {"CalledIMSI", messageData.CalledIMSI},
                        {"MSRN", messageData.MSRN}
                    };

                    telemetryClient.TrackTrace(new TraceTelemetry($"The message originated from {messageData.SwitchNum}").WithCustomProperties(messageCustomDimensions));

                    var sender = client.CreateSender("fraud_call_detections");
                    await sender.SendMessageAsync(new ServiceBusMessage(message).WithCustomProperties(messageCustomDimensions));

                    EventTelemetry eventTelemetry = new EventTelemetry("FraudCallDetectionInInterface").WithCustomProperties(messageCustomDimensions);
                    telemetryClient.TrackEvent(eventTelemetry);
                };

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