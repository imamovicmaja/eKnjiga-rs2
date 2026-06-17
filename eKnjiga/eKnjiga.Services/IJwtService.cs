using eKnjiga.Model.Responses;

namespace eKnjiga.Services
{
    public interface IJwtService
    {
        LoginResponse GenerateToken(UserResponse user);
    }
}