using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class Logout : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Redirect("index.aspx"); // login is disabled
        Session.Remove("FacebookData");
        Session.Remove("FacebookToken");
        Session.Remove("UserId");
        Session.Remove("UserName");
        FormsAuthentication.SignOut();
    }
}