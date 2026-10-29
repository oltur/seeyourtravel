using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.SessionState;

/// <summary>
/// Access control for the photo files (data/images/* and data/thumbs/*).
/// A photo may be opened by anybody when it is public (or belongs to a public place) and otherwise only by the account it belongs to and by administrators (moderation).
/// Photos the database does not know are only opened for administrators.
/// </summary>
public static class PhotoGuard
{
    class Entry { public bool Public; public HashSet<Guid> Owners = new HashSet<Guid>(); }

    static Dictionary<string, Entry> cache;          // file name without extension (lower case) -> who may open it
    static DateTime loadedAt = DateTime.MinValue;
    static readonly object gate = new object();
    const int TtlSeconds = 60;                        // changes inside the site call Invalidate() and apply at once

    public static void Invalidate()
    {
        lock (gate) { cache = null; }
    }

    static Dictionary<string, Entry> Load()
    {
        lock (gate)
        {
            if (cache != null && (DateTime.UtcNow - loadedAt).TotalSeconds < TtlSeconds) return cache;
            var map = new Dictionary<string, Entry>();
            var db = new SeeYourTravelEntities();
            var publicPlaceImages = new HashSet<Guid>(
                (from pi in db.PlaceImages join p in db.Places on pi.PlaceID equals p.PlaceID where p.IsPublic select pi.ImageID).ToList());
            foreach (var i in db.Images.Select(x => new { x.ImageID, x.FileName, x.IsPublic }).ToList())
            {
                string key = Path.GetFileNameWithoutExtension(i.FileName ?? "").ToLowerInvariant();
                if (key.Length == 0) continue;
                map[key] = new Entry { Public = i.IsPublic || publicPlaceImages.Contains(i.ImageID) };
            }
            foreach (var iu in (from u in db.ImageUsers join i in db.Images on u.ImageID equals i.ImageID select new { u.UserID, i.FileName }).ToList())
            {
                Entry e;
                if (map.TryGetValue(Path.GetFileNameWithoutExtension(iu.FileName ?? "").ToLowerInvariant(), out e)) e.Owners.Add(iu.UserID);
            }
            cache = map;
            loadedAt = DateTime.UtcNow;
            return map;
        }
    }

    static Guid UserId(HttpContext ctx)
    {
        return (ctx.Session == null || ctx.Session["UserID"] == null) ? Guid.Empty : (Guid)ctx.Session["UserID"];
    }

    static bool IsAdmin(Guid userId)
    {
        if (userId == Guid.Empty) return false;
        if (userId == new Guid("00000000-0000-0000-0000-000000000000")) return true;
        try { return new SeeYourTravelEntities().IsAdmin(userId).First().Result == 1; } catch (Exception) { return false; }
    }

    /// <summary>While the file data/photos-admin-only.flag exists, every photo (public ones too) is opened by administrators only.</summary>
    public static bool AdminOnly(HttpContext ctx)
    {
        return File.Exists(ctx.Server.MapPath("~/data/photos-admin-only.flag"));
    }

    /// <summary>True when photos must not be listed at all for this request (admin-only mode and the visitor is no administrator).</summary>
    public static bool HideAll(HttpContext ctx)
    {
        return AdminOnly(ctx) && !IsAdmin(UserId(ctx));
    }

    /// <summary>May the person behind this request open the photo with this file name (the extension is ignored)?</summary>
    public static bool CanView(HttpContext ctx, string fileName)
    {
        if (AdminOnly(ctx)) return IsAdmin(UserId(ctx));
        string key = Path.GetFileNameWithoutExtension(fileName ?? "").ToLowerInvariant();
        Entry e;
        if (Load().TryGetValue(key, out e))
        {
            if (e.Public) return true;
            Guid uid = UserId(ctx);
            // the owner, and administrators (who moderate: they see every photo in the My photos list)
            return uid != Guid.Empty && (e.Owners.Contains(uid) || IsAdmin(uid));
        }
        return IsAdmin(UserId(ctx));
    }

    public static bool IsPublic(string fileName)
    {
        Entry e;
        return Load().TryGetValue(Path.GetFileNameWithoutExtension(fileName ?? "").ToLowerInvariant(), out e) && e.Public;
    }
}

/// <summary>Tells Global.asax which requests belong to PhotoHandler.</summary>
public static class PhotoRoute
{
    /// <summary>Files below data/images and data/thumbs must not be served by the web server's own static file handler: it would not check anything.</summary>
    public static IHttpHandler HandlerFor(HttpContext ctx)
    {
        string rel = ctx.Request.AppRelativeCurrentExecutionFilePath ?? "";
        if (rel.StartsWith("~/data/images/", StringComparison.OrdinalIgnoreCase) || rel.StartsWith("~/data/thumbs/", StringComparison.OrdinalIgnoreCase))
            return new PhotoHandler();
        return null;
    }
}

/// <summary>Serves the files below data/images and data/thumbs after the PhotoGuard check.</summary>
public class PhotoHandler : IHttpHandler, IReadOnlySessionState
{
    public bool IsReusable { get { return true; } }

    static string MimeOf(string path)
    {
        switch (Path.GetExtension(path).ToLowerInvariant())
        {
            case ".jpg": case ".jpeg": return "image/jpeg";
            case ".png": return "image/png";
            case ".gif": return "image/gif";
            case ".webp": return "image/webp";
            default: return null;
        }
    }

    public void ProcessRequest(HttpContext ctx)
    {
        // AppRelativeCurrentExecutionFilePath is "~/data/images/<name>" (decoded)
        string rel = ctx.Request.AppRelativeCurrentExecutionFilePath ?? "";
        string mime = MimeOf(rel);
        if (rel.Contains("..") || rel.IndexOf('\\') >= 0 || mime == null || !(rel.StartsWith("~/data/images/", StringComparison.OrdinalIgnoreCase) || rel.StartsWith("~/data/thumbs/", StringComparison.OrdinalIgnoreCase)))
        { Deny(ctx, 404); return; }

        string physical = ctx.Server.MapPath(rel);
        if (!File.Exists(physical)) { Deny(ctx, 404); return; }

        string name = Path.GetFileName(physical);
        if (!PhotoGuard.CanView(ctx, name)) { Deny(ctx, 404); return; }   // 404, not 403: do not reveal that the photo exists

        var res = ctx.Response;
        var modified = File.GetLastWriteTimeUtc(physical);
        modified = new DateTime(modified.Year, modified.Month, modified.Day, modified.Hour, modified.Minute, modified.Second, DateTimeKind.Utc);
        res.Cache.SetLastModified(modified);
        if (!PhotoGuard.AdminOnly(ctx) && PhotoGuard.IsPublic(name)) { res.Cache.SetCacheability(HttpCacheability.Public); res.Cache.SetMaxAge(TimeSpan.FromMinutes(5)); }
        else { res.Cache.SetCacheability(HttpCacheability.Private); res.Cache.SetNoStore(); }   // a private photo is never stored by shared caches

        DateTime since;
        string ims = ctx.Request.Headers["If-Modified-Since"];
        if (ims != null && DateTime.TryParse(ims, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.AdjustToUniversal | System.Globalization.DateTimeStyles.AssumeUniversal, out since) && modified <= since)
        { res.StatusCode = 304; return; }

        res.ContentType = mime;
        res.AppendHeader("X-Content-Type-Options", "nosniff");
        res.TransmitFile(physical);
    }

    static void Deny(HttpContext ctx, int code)
    {
        ctx.Response.StatusCode = code;
        ctx.Response.Cache.SetCacheability(HttpCacheability.NoCache);
        ctx.Response.ContentType = "text/plain";
        ctx.Response.Write("Not found");
    }
}
