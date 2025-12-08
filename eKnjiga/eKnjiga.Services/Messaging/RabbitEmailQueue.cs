using System;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using eKnjiga.Model.Messages;     
using RabbitMQ.Client;            

namespace eKnjiga.Services.Messaging
{
    public sealed class RabbitEmailQueue : IEmailQueue, IDisposable
    {
        private readonly IConnection _conn;

        private const string Exchange = "email";
        private const string RoutingKey = "email.send";
        private const string Queue = "email.send.q";

        public RabbitEmailQueue(string connString)
        {
            var factory = new ConnectionFactory { Uri = new Uri(connString), AutomaticRecoveryEnabled = true };
            _conn = factory.CreateConnection();

            using var ch = _conn.CreateModel();
            ch.ExchangeDeclare(Exchange, ExchangeType.Direct, durable: true);
            ch.QueueDeclare(Queue, durable: true, exclusive: false, autoDelete: false);
            ch.QueueBind(Queue, Exchange, RoutingKey);
        }

        public Task EnqueueAsync(EmailMessage msg, CancellationToken ct = default)
        {
            using var ch = _conn.CreateModel();

            ch.ConfirmSelect();

            var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(msg));
            var props = ch.CreateBasicProperties();
            props.Persistent = true;

            ch.BasicPublish(exchange: Exchange, routingKey: RoutingKey, mandatory: true, basicProperties: props, body: body);

            ch.WaitForConfirmsOrDie(TimeSpan.FromSeconds(5));
            return Task.CompletedTask;
        }

        public void Dispose() => _conn?.Dispose();
    }
}
