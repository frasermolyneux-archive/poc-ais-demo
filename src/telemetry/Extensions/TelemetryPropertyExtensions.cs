using Microsoft.ApplicationInsights.DataContracts;

namespace Company.Telemetry.Extensions
{
    internal static class TelemetryPropertyExtensions
    {
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
