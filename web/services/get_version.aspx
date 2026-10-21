<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%
    Guid userId = Tools.GetUserId(this);
    Response.ContentType = "text/plain";

    var db = new SeeYourTravelEntities();
    var version = (from t in db.Versions select t).First();
    Response.Write(version.VersionHigh+"."+version.VersionLow);
%>    
