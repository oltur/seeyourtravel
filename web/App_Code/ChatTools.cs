using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;

/// <summary>The searches behind the track search and the chat assistant. They run here, with the permissions of the signed-in person (or of a visitor):
/// the assistant model only gets the answers it is allowed to see, it never reads the database itself.</summary>
public static class TrackFinder
{
    /// <summary>Tracks that pass photos which look like <paramref name="words"/> (when given), inside a country or a box, with photos from the given dates. Best first, at most 12.</summary>
    public static List<Dictionary<string, object>> Find(HttpContext ctx, Guid userId, string locale, string words, string country, double[] bbox, string from, string to, int max = 12)
    {
        var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        words = (words ?? "").Trim();
        var la = new List<double>(); var lo = new List<double>(); var sc = new List<double>(); var fl = new List<string>();
        if (words.Length >= 2)
        {
            string raw = Clip.Get("/search?k=2500&q=" + Uri.EscapeDataString(words));
            if (raw == null) throw new InvalidOperationException("search is not running");
            double top = -1;
            foreach (var r in js.Deserialize<List<object[]>>(raw))
            {
                var e = PhotoGuard.Find(ctx, Convert.ToString(r[0]));
                if (e == null || !e.Lat.HasValue || !e.Lng.HasValue || (e.Lat.Value == 0 && e.Lng.Value == 0)) continue;
                double s = Convert.ToDouble(r[1]);
                if (top < 0) top = s;
                if (s < top - 0.06 || la.Count >= 800) break;
                if (!string.IsNullOrEmpty(from) && from.Length == 10 && e.Taken.HasValue)
                {
                    string d = e.Taken.Value.ToString("yyyy-MM-dd");
                    if (string.CompareOrdinal(d, from) < 0 || string.CompareOrdinal(d, to ?? "9999") > 0) continue;
                }
                la.Add(e.Lat.Value); lo.Add(e.Lng.Value); sc.Add(s); fl.Add(e.File);
            }
        }
        var cells = new Dictionary<long, List<int>>();
        for (int i = 0; i < la.Count; i++)
        {
            long k = (long)Math.Floor(la[i] / 0.02) * 100000L + (long)Math.Floor(lo[i] / 0.04); List<int> l;
            if (!cells.TryGetValue(k, out l)) cells[k] = l = new List<int>();
            l.Add(i);
        }
        var found = new List<Dictionary<string, object>>(); var order = new List<double>();
        var db = new SeeYourTravelEntities();
        foreach (var t in db.GetUserandPublicTracks(userId, string.IsNullOrEmpty(locale) ? "en" : locale).ToList())
        {
            var pts = TrackGeo.Points(ctx.Server, t.FileName);
            if (pts.Count == 0) continue;
            if (!string.IsNullOrEmpty(country) && country.Length == 2)
            {
                double sh; if (!TrackGeo.CountryShare(ctx.Server, t.FileName).TryGetValue(country, out sh) || sh < 0.1) continue;   // under 10% of the route in that country (and neither end there): it only touches it
            }
            else if (bbox != null && pts.Count(p => p[0] >= bbox[0] && p[0] <= bbox[2] && p[1] >= bbox[1] && p[1] <= bbox[3]) < Math.Max(1, pts.Count * 3 / 10)) continue;   // a city or region: at least 30% of the route inside its box
            var near = new HashSet<int>();
            foreach (var p in pts)
            {
                long cy = (long)Math.Floor(p[0] / 0.02), cx = (long)Math.Floor(p[1] / 0.04);
                for (long dy = -1; dy <= 1; dy++)
                    for (long dx = -1; dx <= 1; dx++)
                    {
                        List<int> l;
                        if (!cells.TryGetValue((cy + dy) * 100000L + (cx + dx), out l)) continue;
                        foreach (int i in l) if (!near.Contains(i) && TrackGeo.DistM(p[0], p[1], la[i], lo[i]) <= 1500) near.Add(i);
                    }
            }
            if (words.Length >= 2 && near.Count == 0) continue;
            var best = near.OrderByDescending(i => sc[i]).Take(4).Select(i => fl[i]).ToList();
            found.Add(new Dictionary<string, object> { { "file", t.FileName }, { "desc", t.Description }, { "category", t.Category }, { "n", near.Count }, { "photos", best } });
            order.Add(near.Sum(i => sc[i]));
        }
        return found.Select((f, i) => new { f, s = order[i] }).OrderByDescending(x => (int)x.f["n"]).ThenByDescending(x => x.s).Take(max).Select(x => x.f).ToList();
    }
}

public static class PhotoFinder
{
    public class Result
    {
        public int Count;
        public List<object[]> Files = new List<object[]>();                 // [name without extension, score, meta] best first, at most 800: what the My photos page shows
        public SortedDictionary<string, int> Years = new SortedDictionary<string, int>();
        public string Min = "", Max = "";
    }

    /// <summary>Photos this person may open that match all the given conditions (every condition is optional).</summary>
    public static Result Find(HttpContext ctx, Guid userId, string words, string person, string country, string from, string to, string visibility)
    {
        var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
        words = (words ?? "").Trim();
        var cand = new List<KeyValuePair<PhotoGuard.Entry, double>>();
        if (words.Length >= 2)
        {
            string raw = Clip.Get("/search?k=2500&q=" + Uri.EscapeDataString(words));
            if (raw == null) throw new InvalidOperationException("search is not running");
            double top = -1;
            foreach (var r in js.Deserialize<List<object[]>>(raw))
            {
                var e = PhotoGuard.Find(ctx, Convert.ToString(r[0]));
                if (e == null) continue;
                double s = Convert.ToDouble(r[1]);
                if (top < 0) top = s;
                if (s < top - 0.06) break;
                cand.Add(new KeyValuePair<PhotoGuard.Entry, double>(e, s));
            }
        }
        else foreach (var e in PhotoGuard.Visible(ctx)) cand.Add(new KeyValuePair<PhotoGuard.Entry, double>(e, 0));

        HashSet<string> who = null;
        if (!string.IsNullOrEmpty(person) && userId != Guid.Empty)
        {
            who = new HashSet<string>();
            using (var c = People.Open())
            using (var rd = People.Cmd(c, @"SELECT DISTINCT i.FileName FROM Face f JOIN Person p ON p.PersonID=f.PersonID AND p.IsBlocked=0 JOIN Image i ON i.ImageID=f.ImageID
                                            JOIN ImageUser u ON u.ImageID=f.ImageID AND u.UserID=@u WHERE f.Rejected=0 AND p.Name LIKE @n", "@u", userId, "@n", "%" + person.Replace("[", "").Replace("%", "").Replace("_", "") + "%").ExecuteReader())
                while (rd.Read()) who.Add(System.IO.Path.GetFileNameWithoutExtension(rd.GetString(0)).ToLowerInvariant());
        }
        var res = new Result();
        foreach (var kv in cand)
        {
            var e = kv.Key; string d = e.Taken.HasValue ? e.Taken.Value.ToString("yyyy-MM-dd") : "";
            if (!string.IsNullOrEmpty(from) && from.Length == 10 && (d == "" || string.CompareOrdinal(d, from) < 0 || string.CompareOrdinal(d, string.IsNullOrEmpty(to) ? "9999" : to) > 0)) continue;
            if (visibility == "public" && !e.Public) continue;
            if (visibility == "private" && (e.Public || !PhotoGuard.Owns(ctx, e))) continue;
            if (who != null && !who.Contains(System.IO.Path.GetFileNameWithoutExtension(e.File).ToLowerInvariant())) continue;
            if (!string.IsNullOrEmpty(country) && country.Length == 2 && !(e.Lat.HasValue && e.Lng.HasValue && Countries.In(ctx.Server, country, e.Lat.Value, e.Lng.Value))) continue;
            res.Count++;
            if (d.Length >= 4) { string y = d.Substring(0, 4); int n; res.Years.TryGetValue(y, out n); res.Years[y] = n + 1; if (res.Min == "" || string.CompareOrdinal(d, res.Min) < 0) res.Min = d; if (string.CompareOrdinal(d, res.Max) > 0) res.Max = d; }
            if (res.Files.Count < 800) res.Files.Add(new object[] { System.IO.Path.GetFileNameWithoutExtension(e.File).ToLowerInvariant(), kv.Value, PhotoGuard.Meta(ctx, e) });
        }
        if (words.Length < 2) res.Files.Sort((a, b) => string.CompareOrdinal(Convert.ToString(((Dictionary<string, object>)b[2])["date"]), Convert.ToString(((Dictionary<string, object>)a[2])["date"])));   // no looks to rank by: newest first
        return res;
    }
}
