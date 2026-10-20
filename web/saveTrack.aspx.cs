using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.IO;
using System.Linq;
using System.Threading;
using System.Web;

public partial class SaveTrack : System.Web.UI.Page
{
    protected Guid TrackId = Guid.Empty;
    protected string TrackFileName = "";

    HttpFileCollection files;
    Guid trackId;

    protected void Page_Load(object sender, EventArgs e)
    {
        try
        {
            trackId = Guid.Parse(Request.Form["trackId"]);
            files = Request.Files; // Load File collection into HttpFileCollection variable.
            var keys = files.Keys;  // This will get names of all files into a string array.

            string audioFileName = SaveFileByKey("fileAudio", Request.Form["audioSrc"]);
            string imageFileName = SaveFileByKey("fileImage", Request.Form["trackImage"]);
            string textFileName = SaveFileByKey("fileText", Request.Form["textToRead"]);

            string trackFileName = Request.Form["trackFileName"];
            string trackDescription = Request.Form["name"];
            string path = Server.MapPath(".") + "\\tracks\\" + trackId.ToString() + ".js";
            string category = "Other";
            if (!string.IsNullOrEmpty(Request.Form["category"]))
                category = Request.Form["category"];

            string trackData = Request.Form["trackData"];

            using (System.IO.StreamWriter writer = new System.IO.StreamWriter(path, false))
            {
                writer.WriteLine("{");

                writer.WriteLine("\"name\":\"" + Request.Form["name"] + "\"");
                writer.Write(",");
                writer.WriteLine("\"isPublic\":\"" + ((Request.Form["isPublic"]== "isPublic") ?"Yes":"No") + "\"");
                
                if (!string.IsNullOrEmpty(Request.Form["travelWith"]))
                {
                    writer.Write(",");
                    writer.WriteLine("\"travelWith\":\"" + Request.Form["travelWith"] + "\"");
                }
                if (!string.IsNullOrEmpty(Request.Form["copyright"]))
                {
                    writer.Write(",");
                    writer.WriteLine("\"copyright\":\"" + Request.Form["copyright"] + "\"");
                }
                if (!string.IsNullOrEmpty(Request.Form["defaultScale"]))
                {
                    writer.Write(",");
                    writer.WriteLine("\"defaultScale\":" + Request.Form["defaultScale"] + "");
                }
                if (!string.IsNullOrEmpty(Request.Form["photoLocationTolerancy"]))
                {
                    writer.Write(",");
                    writer.WriteLine("\"photoLocationTolerancy\":" + Request.Form["photoLocationTolerancy"] + "");
                }
                if (!string.IsNullOrEmpty(Request.Form["stepsToRedraw"]))
                {
                    writer.Write(",");
                    writer.WriteLine("\"stepsToRedraw\":" + Request.Form["stepsToRedraw"] + "");
                }
                if (!string.IsNullOrEmpty(Request.Form["stepsToShowPhoto"]))
                {
                    writer.Write(",");
                    writer.WriteLine("\"stepsToShowPhoto\":" + Request.Form["stepsToShowPhoto"] + "");
                }
                if (!string.IsNullOrEmpty(Request.Form["numOfPhotos"]))
                {
                    writer.Write(",");
                    writer.WriteLine("\"numOfPhotos\":" + Request.Form["numOfPhotos"] + "");
                }
                else
                {
                    writer.Write(",");
                    writer.WriteLine("\"numOfPhotos\":10");
                }

                if (!string.IsNullOrEmpty(Request.Form["velocityMetersPerSec"]))
                {
                    writer.Write(",");
                    writer.WriteLine("\"velocityMetersPerSec\":" + Request.Form["velocityMetersPerSec"] + "");
                }
                if (!string.IsNullOrEmpty(Request.Form["icon"]))
                {
                    writer.Write(",");
                    writer.WriteLine("\"icon\":\"" + Request.Form["icon"] + "\"");
                }

                writer.Write(",");
                writer.WriteLine("\"useFlickrImages\":\"" + ((Request.Form["useFlickrImages"] == "on") ? "Yes" : "No") + "\"");
                writer.Write(",");
                writer.WriteLine("\"useSYTImagesTrack\":\"" + ((Request.Form["useSYTImagesTrack"] == "on") ? "Yes" : "No") + "\"");
                writer.Write(",");
                writer.WriteLine("\"useGooglePlaces\":\"" + ((Request.Form["useGooglePlaces"] == "on") ? "Yes" : "No") + "\"");
                writer.Write(",");
                writer.WriteLine("\"useSYTPlaces\":\"" + ((Request.Form["useSYTPlaces"] == "on") ? "Yes" : "No") + "\"");

                writer.Write(",");
                writer.WriteLine("\"trackImage\":\"" + imageFileName + "\"");

                writer.Write(",");
                writer.WriteLine("\"audioSrc\":\"" + audioFileName + "\"");

                writer.Write(",");
                writer.WriteLine("\"textToRead\":\"" + textFileName + "\"");

                if (!string.IsNullOrEmpty(Request.Form["trackGpx"]))
                {
                    writer.Write(",");
                    writer.WriteLine("\"trackGpx\":\"" + Request.Form["trackGpx"] + "\"");
                }
                else
                {
                    writer.Write(",");
                    writer.WriteLine("\"trackData\":" + trackData);
                }
                writer.Write(",");
                writer.WriteLine("\"category\":\"" + category + "\"");

                writer.WriteLine("}");
            }

            var db = new SeeYourTravelEntities();
            Guid userId = Tools.GetUserId(this);
            Track track = db.Tracks.FirstOrDefault(t => t.TrackID == trackId);
            if (track == null)
            {
                track = new Track();
                track.TrackID = trackId;
                db.Tracks.Add(track);
            }
            track.FileName = trackId.ToString();
            track.CreatedBy = userId.ToString();
            track.Created = DateTime.Now;
            track.Description = trackDescription;
            track.IsPublic = (Request.Form["isPublic"] == "isPublic");
            track.Category = category;
            track.ImageUrl = string.IsNullOrWhiteSpace(Request.Form["trackImage"]) ? "" : Request.Form["trackImage"];

            if(!string.IsNullOrWhiteSpace(trackData) && trackData.Length > 5)
            {
                dynamic d = JArray.Parse(trackData);
                track.Location = d[0].ToString();
            }
            else
            {
                track.Location = "";
            }

            db.SaveChanges();

            TrackUser trackUser = db.TrackUsers.FirstOrDefault(tu => (tu.TrackID == track.TrackID && tu.UserID == userId));
            if (trackUser == null)
            {
                trackUser = new TrackUser();
                trackUser.TrackUserID = Guid.NewGuid();
                trackUser.TrackID = track.TrackID;
                trackUser.UserID = userId;
                db.TrackUsers.Add(trackUser);

                db.SaveChanges();
            }

            Response.Redirect("./index.aspx?trackid=" + trackId);
        }
        catch (ThreadAbortException)
        {

        }
        catch (Exception ex)
        {
            string message = ex.Message;
            Response.Redirect("./index.aspx?errorMessage=" + HttpUtility.UrlEncode(message));
        }

    }

    private string SaveFileByKey(string key, string defaultFileName)
    {
        if (defaultFileName == null)
            defaultFileName = "";
        var file = files[key];
        if (file == null || file.ContentLength == 0)
            return defaultFileName;
        var oldFileName = file.FileName;
        var ext = Path.GetExtension(oldFileName);
        var newFileName = trackId.ToString() + ext;
        var path = Server.MapPath("./tracks/content/" + newFileName);
        file.SaveAs(path);
        return newFileName;
    }
}