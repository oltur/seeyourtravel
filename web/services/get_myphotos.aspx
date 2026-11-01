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

    var blocked = People.BlockedPhotoKeys();   // photos that show a blocked person: the page hides them
    StringBuilder sb = new StringBuilder();
    // the account's own photos; administrators see all of them (same rule as the GetUserImages function). Read straight from the database:
    // building 23,000 entity objects took about twice as long
    string sql = @"SELECT i.FileName, i.Description, i.IsPublic, i.Lat, i.Lng, i.Created FROM Image i
                   WHERE EXISTS (SELECT 1 FROM UserRole WHERE RoleID = '5195a2d5-0b51-44c4-b672-7383482bc77a' AND UserID = @u)
                      OR EXISTS (SELECT 1 FROM ImageUser tu WHERE tu.ImageID = i.ImageID AND tu.UserID = @u)
                   ORDER BY i.Created";
    using (var c = People.Open())
    using (var r = People.Cmd(c, sql, "@u", userId).ExecuteReader())
        while (r.Read())
        {
            string file = r.GetString(0), desc = r.IsDBNull(1) ? "" : r.GetString(1);
            if (sb.Length != 0)
                sb.Append("\n");
            sb.Append(file + ";" + (desc == "(EMPTY)" ? file : desc) + ";" + (r.GetBoolean(2) ? 1 : 0) + ";" + (r.IsDBNull(3) ? "" : r.GetDouble(3).ToString()) + ";" + (r.IsDBNull(4) ? "" : r.GetDouble(4).ToString()) + ";" + (blocked.Contains(Path.GetFileNameWithoutExtension(file).ToLowerInvariant()) ? 1 : 0) + ";" + (r.IsDBNull(5) ? "" : r.GetDateTime(5).ToString("yyyy-MM-dd")));   // taken date for the time filter
        }
    Response.Write(sb);
%>    
