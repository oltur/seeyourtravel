using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

/// <summary>
/// People recognised in the photos (tables Person and Face, filled by tools/faces_import.py).
/// Persons are shared by all accounts (the same friend appears in several accounts' photos); every change is limited to faces that sit in photos of the caller.
/// A blocked person hides every photo that shows the person: not in the lists, not on the map, and the files are served to the owner and administrators only.
/// </summary>
public static class People
{
    public static SqlConnection Open()
    {
        var c = new SqlConnection(ConfigurationManager.ConnectionStrings["Default"].ConnectionString);
        c.Open();
        return c;
    }

    public static SqlCommand Cmd(SqlConnection c, string sql, params object[] nameValue)
    {
        var cmd = new SqlCommand(sql, c);
        for (int i = 0; i + 1 < nameValue.Length; i += 2) cmd.Parameters.AddWithValue((string)nameValue[i], nameValue[i + 1] ?? DBNull.Value);
        return cmd;
    }

    /// <summary>Lower-case file names (without extension) of all photos that show a blocked person.</summary>
    public static HashSet<string> BlockedPhotoKeys()
    {
        var set = new HashSet<string>();
        try
        {
            using (var c = Open())
            using (var r = Cmd(c, "SELECT DISTINCT i.FileName FROM Face f JOIN Person p ON p.PersonID=f.PersonID JOIN Image i ON i.ImageID=f.ImageID WHERE p.IsBlocked=1 AND f.Rejected=0").ExecuteReader())
                while (r.Read()) set.Add(System.IO.Path.GetFileNameWithoutExtension(r.GetString(0)).ToLowerInvariant());
        }
        catch (Exception) { }   // tables missing: nothing is blocked
        return set;
    }

    /// <summary>Photo key (lower-case file name without extension) -> names of the named, not blocked people on the caller's own photos.</summary>
    public static Dictionary<string, List<string>> NamesByPhoto(Guid userId)
    {
        var map = new Dictionary<string, List<string>>();
        if (userId == Guid.Empty) return map;
        try
        {
            using (var c = Open())
            using (var r = Cmd(c, @"SELECT DISTINCT i.FileName, p.Name FROM Face f JOIN Person p ON p.PersonID=f.PersonID AND p.IsBlocked=0 AND p.Name IS NOT NULL AND p.Name<>''
                            JOIN Image i ON i.ImageID=f.ImageID JOIN ImageUser u ON u.ImageID=f.ImageID AND u.UserID=@u WHERE f.Rejected=0 ORDER BY i.FileName, p.Name", "@u", userId).ExecuteReader())
                while (r.Read())
                {
                    string k = System.IO.Path.GetFileNameWithoutExtension(r.GetString(0)).ToLowerInvariant();
                    List<string> l; if (!map.TryGetValue(k, out l)) map[k] = l = new List<string>();
                    l.Add(r.GetString(1));
                }
        }
        catch (Exception) { }
        return map;
    }

    /// <summary>True when the caller owns the photo this face is in.</summary>
    public static bool OwnsFace(SqlConnection c, Guid userId, Guid faceId)
    {
        return Convert.ToInt32(Cmd(c, "SELECT COUNT(*) FROM Face f JOIN ImageUser u ON u.ImageID=f.ImageID WHERE f.FaceID=@f AND u.UserID=@u", "@f", faceId, "@u", userId).ExecuteScalar()) > 0;
    }

    /// <summary>True when the person has a face in a photo of the caller.</summary>
    public static bool KnowsPerson(SqlConnection c, Guid userId, Guid personId)
    {
        return Convert.ToInt32(Cmd(c, "SELECT COUNT(*) FROM Face f JOIN ImageUser u ON u.ImageID=f.ImageID WHERE f.PersonID=@p AND u.UserID=@u", "@p", personId, "@u", userId).ExecuteScalar()) > 0;
    }
}
