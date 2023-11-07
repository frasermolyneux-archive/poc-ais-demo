using Newtonsoft.Json;

namespace Company.Abstractions.Models
{
    public partial class CarModel
    {
        [JsonProperty("Make")]
        public string Make { get; set; }

        [JsonProperty("Model")]
        public string Model { get; set; }

        [JsonProperty("VehicleType")]
        public long VehicleType { get; set; }

        [JsonProperty("VehicleWeight")]
        public long VehicleWeight { get; set; }
    }
}
