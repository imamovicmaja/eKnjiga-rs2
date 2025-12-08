namespace eKnjiga.Model.Responses
{
    public class CityResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int ZipCode { get; set; }
        public CountryResponse? Country { get; set; }
    }
}
