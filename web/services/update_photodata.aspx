<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%
    Guid userId = Tools.GetUserId(this);
    var data = Request["data"];
    if (userId == Guid.Empty) { Response.StatusCode = 403; Response.ContentType = "text/plain"; Response.Write("Your session has expired: please reload the page and sign in again"); Response.End(); return; }
    if (string.IsNullOrEmpty(data) || data.Split(';').Length < 5) { Response.StatusCode = 400; Response.ContentType = "text/plain"; Response.Write("Bad request"); Response.End(); return; }
    string[] parts = data.Split(';');
    string fileName = parts[0];
    string name = parts[1];
    double lat, lng;
    bool hasLoc = double.TryParse(parts[3], System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out lat)
               & double.TryParse(parts[4], System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out lng);
    bool isPublic = (parts[2]!="0");   // keep the flag the photo already has (moving a photo must not change it)

    var db = new SeeYourTravelEntities();
    var image = (from t in db.GetUserImages(userId) where t.FileName==fileName select t).FirstOrDefault();
    StringBuilder sb = new StringBuilder();

    if (image == null) { Response.StatusCode = 404; Response.ContentType = "text/plain"; Response.Write("Photo not found"); Response.End(); return; }
    image.Description = name;
    if (hasLoc) { image.Lat = lat; image.Lng = lng; }   // photos without a position keep none
    image.IsPublic = isPublic;

//    db.Images.Attach(image);
    int nt = db.SaveChanges();

    Response.Write(sb);
%>    
