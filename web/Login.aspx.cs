using System;
using System.Web;

public partial class Login : System.Web.UI.Page
{
    protected string ReturnUrl = "index.aspx";

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Tools.LoginEnabled)
            Response.Redirect("index.aspx"); // no Google client configured: local mode, everybody is signed in
        var r = Request.QueryString["ReturnUrl"];
        if (Tools.IsSafeReturnUrl(r)) ReturnUrl = r;
    }
}
