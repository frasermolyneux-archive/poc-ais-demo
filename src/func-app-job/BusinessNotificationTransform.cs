using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;

namespace Company.Functions.Job
{
    public class BusinessNotificationTransform
    {
        [FunctionName("BusinessNotificationTransform")]
        public async Task<IActionResult> RunBusinessNotificationTransform([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req, ILogger logger)
        {
            logger.LogDebug("BusinessNotificationTransform has received a message to transform");

            string requestBody = string.Empty;
            using (StreamReader streamReader = new(req.Body))
            {
                requestBody = await streamReader.ReadToEndAsync();
            }

            return new OkObjectResult(requestBody);
        }
    }
}
