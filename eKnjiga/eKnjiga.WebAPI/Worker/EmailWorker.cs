using System.Text;
using System.Text.Json;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using eKnjiga.Model.Messages;

public sealed class EmailWorker : BackgroundService
{
    private readonly IConfiguration _cfg;
    private IConnection? _conn;
    private IModel? _ch;

    private const string Exchange = "email";
    private const string RoutingKey = "email.send";
    private const string Queue = "email.send.q";

    public EmailWorker(IConfiguration cfg) => _cfg = cfg;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
{
    var cs = _cfg["Rabbit:ConnectionString"];

    var factory = new ConnectionFactory
    {
        Uri = new Uri(cs!),
        AutomaticRecoveryEnabled = true,
        NetworkRecoveryInterval = TimeSpan.FromSeconds(10),
        DispatchConsumersAsync = true
    };

    while (!stoppingToken.IsCancellationRequested)
    {
        try
        {
            _conn ??= factory.CreateConnection();

            _ch ??= _conn.CreateModel();

            _ch.ExchangeDeclare(Exchange, ExchangeType.Direct, durable: true);
            _ch.QueueDeclare(Queue, durable: true, exclusive: false, autoDelete: false);
            _ch.QueueBind(Queue, Exchange, RoutingKey);
            _ch.BasicQos(0, 5, false);

            var consumer = new AsyncEventingBasicConsumer(_ch);
            consumer.Received += async (_, ea) =>
            {
                try
                {
                    var json = Encoding.UTF8.GetString(ea.Body.ToArray());

                    var msg = JsonSerializer.Deserialize<EmailMessage>(json)!;

                    await SendEmailAsync(msg, _cfg, stoppingToken);

                    _ch!.BasicAck(ea.DeliveryTag, false);
                }
                catch (Exception ex)
                {
                    _ch!.BasicNack(ea.DeliveryTag, false, requeue: true);
                }
            };

            _ch.BasicConsume(queue: Queue, autoAck: false, consumer: consumer);

            while (!stoppingToken.IsCancellationRequested)
                await Task.Delay(1000, stoppingToken);
        }
        catch (Exception ex)
        {
            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);
        }
    }
}


    private static async Task SendEmailAsync(EmailMessage msg, IConfiguration cfg, CancellationToken ct)
    {
        var mime = new MimeMessage();
        mime.From.Add(new MailboxAddress(null, msg.From ?? cfg["Smtp:From"]!));
        mime.To.Add(MailboxAddress.Parse(msg.To));
        mime.Subject = msg.Subject;

        var bodyBuilder = new BodyBuilder { HtmlBody = msg.Html, TextBody = msg.Text };
        mime.Body = bodyBuilder.ToMessageBody();

        using var smtp = new SmtpClient();

        var host = cfg["Smtp:Host"];
        var port = int.Parse(cfg["Smtp:Port"]!);

        await smtp.ConnectAsync(host, port, SecureSocketOptions.None, ct);

        var user = cfg["Smtp:User"];
        var pass = cfg["Smtp:Pass"];
        if (!string.IsNullOrWhiteSpace(user))
        {
            await smtp.AuthenticateAsync(user, pass, ct);
        }

        await smtp.SendAsync(mime, ct);
        await smtp.DisconnectAsync(true, ct);
    }

    public override void Dispose()
    {
        try { _ch?.Dispose(); } catch { }
        try { _conn?.Dispose(); } catch { }
        base.Dispose();
    }
}
