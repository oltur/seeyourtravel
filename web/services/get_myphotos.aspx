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

    var db = new SeeYourTravelEntities();
    var Images = (from t in db.GetUserImages(userId) orderby t.Created select t).ToList();
    StringBuilder sb = new StringBuilder();
    var blocked = People.BlockedPhotoKeys();   // photos that show a blocked person: the page hides them

    foreach (var Image in Images)
    {
        if (sb.Length != 0)
            sb.Append("\n");
        sb.Append(Image.FileName + ";" + (Image.Description == "(EMPTY)" ? Image.FileName : Image.Description) + ";" + (Image.IsPublic ? 1 : 0) + ";" + Image.Lat + ";" + Image.Lng + ";" + (blocked.Contains(Path.GetFileNameWithoutExtension(Image.FileName).ToLowerInvariant()) ? 1 : 0));
    }
    Response.Write(sb);
%>    
