using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eKnjiga.Services.Database
{
    public class PaypalLog
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [Required]
        [MaxLength(16)]
        public string Direction { get; set; } = "Outbound";

        [Required]
        [MaxLength(128)]
        public string Operation { get; set; } = string.Empty; 

        [MaxLength(512)]
        public string? Url { get; set; }

        [MaxLength(10)]
        public string? Method { get; set; }

        public int? HttpStatus { get; set; }

        [MaxLength(128)]
        public string? CorrelationId { get; set; } 

        [MaxLength(64)]
        public string? OrderId { get; set; }

        [MaxLength(64)]
        public string? CaptureId { get; set; }

        [MaxLength(64)]
        public string? PayerId { get; set; }

        [MaxLength(32)]
        public string? Amount { get; set; }

        [MaxLength(8)]
        public string? Currency { get; set; }

        public string? RequestHeaders { get; set; }
        public string? RequestBody { get; set; }
        public string? ResponseBody { get; set; }
        public string? Error { get; set; }
    }
}
