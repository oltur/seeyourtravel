using System;
using System.Linq;
using System.Web;

public partial class Editor : System.Web.UI.Page
{
    protected Guid TrackId = Guid.Empty;
    protected string TrackFileName = "";
    protected bool IsExisting = false;   // the track is already saved (so it can be deleted)
    protected Guid UserId;

    SeeYourTravelEntities db;
    protected void Page_Load(object sender, EventArgs e)
    {
        UserId = Tools.GetUserId(this);
        db = new SeeYourTravelEntities();

        if (!IsCallback)
        {
            try
            {
                //var t = User.IsInRole("admin");
                if (Request["trackname"] != null)
                {
                    TrackFileName = Request["trackname"];
                    var t = db.GetTrackForUserByIdOrName(UserId, null, TrackFileName);
                    var track = t.FirstOrDefault();
                    TrackId = track.TrackID;
                    IsExisting = true;
                }
                else if (Request["trackid"] != null)
                {
                    TrackId = Guid.Parse(Request["trackid"]);
                    var track = db.GetTrackForUserByIdOrName(UserId, TrackId, null).FirstOrDefault();
                    TrackFileName = track.FileName;
                    IsExisting = true;
                }
                else
                {
                    TrackId = Guid.NewGuid();
                    TrackFileName = TrackId.ToString();
                }

             }
            catch (NullReferenceException ex)
            {
                TrackId = Guid.NewGuid();
                TrackFileName = TrackId.ToString();
            }
        }
    }
}