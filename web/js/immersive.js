// Immersive mode (prototype): a 3D map (MapLibre GL, OpenFreeMap tiles with 3D buildings) is flown along the route with the camera
// behind the vehicle, and the photos of the route fly past on both sides in perspective. The library is loaded only when the
// mode is first used; the normal Leaflet view is untouched.
(function () {
    var BASE = 'https://tiles.openfreemap.org/styles/';
    // name -> OpenFreeMap style, the colour of the 3D buildings added where the style has none, and the sky behind the horizon
    var STYLES = {
        liberty: { b: null, sky: 'linear-gradient(#1c4f93 0%, #6aa5df 38%, #d6e8f8 62%)' },
        bright: { b: '#d8d2c8', sky: 'linear-gradient(#1c4f93 0%, #6aa5df 38%, #d6e8f8 62%)' },
        positron: { b: '#d3d6da', sky: 'linear-gradient(#5b7fa6 0%, #aac3dc 40%, #eef3f8 62%)' },
        dark: { b: '#4a5160', sky: 'linear-gradient(#05070d 0%, #131a2b 40%, #2a3550 62%)' },
        fiord: { b: '#6b7f96', sky: 'linear-gradient(#162a44 0%, #3c5a7e 40%, #8fa9c6 62%)' }
    };
    function styleName() {
        var s = null; try { s = localStorage.getItem('syt_imStyle'); } catch (e) { }
        return STYLES[s] ? s : 'liberty';
    }
    var PHONE = window.matchMedia && matchMedia('(max-width: 700px)').matches;   // fewer flying photos on a phone
    var PHOTO_LIFE_MS = PHONE ? 10500 : 8500, SPAWN_MS = PHONE ? 2300 : 1300, MAX_CARDS = PHONE ? 5 : 9, POOL_MAX = 40, PITCH = 68, ZOOM = 16.3;
    var on = false, raf = 0, last = 0, spawnAcc = 0, side = 1, heading = 0, gl = null, glReady = false, vehMarker = null, loading = false;
    var spawned = 0, pool = [], seen = {}, cards = [], $cards = null, $gl = null, routeKey = null;

    // the mode is kept in the address (#3d, or #3d-dark with a chosen style), so a reload or a shared link opens the same view
    function writeHash() {
        try {
            var h = on ? (styleName() === 'liberty' ? '#3d' : '#3d-' + styleName()) : '';
            if (on || /^#3d/.test(location.hash)) history.replaceState(null, '', location.pathname + location.search + h);
        } catch (e) { }
    }
    function readHash() {
        var m = /^#3d(?:-(\w+))?$/.exec(location.hash || '');
        if (!m) return null;
        if (m[1] && STYLES[m[1]]) { try { localStorage.setItem('syt_imStyle', m[1]); } catch (e) { } }
        return true;
    }
    function tr(key, fallback) { var s = $.t ? $.t(key) : key; return (!s || s === key) ? fallback : s; }
    function pref(name) { try { return localStorage.getItem('syt_im' + name) !== '0'; } catch (e) { return true; } }

    // ---- weather in the sky: colours by condition, a sun or moon with stars, drifting clouds, rain / snow / fog ----
    var PAL = {
        'clear-day': ['#1c6fd1', '#6fb2ee', '#dcefff'], 'partly-cloudy-day': ['#2d6fb8', '#7fb0e0', '#e3eef8'], 'cloudy': ['#66727f', '#97a3af', '#d3d9df'],
        'rain': ['#363f4b', '#566070', '#868f9a'], 'snow': ['#8896a5', '#bcc6d0', '#eef1f4'], 'fog': ['#98a1aa', '#c1c7cd', '#e6e9ec'],
        'clear-night': ['#04060e', '#0f1a33', '#26365a'], 'partly-cloudy-night': ['#070b16', '#18233f', '#2d3b5d']
    };
    var wx = null, fx = null, fxParts = [], fxKind = '', skyKey = '', fxCtx = null, fxW = 0, fxH = 0, fxClear = true;
    function isNight() { return (wx && /night$/.test(wx.icon)) || styleName() === 'dark'; }
    function skyIcon() {
        var ic = wx ? wx.icon : 'clear-day';
        if (styleName() === 'dark' && !/night$/.test(ic) && (ic === 'clear-day' || ic === 'partly-cloudy-day')) ic = ic.replace('day', 'night');
        return ic;
    }
    function applySky() {
        var $s = $('#imSky'); if (!$s.length) return;
        // unchanged weather and style: keep the sky as it is (rebuilding restarts the clouds and makes them jump)
        var key = styleName() + '|' + pref('Wx') + '|' + (wx ? wx.icon : '');
        if (key === skyKey) return;
        skyKey = key;
        var $art = $('#imSkyArt').empty();
        if (!pref('Wx') || !wx) { $s.css('background', STYLES[styleName()].sky); fxKind = ''; return; }
        var ic = skyIcon(), pal = PAL[ic] || PAL['clear-day'];
        $s.css('background', 'linear-gradient(' + pal[0] + ' 0%, ' + pal[1] + ' 40%, ' + pal[2] + ' 64%)');
        var night = /night$/.test(ic), clear = /^clear/.test(ic), part = /^partly/.test(ic);
        if (clear || part) {
            if (night) {
                for (var i = 0; i < 40; i++) $('<i class="imStar">').css({ left: Math.random() * 100 + '%', top: Math.random() * 34 + '%', opacity: .4 + Math.random() * .6, width: (1 + Math.random() * 2) + 'px', height: (1 + Math.random() * 2) + 'px' }).appendTo($art);
                $('<div class="imMoon">').appendTo($art);
            } else $('<div class="imSun">').appendTo($art);
        }
        var nClouds = clear ? 0 : part ? 4 : ic === 'cloudy' ? 9 : ic === 'rain' ? 10 : ic === 'snow' ? 8 : ic === 'fog' ? 3 : 0;
        if (PHONE) nClouds = Math.round(nClouds * 1.4);
        var cc = (ic === 'rain') ? '#59616b' : (ic === 'cloudy') ? '#aeb6bf' : night ? '#4a5878' : '#ffffff';
        for (var k = 0; k < nClouds; k++) {
            var sc = PHONE ? .3 + Math.random() * .32 : .7 + Math.random() * 1.1;   // smaller on a phone, so they still look like clouds
            $('<div class="imCloud">').css({ '--cc': cc, top: (2 + Math.random() * 30) + '%', transform: 'scale(' + sc.toFixed(2) + ')', animationDuration: (90 + Math.random() * 120).toFixed(0) + 's', animationDelay: '-' + (Math.random() * 200).toFixed(0) + 's', opacity: (ic === 'cloudy' || ic === 'rain') ? .95 : .85 }).appendTo($art);
        }
        if (ic === 'fog') $('<div class="imFog">').appendTo($art);
        fxKind = ic === 'rain' ? 'rain' : ic === 'snow' ? 'snow' : '';
        fxParts = [];
        if (fxKind && fx) {
            var n = fxKind === 'rain' ? 170 : 120;
            for (var q = 0; q < n; q++) fxParts.push({ x: Math.random(), y: Math.random(), s: .6 + Math.random() * .8, d: Math.random() * 6.28 });
        }
    }
    function fxStep(dt) {
        if (!fx) return;
        if (!fxKind) { if (!fxClear && fxCtx) { fxCtx.clearRect(0, 0, fx.width, fx.height); fxClear = true; } return; }   // nothing falls: nothing is drawn
        if (!moving()) return;                                                                                          // paused: the drops stand still
        var q = PHONE ? 0.6 : 1, w = Math.round(fx.clientWidth * q), h = Math.round(fx.clientHeight * q);
        if (!fxCtx) fxCtx = fx.getContext('2d');
        if (w !== fxW || h !== fxH) { fx.width = fxW = w; fx.height = fxH = h; }   // resizing clears and reallocates the canvas: only when the size changed
        var c = fxCtx; c.clearRect(0, 0, w, h); fxClear = false;
        if (fxKind === 'rain') {
            c.strokeStyle = 'rgba(190,210,235,.55)'; c.lineWidth = 1.2 * q; c.beginPath();
            for (var i = 0; i < fxParts.length; i++) {
                var p = fxParts[i];
                p.y += dt * 0.0013 * (1.4 + p.s); p.x -= dt * 0.00018;
                if (p.y > 1) { p.y = -0.05; p.x = Math.random(); } if (p.x < 0) p.x = 1;
                c.moveTo(p.x * w, p.y * h); c.lineTo(p.x * w - 3 * q, p.y * h + 14 * p.s * q);
            }
            c.stroke();                                                                                                  // one path for all drops
        } else {
            c.fillStyle = 'rgba(255,255,255,.85)'; c.beginPath();
            for (var j = 0; j < fxParts.length; j++) {
                var f = fxParts[j];
                f.y += dt * 0.00014 * (.8 + f.s); f.d += dt * 0.0012; f.x += Math.sin(f.d) * 0.0004;
                if (f.y > 1) { f.y = -0.03; f.x = Math.random(); }
                var r = (1.4 + f.s * 1.6) * q; c.moveTo(f.x * w + r, f.y * h); c.arc(f.x * w, f.y * h, r, 0, 6.28);
            }
            c.fill();
        }
    }
    var lastWx = -1e9, lastTk = 0;
    function pullWeather(v) {
        if (!window.syt || !syt.api || !syt.api.searchWeather) return;
        try {
            syt.api.searchWeather({ location: { lat: function () { return v.lat; }, lng: function () { return v.lng; } } }).then(function (r) {
                if (on && r && r.icon) { wx = { icon: r.icon, temp: r.temperature }; applySky(); }
            });
        } catch (e) { }
    }

    // ---- running line: the places near the vehicle (from the places already on the map) ----
    var info = { text: '', at: 0, lat: 0, lng: 0 }, infoBusy = false;
    function wikiLang() { var m = document.cookie.match(/(?:^|; )i18next=([^;]*)/), c = m ? decodeURIComponent(m[1]).slice(0, 2) : 'en'; return /^(en|de|uk|he)$/.test(c) ? c : 'en'; }
    // local info: the first sentences of the nearest Wikipedia article, and the height above sea level
    function pullInfo(v) {
        if (infoBusy) return; infoBusy = true;
        var done = function () { infoBusy = false; };
        var wl = wikiLang(), parts = {};
        var q1 = $.ajax({ dataType: 'json', url: 'https://' + wl + '.wikipedia.org/w/api.php', data: { action: 'query', generator: 'geosearch', ggscoord: v.lat + '|' + v.lng, ggsradius: 8000, ggslimit: 6, prop: 'extracts', exintro: 1, exsentences: 2, explaintext: 1, exlimit: 6, format: 'json', origin: '*' } });
        var q2 = $.ajax({ dataType: 'json', url: 'https://api.open-meteo.com/v1/elevation', data: { latitude: v.lat, longitude: v.lng } });
        $.when(q1.then(function (r) { return r; }, function () { return $.Deferred().resolve(null); }), q2.then(function (r) { return r; }, function () { return $.Deferred().resolve(null); })).then(function (a, b) {
            var out = [];
            try {
                var pages = a && a.query && a.query.pages ? Object.keys(a.query.pages).map(function (k) { return a.query.pages[k]; }) : [];
                pages.sort(function (x, y) { return (x.index || 0) - (y.index || 0); });
                for (var i = 0; i < pages.length; i++) {
                    var p = pages[i], ex = (p.extract || '').replace(/\s+/g, ' ').trim();
                    if (ex.length > 40) { out.push(p.title + ': ' + (ex.length > 220 ? ex.slice(0, 217) + '\u2026' : ex)); break; }
                }
                if (b && b.elevation && b.elevation.length) out.push(tr('ImElevation', 'Elevation') + ' ' + Math.round(b.elevation[0]) + ' m');
            } catch (e) { }
            info = { text: out.join('   \u00b7   '), at: Date.now(), lat: v.lat, lng: v.lng };
            done();
        }, done);
    }
    var tickerNext = '';
    function dist(a, b, c, d) {
        var R = 6371000, x = (d - b) * Math.PI / 180 * Math.cos((a + c) / 2 * Math.PI / 180), y = (c - a) * Math.PI / 180;
        return Math.sqrt(x * x + y * y) * R;
    }
    function fmtDist(m) { return m < 1000 ? Math.round(m / 10) * 10 + ' m' : (m / 1000).toFixed(1) + ' km'; }
    function tickerText(v) {
        var all = window.sytSeenPlaces || {}, list = [];
        Object.keys(all).forEach(function (k) { var p = all[k]; if (p && p.name) { var d = dist(v.lat, v.lng, p.lat, p.lng); if (d < 6000) list.push({ p: p, d: d }); } });
        list.sort(function (a, b) { return ((b.p.description ? 1 : 0) - (a.p.description ? 1 : 0)) || (a.d - b.d); });
        var parts = list.slice(0, 4).map(function (x) { return x.p.name + (x.p.description ? ' \u2014 ' + x.p.description : '') + ' (' + fmtDist(x.d) + ')'; });
        var out = [];
        if (parts.length) out.push(tr('ImNearby', 'Nearby') + ': ' + parts.join('   \u00b7   '));
        if (info.text) out.push(info.text);
        if (wx && wx.temp) out.push(wx.temp);
        return out.join('   \u00b7   ');
    }
    function tickerStart() {
        var $t = $('#imTicker'); if (!$t.length) return;
        var span = $t.find('span')[0];
        span.addEventListener('animationiteration', function () { tickerLoad(span); });
        tickerLoad(span);
    }
    function tickerLoad(span) {
        var v = vehicle(), txt = (pref('Ticker') && v) ? tickerText(v) : '';
        $('#imTicker').toggle(!!txt);
        if (txt !== span.textContent) span.textContent = txt;
        // about 70 pixels a second
        span.style.animationDuration = Math.max(14, Math.round((txt.length * 7.5 + window.innerWidth) / 70)) + 's';
    }

    function moving() { return typeof isTrackPaused !== 'undefined' && !isTrackPaused && typeof animatedMarker !== 'undefined'; }

    function loadLib(cb) {
        if (window.maplibregl) return cb();
        if (loading) return; loading = true;
        var l = document.createElement('link'); l.rel = 'stylesheet'; l.href = 'libs/maplibre-gl.css'; document.head.appendChild(l);
        var s = document.createElement('script'); s.src = 'libs/maplibre-gl.js'; s.onload = function () { loading = false; cb(); };
        s.onerror = function () { loading = false; if (window.toastr) toastr.error('Immersive mode could not load'); leave(); };
        document.head.appendChild(s);
    }

    // where the vehicle is right now, and the direction (degrees, 0 = north) of the segment it is on
    function vehicle() {
        var am = window.animatedMarker;
        if (!am || !am.getLatLng) return null;
        var s = am._seg, ll = am.getLatLng();
        if (s && s.from && s.to && s.dur > 0) {
            var f = Math.max(0, Math.min(1, (Date.now() - s.start) / s.dur));
            var lat = s.from.lat + (s.to.lat - s.from.lat) * f, lng = s.from.lng + (s.to.lng - s.from.lng) * f;
            var dy = s.to.lat - s.from.lat, dx = (s.to.lng - s.from.lng) * Math.cos(lat * Math.PI / 180);
            var b = (dx === 0 && dy === 0) ? null : Math.atan2(dx, dy) * 180 / Math.PI;
            return { lat: lat, lng: lng, bearing: b };
        }
        return { lat: ll.lat, lng: ll.lng, bearing: null };
    }

    function feed(photos) {
        if (!photos) return;
        for (var i = 0; i < photos.length; i++) {
            var ph = photos[i], k = ph.photo_file_url;
            if (!k || seen[k]) continue;
            seen[k] = 1; pool.push(ph);
        }
        while (pool.length > POOL_MAX) pool.shift();
    }

    function spawn() {
        if (!pool.length || cards.length >= MAX_CARDS) return;
        // own and public photos (Wikimedia Commons etc.) take turns, so neither kind is starved
        var want = (spawned++ % 2 === 0) ? 'own' : 'public', idx = -1;
        for (var i = 0; i < pool.length && idx < 0; i++) if ((pool[i].source === 'own') === (want === 'own')) idx = i;
        if (idx < 0) idx = 0;
        var ph = pool.splice(idx, 1)[0];
        var el = document.createElement('div');
        el.className = 'imCard';
        var im = new Image();
        im.alt = ''; im.decoding = 'async'; im.src = ph.photo_file_url;
        el.appendChild(im);
        // attribution: the author and licence of public photos, who is on (or that it is from the community for) own ones
        var cap = document.createElement('span');
        cap.className = 'imCredit';
        cap.textContent = (ph.people && ph.people.length) ? ph.people.join(', ') : (typeof photoCredit === 'function' ? photoCredit(ph) : (ph.owner_name || ''));
        el.appendChild(cap);
        el.addEventListener('click', function () { if (window.photoViewer) photoViewer.open(0, [ph]); });
        $cards.append(el);
        side = -side;
        cards.push({ el: el, t: 0, side: side, lift: (Math.random() - .5) * 0.16 });
    }

    function layout(c, W, H) {
        // perspective walls: a fixed distance from the road, coming toward the viewer; large, so they overlap and fill the sides
        // phones: the photos stay further out, stop growing sooner and fade earlier, so they never cover the vehicle
        var t = c.t, z = PHONE ? -2200 + t * 2550 : -2200 + t * 3000;
        var x = c.side * W * (PHONE ? 0.34 : 0.30), y = -H * (0.0 + c.lift);
        var a = c.side * -22;                                   // turned toward the road
        var fo = PHONE ? .74 : .84;
        var fade = t < .10 ? t / .10 : (t > fo ? Math.max(0, (1 - t) / (1 - fo)) : 1);
        c.el.style.opacity = fade.toFixed(3);
        c.el.style.transform = 'translate3d(' + x.toFixed(1) + 'px,' + y.toFixed(1) + 'px,' + z.toFixed(1) + 'px) rotateY(' + a + 'deg)';
    }

    function buildGl() {
        var v = vehicle(); if (!v) return;
        $gl = $('<div id="imMap"></div>').appendTo('body');
        setupDone = false; glReady = false; vehMarker = null; glMarkers = {};
        gl = new maplibregl.Map({
            container: 'imMap', style: BASE + styleName(), center: [v.lng, v.lat], zoom: ZOOM, pitch: PITCH, bearing: heading,
            maxPitch: 85, interactive: false, attributionControl: false, fadeDuration: 0,
            pixelRatio: Math.min(window.devicePixelRatio || 1, PHONE ? 1.5 : 2), antialias: !PHONE   // a 3x screen would draw 9x the pixels
        });
        gl.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-left');
        if (window.matchMedia && matchMedia('(max-width: 700px)').matches) setTimeout(function () { $('#imMap .maplibregl-ctrl-attrib').removeClass('maplibregl-compact-show'); }, 4000);   // phones: only the (i) button stays; tap it for the credit
        // (re)built every time a style has loaded: the route, and 3D buildings for the styles that have none of their own
        var setup = function () {
            // once per style: the route and 3D buildings (for styles with none of their own) are added as soon as the style is usable
            if (setupDone || !gl || !gl.isStyleLoaded()) return;
            var sty = STYLES[styleName()];
            // the vector source of the new style may not be registered yet: try again on the next event instead of giving up
            if (!gl.getSource('openmaptiles')) return;
            // still the OLD style (our route is in it): the swapped one has not arrived yet, so wait
            if (gl.getLayer('route-line') || gl.getLayer('building-3d-added')) return;
            setupDone = true;
            glReady = true;
            applySky();
            try {
                var has = gl.getStyle().layers.some(function (l) { return l.type === 'fill-extrusion'; });
                if (!has && sty.b && gl.getSource('openmaptiles')) {
                    gl.addLayer({ id: 'building-3d-added', type: 'fill-extrusion', source: 'openmaptiles', 'source-layer': 'building', minzoom: 14,
                        paint: { 'fill-extrusion-color': sty.b, 'fill-extrusion-height': ['coalesce', ['get', 'render_height'], 8], 'fill-extrusion-base': ['coalesce', ['get', 'render_min_height'], 0], 'fill-extrusion-opacity': 0.92 } });
                }
            } catch (e) { console.log('3D buildings: ' + e); }
            addTerrain();
            var data = (window.track && track.trackData) || [], step = Math.max(1, Math.floor(data.length / 1500)), pts = [];
            for (var i = 0; i < data.length; i += step) pts.push([data[i].lng, data[i].lat]);
            if (pts.length > 1) {
                gl.addSource('route', { type: 'geojson', data: { type: 'Feature', geometry: { type: 'LineString', coordinates: pts } } });
                gl.addLayer({ id: 'route-casing', type: 'line', source: 'route', layout: { 'line-cap': 'round', 'line-join': 'round' }, paint: { 'line-color': '#ffffff', 'line-width': 11 } });
                gl.addLayer({ id: 'route-line', type: 'line', source: 'route', layout: { 'line-cap': 'round', 'line-join': 'round' }, paint: { 'line-color': '#e8344e', 'line-width': 6 } });
            }
            if (!vehMarker) {
                var el = document.createElement('div'); el.className = 'imVehicle';
                var ic = animatedMarker.options && animatedMarker.options.icon && animatedMarker.options.icon.options && animatedMarker.options.icon.options.iconUrl;
                if (ic) { var im = new Image(); im.src = ic; im.alt = ''; el.appendChild(im); }
                vehMarker = new maplibregl.Marker({ element: el, anchor: 'bottom', pitchAlignment: 'viewport', rotationAlignment: 'viewport' }).setLngLat([v.lng, v.lat]).addTo(gl);
            }
        };
        // the map could not be loaded (tile server unreachable): say so and go back to the normal map
        var guard = gl;
        setTimeout(function () { if (on && gl === guard && !glReady) { if (window.toastr) toastr.error('3D map could not be loaded'); leave(); } }, 25000);
        gl.on('styledata', setup);
        gl.on('idle', setup);          // safety net: a style that was swapped has finished drawing
    }

    // hills: free elevation tiles (Terrarium: Mapzen / AWS open data) lift the ground; buildings and the route stand on it
    function addTerrain() {
        if (!gl) return;
        try {
            if (!gl.getSource('imDem')) gl.addSource('imDem', { type: 'raster-dem', tiles: ['https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png'], tileSize: 256, maxzoom: 14, encoding: 'terrarium', attribution: 'Elevation: Mapzen, AWS Terrain Tiles' });
            if (!gl.getLayer('imHill')) gl.addLayer({ id: 'imHill', type: 'hillshade', source: 'imDem', paint: { 'hillshade-exaggeration': 0.45, 'hillshade-shadow-color': 'rgba(20,30,50,.55)', 'hillshade-highlight-color': 'rgba(255,255,255,.35)' } });
            applyTerrain();
        } catch (e) { console.log('terrain: ' + e); }
    }
    function applyTerrain() {
        if (!gl || !gl.getSource('imDem')) return;
        var onT = pref('Terrain');
        gl.setTerrain(onT ? { source: 'imDem', exaggeration: 1.5 } : null);
        if (gl.getLayer('imHill')) gl.setLayoutProperty('imHill', 'visibility', onT ? 'visible' : 'none');
    }

    // ---- the markers of the normal map are shown in 3D too: places, weather, text points, start and finish, photo pins ----
    var glMarkers = {}, lastSync = 0, glPopup = null;
    function leafletMarkers() {
        var out = [];
        function walk(g) { if (!g || !g.eachLayer) return; g.eachLayer(function (l) { if (l instanceof L.Marker) out.push(l); else walk(l); }); }
        if (window.markers) walk(window.markers);
        return out;
    }
    function markerEl(m) {
        var ic = m.options.icon, o = (ic && ic.options) || {}, el = document.createElement('div'), anchor, size;
        if (o.html !== undefined) {
            size = o.iconSize || [30, 30]; anchor = o.iconAnchor || [size[0] / 2, size[1] / 2];
            el.className = o.className || ''; el.innerHTML = typeof o.html === 'string' ? o.html : '';
        } else {
            var url = o.iconUrl || (ic && ic._getIconUrl ? ic._getIconUrl('icon') : '');
            size = o.iconSize || [25, 41]; anchor = o.iconAnchor || [size[0] / 2, size[1]];
            var im = new Image(); im.src = url; im.alt = ''; im.draggable = false; el.appendChild(im);
            el.className = o.className || '';
        }
        el.style.width = size[0] + 'px'; el.style.height = size[1] + 'px'; el.style.cursor = 'pointer';
        var img = el.querySelector(':scope > img'); if (img && o.html === undefined) { img.style.width = size[0] + 'px'; img.style.height = size[1] + 'px'; img.style.display = 'block'; }
        var tt = m.getTooltip && m.getTooltip();
        if (tt && tt.options && tt.options.permanent) {
            var c = tt.getContent(), lab = document.createElement('span');
            lab.className = 'imLabel'; lab.textContent = (c && c.nodeType) ? c.textContent : String(c || '');
            el.style.overflow = 'visible'; el.appendChild(lab);
        }
        el.addEventListener('click', function (e) {
            e.stopPropagation();
            var pc = m.getPopup && m.getPopup();
            // markers without a popup have their own click action on the normal map (e.g. a photo pin opens the large photo): run it
            if (!pc) { try { m.fire('click', { latlng: m.getLatLng() }); } catch (err) { } return; }
            if (!gl) return;
            var cc = pc.getContent(), node;
            if (typeof cc === 'function') { try { cc = cc(m); } catch (err) { return; } }   // e.g. the places build their popup when it is opened
            if (typeof cc === 'string') { node = document.createElement('div'); node.innerHTML = cc; }
            else if (cc && cc.nodeType) { node = cc.cloneNode(true); node.onclick = cc.onclick; }
            else return;
            if (glPopup) glPopup.remove();
            var ll = m.getLatLng();
            glPopup = new maplibregl.Popup({ offset: [size[0] / 2 - anchor[0], -anchor[1] - 4], maxWidth: '280px' }).setLngLat([ll.lng, ll.lat]).setDOMContent(node).addTo(gl);
        });
        return { el: el, anchor: anchor };
    }
    function syncMarkers(v) {
        if (!gl || !glReady || !window.L) return;
        var want = {}, near = [];
        leafletMarkers().forEach(function (m) {
            var ll = m.getLatLng();
            if (!ll || Math.abs(ll.lat) > 90 || m === window.animatedMarker || m === window.markerWhereIAm) return;
            var d = dist(v.lat, v.lng, ll.lat, ll.lng);
            if (d < 7000 || m === window.markerStart || m === window.markerFinish) near.push({ m: m, d: d });
        });
        near.sort(function (a, b) { return a.d - b.d; });
        near.slice(0, 200).forEach(function (x) {
            var id = L.stamp(x.m); want[id] = 1;
            var rec = glMarkers[id];
            if (rec && rec.ic !== x.m.options.icon) { rec.gm.remove(); delete glMarkers[id]; rec = null; }   // e.g. the start marker gets its round picture later
            if (!rec) {
                var built = markerEl(x.m), ll = x.m.getLatLng();
                var gm = new maplibregl.Marker({ element: built.el, anchor: 'top-left', offset: [-built.anchor[0], -built.anchor[1]], pitchAlignment: 'viewport', rotationAlignment: 'viewport' }).setLngLat([ll.lng, ll.lat]).addTo(gl);
                glMarkers[id] = { gm: gm, ic: x.m.options.icon };
            }
        });
        Object.keys(glMarkers).forEach(function (id) { if (!want[id]) { glMarkers[id].gm.remove(); delete glMarkers[id]; } });
    }

    var camKey = '', slow = 0, slowN = 0, lowered = false, lastCam = 0, lastFeed = 0, lastOcc = 0, setupDone = false, zoomOff = 0, zoomCur = 0;
    function clampZoom(z) { return Math.max(13, Math.min(18, z)); }
    function zoomBy(d) { zoomOff = clampZoom(ZOOM + zoomOff + d) - ZOOM; }
    function frame(now) {
        raf = requestAnimationFrame(frame);
        var dt = Math.min(100, now - (last || now)); last = now;
        // a slow device: after three seconds of frames longer than 40 ms the map is drawn at a lower resolution
        if (moving() && dt > 0) { slow += dt; slowN++; if (slowN >= 120) { if (!lowered && slow / slowN > 40 && gl && gl.setPixelRatio) { lowered = true; try { gl.setPixelRatio(1); } catch (e) { } } slow = 0; slowN = 0; } }
        var v = vehicle();
        if (v && gl && glReady && now - lastCam > 30) {
            lastCam = now;
            if (v.bearing != null) {
                var d = ((v.bearing - heading + 540) % 360) - 180;
                heading = (heading + d * 0.06 + 360) % 360;
            }
            // the vehicle sits in the lower part of the picture: the camera is behind it
            var h = window.innerHeight;                                   // (no layout read every frame)
            zoomCur += (zoomOff - zoomCur) * (1 - Math.exp(-dt / 140));   // eases over about a third of a second, independent of the frame rate
            var ck = v.lat + '|' + v.lng + '|' + heading.toFixed(2) + '|' + zoomCur.toFixed(3) + '|' + h;
            if (ck !== camKey) {                                          // paused and still: the camera is not touched
                camKey = ck;
                gl.jumpTo({ center: [v.lng, v.lat], bearing: heading, pitch: PITCH, zoom: ZOOM + zoomCur, padding: { top: Math.round(h * 0.6), bottom: 0, left: 0, right: 0 } });
            }
            if (vehMarker) vehMarker.setLngLat([v.lng, v.lat]);
        }
        // the photos around the vehicle (own and public ones) keep the walls supplied, also at places the strip is not updated for
        if (v && now - lastFeed > 8000 && window.photoSearch && window.track) {
            lastFeed = now;
            try { photoSearch.get(track, { lat: v.lat, lng: v.lng }).then(function (r) { if (on && r) feed(r.photos); }); } catch (e) { }
        }
        fxStep(dt);
        // markers behind a mountain are drawn faint by the map (opacity 0.2) and would hang in the sky: hide them completely
        if (now - lastOcc > 250) {
            lastOcc = now;
            Object.keys(glMarkers).forEach(function (id) { var e = glMarkers[id].gm.getElement(), op = parseFloat(e.style.opacity); e.classList.toggle('imOccluded', op === op && op < 0.5); });
        }
        if (v && now - lastSync > 1500) { lastSync = now; try { syncMarkers(v); } catch (e) { console.log('markers: ' + e); } }
        if (v && pref('Ticker') && (Date.now() - info.at > 60000 || dist(v.lat, v.lng, info.lat, info.lng) > 3000)) pullInfo(v);
        // the running line is filled again while it is empty (the places arrive a little after the start)
        if (now - lastTk > 3000) { lastTk = now; var tk = $('#imTicker span')[0]; if (tk && !tk.textContent) tickerLoad(tk); }
        if (v && now - lastWx > 90000) { lastWx = now; pullWeather(v); }
        if (!moving()) return;                                    // paused: the photos stay where they are
        spawnAcc += dt;
        if (spawnAcc >= SPAWN_MS) { spawnAcc = 0; spawn(); }
        var W = $cards[0].clientWidth, H = $cards[0].clientHeight;
        for (var i = cards.length - 1; i >= 0; i--) {
            var c = cards[i];
            c.t += dt / PHOTO_LIFE_MS;
            if (c.t >= 1) { c.el.remove(); cards.splice(i, 1); continue; }
            layout(c, W, H);
        }
    }

    function enter() {
        if (on || typeof map === 'undefined' || typeof animatedMarker === 'undefined') return;
        on = true;
        if (PHONE && fsCan() && !fsOn()) { fsAuto = true; fsEnter(); }   // the 3D button click allows it
        document.body.classList.add('immersive');
        $('#immersiveButton').addClass('on');
        writeHash();
        loadLib(function () {
            if (!on) return;
            $('<div id="imSky"></div>').css('background', STYLES[styleName()].sky).appendTo('body');
            $('<div id="imSkyArt"></div>').appendTo('body');
            fx = $('<canvas id="imFx"></canvas>').appendTo('body')[0];
            $('<div id="imTicker"><span></span></div>').appendTo('body');
            zoomOff = 0; zoomCur = 0;
            var $z = $('<div id="imZoom"><button type="button" class="in" aria-label="Zoom in" title="Zoom in">+</button><button type="button" class="out" aria-label="Zoom out" title="Zoom out">\u2212</button></div>').appendTo('body');
            $z.find('.in').on('click', function () { zoomBy(1); });
            $z.find('.out').on('click', function () { zoomBy(-1); });
            lastWx = -1e9; lastTk = 0; wx = wx || null;
            buildGl();
            $cards = $('<div id="imCards"></div>').appendTo('body');
            if (window.lastStripArgs) feed(window.lastStripArgs.photos);   // photos already found are the first ones to fly in
            last = 0; spawnAcc = SPAWN_MS - 300; cards = [];
            raf = requestAnimationFrame(frame);
            applySky(); tickerStart();
        });
    }

    function leave() {
        if (!on) return;
        on = false;
        if (fsAuto && fsOn()) fsLeave(); fsAuto = false;
        cancelAnimationFrame(raf);
        document.body.classList.remove('immersive');
        glMarkers = {}; glPopup = null; setupDone = false; glReady = false; vehMarker = null; skyKey = ''; camKey = ''; fxCtx = null; fxW = fxH = 0; seen = {}; pool = []; lowered = false;   // a new 3D session starts from scratch
        if (gl) { try { gl.remove(); } catch (e) { } gl = null; glReady = false; vehMarker = null; }
        $('#imMap, #imSky, #imSkyArt, #imFx, #imTicker, #imCards, #imZoom').remove(); fx = null;
        $gl = null; $cards = null; cards = [];
        $('#immersiveButton').removeClass('on');
        writeHash();
        try { map.setView(animatedMarker.getLatLng(), map.getZoom(), { animate: false }); } catch (e) { }   // the normal map was not followed meanwhile: pick up the vehicle
    }

    function setStyle(name) {
        if (!STYLES[name]) name = 'liberty';
        try { localStorage.setItem('syt_imStyle', name); } catch (e) { }
        if (on && gl) { glReady = false; setupDone = false; gl.setStyle(BASE + name); writeHash(); }
    }
    // ---- fullscreen (where the browser allows it: Android, desktop; iPhone only as an installed web app) ----
    var fsEl = document.documentElement, fsAuto = false;
    function fsOn() { return !!(document.fullscreenElement || document.webkitFullscreenElement); }
    function fsCan() { return !!(fsEl.requestFullscreen || fsEl.webkitRequestFullscreen); }
    function fsEnter() { try { var p = (fsEl.requestFullscreen || fsEl.webkitRequestFullscreen).call(fsEl); if (p && p.catch) p.catch(function () { }); } catch (e) { } }
    function fsLeave() { try { var p = (document.exitFullscreen || document.webkitExitFullscreen).call(document); if (p && p.catch) p.catch(function () { }); } catch (e) { } }
    window.sytFullscreen = { toggle: function () { fsAuto = false; fsOn() ? fsLeave() : fsEnter(); }, can: fsCan };
    window.sytImmersive = { refreshHash: writeHash, zoomTarget: function () { return ZOOM + zoomOff; }, gl: function () { return gl; }, setStyle: setStyle, stats: function () { var s = {}; pool.forEach(function (p) { var k = p.source || '?'; s[k] = (s[k] || 0) + 1; }); return { pool: pool.length, bySource: s }; }, toggle: function () { on ? leave() : enter(); }, isOn: function () { return on; } };

    $(function () {
        if (!fsCan()) $('#fsButton').hide();
        $('#imStyle').val(styleName()).on('change', function () { setStyle(this.value); });
        $('#imTickerCheck').prop('checked', pref('Ticker')).on('change', function () { try { localStorage.setItem('syt_imTicker', this.checked ? '1' : '0'); } catch (e) { } var s = $('#imTicker span')[0]; if (s) tickerLoad(s); });
        $('#imTerrainCheck').prop('checked', pref('Terrain')).on('change', function () { try { localStorage.setItem('syt_imTerrain', this.checked ? '1' : '0'); } catch (e) { } applyTerrain(); });
        $('#imWxCheck').prop('checked', pref('Wx')).on('change', function () { try { localStorage.setItem('syt_imWx', this.checked ? '1' : '0'); } catch (e) { } applySky(); });
        // the photos the player finds for each place also feed the flying walls
        var orig = window.flyInPhotos;
        window.flyInPhotos = function (photos, p, tol) {
            if (typeof orig === 'function') orig(photos, p, tol);
            feed(photos);
        };
        if (readHash()) {
            // opened with #3d in the address: switch the mode on as soon as the track has loaded
            $('#imStyle').val(styleName());
            var tries = 0, wait = setInterval(function () {
                if (++tries > 120) return clearInterval(wait);
                if (window.isTrackLoaded && window.animatedMarker) { clearInterval(wait); enter(); }
            }, 500);
        }
        // mouse wheel and two-finger pinch change the scale (the camera keeps following the vehicle)
        document.addEventListener('wheel', function (e) {
            if (!on || !$(e.target).closest('#imMap, #imCards, #imSky, #imSkyArt, #imFx').length) return;
            e.preventDefault();
            zoomBy(-e.deltaY * 0.0025);
        }, { passive: false });
        var pinch = null;
        document.addEventListener('touchstart', function (e) { if (on && e.touches.length === 2) pinch = Math.hypot(e.touches[0].clientX - e.touches[1].clientX, e.touches[0].clientY - e.touches[1].clientY); }, { passive: true });
        document.addEventListener('touchmove', function (e) {
            if (!on || pinch === null || e.touches.length !== 2) return;
            var d = Math.hypot(e.touches[0].clientX - e.touches[1].clientX, e.touches[0].clientY - e.touches[1].clientY);
            if (pinch > 0 && d > 0) zoomBy(Math.log2(d / pinch));
            pinch = d; e.preventDefault();
        }, { passive: false });
        document.addEventListener('touchend', function () { pinch = null; }, { passive: true });
        // Esc never leaves the 3D mode (the 3D button does): it only closes what is open on top (photo, menu, settings), which the other handlers do themselves

    });
})();
