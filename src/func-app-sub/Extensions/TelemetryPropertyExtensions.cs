using Azure.Messaging.ServiceBus;

namespace Company.Functions.Sub.Extensions
{
    internal static class TelemetryPropertyExtensions
    {
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
    }
}
