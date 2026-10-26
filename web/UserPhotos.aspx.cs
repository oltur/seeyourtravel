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
using System.IO;

public partial class UserPhotos : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        Guid userId = Tools.GetUserId(this);
        if(userId == Guid.Empty || userId == new Guid("4324d1ff-b698-44b6-bc2a-d96f42d2300b"))
        {
            Response.Redirect("index.aspx");
        }

        if (this.IsPostBack)
        {
            SeeYourTravelEntities db = new SeeYourTravelEntities();

            HttpFileCollection files = Request.Files; // Load File collection into HttpFileCollection variable.
            var keys = files.Keys;  // This will get names of all files into a string array.
            for (int i= 0; i < keys.Count; i++)
            {
                Guid id = Guid.NewGuid();
                var file = files[i];
                var oldFileName = file.FileName;
                var ext = Path.GetExtension(oldFileName);
                var newFileName = id.ToString() + ext;
                var path = Server.MapPath("./data/images/" + newFileName);
                file.SaveAs(path);
                PhotoDerivatives.Create(Server, path);
                Location location = LocationExtractor.GetLocation(path);

                var image = new Image();
                image.ImageID = id;
                image.FileName = newFileName;
                image.Description = oldFileName;
                image.IsPublic = (Request["isPublic"] == "isPublic");
                image.Lat = location == null ? null : new double?(location.lat);
                image.Lng = location == null ? null : new double?(location.lng);
                image.Created = DateTime.Now;
                db.Images.Add(image);

                db.SaveChanges(); PhotoGuard.Invalidate();

                ImageUser imageUser = new ImageUser();
                imageUser.ImageUserID = Guid.NewGuid();
                imageUser.ImageID = image.ImageID;
                imageUser.UserID = userId;
                db.ImageUsers.Add(imageUser);

                db.SaveChanges(); PhotoGuard.Invalidate();
            }
        }
    }
}