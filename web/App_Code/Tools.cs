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
    public static bool LoginEnabled { get { return GoogleClientId.Length > 0; } }

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