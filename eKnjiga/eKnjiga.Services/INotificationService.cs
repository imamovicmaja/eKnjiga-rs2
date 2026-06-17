using eKnjiga.Model.Responses;
using eKnjiga.Model.SearchObjects;

namespace eKnjiga.Services
{
    public interface INotificationService
    {
        Task<PagedResult<NotificationResponse>> GetForCurrentUserAsync(NotificationSearchObject search);

        Task MarkAsReadAsync(int id);

        Task CreateAsync(int userId, string title, string text);
        Task<int> GetUnreadCountAsync();
    }
}