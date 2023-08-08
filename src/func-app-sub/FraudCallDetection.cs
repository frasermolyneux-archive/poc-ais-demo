using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace func_app_sub
{
    public class FraudCallDetection
    {
        [Function("FraudCallDetection")]
        public async Task RunFraudCallDetection([EventHubTrigger("fraud-call-detection", Connection = "eventhub_connection_string")] string[] input, FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("HttpFunction");
            logger.LogDebug("FraudCallDetection has received a message");

            foreach (string messageBatch in input)
            {
                await using (var client = new ServiceBusClient(Environment.GetEnvironmentVariable("servicebus_connection_string")))
                {
                    var sender = client.CreateSender("fraud_call_detections");
                    await sender.SendMessageAsync(new ServiceBusMessage(messageBatch));
                };
            }
        }
    }
}
