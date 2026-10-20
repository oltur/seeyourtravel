<%@ Page Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%
    Guid userId = Tools.GetUserId(this);
    string fileName = Request["fileName"];

    var db = new SeeYourTravelEntities();
    Guid trackId = (from t in db.GetUserTracks(userId) where t.FileName==fileName select t.TrackID).FirstOrDefault();
    StringBuilder sb = new StringBuilder();

    Track track = new Track() { TrackID = trackId };
    db.Tracks.Attach(track);
    db.Tracks.Remove(track);
    db.SaveChanges();

    Response.Write(sb);
%>    
