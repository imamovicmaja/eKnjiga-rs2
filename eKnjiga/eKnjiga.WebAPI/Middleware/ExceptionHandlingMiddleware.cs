using eKnjiga.Services.Exceptions;
using System.Net;
using System.Text.Json;

namespace eKnjiga.WebAPI.Middleware
{
    public class ExceptionHandlingMiddleware
    {
        private readonly RequestDelegate _next;

        public ExceptionHandlingMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            try
            {
                await _next(context);
            }
            catch (UserException ex)
            {
                await WriteErrorAsync(context, (HttpStatusCode)ex.StatusCode, ex.Message);
            }
            catch (UnauthorizedAccessException ex)
            {
                await WriteErrorAsync(context, HttpStatusCode.Forbidden, ex.Message);
            }
            catch (KeyNotFoundException ex)
            {
                await WriteErrorAsync(context, HttpStatusCode.NotFound, ex.Message);
            }
            catch (InvalidOperationException ex)
            {
                await WriteErrorAsync(context, HttpStatusCode.BadRequest, ex.Message);
            }
            catch (Exception)
            {
                await WriteErrorAsync(context, HttpStatusCode.InternalServerError, "Došlo je do greške na serveru.");
            }
        }

        private static async Task WriteErrorAsync(HttpContext context, HttpStatusCode statusCode, string message)
        {
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = (int)statusCode;

            var response = new
            {
                message = message
            };

            await context.Response.WriteAsync(JsonSerializer.Serialize(response));
        }
    }
}