using System.Threading;
using System.Threading.Tasks;
using eKnjiga.Model.Messages;

namespace eKnjiga.Services.Messaging
{
    public interface IEmailQueue
    {
        Task EnqueueAsync(EmailMessage msg, CancellationToken ct = default);
    }
}
