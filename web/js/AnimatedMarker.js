/*
 * L.AnimatedMarker is used to display animated icons on the map.
 */

L.AnimatedMarker = L.Marker.extend({
    options: {
        // meters
        distance: 400,
        // ms
        interval: 2000,
        // animate on add?
        autoStart: true,
        // callback onend
        onEnd: function () {
        },
        onStep: function (p) {
        },
        clickable: false
    },
    useTransition: true,
    initialize: function (latlngs, options) {
        if (this.useTransition && L.DomUtil.TRANSITION) {
            // No need to to check up the line if we can animate using CSS3
            this._latlngs = latlngs;
        } else {
            // Chunk up the lines into options.distance bits
            this._latlngs = this._chunk(latlngs);
            this.options.distance = 10;
            this.options.interval = 30;
        }

        L.Marker.prototype.initialize.call(this, latlngs[0], options);
    },

    // Breaks the line up into tiny chunks (see options) ONLY if CSS3 animations
    // are not supported.
    _chunk: function (latlngs) {
        var i,
            len = latlngs.length,
            chunkedLatLngs = [];

        for (i = 1; i < len; i++) {
            var cur = latlngs[i - 1],
                next = latlngs[i],
                dist = cur.distanceTo(next),
                factor = this.options.distance / dist,
                dLat = factor * (next.lat - cur.lat),
                dLng = factor * (next.lng - cur.lng);

            if (dist > this.options.distance) {
                while (dist > this.options.distance) {
                    cur = new L.LatLng(cur.lat + dLat, cur.lng + dLng);
                    dist = cur.distanceTo(next);
                    chunkedLatLngs.push(cur);
                }
            } else {
                chunkedLatLngs.push(cur);
            }
        }

        return chunkedLatLngs;
    },

    onAdd: function (map) {
        L.Marker.prototype.onAdd.call(this, map);
        var self = this;

        // Zoom animation resets marker positions: drop the (possibly very long) transition while zooming,
        // then put the marker where it really is and carry on towards the next vertex.
        map.on('zoomstart', function () {
            if (self._seg) self._setTransition('');
        });
        map.on('zoomend', function () {
            if (self._seg) self.changeSpeed();
        });

        // A resize (or coming back to the tab) can leave the icon standing where its CSS transition was interrupted
        // until the next vertex: put it where it really is and carry on.
        var resync = function () {
            clearTimeout(self._resyncTid);
            self._resyncTid = setTimeout(function () { if (self._seg && self._tid && self._icon) self.changeSpeed(); }, 120);
        };
        map.on('resize moveend', resync);
        document.addEventListener('visibilitychange', function () { if (!document.hidden) resync(); });

        // Start animating when added to the map
        if (this.options.autoStart) {
            this.start();
        }
    },

    resetAM: function () {
        this._i = 0;

        var t = this._latlngs[0];
        if (this.useTransition && L.DomUtil.TRANSITION) {
            if (this._icon) {
                this._icon.style[L.DomUtil.TRANSITION] = '';
            }
            if (this._shadow) {
                this._shadow.style[L.DomUtil.TRANSITION] = '';
            }
        }
        this.setLatLng(t);
    },

    isFinished: function () {
        return (this._i === this._latlngs.length);
    },

    animate: function () {
        var self = this,
            len = this._latlngs.length,
            speed = this.options.interval;

        // Normalize the transition speed from vertex to vertex
        if (this._i < len) {
            if (this._i > 0) {
                speed = this._latlngs[this._i - 1].distanceTo(this._latlngs[this._i]) / this.options.distance * this.options.interval;
            }
            else {
                speed = this._latlngs[this._i + 1].distanceTo(this._latlngs[this._i]) / this.options.distance * this.options.interval;
            }
        }

        // Only if CSS3 transitions are supported
        if (this.useTransition && L.DomUtil.TRANSITION) {
            if (this._icon) {
                this._icon.style[L.DomUtil.TRANSITION] = ('all ' + speed + 'ms linear');
            }
            if (this._shadow) {
                this._shadow.style[L.DomUtil.TRANSITION] = 'all ' + speed + 'ms linear';
            }
        }

        // Remember the segment being travelled, so the speed can be changed mid-way (see changeSpeed)
        var segFrom = (this._i > 0) ? this._latlngs[this._i - 1] : this._latlngs[this._i];
        this._seg = { from: segFrom, to: this._latlngs[this._i], start: new Date().getTime(), dur: speed };

        // Move to the next vertex
        var t = this._latlngs[this._i];
        this.setLatLng(t);
        this._i++;

        // Fire onStep if requested
        if (self.options.onStep)
            setTimeout(function () {
                self.options.onStep(t);
            }, 1);

        // Queue up the animation to the next vertex
        this._tid = setTimeout(function () { self._next(); }, speed);
    },

    _next: function () {
        this._seg = null;
        if (this._i === this._latlngs.length) {
            this.options.onEnd.apply(this, []);
        } else {
            this.animate();
        }
    },

    _setTransition: function (v) {
        if (this._icon) this._icon.style[L.DomUtil.TRANSITION] = v;
        if (this._shadow) this._shadow.style[L.DomUtil.TRANSITION] = v;
    },

    // Apply a new options.distance (metres per interval) right away, also in the middle of a segment,
    // and re-sync the marker with its real position (used after speed changes and zooming)
    changeSpeed: function () {
        var seg = this._seg;
        if (!seg || !(this.useTransition && L.DomUtil.TRANSITION)) return;
        var self = this, running = !!this._tid;
        clearTimeout(this._tid);

        var f = Math.min(1, Math.max(0, (new Date().getTime() - seg.start) / seg.dur));
        if (!(seg.dur > 0)) f = 1;
        var cur = new L.LatLng(seg.from.lat + f * (seg.to.lat - seg.from.lat), seg.from.lng + f * (seg.to.lng - seg.from.lng));
        var dur = cur.distanceTo(seg.to) / this.options.distance * this.options.interval;

        // jump to where the marker is now, then continue to the vertex at the new speed
        this._setTransition('');
        this.setLatLng(cur);
        if (!running) return;
        this._seg = { from: cur, to: seg.to, start: new Date().getTime() + 30, dur: dur };
        this._tid = setTimeout(function () {
            self._setTransition('all ' + dur + 'ms linear');
            self.setLatLng(seg.to);
            self._seg.start = new Date().getTime();
            self._tid = setTimeout(function () { self._next(); }, dur);
        }, 30);
    },

    // Start the animation
    start: function () {
        if (!this._i) {
            this._i = 1;
        }
        else {
            this.resetAM();
        }

        this.startagain();
    },

    // Continue the animation
    startagain: function () {
        //if (this.isFinished()) {
        //    this.initialize();
        //}
        if (!this._i) {
            this._i = 1;
        }

        var self = this;
        setTimeout(function () {
            self.animate();
        }, 10);
    },

    // Stop the animation in place
    stop: function () {
        if (this._tid) {
            clearTimeout(this._tid);
            this._tid = null;
        }
    }
});

L.animatedMarker = function (latlngs, options) {
    return new L.AnimatedMarker(latlngs, options);
};