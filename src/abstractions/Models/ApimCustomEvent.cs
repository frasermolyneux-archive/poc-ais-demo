using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Company.Abstractions.Models
{
    public class ApimCustomEvent
    {
        public string OperationId { get; set; }
        public string ServiceId { get; set; }
        public string ServiceName { get; set; }
        public string EventName { get; set; }
        public Dictionary<string, string> CustomDimensions { get; set; }
    }
}