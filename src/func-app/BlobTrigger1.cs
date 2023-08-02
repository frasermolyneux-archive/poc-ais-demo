using System;
using System.IO;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.Azure.ServiceBus;

namespace Company.Function
{
    public class BlobTrigger1
    {
        private readonly ILogger _logger;
        public IConfiguration Configuration { get; }

        public BlobTrigger1(ILoggerFactory loggerFactory, IConfiguration configuration)
        {
            this.Configuration = configuration;
            _logger = loggerFactory.CreateLogger<BlobTrigger1>();
        }

        [Function("BlobTrigger1")]
        public void Run([BlobTrigger("files-in/{name}", Connection = "ingest_connection_string")] string myBlob, string name)
        {
            _logger.LogInformation($"C# Blob trigger function Processed blob\n Name: {name} \n Data: {myBlob}");

            // Create a connection to the service bus and send a message to the queue with the blob name
            // This will trigger the next function in the pipeline
            var serviceBusConnectionString = Configuration["servicebus_connection_string"];
            var message = $"{{ \"blobName\": \"{name}\" }}";
            var client = new Microsoft.Azure.ServiceBus.QueueClient(serviceBusConnectionString, "files-in");
            var msg = new Microsoft.Azure.ServiceBus.Message(System.Text.Encoding.UTF8.GetBytes(message));
            client.SendAsync(msg).Wait();
        }
    }
}
