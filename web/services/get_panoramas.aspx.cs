using System;
using System.Diagnostics;
using System.IO;
using System.Web;
using System.Xml;
using System.Linq;
using System.Text;
using System.Collections.Generic;

public partial class services_get_panoramas : System.Web.UI.Page
{
    private static Random rng = new Random();

    public void Shuffle<T>(IList<T> list)
    {
        int n = list.Count;
        while (n > 1)
        {
            n--;
            int k = rng.Next(n + 1);
            T value = list[k];
            list[k] = list[n];
            list[n] = value;
        }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        string callback = Request.QueryString["callback"];
        string set = Request.QueryString["set"];
        string size = Request.QueryString["size"];
        if (string.IsNullOrWhiteSpace(size))
            size = "medium";
        int from = int.Parse(Request.QueryString["from"]);
        int to = int.Parse(Request.QueryString["to"]);
        double minx =  double.Parse(Request.QueryString["minx"]);
        double miny = double.Parse(Request.QueryString["miny"]);
        double maxx = double.Parse(Request.QueryString["maxx"]);
        double maxy = double.Parse(Request.QueryString["maxy"]);
        double x = (minx+maxx)/2;
        double y = (miny+maxy)/2;
        StringBuilder items = new StringBuilder();

        string order = Request.QueryString["order"];

        Guid userId = Tools.GetUserId(this);

        var db = new SeeYourTravelEntities();
        var Images = (from t in db.GetUserAndPublicImagesByLocation(userId,miny,minx,maxy,maxx,0,10000) select t).ToList();

        Shuffle(Images);

        //XmlDocument doc = new XmlDocument();
        //    doc.Load(Server.MapPath(@"..\data\photos.xml"));
        //    string query = string.Format("//r[b>={2} and b<={3} and c>={0} and c<={1}][position() >= {4} and position() <= {5}]", minx, maxx, miny, maxy, from, to);
        //    XmlNodeList list = doc.SelectNodes(query);

        //    foreach (XmlElement elem in list)
        for (int i = from; i <= Math.Min(to,Images.Count-1);i++)
        {
            var Image = Images[i];
            string url = "./data/images/" + Path.GetFileName(Image.FileName);
            string urlThumbnail = "services/get_thumbnail.aspx?size=" + size + "&v=2&p=" + Path.GetFileNameWithoutExtension(Image.FileName);


            string localPath = Server.MapPath("../data/images/" + Path.GetFileName(Image.FileName));
            if (File.Exists(localPath))
            {
                if (items.Length > 0)
                    items.Append(",");
                items.Append("{\"height\":100,\"latitude\":" + ((decimal)Image.Lat).ToString() + ",\"longitude\":" + ((decimal)Image.Lng).ToString() + ",\"owner_id\":999999,\"owner_name\":\"-----\",\"owner_url\":\"http://www.example.com/\",\"photo_file_url\":\"" + urlThumbnail + "\",\"photo_id\":9999999999,\"photo_title\":\"TBD\",\"photo_url\":\"" + url + "\",\"upload_date\":\"1 January 1901\",\"width\":100}");
            }
        }

        // http://www.panoramio.com/map/get_panoramas.php?set=full&from=0&to=10&miny=47.955776&minx=10.096568999999999&maxy=48.055775999999994&maxx=10.196569&size=medium&mapfilter=true&order=popularity&callback=jQuery111207306344823446125_1436809161913&_=1436809161914

        //     /**/jQuery111206939764672424644_1428245949396({"count":13077,"has_more":true,"map_location":{"lat":48.475934500000001,"lon":29.627099594436846,"panoramio_zoom":11},"photos":[{"height":375,"latitude":46.638703999999997,"longitude":30.78603,"owner_id":13058,"owner_name":"Cyrill","owner_url":"http://www.panoramio.com/user/13058","photo_file_url":"http://mw2.google.com/mw-panoramio/photos/medium/97671.jpg","photo_id":97671,"photo_title":"kin-dza-dza","photo_url":"http://www.panoramio.com/photo/97671","upload_date":"09 December 2006","width":500},{"height":500,"latitude":48.292124000000001,"longitude":25.938113999999999,"owner_id":6389390,"owner_name":"EdwardTurJ","owner_url":"http://www.panoramio.com/user/6389390","photo_file_url":"http://mw2.google.com/mw-panoramio/photos/medium/65444724.jpg","photo_id":65444724,"photo_title":"Frosty Morning","photo_url":"http://www.panoramio.com/photo/65444724","place_id":"8042a62ade08f75fbf6e9f9902a802a90433d409","upload_date":"23 January 2012","width":375},{"height":333,"latitude":50.750559000000003,"longitude":26.043975,"owner_id":5639933,"owner_name":"Kostia Semytskyi","owner_url":"http://www.panoramio.com/user/5639933","photo_file_url":"http://mw2.google.com/mw-panoramio/photos/medium/77706532.jpg","photo_id":77706532,"photo_title":"\u0422\u0443\u043d\u0435\u043b\u044c \u043a\u043e\u0445\u0430\u043d\u043d\u044f / \u0422unnel of love","photo_url":"http://www.panoramio.com/photo/77706532","upload_date":"25 August 2012","width":500},{"height":497,"latitude":48.095083000000002,"longitude":35.021774000000001,"owner_id":4353734,"owner_name":"Buts_YV","owner_url":"http://www.panoramio.com/user/4353734","photo_file_url":"http://mw2.google.com/mw-panoramio/photos/medium/75587981.jpg","photo_id":75587981,"photo_title":"Dnieper. Sunset. \u0414\u043d\u0435\u043f\u0440. \u0417\u0430\u043a\u0430\u0442 ","photo_url":"http://www.panoramio.com/photo/75587981","upload_date":"18 July 2012","width":500}]})

        //Response.Cache.SetNoStore();
        //Response.Cache.SetNoServerCaching();
        //Response.Cache.SetMaxAge(new TimeSpan(0));
        //Response.Cache.SetCacheability(HttpCacheability.NoCache);
        //Response.Cache.AppendCacheExtension("no-store, must-revalidate");
        //Response.AppendHeader("Pragma", "no-cache");
        //Response.AppendHeader("Expires", "0");

        Response.ContentType = "application/javascript; charset=utf-8";
        Response.Headers.Add("X-Frame-Options", "SAMEORIGIN");
        Response.Headers.Add("Content-Disposition", "Attachment");

        string result = "/**/" + callback + "({\"count\":" + Images.Count + ",\"has_more\":false,\"map_location\":{\"lat\":" + y + ",\"lon\":" + x + ",\"panoramio_zoom\":5},\"photos\":[" + items.ToString() + "]})";

        Response.Write(result);
        
        Response.End();
    }
}