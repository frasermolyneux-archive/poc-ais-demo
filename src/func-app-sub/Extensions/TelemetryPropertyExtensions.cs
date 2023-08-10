using Azure.Messaging.ServiceBus;
using Microsoft.ApplicationInsights.DataContracts;
using System.Diagnostics;

namespace func_app_sub.Extensions
{
    internal static class TelemetryPropertyExtensions
    {
        public static Activity WithCustomProperties(this Activity activity, IDictionary<string, string> additionalProperties)
        {
            foreach (var property in additionalProperties)
            {
                activity.SetBaggage(property.Key, property.Value);
            }

            return activity;
        }

        public static ServiceBusMessage WithCustomProperties(this ServiceBusMessage message, IDictionary<string, string> additionalProperties)
        {
            foreach (var property in additionalProperties)
            {
                if (!message.ApplicationProperties.ContainsKey(property.Key))
                {
                    message.ApplicationProperties.Add(property.Key, property.Value);
                }
            }

            return message;
        }

        public static EventTelemetry WithCustomProperties(this EventTelemetry telemetry, IDictionary<string, string> additionalProperties)
        {
            foreach (var property in additionalProperties)
            {
                if (!telemetry.Properties.ContainsKey(property.Key))
                {
                    telemetry.Properties.Add(property.Key, property.Value);
                }
            }

            return telemetry;
        }

        public static MetricTelemetry WithCustomProperties(this MetricTelemetry telemetry, IDictionary<string, string> additionalProperties)
        {
            foreach (var property in additionalProperties)
            {
                if (!telemetry.Properties.ContainsKey(property.Key))
                {
                    telemetry.Properties.Add(property.Key, property.Value);
                }
            }

            return telemetry;
        }

        public static TraceTelemetry WithCustomProperties(this TraceTelemetry telemetry, IDictionary<string, string> additionalProperties)
        {
            foreach (var property in additionalProperties)
            {
                if (!telemetry.Properties.ContainsKey(property.Key))
                {
                    telemetry.Properties.Add(property.Key, property.Value);
                }
            }

            return telemetry;
        }

        public static ExceptionTelemetry WithCustomProperties(this ExceptionTelemetry telemetry, IDictionary<string, string> additionalProperties)
        {
            foreach (var property in additionalProperties)
            {
                if (!telemetry.Properties.ContainsKey(property.Key))
                {
                    telemetry.Properties.Add(property.Key, property.Value);
                }
            }

            return telemetry;
        }
    }
}
