// Position slider: shows where the vehicle is on the route and lets the visitor move to any position (normal and 3D view).
(function () {
    var cum = null, total = 0, trackRef = null, dragging = false, wasPlaying = false, lastSeek = 0, $bar = null, $in = null, $lab = null;

    function lengths() {
        var am = window.animatedMarker, data = am && am._latlngs;
        if (!data || data.length < 2) return false;
        if (trackRef === data && cum) return true;
        cum = [0];
        for (var i = 1; i < data.length; i++) cum.push(cum[i - 1] + data[i - 1].distanceTo(data[i]));
        total = cum[cum.length - 1]; trackRef = data;
        return total > 0;
    }
    function indexAt(d) {              // the first point at or after the distance d
        var lo = 0, hi = cum.length - 1;
        while (lo < hi) { var mid = (lo + hi) >> 1; if (cum[mid] < d) lo = mid + 1; else hi = mid; }
        return lo;
    }
    function current() {               // distance travelled by the vehicle now (m)
        var am = window.animatedMarker, i = am._i || 0;
        if (i <= 0) return 0;
        i = Math.min(i, cum.length - 1);
        var a = cum[i - 1], b = cum[i], s = am._seg, f = 0;
        if (s && s.dur > 0 && s.from === am._latlngs[i - 1]) f = Math.max(0, Math.min(1, (Date.now() - s.start) / s.dur));
        else {   // standing (paused, or just moved by the slider): where on the segment is the marker?
            var seg = am._latlngs[i - 1].distanceTo(am._latlngs[i]);
            f = seg > 0 ? Math.max(0, Math.min(1, am._latlngs[i - 1].distanceTo(am.getLatLng()) / seg)) : 0;
        }
        return a + (b - a) * f;
    }
    function km(m) { return (m / 1000).toFixed(m < 10000 ? 1 : 0); }

    function seekTo(d, resume) {
        var am = window.animatedMarker; if (!am || !lengths()) return;
        var k = Math.max(1, Math.min(cum.length - 1, indexAt(d)));
        am.stop(); am._seg = null;
        am._i = k;
        am._setTransition('');
        var p = am._latlngs[k - 1], q = am._latlngs[k], span = cum[k] - cum[k - 1] || 1, f = Math.max(0, Math.min(1, (d - cum[k - 1]) / span));
        am.setLatLng(L.latLng(p.lat + (q.lat - p.lat) * f, p.lng + (q.lng - p.lng) * f));
        var here = am.getLatLng();
        try { if (window.map && (typeof followsTrack !== 'function' || followsTrack())) map.setView(here, map.getZoom(), { animate: false }); } catch (e) { }
        try { if (window.flyIn && flyIn.clear) flyIn.clear(); showPhotos(window.track, here); } catch (e) { }
        if (resume) am.startagain();
    }

    function build() {
        if ($bar) return;
        $bar = $('<div id="sytSeek" title="Position on the route"><input type="range" min="0" max="1000" value="0" step="1" aria-label="Position on the route"/><div class="ticks"></div><span class="lab"></span></div>').appendTo('body');
        $in = $bar.find('input'); $lab = $bar.find('.lab');
        $in.on('input', function () {
            if (!lengths()) return;
            var d = this.value / 1000 * total;
            $lab.text(km(d) + ' / ' + km(total) + ' km');
            if (Date.now() - lastSeek > 120) { lastSeek = Date.now(); seekTo(d, false); }
        });
        $in.on('pointerdown keydown', function () {
            if (dragging) return;
            dragging = true; wasPlaying = (typeof isTrackPaused !== 'undefined') && !isTrackPaused;
        });
        $in.on('change pointerup keyup blur', function () {
            if (!dragging) return;
            dragging = false;
            if (lengths()) seekTo(this.value / 1000 * total, wasPlaying);
        });
        // a mark for every point of the route that has a text
        if (lengths()) {
            var $t = $bar.find('.ticks'), pts = (window.track && track.trackData) || [], data = window.animatedMarker._latlngs;
            for (var i = 0; i < data.length; i++) if (data[i].syt_text) $('<i>').css('left', (cum[i] / total * 100) + '%').attr('title', String(data[i].syt_text).slice(0, 80)).appendTo($t);
        }
    }

    setInterval(function () {
        if (!window.isTrackLoaded || !window.animatedMarker) { if ($bar) $bar.hide(); return; }
        if (!lengths()) return;
        build(); $bar.show();
        if (!dragging) {
            var d = current();
            $in.val(Math.round(d / total * 1000));
            $lab.text(km(d) + ' / ' + km(total) + ' km');
        }
    }, 250);
})();
