using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace eKnjiga.Model.Requests
{
    public class ReviewUpdateRequest
    {
        [Required]
        [Range(1, 5)]
        public double Rating { get; set; }
    }
}
