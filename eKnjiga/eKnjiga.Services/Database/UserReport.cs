using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using eKnjiga.Model.Enums;

namespace eKnjiga.Services.Database
{
    public class UserReport
    {
        [Key]
        public int Id { get; set; }
        
        [Required]
        [MaxLength(200)]
        public string Reason { get; set; } = string.Empty;

        [Required]
        public UserReportStatus Status { get; set; } = UserReportStatus.Pending; 
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public DateTime? ProcessedAt { get; set; }

        // Foreign key for reported User
        public int UserReportedId { get; set; }
        [ForeignKey("UserReportedId")]
        public User UserReported { get; set; }

        // Foreign key for User who reported
        public int ReportedByUserId { get; set; }
        [ForeignKey("ReportedByUserId")]
        public User ReportedByUser { get; set; }

        // Foreign key for User who processed the report
        public int? ProcessedByUserId { get; set; }
        [ForeignKey("ProcessedByUserId")]
        public User? ProcessedByUser { get; set; }
    }
} 