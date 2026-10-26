<%@ Page EnableSessionState="ReadOnly" Language="C#" %>
<%@ Import Namespace="System.Linq" %>
<%
    Response.ContentType = "text/plain";
    Guid userId = Tools.GetUserId(this);
    Guid placeId;
    if (userId == Guid.Empty || !Guid.TryParse(Request["id"], out placeId))
    {
        Response.StatusCode = 400;
        Response.Write("Bad request");
        Response.End();
        return;
    }

    var db = new SeeYourTravelEntities();
    // only places the user may see in the list (own ones; everything for administrators) can be deleted
    if (!db.GetUserPlaces(userId).Any(x => x.PlaceID == placeId))
    {
        Response.StatusCode = 403;
        Response.Write("Not allowed");
        Response.End();
        return;
    }
    var place = db.Places.Find(placeId);
    if (place != null)
    {
        db.PlaceUsers.RemoveRange(db.PlaceUsers.Where(x => x.PlaceID == placeId));
        db.PlaceImages.RemoveRange(db.PlaceImages.Where(x => x.PlaceID == placeId));
        db.PlaceTypePlaces.RemoveRange(db.PlaceTypePlaces.Where(x => x.PlaceID == placeId));
        db.Places.Remove(place);
        db.SaveChanges(); PhotoGuard.Invalidate();
    }
    Response.Write("OK");
%>
