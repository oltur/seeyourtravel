<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.Linq" %>
<%
    // POST action = private | public | delete, ids = photo file names separated by line breaks (only the caller's own photos; administrators may touch all)
    Response.ContentType = "text/plain"; Response.Cache.SetCacheability(HttpCacheability.NoCache);
    Guid userId = Tools.GetUserId(this);
    if (userId == Guid.Empty) { Response.StatusCode = 403; Response.Write("Your session has expired: please reload the page and sign in again"); Response.End(); return; }
    string action = Request.Form["action"];
    var ids = (Request.Form["ids"] ?? "").Split(new[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries).Select(s => s.Trim()).Where(s => s.Length > 0).Distinct().ToList();
    if ((action != "private" && action != "public" && action != "delete") || ids.Count == 0 || ids.Count > 20000) { Response.StatusCode = 400; Response.Write("Bad request"); Response.End(); return; }

    var db = new SeeYourTravelEntities();
    var wanted = new System.Collections.Generic.HashSet<string>(ids, StringComparer.OrdinalIgnoreCase);
    var mine = db.GetUserImages(userId).Select(x => new { x.ImageID, x.FileName }).Distinct().ToList().Where(x => wanted.Contains(x.FileName)).ToList();
    int n = 0;
    for (int i = 0; i < mine.Count; i += 400)
    {
        var part = mine.Skip(i).Take(400).Select(x => "'" + x.ImageID.ToString() + "'").ToList();   // GUIDs read from the database
        string inList = string.Join(",", part);
        if (action == "delete") db.Database.ExecuteSqlCommand("DELETE FROM Image WHERE ImageID IN (" + inList + ")");   // ImageUser, PlaceImage cascade
        else db.Database.ExecuteSqlCommand("UPDATE Image SET IsPublic = " + (action == "public" ? "1" : "0") + " WHERE ImageID IN (" + inList + ")");
        n += part.Count;
    }
    PhotoGuard.Invalidate();
    Response.Write(n);
%>
