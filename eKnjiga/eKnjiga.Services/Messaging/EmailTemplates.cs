using eKnjiga.Model.Messages;
using eKnjiga.Services.Database;

namespace eKnjiga.Services.Messaging
{
    public static class EmailTemplates
    {
        public static EmailMessage Welcome(User user)
        {
            return new EmailMessage(
                to: user.Email,
                subject: "Dobrodošli na eKnjiga",
                html: $@"
                    <h2>Zdravo {user.FirstName}</h2>
                    <p>Hvala na registraciji, vaš profil je kreiran.</p>
                ",
                text: $"Zdravo {user.FirstName}, hvala na registraciji, vaš profil je kreiran."
            );
        }
    }
}