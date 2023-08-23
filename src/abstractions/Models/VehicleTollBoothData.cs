namespace Company.Abstractions.Models
{
    public class VehicleTollBoothData
    {
        public DateTime EntryTime { get; set; }
        public CarModelData CarModel { get; set; }
        public string State { get; set; }
        public int TollAmount { get; set; }
        public int Tag { get; set; }
        public int TollId { get; set; }
        public string LicensePlate { get; set; }
        public DateTime EventProcessedUtcTime { get; set; }
        public int PartitionId { get; set; }
        public DateTime EventEnqueuedUtcTime { get; set; }
    }
}
