<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<%@ Import Namespace="Newtonsoft.Json.Linq" %>
<%
    Response.ContentType = "text/plain";

    //FileInfo[] files = new DirectoryInfo(Server.MapPath("..")).GetFiles("*.js");
    //StringBuilder sb = new StringBuilder();

    //foreach( FileInfo file in files)                                                                      
    //{
    //if(sb.Length != 0)
    //	sb.Append("\n");
    //sb.Append(Path.GetFileNameWithoutExtension(file.Name));
    //}
    //Response.Write(sb);

    Guid userId = Tools.GetUserId(this);

    var db = new SeeYourTravelEntities();
    var places = (from t in db.GetUserPlaces(userId) orderby t.Created select t).ToList();
    StringBuilder sb = new StringBuilder();

    var dict = places.Select(value => new { value, value.PlaceID })
                      .ToDictionary(pair => pair.PlaceID, pair => pair.value);
    string json = JsonConvert.SerializeObject(dict);
    //foreach (var place in Places)
    //{
    //    if (sb.Length != 0)
    //        sb.Append("\n");
    //    sb.Append(place.Name + ";" + place.Vicinity + ";" + (place.IsPublic ? 1 : 0) + ";" + place.Lat + ";" + place.Lng + ";" + place.Rating + ";" + place.FileName + ";" + place.PlaceID );
    //}
    sb.Append(json);
    Response.Write(sb);
%>    
