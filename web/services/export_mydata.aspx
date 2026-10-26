<%@ Page EnableSessionState="ReadOnly" Language="C#" %>
<%
    Guid userId = Tools.GetUserId(this);
    if (userId == Guid.Empty || userId == new Guid("4324d1ff-b698-44b6-bc2a-d96f42d2300b"))
    {
        Response.StatusCode = 403;
        Response.ContentType = "text/plain";
        Response.Write("Please sign in");
        Response.End();
        return;
    }
    var db = new SeeYourTravelEntities();
    Response.Clear();
    Response.BufferOutput = false;
    Response.ContentType = "application/zip";
    Response.AddHeader("Content-Disposition", "attachment; filename=\"seeyourtravel-my-data-" + DateTime.UtcNow.ToString("yyyy-MM-dd") + ".zip\"");
    Response.AddHeader("Cache-Control", "no-store");
    var signIn = Tools.GetUserSignIn(this).Split('|')[0];
    AccountData.Export(Server, db, userId, Tools.GetUserName(this), signIn, Response.OutputStream);
    Response.Flush();
    Response.End();
%>
