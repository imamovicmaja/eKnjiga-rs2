using System.Reflection;

namespace eKnjiga.Services.Database
{
    internal static class SeedBookAssets
    {
        private static string ResName(int bookId, string filename)
        {
            var root = typeof(SeedBookAssets).Namespace;
            return $"{root}.seedAssets.books._{bookId}.{filename}";
        }

        private static byte[]? Read(string resourceName)
        {
            var asm = Assembly.GetExecutingAssembly();
            using var s = asm.GetManifestResourceStream(resourceName);
            if (s == null) return null;
            using var ms = new MemoryStream();
            s.CopyTo(ms);
            return ms.ToArray();
        }

        public static byte[] GetCover(int bookId)
        {
            var name = ResName(bookId, "cover.png");
            var data = Read(name);
            if (data == null)
                throw new InvalidOperationException($"Slika naslovnice nije pronađena: {name}");
            return data;
        }

        public static byte[] GetPdf(int bookId)
        {
            var name = ResName(bookId, "book.pdf");
            var data = Read(name);
            if (data == null)
                throw new InvalidOperationException($"PDF datoteka nije pronađena.: {name}");
            return data;
        }

        public static string[] ListAll()
        {
            var asm = Assembly.GetExecutingAssembly();
            return asm.GetManifestResourceNames();
        }
    }
}
