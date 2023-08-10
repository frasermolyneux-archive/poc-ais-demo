using Azure.Messaging.ServiceBus;
using Company.Abstractions.Models;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Company.Functions.Sub
{
    public class BusinessNotificationsTrigger
    {
        private readonly ILogger _logger;

        public BusinessNotificationsTrigger(ILoggerFactory loggerFactory)
        {
            _logger = loggerFactory.CreateLogger<BusinessNotificationsTrigger>();
        }

        // Monitor the event hub for messages and process them as they arrive.
        // Example input format:
        // {
        //     "key1": "value1",
        //     "key2": "value2",
        //     "key3": "value3",
        //     "notificationType": "type",
        //     "nestedKey": {
        //         "nestedKey1": "nestedValue1"
        //     },
        //     "arrayKey": [
        //         "arrayValue1",
        //         "arrayValue2"
        //     ]
        // }
        // The function will deserialize the JSON into an object.
        // If deserialization fails, the function will log the error and move on to the next message.
        // If deserialization succeeds, the function will use the value of the notificationType property to determine the service bus where the message should be sent.
        [FunctionName("BusinessNotificationsTrigger")]
        public async Task RunBusinessNotificationsTrigger([EventHubTrigger("business-notifications", Connection = "eventhub_connection_string")] string[] input)
        {
            foreach (string message in input)
            {
                // Deserialize the message
                BusinessNotificationData? messageData;
                try
                {
                    messageData = JsonConvert.DeserializeObject<BusinessNotificationData>(message);
                }
                catch (Exception ex)
                {
                    _logger.LogError($"Unable to deserialize message: {ex.Message}");
                    continue;
                }

                // Send the message to the appropriate service bus queue
                await using (var client = new ServiceBusClient(Environment.GetEnvironmentVariable("servicebus_connection_string")))
                {
                    var sender = client.CreateSender(messageData?.notificationType);
                    await sender.SendMessageAsync(new ServiceBusMessage(message));
                };
            }
        }

        // Monitor the event hub for messages and process them as they arrive.
        // Example input format:
        // [
        //    {
        //        "key1": "value1",
        //        "key2": "value2",
        //        "key3": "value3",
        //        "notificationType": "type",
        //        "nestedKey": {
        //            "nestedKey1": "nestedValue1"
        //        },
        //        "arrayKey": [
        //            "arrayValue1",
        //            "arrayValue2"
        //        ]
        //    }
        //]
        // The function will deserialize the JSON into an object.
        // If deserialization fails, the function will log the error and move on to the next message.
        // If deserialization succeeds, the function will use the value of the notificationType property to determine the service bus where the message should be sent.
        [FunctionName("BusinessNotificationsTriggerBatch")]
        public async Task RunBusinessNotificationsTriggerBatch([EventHubTrigger("business-notifications", Connection = "eventhub_connection_string")] string[] input)
        {
            foreach (string messageBatch in input)
            {
                // Deserialize the message
                List<BusinessNotificationData>? messagesData;
                try
                {
                    messagesData = JsonConvert.DeserializeObject<List<BusinessNotificationData>>(messageBatch);
                }
                catch (Exception ex)
                {
                    _logger.LogError($"Unable to deserialize message: {ex.Message}");
                    continue;
                }

                foreach (var subMessage in messagesData)
                {
                    // Send the message to the appropriate service bus queue
                    await using (var client = new ServiceBusClient(Environment.GetEnvironmentVariable("servicebus_connection_string")))
                    {
                        var sender = client.CreateSender(subMessage.notificationType);
                        await sender.SendMessageAsync(new ServiceBusMessage(messageBatch));
                    };
                }
            }
        }
    }
}
