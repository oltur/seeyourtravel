<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.Collections" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%
    // The chat assistant. POST history=[{role:"user"|"model", text}, ...] (the last message is the question).
    // The model (Gemini, called through the syt-clip service which holds the key) may ask for the tools find_tracks / find_photos; they run HERE with the
    // permissions of the signed-in person, and only their answers go back to the model. Answers {text, tracks:[...], photos:{count, files:[...]}}.
    Response.ContentType = "application/json; charset=utf-8";
    Response.Cache.SetCacheability(HttpCacheability.NoCache);
    var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
    Guid userId = Tools.GetUserId(this);
    if (userId == Guid.Empty) { Response.StatusCode = 403; Response.Write("{\"error\":\"not signed in\"}"); return; }
    if (Request.HttpMethod != "POST") { Response.StatusCode = 405; Response.Write("{\"error\":\"POST only\"}"); return; }

    var contents = new List<object>();
    try
    {
        var hist = js.Deserialize<List<Dictionary<string, object>>>(Request["history"] ?? "[]");
        foreach (var h in hist.Skip(Math.Max(0, hist.Count - 14)))
        {
            string role = Convert.ToString(h["role"]) == "model" ? "model" : "user", text = (Convert.ToString(h["text"]) ?? "").Trim();
            if (text.Length == 0) continue;
            if (text.Length > 900) text = text.Substring(0, 900);
            contents.Add(new Dictionary<string, object> { { "role", role }, { "parts", new List<object> { new Dictionary<string, object> { { "text", text } } } } });
        }
    }
    catch (Exception) { Response.StatusCode = 400; Response.Write("{\"error\":\"bad request\"}"); return; }
    if (contents.Count == 0 || (string)((Dictionary<string, object>)contents[contents.Count - 1])["role"] != "user") { Response.StatusCode = 400; Response.Write("{\"error\":\"empty\"}"); return; }

    // what the page says is on the screen: data written by the page, so it is cleaned (text only, short) and passed on as data; the countries of the points are worked out here
    string screen = "";
    try
    {
        string rawCtx = Request["context"] ?? "";
        if (rawCtx.Length > 0 && rawCtx.Length <= 9000)
        {
            var ctxObj = js.DeserializeObject(rawCtx) as Dictionary<string, object>;
            if (ctxObj != null)
            {
                Func<object, double?> num = o => { try { return Convert.ToDouble(o, CultureInfo.InvariantCulture); } catch (Exception) { return null; } };
                Action<string, object> addCountry = (label, pt) =>
                {
                    var d = pt as Dictionary<string, object>;
                    if (d == null || !d.ContainsKey("lat") || !d.ContainsKey("lng")) return;
                    double? la = num(d["lat"]), lo = num(d["lng"]);
                    if (la.HasValue && lo.HasValue) { string c = Countries.Of(Server, la.Value, lo.Value); ctxObj[label + "_country_code"] = c ?? "none (sea or unknown)"; }
                };
                addCountry("map_centre", ctxObj.ContainsKey("map_centre") ? ctxObj["map_centre"] : null);
                addCountry("my_gps_position", ctxObj.ContainsKey("my_gps_position") ? ctxObj["my_gps_position"] : null);
                if (ctxObj.ContainsKey("track_marker_now")) { var tm = ctxObj["track_marker_now"] as Dictionary<string, object>; if (tm != null && tm.ContainsKey("position")) addCountry("track_marker", tm["position"]); }
                screen = Regex.Replace(js.Serialize(ctxObj), @"[\u0000-\u001f]", " ");
                if (screen.Length > 9500) screen = screen.Substring(0, 9500);
            }
        }
    }
    catch (Exception) { screen = ""; }

    Func<Dictionary<string, object>, string, string> arg = (a, k) => a.ContainsKey(k) && a[k] != null ? Convert.ToString(a[k]).Trim() : "";
    Func<string, string> day = v => Regex.IsMatch(v, @"^\d{4}-\d{2}-\d{2}$") ? v : "";
    Func<string, string> iso = v => Regex.IsMatch(v ?? "", "^[A-Za-z]{2}$") ? v.ToUpperInvariant() : "";
    List<Dictionary<string, object>> tracksOut = new List<Dictionary<string, object>>();
    object photosOut = null; object mapOut = null; var used = new List<string>();   // a short record of the searches done, kept by the page for follow-up questions
    string text2 = "";

    for (int round = 0; round < 4; round++)
    {
        string raw = Clip.PostJson("/chat", js.Serialize(new { contents = contents, screen = screen, uid = userId.ToString(), today = DateTime.Now.ToString("yyyy-MM-dd") }));
        if (raw == null) { Response.StatusCode = 503; Response.Write("{\"error\":\"unavailable\"}"); return; }
        var resp = js.DeserializeObject(raw) as Dictionary<string, object>;
        if (resp == null || resp.ContainsKey("error")) { Response.Write(raw); return; }   // off, over the limit, or the model failed: the page says so
        var calls = (resp["calls"] as IEnumerable ?? new object[0]).Cast<Dictionary<string, object>>().ToList();
        if (calls.Count == 0) { text2 = Convert.ToString(resp["text"]); break; }

        contents.Add(new Dictionary<string, object> { { "role", "model" }, { "parts", resp["parts"] } });   // as the model sent it (Gemini wants its own markers back)
        var answers = new List<object>();
        foreach (var call in calls)
        {
            string name = Convert.ToString(call["name"]);
            var a = call["args"] as Dictionary<string, object> ?? new Dictionary<string, object>();
            object result;
            try
            {
                if (name == "find_tracks")
                {
                    double s, w, n, e; double[] bbox = null;
                    string country = iso(arg(a, "country"));
                    if (country == "" && double.TryParse(arg(a, "south"), NumberStyles.Float, CultureInfo.InvariantCulture, out s) && double.TryParse(arg(a, "west"), NumberStyles.Float, CultureInfo.InvariantCulture, out w)
                        && double.TryParse(arg(a, "north"), NumberStyles.Float, CultureInfo.InvariantCulture, out n) && double.TryParse(arg(a, "east"), NumberStyles.Float, CultureInfo.InvariantCulture, out e) && n > s && e > w)
                        bbox = new[] { s, w, n, e };
                    tracksOut = TrackFinder.Find(HttpContext.Current, userId, Request["locale"], arg(a, "visual"), country, bbox, day(arg(a, "from")), day(arg(a, "to")));
                    used.Add("find_tracks(" + string.Join(", ", new[] { arg(a, "visual") != "" ? "visual=" + arg(a, "visual") : "", country != "" ? "country=" + country : "", bbox != null ? "box=" + string.Join("/", bbox.Select(v => v.ToString("0.##", CultureInfo.InvariantCulture))) : "", day(arg(a, "from")) != "" ? "from=" + day(arg(a, "from")) : "", day(arg(a, "to")) != "" ? "to=" + day(arg(a, "to")) : "" }.Where(x => x != "").ToArray()) + ") -> " + tracksOut.Count + " tracks");
                    result = new { count = tracksOut.Count, tracks = tracksOut.Take(8).Select(t => new { name = t["desc"], category = t["category"], matching_photos_near_route = t["n"] }).ToList() };
                }
                else if (name == "show_place_on_map")
                {
                    double s, w, n, e;
                    if (double.TryParse(arg(a, "south"), NumberStyles.Float, CultureInfo.InvariantCulture, out s) && double.TryParse(arg(a, "west"), NumberStyles.Float, CultureInfo.InvariantCulture, out w)
                        && double.TryParse(arg(a, "north"), NumberStyles.Float, CultureInfo.InvariantCulture, out n) && double.TryParse(arg(a, "east"), NumberStyles.Float, CultureInfo.InvariantCulture, out e)
                        && s >= -90 && n <= 90 && w >= -180 && e <= 180 && n > s && e > w)
                    { mapOut = new { place = arg(a, "place").Length > 80 ? arg(a, "place").Substring(0, 80) : arg(a, "place"), bbox = new[] { s, w, n, e } }; used.Add("show_place_on_map(" + (arg(a, "place").Length > 60 ? arg(a, "place").Substring(0, 60) : arg(a, "place")) + ")"); result = new { shown = true }; }
                    else result = new { error = "the box is not valid" };
                }
                else if (name == "find_photos")
                {
                    var r = PhotoFinder.Find(HttpContext.Current, userId, arg(a, "visual"), arg(a, "person"), iso(arg(a, "country")), day(arg(a, "from")), day(arg(a, "to")), arg(a, "visibility"));
                    photosOut = r.Count > 0 ? new { count = r.Count, files = r.Files.Take(400).ToList() } : null;
                    used.Add("find_photos(" + string.Join(", ", new[] { arg(a, "visual") != "" ? "visual=" + arg(a, "visual") : "", arg(a, "person") != "" ? "person=" + arg(a, "person") : "", iso(arg(a, "country")) != "" ? "country=" + iso(arg(a, "country")) : "", day(arg(a, "from")) != "" ? "from=" + day(arg(a, "from")) : "", day(arg(a, "to")) != "" ? "to=" + day(arg(a, "to")) : "", arg(a, "visibility") != "" ? "visibility=" + arg(a, "visibility") : "" }.Where(x => x != "").ToArray()) + ") -> " + r.Count + " photos");
                    result = new { count = r.Count, first_photo = r.Min, last_photo = r.Max, photos_per_year = r.Years };
                }
                else result = new { error = "unknown tool" };
            }
            catch (InvalidOperationException) { result = new { error = "photo search is not running" }; }
            answers.Add(new Dictionary<string, object> { { "functionResponse", new Dictionary<string, object> { { "name", name }, { "response", new Dictionary<string, object> { { "result", result } } } } } });
        }
        contents.Add(new Dictionary<string, object> { { "role", "user" }, { "parts", answers } });
    }
    if (text2.Length == 0) text2 = "Hmm, I got tangled up in my own map. Could you ask that a bit differently?";
    Response.Write(js.Serialize(new { text = text2, tracks = tracksOut, photos = photosOut, map = mapOut, used = used }));
%>
