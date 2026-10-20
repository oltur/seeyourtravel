using System;
using System.Web;
using System.Web.Security;

public partial class Logout : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Tools.LoginEnabled)
            Response.Redirect("index.aspx"); // local mode: nothing to log out of

        // the same button logs in (for guests) and out
        bool wasGuest = Tools.GetUserId(this) == Guid.Empty;
        Session.Remove("FacebookData");
        Session.Remove("FacebookToken");
        Session.Remove("UserId");
        Session.Remove("UserName");
        FormsAuthentication.SignOut();
        Response.Redirect(wasGuest ? "Login.aspx" : "index.aspx");
    }
}
