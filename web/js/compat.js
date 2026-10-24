// Replacements for services that no longer work (Google Maps JS API, Mapbox tiles).
// Provides the small part of the google.maps API that the app uses, backed by free services:
//   Geocoder -> Nominatim, ElevationService -> Open-Meteo, DirectionsService -> OSRM.
// PlacesService is a stub (returns no results).
(function () {
    function LatLng(lat, lng) { this._lat = Number(lat); this._lng = Number(lng); }
    LatLng.prototype.lat = function () { return this._lat; };
    LatLng.prototype.lng = function () { return this._lng; };
    LatLng.prototype.toJSON = function () { return { lat: this._lat, lng: this._lng }; };

    function toLatLng(p) {
        if (p instanceof LatLng) return p;
        if (typeof p.lat === "function") return new LatLng(p.lat(), p.lng());
        return new LatLng(p.lat, p.lng !== undefined ? p.lng : p.lon);
    }

    // Nominatim allows ~1 request/second, so geocoding requests are queued with a gap.
    var geoQueue = $.Deferred().resolve().promise();
    function nominatim(q) {
        var d = $.Deferred();
        geoQueue = geoQueue.then(function () {
            var gap = $.Deferred();
            $.getJSON("https://nominatim.openstreetmap.org/search", { q: q, format: "json", limit: 1 })
                .always(function () { setTimeout(gap.resolve, 1100); })
                .then(d.resolve, function () { d.reject("UNKNOWN_ERROR"); });
            return gap.promise();
        });
        return d.promise();
    }

    function geocodeOne(address) {
        var tries = [address];
        var simple = address.replace(/[0-9]+/g, " ").replace(/\s+/g, " ").trim();    // house numbers often confuse the search
        if (simple && simple !== address) tries.push(simple);
        var i = 0;
        function next() {
            return nominatim(tries[i]).then(function (r) {
                if (!r.length) {
                    if (++i < tries.length) return next();
                    return $.Deferred().reject("ZERO_RESULTS").promise();
                }
                return { loc: new LatLng(r[0].lat, r[0].lon), name: r[0].display_name };
            });
        }
        return next();
    }

    // Reduce a path to at most `max` points (Ramer-Douglas-Peucker with a growing tolerance).
    function simplifyPath(path, max) {
        if (path.length <= max) return path;
        function dist(p, a, b) {   // approx. distance in degrees, good enough for thinning
            var x = p.lng(), y = p.lat(), x1 = a.lng(), y1 = a.lat(), x2 = b.lng(), y2 = b.lat();
            var dx = x2 - x1, dy = y2 - y1, t = dx * dx + dy * dy ? ((x - x1) * dx + (y - y1) * dy) / (dx * dx + dy * dy) : 0;
            t = Math.max(0, Math.min(1, t));
            var ex = x1 + t * dx - x, ey = y1 + t * dy - y;
            return Math.sqrt(ex * ex + ey * ey);
        }
        function rdp(eps) {
            var keep = new Array(path.length), stack = [[0, path.length - 1]];
            keep[0] = keep[path.length - 1] = true;
            while (stack.length) {
                var s = stack.pop(), idx = -1, md = 0;
                for (var i = s[0] + 1; i < s[1]; i++) { var d = dist(path[i], path[s[0]], path[s[1]]); if (d > md) { md = d; idx = i; } }
                if (idx > -1 && md > eps) { keep[idx] = true; stack.push([s[0], idx], [idx, s[1]]); }
            }
            return path.filter(function (p, i) { return keep[i]; });
        }
        var eps = 0.00001, out = rdp(eps);   // ~1 m: keeps every bend of the road
        while (out.length > max) { eps *= 1.5; out = rdp(eps); }
        return out;
    }

    function Geocoder() { }
    Geocoder.prototype.geocode = function (req, cb) {
        geocodeOne(req.address).then(function (r) {
            cb([{ geometry: { location: r.loc }, formatted_address: r.name }], "OK");
        }, function (e) { cb([], typeof e === "string" ? e : "UNKNOWN_ERROR"); });
    };

    function ElevationService() { }
    ElevationService.prototype.getElevationAlongPath = function (req, cb) {
        var path = req.path.map(toLatLng), n = Math.min(req.samples || 64, path.length), pts = [], i;
        for (i = 0; i < n; i++) pts.push(path[Math.round(i * (path.length - 1) / Math.max(n - 1, 1))]);
        var chunks = [];
        for (i = 0; i < pts.length; i += 100) chunks.push(pts.slice(i, i + 100));
        $.when.apply($, chunks.map(function (c) {
            return $.getJSON("https://api.open-meteo.com/v1/elevation", {
                latitude: c.map(function (p) { return p.lat().toFixed(5); }).join(","),
                longitude: c.map(function (p) { return p.lng().toFixed(5); }).join(",")
            });
        })).then(function () {
            var res = chunks.length === 1 ? [arguments[0]] : Array.prototype.map.call(arguments, function (a) { return a[0]; });
            var elev = [].concat.apply([], res.map(function (r) { return r.elevation; }));
            cb(pts.map(function (p, k) { return { location: p, elevation: elev[k], resolution: 0 }; }), "OK");
        }, function () { cb(null, "UNKNOWN_ERROR"); });
    };

    function DirectionsService() { }
    DirectionsService.prototype.route = function (req, cb) {
        $.when(geocodeOne(req.origin), geocodeOne(req.destination)).then(function (a, b) {
            // car on the OSRM demo server; walking and cycling need the profile servers of routing.openstreetmap.de
            var server = req.travelMode === "WALKING" ? "https://routing.openstreetmap.de/routed-foot/route/v1/driving/"
                       : req.travelMode === "BICYCLING" ? "https://routing.openstreetmap.de/routed-bike/route/v1/driving/"
                       : "https://router.project-osrm.org/route/v1/driving/";
            var url = server +
                a.loc.lng() + "," + a.loc.lat() + ";" + b.loc.lng() + "," + b.loc.lat() +
                "?overview=full&geometries=geojson";
            $.getJSON(url).then(function (r) {
                if (!r.routes || !r.routes.length) return cb(null, "ZERO_RESULTS");
                var path = simplifyPath(r.routes[0].geometry.coordinates.map(function (c) { return new LatLng(c[1], c[0]); }), 3000);
                cb({ routes: [{ overview_path: path }] }, "OK");
            }, function () { cb(null, "UNKNOWN_ERROR"); });
        }, function (e) { cb(null, typeof e === "string" ? e : "NOT_FOUND"); });
    };

    function PlacesService() { }
    PlacesService.prototype.nearbySearch = function (req, cb) { cb([], "ZERO_RESULTS"); };

    window.sytSimplifyPath = function (pairs, max) {   // [[lat,lng],...] -> thinned [[lat,lng],...]
        var path = pairs.map(function (p) { return new LatLng(p[0], p[1]); });
        path.forEach(function (p, i) { p._src = pairs[i]; });
        return simplifyPath(path, max).map(function (p) { return p._src; });
    };

    window.google = { maps: {
        LatLng: LatLng, Geocoder: Geocoder, ElevationService: ElevationService,
        DirectionsService: DirectionsService, UnitSystem: { METRIC: 0, IMPERIAL: 1 },
        places: { PlacesService: PlacesService, PlacesServiceStatus: { OK: "OK", ZERO_RESULTS: "ZERO_RESULTS" } }
    } };

    // Mapbox style URLs/tokens in the app are dead and the OSM volunteer tile servers reject clients that
    // send no Referer, so the base maps are keyless providers (OSM, Esri, OpenTopoMap).
    var OSM_ATTR = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';
    var ESRI = "https://server.arcgisonline.com/ArcGIS/rest/services/";
    window.SYT_MAP_STYLES = {
        // The page sends its origin as Referer (<meta name="referrer">), which OSM's tile policy requires.
        osm:       { label: "Streets (OpenStreetMap)", url: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", subdomains: "abc", maxZoom: 19, attribution: OSM_ATTR },
        esri:      { label: "Streets (Esri)", url: ESRI + "World_Street_Map/MapServer/tile/{z}/{y}/{x}", subdomains: "abc", maxZoom: 19, attribution: "Tiles &copy; Esri" },
        light:     { label: "Light",     url: ESRI + "Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}", subdomains: "abc", maxZoom: 16, attribution: "Tiles &copy; Esri" },
        dark:      { label: "Dark",      url: ESRI + "Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}", subdomains: "abc", maxZoom: 16, attribution: "Tiles &copy; Esri" },
        satellite: { label: "Satellite", url: ESRI + "World_Imagery/MapServer/tile/{z}/{y}/{x}", subdomains: "abc", maxZoom: 18, attribution: "Tiles &copy; Esri" },
        topo:      { label: "Topographic", url: "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png", subdomains: "abc", maxZoom: 17, attribution: OSM_ATTR + ', SRTM | &copy; <a href="https://opentopomap.org">OpenTopoMap</a>' }
    };
    function savedStyle() {
        try { var c = $.cookie("settings_mapStyle"); if (c && window.SYT_MAP_STYLES[c]) return c; } catch (e) { }
        return "osm";
    }
    window.sytMapStyle = savedStyle();

    var origTileLayer = L.tileLayer;
    L.tileLayer = function () {
        var st = window.SYT_MAP_STYLES[window.sytMapStyle] || window.SYT_MAP_STYLES.osm;
        return origTileLayer(st.url, { subdomains: st.subdomains, maxZoom: st.maxZoom, attribution: st.attribution });
    };
    for (var k in origTileLayer) { if (origTileLayer.hasOwnProperty(k)) L.tileLayer[k] = origTileLayer[k]; }

    // Fill the "Map style" list in Settings with the styles above.
    $(function () {
        var sel = $("#mapStyle");
        if (!sel.length) return;
        sel.empty();
        $.each(window.SYT_MAP_STYLES, function (key, st) { sel.append($("<option>").val(key).text(st.label)); });
        sel.val(window.sytMapStyle);
    });
})();
