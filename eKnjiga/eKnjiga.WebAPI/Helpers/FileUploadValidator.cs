using eKnjiga.Services.Exceptions;

namespace eKnjiga.WebAPI.Helpers
{
    public static class FileUploadValidator
    {
        private const long MaxImageSize = 2 * 1024 * 1024;
        private const long MaxPdfSize = 20 * 1024 * 1024;

        private static readonly string[] AllowedImageExtensions = [".jpg", ".jpeg", ".png"];
        private static readonly string[] AllowedPdfExtensions = [".pdf"];

        public static async Task ValidateImageAsync(IFormFile file)
        {
            if (file == null || file.Length == 0)
                throw new UserException("Slika nije poslana.");

            if (file.Length > MaxImageSize)
                throw new UserException("Slika je prevelika. Maksimalna veličina je 2 MB.");

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!AllowedImageExtensions.Contains(extension))
                throw new UserException("Dozvoljene su samo JPG, JPEG i PNG slike.");

            await using var stream = file.OpenReadStream();

            var header = new byte[8];
            var read = await stream.ReadAsync(header, 0, header.Length);

            var isJpg =
                read >= 3 &&
                header[0] == 0xFF &&
                header[1] == 0xD8 &&
                header[2] == 0xFF;

            var isPng =
                read >= 8 &&
                header[0] == 0x89 &&
                header[1] == 0x50 &&
                header[2] == 0x4E &&
                header[3] == 0x47 &&
                header[4] == 0x0D &&
                header[5] == 0x0A &&
                header[6] == 0x1A &&
                header[7] == 0x0A;

            if (!isJpg && !isPng)
                throw new UserException("Fajl nije validna JPG, JPEG ili PNG slika.");
        }

        public static async Task ValidatePdfAsync(IFormFile file)
        {
            if (file == null || file.Length == 0)
                throw new UserException("PDF fajl nije poslan.");

            if (file.Length > MaxPdfSize)
                throw new UserException("PDF je prevelik. Maksimalna veličina je 20 MB.");

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!AllowedPdfExtensions.Contains(extension))
                throw new UserException("Dozvoljen je samo PDF fajl.");

            await using var stream = file.OpenReadStream();

            var header = new byte[5];
            var read = await stream.ReadAsync(header, 0, header.Length);

            var isPdf =
                read == 5 &&
                header[0] == 0x25 &&
                header[1] == 0x50 &&
                header[2] == 0x44 &&
                header[3] == 0x46 &&
                header[4] == 0x2D;

            if (!isPdf)
                throw new UserException("Fajl nije validan PDF dokument.");
        }
    }
}