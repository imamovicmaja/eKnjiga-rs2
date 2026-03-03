using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace eKnjiga.Model.Requests
{
    public class UserProfileImageUpsertRequest
    {
        public byte[]? ProfileImage { get; set; }
    }
} 