using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web;

// Places of SeeYourTravel users inside a bounding box: the signed-in user's own places and the public ones.
// The answer is shaped like the Wikipedia places the map already shows (id, name, thumb, geometry).
public partial class services_get_places : System.Web.UI.Page
{
    static bool TryD(string s, out double d)
    {
        return double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out d);
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        string callback = Request.QueryString["callback"];
        if (string.IsNullOrEmpty(callback) || callback.Any(c => !(char.IsLetterOrDigit(c) || c == '_' || c == '$' || c == '.')))
            callback = "callback";

        var results = new List<object>();
        double minx, miny, maxx, maxy;
        if (TryD(Request.QueryString["minx"], out minx) && TryD(Request.QueryString["miny"], out miny)
            && TryD(Request.QueryString["maxx"], out maxx) && TryD(Request.QueryString["maxy"], out maxy))
        {
            Guid userId = Tools.GetUserId(this);
            var db = new SeeYourTravelEntities();
            var places = db.Places
                .Where(p => p.Lat >= miny && p.Lat <= maxy && p.Lng >= minx && p.Lng <= maxx)
                .Where(p => p.IsPublic || p.PlaceUsers.Any(u => u.UserID == userId))
                .OrderBy(p => p.Created)
                .Take(60)
                .ToList();

            foreach (var place in places)
            {
                // only a place that its owner made public shows its photo to everybody
                string thumb = "";
                if (place.IsPublic)
                {
                    var file = (from pi in db.PlaceImages where pi.PlaceID == place.PlaceID join i in db.Images on pi.ImageID equals i.ImageID select i.FileName).FirstOrDefault();
                    if (!string.IsNullOrEmpty(file)) thumb = "services/get_thumbnail.aspx?size=small&p=" + Uri.EscapeDataString(file);
                }
                string link = place.Link ?? "";
                if (!link.StartsWith("http://", StringComparison.OrdinalIgnoreCase) && !link.StartsWith("https://", StringComparison.OrdinalIgnoreCase)) link = "";
                results.Add(new
                {
                    id = "syt-" + place.PlaceID,
                    name = place.Name,
                    link = link,
                    thumb = thumb,
                    types = "syt",
                    photos = new[] { new { raw_reference = new { fife_url = thumb.Length > 0 ? thumb : "img/something.png" } } },
                    geometry = new { location = new { lat = place.Lat, lng = place.Lng } }
                });
            }
        }

        Response.ContentType = "application/javascript; charset=utf-8";
        Response.Headers.Add("X-Frame-Options", "SAMEORIGIN");
        Response.Headers.Add("X-Content-Type-Options", "nosniff");
        Response.Write("/**/" + callback + "( " + new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(new { results = results, status = "OK" }) + " )");
        Response.End();
    }
}
