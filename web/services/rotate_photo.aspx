<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Drawing" %>
<%@ Import Namespace="System.Drawing.Imaging" %>
<%
    // POST fileName=<photo> dir=cw|ccw : turns one of the caller's own photos (the original and both web copies) by 90 degrees
    Response.ContentType = "text/plain";
    Guid userId = Tools.GetUserId(this);
    if (userId == Guid.Empty) { Response.StatusCode = 403; Response.Write("Your session has expired: please reload the page and sign in again"); return; }
    string fileName = Request.Form["fileName"], dir = Request.Form["dir"];
    if (Request.HttpMethod != "POST" || string.IsNullOrEmpty(fileName) || (dir != "cw" && dir != "ccw") || fileName != Path.GetFileName(fileName)) { Response.StatusCode = 400; Response.Write("Bad request"); return; }

    var db = new SeeYourTravelEntities();
    if (!db.GetUserImages(userId).Any(t => t.FileName == fileName)) { Response.StatusCode = 404; Response.Write("Photo not found"); return; }
    string original = Server.MapPath("~/data/images/" + fileName);
    if (!File.Exists(original)) { Response.StatusCode = 404; Response.Write("Photo not found"); return; }
    var turn = dir == "cw" ? RotateFlipType.Rotate90FlipNone : RotateFlipType.Rotate270FlipNone;

    try
    {
        RotateFile(original, turn, 95L, true);   // the original first: if it fails nothing else was changed
        foreach (int size in PhotoDerivatives.Sizes)   // the web copies carry no EXIF, so a plain turn is right
        {
            string path = PhotoDerivatives.PathFor(Server, size, fileName);
            if (File.Exists(path)) RotateFile(path, turn, 82L, false);
        }
    }
    catch (Exception ex) { Response.StatusCode = 500; Response.Write("Cannot rotate: " + ex.Message); return; }
    PhotoDerivatives.ForgetDimensions(Server, fileName);
    Response.Write("ok");
%>
<script runat="server">
    static void RotateFile(string path, RotateFlipType turn, long quality, bool bakeExif)
    {
        string tmp = path + ".tmp";
        using (var bmp = new Bitmap(path))
        {
            if (bakeExif) PhotoDerivatives.ApplyExifOrientation(bmp);   // the pixels now show the photo upright ...
            if (bakeExif) { try { bmp.RemovePropertyItem(0x0112); } catch (Exception) { } }   // ... so the orientation tag must go
            bmp.RotateFlip(turn);
            var codec = ImageCodecInfo.GetImageEncoders().First(c => c.MimeType == "image/jpeg");
            var ps = new EncoderParameters(1);
            ps.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, quality);
            bmp.Save(tmp, codec, ps);
        }
        File.Delete(path);
        File.Move(tmp, path);
    }
</script>
