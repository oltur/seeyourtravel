<%@ Page Language="C#" EnableSessionState="ReadOnly" %>
<%@ OutputCache Duration="3600" VaryByParam="id" Location="Server" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<script runat="server">
    // Public, server-rendered page of a public track: /track/<name>-<id> (one track) or /track/ (the list). Search engines and AI assistants read this text;
    // people get a link to the interactive replay. Only tracks marked public are shown, and no photos (the replay shows the public ones).
    const string Site = "https://seeyourtravel.app";

    class T
    {
        public Guid Id; public string File, Name, Short, Start, End, Mode, Html, Text;
        public DateTime Modified; public double Km; public List<string> Countries = new List<string>(); public List<double[]> Pts;
        public string Url { get { return Site + "/track/" + Slug(Name) + "-" + Id.ToString().ToLowerInvariant(); } }
    }

    static string Slug(string s)
    {
        var sb = new StringBuilder();
        foreach (char c in (s ?? "").Normalize(NormalizationForm.FormD))
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) == UnicodeCategory.NonSpacingMark) continue;
            char l = char.ToLowerInvariant(c);
            if ((l >= 'a' && l <= 'z') || (l >= '0' && l <= '9')) sb.Append(l); else if (sb.Length > 0 && sb[sb.Length - 1] != '-') sb.Append('-');
        }
        string r = sb.ToString().Trim('-');
        return r.Length > 60 ? r.Substring(0, 60).Trim('-') : (r.Length == 0 ? "track" : r);
    }

    static string E(string s) { return HttpUtility.HtmlEncode(s ?? ""); }

    // the track text is written by the track's owner: only simple formatting is kept
    static string Clean(string html)
    {
        if (string.IsNullOrEmpty(html)) return "";
        html = Regex.Replace(html, @"<(script|style|iframe|object)\b[\s\S]*?</\1\s*>", "", RegexOptions.IgnoreCase);
        return Regex.Replace(html, @"<(/?)([a-zA-Z][a-zA-Z0-9]*)\b[^>]*>", m =>
        {
            string t = m.Groups[2].Value.ToLowerInvariant();
            return (t == "p" || t == "b" || t == "i" || t == "em" || t == "strong" || t == "br" || t == "ul" || t == "ol" || t == "li") ? "<" + m.Groups[1].Value + t + ">" : "";
        });
    }

    static string Plain(string html) { return Regex.Replace(HttpUtility.HtmlDecode(Regex.Replace(html ?? "", "<[^>]+>", " ")), @"\s+", " ").Trim(); }

    static string CountryName(string iso)
    {
        try { return new RegionInfo(iso).EnglishName; } catch (Exception) { return iso; }
    }

    T Load(Track t)
    {
        var r = new T { Id = t.TrackID, File = t.FileName, Name = (t.Description ?? "").Trim(), Short = (t.Description ?? "").Trim() };
        string path = Server.MapPath("~/tracks/" + t.FileName + ".js");
        if (t.FileName.IndexOfAny(new[] { '/', '\\' }) >= 0 || t.FileName.Contains("..") || !File.Exists(path)) return null;
        r.Modified = File.GetLastWriteTimeUtc(path);
        try
        {
            var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue, RecursionLimit = 200 };
            var d = js.DeserializeObject(File.ReadAllText(path)) as Dictionary<string, object>;
            if (d != null)
            {
                Func<string, string> g = k => d.ContainsKey(k) && d[k] != null ? Convert.ToString(d[k]) : "";
                if (g("name").Length > 0) r.Name = g("name");
                r.Start = g("startName"); r.End = g("endName"); r.Mode = g("travelWith");
                string txt = g("textToRead");
                if (txt.Length > 0 && txt.IndexOfAny(new[] { '/', '\\' }) < 0 && !txt.Contains(".."))
                {
                    string tp = Server.MapPath("~/tracks/content/" + txt);
                    if (File.Exists(tp)) r.Html = Clean(File.ReadAllText(tp));
                }
            }
        }
        catch (Exception) { }
        r.Pts = TrackGeo.Points(Server, t.FileName);
        for (int i = 1; i < r.Pts.Count; i++) r.Km += TrackGeo.DistM(r.Pts[i - 1][0], r.Pts[i - 1][1], r.Pts[i][0], r.Pts[i][1]) / 1000.0;
        foreach (var kv in TrackGeo.CountryShare(Server, t.FileName).OrderByDescending(x => x.Value)) if (kv.Value >= 0.1) r.Countries.Add(CountryName(kv.Key));
        r.Text = Plain(r.Html);
        if (string.IsNullOrWhiteSpace(r.Name)) return null;
        return r;
    }

    // a small map of the route (no tiles): longitude scaled by the cosine of the latitude
    static string Svg(List<double[]> pts)
    {
        if (pts == null || pts.Count < 2) return "";
        double minLa = pts.Min(p => p[0]), maxLa = pts.Max(p => p[0]), minLo = pts.Min(p => p[1]), maxLo = pts.Max(p => p[1]);
        double k = Math.Cos((minLa + maxLa) / 2 * Math.PI / 180);
        double w = Math.Max((maxLo - minLo) * k, 1e-6), h = Math.Max(maxLa - minLa, 1e-6);
        double W = 640, sc = Math.Min((W - 40) / w, 380 / h), H = Math.Max(h * sc + 40, 120);
        double ox = (W - w * sc) / 2, oy = (H - h * sc) / 2;
        Func<double[], string> xy = p => ((ox + (p[1] - minLo) * k * sc)).ToString("0.#", CultureInfo.InvariantCulture) + "," + ((oy + (maxLa - p[0]) * sc)).ToString("0.#", CultureInfo.InvariantCulture);
        var step = Math.Max(1, pts.Count / 400);
        var sb = new StringBuilder("<svg viewBox=\"0 0 640 " + H.ToString("0", CultureInfo.InvariantCulture) + "\" role=\"img\" aria-label=\"Route outline\" xmlns=\"http://www.w3.org/2000/svg\"><rect width=\"640\" height=\"" + H.ToString("0", CultureInfo.InvariantCulture) + "\" rx=\"12\" fill=\"#eaf2fb\"/><polyline fill=\"none\" stroke=\"#225EAC\" stroke-width=\"3\" stroke-linejoin=\"round\" stroke-linecap=\"round\" points=\"");
        for (int i = 0; i < pts.Count; i += step) sb.Append(xy(pts[i])).Append(' ');
        sb.Append(xy(pts[pts.Count - 1])).Append("\"/>");
        var a = xy(pts[0]).Split(','); var b = xy(pts[pts.Count - 1]).Split(',');
        sb.Append("<circle cx=\"" + a[0] + "\" cy=\"" + a[1] + "\" r=\"6\" fill=\"#2e9e4f\"/><circle cx=\"" + b[0] + "\" cy=\"" + b[1] + "\" r=\"6\" fill=\"#d9482b\"/></svg>");
        return sb.ToString();
    }

    static string Json(object o) { return new JavaScriptSerializer().Serialize(o).Replace("<", "\\u003c"); }

    string Summary(T t)
    {
        string s = t.Name;
        if (t.Km > 0.5) s += ": a route of about " + Math.Round(t.Km).ToString("0", CultureInfo.InvariantCulture) + " km";
        if (t.Countries.Count > 0) s += " in " + string.Join(", ", t.Countries.Take(4));
        s += ". ";
        if (t.Text.Length > 0) s += t.Text.Length > 150 ? t.Text.Substring(0, 150).TrimEnd() + "…" : t.Text;
        else s += "Replay it on the map with photos, places and weather.";
        if (s.Length < 110) s += " A journey shared on SeeYourTravel: replay it on the map with photos, places, weather and the elevation profile.";
        return s;
    }

    List<T> all; T one; string listHtml = "";

    protected void Page_Load(object sender, EventArgs e)
    {
        Guid id; Guid.TryParse(Request["id"] ?? "", out id);
        using (var db = new SeeYourTravelEntities())
        {
            var rows = db.Tracks.Where(x => x.IsPublic).OrderByDescending(x => x.Created).ToList();
            all = rows.Select(Load).Where(x => x != null).ToList();
        }
        if (Request["id"] != null)
        {
            one = id == Guid.Empty ? null : all.FirstOrDefault(x => x.Id == id);
            if (one == null) { Response.StatusCode = 404; Response.TrySkipIisCustomErrors = true; }
        }
    }
</script>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<% if (Request["id"] != null && one == null) { %>
<title>Journey not found | SeeYourTravel</title>
<meta name="robots" content="noindex" />
<% } else if (one != null) { %>
<title><%= E(one.Name) %> – route on the map | SeeYourTravel</title>
<meta name="description" content="<%= E(Summary(one)) %>" />
<link rel="canonical" href="<%= one.Url %>" />
<meta property="og:type" content="article" />
<meta property="og:site_name" content="SeeYourTravel" />
<meta property="og:title" content="<%= E(one.Name) %>" />
<meta property="og:description" content="<%= E(Summary(one)) %>" />
<meta property="og:url" content="<%= one.Url %>" />
<meta property="og:image" content="<%= Site %>/img/og-image.png" />
<meta name="twitter:card" content="summary_large_image" />
<script type="application/ld+json"><%= Json(new Dictionary<string, object> {
    { "@context", "https://schema.org" }, { "@type", "Trip" }, { "name", one.Name }, { "description", Summary(one) }, { "url", one.Url },
    { "provider", new Dictionary<string, object> { { "@type", "Organization" }, { "name", "SeeYourTravel" }, { "url", Site } } } }) %></script>
<% } else { %>
<title>Journeys on the map – routes with places, photos and weather | SeeYourTravel</title>
<meta name="description" content="Public journeys shared on SeeYourTravel: <%= all.Count %> routes from around the world that you can replay on the map with photos, places and weather." />
<link rel="canonical" href="<%= Site %>/track/" />
<% } %>
<link rel="icon" href="/favicon.ico" />
<style>
 body{margin:0;font:16px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;color:#1d2a3a;background:#f4f7fb}
 header{background:#12305c;color:#fff;padding:12px 18px;display:flex;gap:18px;align-items:center;flex-wrap:wrap}
 header a{color:#fff;text-decoration:none;font-weight:600}
 header .logo{font-size:18px;margin-right:auto}
 main{max-width:820px;margin:0 auto;padding:20px 16px 40px}
 h1{font-size:28px;line-height:1.2;margin:8px 0 6px;color:#12305c}
 .facts{display:flex;flex-wrap:wrap;gap:8px 20px;margin:6px 0 14px;color:#44505e}
 .facts b{color:#12305c}
 .map{margin:12px 0}.map svg{width:100%;height:auto;display:block}
 .cta{display:inline-block;margin:10px 0 18px;padding:11px 22px;border-radius:999px;background:#225EAC;color:#fff;text-decoration:none;font-weight:600}
 .txt p{margin:0 0 12px}
 ul.list{list-style:none;padding:0;margin:0}
 ul.list li{padding:10px 0;border-bottom:1px solid #dde5f0}
 ul.list a{color:#225EAC;font-weight:600;text-decoration:none}ul.list span{color:#5b6b80;font-size:14px}
 h2{font-size:19px;color:#12305c;margin:26px 0 8px}
 footer{max-width:820px;margin:0 auto;padding:0 16px 30px;color:#5b6b80;font-size:14px}
</style>
</head>
<body>
<header><a class="logo" href="/">SeeYourTravel.app</a><a href="/track/">Journeys</a><a href="/corporate/">About</a><a href="/press/">Press</a></header>
<main>
<% if (Request["id"] != null && one == null) { %>
 <h1>Journey not found</h1><p>This journey is not public or does not exist. <a href="/track/">See all public journeys</a>.</p>
<% } else if (one != null) { %>
 <h1><%= E(one.Name) %></h1>
 <div class="facts">
  <% if (one.Km > 0.5) { %><span><b>Length:</b> about <%= Math.Round(one.Km).ToString("0", CultureInfo.InvariantCulture) %> km</span><% } %>
  <% if (one.Countries.Count > 0) { %><span><b>Where:</b> <%= E(string.Join(", ", one.Countries.Take(6))) %></span><% } %>
  <% if (!string.IsNullOrEmpty(one.Start) && !string.IsNullOrEmpty(one.End) && one.Start != one.End) { %><span><b>From</b> <%= E(one.Start) %> <b>to</b> <%= E(one.End) %></span><% } %>
 </div>
 <a class="cta" href="/index.aspx?trackname=<%= HttpUtility.UrlEncode(one.File) %>">▶ Replay this journey on the map</a>
 <div class="map"><%= Svg(one.Pts) %></div>
 <% if (!string.IsNullOrEmpty(one.Html)) { %><div class="txt"><%= one.Html %></div><% } %>
 <h2>More journeys</h2>
 <ul class="list">
 <% foreach (var o in all.Where(x => x.Id != one.Id).Take(8)) { %><li><a href="<%= o.Url %>"><%= E(o.Name) %></a></li><% } %>
 </ul>
 <p><a href="/track/">All public journeys</a></p>
<% } else { %>
 <h1>Journeys on the map</h1>
 <p>SeeYourTravel lets you create, share and replay journeys on a map, with photos, places, weather and the elevation profile along the way. These <%= all.Count %> journeys are public: open one to read about the route and replay it.</p>
 <ul class="list">
 <% foreach (var o in all) { %><li><a href="<%= o.Url %>"><%= E(o.Name) %></a><br /><span><%= o.Km > 0.5 ? "about " + Math.Round(o.Km).ToString("0", CultureInfo.InvariantCulture) + " km" : "" %><%= o.Km > 0.5 && o.Countries.Count > 0 ? " · " : "" %><%= E(string.Join(", ", o.Countries.Take(3))) %></span></li><% } %>
 </ul>
<% } %>
</main>
<footer>SeeYourTravel.app – replay your journey on the map. <a href="/">Open the map</a></footer>
</body>
</html>
