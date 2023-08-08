namespace Company.Abstractions.Models
{
    public class BusinessNotificationData
    {
        public string key1 { get; set; }
        public string key2 { get; set; }
        public string key3 { get; set; }
        public NestedKey nestedKey { get; set; }
        public string[] arrayKey { get; set; }
    }
}
