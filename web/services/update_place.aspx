<%@ Page EnableSessionState="ReadOnly" Language="C#" %>
<%@ Import Namespace="System.Globalization" %>
<%
    Response.Clear();
    Response.ContentType = "text/plain";
    if (Request.HttpMethod != "POST" || Request.Headers["X-Requested-With"] != "XMLHttpRequest") { Response.StatusCode = 405; Response.Write("POST only"); Response.End(); return; }
    Guid userId = Tools.GetUserId(this);
    Guid placeId;
    double lat, lng;
    string name = (Request["name"] ?? "").Trim();
    string link = (Request["link"] ?? "").Trim();
    if (userId == Guid.Empty || !Guid.TryParse(Request["id"], out placeId)
        || !double.TryParse(Request["lat"], NumberStyles.Float, CultureInfo.InvariantCulture, out lat) || !double.TryParse(Request["lng"], NumberStyles.Float, CultureInfo.InvariantCulture, out lng)
        || lat < -90 || lat > 90 || lng < -180 || lng > 180 || name.Length == 0 || name.Length > 200 || link.Length > 500
        || (link.Length > 0 && !link.StartsWith("http://", StringComparison.OrdinalIgnoreCase) && !link.StartsWith("https://", StringComparison.OrdinalIgnoreCase)))
    { Response.StatusCode = 400; Response.Write("Check the name, the link (http:// or https://) and the coordinates"); Response.End(); return; }

    var db = new SeeYourTravelEntities();
    if (!db.GetUserPlaces(userId).Any(x => x.PlaceID == placeId)) { Response.StatusCode = 403; Response.Write("Not allowed"); Response.End(); return; }
    var place = db.Places.Find(placeId);
    if (place == null) { Response.StatusCode = 404; Response.Write("Place not found"); Response.End(); return; }
    place.Name = name;
    place.Link = link;
    place.Lat = lat;
    place.Lng = lng;
    place.IsPublic = Request["isPublic"] == "1";
    db.SaveChanges();
    Response.Write("OK");
%>
