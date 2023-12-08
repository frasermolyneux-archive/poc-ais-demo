using Microsoft.ApplicationInsights;
using Microsoft.ApplicationInsights.DataContracts;

namespace Company.Telemetry
{
    public interface IScopedTelemetryClient
    {
        TelemetryClient Client { get; }
        void SetAdditionalProperty(string key, string value);
        void SetAdditionalProperties(Dictionary<string, string> additionalProperties);
        void TrackEvent(EventTelemetry telemetry);
    }
}
