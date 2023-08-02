using Azure.Messaging.ServiceBus;


using Microsoft.AspNetCore.Mvc.RazorPages;

namespace web_app.Pages
{
    public class IndexModel : PageModel
    {
        private readonly ILogger<IndexModel> _logger;
        private readonly IConfiguration configuration;

        public string Region { get; set; } = "Unknown";

        public IndexModel(ILogger<IndexModel> logger, IConfiguration configuration)
        {
            _logger = logger;
            this.configuration = configuration;
            Region = configuration["location"] ?? "Unknown";
        }

        public async Task OnGet()
        {
            // If there is a Request-Id received from the upstream service, set the telemetry context accordingly.
            var requestId = string.Empty;
            if (HttpContext.Request.Headers.ContainsKey("Request-Id"))
            {
                requestId = HttpContext.Request.Headers["Request-Id"];
            }

            await using (var client = new ServiceBusClient(configuration["servicebus_connection_string"]))
            {
                var sender = client.CreateSender("from_website");
                await sender.SendMessageAsync(new ServiceBusMessage($"Hello from the web application at {Region}!")
                {
                    CorrelationId = requestId
                });
            }
        }

        public static string GetOperationId(string id)
        {
            // Returns the root ID from the '|' to the first '.' if any.
            int rootEnd = id.IndexOf('.');
            if (rootEnd < 0)
                rootEnd = id.Length;

            int rootStart = id[0] == '|' ? 1 : 0;
            return id.Substring(rootStart, rootEnd - rootStart);
        }
    }
}