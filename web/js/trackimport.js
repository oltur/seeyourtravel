// Reading tracks from files: GPX, KML / KMZ (Google My Maps), GeoJSON and Google Timeline exports
// (new on-device Timeline.json, old Takeout Records.json and "Semantic Location History" files).
//
// sytTrackImport.read(file)   -> Promise of candidates [{ label, detail, points: [[lat, lng(, text)], ...], meters }]
//                                 (a rejected promise carries an Error whose .code is
//                                  "toobig" | "kmz" | "unknown" | "invalid")
// sytTrackImport.choose(list) -> Promise of the candidate the user picked (or null); a dialog is shown
(function () {
    'use strict';
    var MAX_BYTES = 250 * 1024 * 1024;

    function fail(code, msg) { var e = new Error(msg || code); e.code = code; return e; }
    function num(v) { v = parseFloat(v); return isFinite(v) ? v : null; }
    function validLL(lat, lng) { return lat !== null && lng !== null && Math.abs(lat) <= 90 && Math.abs(lng) <= 180 && !(lat === 0 && lng === 0); }

    function meters(a, b) {   // haversine
        var R = 6371000, r = Math.PI / 180, dLat = (b[0] - a[0]) * r, dLng = (b[1] - a[1]) * r;
        var h = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(a[0] * r) * Math.cos(b[0] * r) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
    }
    function lengthOf(points) { var s = 0; for (var i = 1; i < points.length; i++) s += meters(points[i - 1], points[i]); return s; }

    // drop invalid points and immediate repeats
    function clean(points) {
        var out = [], last = null;
        points.forEach(function (p) {
            if (!p || !validLL(p[0], p[1])) return;
            if (last && last[0] === p[0] && last[1] === p[1] && !p[2]) return;
            out.push(p); last = p;
        });
        return out;
    }
    function candidate(label, points, detail) {
        points = clean(points);
        return points.length ? { label: label, detail: detail || '', points: points, meters: lengthOf(points) } : null;
    }
    function compact(list) { return list.filter(Boolean); }

    // ---------------------------------------------------------------- GPX
    function fromGpx(doc) {
        var out = [], q = function (root, name) { return Array.prototype.slice.call(root.getElementsByTagNameNS('*', name)); };
        function pts(root, name) { return q(root, name).map(function (n) { return [num(n.getAttribute('lat')), num(n.getAttribute('lon'))]; }); }
        function nm(n, fallback) { var e = q(n, 'name')[0]; return (e && e.textContent.trim()) || fallback; }
        q(doc, 'trk').forEach(function (t, i) {
            var all = [];
            q(t, 'trkseg').forEach(function (s) { all = all.concat(pts(s, 'trkpt')); });
            if (!all.length) all = pts(t, 'trkpt');
            out.push(candidate(nm(t, 'Track ' + (i + 1)), all));
        });
        q(doc, 'rte').forEach(function (r, i) { out.push(candidate(nm(r, 'Route ' + (i + 1)), pts(r, 'rtept'))); });
        if (!out.length || !compact(out).length) {
            var w = q(doc, 'wpt').map(function (n) { var e = q(n, 'name')[0]; return [num(n.getAttribute('lat')), num(n.getAttribute('lon')), e ? e.textContent.trim() : '']; });
            out.push(candidate('Waypoints', w));
        }
        return compact(out);
    }

    // ---------------------------------------------------------------- KML (Google My Maps)
    function kmlCoords(text) {   // "lon,lat,alt lon,lat,alt ..."
        var pts = [];
        String(text || '').trim().split(/\s+/).forEach(function (t) {
            var p = t.split(',');
            if (p.length >= 2) pts.push([num(p[1]), num(p[0])]);
        });
        return pts;
    }
    function fromKml(doc) {
        var q = function (root, name) { return Array.prototype.slice.call(root.getElementsByTagNameNS('*', name)); };
        var out = [], singles = [];
        q(doc, 'Placemark').forEach(function (pm, i) {
            var nameEl = Array.prototype.slice.call(pm.children).filter(function (c) { return c.localName === 'name'; })[0];
            var name = (nameEl && nameEl.textContent.trim()) || '';
            var lines = [];
            q(pm, 'LineString').forEach(function (ls) { var c = q(ls, 'coordinates')[0]; if (c) lines.push(kmlCoords(c.textContent)); });
            q(pm, 'Track').forEach(function (tr) {   // gx:Track: <gx:coord>lon lat alt</gx:coord>
                lines.push(q(tr, 'coord').map(function (c) { var p = c.textContent.trim().split(/\s+/); return [num(p[1]), num(p[0])]; }));
            });
            if (lines.length) {
                var all = [].concat.apply([], lines);
                out.push(candidate(name || ('Line ' + (i + 1)), all));
            } else {
                var pt = q(pm, 'Point')[0];
                if (pt) { var c = q(pt, 'coordinates')[0]; if (c) { var p = kmlCoords(c.textContent)[0]; if (p) singles.push([p[0], p[1], name]); } }
            }
        });
        if (singles.length) out.push(candidate('Places', singles));
        return compact(out);
    }

    // ---------------------------------------------------------------- GeoJSON
    function fromGeoJson(g) {
        var out = [];
        function lonlat(c) { return [num(c[1]), num(c[0])]; }
        function geom(geometry, name) {
            if (!geometry) return;
            var t = geometry.type, c = geometry.coordinates;
            if (t === 'LineString') out.push(candidate(name || 'Line', c.map(lonlat)));
            else if (t === 'MultiLineString') out.push(candidate(name || 'Line', [].concat.apply([], c.map(function (l) { return l.map(lonlat); }))));
            else if (t === 'GeometryCollection') geometry.geometries.forEach(function (x) { geom(x, name); });
        }
        var points = [];
        function feature(f, i) {
            var name = f.properties && (f.properties.name || f.properties.title);
            if (f.geometry && f.geometry.type === 'Point') { var p = lonlat(f.geometry.coordinates); points.push([p[0], p[1], name || '']); }
            else geom(f.geometry, name || ('Line ' + (i + 1)));
        }
        if (g.type === 'FeatureCollection') g.features.forEach(feature);
        else if (g.type === 'Feature') feature(g, 0);
        else geom(g);
        if (points.length) out.push(candidate('Places', points));
        return compact(out);
    }

    // ---------------------------------------------------------------- Google Timeline / Takeout
    function parseLL(v) {   // "51.24°, 6.33°" | "geo:51.24,6.33" | {latLng: ...} | {latitudeE7, longitudeE7} | {latE7, lngE7}
        if (v == null) return null;
        if (typeof v === 'string') {
            var m = v.match(/(-?\d+(?:\.\d+)?)\s*°?\s*,\s*(-?\d+(?:\.\d+)?)/);
            return m ? [num(m[1]), num(m[2])] : null;
        }
        if (v.latLng) return parseLL(v.latLng);
        if (v.point) return parseLL(v.point);
        if (v.latitudeE7 !== undefined) return [v.latitudeE7 / 1e7, v.longitudeE7 / 1e7];
        if (v.latE7 !== undefined) return [v.latE7 / 1e7, v.lngE7 / 1e7];
        if (v.latitude !== undefined) return [num(v.latitude), num(v.longitude)];
        return null;
    }
    function dayOf(t) {   // "2024-05-01T08:00:00+02:00" | ms | "1556000000000"
        if (t == null) return '';
        if (typeof t === 'number' || /^\d{10,}$/.test(String(t))) { var n = Number(t); return new Date(n < 1e12 ? n * 1000 : n).toISOString().slice(0, 10); }
        return String(t).slice(0, 10);
    }
    function byDay(items, labelFn) {
        // items: [{day, points:[...]}] in file order -> one candidate per day, in date order
        var days = {}, order = [];
        items.forEach(function (it) {
            if (!it.day || !it.points.length) return;
            if (!days[it.day]) { days[it.day] = []; order.push(it.day); }
            days[it.day] = days[it.day].concat(it.points);
        });
        order.sort();
        return compact(order.map(function (d) { return candidate(labelFn ? labelFn(d) : d, days[d]); })).filter(function (c) { return c.points.length > 1; });
    }
    function fromTimeline(data) {
        var items = [];
        var segs = Array.isArray(data) ? data : (data.semanticSegments || null);
        if (segs) {   // new on-device export (Android: {semanticSegments}, iOS: a plain list)
            segs.forEach(function (s) {
                var pts = [], day = dayOf(s.startTime);
                if (s.activity) { var a = parseLL(s.activity.start); if (a) pts.push(a); }
                (s.timelinePath || []).forEach(function (p) { var q = parseLL(p); if (q) pts.push(q); });
                if (s.activity) { var b = parseLL(s.activity.end); if (b) pts.push(b); }
                if (s.visit && s.visit.topCandidate) { var v = parseLL(s.visit.topCandidate.placeLocation); if (v) pts.push(v); }
                items.push({ day: day, points: pts });
            });
        } else if (data.locations) {   // old Takeout Records.json
            data.locations.forEach(function (l) { var p = parseLL(l); if (p) items.push({ day: dayOf(l.timestamp || l.timestampMs), points: [p] }); });
        } else if (data.timelineObjects) {   // old Takeout "Semantic Location History"
            data.timelineObjects.forEach(function (o) {
                var a = o.activitySegment, v = o.placeVisit, pts = [], day;
                if (a) {
                    day = dayOf(a.duration && (a.duration.startTimestamp || a.duration.startTimestampMs));
                    var s = parseLL(a.startLocation); if (s) pts.push(s);
                    var wp = (a.waypointPath && a.waypointPath.waypoints) || (a.simplifiedRawPath && a.simplifiedRawPath.points) || [];
                    wp.forEach(function (p) { var q = parseLL(p); if (q) pts.push(q); });
                    var e = parseLL(a.endLocation); if (e) pts.push(e);
                } else if (v) {
                    day = dayOf(v.duration && (v.duration.startTimestamp || v.duration.startTimestampMs));
                    var l = parseLL(v.location); if (l) pts.push(l);
                }
                items.push({ day: day, points: pts });
            });
        }
        return byDay(items, function (d) {
            var dt = new Date(d + 'T12:00:00Z');
            return isNaN(dt) ? d : dt.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric', timeZone: 'UTC' });
        });
    }

    // ---------------------------------------------------------------- KMZ (a zip with doc.kml)
    function kmzToText(buf) {
        if (typeof DecompressionStream === 'undefined') return Promise.reject(fail('kmz'));
        var dv = new DataView(buf), u8 = new Uint8Array(buf), i = u8.length - 22;
        while (i >= 0 && dv.getUint32(i, true) !== 0x06054b50) i--;
        if (i < 0) return Promise.reject(fail('invalid'));
        var count = dv.getUint16(i + 10, true), p = dv.getUint32(i + 16, true), entries = [];
        for (var k = 0; k < count; k++) {
            if (dv.getUint32(p, true) !== 0x02014b50) break;
            var nameLen = dv.getUint16(p + 28, true), extra = dv.getUint16(p + 30, true), comm = dv.getUint16(p + 32, true);
            entries.push({
                method: dv.getUint16(p + 10, true), csize: dv.getUint32(p + 20, true), offset: dv.getUint32(p + 42, true),
                name: new TextDecoder().decode(u8.subarray(p + 46, p + 46 + nameLen))
            });
            p += 46 + nameLen + extra + comm;
        }
        var e = entries.filter(function (x) { return /(^|\/)doc\.kml$/i.test(x.name); })[0] || entries.filter(function (x) { return /\.kml$/i.test(x.name); })[0];
        if (!e) return Promise.reject(fail('invalid'));
        var lh = e.offset, start = lh + 30 + dv.getUint16(lh + 26, true) + dv.getUint16(lh + 28, true);
        var data = u8.subarray(start, start + e.csize);
        if (e.method === 0) return Promise.resolve(new TextDecoder().decode(data));
        return new Response(new Blob([data]).stream().pipeThrough(new DecompressionStream('deflate-raw'))).text();
    }

    // ---------------------------------------------------------------- entry point
    function readFile(file, asBuffer) {
        return new Promise(function (resolve, reject) {
            var r = new FileReader();
            r.onload = function () { resolve(r.result); };
            r.onerror = function () { reject(fail('invalid')); };
            asBuffer ? r.readAsArrayBuffer(file) : r.readAsText(file);
        });
    }
    function parseXml(text) {
        var doc = new DOMParser().parseFromString(text, 'application/xml');
        if (doc.getElementsByTagName('parsererror').length) throw fail('invalid');
        return doc;
    }
    function fromText(text) {
        var t = text.replace(/^﻿/, '').trim();
        if (t.charAt(0) === '<') {
            var doc = parseXml(t), root = doc.documentElement.localName.toLowerCase();
            if (root === 'gpx') return fromGpx(doc);
            if (root === 'kml') return fromKml(doc);
            throw fail('unknown');
        }
        var json;
        try { json = JSON.parse(t); } catch (e) { throw fail('invalid'); }
        if (json && (json.type === 'FeatureCollection' || json.type === 'Feature' || json.coordinates || json.geometries)) return fromGeoJson(json);
        if (Array.isArray(json) || (json && (json.semanticSegments || json.locations || json.timelineObjects))) return fromTimeline(json);
        throw fail('unknown');
    }

    function read(file) {
        if (file.size > MAX_BYTES) return Promise.reject(fail('toobig'));
        var isKmz = /\.kmz$/i.test(file.name);
        var p = isKmz ? readFile(file, true).then(kmzToText) : readFile(file, false);
        return p.then(function (text) { return fromText(text); });
    }

    // ---------------------------------------------------------------- chooser dialog
    function esc(t) { return $('<div>').text(t == null ? '' : String(t)).html(); }
    function km(m) { return m < 1000 ? Math.round(m) + ' ' + T('UnitM', 'm') : (m / 1000).toFixed(m < 100000 ? 1 : 0) + ' ' + T('UnitKm', 'km'); }

    function choose(list) {
        return new Promise(function (resolve) {
            var rows = list.map(function (c, i) {
                return '<label class="ic-row"><input type="radio" name="icChoice" value="' + i + '"' + (i === 0 ? ' checked' : '') + '>' +
                    '<span class="ic-main">' + esc(c.label) + '</span>' +
                    '<span class="ic-sub">' + esc(T('ImportPoints', '{0} points').replace('{0}', c.points.length.toLocaleString()) + ' · ' + km(c.meters)) + '</span></label>';
            }).join('');
            var $d = $('<div class="ic-backdrop"><div class="ic-box" role="dialog" aria-modal="true">' +
                '<h3>' + esc(T('ImportChoose', 'Choose what to import')) + '</h3>' +
                '<div class="ic-list">' + rows + '</div>' +
                '<div class="ic-buttons"><button type="button" class="ic-cancel">' + esc(T('Cancel', 'Cancel')) + '</button>' +
                '<button type="button" class="ic-ok">' + esc(T('ImportButton', 'Import')) + '</button></div></div></div>').appendTo('body');
            function done(v) { $(document).off('keydown.ic'); $d.remove(); resolve(v); }
            $d.find('.ic-ok').on('click', function () { done(list[parseInt($d.find('input:checked').val(), 10)] || null); }).focus();
            $d.find('.ic-cancel').on('click', function () { done(null); });
            $d.on('dblclick', '.ic-row', function () { $(this).find('input').prop('checked', true); $d.find('.ic-ok').click(); });
            $d.on('click', function (e) { if (e.target === this) done(null); });
            $(document).on('keydown.ic', function (e) { if (e.key === 'Escape') done(null); });
        });
    }

    window.sytTrackImport = { read: read, choose: choose, _fromText: fromText };
})();
