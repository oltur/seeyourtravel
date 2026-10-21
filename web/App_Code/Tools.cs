using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;

/// <summary>
/// Summary description for Tools
/// </summary>
public static class Tools
{
    // Google sign-in is on when GoogleClientId is set in Web.config; otherwise everybody is auto-signed-in (local dev mode).
    public static string GoogleClientId
    {
        get { return (System.Configuration.ConfigurationManager.AppSettings["GoogleClientId"] ?? "").Trim(); }
    }
    /// <summary>
    /// Address of a static file (relative to the site root) with a version taken from its modification time,
    /// e.g. js/OurTravel.js?v=1d9b2c3a4f - so browsers and Cloudflare fetch a changed file immediately instead of an old cached copy.
    /// <paramref name="prefix"/> is for pages in a sub folder, e.g. "../".
    /// </summary>
    public static string V(string path, string prefix = "")
    {
        try
        {
            var clean = path.Replace("//", "/").TrimStart('/');
            var file = HttpContext.Current.Server.MapPath("~/" + clean);
            if (System.IO.File.Exists(file))
                return prefix + path + "?v=" + System.IO.File.GetLastWriteTimeUtc(file).Ticks.ToString("x");
        }
        catch (Exception) { }
        return prefix + path;
    }

    /// <summary>Like V, for a file whose address on the page differs from its path under the site root.</summary>
    public static string VAt(string siteRootPath, string url)
    {
        try
        {
            var file = HttpContext.Current.Server.MapPath("~/" + siteRootPath.TrimStart('/'));
            if (System.IO.File.Exists(file))
                return url + "?v=" + System.IO.File.GetLastWriteTimeUtc(file).Ticks.ToString("x");
        }
        catch (Exception) { }
        return url;
    }

    public static bool LoginEnabled { get { return GoogleClientId.Length > 0; } }

    // True when the request came through a reverse proxy / Cloudflare tunnel.
    public static bool IsProxied(HttpRequest r)
    {
        return r.Headers["X-Forwarded-For"] != null || r.Headers["CF-Connecting-IP"] != null || r.Headers["CF-Ray"] != null || r.Headers["X-Forwarded-Host"] != null;
    }

    // Local mode (everybody is signed in as the owner) is only for direct local access, never through a proxy/tunnel.
    public static bool AutoLogin(HttpRequest r)
    {
        return !LoginEnabled && !IsProxied(r);
    }

    // The original request was HTTPS (TLS is terminated by Cloudflare, the app itself sees plain HTTP).
    public static bool IsHttps(HttpRequest r)
    {
        return r.IsSecureConnection || string.Equals(r.Headers["X-Forwarded-Proto"], "https", StringComparison.OrdinalIgnoreCase)
            || (r.Headers["CF-Visitor"] ?? "").Contains("\"scheme\":\"https\"");
    }

    public static string ClientIp(HttpRequest r)
    {
        return r.Headers["CF-Connecting-IP"] ?? r.UserHostAddress;
    }

    // "email=UserName;email2=UserName2": Google accounts that are administrators, and the existing user each one maps to.
    public static Dictionary<string, string> GoogleAdmins()
    {
        var map = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var raw = System.Configuration.ConfigurationManager.AppSettings["GoogleAdmins"] ?? "";
        foreach (var part in raw.Split(new[] { ';' }, StringSplitOptions.RemoveEmptyEntries))
        {
            var kv = part.Split(new[] { '=' }, 2);
            var email = kv[0].Trim();
            if (email.Length > 0) map[email] = (kv.Length > 1 && kv[1].Trim().Length > 0) ? kv[1].Trim() : email;
        }
        return map;
    }

    public static bool IsSafeReturnUrl(string url)
    {
        return !string.IsNullOrEmpty(url) && !url.Contains("://") && !url.StartsWith("//") && !url.StartsWith("\\") && !url.StartsWith("/\\");
    }

    public static Guid GetUserId(Page page)
    {
        return (page.Session["UserID"] == null) ? Guid.Empty : (Guid)page.Session["UserID"];
    }
    public static string GetUserName(Page page)
    {
        return (page.Session["UserName"] == null) ? "Guest" : page.Session["UserName"].ToString();
    }
    public static bool IsGuest(Page page)
    {
        var db = new SeeYourTravelEntities();
        return db.IsGuest(GetUserId(page)).First().Result == 1;
    }
    public static string GetUserInformation(Page page)
    {
        var db = new SeeYourTravelEntities();
        var currentUserID = (Guid)page.Session["UserId"];
        var isAdmin = db.IsAdmin(currentUserID).First().Result == 1;
        var user = db.Users.Where(x => x.UserID == currentUserID).First();
        return "Name: " + user.UserName + (isAdmin ? " (Administrator) " : "") + (IsGuest(page) ? " (Guest) " : "")
            + "Facebook ID: " + (string.IsNullOrWhiteSpace(user.FacebookId) ? " None ": user.FacebookId)
            + " Images: " + user.ImageUsers.Count()
            + " Places: " + user.PlaceUsers.Count()
            + " Tracks: " + user.TrackUsers.Count();
    }
}