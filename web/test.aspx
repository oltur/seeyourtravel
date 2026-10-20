<%@ Page Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%
    Guid userId = Tools.GetUserId(this);
    Response.ContentType = "text/plain";

    var files = Directory.GetFiles(@"D:\Projects\__seeyourtravel\seeyourtravel.com\web\data\images", "*.*");

    StringBuilder sb = new StringBuilder();

    var db = new SeeYourTravelEntities();
    int i = 0;
    foreach (var file in files)
    {
        string fileName = Path.GetFileName(file);

        string query = string.Format("select i.filename from image i where filename in ('{0}')", fileName);

        var any = db.Database.SqlQuery<string>(query).Any();

        if (!any)
        {
            sb.AppendFormat("'{0}'<br/>,", fileName);

            File.Copy(file, file + "xxx");
        }
        i++;
    }
    Response.Write(sb);

%>    
