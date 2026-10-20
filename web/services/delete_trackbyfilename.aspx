<%@ Page Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%
    // Deletes a track owned by the current user (or any track, for administrators). Answers "OK" or an error text.
    Response.ContentType = "text/plain";
    Guid userId = Tools.GetUserId(this);
    string fileName = Request["fileName"];
    Guid parsed;

    if (userId == Guid.Empty) { Response.StatusCode = 403; Response.Write("Please sign in"); Response.End(); }
    if (string.IsNullOrWhiteSpace(fileName) || !Guid.TryParse(fileName.Replace(".js", ""), out parsed) && fileName.IndexOfAny(new[] { '/', '\\', ':' }) >= 0)
    { Response.StatusCode = 400; Response.Write("Bad track name"); Response.End(); }

    var db = new SeeYourTravelEntities();
    bool isAdmin = db.IsAdmin(userId).First().Result == 1;
    var track = db.GetUserTracks(userId).Where(t => t.FileName == fileName).Select(t => t.TrackID).FirstOrDefault();
    Guid trackId = track;
    if (trackId == Guid.Empty && isAdmin)
        trackId = db.Tracks.Where(t => t.FileName == fileName).Select(t => t.TrackID).FirstOrDefault();
    if (trackId == Guid.Empty) { Response.StatusCode = 404; Response.Write("Track not found"); Response.End(); }

    foreach (var tu in db.TrackUsers.Where(x => x.TrackID == trackId).ToList()) db.TrackUsers.Remove(tu);
    var entity = db.Tracks.First(t => t.TrackID == trackId);
    string file = entity.FileName;
    db.Tracks.Remove(entity);
    db.SaveChanges();

    try { string p = Server.MapPath("~/tracks/" + file + ".js"); if (File.Exists(p)) File.Delete(p); } catch (Exception) { }
    Response.Write("OK");
%>
