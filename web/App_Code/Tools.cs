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