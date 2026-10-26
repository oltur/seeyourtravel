<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%
    Guid userId = Tools.GetUserId(this);
    var data = Request["data"];
    string[] parts = data.Split(';');
    string fileName = parts[0];
    string name = parts[1];
    double lat = double.Parse(parts[3]);
    double lng = double.Parse(parts[4]);
    bool isPublic = false;   // our own photos are private

    var db = new SeeYourTravelEntities();
    var image = (from t in db.GetUserImages(userId) where t.FileName==fileName select t).FirstOrDefault();
    StringBuilder sb = new StringBuilder();

    image.Description = name;
    image.Lat = lat;
    image.Lng = lng;
    image.IsPublic = isPublic;

//    db.Images.Attach(image);
    int nt = db.SaveChanges();

    Response.Write(sb);
%>    
