using Company.Functions.Job;
using Company.Telemetry;
using Microsoft.Azure.Functions.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection;

[assembly: FunctionsStartup(typeof(Startup))]

namespace Company.Functions.Job
{
    public class Startup : FunctionsStartup
    {
        public override void Configure(IFunctionsHostBuilder builder)
        {
            builder.Services.AddScoped<IScopedLogger, ScopedLogger>();
            builder.Services.AddScoped<IScopedTelemetryClient, ScopedTelemetryClient>();
        }
    }
}
