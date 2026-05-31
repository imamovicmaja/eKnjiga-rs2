using eKnjiga.Model.Enums;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace eKnjiga.Services.Database.seedAssets
{
    public static class DbSeeder
    {

        public static void SeedBookFiles(eKnjigaDbContext context)
        {
            var books = context.Books.ToList();

            foreach (var book in books)
            {
                var pdf = SeedBookAssets.TryGetPdf(book.Id);
                if (pdf != null && (book.PdfFile == null || book.PdfFile.Length == 0))
                {
                    book.PdfFile = pdf;
                }

                var relativeCoverPath = $"/images/books/{book.Id}.png";
                var absoluteCoverPath = Path.Combine(
                    Directory.GetCurrentDirectory(),
                    "wwwroot",
                    "images",
                    "books",
                    $"{book.Id}.png"
                );

                if (File.Exists(absoluteCoverPath))
                {
                    if (string.IsNullOrWhiteSpace(book.CoverImage))
                    {
                        book.CoverImage = relativeCoverPath;
                    }
                }
            }

            context.SaveChanges();
        }

        public static void SeedOrders(eKnjigaDbContext context)
        {
            if (!context.Orders.Any())
            {
                var orders = new List<Order>
        {
            // MAJA - PDF plaćen
            new Order
            {
                UserId = 2,
                OrderDate = DateTime.Now.AddDays(-3),
                CreatedAt = DateTime.Now.AddDays(-3),
                TotalPrice = 29.99m,
                OrderStatus = OrderStatus.Completed,
                PaymentStatus = PaymentStatus.Paid,
                OrderItems = new List<OrderItem>
                {
                    new OrderItem
                    {
                        BookId = 1,
                        Quantity = 1,
                        UnitPrice = 29.99m,
                        IsPdfPurchase = true
                    }
                }
            },

            // MAJA - PDF pending
            new Order
            {
                UserId = 2,
                OrderDate = DateTime.Now.AddDays(-1),
                CreatedAt = DateTime.Now.AddDays(-1),
                TotalPrice = 19.99m,
                OrderStatus = OrderStatus.Pending,
                PaymentStatus = PaymentStatus.Pending,
                OrderItems = new List<OrderItem>
                {
                    new OrderItem
                    {
                        BookId = 2,
                        Quantity = 1,
                        UnitPrice = 19.99m,
                        IsPdfPurchase = true
                    }
                }
            },

            // MAJA - tvrda kopija u obradi
            new Order
            {
                UserId = 2,
                OrderDate = DateTime.Now.AddDays(-2),
                CreatedAt = DateTime.Now.AddDays(-2),
                TotalPrice = 39.99m,
                OrderStatus = OrderStatus.Processing,
                PaymentStatus = PaymentStatus.Pending,
                OrderItems = new List<OrderItem>
                {
                    new OrderItem
                    {
                        BookId = 3,
                        Quantity = 1,
                        UnitPrice = 39.99m,
                        IsPdfPurchase = false
                    }
                }
            },

            // MAJA - OTKAZANA PDF narudžba
            new Order
            {
                UserId = 2,
                OrderDate = DateTime.Now.AddDays(-5),
                CreatedAt = DateTime.Now.AddDays(-5),
                TotalPrice = 15.99m,
                OrderStatus = OrderStatus.Cancelled,
                PaymentStatus = PaymentStatus.Pending,
                OrderItems = new List<OrderItem>
                {
                    new OrderItem
                    {
                        BookId = 2,
                        Quantity = 1,
                        UnitPrice = 15.99m,
                        IsPdfPurchase = true
                    }
                }
            },

            // HARIS - PDF plaćen
            new Order
            {
                UserId = 3,
                OrderDate = DateTime.Now.AddDays(-4),
                CreatedAt = DateTime.Now.AddDays(-4),
                TotalPrice = 24.99m,
                OrderStatus = OrderStatus.Completed,
                PaymentStatus = PaymentStatus.Paid,
                OrderItems = new List<OrderItem>
                {
                    new OrderItem
                    {
                        BookId = 2,
                        Quantity = 1,
                        UnitPrice = 24.99m,
                        IsPdfPurchase = true
                    }
                }
            },

            // HARIS - tvrda kopija u obradi
            new Order
            {
                UserId = 3,
                OrderDate = DateTime.Now.AddDays(-2),
                CreatedAt = DateTime.Now.AddDays(-2),
                TotalPrice = 34.99m,
                OrderStatus = OrderStatus.Processing,
                PaymentStatus = PaymentStatus.Pending,
                OrderItems = new List<OrderItem>
                {
                    new OrderItem
                    {
                        BookId = 4,
                        Quantity = 1,
                        UnitPrice = 34.99m,
                        IsPdfPurchase = false
                    }
                }
            },

            // HARIS - pending PDF
            new Order
            {
                UserId = 3,
                OrderDate = DateTime.Now.AddDays(-1),
                CreatedAt = DateTime.Now.AddDays(-1),
                TotalPrice = 14.99m,
                OrderStatus = OrderStatus.Pending,
                PaymentStatus = PaymentStatus.Pending,
                OrderItems = new List<OrderItem>
                {
                    new OrderItem
                    {
                        BookId = 1,
                        Quantity = 1,
                        UnitPrice = 14.99m,
                        IsPdfPurchase = true
                    }
                }
            }
        };

                context.Orders.AddRange(orders);
                context.SaveChanges();
            }

            var userBooks = context.Orders
                .Include(o => o.OrderItems)
                .Where(o => o.OrderStatus == OrderStatus.Completed &&
                            o.PaymentStatus == PaymentStatus.Paid)
                .SelectMany(o => o.OrderItems
                    .Where(oi => oi.IsPdfPurchase)
                    .Select(oi => new { o.UserId, oi.BookId }))
                .Distinct()
                .ToList();

            foreach (var ub in userBooks)
            {
                if (!context.UserBooks.Any(x => x.UserId == ub.UserId && x.BookId == ub.BookId))
                {
                    context.UserBooks.Add(new UserBook
                    {
                        UserId = ub.UserId,
                        BookId = ub.BookId,
                        IsFavorite = false
                    });
                }
            }

            context.SaveChanges();
        }

    }
}