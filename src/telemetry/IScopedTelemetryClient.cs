using Microsoft.ApplicationInsights.DataContracts;

namespace Company.Telemetry
{
    public interface IScopedTelemetryClient
    {
        void SetAdditionalProperty(string key, string value);
        void SetAdditionalProperties(Dictionary<string, string> additionalProperties);
        void TrackEvent(EventTelemetry telemetry);
    }
}
