using System;
using System.Linq;

public partial class Index : System.Web.UI.Page
{
    protected Guid TrackId = Guid.Empty;
    protected string TrackFileName = "";
    protected Guid UserId;

    SeeYourTravelEntities db;
    protected void Page_Load(object sender, EventArgs e)
    {
        UserId = Tools.GetUserId(this);
        db = new SeeYourTravelEntities();

        try
        {
            //var t = User.IsInRole("admin");
            if (Request["trackname"] != null)
            {
                TrackFileName = Request["trackname"];
                var t = db.GetTrackForUserByIdOrName(UserId, null, TrackFileName);
                var track = t.FirstOrDefault();
                TrackId = track.TrackID;
            }
            else if (Request["trackid"] != null)
            {
                TrackId = Guid.Parse(Request["trackid"]);
                var track = db.GetTrackForUserByIdOrName(UserId, TrackId, null).FirstOrDefault();
                TrackFileName = track.FileName;
            }
            else
            {
                TrackId = Guid.NewGuid();
                TrackFileName = "";
            }
        }
        catch (NullReferenceException ex)
        {
            TrackId = Guid.NewGuid();
            TrackFileName = "";
        }
    }
}