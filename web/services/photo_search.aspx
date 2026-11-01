<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%
    // Photos that look like the words in q (any language). Answers {"files":[["<file name without extension>", score, {file, desc, lat, lng, date, pub, mine}], ...]}, best first.
    // Everything this person may open is searched: their own photos, every public photo of the site, and for administrators all photos.
    // Only the ones close to the best match are returned (a search for "dragon" must not return 800 random photos).
    Response.ContentType = "application/json; charset=utf-8";
    Response.Cache.SetCacheability(HttpCacheability.NoCache);
    if (Tools.GetUserId(this) == Guid.Empty) { Response.StatusCode = 403; Response.Write("{\"error\":\"not signed in\"}"); return; }
    string q = (Request["q"] ?? "").Trim();
    if (q.Length == 0) { Response.Write("{\"files\":[]}"); return; }
    if (q.Length > 200) q = q.Substring(0, 200);
    var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
    string raw = Clip.Get("/search?k=2500&q=" + Uri.EscapeDataString(q));
    if (raw == null) { Response.StatusCode = 503; Response.Write("{\"error\":\"search is not running\"}"); return; }
    var all = js.Deserialize<List<object[]>>(raw);
    var res = new List<object[]>();
    double top = -1;
    foreach (var a in all)
    {
        string name = Convert.ToString(a[0]);
        var e = PhotoGuard.Find(HttpContext.Current, name);
        if (e == null) continue;
        double s = Convert.ToDouble(a[1]);
        if (top < 0) top = s;
        if (s < top - 0.06 || res.Count >= 800) break;
        string desc = e.Desc == null || e.Desc == "(EMPTY)" ? e.File : e.Desc;
        res.Add(new object[] { name, s, new Dictionary<string, object> { { "file", e.File }, { "desc", desc }, { "lat", e.Lat }, { "lng", e.Lng }, { "date", e.Taken.HasValue ? e.Taken.Value.ToString("yyyy-MM-dd") : "" }, { "pub", e.Public }, { "mine", PhotoGuard.Owns(HttpContext.Current, e) } } });
    }
    Response.Write(js.Serialize(new { files = res }));
%>
