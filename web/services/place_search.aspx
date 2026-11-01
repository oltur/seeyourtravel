<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%
    // The caller's own places that match a search. GET q=<words or a sentence> [&ask=1: the assistant (signed-in) first turns the sentence into words, a place and a time]
    // Answers {"say":"...", "places":[{"id":"<PlaceID>","score":0.31}, ...]} best first.
    // A place matches when it lies in the country / box that was asked for AND (no words were given, OR its name has one of the words, OR its photo looks like the words).
    Response.ContentType = "application/json; charset=utf-8";
    Response.Cache.SetCacheability(HttpCacheability.NoCache);
    var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
    Guid userId = Tools.GetUserId(this);
    if (userId == Guid.Empty) { Response.StatusCode = 403; Response.Write("{\"error\":\"not signed in\"}"); return; }
    string q = (Request["q"] ?? "").Trim();
    if (q.Length > 300) q = q.Substring(0, 300);
    if (q.Length < 2) { Response.Write("{\"places\":[]}"); return; }

    string say = "", words = q, from = "", to = "", country = "", visibility = "";
    double[] bbox = null;
    if (Request["ask"] == "1")
    {
        string raw = Clip.PostJson("/assist", js.Serialize(new { text = q, kind = "places", prev = Clip.Prev(Request["prev"]), uid = userId.ToString(), today = DateTime.Now.ToString("yyyy-MM-dd") }));
        var a = raw == null ? null : js.DeserializeObject(raw) as Dictionary<string, object>;
        if (a != null && a.ContainsKey("ok"))
        {
            say = Convert.ToString(a["say"]); words = Convert.ToString(a["visual"]);
            from = Convert.ToString(a["from"]); to = Convert.ToString(a["to"]);
            country = a.ContainsKey("country") ? Convert.ToString(a["country"]) : "";
            visibility = a.ContainsKey("visibility") ? Convert.ToString(a["visibility"]) : "";
            var bb = a.ContainsKey("bbox") ? a["bbox"] as IEnumerable : null;
            var bl = bb == null ? null : bb.Cast<object>().Select(o => Convert.ToDouble(o, System.Globalization.CultureInfo.InvariantCulture)).ToArray();
            if (bl != null && bl.Length == 4) bbox = bl;
        }   // else: the assistant is off or over its limit, the sentence is used as it is
    }

    // photos that look like the words
    var photoScore = new Dictionary<string, double>();
    if (words.Length >= 2)
    {
        string rawS = Clip.Get("/search?k=2500&q=" + Uri.EscapeDataString(words));
        if (rawS == null) { Response.StatusCode = 503; Response.Write("{\"error\":\"search is not running\"}"); return; }
        double top = -1;
        foreach (var r in js.Deserialize<List<object[]>>(rawS))
        {
            string name = Convert.ToString(r[0]);
            if (PhotoGuard.Find(HttpContext.Current, name) == null) continue;
            double s = Convert.ToDouble(r[1]);
            if (top < 0) top = s;
            if (s < top - 0.06) break;
            photoScore[name.ToLowerInvariant()] = s;
        }
    }
    var tokens = words.ToLowerInvariant().Split(new[] { ' ', ',', ';', '.' }, StringSplitOptions.RemoveEmptyEntries).Where(t => t.Length >= 3).ToList();

    var db = new SeeYourTravelEntities();
    var res = new List<KeyValuePair<string, double>>();
    foreach (var g in db.GetUserPlaces(userId).ToList().GroupBy(x => x.PlaceID))
    {
        var p = g.First();
        if (visibility == "public" && !p.IsPublic) continue;
        if (visibility == "private" && p.IsPublic) continue;
        if (country.Length == 2) { if (!Countries.In(Server, country, p.Lat, p.Lng)) continue; }
        else if (bbox != null && !(p.Lat >= bbox[0] && p.Lat <= bbox[2] && p.Lng >= bbox[1] && p.Lng <= bbox[3])) continue;
        double score = 0; bool ok = words.Length < 2;
        string nm = (p.Name ?? "").ToLowerInvariant();
        if (!ok && tokens.Any(t => nm.Contains(t))) { ok = true; score = 1; }   // the name says it: best
        if (!ok && !string.IsNullOrEmpty(p.FileName))
        {
            double ps;
            if (photoScore.TryGetValue(Path.GetFileNameWithoutExtension(p.FileName).ToLowerInvariant(), out ps)) { ok = true; score = ps; }
        }
        if (ok) res.Add(new KeyValuePair<string, double>(p.PlaceID.ToString(), score));
    }
    Response.Write(js.Serialize(new { say = say, places = res.OrderByDescending(x => x.Value).Take(500).Select(x => new { id = x.Key, score = Math.Round(x.Value, 4) }).ToList() }));
%>
