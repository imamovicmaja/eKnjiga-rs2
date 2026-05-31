using System.Collections.Generic;
using System;
using System.Net;
using System.Text.Json;
using System.Threading.Tasks;

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
				await WriteErrorAsync(context, HttpStatusCode.InternalServerError, "An unexpected error occurred.");
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