// Record a route with the phone's (or computer's) location while this page is open, then save it as a track in the editor.
//   sytRecorder.toggle()  - start recording (or stop it, when running)
// Needs: HTTPS (the app is), the browser's location permission, and the page kept open with the screen on
// (a screen wake lock is requested where the browser supports it). The points are also kept in localStorage,
// so a closed or reloaded page can continue the recording.
(function () {
    'use strict';
    var KEY = 'sytRecording', DONE = 'sytRecorded';
    var MIN_MOVE_M = 10, MAX_ACCURACY_M = 60;
    var watchId = null, wake = null, st = null, line = null, me = null, tick = null, $bar = null;

    function t(key, def) { return (window.T ? window.T(key, def) : def); }
    function load(k) { try { return JSON.parse(localStorage.getItem(k)); } catch (e) { return null; } }
    function store(k, v) { try { v === null ? localStorage.removeItem(k) : localStorage.setItem(k, JSON.stringify(v)); } catch (e) { } }

    function meters(a, b) {
        var R = 6371000, r = Math.PI / 180, dLat = (b[0] - a[0]) * r, dLng = (b[1] - a[1]) * r;
        var h = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(a[0] * r) * Math.cos(b[0] * r) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return 2 * R * Math.asin(Math.min(1, Math.sqrt(h)));
    }
    function elapsedMs() { return st ? st.activeMs + (st.paused ? 0 : Date.now() - st.since) : 0; }
    function fmtTime(ms) { var s = Math.floor(ms / 1000), h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60); s = s % 60; return (h ? h + ':' : '') + (h && m < 10 ? '0' : '') + m + ':' + (s < 10 ? '0' : '') + s; }
    function fmtDist(m) { return m < 1000 ? Math.round(m) + ' ' + t('UnitM', 'm') : (m / 1000).toFixed(2) + ' ' + t('UnitKm', 'km'); }

    // ---------- the recording bar
    function ensureBar() {
        if ($bar) return $bar;
        $bar = $('<div id="recBar" role="status"><span class="rec-dot"></span><span class="rec-info"></span>' +
            '<button type="button" class="rec-pause"></button><button type="button" class="rec-stop"></button><button type="button" class="rec-discard" title=""></button>' +
            '<div class="rec-note"></div></div>').appendTo('body');
        $bar.find('.rec-pause').on('click', function () { setPaused(!st.paused); });
        $bar.find('.rec-stop').on('click', stopAndSave);
        $bar.find('.rec-discard').on('click', function () { if (confirm(t('RecDiscardConfirm', 'Discard this recording?'))) discard(); });
        return $bar;
    }
    function render() {
        if (!st || !$bar) return;
        $bar.toggleClass('paused', st.paused);
        $bar.find('.rec-info').text(fmtTime(elapsedMs()) + ' · ' + fmtDist(st.meters) + ' · ' + st.points.length + ' ' + t('RecPoints', 'points'));
        $bar.find('.rec-pause').text(st.paused ? t('RecResume', 'Resume') : t('Pause', 'Pause'));
        $bar.find('.rec-stop').text(t('RecStop', 'Stop and save'));
        $bar.find('.rec-discard').text('×').attr('title', t('RecDiscard', 'Discard'));
        $bar.find('.rec-note').text(t('RecKeepOpen', 'Keep this page open and the screen on while recording.'));
    }

    // ---------- map
    function draw() {
        if (typeof map === 'undefined' || !st) return;
        var ll = st.points.map(function (p) { return [p[0], p[1]]; });
        if (!line) line = L.polyline(ll, { color: '#e53935', weight: 5, opacity: .9 }).addTo(map); else line.setLatLngs(ll);
        if (ll.length) {
            var last = ll[ll.length - 1];
            if (!me) me = L.circleMarker(last, { radius: 8, color: '#fff', weight: 3, fillColor: '#e53935', fillOpacity: 1 }).addTo(map); else me.setLatLng(last);
            if (!map.getBounds().pad(-0.25).contains(last)) map.panTo(last);
        }
    }

    // ---------- location
    function onPos(pos) {
        if (!st || st.paused) return;
        var c = pos.coords, p = [+c.latitude.toFixed(6), +c.longitude.toFixed(6)];
        if (c.accuracy && c.accuracy > MAX_ACCURACY_M) return;                         // too imprecise
        var last = st.points.length ? st.points[st.points.length - 1] : null;
        if (last) {
            var d = meters(last, p);
            if (d < Math.max(MIN_MOVE_M, (c.accuracy || 0) * 0.5)) return;             // standing still / jitter
            st.meters += d;
        }
        st.points.push(p);
        store(KEY, st);
        draw(); render();
    }
    function onErr(err) {
        if (err.code === 1) { toastr.error(t('RecDenied', 'Location permission was denied. Allow it in the browser settings to record a route.')); discard(); }
        else toastr.warning(t('RecNoSignal', 'No location signal yet. Recording continues when it returns.'));
    }
    function keepAwake() {
        if (!('wakeLock' in navigator) || !st || st.paused) return;
        navigator.wakeLock.request('screen').then(function (l) { wake = l; l.addEventListener('release', function () { wake = null; }); }).catch(function () { });
    }
    document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'visible' && st && !wake) keepAwake(); });

    function begin(state) {
        st = state;
        ensureBar(); render(); $bar.addClass('on');
        watchId = navigator.geolocation.watchPosition(onPos, onErr, { enableHighAccuracy: true, maximumAge: 2000, timeout: 30000 });
        keepAwake(); draw();
        tick = setInterval(render, 1000);
        $('#recordButton').addClass('active');
    }
    function setPaused(p) {
        if (!st) return;
        if (p) { st.activeMs += Date.now() - st.since; if (wake) { try { wake.release(); } catch (e) { } } }
        else { st.since = Date.now(); keepAwake(); }
        st.paused = p; store(KEY, st); render();
    }
    function end() {
        if (watchId !== null) navigator.geolocation.clearWatch(watchId);
        watchId = null; clearInterval(tick);
        if (wake) { try { wake.release(); } catch (e) { } wake = null; }
        if (line && typeof map !== 'undefined') map.removeLayer(line);
        if (me && typeof map !== 'undefined') map.removeLayer(me);
        line = me = null;
        if ($bar) $bar.removeClass('on');
        $('#recordButton').removeClass('active');
    }
    function discard() { end(); st = null; store(KEY, null); }
    function stopAndSave() {
        if (!st) return;
        if (st.points.length < 2) { toastr.warning(t('RecTooShort', 'Not enough points yet: move a little and try again.')); return; }
        if (!st.paused) { st.activeMs += Date.now() - st.since; }
        var result = { points: st.points, meters: st.meters, activeMs: st.activeMs, startedAt: st.startedAt };
        end(); st = null; store(KEY, null); store(DONE, result);
        window.location = 'editor.aspx?recorded=1';
    }

    function start() {
        if (!navigator.geolocation) { toastr.error(t('RecUnsupported', 'This browser cannot read your location.')); return; }
        var old = load(KEY);
        if (old && old.points && old.points.length &&
            confirm(t('RecResumePrompt', 'A recording from {0} was not finished. Continue it?').replace('{0}', new Date(old.startedAt).toLocaleString()))) {
            old.paused = false; old.since = Date.now(); begin(old); return;
        }
        begin({ startedAt: Date.now(), since: Date.now(), activeMs: 0, paused: false, meters: 0, points: [] });
        toastr.info(t('RecStarted', 'Recording started. Walk, ride or drive: the route is drawn as you go.'));
    }
    function toggle() { if (st) { if (confirm(t('RecStopConfirm', 'Stop the recording and save the route?'))) stopAndSave(); } else start(); }

    window.sytRecorder = { toggle: toggle, isRecording: function () { return !!st; }, _state: function () { return st; }, _done: function () { return load(DONE); }, clearDone: function () { store(DONE, null); } };

    // a recording that was interrupted (page closed, phone locked): offer to continue it
    $(function () {
        var old = load(KEY);
        if (old && old.points && old.points.length > 1 && !window.__sytNoResume) {
            setTimeout(function () { if (!st && confirm(t('RecResumePrompt', 'A recording from {0} was not finished. Continue it?').replace('{0}', new Date(old.startedAt).toLocaleString()))) { old.paused = false; old.since = Date.now(); begin(old); } }, 1500);
        }
    });
})();
