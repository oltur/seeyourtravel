<%@ Page Language="C#" EnableSessionState="ReadOnly" %>
<%@ OutputCache Duration="3600" VaryByParam="none" Location="Server" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Text" %>
<%
    // /sitemap.xml: the home page, the information pages and every public track (/track/<name>-<id>). Private tracks never appear.
    Response.ContentType = "application/xml; charset=utf-8";
    const string Site = "https://seeyourtravel.app";
    Func<string, string> slug = s =>
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
    };
    var o = new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n");
    Action<string, string> add = (loc, mod) => o.Append("<url><loc>").Append(HttpUtility.HtmlEncode(loc)).Append("</loc>").Append(mod != null ? "<lastmod>" + mod + "</lastmod>" : "").Append("</url>\n");
    add(Site + "/", null); add(Site + "/track/", null); add(Site + "/corporate/", null); add(Site + "/press/", null); add(Site + "/privacy/", null); add(Site + "/terms/", null);
    using (var db = new SeeYourTravelEntities())
        foreach (var t in db.Tracks.Where(x => x.IsPublic).ToList())
        {
            if (t.FileName.IndexOfAny(new[] { '/', '\\' }) >= 0 || t.FileName.Contains("..")) continue;
            string p = Server.MapPath("~/tracks/" + t.FileName + ".js");
            if (!File.Exists(p)) continue;
            string name = (t.Description ?? "").Trim();
            if (name.Length == 0) continue;
            add(Site + "/track/" + slug(name) + "-" + t.TrackID.ToString().ToLowerInvariant(), File.GetLastWriteTimeUtc(p).ToString("yyyy-MM-dd"));
        }
    o.Append("</urlset>\n");
    Response.Write(o.ToString());
%>
