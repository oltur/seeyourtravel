<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.Drawing" %>
<%@ Import Namespace="System.Drawing.Drawing2D" %>
<%@ Import Namespace="System.Drawing.Imaging" %>
<%@ Import Namespace="System.IO" %>
<%
    // A small square picture of one face (id=FaceID): cut out of the 1600 px copy, kept in the temp folder (outside the web root, so it can't be fetched without the check). Shown to the owner and administrators only.
    Guid face;
    if (!Guid.TryParse(Request["id"], out face)) { Response.StatusCode = 404; return; }
    string fileName = null; float x = 0, y = 0, w = 0, h = 0;
    using (var c = People.Open())
    using (var r = People.Cmd(c, "SELECT i.FileName, f.X, f.Y, f.W, f.H FROM Face f JOIN Image i ON i.ImageID=f.ImageID WHERE f.FaceID=@f", "@f", face).ExecuteReader())
        if (r.Read()) { fileName = r.GetString(0); x = r.GetFloat(1); y = r.GetFloat(2); w = r.GetFloat(3); h = r.GetFloat(4); }
    if (fileName == null || !PhotoGuard.CanView(Context, fileName)) { Response.StatusCode = 404; return; }
    string cache = Path.Combine(Path.GetTempPath(), "syt-facecache", face.ToString("N") + ".jpg");
    if (!File.Exists(cache))
    {
        string src = PhotoDerivatives.PathFor(Server, 1600, fileName);
        if (!File.Exists(src)) { Response.StatusCode = 404; return; }
        Directory.CreateDirectory(Path.GetDirectoryName(cache));
        using (var bmp = new Bitmap(src))
        {
            // square around the face with some margin
            double cx = (x + w / 2) * bmp.Width, cy = (y + h / 2) * bmp.Height, side = Math.Max(w * bmp.Width, h * bmp.Height) * 1.6;
            side = Math.Min(side, Math.Min(bmp.Width, bmp.Height));
            double left = Math.Max(0, Math.Min(bmp.Width - side, cx - side / 2)), top = Math.Max(0, Math.Min(bmp.Height - side, cy - side / 2));
            using (var t = new Bitmap(160, 160, PixelFormat.Format24bppRgb))
            {
                using (var g = Graphics.FromImage(t))
                {
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.DrawImage(bmp, new Rectangle(0, 0, 160, 160), new Rectangle((int)left, (int)top, (int)side, (int)side), GraphicsUnit.Pixel);
                }
                var codec = ImageCodecInfo.GetImageEncoders().First(e => e.MimeType == "image/jpeg");
                var ps = new EncoderParameters(1);
                ps.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, 82L);
                t.Save(cache + ".tmp", codec, ps);
            }
        }
        File.Move(cache + ".tmp", cache);
    }
    Response.ContentType = "image/jpeg";
    Response.Cache.SetCacheability(HttpCacheability.Private);
    Response.Cache.SetNoStore();
    Response.TransmitFile(cache);
%>
