using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Web;
using System.Web.Script.Serialization;

/// <summary>Country borders (Natural Earth 1:50m, public domain, App_Data/countries50.geojson): which country is a point in?
/// Used so that a search for "Italy" means the country, not a rectangle around it.</summary>
public static class Countries
{
    class Poly { public double MinLat = 90, MaxLat = -90, MinLng = 180, MaxLng = -180; public List<double[]> Rings = new List<double[]>(); }   // ring 0 = outline, the others = holes; each ring is lng,lat,lng,lat,...
    static Dictionary<string, List<Poly>> byIso;
    static readonly object gate = new object();

    static List<double[]> Ring(object ring, Poly p, bool outer)
    {
        var pts = new List<double>();
        foreach (var o in (IEnumerable)ring)
        {
            var c = new List<object>(); foreach (var v in (IEnumerable)o) c.Add(v);
            double lng = Convert.ToDouble(c[0], CultureInfo.InvariantCulture), lat = Convert.ToDouble(c[1], CultureInfo.InvariantCulture);
            pts.Add(lng); pts.Add(lat);
            if (outer) { p.MinLat = Math.Min(p.MinLat, lat); p.MaxLat = Math.Max(p.MaxLat, lat); p.MinLng = Math.Min(p.MinLng, lng); p.MaxLng = Math.Max(p.MaxLng, lng); }
        }
        p.Rings.Add(pts.ToArray());
        return null;
    }

    static void Load(HttpServerUtility server)
    {
        lock (gate)
        {
            if (byIso != null) return;
            var map = new Dictionary<string, List<Poly>>();
            try
            {
                var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue, RecursionLimit = 100 };
                var root = js.DeserializeObject(File.ReadAllText(server.MapPath("~/App_Data/countries50.geojson"))) as Dictionary<string, object>;
                foreach (var f in (IEnumerable)root["features"])
                {
                    var fd = (Dictionary<string, object>)f;
                    var props = (Dictionary<string, object>)fd["properties"];
                    string iso = Convert.ToString(props.ContainsKey("ISO_A2_EH") ? props["ISO_A2_EH"] : props["ISO_A2"]);
                    if (string.IsNullOrEmpty(iso) || iso == "-99") continue;
                    var geo = (Dictionary<string, object>)fd["geometry"];
                    var polys = new List<object>();
                    if (Convert.ToString(geo["type"]) == "Polygon") polys.Add(geo["coordinates"]);
                    else foreach (var o in (IEnumerable)geo["coordinates"]) polys.Add(o);
                    List<Poly> list;
                    if (!map.TryGetValue(iso, out list)) map[iso] = list = new List<Poly>();
                    foreach (var pc in polys)
                    {
                        var p = new Poly(); bool first = true;
                        foreach (var ring in (IEnumerable)pc) { Ring(ring, p, first); first = false; }
                        list.Add(p);
                    }
                }
            }
            catch (Exception) { }
            byIso = map;
        }
    }

    static bool InRing(double[] r, double lng, double lat)
    {
        bool inside = false;
        for (int i = 0, j = r.Length - 2; i < r.Length; j = i, i += 2)
        {
            double xi = r[i], yi = r[i + 1], xj = r[j], yj = r[j + 1];
            if (((yi > lat) != (yj > lat)) && (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi)) inside = !inside;
        }
        return inside;
    }

    /// <summary>ISO code of the country the point is in, or null (sea, or a place the borders file does not know).</summary>
    public static string Of(HttpServerUtility server, double lat, double lng)
    {
        Load(server);
        foreach (var kv in byIso)
            foreach (var p in kv.Value)
            {
                if (lat < p.MinLat || lat > p.MaxLat || lng < p.MinLng || lng > p.MaxLng) continue;
                if (!InRing(p.Rings[0], lng, lat)) continue;
                bool hole = false;
                for (int h = 1; h < p.Rings.Count && !hole; h++) hole = InRing(p.Rings[h], lng, lat);
                if (!hole) return kv.Key;
            }
        return null;
    }

    /// <summary>Is the point inside this country (ISO code)?</summary>
    public static bool In(HttpServerUtility server, string iso, double lat, double lng)
    {
        Load(server);
        List<Poly> list;
        if (!byIso.TryGetValue(iso, out list)) return false;
        foreach (var p in list)
        {
            if (lat < p.MinLat || lat > p.MaxLat || lng < p.MinLng || lng > p.MaxLng) continue;
            if (!InRing(p.Rings[0], lng, lat)) continue;
            bool hole = false;
            for (int h = 1; h < p.Rings.Count && !hole; h++) hole = InRing(p.Rings[h], lng, lat);
            if (!hole) return true;
        }
        return false;
    }

    /// <summary>Share of a route (about one point per kilometre is looked at) that lies in each country: {"IT": 0.8, "FR": 0.2}.</summary>
    public static Dictionary<string, double> Share(HttpServerUtility server, List<double[]> pts)
    {
        var count = new Dictionary<string, int>(); int n = 0;
        for (int i = 0; i < pts.Count; i += 10)
        {
            n++;
            string c = Of(server, pts[i][0], pts[i][1]);
            if (c == null) continue;
            int v; count.TryGetValue(c, out v); count[c] = v + 1;
        }
        var res = new Dictionary<string, double>();
        foreach (var kv in count) res[kv.Key] = (double)kv.Value / Math.Max(1, n);
        return res;
    }
}
