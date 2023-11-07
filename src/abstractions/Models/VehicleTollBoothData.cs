using Newtonsoft.Json;

namespace Company.Abstractions.Models
{
    public partial class VehicleTollBoothData
    {
        [JsonProperty("EntryTime")]
        public DateTimeOffset EntryTime { get; set; }

        [JsonProperty("CarModel")]
        public CarModel CarModel { get; set; }

        [JsonProperty("State")]
        public string State { get; set; }

        [JsonProperty("TollAmount")]
        public long TollAmount { get; set; }

        [JsonProperty("Tag")]
        public long Tag { get; set; }

        [JsonProperty("TollId")]
        public long TollId { get; set; }

        [JsonProperty("LicensePlate")]
        public string LicensePlate { get; set; }

        [JsonProperty("EventProcessedUtcTime")]
        public DateTimeOffset EventProcessedUtcTime { get; set; }

        [JsonProperty("PartitionId")]
        public long PartitionId { get; set; }

        [JsonProperty("EventEnqueuedUtcTime")]
        public DateTimeOffset EventEnqueuedUtcTime { get; set; }
    }
}
