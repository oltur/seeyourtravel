<%@ WebHandler Language="C#" Class="GoogleLoginHandler" %>

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.Security;
using System.Web.SessionState;

// Receives the Google Sign-In ID token (POST "credential"), verifies it with Google and signs the user in.
public class GoogleLoginHandler : IHttpHandler, IRequiresSessionState
{
    public bool IsReusable { get { return false; } }

    public void ProcessRequest(HttpContext ctx)
    {
        ctx.Response.ContentType = "application/json";
        string error = null;
        try
        {
            if (!Tools.LoginEnabled) { error = "Google login is not configured"; }
            else
            {
                var info = Verify(ctx.Request.Form["credential"], out error);
                if (info != null)
                {
                    string name = info.ContainsKey("name") ? Convert.ToString(info["name"]) : null;
                    string shown = CompleteLogin(ctx, Convert.ToString(info["email"]), name, out error);
                    if (shown != null)
                    {
                        ctx.Response.Write(new JavaScriptSerializer().Serialize(new { ok = true, name = shown }));
                        return;
                    }
                }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Trace.WriteLine("[GoogleLogin] " + ex);
            error = "Login failed";
        }
        ctx.Response.SuppressFormsAuthenticationRedirect = true;
        ctx.Response.StatusCode = 401;
        ctx.Response.Write(new JavaScriptSerializer().Serialize(new { ok = false, error = error ?? "Login failed" }));
    }

    // Asks Google whether the token is valid, then checks audience, issuer, expiry and e-mail verification.
    static Dictionary<string, object> Verify(string credential, out string error)
    {
        error = null;
        if (string.IsNullOrEmpty(credential) || credential.Length > 4096) { error = "No credential"; return null; }
        string json;
        try
        {
            var req = (HttpWebRequest)WebRequest.Create("https://oauth2.googleapis.com/tokeninfo?id_token=" + Uri.EscapeDataString(credential));
            req.Timeout = 10000;
            using (var resp = (HttpWebResponse)req.GetResponse())
            using (var rd = new StreamReader(resp.GetResponseStream()))
                json = rd.ReadToEnd();
        }
        catch (WebException) { error = "Google rejected the token"; return null; }

        var info = new JavaScriptSerializer().Deserialize<Dictionary<string, object>>(json);
        Func<string, string> get = k => info.ContainsKey(k) ? Convert.ToString(info[k]) : "";
        long exp;
        if (get("aud") != Tools.GoogleClientId) { error = "Token is for another application"; return null; }
        if (get("iss") != "accounts.google.com" && get("iss") != "https://accounts.google.com") { error = "Bad issuer"; return null; }
        if (!long.TryParse(get("exp"), out exp) || exp < DateTimeOffset.UtcNow.ToUnixTimeSeconds()) { error = "Token expired"; return null; }
        if (get("email_verified").ToLowerInvariant() != "true" || get("email").Length == 0) { error = "E-mail is not verified"; return null; }
        return info;
    }

    // Finds or creates the user for this Google account, grants admin to the configured accounts and signs in.
    // Returns the user name shown in the UI, or null (with error set).
    public static string CompleteLogin(HttpContext ctx, string email, string displayName, out string error)
    {
        error = null;
        email = email.Trim().ToLowerInvariant();
        var db = new SeeYourTravelEntities();
        var admins = Tools.GoogleAdmins();
        string mappedName;
        bool isConfiguredAdmin = admins.TryGetValue(email, out mappedName);
        string key = "google:" + email;

        User user;
        if (isConfiguredAdmin)
        {
            // administrators sign in as an existing user (the owner of the data), found by name
            user = db.Users.FirstOrDefault(u => u.UserName == mappedName);
        }
        else
        {
            user = db.Users.FirstOrDefault(u => u.FacebookId == key);
        }
        if (user == null)
        {
            user = new User();
            user.UserID = Guid.NewGuid();
            user.FacebookId = key;
            user.UserName = isConfiguredAdmin ? mappedName : (string.IsNullOrWhiteSpace(displayName) ? email : displayName);
            user.UserPassword = Guid.NewGuid().ToString();
            user.Disabled = false;
            db.Users.Add(user);
            db.SaveChanges();
        }
        if (user.Disabled == true) { error = "This account is disabled"; return null; }

        if (isConfiguredAdmin)
        {
            var adminRole = db.Roles.First(r => r.RoleName == "admin");
            var id0 = user.UserID;
            if (!db.UserRoles.Any(r => r.UserID == id0 && r.RoleID == adminRole.RoleID))
            {
                db.UserRoles.Add(new UserRole { UserRoleID = Guid.NewGuid(), UserID = id0, RoleID = adminRole.RoleID });
                db.SaveChanges();
            }
        }

        var login = new UserLogin();
        login.UserLoginID = Guid.NewGuid();
        login.UserID = user.UserID;
        login.Time = DateTime.UtcNow;
        login.LoginType = "Google";
        login.CallerIp = ctx.Request.UserHostAddress;
        login.CallerAgent = ctx.Request.UserAgent;
        login.CalledUrl = ctx.Request.Url.OriginalString;
        db.UserLogins.Add(login);
        db.SaveChanges();

        ctx.Session["UserId"] = user.UserID;
        ctx.Session["UserName"] = user.UserName;
        bool admin = db.IsAdmin(user.UserID).First().Result == 1;
        var ticket = new FormsAuthenticationTicket(2, user.UserID.ToString(), DateTime.Now, DateTime.Now.AddDays(30), true, admin ? "admin" : "");
        var cookie = new HttpCookie(FormsAuthentication.FormsCookieName, FormsAuthentication.Encrypt(ticket));
        cookie.HttpOnly = true;
        cookie.Expires = ticket.Expiration;
        ctx.Response.Cookies.Add(cookie);
        return user.UserName;
    }
}
