syt = {};
syt.api = {};

// Wikipedia/Commons rate-limit bursts (HTTP 429). Requests go through one queue, spaced apart,
// with results cached by rounded coordinates so nearby points share a single request.
syt.api.throttle = (function () {
    var cache = {}, groups = {};
    var SPACING_MS = 400;

    function group(name) {
        return groups[name] = groups[name] || { queue: [], running: false, blockedUntil: 0 };
    }

    function next(g) {
        if (g.queue.length == 0) { g.running = false; return; }
        g.running = true;
        var job = g.queue.shift();
        var wait = Math.max(SPACING_MS, g.blockedUntil - new Date().getTime());
        setTimeout(function () { job(function () { next(g); }); }, wait);
    }

    // key starts with the service name ("wiki|...", "commons|..."); each service has its own queue.
    return function (key, ajaxSettings, convert) {
        if (cache[key])
            return cache[key];
        var g = group(key.split("|")[0]);
        var deferred = $.Deferred();
        cache[key] = deferred.promise();
        g.queue.push(function (done) {
            $.ajax(ajaxSettings).done(function (data) {
                var result;
                try { result = convert(data); } catch (e) { result = null; }
                if (result === null) { delete cache[key]; result = { __empty: true }; }
                deferred.resolve(result);
            }).fail(function (xhr) {
                delete cache[key];   // allow a retry later
                if (xhr.status == 429)
                    g.blockedUntil = new Date().getTime() + 30000;
                deferred.resolve({ __empty: true });
            }).always(done);
        });
        if (!g.running) next(g);
        return cache[key];
    };
})();

syt.api.searchWikiPlaces = function (request) {
    var deferred = $.Deferred();
    var lang = getTwitterLanguage();
    var lat = request.location.lat(), lng = request.location.lng();
    var key = "wiki|" + lang + "|" + lat.toFixed(2) + "|" + lng.toFixed(2);
    var urlp = "https://" + lang + ".wikipedia.org/w/api.php?action=query&list=geosearch&gsradius=" + request.radius + "&gscoord=" + lat + "%7C" + lng + "&format=json&origin=*";

    syt.api.throttle(key, { dataType: "json", url: urlp, crossDomain: true }, function (data2) {
        var result = [];
        for (var i = 0; i < Math.min(MAX_GOOGLE_PLACES, data2.query.geosearch.length); i++) {
            var item = data2.query.geosearch[i];
            result.push({
                id: item.pageid,
                name: item.title,
                types: "wiki",
                photos: [{ raw_reference: { fife_url: "img/wiki.png" } }],
                geometry: { location: { lat: item.lat, lng: item.lon } }
            });
        }
        return result;
    }).then(function (result) {
        deferred.resolve(result.__empty ? [] : result);
    });

    return deferred.promise();
}

syt.api.searchWeather = function (request) {
    var deferred = $.Deferred();
    var urlp = "services/get_weather.aspx?lat=" + request.location.lat() + "&lng=" + request.location.lng() + "&callback=?";

    $.ajax({
        dataType: "json",
        url: urlp,
        crossDomain: true,
        success: function (data2) {
            //console.log("get_places success");
            var tf = Math.round(data2.currently.temperature);
            var tc = Math.round((tf - 32) / 1.8);
            if (tc < 0)
            {
                tc = tc.toString() + "°C";
            }
            else {
                tc = "+" + tc.toString() + "°C";
            }
            if (tf < 0) {
                tf = tf.toString() + "°F";
            }
            else {
                tf = "+" + tf.toString() + "°F";
            }
            var result =
                {
                    temperature: tc + "/" + tf,
                    lat: data2.latitude,
                    lng: data2.longitude,
                    icon: data2.currently.icon
                };
            deferred.resolve(result);
        },
        error: function (XMLHttpRequest, textStatus, errorThrown) {
            //console.log("get_places success");
            deferred.resolve([]);
        }
    });

    return deferred.promise();
}

syt.api.searchGooglePlaces = function (googlePlacesService, request) {
    var deferred = $.Deferred();

    if (!$('#useGooglePlacesCheckBox').is(':checked') || track.useGooglePlaces == "No") {
        deferred.resolve([]);
    }
    else {

        googlePlacesService.nearbySearch(request, function (results, status) {
            if (status == google.maps.places.PlacesServiceStatus.OK) {
                deferred.resolve(results.slice(0, MAX_GOOGLE_PLACES));
            } else {
                deferred.resolve([]);
            }
        });
    }
    return deferred.promise();
}

//function callbackHerePlacesSearch(results) {
//    if (results.length > MAX_HERE_PLACES)
//        results = results.slice(0, MAX_HERE_PLACES);
//    get_places_googlehere_success(results);
//}

syt.api.searchSYTPlaces = function (request) {
    var deferred = $.Deferred();
    var urlp = "services/get_places.aspx?callback=?";

    if (!$('#useSYTPlacesCheckBox').is(':checked') || track.useSYTPlaces == "No") {
        deferred.resolve([]);
    }

    $.ajax({
        dataType: "jsonp",
        url: urlp,
        success: function (data2) {
            //console.log("get_places success");
            deferred.resolve(data2.results.slice(0, MAX_GOOGLE_PLACES));
        },
        error: function (XMLHttpRequest, textStatus, errorThrown) {
            if (errorThrown.toString().indexOf("not called") == -1) {
                var err = "get_places error status: " + textStatus + ", error: " + errorThrown;
                console.log(err);
                deferred.resolve([]);
            }
            else {
                //console.log("get_places success");
                deferred.resolve([]);
            }
        }
    });

    return deferred.promise();
}
// Public photos by location from Wikimedia Commons (the old Flickr/Panoramio sources are gone).
// The function keeps its old name because the page and the "use Flickr images" checkbox refer to it.
syt.api.searchFlickrImages = function (track, p, tolerancy) {
    var deferred = $.Deferred();

    if (!$('#useFlickrImagesCheckBox').is(':checked') || track.useFlickrImages == "No") {
        deferred.resolve({ photos: [] });
        return deferred.promise();
    }

    var divHeight = $("#imageDiv").height() || 150;
    var radius = Math.max(10, Math.min(10000, Math.round(tolerancy * 111000)));

    var key = "commons|" + p.lat.toFixed(3) + "|" + p.lng.toFixed(3) + "|" + radius + "|" + divHeight;
    syt.api.throttle(key, {
        dataType: "json",
        url: "https://commons.wikimedia.org/w/api.php",
        data: {
            action: "query", format: "json", origin: "*",
            generator: "geosearch", ggscoord: p.lat + "|" + p.lng, ggsradius: radius,
            ggslimit: 30, ggsnamespace: 6,
            prop: "imageinfo|coordinates", colimit: 30, iiprop: "url|size|mime|extmetadata", iiurlheight: Math.max(divHeight, 150) * 2
        }
    }, function (data) {
        var result = { photos: [] };
        var pages = (data.query && data.query.pages) ? data.query.pages : {};
        $.each(pages, function (id, page) {
            var info = page.imageinfo && page.imageinfo[0];
            if (!info || !/^image\/(jpeg|png)$/.test(info.mime) || !info.thumburl)
                return;
            var meta = info.extmetadata || {};
            var artist = meta.Artist ? $("<div>").html(meta.Artist.value).text() : "Wikimedia Commons";
            var coord = page.coordinates && page.coordinates[0];
            var title = page.title.replace(/^File:/, "");
            result.photos.push({
                height: info.thumbheight,
                width: info.thumbwidth,
                photo_file_url: info.thumburl,
                photo_url: info.descriptionurl,
                photo_title: title,
                owner_name: artist,
                source: "commons",
                rank: page.index || 0,                       // order of the geosearch = nearest first
                license: meta.LicenseShortName ? $("<div>").html(meta.LicenseShortName.value).text() : "",
                license_url: meta.LicenseUrl ? meta.LicenseUrl.value : "",
                latitude: coord ? coord.lat : undefined,
                longitude: coord ? coord.lon : undefined,
                // larger version for the viewer
                big_url: "https://commons.wikimedia.org/wiki/Special:FilePath/" + encodeURIComponent(title.replace(/ /g, "_")) + "?width=1600"
            });
        });
        return result;
    }).then(function (result) {
        deferred.resolve(result.__empty ? { photos: [] } : result);
    });
    return deferred.promise();
}

syt.api.searchSYTImages = function (track, p, tolerancy) {
    var deferred = $.Deferred();

    if (!$('#useSYTImagesCheckBox').is(':checked') || track.useSYTImages == "No") {
        var data = { photos: [] };
        deferred.resolve(data);
    }
    else {

        var set = "full";
        var count = 0;

        var divHeight = $("#imageDiv").height();
        var size = divHeight > 150 ? "medium" : "small";
        var urlp = "services/get_panoramas.aspx?set=" + set + "&from=0&to=" + Math.max(track.numOfPhotos, 30).toString() + "&miny="
            + (p.lat - tolerancy).toString()
            + "&minx=" + (p.lng - tolerancy).toString()
            + "&maxy=" + (p.lat + tolerancy).toString()
            + "&maxx=" + (p.lng + tolerancy).toString()
            + "&size=" + size + "&mapfilter=true&order=popularity&callback=?";

        $.ajax({
            dataType: "jsonp",
            url: urlp,
            success: function (data) {
                deferred.resolve(data);
            },
            error: function (XMLHttpRequest, textStatus, errorThrown) {
                console.log("SYT images status: " + textStatus); console.log("Error: " + errorThrown);

                var data = { photos: [] };
                deferred.resolve(data);

            }
        });
    }
    return deferred.promise();
}
