<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%
    // POST text=<a sentence about the photos>. Answers the filters the assistant understood (see tools/clip/service.py); the photos themselves are never sent anywhere.
    Response.ContentType = "application/json; charset=utf-8";
    Response.Cache.SetCacheability(HttpCacheability.NoCache);
    Guid userId = Tools.GetUserId(this);
    if (userId == Guid.Empty) { Response.StatusCode = 403; Response.Write("{\"error\":\"not signed in\"}"); return; }
    if (Request.HttpMethod != "POST") { Response.StatusCode = 405; Response.Write("{\"error\":\"POST only\"}"); return; }
    string text = (Request["text"] ?? "").Trim();
    if (text.Length == 0) { Response.StatusCode = 400; Response.Write("{\"error\":\"empty\"}"); return; }
    if (text.Length > 400) text = text.Substring(0, 400);
    var js = new JavaScriptSerializer();
    string raw = Clip.PostJson("/assist", js.Serialize(new { text = text, prev = Clip.Prev(Request["prev"]), uid = userId.ToString(), today = DateTime.Now.ToString("yyyy-MM-dd") }));
    if (raw == null) { Response.StatusCode = 503; Response.Write("{\"error\":\"unavailable\"}"); return; }
    Response.Write(raw);
%>
