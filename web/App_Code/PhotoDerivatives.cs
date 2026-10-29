using System;
using System.Collections.Concurrent;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Web;

/// <summary>
/// Ready-made web copies of the photos in data/images (see also tools/make_thumbs.py):
///   data/thumbs/480/NAME.jpg   long side 480 px  - strip, cards, pins, hover preview
///   data/thumbs/1600/NAME.jpg  long side 1600 px - photo viewer
/// Aspect ratio is kept, the camera rotation is applied and no EXIF/GPS is written.
/// </summary>
public static class PhotoDerivatives
{
    public static readonly int[] Sizes = { 480, 1600 };
    static readonly ConcurrentDictionary<string, int[]> dims = new ConcurrentDictionary<string, int[]>();

    public static string ThumbsRoot(HttpServerUtility server)
    {
        return server.MapPath("~/data/thumbs");
    }

    public static string PathFor(HttpServerUtility server, int size, string fileName)
    {
        return Path.Combine(ThumbsRoot(server), size.ToString(), Path.GetFileNameWithoutExtension(fileName) + ".jpg");
    }

    /// <summary>Public URL (relative to the site root) of a derivative.</summary>
    public static string UrlFor(int size, string fileName)
    {
        return "data/thumbs/" + size + "/" + Path.GetFileNameWithoutExtension(fileName) + ".jpg";
    }

    /// <summary>Width and height of a derivative (read from the file header, cached), or null if it doesn't exist.</summary>
    public static int[] Dimensions(string path)
    {
        if (!File.Exists(path)) return null;
        return dims.GetOrAdd(path, p =>
        {
            try { using (var img = System.Drawing.Image.FromFile(p)) return new[] { img.Width, img.Height }; }
            catch (Exception) { return null; }
        });
    }

    /// <summary>Drops the cached sizes of a photo's web copies (after they were turned).</summary>
    public static void ForgetDimensions(HttpServerUtility server, string fileName)
    {
        int[] old;
        foreach (var size in Sizes) dims.TryRemove(PathFor(server, size, fileName), out old);
    }

    /// <summary>Creates the derivatives of a freshly uploaded photo. Never throws (the original is already saved).</summary>
    public static void Create(HttpServerUtility server, string originalPath)
    {
        try
        {
            using (var src = new Bitmap(originalPath))
            {
                ApplyExifOrientation(src);
                foreach (var size in Sizes)
                {
                    var dest = PathFor(server, size, originalPath);
                    Directory.CreateDirectory(Path.GetDirectoryName(dest));
                    SaveScaled(src, size, size == 480 ? 80L : 82L, dest);
                }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Trace.WriteLine("[PhotoDerivatives] " + ex.Message);
        }
    }

    static void SaveScaled(Bitmap src, int longSide, long quality, string dest)
    {
        double scale = Math.Min(1.0, (double)longSide / Math.Max(src.Width, src.Height));
        int w = Math.Max(1, (int)Math.Round(src.Width * scale)), h = Math.Max(1, (int)Math.Round(src.Height * scale));
        using (var target = new Bitmap(w, h, PixelFormat.Format24bppRgb))
        {
            using (var g = Graphics.FromImage(target))
            {
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.CompositingQuality = CompositingQuality.HighQuality;
                g.DrawImage(src, 0, 0, w, h);
            }
            var codec = ImageCodecInfo.GetImageEncoders().First(c => c.MimeType == "image/jpeg");
            var ps = new EncoderParameters(1);
            ps.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, quality);
            var tmp = dest + ".tmp";
            target.Save(tmp, codec, ps);
            if (File.Exists(dest)) File.Delete(dest);
            File.Move(tmp, dest);
        }
    }

    public static void ApplyExifOrientation(Bitmap bitmap)
    {
        try
        {
            var item = bitmap.GetPropertyItem(0x0112);
            switch (BitConverter.ToUInt16(item.Value, 0))
            {
                case 2: bitmap.RotateFlip(RotateFlipType.RotateNoneFlipX); break;
                case 3: bitmap.RotateFlip(RotateFlipType.Rotate180FlipNone); break;
                case 4: bitmap.RotateFlip(RotateFlipType.Rotate180FlipX); break;
                case 5: bitmap.RotateFlip(RotateFlipType.Rotate90FlipX); break;
                case 6: bitmap.RotateFlip(RotateFlipType.Rotate90FlipNone); break;
                case 7: bitmap.RotateFlip(RotateFlipType.Rotate270FlipX); break;
                case 8: bitmap.RotateFlip(RotateFlipType.Rotate270FlipNone); break;
            }
        }
        catch (Exception) { }   // no orientation tag (Mono reports that as an ExternalException)
    }
}
