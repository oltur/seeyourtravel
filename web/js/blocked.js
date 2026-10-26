// Countries that are covered with a blank white layer on the map; tracks that go into them are not opened.
// Borders: Natural Earth 1:10m, Ukrainian perspective (geo/blocked.json).
(function () {
    var parts = [];          // { name, bbox: [w, s, e, n], rings: [outer, hole1, ...] }
    var ready = null;        // promise of the loaded borders

    function ringHas(x, y, ring) {
        var c = false;
        for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
            var xi = ring[i][0], yi = ring[i][1], xj = ring[j][0], yj = ring[j][1];
            if ((yi > y) !== (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) c = !c;
        }
        return c;
    }

    function prepare(data) {
        data.features.forEach(function (f) {
            var g = f.geometry, polys = g.type === "MultiPolygon" ? g.coordinates : [g.coordinates];
            polys.forEach(function (rings) {
                var w = 180, s = 90, e = -180, n = -90;
                rings[0].forEach(function (c) { w = Math.min(w, c[0]); e = Math.max(e, c[0]); s = Math.min(s, c[1]); n = Math.max(n, c[1]); });
                parts.push({ name: f.properties.n, bbox: [w, s, e, n], rings: rings });
            });
        });
    }

    function load() {
        if (!ready) ready = $.getJSON("geo/blocked.json").then(function (d) { prepare(d); return d; });
        return ready;
    }

    // name of the blocked country that the point is in, or ""
    function countryAt(lat, lng) {
        for (var i = 0; i < parts.length; i++) {
            var p = parts[i], b = p.bbox;
            if (lng < b[0] || lng > b[2] || lat < b[1] || lat > b[3]) continue;
            if (!ringHas(lng, lat, p.rings[0])) continue;
            var inHole = false;
            for (var h = 1; h < p.rings.length; h++) if (ringHas(lng, lat, p.rings[h])) { inHole = true; break; }
            if (!inHole) return p.name;
        }
        return "";
    }

    // inside by a margin: the borders are drawn on a 1:10 000 000 scale (off by a kilometre or two), so a point that only touches
    // the border (a track running along it) is not counted; the point and four points about 2 km around it must all be inside
    function deepAt(lat, lng) {
        var c = countryAt(lat, lng);
        if (!c) return "";
        var d = 0.02;
        return (countryAt(lat + d, lng) === c && countryAt(lat - d, lng) === c && countryAt(lat, lng + d) === c && countryAt(lat, lng - d) === c) ? c : "";
    }

    // pts: [{lat,lng}] or [[lat,lng,...]]; every point of a short track, an even sample (always with both ends) of a long one
    function trackCountry(pts) {
        if (!pts || !pts.length) return "";
        var step = Math.max(1, Math.floor(pts.length / 1500));
        for (var i = 0; i < pts.length; i += step) {
            var p = pts[i], found = p.lat !== undefined ? deepAt(p.lat, p.lng) : deepAt(p[0], p[1]);
            if (found) return found;
        }
        var l = pts[pts.length - 1];
        return l.lat !== undefined ? deepAt(l.lat, l.lng) : deepAt(l[0], l[1]);
    }

    // blank white cover (dashed border) over the base map (below the markers and the track), at every zoom level
    function cover(map) {
        if (map._sytCover) return;
        map._sytCover = true;
        if (!map.getPane("blockPane")) { map.createPane("blockPane"); map.getPane("blockPane").style.zIndex = 350; map.getPane("blockPane").style.pointerEvents = "none"; }
        load().then(function (d) {
            // the base map repeats east and west when zoomed out: so does the cover
            var renderer = L.canvas({ pane: "blockPane", padding: 0.5 });
            [-1800, -1440, -1080, -720, -360, 0, 360, 720, 1080, 1440, 1800].forEach(function (shift) {
                L.geoJSON(d, {
                    pane: "blockPane", interactive: false, smoothFactor: 0.6, renderer: renderer,
                    coordsToLatLng: function (c) { return new L.LatLng(c[1], c[0] + shift); },
                    style: { color: "#a3adbb", weight: 1.5, opacity: 1, dashArray: "7 6", fillColor: "#fff", fillOpacity: 1 }
                }).addTo(map);
            });
        });
    }

    function message(country) {
        return T("BlockedTrack", "This track goes through {0}. Tracks in this country are not available on SeeYourTravel.").replace("{0}", T("Country_" + country.replace(/ /g, ""), country));
    }

    window.sytBlocked = { load: load, countryAt: countryAt, trackCountry: trackCountry, cover: cover, message: message };
})();
