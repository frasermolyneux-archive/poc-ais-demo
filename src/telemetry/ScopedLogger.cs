using Microsoft.Extensions.Logging;
using System.Diagnostics;

namespace Company.Telemetry
{
    public class ScopedLogger : IScopedLogger
    {
        private readonly ILogger logger;

        private readonly Dictionary<string, string> _additionalProperties = new Dictionary<string, string>();

        public ScopedLogger(ILogger<ScopedLogger> logger)
        {
            this.logger = logger;
        }

        public void SetAdditionalProperty(string key, string value)
        {
            _additionalProperties.Add(key, value);

            if (Activity.Current?.GetBaggageItem(key) == null)
            {
                Activity.Current?.SetBaggage(key, value);
            }
        }

        public void SetAdditionalProperties(Dictionary<string, string> additionalProperties)
        {
            foreach (var property in additionalProperties)
            {
                if (!_additionalProperties.ContainsKey(property.Key))
                {
                    _additionalProperties.Add(property.Key, property.Value);
                }

                if (Activity.Current?.GetBaggageItem(property.Key) == null)
                {
                    Activity.Current?.SetBaggage(property.Key, property.Value);
                }
            }
        }

        public void LogDebug(EventId eventId, Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Debug, eventId, exception, message, args);
        }

        public void LogDebug(EventId eventId, string? message, params object?[] args)
        {
            Log(LogLevel.Debug, eventId, message, args);
        }

        public void LogDebug(Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Debug, exception, message, args);
        }

        public void LogDebug(string? message, params object?[] args)
        {
            Log(LogLevel.Debug, message, args);
        }

        public void LogTrace(EventId eventId, Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Trace, eventId, exception, message, args);
        }

        public void LogTrace(EventId eventId, string? message, params object?[] args)
        {
            Log(LogLevel.Trace, eventId, message, args);
        }

        public void LogTrace(Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Trace, exception, message, args);
        }

        public void LogTrace(string? message, params object?[] args)
        {
            Log(LogLevel.Trace, message, args);
        }

        public void LogInformation(EventId eventId, Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Information, eventId, exception, message, args);
        }

        public void LogInformation(EventId eventId, string? message, params object?[] args)
        {
            Log(LogLevel.Information, eventId, message, args);
        }

        public void LogInformation(Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Information, exception, message, args);
        }

        public void LogInformation(string? message, params object?[] args)
        {
            Log(LogLevel.Information, message, args);
        }

        public void LogWarning(EventId eventId, Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Warning, eventId, exception, message, args);
        }

        public void LogWarning(EventId eventId, string? message, params object?[] args)
        {
            Log(LogLevel.Warning, eventId, message, args);
        }

        public void LogWarning(Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Warning, exception, message, args);
        }

        public void LogWarning(string? message, params object?[] args)
        {
            Log(LogLevel.Warning, message, args);
        }

        public void LogError(EventId eventId, Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Error, eventId, exception, message, args);
        }

        public void LogError(EventId eventId, string? message, params object?[] args)
        {
            Log(LogLevel.Error, eventId, message, args);
        }

        public void LogError(Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Error, exception, message, args);
        }

        public void LogError(string? message, params object?[] args)
        {
            Log(LogLevel.Error, message, args);
        }

        public void LogCritical(EventId eventId, Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Critical, eventId, exception, message, args);
        }

        public void LogCritical(EventId eventId, string? message, params object?[] args)
        {
            Log(LogLevel.Critical, eventId, message, args);
        }

        public void LogCritical(Exception? exception, string? message, params object?[] args)
        {
            Log(LogLevel.Critical, exception, message, args);
        }

        public void LogCritical(string? message, params object?[] args)
        {
            Log(LogLevel.Critical, message, args);
        }

        public void Log(LogLevel logLevel, string? message, params object?[] args)
        {
            Log(logLevel, 0, null, message, args);
        }

        public void Log(LogLevel logLevel, EventId eventId, string? message, params object?[] args)
        {
            Log(logLevel, eventId, null, message, args);
        }

        public void Log(LogLevel logLevel, Exception? exception, string? message, params object?[] args)
        {
            Log(logLevel, 0, exception, message, args);
        }

        public void Log(LogLevel logLevel, EventId eventId, Exception? exception, string? message, params object?[] args)
        {
            using (logger.BeginScope(_additionalProperties))
            {
                logger.Log(logLevel, eventId, exception, message, args);
            }
        }
    }
}
