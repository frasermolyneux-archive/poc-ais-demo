namespace Company.Abstractions.Models
{
    public class FraudCallDetetectionData
    {
        public string RecordType { get; set; }
        public string SystemIdentity { get; set; }
        public string FileNum { get; set; }
        public string SwitchNum { get; set; }
        public string CallingNum { get; set; }
        public string CallingIMSI { get; set; }
        public string CalledNum { get; set; }
        public string CalledIMSI { get; set; }
        public string DateS { get; set; }
        public object TimeS { get; set; }
        public int TimeType { get; set; }
        public int CallPeriod { get; set; }
        public object CallingCellID { get; set; }
        public object CalledCellID { get; set; }
        public string ServiceType { get; set; }
        public int Transfer { get; set; }
        public object IncomingTrunk { get; set; }
        public string OutgoingTrunk { get; set; }
        public string MSRN { get; set; }
        public object CalledNum2 { get; set; }
        public object FCIFlag { get; set; }
        public DateTime callrecTime { get; set; }
        public DateTime EventProcessedUtcTime { get; set; }
        public int PartitionId { get; set; }
        public DateTime EventEnqueuedUtcTime { get; set; }
    }
}
