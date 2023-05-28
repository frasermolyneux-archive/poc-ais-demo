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
            await using (var client = new ServiceBusClient(configuration["servicebus_connection_string"]))
            {
                var sender = client.CreateSender("from_website");
                await sender.SendMessageAsync(new ServiceBusMessage($"Hello from the web application at {Region}!"));
            }
        }
    }
}