using Company.Telemetry.Extensions;
using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;
using Microsoft.ApplicationInsights.Extensibility;
using System.Diagnostics;

namespace Company.Telemetry
{
    public class ScopedTelemetryClient : IScopedTelemetryClient
    {
        private readonly TelemetryClient telemetryClient;

        private readonly Dictionary<string, string> _additionalProperties = new Dictionary<string, string>();

        public TelemetryClient Client => telemetryClient;

        public ScopedTelemetryClient(TelemetryConfiguration telemetryConfiguration)
        {
            this.telemetryClient = new TelemetryClient(telemetryConfiguration);
        }

        public void SetAdditionalProperty(string key, string value)
        {
            _additionalProperties.Add(key, value);

            if (Activity.Current?.GetBaggageItem(key) == null)
            {
                Activity.Current?.SetBaggage(key, value);
            }
        }

        public void SetAdditionalProperties(Dictionary<string, string> additionalProperties)
        {
            foreach (var property in additionalProperties)
            {
                if (!_additionalProperties.ContainsKey(property.Key))
                {
                    _additionalProperties.Add(property.Key, property.Value);
                }

                if (Activity.Current?.GetBaggageItem(property.Key) == null)
                {
                    Activity.Current?.SetBaggage(property.Key, property.Value);
                }
            }
        }

        public void TrackEvent(EventTelemetry telemetry)
        {
            telemetryClient.TrackEvent(telemetry.WithCustomProperties(_additionalProperties));
        }
    }
}
