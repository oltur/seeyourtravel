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

public partial class UserPlaces : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        Guid userId = Tools.GetUserId(this);
        if (userId == Guid.Empty || userId == new Guid("4324d1ff-b698-44b6-bc2a-d96f42d2300b"))
        {
            Response.Redirect("index.aspx");
        }

        if (this.IsPostBack)
        {
            SeeYourTravelEntities db = new SeeYourTravelEntities();

            Guid? imageId = null;

            var placeId = Guid.NewGuid();
            var placeDescription = Request["placeDescription"];
            var placeLink = Request["placeLink"];
            var placeLatLng = Request["placeLatLng"].Split(';');
            var placeisPublic = Request["isPublic"];

            Location location = new Location(double.Parse(placeLatLng[0]), double.Parse(placeLatLng[1]));

            HttpFileCollection files = Request.Files; // Load File collection into HttpFileCollection variable.
            var keys = files.Keys;  // This will get names of all files into a string array.
            for (int i = 0; i < keys.Count; i++)
            {
                imageId = Guid.NewGuid();
                var file = files[i];
                var oldFileName = file.FileName;
                var ext = Path.GetExtension(oldFileName);
                var newFileName = imageId.ToString() + ext;
                var path = Server.MapPath("./data/images/" + newFileName);
                file.SaveAs(path);
                PhotoDerivatives.Create(Server, path);
                Location photoLocation = LocationExtractor.GetLocation(path);

                var image = new Image();
                image.ImageID = imageId.Value;
                image.FileName = newFileName;
                image.Description = oldFileName;
                image.IsPublic = (Request["isPublic"] == "isPublic");
                image.Lat = photoLocation == null ? null : new double?(photoLocation.lat);
                image.Lng = photoLocation == null ? null : new double?(photoLocation.lng);
                image.Created = DateTime.Now;
                db.Images.Add(image);

                db.SaveChanges();

                ImageUser imageUser = new ImageUser();
                imageUser.ImageUserID = Guid.NewGuid();
                imageUser.ImageID = image.ImageID;
                imageUser.UserID = userId;
                db.ImageUsers.Add(imageUser);

                db.SaveChanges();
            }

            Place place = new Place();
            place.PlaceID = placeId;
            place.Name = placeDescription;
            place.IsPublic = (Request["isPublic"] == "isPublic");
            place.Lat = (location.lat);
            place.Lng = (location.lng);
            place.Created = DateTime.Now;
            place.Link = placeLink;
            place.Rating = 3; // TBD: fix
            place.Vicinity = ""; // TBD: fix
            place.Description = "";
            db.Places.Add(place);

            db.SaveChanges();

            PlaceUser placeUser = new PlaceUser();
            placeUser.PlaceUserID = Guid.NewGuid();
            placeUser.PlaceID = place.PlaceID;
            placeUser.UserID = userId;
            db.PlaceUsers.Add(placeUser);

            db.SaveChanges();

            if (imageId.HasValue)
            {
                PlaceImage placeImage = new PlaceImage();
                placeImage.PlaceImageID = Guid.NewGuid();
                placeImage.PlaceID = place.PlaceID;
                placeImage.ImageID = imageId.Value;
                db.PlaceImages.Add(placeImage);

                db.SaveChanges();
            }
        }
    }
}