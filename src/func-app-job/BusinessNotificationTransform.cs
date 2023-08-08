using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using System.Net;

namespace Company.Functions.Job
{
    public class BusinessNotificationTransform
    {
        [Function("BusinessNotificationTransform")]
        public async Task<HttpResponseData> RunBusinessNotificationTransform([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData req, FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("HttpFunction");
            logger.LogDebug("BusinessNotificationTransform has received a message to transform");

            string requestBody = string.Empty;
            using (StreamReader streamReader = new(req.Body))
            {
                requestBody = await streamReader.ReadToEndAsync();
            }

            var response = req.CreateResponse(HttpStatusCode.OK);

            response.Headers.Add("Content-Type", "application/json; charset=utf-8");
            response.WriteString(requestBody);

            return response;
        }
    }
}
