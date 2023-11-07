using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Company.Abstractions.Models
{
    public class ApimCustomEvent
    {
        public string EventName { get; set; }
        public Dictionary<string, string> AdditionalProperties { get; set; }
    }
}