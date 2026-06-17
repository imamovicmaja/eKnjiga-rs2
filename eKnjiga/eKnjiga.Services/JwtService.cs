using eKnjiga.Model.Responses;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace eKnjiga.Services
{
    public class JwtService : IJwtService
    {
        private readonly IConfiguration _configuration;

        public JwtService(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public LoginResponse GenerateToken(UserResponse user)
        {
            var key = _configuration["Jwt:Key"];

            if (string.IsNullOrWhiteSpace(key))
                throw new InvalidOperationException("JWT ključ nije konfigurisan.");

            var issuer = _configuration["Jwt:Issuer"] ?? "eKnjiga";
            var audience = _configuration["Jwt:Audience"] ?? "eKnjigaUsers";

            var expiryMinutesValue = _configuration["Jwt:ExpiryMinutes"];
            var expiryMinutes = int.TryParse(expiryMinutesValue, out var parsed)
                ? parsed
                : 120;

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.GivenName, user.FirstName),
                new Claim(ClaimTypes.Surname, user.LastName),
                new Claim(ClaimTypes.Email, user.Email)
            };

            if (user.Role != null && !string.IsNullOrWhiteSpace(user.Role.Name))
            {
                claims.Add(new Claim(ClaimTypes.Role, user.Role.Name));
            }

            var securityKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(key)
            );

            var credentials = new SigningCredentials(
                securityKey,
                SecurityAlgorithms.HmacSha256
            );

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
                signingCredentials: credentials
            );

            var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

            return new LoginResponse
            {
                Token = tokenString,
                UserId = user.Id,
                Username = user.Username,
                Role = user.Role?.Name ?? string.Empty
            };
        }
    }
}