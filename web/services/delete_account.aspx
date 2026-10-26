<%@ Page EnableSessionState="True" Language="C#" %>
<%@ Import Namespace="System.Web.Security" %>
<%
    Response.Clear();
    Response.ContentType = "text/plain";
    if (Request.HttpMethod != "POST" || Request.Headers["X-Requested-With"] != "XMLHttpRequest") { Response.StatusCode = 405; Response.Write("POST only"); Response.End(); return; }
    Guid userId = Tools.GetUserId(this);
    var db = new SeeYourTravelEntities();
    string why = AccountData.CannotDelete(db, userId);
    if (why != null) { Response.StatusCode = 403; Response.Write(why); Response.End(); return; }

    // the user has to type their own name
    var user = db.Users.First(u => u.UserID == userId);
    if (string.IsNullOrWhiteSpace(Request["confirm"]) || !string.Equals(Request["confirm"].Trim(), (user.UserName ?? "").Trim(), StringComparison.Ordinal))
    { Response.StatusCode = 400; Response.Write("The name does not match"); Response.End(); return; }

    string done = AccountData.Delete(Server, db, userId);

    Session.Remove("FacebookData");
    Session.Remove("FacebookToken");
    Session.Remove("UserId");
    Session.Remove("UserName");
    FormsAuthentication.SignOut();
    Response.Write("OK " + done);
%>
