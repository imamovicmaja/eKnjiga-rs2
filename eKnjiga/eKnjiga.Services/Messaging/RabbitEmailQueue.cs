using Microsoft.Extensions.Configuration;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;
using eKnjiga.Model.Messages;
using System.Threading.Tasks;
using System.Threading;
using System;

namespace eKnjiga.Services.Messaging
{
    public sealed class RabbitEmailQueue : IEmailQueue, IDisposable
    {
        private readonly IConnection _conn;
        private readonly string _exchange;
        private readonly string _routingKey;
        private readonly string _queue;

        public RabbitEmailQueue(IConfiguration cfg)
        {
            var connString = cfg["Rabbit:ConnectionString"]
                ?? throw new InvalidOperationException("Rabbit:ConnectionString is missing.");

            _exchange = cfg["Rabbit:Exchange"]
                ?? throw new InvalidOperationException("Rabbit:Exchange is missing.");

            _routingKey = cfg["Rabbit:RoutingKey"]
                ?? throw new InvalidOperationException("Rabbit:RoutingKey is missing.");

            _queue = cfg["Rabbit:Queue"]
                ?? throw new InvalidOperationException("Rabbit:Queue is missing.");

            var factory = new ConnectionFactory
            {
                Uri = new Uri(connString),
                AutomaticRecoveryEnabled = true
            };

            _conn = factory.CreateConnection();

            using var ch = _conn.CreateModel();
            ch.ExchangeDeclare(_exchange, ExchangeType.Direct, durable: true);
            ch.QueueDeclare(_queue, durable: true, exclusive: false, autoDelete: false);
            ch.QueueBind(_queue, _exchange, _routingKey);
        }

        public Task EnqueueAsync(EmailMessage msg, CancellationToken ct = default)
        {
            using var ch = _conn.CreateModel();

            ch.ConfirmSelect();

            var body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(msg));
            var props = ch.CreateBasicProperties();
            props.Persistent = true;

            ch.BasicPublish(
                exchange: _exchange,
                routingKey: _routingKey,
                mandatory: true,
                basicProperties: props,
                body: body
            );

            ch.WaitForConfirmsOrDie(TimeSpan.FromSeconds(5));
            return Task.CompletedTask;
        }

        public void Dispose() => _conn?.Dispose();
    }
}