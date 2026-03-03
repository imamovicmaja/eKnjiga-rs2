using System.Text;
using System.Text.Json;
using eKnjiga.Model.Messages;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MimeKit;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;

namespace eKnjiga.Worker.Messaging
{
    public sealed class RabbitEmailConsumer : BackgroundService
    {
        private readonly IConfiguration _cfg;
        private readonly ILogger<RabbitEmailConsumer> _logger;

        private IConnection? _conn;
        private IModel? _ch;

        private const string Exchange = "email";
        private const string RoutingKey = "email.send";
        private const string Queue = "email.send.q";

        public RabbitEmailConsumer(IConfiguration cfg, ILogger<RabbitEmailConsumer> logger)
        {
            _cfg = cfg;
            _logger = logger;
        }

        protected override Task ExecuteAsync(CancellationToken stoppingToken)
        {
            try
            {
                StartRabbitConsumer(stoppingToken);
                _logger.LogInformation("RabbitEmailConsumer started. Listening on queue: {Queue}", Queue);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "RabbitEmailConsumer failed to start");
                throw;
            }

            // Keep the background service alive; Rabbit client runs the consumer callbacks.
            return Task.Delay(Timeout.InfiniteTimeSpan, stoppingToken);
        }

        private void StartRabbitConsumer(CancellationToken stoppingToken)
        {
            var cs = _cfg["Rabbit:ConnectionString"];
            if (string.IsNullOrWhiteSpace(cs))
            {
                throw new InvalidOperationException("Rabbit:ConnectionString is missing.");
            }

            var factory = new ConnectionFactory
            {
                Uri = new Uri(cs),
                AutomaticRecoveryEnabled = true,
                NetworkRecoveryInterval = TimeSpan.FromSeconds(10),
                DispatchConsumersAsync = true
            };

            _conn = factory.CreateConnection();
            _ch = _conn.CreateModel();

            // Ensure topology exists (idempotent)
            _ch.ExchangeDeclare(Exchange, ExchangeType.Direct, durable: true);
            _ch.QueueDeclare(Queue, durable: true, exclusive: false, autoDelete: false);
            _ch.QueueBind(Queue, Exchange, RoutingKey);

            // Fair dispatch: limit number of unacked messages
            _ch.BasicQos(prefetchSize: 0, prefetchCount: 5, global: false);

            var consumer = new AsyncEventingBasicConsumer(_ch);
            consumer.Received += OnMessageReceivedAsync;

            _ch.BasicConsume(queue: Queue, autoAck: false, consumer: consumer);

            // If app is stopping, try to close cleanly
            stoppingToken.Register(() =>
            {
                try
                {
                    _logger.LogInformation("Stopping RabbitEmailConsumer...");
                    _ch?.Close();
                    _conn?.Close();
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Error while stopping RabbitEmailConsumer");
                }
            });
        }

        private async Task OnMessageReceivedAsync(object sender, BasicDeliverEventArgs ea)
        {
            if (_ch == null)
            {
                // Can't ack/nack safely; nothing to do.
                _logger.LogWarning("Channel is null while message received");
                return;
            }

            try
            {
                var json = Encoding.UTF8.GetString(ea.Body.ToArray());

                EmailMessage? msg;
                try
                {
                    msg = JsonSerializer.Deserialize<EmailMessage>(json);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "Invalid message JSON. Acking to drop. Body: {Body}", json);
                    _ch.BasicAck(ea.DeliveryTag, multiple: false);
                    return;
                }

                if (msg == null || string.IsNullOrWhiteSpace(msg.To))
                {
                    _logger.LogWarning("EmailMessage is null or missing 'To'. Acking to drop.");
                    _ch.BasicAck(ea.DeliveryTag, multiple: false);
                    return;
                }

                await SendEmailAsync(msg, _cfg, CancellationToken.None);

                _ch.BasicAck(ea.DeliveryTag, multiple: false);
                _logger.LogInformation("Email sent to: {To} | Subject: {Subject}", msg.To, msg.Subject);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed processing email message. Nacking with requeue.");
                _ch.BasicNack(ea.DeliveryTag, multiple: false, requeue: true);
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
            var portStr = cfg["Smtp:Port"];

            if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(portStr))
            {
                throw new InvalidOperationException("SMTP config missing (Smtp:Host / Smtp:Port).");
            }

            var port = int.Parse(portStr);

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
}
