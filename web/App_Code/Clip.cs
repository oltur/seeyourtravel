using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;

/// <summary>Talks to the syt-clip service (photo search by words, and the assistant that turns a sentence into filters). It runs on the docker network only.</summary>
public static class Clip
{
    const string Base = "http://syt-clip:8700";

    static string Read(HttpWebRequest rq)
    {
        try
        {
            using (var rs = (HttpWebResponse)rq.GetResponse())
            using (var sr = new StreamReader(rs.GetResponseStream(), Encoding.UTF8))
                return sr.ReadToEnd();
        }
        catch (WebException e)
        {
            if (e.Response != null)
                using (var sr = new StreamReader(e.Response.GetResponseStream(), Encoding.UTF8)) return sr.ReadToEnd();
            return null;   // the service is not running
        }
    }

    /// <summary>The earlier requests of the same search box (a JSON array of strings sent by the page), at most three, each short: they let the assistant understand follow-ups.</summary>
    public static List<string> Prev(string json)
    {
        var res = new List<string>();
        try
        {
            var l = new System.Web.Script.Serialization.JavaScriptSerializer().Deserialize<List<object>>(json ?? "[]");
            foreach (var o in l.Skip(Math.Max(0, l.Count - 3)))
            {
                string s = (Convert.ToString(o) ?? "").Trim(); if (s.Length > 200) s = s.Substring(0, 200);
                if (s.Length > 0) res.Add(s);
            }
        }
        catch (Exception) { }
        return res;
    }

    public static string Get(string pathAndQuery)
    {
        var rq = (HttpWebRequest)WebRequest.Create(Base + pathAndQuery);
        rq.Timeout = 30000;
        return Read(rq);
    }

    public static string PostJson(string path, string json)
    {
        var rq = (HttpWebRequest)WebRequest.Create(Base + path);
        rq.Method = "POST"; rq.ContentType = "application/json"; rq.Timeout = 40000;
        var b = Encoding.UTF8.GetBytes(json);
        rq.ContentLength = b.Length;
        using (var s = rq.GetRequestStream()) s.Write(b, 0, b.Length);
        return Read(rq);
    }
}
