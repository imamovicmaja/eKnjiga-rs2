namespace eKnjiga.Services.Exceptions
{
    public class UserException : Exception
    {
        public int StatusCode { get; }

        public UserException(string message, int statusCode = 400)
            : base(message)
        {
            StatusCode = statusCode;
        }
    }
}