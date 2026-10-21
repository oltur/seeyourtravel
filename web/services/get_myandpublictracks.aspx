<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%
    Response.ContentType = "text/plain";

    //FileInfo[] files = new DirectoryInfo(Server.MapPath("..")).GetFiles("*.js");
    //StringBuilder sb = new StringBuilder();

    //foreach( FileInfo file in files)                                                                      
    //{
    //if(sb.Length != 0)
    //	sb.Append("\n");
    //sb.Append(Path.GetFileNameWithoutExtension(file.Name));
    //}
    //Response.Write(sb);

    Guid userId = Tools.GetUserId(this);

    string locale = Request["locale"];

    var db = new SeeYourTravelEntities();
    var tracks = (from t in db.GetUserandPublicTracks(userId, locale) orderby t.Category, t.Description select t).ToList();
    StringBuilder sb = new StringBuilder();

    foreach (var track in tracks)
    {
        if (sb.Length != 0)
            sb.Append("\n");
            sb.Append(track.FileName + ";" + track.Description + ";" + (track.IsPublic ? 1 : 0) + ";" + (track.Category) + ";" + track.ImageUrl + ";" + track.Location.Replace("\n", " ").Replace("\r", " "));
    }
    Response.Write(sb); Response.End();
%>    
