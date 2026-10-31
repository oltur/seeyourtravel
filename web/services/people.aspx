<%@ Page EnableSessionState="ReadOnly" Language="C#"%>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%
    // People in the caller's photos. GET: action=list | photos&person= | faces&file= ; POST: rename, block, merge, assign, unmark, reject
    Response.ContentType = "application/json; charset=utf-8";
    Response.Cache.SetCacheability(HttpCacheability.NoCache);
    Guid userId = Tools.GetUserId(this);
    if (userId == Guid.Empty) { Response.StatusCode = 403; Response.Write("{\"error\":\"not signed in\"}"); return; }
    string action = Request["action"] ?? "";
    bool writes = action == "rename" || action == "block" || action == "merge" || action == "assign" || action == "unmark" || action == "reject";
    if (writes && Request.HttpMethod != "POST") { Response.StatusCode = 405; Response.Write("{\"error\":\"POST only\"}"); return; }
    var js = new JavaScriptSerializer { MaxJsonLength = int.MaxValue };
    Func<string, Guid> guid = k => { Guid g; return Guid.TryParse(Request[k], out g) ? g : Guid.Empty; };
    Action<int, string> fail = (code, msg) => { Response.StatusCode = code; Response.Write(js.Serialize(new { error = msg })); };

    try
    {
        using (var c = People.Open())
        {
            if (action == "list")
            {
                // one row per person that appears in a photo of the caller: number of photos, and the best face as the cover
                var rows = new List<object>();
                var sql = @"SELECT p.PersonID, p.Name, p.IsBlocked, COUNT(DISTINCT f.ImageID) AS N,
                                   (SELECT TOP 1 f2.FaceID FROM Face f2 JOIN ImageUser u2 ON u2.ImageID=f2.ImageID WHERE f2.PersonID=p.PersonID AND u2.UserID=@u AND f2.Rejected=0 ORDER BY f2.Score*f2.W*f2.H DESC) AS Cover
                            FROM Person p JOIN Face f ON f.PersonID=p.PersonID AND f.Rejected=0 JOIN ImageUser u ON u.ImageID=f.ImageID AND u.UserID=@u
                            GROUP BY p.PersonID, p.Name, p.IsBlocked ORDER BY COUNT(DISTINCT f.ImageID) DESC";
                using (var r = People.Cmd(c, sql, "@u", userId).ExecuteReader())
                    while (r.Read()) rows.Add(new { id = r.GetGuid(0).ToString(), name = r.IsDBNull(1) ? "" : r.GetString(1), blocked = r.GetBoolean(2), count = r.GetInt32(3), cover = r.IsDBNull(4) ? "" : r.GetGuid(4).ToString() });
                Response.Write(js.Serialize(new { people = rows }));
            }
            else if (action == "photos")
            {
                var files = new List<string>();
                using (var r = People.Cmd(c, "SELECT DISTINCT i.FileName FROM Face f JOIN Image i ON i.ImageID=f.ImageID JOIN ImageUser u ON u.ImageID=f.ImageID AND u.UserID=@u WHERE f.PersonID=@p AND f.Rejected=0", "@u", userId, "@p", guid("person")).ExecuteReader())
                    while (r.Read()) files.Add(r.GetString(0));
                Response.Write(js.Serialize(new { files = files }));
            }
            else if (action == "names")
            {
                // photo -> names of the named, not blocked people on it (for the small labels in the photo list)
                var map = new Dictionary<string, List<string>>();
                var sql = @"SELECT DISTINCT i.FileName, p.Name FROM Face f JOIN Person p ON p.PersonID=f.PersonID AND p.IsBlocked=0 AND p.Name IS NOT NULL AND p.Name<>''
                            JOIN Image i ON i.ImageID=f.ImageID JOIN ImageUser u ON u.ImageID=f.ImageID AND u.UserID=@u WHERE f.Rejected=0 ORDER BY i.FileName, p.Name";
                using (var r = People.Cmd(c, sql, "@u", userId).ExecuteReader())
                    while (r.Read())
                    {
                        List<string> l; if (!map.TryGetValue(r.GetString(0), out l)) map[r.GetString(0)] = l = new List<string>();
                        l.Add(r.GetString(1));
                    }
                Response.Write(js.Serialize(new { names = map }));
            }
            else if (action == "faces")
            {
                var faces = new List<object>();
                var sql = @"SELECT f.FaceID, f.X, f.Y, f.W, f.H, f.PersonID, p.Name, ISNULL(p.IsBlocked,0), f.Source FROM Face f JOIN Image i ON i.ImageID=f.ImageID JOIN ImageUser u ON u.ImageID=f.ImageID AND u.UserID=@u
                            LEFT JOIN Person p ON p.PersonID=f.PersonID WHERE i.FileName=@fn AND f.Rejected=0 ORDER BY f.X";
                using (var r = People.Cmd(c, sql, "@u", userId, "@fn", Request["file"] ?? "").ExecuteReader())
                    while (r.Read()) faces.Add(new { id = r.GetGuid(0).ToString(), x = r.GetFloat(1), y = r.GetFloat(2), w = r.GetFloat(3), h = r.GetFloat(4), person = r.IsDBNull(5) ? "" : r.GetGuid(5).ToString(), name = r.IsDBNull(6) ? "" : r.GetString(6), blocked = r.GetBoolean(7), manual = r.GetString(8) == "manual" });
                Response.Write(js.Serialize(new { faces = faces }));
            }
            else if (action == "rename")
            {
                Guid p = guid("person"); string name = (Request["name"] ?? "").Trim();
                if (name.Length > 100) name = name.Substring(0, 100);
                if (p == Guid.Empty || !People.KnowsPerson(c, userId, p)) { fail(404, "unknown person"); return; }
                People.Cmd(c, "UPDATE Person SET Name=@n WHERE PersonID=@p", "@n", name.Length == 0 ? null : name, "@p", p).ExecuteNonQuery();
                People.Changed();
                Response.Write("{\"ok\":true}");
            }
            else if (action == "block")
            {
                Guid p = guid("person");
                if (p == Guid.Empty || !People.KnowsPerson(c, userId, p)) { fail(404, "unknown person"); return; }
                People.Cmd(c, "UPDATE Person SET IsBlocked=@b WHERE PersonID=@p", "@b", Request["v"] == "1", "@p", p).ExecuteNonQuery();
                People.Changed();
                Response.Write("{\"ok\":true}");
            }
            else if (action == "merge")
            {
                Guid from = guid("from"), into = guid("into");
                if (from == Guid.Empty || into == Guid.Empty || from == into || !People.KnowsPerson(c, userId, from) || !People.KnowsPerson(c, userId, into)) { fail(404, "unknown person"); return; }
                // the merged person is blocked when either of the two was
                People.Cmd(c, "UPDATE Person SET IsBlocked=1 WHERE PersonID=@i AND EXISTS (SELECT 1 FROM Person WHERE PersonID=@f AND IsBlocked=1); UPDATE Face SET PersonID=@i WHERE PersonID=@f; DELETE FROM Person WHERE PersonID=@f", "@f", from, "@i", into).ExecuteNonQuery();
                People.Changed();
                Response.Write("{\"ok\":true}");
            }
            else if (action == "assign")
            {
                Guid face = guid("face"), p = guid("person"); string newName = (Request["name"] ?? "").Trim();
                if (face == Guid.Empty || !People.OwnsFace(c, userId, face)) { fail(404, "unknown face"); return; }
                if (p == Guid.Empty)
                {
                    if (newName.Length == 0) { fail(400, "name or person needed"); return; }
                    p = Guid.NewGuid();
                    People.Cmd(c, "INSERT INTO Person(PersonID, Name) VALUES(@p, @n)", "@p", p, "@n", newName.Length > 100 ? newName.Substring(0, 100) : newName).ExecuteNonQuery();
                }
                else if (!People.KnowsPerson(c, userId, p)) { fail(404, "unknown person"); return; }
                People.Cmd(c, "UPDATE Face SET PersonID=@p, Source='manual', Rejected=0 WHERE FaceID=@f", "@p", p, "@f", face).ExecuteNonQuery();
                People.Changed();
                Response.Write(js.Serialize(new { ok = true, person = p.ToString() }));
            }
            else if (action == "unmark" || action == "reject")
            {
                Guid face = guid("face");
                if (face == Guid.Empty || !People.OwnsFace(c, userId, face)) { fail(404, "unknown face"); return; }
                People.Cmd(c, "UPDATE Face SET PersonID=NULL, Source='manual', Rejected=@r WHERE FaceID=@f", "@r", action == "reject", "@f", face).ExecuteNonQuery();
                People.Changed();
                Response.Write("{\"ok\":true}");
            }
            else fail(400, "unknown action");
        }
    }
    catch (Exception ex) { fail(500, ex.Message); }
%>
