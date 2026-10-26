<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%
    Guid userId = Tools.GetUserId(this);
    string fileName = Request["fileName"];

    var db = new SeeYourTravelEntities();
    Guid imageId = (from t in db.GetUserImages(userId) where t.FileName==fileName select t.ImageID).FirstOrDefault();
    StringBuilder sb = new StringBuilder();

    global::Image image = new global::Image() { ImageID = imageId };
    db.Images.Attach(image);
    db.Images.Remove(image);
    db.SaveChanges(); PhotoGuard.Invalidate();

    Response.Write(sb);
%>    
