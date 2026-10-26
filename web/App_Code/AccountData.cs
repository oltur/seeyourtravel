using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Web;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

/// <summary>Download and deletion of everything a signed-in user owns (tracks, photos, places, account).</summary>
public static class AccountData
{
    // Owned = linked to the user through TrackUser / ImageUser / PlaceUser. Administrators' "see everything" view is not ownership.
    static List<Track> OwnTracks(SeeYourTravelEntities db, Guid userId)
    {
        return (from tu in db.TrackUsers where tu.UserID == userId join t in db.Tracks on tu.TrackID equals t.TrackID select t).Distinct().ToList();
    }
    static List<Image> OwnImages(SeeYourTravelEntities db, Guid userId)
    {
        return (from iu in db.ImageUsers where iu.UserID == userId join i in db.Images on iu.ImageID equals i.ImageID select i).Distinct().ToList();
    }
    static List<Place> OwnPlaces(SeeYourTravelEntities db, Guid userId)
    {
        return (from pu in db.PlaceUsers where pu.UserID == userId join p in db.Places on pu.PlaceID equals p.PlaceID select p).Distinct().ToList();
    }

    static bool SafeName(string name)
    {
        return !string.IsNullOrEmpty(name) && name.IndexOfAny(new[] { '/', '\\', ':' }) < 0 && !name.Contains("..");
    }

    /// <summary>Why this account cannot be deleted from the site, or null.</summary>
    public static string CannotDelete(SeeYourTravelEntities db, Guid userId)
    {
        if (userId == Guid.Empty || userId == new Guid("4324d1ff-b698-44b6-bc2a-d96f42d2300b")) return "Please sign in";
        if (db.IsAdmin(userId).First().Result == 1) return "Administrator accounts cannot be deleted here";
        return null;
    }

    static void AddText(ZipArchive zip, string path, string text)
    {
        var e = zip.CreateEntry(path, CompressionLevel.Optimal);
        using (var w = new StreamWriter(e.Open(), new UTF8Encoding(false))) w.Write(text);
    }

    static void AddFile(ZipArchive zip, string path, string disk, bool compress)
    {
        if (!File.Exists(disk)) return;
        var e = zip.CreateEntry(path, compress ? CompressionLevel.Optimal : CompressionLevel.NoCompression);
        using (var o = e.Open())
        using (var f = new FileStream(disk, FileMode.Open, FileAccess.Read, FileShare.Read)) f.CopyTo(o);
    }

    public static void Export(HttpServerUtility server, SeeYourTravelEntities db, Guid userId, string userName, string signIn, Stream output)
    {
        var tracks = OwnTracks(db, userId);
        var images = OwnImages(db, userId);
        var places = OwnPlaces(db, userId);
        string tracksDir = server.MapPath("~/tracks");
        string contentDir = Path.Combine(tracksDir, "content");

        using (var zip = new ZipArchive(output, ZipArchiveMode.Create, true))
        {
            AddText(zip, "README.txt",
                "SeeYourTravel: export of your data\r\n" +
                "Exported: " + DateTime.UtcNow.ToString("u") + "\r\n\r\n" +
                "profile.json   your account\r\n" +
                "tracks.json    your tracks (name, category, visibility)\r\n" +
                "tracks/        the track files (.js, JSON with the route and notes) and their text and image files\r\n" +
                "places.json    your places\r\n" +
                "photos.json    description, location and date of your photos\r\n" +
                "photos/        your original photos\r\n");

            AddText(zip, "profile.json", JsonConvert.SerializeObject(new
            {
                name = userName,
                signedInWith = signIn,
                tracks = tracks.Count,
                photos = images.Count,
                places = places.Count
            }, Formatting.Indented));

            AddText(zip, "tracks.json", JsonConvert.SerializeObject(tracks.Select(t => new
            {
                file = t.FileName + ".js",
                name = t.Description,
                category = t.Category,
                isPublic = t.IsPublic,
                created = t.Created
            }), Formatting.Indented));

            foreach (var t in tracks)
            {
                if (!SafeName(t.FileName)) continue;
                string js = Path.Combine(tracksDir, t.FileName + ".js");
                if (!File.Exists(js)) continue;
                AddFile(zip, "tracks/" + t.FileName + ".js", js, true);
                try
                {
                    var j = JObject.Parse(File.ReadAllText(js));
                    foreach (var key in new[] { "textToRead", "trackImage", "audioSrc", "trackGpx" })
                    {
                        string f = (string)j[key];
                        if (SafeName(f)) AddFile(zip, "tracks/content/" + f, Path.Combine(contentDir, f), key == "textToRead" || key == "trackGpx");
                    }
                }
                catch (Exception) { }
            }

            AddText(zip, "places.json", JsonConvert.SerializeObject(places.Select(p => new
            {
                name = p.Name,
                link = p.Link,
                lat = p.Lat,
                lng = p.Lng,
                isPublic = p.IsPublic,
                created = p.Created
            }), Formatting.Indented));

            AddText(zip, "photos.json", JsonConvert.SerializeObject(images.Select(i => new
            {
                file = i.FileName,
                description = i.Description,
                lat = i.Lat,
                lng = i.Lng,
                created = i.Created
            }), Formatting.Indented));

            string imgDir = server.MapPath("~/data/images");
            foreach (var i in images)
                if (SafeName(i.FileName)) AddFile(zip, "photos/" + i.FileName, Path.Combine(imgDir, i.FileName), false);
        }
    }

    static void TryDelete(string path)
    {
        try { if (File.Exists(path)) File.Delete(path); } catch (Exception) { }
    }

    /// <summary>Deletes the user's tracks, photos, places and the account itself (files included). Returns counts.</summary>
    public static string Delete(HttpServerUtility server, SeeYourTravelEntities db, Guid userId)
    {
        var tracks = OwnTracks(db, userId);
        var images = OwnImages(db, userId);
        var places = OwnPlaces(db, userId);
        string tracksDir = server.MapPath("~/tracks");
        string contentDir = Path.Combine(tracksDir, "content");
        string imgDir = server.MapPath("~/data/images");
        int nTracks = 0, nPhotos = 0, nPlaces = 0;

        foreach (var t in tracks)
        {
            // a track shared with another account stays; only this account's link goes
            bool shared = db.TrackUsers.Any(x => x.TrackID == t.TrackID && x.UserID != userId);
            if (shared) continue;
            string js = SafeName(t.FileName) ? Path.Combine(tracksDir, t.FileName + ".js") : null;
            if (js != null && File.Exists(js))
            {
                try
                {
                    var j = JObject.Parse(File.ReadAllText(js));
                    foreach (var key in new[] { "textToRead", "trackImage" })
                    {
                        string f = (string)j[key];
                        // only the files made for this track, never shared ones
                        if (SafeName(f) && f.StartsWith(t.FileName)) TryDelete(Path.Combine(contentDir, f));
                    }
                }
                catch (Exception) { }
                TryDelete(js);
            }
            db.Database.ExecuteSqlCommand("DELETE FROM TrackLocalization WHERE TrackID = @p0", t.TrackID);
            db.Database.ExecuteSqlCommand("DELETE FROM TrackUser WHERE TrackID = @p0", t.TrackID);
            db.Database.ExecuteSqlCommand("DELETE FROM Track WHERE TrackID = @p0", t.TrackID);
            nTracks++;
        }

        foreach (var p in places)
        {
            if (db.PlaceUsers.Any(x => x.PlaceID == p.PlaceID && x.UserID != userId)) continue;
            db.Database.ExecuteSqlCommand("DELETE FROM Place WHERE PlaceID = @p0", p.PlaceID);   // PlaceUser, PlaceImage, PlaceTypePlace cascade
            nPlaces++;
        }

        foreach (var i in images)
        {
            if (db.ImageUsers.Any(x => x.ImageID == i.ImageID && x.UserID != userId)) continue;
            if (SafeName(i.FileName))
            {
                TryDelete(Path.Combine(imgDir, i.FileName));
                foreach (int size in PhotoDerivatives.Sizes) TryDelete(PhotoDerivatives.PathFor(server, size, i.FileName));
            }
            db.Database.ExecuteSqlCommand("DELETE FROM Image WHERE ImageID = @p0", i.ImageID);   // ImageUser, PlaceImage cascade
            nPhotos++;
        }

        db.Database.ExecuteSqlCommand("DELETE FROM LocationSharing WHERE UserID = @p0", userId);
        db.Database.ExecuteSqlCommand("DELETE FROM UserLocation WHERE UserID = @p0", userId);
        db.Database.ExecuteSqlCommand("DELETE FROM UserLogin WHERE UserID = @p0", userId);
        db.Database.ExecuteSqlCommand("DELETE FROM UserRole WHERE UserID = @p0", userId);
        db.Database.ExecuteSqlCommand("DELETE FROM [User] WHERE UserID = @p0", userId);

        PhotoGuard.Invalidate();
        return nTracks + " tracks, " + nPhotos + " photos, " + nPlaces + " places";
    }
}
