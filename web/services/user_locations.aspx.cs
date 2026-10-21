using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;

// Sharing the position with other users is opt-in:
//   getsharing / setsharing  - read / change the signed-in user's consent (setsharing must be a POST from the page)
//   senduserlocation         - saves the position, ONLY for users who agreed (switching sharing off deletes the saved positions)
//   getfriendslocations      - last positions (rounded to ~100 m, at most one hour old) of the OTHER users who agreed,
//                              and only for a user who agreed too
public partial class services_user_locations : System.Web.UI.Page
{
    static bool tableChecked;
    static readonly object tableLock = new object();

    public class FriendRow
    {
        public Guid UserID { get; set; }
        public string UserName { get; set; }
        public double Lat { get; set; }
        public double Lng { get; set; }
        public DateTime Time { get; set; }
    }

    static void EnsureTable(SeeYourTravelEntities db)
    {
        if (tableChecked) return;
        lock (tableLock)
        {
            if (tableChecked) return;
            db.Database.ExecuteSqlCommand(
                "IF OBJECT_ID('dbo.LocationSharing') IS NULL CREATE TABLE dbo.LocationSharing (UserID uniqueidentifier NOT NULL PRIMARY KEY, Enabled bit NOT NULL, Updated datetime NOT NULL)");
            tableChecked = true;
        }
    }

    static bool IsSharing(SeeYourTravelEntities db, Guid userId)
    {
        return db.Database.SqlQuery<int>("SELECT COUNT(*) FROM dbo.LocationSharing WHERE UserID = @p0 AND Enabled = 1", userId).First() > 0;
    }

    void Json(string body)
    {
        Response.Clear();
        Response.Write(body);
        Response.End();
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        string action = Request.QueryString["action"] ?? "";
        string callback = Request.QueryString["callback"];
        if (string.IsNullOrEmpty(callback) || !Regex.IsMatch(callback, @"^[A-Za-z0-9_$.]{1,100}$"))
            callback = "callback";
        Func<string, string> jsonp = body => "/**/" + callback + "( " + body + " )";

        Response.ContentType = "application/javascript; charset=utf-8";
        Response.Headers.Add("X-Frame-Options", "SAMEORIGIN");
        Response.Headers.Add("Content-Disposition", "Attachment");
        Response.Cache.SetCacheability(HttpCacheability.NoCache);

        // the signed-in user comes from the session, never from the query string; guests have no position and no friends
        Guid userId = Tools.GetUserId(this);
        var js = new JavaScriptSerializer();
        var db = new SeeYourTravelEntities();
        try { EnsureTable(db); }
        catch (Exception ex) { Debug.WriteLine("[user_locations] " + ex.Message); Json(jsonp(action.Equals("getfriendslocations", StringComparison.OrdinalIgnoreCase) ? "[]" : "{}")); return; }

        if (action.Equals("getsharing", StringComparison.OrdinalIgnoreCase))
        {
            Json(jsonp(js.Serialize(new { enabled = userId != Guid.Empty && IsSharing(db, userId), signedIn = userId != Guid.Empty })));
        }
        else if (action.Equals("setsharing", StringComparison.OrdinalIgnoreCase))
        {
            // changing consent needs a POST made by the page itself (not a link or an image on another site)
            if (Request.HttpMethod != "POST" || Request.Headers["X-Requested-With"] != "XMLHttpRequest" || userId == Guid.Empty)
            {
                Response.StatusCode = 403;
                Json(jsonp("{\"error\":\"not allowed\"}"));
                return;
            }
            bool on = Request.Form["enabled"] == "1";
            db.Database.ExecuteSqlCommand(
                "MERGE dbo.LocationSharing AS t USING (SELECT @p0 AS UserID) AS s ON t.UserID = s.UserID " +
                "WHEN MATCHED THEN UPDATE SET Enabled = @p1, Updated = GETUTCDATE() " +
                "WHEN NOT MATCHED THEN INSERT (UserID, Enabled, Updated) VALUES (@p0, @p1, GETUTCDATE());", userId, on);
            if (!on)
                db.Database.ExecuteSqlCommand("DELETE FROM UserLocation WHERE UserID = @p0", userId);   // withdrawing consent removes the saved positions
            Json(jsonp(js.Serialize(new { enabled = on })));
        }
        else if (action.Equals("senduserlocation", StringComparison.OrdinalIgnoreCase))
        {
            double latV, lngV;
            int source;
            if (!int.TryParse(Request.QueryString["source"], out source)) source = 1;
            if (userId == Guid.Empty || !IsSharing(db, userId) ||
                !double.TryParse(Request.QueryString["lat"], NumberStyles.Float, CultureInfo.InvariantCulture, out latV) ||
                !double.TryParse(Request.QueryString["lng"], NumberStyles.Float, CultureInfo.InvariantCulture, out lngV))
            {
                Json(jsonp("{}"));
                return;
            }
            var userLocation = new UserLocation();
            userLocation.UserLocationID = Guid.NewGuid();
            userLocation.UserID = userId;
            userLocation.Lat = latV;
            userLocation.Lng = lngV;
            userLocation.Time = DateTime.UtcNow;
            userLocation.Source = source;
            db.UserLocations.Add(userLocation);
            try { db.SaveChanges(); }
            catch (Exception ex) { Debug.WriteLine("[user_locations] " + ex.Message); }
            Json(jsonp("{}"));
        }
        else if (action.Equals("getfriendslocations", StringComparison.OrdinalIgnoreCase))
        {
            if (userId == Guid.Empty || !IsSharing(db, userId)) { Json(jsonp("[]")); return; }
            var rows = db.Database.SqlQuery<FriendRow>(
                "SELECT u.UserID, u.UserName, l.Lat, l.Lng, l.Time " +
                "FROM dbo.LocationSharing s JOIN [User] u ON u.UserID = s.UserID " +
                "CROSS APPLY (SELECT TOP 1 Lat, Lng, Time FROM UserLocation WHERE UserID = s.UserID ORDER BY Time DESC) l " +
                "WHERE s.Enabled = 1 AND s.UserID <> @p0 AND l.Time > DATEADD(hour, -1, GETUTCDATE())", userId).ToList();
            var list = rows.Select(r => new
            {
                userId = r.UserID.ToString(),
                userName = r.UserName,
                lat = Math.Round(r.Lat, 3),
                lng = Math.Round(r.Lng, 3),
                time = r.Time.ToString("u")
            }).ToList();
            Json(jsonp(js.Serialize(list)));
        }
        else
        {
            Json(jsonp("{}"));
        }
    }
}
