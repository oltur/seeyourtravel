using System;
using System.Web;
using System.Web.Security;
using System.Data.SqlClient;
using System.Configuration;
using System.Data;
//using System.Web.Helpers;
using System.Diagnostics;
using System.Web.Script.Serialization;
using System.Collections.Generic;
using System.Linq;

public partial class UserTracks : System.Web.UI.Page
{
    SeeYourTravelEntities db;
    protected void Page_Load(object sender, EventArgs e)
    {
        Guid userId = Tools.GetUserId(this);
        if(userId == Guid.Empty || userId == new Guid("4324d1ff-b698-44b6-bc2a-d96f42d2300b"))
        {
            Response.Redirect("index.aspx");
        }

        //var db = new SeeYourTravelEntities();
    }
}