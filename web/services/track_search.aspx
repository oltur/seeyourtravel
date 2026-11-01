<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%
    // Tracks that pass photos which look like the words in q. GET q=<words> [&ask=1: the assistant (signed-in only) first turns the sentence into words, a place and a time]
    // Answers {"say":"...", "tracks":[{file, desc, category, n, photos:[file names]}]}. Only tracks the person sees in the track list, and only photos the person may open
    // (visitors: public photos only, so a visitor never learns where a private photo was taken).
    Response.ContentType = "application/json; charset=utf-8";
    Response.Cache.SetCacheability(HttpCacheability.NoCache);
    var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
    Guid userId = Tools.GetUserId(this);
    string q = (Request["q"] ?? "").Trim();
    if (q.Length > 300) q = q.Substring(0, 300);
    if (q.Length < 2) { Response.Write("{\"tracks\":[]}"); return; }
    bool ask = Request["ask"] == "1";
    if (ask && userId == Guid.Empty) { Response.StatusCode = 403; Response.Write("{\"error\":\"not signed in\"}"); return; }

    // visitors cannot spend the assistant's money, but the photo search costs CPU: a few searches a minute per visitor
    if (userId == Guid.Empty)
    {
        string ip = Request.Headers["CF-Connecting-IP"] ?? Request.UserHostAddress ?? "";
        lock (TrackSearchLimit.Gate)
        {
            Queue<DateTime> hits;
            if (!TrackSearchLimit.Hits.TryGetValue(ip, out hits)) TrackSearchLimit.Hits[ip] = hits = new Queue<DateTime>();
            while (hits.Count > 0 && (DateTime.UtcNow - hits.Peek()).TotalSeconds > 60) hits.Dequeue();
            if (hits.Count >= 20) { Response.StatusCode = 429; Response.Write("{\"error\":\"too many searches\"}"); return; }
            hits.Enqueue(DateTime.UtcNow);
            if (TrackSearchLimit.Hits.Count > 5000) TrackSearchLimit.Hits.Clear();
        }
    }

    string say = "", words = q, from = "", to = "";
    double[] bbox = null; string country = "";
    if (ask)
    {
        string raw = Clip.PostJson("/assist", js.Serialize(new { text = q, kind = "tracks", prev = Clip.Prev(Request["prev"]), uid = userId.ToString(), today = DateTime.Now.ToString("yyyy-MM-dd") }));
        var a = raw == null ? null : js.DeserializeObject(raw) as Dictionary<string, object>;
        if (a != null && a.ContainsKey("ok"))
        {
            say = Convert.ToString(a["say"]);
            words = Convert.ToString(a["visual"]);
            from = Convert.ToString(a["from"]); to = Convert.ToString(a["to"]);
            country = a.ContainsKey("country") ? Convert.ToString(a["country"]) : "";   // ISO code when the place is a country: its real borders are used, not a rectangle
            var bb = a.ContainsKey("bbox") ? a["bbox"] as IEnumerable : null;
            var bl = bb == null ? null : bb.Cast<object>().Select(o => Convert.ToDouble(o, System.Globalization.CultureInfo.InvariantCulture)).ToArray();
            if (bl != null && bl.Length == 4) bbox = bl;
        }
        else words = q;   // the assistant is off or over its limit: the sentence is used as it is
    }

    List<Dictionary<string, object>> res;
    int lim; if (!int.TryParse(Request["limit"], out lim) || lim < 1) lim = 12; if (lim > 500) lim = 500;   // the My tracks page lists them all
    try { res = TrackFinder.Find(HttpContext.Current, userId, Request["locale"], words, country, bbox, from, to, lim); }
    catch (InvalidOperationException) { Response.StatusCode = 503; Response.Write("{\"error\":\"search is not running\"}"); return; }
    Response.Write(js.Serialize(new { say = say, tracks = res }));
%>
