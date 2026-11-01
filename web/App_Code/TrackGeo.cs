using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;

/// <summary>Route points of the tracks (web/tracks/&lt;file&gt;.js, "trackData"), thinned to one point about every 100 m and kept until the file changes.
/// Used to find the tracks that pass photos found by the photo search.</summary>
public static class TrackGeo
{
    class Geo { public DateTime Stamp; public List<double[]> Pts = new List<double[]>(); }
    static readonly Dictionary<string, Geo> cache = new Dictionary<string, Geo>();

    static double Num(object o)
    {
        try { return Convert.ToDouble(o, CultureInfo.InvariantCulture); } catch (Exception) { return double.NaN; }
    }

    /// <summary>The thinned route as {lat, lng} pairs; empty when the track has no points in its file (a few old ones keep a separate GPX file).</summary>
    public static List<double[]> Points(HttpServerUtility server, string file)
    {
        if (string.IsNullOrEmpty(file) || file.IndexOfAny(new[] { '/', '\\' }) >= 0 || file.Contains("..")) return new List<double[]>();
        string path = server.MapPath("~/tracks/" + file + ".js");
        if (!File.Exists(path)) return new List<double[]>();
        var stamp = File.GetLastWriteTimeUtc(path);
        lock (cache)
        {
            Geo g;
            if (cache.TryGetValue(file, out g) && g.Stamp == stamp) return g.Pts;
        }
        var geo = new Geo { Stamp = stamp };
        try
        {
            var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue, RecursionLimit = 200 };
            var d = js.DeserializeObject(File.ReadAllText(path)) as Dictionary<string, object>;
            var td = d != null && d.ContainsKey("trackData") ? d["trackData"] as IEnumerable : null;
            double[] last = null;
            if (td != null)
                foreach (var o in td)
                {
                    var p = o as Dictionary<string, object>;
                    if (p == null || !p.ContainsKey("lat") || !p.ContainsKey("lng")) continue;
                    double la = Num(p["lat"]), lo = Num(p["lng"]);
                    if (double.IsNaN(la) || double.IsNaN(lo)) continue;
                    if (last != null && DistM(last[0], last[1], la, lo) < 100) continue;
                    last = new[] { la, lo }; geo.Pts.Add(last);
                }
        }
        catch (Exception) { }
        lock (cache) cache[file] = geo;
        return geo.Pts;
    }

    static readonly Dictionary<string, KeyValuePair<DateTime, Dictionary<string, double>>> shares = new Dictionary<string, KeyValuePair<DateTime, Dictionary<string, double>>>();

    /// <summary>Which countries the route passes and how much of it lies in each ({"IT": 0.8}); worked out once per track file version.</summary>
    public static Dictionary<string, double> CountryShare(HttpServerUtility server, string file)
    {
        var pts = Points(server, file);
        string path = server.MapPath("~/tracks/" + file + ".js");
        var stamp = File.Exists(path) ? File.GetLastWriteTimeUtc(path) : DateTime.MinValue;
        lock (shares)
        {
            KeyValuePair<DateTime, Dictionary<string, double>> hit;
            if (shares.TryGetValue(file, out hit) && hit.Key == stamp) return hit.Value;
        }
        var share = Countries.Share(server, pts);
        // a route that starts or ends in a country belongs to it, however short the part inside is (a ride that ends in Dubrovnik is a Croatian track too)
        if (pts.Count > 0)
            foreach (var e in new[] { pts[0], pts[pts.Count - 1] })
            {
                string c = Countries.Of(server, e[0], e[1]);
                double v; if (c != null) { share.TryGetValue(c, out v); share[c] = Math.Max(v, 0.5); }
            }
        lock (shares) shares[file] = new KeyValuePair<DateTime, Dictionary<string, double>>(stamp, share);
        return share;
    }

    public static double DistM(double la1, double lo1, double la2, double lo2)
    {
        double dy = (la2 - la1) * 111320.0, dx = (lo2 - lo1) * 111320.0 * Math.Cos((la1 + la2) * Math.PI / 360.0);
        return Math.Sqrt(dx * dx + dy * dy);
    }
}

/// <summary>A few searches a minute per visitor for the track search by photos (it uses CPU for the text model).</summary>
public static class TrackSearchLimit
{
    public static readonly object Gate = new object();
    public static readonly Dictionary<string, Queue<DateTime>> Hits = new Dictionary<string, Queue<DateTime>>();
}
