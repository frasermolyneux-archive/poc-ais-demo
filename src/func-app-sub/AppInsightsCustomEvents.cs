using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Company.Abstractions.Models;
using Microsoft.ApplicationInsights;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Company.Functions.Sub
{
    public class AppInsightsCustomEvents
    {
        private readonly ILogger _logger;
        public TelemetryClient TelemetryClient { get; }

        public AppInsightsCustomEvents(ILoggerFactory loggerFactory, TelemetryClient telemetryClient)
        {
            this.TelemetryClient = telemetryClient;
            _logger = loggerFactory.CreateLogger<AppInsightsCustomEvents>();
        }

        [FunctionName("AppInsightsCustomEventsTrigger")]
        public async Task RunAppInsightsCustomEventsTrigger([EventHubTrigger("appinsights-custom-events", Connection = "eventhub_connection_string")] string[] input)
        {
            foreach (string message in input)
            {
                // Deserialize the message
                ApimCustomEvent? messageData;
                try
                {
                    messageData = JsonConvert.DeserializeObject<ApimCustomEvent>(message);
                }
                catch (Exception ex)
                {
                    _logger.LogError($"Unable to deserialize custom event: {ex.Message}");
                    continue;
                }

                TelemetryClient.TrackEvent(messageData.EventName, messageData?.AdditionalProperties);
            }
        }
    }
}