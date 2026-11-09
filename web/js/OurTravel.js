
//#region Variables
var ATTRIBUTION = 'SeeYourTravel.app &copy; Map data &copy; <a target="_blank" href= "http://openstreetmap.org" > OpenStreetMap</a >, <a target="_blank" href= "http://creativecommons.org/licenses/by-sa/2.0/" > CC - BY - SA</a >, Imagery © <a target="_blank" href= "http://flickr.com" > Flickr</a>; Powered by <a target="_blank" href="https://darksky.net/poweredby/">DarkSky</a> <img src="img/poweredbygoolge/desktop/powered-by-google-on-white.png" />';
var tracksFolder = 'tracks/';
// "Follow the track" (Settings): the map moves along with the marker; dragging the map yourself pauses it for 10 seconds
var followPausedUntil = 0;
function followsTrack() { return $('#followCheckBox').is(':checked') && Date.now() > followPausedUntil; }
// Zoom a track is opened at: a track that fits the screen is shown whole; a longer one starts close enough for the
// marker to be followed, the closer the slower its means of transport.
var FOLLOW_ZOOM = { WalkingMan: 15, Bike: 14, Car: 11, Bus: 11, Yacht: 10, Plane: 6 };
function setInitialTrackView(t) {
    var pts = t.trackData, start = pts[0];
    var bounds = L.latLngBounds(pts);
    var how = t.travelWith || TRANSPORT_BY_ICON[t.icon] || 'Car';
    var followZoom = FOLLOW_ZOOM[how] || 11;
    // leave room for the photo strip at the bottom and the menus on top
    var stripH = $('#imageDiv0').is(':visible') ? $('#imageDiv0').outerHeight() || 0 : 0;
    var padTL = L.point(30, 60), padBR = L.point(30, 30 + stripH);
    var fit = map.getBoundsZoom(bounds, false, padTL.add(padBR));
    if (!isFinite(fit)) fit = followZoom;
    if (fit >= followZoom || !followsTrack()) {
        // the whole track fits (or following is off, so the whole track is the useful view)
        map.fitBounds(bounds, { paddingTopLeft: padTL, paddingBottomRight: padBR, maxZoom: Math.max(followZoom + 2, 16), animate: false });
        if (map.getZoom() < 3) map.setZoom(3, { animate: false });
    } else {
        map.setView(start, followZoom, { animate: false });
    }
}

function followChanged() {
    SaveSettings();
    followPausedUntil = 0;
    if ($('#followCheckBox').is(':checked') && typeof animatedMarker != 'undefined' && animatedMarker && typeof map != 'undefined')
        map.panTo(animatedMarker.getLatLng());   // pick up the marker right away
}
// Small screens (phones): fewer, smaller and more strongly grouped markers, smaller photo cards
function isCompact() { return window.innerWidth < 700 || window.innerHeight < 520; }
if (document.documentElement) document.documentElement.classList.toggle('compact', isCompact());
// translated text with the English text as the fallback (a missing key shows the English text)
function T(key, def, opts) { return (window.$ && $.t) ? $.t(key, $.extend({ defaultValue: def }, opts || {})) : def; }
//        var url = 'http://{s}.tile.cloudmade.com/5bcd2fc5d5714bd48096c7478324e0fe/997/256/{z}/{x}/{y}.png';
//        var url = 'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibWFwYm94IiwiYSI6IjZjNmRjNzk3ZmE2MTcwOTEwMGY0MzU3YjUzOWFmNWZhIn0.Y8bhBaUMqFiPrDRW9hieoQ';      
var mapTileUrl = 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token=pk.eyJ1Ijoib2x0dXJ1YSIsImEiOiJlODQ4ZTI2MWI4OGZkZjUyNDRiNjY4MDFkZGI0ODc4NyJ9.iiCb_tZgs_ipvEv3s6Zx0A';
//var panoramioUrl = "https://ssl.panoramio.com/map/get_panoramas.php?set=";
var flickrUrl = "https://api.flickr.com/services/rest/?method=flickr.photos.search&bbox={0}%2C{1}%2C{2}%2C{3}&per_page={4}&format=json&nojsoncallback=1&api_key=2203a1e292f7b65958730b236c0756fa";

var MAX_GOOGLE_PLACES = IS_MOBILE_LIGHTWEIGHT ? 3 : 5;
var STEPS_PER_PIECE = IS_MOBILE_LIGHTWEIGHT ? 10 : 20;
var PIECES_COUNT = IS_MOBILE_LIGHTWEIGHT ? 5 : 5;
var MAX_HERE_PLACES = 50;
var MAX_GOOGLE_RADIUS = 10000;
var GOOGLE_TYPES = ['lodging', 'restaurant', 'museum', 'park', 'bakery', 'zoo']
var sidePanelWidth = 200;
var cacheImages = false;
var updateIntervalSeconds = 5;

var scrollerEnabled = false;
var scroller;
var scrollerContent;
var curX;
var fullW;
// the page was opened for a specific track: don't jump to the current location or show a placeholder view first
var trackRequested = /[?&](trackname|trackid)=[^&]/i.test(location.search);
var viewportW;
var myBarChart = null;

var versionUrl = "services/get_version.aspx";

// a label instead of the old picture: the words are translated ("i" + data-i18n is picked up by every $(".i").i18n())
var iconWhereIAm = L.divIcon({
    className: 'youHere',
    html: '<span class="yhBox i" data-i18n="YouAreHere">You are here</span>',
    iconSize: [90, 40],
    iconAnchor: [45, 40]
});

var iconFriend = L.icon({
    iconUrl: ("img/friendlocation.png"),
    iconSize: [30, 30],
    iconAnchor: [15, 30],
    //shadowUrl: null
});
//#endregion


// #region Utils
function pointToLatLng(point) {
    var result;
    if (point.hasOwnProperty("lat")) {
        result = new L.LatLng(point.lat, point.lng);
        if (point.hasOwnProperty("syt_text")) {
            result["syt_text"] = point["syt_text"];
        }
        if (point.hasOwnProperty("syt_audio")) {
            result["syt_audio"] = point["syt_audio"];
        }
        return result;
    }
    else {
        var lat = point[0];
        var lng = point[1];
        result = new L.LatLng(lat, lng);
        if (point.length > 2) {
            result["syt_text"] = point[2];
            if (point.length > 3) {
                result["syt_audio"] = point[3];
            }
        }
        return result;
    }
}

function translateTracksPath(path) {
    return tracksFolder + path;
}

function translateTracksContentPath(path) {
    return tracksFolder + "content/" + path;
}
//#endregion

// "Ready gate": the vehicle starts only when the first places (markers) and the first photos are shown, or after a short
// wait at most - so the first stretch of the journey is not empty. A small notice with a "Start now" link shows meanwhile.
var SYT_GATE_MAX_MS = 3500;
window.sytGate = { places: false, photos: false, done: true };
function loadTrackOnPageLoad() {
    var g = window.sytGate = { places: false, photos: false, done: false };
    init(trackParam,
        function () {
            var $note = $('<div id="trackLoading" class="gate"><span class="spin"></span><span class="txt i" data-i18n="PreparingJourney">Preparing your journey\u2026</span><a href="#" class="skip i" data-i18n="StartNow">Start now</a></div>').appendTo('body');
            if ($.fn.i18n) $note.find('.i').i18n();
            var go = function () {
                if (g.done) return;
                g.done = true;
                clearInterval(poll); clearTimeout(cap);
                $note.fadeOut(200, function () { $note.remove(); });
                toastr.warning("Let's go!", "", { timeOut: 2000, extendedTimeOut: 3000 });
                setTimeout(doStartStop, 500);
            };
            var poll = setInterval(function () { if (g.places && g.photos) go(); }, 150);
            var cap = setTimeout(go, SYT_GATE_MAX_MS);
            $note.find('.skip').on('click', function (e) { e.preventDefault(); go(); });
        });
}
function showHelpPanel(show) {
    if (show) {
        $(".fb-comments").attr("data-width", !getIsMobile() ? 400 : getScreenWidth() - 80);
        if (track) {
            var elevator = new google.maps.ElevationService;
            elevator.getElevationAlongPath({
                'path': compactTrackData(track.trackData),
                'samples': 128
            }, plotElevation);
        }
        updateTrackStats();
        $('#helpPanel').show('slide', { direction: "left" }, 500);
    }
    else {
        clearElevation();
        myBarChart = null;
        $("#helpPanel").hide('slide', { direction: "right" }, 500);
    }
}

//#region Handlers
function clickHelp() {
    $("#menuPanel").hide('slide', 500);
    showHelpPanel(!$("#helpPanel").is(":visible"));
}
function clickSettings() {
    $("#menuPanel").hide('slide', 500);
    $('#settingsPanel').show('slide', { direction: "up" }, 500);
}
function clickMenu() {
    showHelpPanel(false);
    $('#settingsPanel').hide('slide', { direction: "up" }, 500);
    $('#menuPanel').toggle('slide', 300, function () {
        var open = $('#menuPanel').is(':visible');
        $('#alogo').attr('aria-expanded', open ? 'true' : 'false');
        $('#searchAiHint').toggle(!!window.sytSignedIn);
        if (open) $('#menuPanel').find('input, button:not(:disabled), a').first().focus();
    });
}
// Esc closes the menu and the settings (the usual way out of a drawer or a dialog)
$(document).on('keydown', function (e) {
    if (e.key !== 'Escape') return;
    if ($('#menuPanel').is(':visible')) { $('#menuPanel').hide('slide', 200); $('#alogo').attr('aria-expanded', 'false').focus(); }
    if ($('#settingsPanel').is(':visible')) $('#settingsPanel').hide('slide', { direction: 'up' }, 200);
});

// Place search of the menu. An address or a place name goes to the geocoder; a sentence ("castles in Scotland"), or a place the geocoder does not know, goes to the AI assistant
// (signed-in people): it moves the map and can list tracks there.
function search($input) {
    var q = $.trim($input.val());
    try { if (window.event && window.event.stopPropagation) window.event.stopPropagation(); } catch (e) { }
    if (!q) return;
    var ai = window.sytSignedIn && window.sytChatAsk;
    function askAi() { $('#menuPanel').hide('slide', 200); window.sytChatAsk(q); }
    if (ai && q.split(/\s+/).length >= 4) { askAi(); return; }
    var service = new google.maps.Geocoder();
    service.geocode({ 'address': q }, function (results, status) {
        if (status === 'OK') {
            map.panTo(new L.LatLng(results[0].geometry.location.lat(), results[0].geometry.location.lng()));
        } else if (ai) {
            askAi();
        } else {
            toastr.error(T('PlaceNotFound', 'Place not found') + ' (' + status + ')');
        }
    });
}

function onBodyResize() {
    if ($("#map").length) {
        $("#map").height(window.innerHeight);
    }
    if ($(".viewport").length) {
        $(".viewport").height(window.innerHeight - 150);
    }

    if (typeof (switchSidePanel) != "undefined") {
        if (window.innerWidth < 800 || showSidePanel == "no") {
            switchSidePanel(false);
        }
        else {
            switchSidePanel(true);
        }
    }
}

//#endregion

var locationTimer = null;
function showLocation() {
    if (locationTimer) return;          // already running: one position check per minute is enough
    if (navigator.geolocation) {
        var options = {
            enableHighAccuracy: true,
            timeout: 5000,
            maximumAge: 300000
        };
        navigator.geolocation.getCurrentPosition(showPosition, errorPosition, options);
        locationTimer = setTimeout(function () { locationTimer = null; showLocation(); }, 60000);
    } else {
        console.log("Geolocation is not supported by this browser");
    }
}
function errorPosition(err) {
    console.warn('Cannot get position(' + err.code + '): ' + err.message);
};
var centeredOnMe = false;
var lastSent = { t: 0, pos: null };
var shareLocation = false;   // the user's consent, kept on the server
function showPosition(position) {
    //    console.log("position: " + position.coords.latitude + ", " + position.coords.longitude);
    if ($("#map").length) {
        //x.innerHTML = "Latitude: " + position.coords.latitude +
        //"<br>Longitude: " + position.coords.longitude;
        var newLatLng = new L.LatLng(position.coords.latitude, position.coords.longitude);
        //crd.accuracy
        markerWhereIAm.setLatLng(newLatLng);
        //        markerWhereIAmCircle.setLatLng(newLatLng);
        //        markerWhereIAmCircle.setRadius(position.coord.accuracy);

        // go to the user's position once (the fix is repeated every minute and must not undo where the user has moved the map to);
        // pages that keep their own view (My photos) set keepMapView
        if (typeof track == "undefined" && !trackRequested && !centeredOnMe && !window.keepMapView)
            map.setView(newLatLng, 8);
        centeredOnMe = true;

        //console.log(window.navigator.standalone);
        // only signed-in users share their position, and only if it changed or a minute passed (guests: nothing is sent)
        var now = Date.now();
        var moved = !lastSent.pos || lastSent.pos.distanceTo(newLatLng) > 30;
        if (!globalUserId || !shareLocation || (!moved && now - lastSent.t < 60000)) return;
        lastSent = { t: now, pos: newLatLng };
        var urlp = "services/user_locations.aspx?action=senduserlocation&source=2&userId=" + globalUserId + "&lat=" + position.coords.latitude.toString() + "&lng=" + position.coords.longitude.toString()
        $.ajax({
            dataType: "jsonp",
            url: urlp,
            success: function (data) {
            },
            error: function (XMLHttpRequest, textStatus, errorThrown) {
                console.log("senduserlocation error status: " + textStatus); console.log("Error: " + errorThrown);
            }
        });

        var urlp = "services/user_locations.aspx?action=getfriendslocations&userId=" + globalUserId

        markersFriends.clearLayers();

        $.ajax({
            dataType: "jsonp",
            url: urlp,
            success: function (data) {
                for (var i in data) {
                    var markerFriend = L.marker(new L.LatLng(data[i].lat - 0.0002 + Math.random() * 0.0004, data[i].lng - 0.0002 + Math.random() * 0.0004), { icon: iconFriend }).bindPopup(data[i].userName.concat(", ", data[i].time));
                    markersFriends.addLayer(markerFriend);
                }
            },
            error: function (XMLHttpRequest, textStatus, errorThrown) {
                console.log("getfriendslocations error status: " + textStatus); console.log("Error: " + errorThrown);
            }
        });


    }
}

// Moving speed in km/h (minimum 5), set in Settings (applies immediately).
// The marker advances once per second, so metres per step = km/h / 3.6.
var MIN_SPEED_KMH = 5;
function getSpeedMps() {
    var v = parseFloat($("#speedSlider").val());
    if (!(v >= MIN_SPEED_KMH)) v = MIN_SPEED_KMH;
    return v / 3.6;
}

function changeSpeed(value) {
    var v = Math.max(MIN_SPEED_KMH, parseFloat(value) || MIN_SPEED_KMH);
    $("#speedSlider").val(v);
    $("#speedValue").text(parseFloat($("#speedSlider").val()) + " km/h");
    if (window.updateTrackStats && $('#helpPanel').is(':visible')) updateTrackStats();
    if (typeof animatedMarker != "undefined")
    {
        animatedMarker.options.distance = getSpeedMps();
        animatedMarker.changeSpeed();
    }
}

// Realistic speeds (km/h) per means of transport ("Travel with" in the editor; older tracks: the vehicle picture saved with them).
var REALISTIC_KMH = { WalkingMan: 5, Bike: 20, Car: 80, Bus: 60, Yacht: 15, Plane: 800 };
var TRANSPORT_BY_ICON = { 'aman.gif': 'WalkingMan', 'man.png': 'WalkingMan', 'mybike.png': 'Bike', 'mycar.png': 'Car', 'mybus.png': 'Bus', 'myyacht.png': 'Yacht', 'myplane.png': 'Plane' };
function realisticKmh(track) { return REALISTIC_KMH[track.travelWith] || REALISTIC_KMH[TRANSPORT_BY_ICON[track.icon]] || 0; }
function trackOwnKmh(track) { return Math.round(track.velocityMetersPerSec * 3.6 / 5) * 5; }

// When a track is loaded: with "Realistic speed" ticked in Settings the speed is the realistic one for its means of transport;
// otherwise the speed saved in Settings, or - without one - the track's own (time-lapse) speed.
function applyDefaultSpeed(track) {
    if ($("#realisticSpeedCheckBox").is(":checked") && realisticKmh(track)) { changeSpeed(realisticKmh(track)); return; }
    if (parseFloat($.cookie("settings_speedKmh")) >= MIN_SPEED_KMH) return;
    changeSpeed(trackOwnKmh(track));
}

// Ticking / unticking the box takes effect at once for the loaded track
function onRealisticSpeedChange() {
    $.cookie("settings_realisticSpeed", $("#realisticSpeedCheckBox").is(":checked"), { expires: 365 });
    if (typeof track != "undefined" && track && isTrackLoaded) {
        if ($("#realisticSpeedCheckBox").is(":checked") && realisticKmh(track)) changeSpeed(realisticKmh(track));
        else changeSpeed(trackOwnKmh(track));
        SaveSettings();
    }
}

function SaveSettings() {
    $.cookie("settings_speedKmh", $("#speedSlider").val());
    $.cookie("settings_scriptTextCheckBox", $("#scriptTextCheckBox").is(':checked'));
    $.cookie("settings_imagesCheckBox", $("#imagesCheckBox").is(':checked'));
    $.cookie("settings_loopTrackCheckBox", $("#loopTrackCheckBox").is(':checked'));
    $.cookie("settings_useFlickrImagesCheckBox", $("#useFlickrImagesCheckBox").is(':checked'));
    $.cookie("settings_useSYTImagesCheckBox", $("#useSYTImagesCheckBox").is(':checked'));
    $.cookie("settings_useGooglePlacesCheckBox", $("#useGooglePlacesCheckBox").is(':checked'));
    $.cookie("settings_useSYTPlacesCheckBox", $("#useSYTPlacesCheckBox").is(':checked'));
    $.cookie("settings_flyIn", $("#flyInCheckBox").is(':checked'));
    $.cookie("settings_follow", $("#followCheckBox").is(':checked'));
    $.cookie("settings_realisticSpeed", $("#realisticSpeedCheckBox").is(':checked'));

    $.cookie("settings_mapStyle", $('#mapStyle option:selected').val());
    $.cookie("settings_volume", $('#slider').slider("value"));
    $.cookie("settings_mute", audio.muted);
};

function LoadSettings() {
    var savedSpeed = parseFloat($.cookie("settings_speedKmh"));
    if (savedSpeed >= MIN_SPEED_KMH) {
        $("#speedSlider").val(savedSpeed);
        changeSpeed(savedSpeed);
    }

    if (typeof $.cookie("settings_scriptTextCheckBox") != "undefined") {
        var a = $.cookie("settings_scriptTextCheckBox") == "true";
        var b = $.cookie("settings_imagesCheckBox") == "true";
        var c = $.cookie("settings_mute") == "true";
        var d = $.cookie("settings_loopTrackCheckBox") == "true";
        $("#scriptTextCheckBox").prop("checked", a);
        $("#imagesCheckBox").prop("checked", b);
        $("#loopTrackCheckBox").prop("checked", d);
        $("#useFlickrImagesCheckBox").prop("checked", $.cookie("settings_useFlickrImagesCheckBox") == "true");
        $("#useSYTImagesCheckBox").prop("checked", $.cookie("settings_useSYTImagesCheckBox") == "true");
        $("#useGooglePlacesCheckBox").prop("checked", $.cookie("settings_useGooglePlacesCheckBox") == "true");
        $("#useSYTPlacesCheckBox").prop("checked", $.cookie("settings_useSYTPlacesCheckBox") == "true");
        if (typeof $.cookie("settings_flyIn") != "undefined") $("#flyInCheckBox").prop("checked", $.cookie("settings_flyIn") == "true");
        if (typeof $.cookie("settings_follow") != "undefined") $("#followCheckBox").prop("checked", $.cookie("settings_follow") == "true");   // on by default
        $("#realisticSpeedCheckBox").prop("checked", $.cookie("settings_realisticSpeed") == "true");   // off by default

        // The Description panel is shown/hidden when a track is loaded (see loadTrack).
        if (!b)
            $('#imageDiv0').toggle('fold', 1000);
        if (c)
            clickMute();
    }
    if (typeof $.cookie("settings_mapStyle") != "undefined" && window.SYT_MAP_STYLES[$.cookie("settings_mapStyle")]) {
        $('#mapStyle').val($.cookie("settings_mapStyle"));
        selectMapStyle();
    }
    if (typeof $.cookie("settings_volume") != "undefined") {
        $('#slider').slider("value", $.cookie("settings_volume"));
    }
};

// Browsers block audio.play() until the user interacts with the page; retry on the first interaction.
function safePlayAudio() {
    var promise = audio.play();
    if (promise && promise.catch) {
        promise.then(function () { console.log("Audio playing: " + audio.src); }).catch(function (err) {
            if (err && err.name === "NotAllowedError") {
                toastr.info(T("EnableMusic", "Click anywhere on the page to enable the music"), "", { timeOut: 5000 });
                var resume = function () {
                    $(document).off("click keydown touchstart", resume);
                    if (!isTrackPaused && audio.src)
                        audio.play().catch(function () { });
                };
                $(document).on("click keydown touchstart", resume);
            }
            else {
                console.log("Audio error: " + err);
            }
        });
    }
}

function clickMute() {
    if (audio.muted) {
        audio.muted = false;
        $('#mute').css('background-image', 'url(img/unmute.png )');
    }
    else {
        audio.muted = true;
        $('#mute').css('background-image', 'url(img/mute.png )');
    }
}

var isTrackLoaded = false;
var isTrackPaused = !IS_IOS;
$(function () {
    if (IS_IOS) {
        toastr.warning("Please press the Play button to start the track", "", { timeOut: 5000, extendedTimeOut: 10000 });
    }
});


function doStartStop() {
    if (isTrackLoaded) {
        $('#continuePauseButton, #restartButton').removeAttr('disabled');
        if (isTrackPaused) {
            isTrackPaused = !isTrackPaused;
            if (typeof animatedMarker != "undefined")
                animatedMarker.startagain();
            if (track.audioSrc && track.audioSrc.length > 0)
                safePlayAudio();
            scrollerEnabled = true;

            $('#continuePauseButton').css('background-image', 'url(img/pause.png )');
            if ($("#showGoesOn").length > 0)
                $("#showGoesOn").val("1");
        }
        else {
            isTrackPaused = !isTrackPaused;
            if (typeof animatedMarker != "undefined")
                animatedMarker.stop();
            audio.pause();
            scrollerEnabled = false;

            $('#continuePauseButton').css('background-image', 'url(img/play.png )');
            if ($("#showGoesOn").length > 0)
                $("#showGoesOn").val("0");
        }
    }
    else {
        $('#continuePauseButton, #restartButton').attr('disabled', 'disabled');
    }
}

// Start the route again from its first point (also after it was paused or has ended), with music and photos from the beginning.
function restartRoute() {
    if (!isTrackLoaded || typeof animatedMarker == "undefined" || !track)
        return;
    animatedMarker.stop();
    animatedMarker._seg = null;
    animatedMarker.options.distance = getSpeedMps();
    animatedMarker.start();                       // jumps back to the first point and moves on
    isTrackPaused = false;
    scrollerEnabled = true;
    $('#continuePauseButton').css('background-image', 'url(img/pause.png )');
    if ($("#showGoesOn").length > 0)
        $("#showGoesOn").val("1");
    if (track.audioSrc && track.audioSrc.length > 0) {
        audio.currentTime = 0;
        safePlayAudio();
    }
    if (window.flyIn && flyIn.clear) flyIn.clear();   // photos may fly in again
    try { map.setView(track.trackData[0], map.getZoom(), { animate: false }); } catch (e) { }
    if (typeof toastr != "undefined") toastr.info(T("Route restarted", "Route restarted"), "", { timeOut: 1500 });
}

// If a stop has too few photos, widen the search radius (x2 each time, up to MAX_PHOTO_WIDENINGS times).
var MIN_PHOTOS = 15;
var MIN_NAME_PHOTOS = 6;   // below this many photos after widening, search by place name
var MAX_PHOTO_WIDENINGS = 4;

// Photo search with a small cache and look-ahead: the photos for the places the marker will reach in the next
// few seconds are searched (and their first thumbnails preloaded) in advance. Only a few places are kept; older ones,
// and the preloaded images of the current one, are released so memory stays low.
var photoSearch = (function () {
    var MAX_ENTRIES = 4;        // current place + the next ones + one previous
    var PRELOAD_THUMBS = 12;    // thumbnails preloaded per upcoming place (about what is visible in the strip)
    var entries = [];           // least recently used first

    function keyOf(p, tol) {
        return [p.lat.toFixed(3), p.lng.toFixed(3), tol.toFixed(4),
            $('#useFlickrImagesCheckBox').is(':checked'), $('#useSYTImagesCheckBox').is(':checked')].join('|');
    }
    function release(e) {
        for (var i = 0; i < e.imgs.length; i++) { e.imgs[i].onload = e.imgs[i].onerror = null; e.imgs[i].src = ''; }
        e.imgs = [];
    }
    function find(key) {
        for (var i = 0; i < entries.length; i++)
            if (entries[i].key === key) { var e = entries.splice(i, 1)[0]; entries.push(e); return e; }
        return null;
    }
    function create(track, p, tol, low) {
        var key = keyOf(p, tol);
        var e = find(key);
        if (e) {
            if (!low) { syt.api.searchFlickrImages(track, p, tol, false); }   // a prefetched request that is now needed jumps the queue
            return e;
        }
        e = { key: key, imgs: [], released: false };
        e.promise = new Promise(function (resolve) {
            var attempt = function (t, widenings) {
                Promise.all([syt.api.searchSYTImages(track, p, t), syt.api.searchFlickrImages(track, p, t, low && widenings === 0)])
                    .then(function (v) {
                        var photos = v[0].photos.concat(v[1].photos);
                        if (photos.length < MIN_PHOTOS && widenings < MAX_PHOTO_WIDENINGS) attempt(t * 2, widenings + 1);
                        else if (photos.length < MIN_NAME_PHOTOS) {
                            // still (almost) nothing around the point: look for photos of the place by name
                            syt.api.searchPlaceNamePhotos(track, p, low).then(function (byName) {
                                resolve({ photos: arrangePhotos(photos.concat(byName.photos)), tol: t });
                            });
                        }
                        else resolve({ photos: arrangePhotos(photos), tol: t });
                    });
            };
            attempt(tol, 0);
        });
        entries.push(e);
        while (entries.length > MAX_ENTRIES) { var old = entries.shift(); old.released = true; release(old); }
        return e;
    }
    function defaultTol(track, tol) {
        return tol || (track.photoLocationTolerancy / 1000) || 0.1;
    }

    // upcoming positions along the track: where the marker will be after k photo updates
    function upcoming(track, n) {
        if (typeof animatedMarker === 'undefined' || !track || !track.trackData) return [];
        var data = track.trackData, len = data.length, i = Math.max(animatedMarker._i || 0, 0);
        var step = getSpeedMps() * updateIntervalSeconds, need = step, acc = 0, res = [];
        for (var j = i; j < len - 1 && res.length < n; j++) {
            var a = pointToLatLng(data[j]), b = pointToLatLng(data[j + 1]), d = a.distanceTo(b);
            while (d > 0 && acc + d >= need && res.length < n) {
                var f = (need - acc) / d;
                res.push({ lat: a.lat + f * (b.lat - a.lat), lng: a.lng + f * (b.lng - a.lng) });
                need += step;
            }
            acc += d;
        }
        return res;
    }

    return {
        get: function (track, p, tol) {
            tol = defaultTol(track, tol);
            var e = create(track, p, tol, false);
            return e.promise;
        },
        // search + preload the photos of the places ahead (low priority)
        prefetch: function (track) {
            if (document.hidden) return;
            if (navigator.connection && navigator.connection.saveData) return;
            if (navigator.deviceMemory && navigator.deviceMemory < 1) return;
            var tol = defaultTol(track), pts = upcoming(track, 2);
            pts.forEach(function (pt) {
                var e = create(track, pt, tol, true);
                if (e.preloading) return;
                e.preloading = true;
                e.promise.then(function (r) {
                    if (e.released) return;
                    var list = r.photos.slice(0, PRELOAD_THUMBS);
                    for (var k = 0; k < list.length; k++) {
                        var im = new Image();
                        im.decoding = 'async';
                        im.src = list[k].photo_file_url;
                        e.imgs.push(im);
                    }
                });
            });
        },
        // the strip now shows this place: its preloaded copies are no longer needed
        shown: function (track, p, tol) {
            var e = find(keyOf(p, defaultTol(track, tol)));
            if (e) release(e);
        },
        clear: function () { entries.forEach(release); entries = []; },
        stats: function () { return { entries: entries.length, preloaded: entries.reduce(function (n, e) { return n + e.imgs.length; }, 0) }; }
    };
})();

function showPhotos(track, p, tolerancy) {
    photoSearch.get(track, p, tolerancy).then(function (r) {
        get_photos_success(r.photos, p, r.tol);
        photoSearch.shown(track, p, tolerancy);
        setTimeout(function () { photoSearch.prefetch(track); }, 1500);   // after the current photos have been requested
    });
}

// ---- Photo strip -------------------------------------------------------------------------------
var MAX_STRIP_PHOTOS = 30;
var stripPhotos = [];   // the photos currently shown, in strip order (used by the viewer)

function photoKey(ph) {
    // the same picture can come from two sources; compare by file name
    var t = (ph.source === "commons" ? ph.photo_title : (ph.photo_file_url || "")).toString().toLowerCase();
    return t.replace(/^.*[\/\\]/, "").replace(/\?.*$/, "").replace(/[ _]/g, "");
}

function photoCredit(ph) {
    if (ph.source === "commons") {
        var c = ph.owner_name || "Wikimedia Commons";
        return ph.license ? c + " · " + ph.license : c;
    }
    return $.t("Photo from the SeeYourTravel community");
}

// A "series" = photos that are probably alike: same author and a title that differs only in numbers (e.g. "Split - panoramio (18)")
function seriesKey(ph, i) {
    if (ph.source !== "commons") return "own|" + i;   // own photos are not grouped
    var t = (ph.photo_title || "").toLowerCase().replace(/\.[a-z0-9]+$/, "").replace(/[\d_()\-#\[\]]+/g, " ").replace(/\s+/g, " ").trim();
    return "commons|" + (ph.owner_name || "") + "|" + t.slice(0, 24);
}

var MAX_PER_SERIES = 2;

// Dedupe, pick a varied set and mix it: random order, sources alternate, similar photos are never next to each other.
function arrangePhotos(photos) {
    if (photos.arranged) return photos;
    var seen = {}, list = [];
    for (var i = 0; i < photos.length; i++) {
        var ph = photos[i];
        ph.source = ph.source || "own";
        var k = photoKey(ph);
        if (seen[k]) continue;
        seen[k] = true;
        ph._series = seriesKey(ph, i);
        list.push(ph);
    }
    shuffle(list);
    // varied selection: at most MAX_PER_SERIES photos of one series
    var counts = {}, picked = [];
    for (var j = 0; j < list.length && picked.length < MAX_STRIP_PHOTOS; j++) {
        var s = list[j]._series;
        if ((counts[s] || 0) >= MAX_PER_SERIES) continue;
        counts[s] = (counts[s] || 0) + 1;
        picked.push(list[j]);
    }
    // spread: prefer another source and another series than the previous photo
    var out = [], pool = picked.slice(), last = null;
    while (pool.length) {
        var idx = -1, i2;
        for (i2 = 0; i2 < pool.length && idx < 0; i2++)
            if (!last || (pool[i2].source !== last.source && pool[i2]._series !== last._series)) idx = i2;
        for (i2 = 0; i2 < pool.length && idx < 0; i2++)
            if (!last || pool[i2]._series !== last._series) idx = i2;
        if (idx < 0) idx = 0;
        last = pool.splice(idx, 1)[0];
        out.push(last);
    }
    out.arranged = true;
    return out;
}

// ---- The strip is an endless queue -----------------------------------------------------------------------------
// Photos scroll past from right to left. A new batch of photos is not shown by rebuilding the strip: what is on screen stays,
// the photos that have not come into view yet are replaced by the new ones, the new ones are added behind the visible
// photos, and photos that have scrolled out of sight are removed. When the queue gets short the current photos are queued again.
var stripCycleIdx = 0;      // next photo of stripPhotos to queue again
var stripH = 0;             // height the photos were laid out for
var lastStripTrim = 0;

function stripItems() { return scrollerContent.children('li').get(); }

// one photo as a strip item (not placed yet)
function makeStripItem(ph, i, divHeight) {
    var nextLi = document.createElement("li");
    var nextLink = document.createElement("a");
    var nextImage = document.createElement("img");
    nextLink.href = ph.photo_url;
    nextLink.target = "_blank";
    nextLink.setAttribute("data-index", i);
    nextLink.setAttribute("aria-label", ph.photo_title && ph.photo_title !== "TBD" ? ph.photo_title : "Photo " + (i + 1));

    nextImage.width = ph.width * divHeight / ph.height;
    nextImage.height = divHeight;
    nextImage.alt = ph.photo_title && ph.photo_title !== "TBD" ? ph.photo_title : "";
    nextImage.loading = "lazy";
    if (cacheImages == true) {
        getFromCacheOrServer(ph.photo_file_url, nextImage, function (obj, data) {
            obj.src = data;
        });
    }
    else {
        nextImage.src = ph.photo_file_url;
    }

    nextImage.title = photoCredit(ph);
    nextImage.classList.add("photo");
    nextImage.setAttribute("data-ar", ph.width / ph.height);
    // Own photos: the original file; public photos (Commons): a large version.
    var full = ph.big_url || ph.photo_file_url;
    nextImage.setAttribute("data-full", full);
    nextImage.setAttribute("data-credit", photoCredit(ph));
    nextLink.appendChild(nextImage);
    nextLi.appendChild(nextLink);
    var badge = document.createElement("span");
    var ownPrivate = ph.source === "own" && ph.syt_public === false;   // our own photo that only its owner may see
    badge.className = "photoBadge " + (ph.source === "own" ? (ownPrivate ? "own priv" : "own") : "pub");
    if (ph.source === "own") badge.innerHTML = '<i class="fa fa-map-marker"></i>';     // green pin: public, red pin: private
    else badge.textContent = "🌍";
    badge.title = ph.source === "own" ? (ownPrivate ? T("BadgeOwnPrivate", "Your photo: private, only you can see it") : T("BadgeOwnPublic", "Your photo: public")) : T("BadgePublic", "Public photo (Wikimedia Commons)");
    nextLi.appendChild(badge);
    if (ph.people && ph.people.length) {   // the owner's own photos: who is on it, shown on hover only
        var who = document.createElement("span");
        who.className = "photoWho"; who.textContent = ph.people.join(", ");
        nextLi.appendChild(who);
    }
    nextLi._ph = ph;
    return nextLi;
}

function placeStripItem(li, x, h) {
    var img = li.getElementsByTagName("img")[0];
    var ar = parseFloat(img.getAttribute("data-ar")) || (img.width / img.height) || 1.5;
    var w = Math.round(ar * h);
    img.style.width = w + "px"; img.style.height = h + "px";
    img.width = w; img.height = h;
    li.style.left = x + "px";
    li._left = x; li._w = w;
    return w;
}

// Size every photo to the strip height and place them side by side (cheap: no reloading, used live while resizing).
// The first photo keeps its position, so the part of the strip in view can be kept.
function layoutStrip(h) {
    var items = stripItems(), x = items.length ? (items[0]._left || 0) : 0;
    items.forEach(function (li) { x += placeStripItem(li, x, h); });
    stripH = h;
    curX = x;
    fullW = x;       // "something to scroll" for the code that only needs to know that
}

function stripEnd() {
    var items = stripItems(), last = items[items.length - 1];
    return last ? last._left + last._w : 0;
}

// append photos behind the last one
function appendToStrip(list, h) {
    var ul = scrollerContent[0], x = stripEnd(), first = !stripItems().length;
    list.forEach(function (ph, k) {
        var li = makeStripItem(ph, k, h);
        ul.appendChild(li);
        x += placeStripItem(li, x, h);
    });
    curX = x; fullW = x;
    return first;
}

// keep about two viewport widths of photos in front of the viewer: the queue never runs dry
function ensureStripAhead() {
    if (!stripPhotos.length) return;
    var el = scroller[0], h = stripH || $("#imageDiv").height();
    var need = el.scrollLeft + el.clientWidth * 2, guard = 0, add = [];
    var end = stripEnd();
    while (end < need && guard++ < 60) {
        var ph = stripPhotos[stripCycleIdx++ % stripPhotos.length];
        add.push(ph);
        end += Math.round((ph.width / ph.height) * h);
    }
    if (add.length) appendToStrip(add, h);
}

// remove photos that have scrolled out of sight (a viewport is kept behind, so dragging back still works)
function trimStripPassed() {
    var el = scroller[0], limit = el.scrollLeft - el.clientWidth, items = stripItems(), shift = 0;
    while (items.length > 1 && items[0]._left + items[0]._w < limit) {
        var li = items.shift();
        li.parentNode.removeChild(li);
    }
    // the positions would grow for ever: move everything back to the start now and then
    if (items.length && items[0]._left > 4000) {
        shift = items[0]._left;
        items.forEach(function (li) { li._left -= shift; li.style.left = li._left + "px"; });
        el.scrollLeft = el.scrollLeft - shift;
        stripShifted = shift;
        curX = stripEnd(); fullW = curX;
    }
}
var stripShifted = 0;   // set when the positions were moved, so the scroller code can follow

var lastStripArgs = null;
function get_photos_success(photos, p, tolerancy, force) {
    if (window.sytGate) window.sytGate.photos = true;
    lastStripArgs = { photos: photos, p: p, tol: tolerancy };
    // same place as before (same cached, arranged list): keep the strip as it is - no flicker, no re-download, no DOM rebuild
    if (!force && photos === stripPhotos && scrollerContent.children().length) {
        $("#lblCoord").text(p.lat + " " + p.lng);
        return;
    }
    if (window.hidePhotoPreview) window.hidePhotoPreview();
    var divHeight = $("#imageDiv").height();

    photos = arrangePhotos(photos);
    $("#lblCoord").text(p.lat + " " + p.lng);
    if (window.flyInPhotos) window.flyInPhotos(photos, p, tolerancy);

    var imageUl = imageDiv.children();
    var current = stripItems();

    if (!photos.length && current.length) {
        // nothing new here: the photos on their way keep scrolling
        return;
    }
    stripPhotos = photos;
    count = photos.length;
    stripCycleIdx = 0;
    $("#photoEmpty").remove();

    if (force || !current.length) {
        // first batch (or a re-layout): build the queue from scratch
        imageUl.empty();
        appendToStrip(photos, divHeight);
        stripH = divHeight;
        if (!photos.length) $('<div id="photoEmpty"></div>').text($.t("No photos here yet")).appendTo(scroller);
        viewportW = scroller.width();
        return;
    }

    // a new batch while photos are scrolling: what is in view stays; what has not come into view yet is replaced
    var el = scroller[0], right = el.scrollLeft + el.clientWidth, keep = {};
    current.forEach(function (li) {
        if (li._left > right + 4) li.parentNode.removeChild(li);       // not seen yet: the new batch takes its place
        else keep[photoKey(li._ph)] = true;                            // in view or just passed: do not show it again right away
    });
    appendToStrip(photos.filter(function (ph) { return !keep[photoKey(ph)]; }), divHeight);
    ensureStripAhead();
    viewportW = scroller.width();
}

// the photos of the strip in the order they are queued, each photo once (the viewer pages through these)
function stripViewerList() {
    var seen = {}, list = [];
    stripItems().forEach(function (li) { var k = photoKey(li._ph); if (!seen[k]) { seen[k] = true; list.push(li._ph); } });
    return list;
}

//#region Fly-in photos
// When the marker arrives at a new place, up to three photos that were taken nearby fly out of their exact spot on the map
// into small cards around the marker, stay for a few seconds and shrink back into a round pin on the map.
var flyIn = (function () {
    var MAX_CARDS = 3, HOLD_MS = 6500, MAX_PINS = 60, MIN_GAP_MS = 2500, IDLE_GAP_MS = 15000, SHOWN_TTL_MS = 10 * 60 * 1000;   // a photo may fly in again after 10 minutes
    var layer = null, lastShow = 0, shown = {}, shownOrder = [], pins = [], pinPhotos = [], active = [], current = null;

    function enabled() {
        return $('#flyInCheckBox').is(':checked') && !document.hidden;
    }
    function reduced() { return window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches; }
    function ensureLayer() {
        if (layer) return layer;
        layer = $('<div class="flyLayer"></div>').appendTo(map.getContainer())[0];
        return layer;
    }
    // identity of a picture independent of the thumbnail size/URL it was found with (same file name = same photo)
    function key(ph) { return photoKey(ph); }
    function remember(ph) {
        shown[key(ph)] = Date.now(); shownOrder.push(key(ph));
        while (shownOrder.length > 400) delete shown[shownOrder.shift()];
    }

    function anchors(n, w, h, center) {
        var off = n === 1 ? [[0, -h - 40]] : n === 2 ? [[-w / 2 - 14, -h - 40], [w / 2 + 14, -h - 40]] : [[-w - 24, -h - 20], [0, -h - 60], [w + 24, -h - 20]];
        var c = map.getSize(), out = [];
        // flip below the marker when there is no room above, and keep the cards inside the map
        var flip = center.y + off[0][1] - h / 2 < 60;
        off.forEach(function (o) {
            var x = center.x + o[0], y = center.y + (flip ? -o[1] + h * 0.2 : o[1]);
            out.push({ x: Math.max(w / 2 + 8, Math.min(c.x - w / 2 - 8, x)), y: Math.max(h / 2 + 50, Math.min(c.y - h / 2 - 170, y)) });
        });
        return out;
    }

    function addPin(ph) {
        var thumb = (ph.photo_file_url || '').replace(/"/g, '%22');
        var m = L.marker([ph.latitude, ph.longitude], {
            icon: L.divIcon({ className: 'photoPin', html: '<img src="' + thumb + '" alt="" loading="lazy"/>', iconSize: isCompact() ? [30, 30] : [38, 38], iconAnchor: isCompact() ? [15, 15] : [19, 19] }),
            title: ph.photo_title && ph.photo_title !== 'TBD' ? ph.photo_title : '', thumb: ph.photo_file_url
        });
        var idx = pinPhotos.push(ph) - 1;
        m.on('click', function () { photoViewer.open(idx, pinPhotos); });
        placeCluster.addLayer(m);
        pins.push(m);
        while (pins.length > MAX_PINS) { placeCluster.removeLayer(pins.shift()); }
    }

    function closeAll() {
        active.slice().forEach(function (c) { c(true); });
    }

    // Photos with a known position that were not shown yet, nearest first (own photos win ties).
    function candidates(photos, here, maxDist) {
        var list = [];
        photos.forEach(function (ph) {
            if (typeof ph.latitude !== 'number' || typeof ph.longitude !== 'number' || (shown[key(ph)] && Date.now() - shown[key(ph)] < SHOWN_TTL_MS)) return;
            var d = here.distanceTo([ph.latitude, ph.longitude]);
            if (d <= maxDist) list.push({ ph: ph, d: d + (ph.source === 'own' ? 0 : 150) });
        });
        list.sort(function (a, b) { return a.d - b.d; });
        return list.map(function (x) { return x.ph; });
    }

    function fly(picks, here) {
        var narrow = map.getSize().x < 640, compact = isCompact();
        if (narrow) picks = picks.slice(0, compact ? 1 : 2);   // cards do not fit side by side on a phone
        var W = compact ? 112 : 150, H = compact ? 80 : 106, c = map.latLngToContainerPoint(here), pos = anchors(picks.length, W, H, c), L0 = ensureLayer();
        lastShow = Date.now();
        picks.forEach(function (ph, i) {
            remember(ph);
            var card = document.createElement('div');
            card.className = 'flyCard';
            var credit = (ph.people && ph.people.length ? ph.people.join(', ') : photoCredit(ph)).replace(/</g, '&lt;');   // the owner's own photo shows who is on it instead of the generic credit
            card.innerHTML = '<img alt="" src="' + (ph.photo_file_url || '').replace(/"/g, '%22') + '"/><span>' + credit + '</span>';
            card.style.left = (pos[i].x - W / 2) + 'px'; card.style.top = (pos[i].y - H / 2) + 'px';
            var origin = map.latLngToContainerPoint([ph.latitude, ph.longitude]);
            card.style.transform = 'translate(' + (origin.x - pos[i].x) + 'px,' + (origin.y - pos[i].y) + 'px) scale(.12)';
            card.style.opacity = '0';
            L0.appendChild(card);
            var hovered = false, timer = null, closed = false;
            function close(force) {
                if (closed || (hovered && force !== true)) return; closed = true;
                clearTimeout(timer);
                var k = active.indexOf(close); if (k >= 0) active.splice(k, 1);
                var o2 = map.latLngToContainerPoint([ph.latitude, ph.longitude]);
                var cx = parseFloat(card.style.left) + W / 2, cy = parseFloat(card.style.top) + H / 2;
                card.classList.add('leaving');
                card.style.transform = 'translate(' + (o2.x - cx) + 'px,' + (o2.y - cy) + 'px) scale(.12)';
                card.style.opacity = '0';
                setTimeout(function () { if (card.parentNode) card.parentNode.removeChild(card); addPin(ph); }, reduced() ? 50 : 700);
            }
            active.push(close);
            card.addEventListener('mouseenter', function () { hovered = true; clearTimeout(timer); });
            card.addEventListener('mouseleave', function () { hovered = false; timer = setTimeout(close, 1500); });
            card.addEventListener('click', function () { photoViewer.open(0, [ph]); });
            // fly in on the next frames (the browser needs the start state first)
            setTimeout(function () {
                if (closed) return;
                card.classList.add('flying');
                card.style.transform = 'translate(0,0) scale(1)';
                card.style.opacity = '1';
                timer = setTimeout(close, HOLD_MS + i * 500);
            }, 60 + i * 220);
        });
    }

    // radius of the search that found these photos (degrees) -> metres we accept for "nearby"
    function reach(tol) {
        return Math.max(2500, Math.min(10000, (tol || 0.02) * 111000 * 0.6));
    }

    function show(photos, p, tol) {
        if (typeof map === 'undefined' || typeof placeCluster === 'undefined') return;
        current = { photos: photos, p: p, tol: tol };
        if (!enabled()) return;
        var now = Date.now();
        if (now - lastShow < MIN_GAP_MS) return;
        var here = L.latLng(p.lat, p.lng);
        var cand = candidates(photos, here, reach(tol));
        // nothing close: still fly in the nearest one or two (within 20 km)
        if (!cand.length) cand = candidates(photos, here, 20000).slice(0, 2);
        if (!cand.length) return;
        closeAll();   // a new place: the old cards fly back to their spots and make room
        fly(cand.slice(0, MAX_CARDS), here);
    }

    // Long stay in one place (or nothing new for a while): bring up photos around the marker that were not shown yet.
    setInterval(function () {
        if (!current || !enabled() || typeof map === 'undefined' || typeof placeCluster === 'undefined') return;
        if (active.length || Date.now() - lastShow < IDLE_GAP_MS) return;
        var here = (typeof animatedMarker !== 'undefined' && animatedMarker.getLatLng) ? animatedMarker.getLatLng() : L.latLng(current.p.lat, current.p.lng);
        var cand = candidates(current.photos, here, Math.max(reach(current.tol), 5000));
        if (!cand.length) { lastShow = Date.now() - IDLE_GAP_MS + 5000; return; }   // check again in 5 s
        fly(cand.slice(0, MAX_CARDS), here);
    }, 4000);

    return { show: show, clear: function () { closeAll(); $('.flyLayer').empty(); pins.forEach(function (m) { placeCluster.removeLayer(m); }); pins = []; pinPhotos = []; shown = {}; shownOrder = []; current = null; } };
})();
window.flyInPhotos = flyIn.show;
//#endregion

//#region Photo viewer
var photoViewer = (function () {
    var $v, $img, $cap, idx = 0, open = false, list = null;

    function build() {
        $v = $(
            '<div id="photoViewer" role="dialog" aria-modal="true" aria-label="Photo viewer">' +
            '<button type="button" class="pv-btn pv-close" aria-label="' + T("Close", "Close") + '" title="' + T("Close", "Close") + ' (Esc)">×</button>' +
            '<button type="button" class="pv-btn pv-prev" aria-label="' + T("Previous", "Previous") + '" title="' + T("Previous", "Previous") + ' (←)">‹</button>' +
            '<button type="button" class="pv-btn pv-next" aria-label="' + T("Next", "Next") + '" title="' + T("Next", "Next") + ' (→)">›</button>' +
            '<figure><img alt=""/><figcaption></figcaption></figure></div>').appendTo('body');
        $img = $v.find('img'); $cap = $v.find('figcaption');
        $v.on('click', function (e) { if (e.target === this || $(e.target).is('figure')) close(); });
        $v.find('.pv-close').on('click', close);
        $v.find('.pv-prev').on('click', function () { go(-1); });
        $v.find('.pv-next').on('click', function () { go(1); });
        $(document).on('keydown.pv', function (e) {
            if (!open) return;
            if (e.key === 'Escape') close();
            else if (e.key === 'ArrowLeft') go(-1);
            else if (e.key === 'ArrowRight') go(1);
        });
        var sx = null;   // swipe
        $v.on('touchstart', function (e) { sx = e.originalEvent.touches[0].clientX; })
          .on('touchend', function (e) {
              if (sx === null) return;
              var dx = e.originalEvent.changedTouches[0].clientX - sx; sx = null;
              if (Math.abs(dx) > 50) go(dx < 0 ? 1 : -1);
          });
    }

    function esc(t) { return $('<div>').text(t == null ? '' : t).html(); }

    function show() {
        var ph = list[idx];
        if (!ph) return;
        var full = ph.big_url || ph.photo_file_url;
        $img.attr('src', ph.photo_file_url);                         // instantly show the strip thumbnail ...
        var big = new Image();
        big.onload = function () { if (list[idx] === ph) $img.attr('src', full); };   // ... then the large one
        big.src = full;
        var title = ph.photo_title && ph.photo_title !== "TBD" ? ph.photo_title.replace(/\.[a-z]{3,4}$/i, "") : "";
        var html = (title ? '<strong>' + esc(title) + '</strong><br>' : '') + esc(photoCredit(ph));
        if (ph.source === "commons") {
            if (ph.license_url) html = html.replace(esc(ph.license), '<a href="' + esc(ph.license_url) + '" target="_blank" rel="noopener">' + esc(ph.license) + '</a>');
            html += ' · <a href="' + esc(ph.photo_url) + '" target="_blank" rel="noopener">' + esc(T("SourceCommons", "Source: Wikimedia Commons")) + '</a>';
        }
        if (ph.source === "own" && ph.photo_url) html += ' \u00b7 <a href="' + esc(ph.photo_url) + '" target="_blank" rel="noopener">' + esc(T("Original", "Original")) + '</a>';
        if (ph.people && ph.people.length) html += ' \u00b7 <i class="fa fa-user"></i> ' + esc(ph.people.join(", "));
        if (ph.source === "own" && typeof ph.syt_public === "boolean") html += ' \u00b7 <i class="fa fa-map-marker" style="color:' + (ph.syt_public ? '#2fbf6c' : '#ff5a52') + '"></i> ' + esc(ph.syt_public ? T("Public", "Public") : T("Private", "Private"));
        if (typeof ph.latitude === "number" && typeof ph.longitude === "number" && typeof map !== "undefined")
            html += ' · <a href="#" class="pv-map">' + esc(T("ShowOnMap", "Show on map")) + '</a>';
        html += '<span class="pv-count">' + (idx + 1) + ' / ' + list.length + '</span>';
        $cap.html(html);
        $cap.find('.pv-map').on('click', function (e) {
            e.preventDefault(); close();
            map.setView([ph.latitude, ph.longitude], Math.max(map.getZoom(), 14));
        });
    }

    function go(d) { if (!list.length) return; idx = (idx + d + list.length) % list.length; show(); }
    function close() { open = false; if ($v) $v.removeClass('open'); setTimeout(function () { if (!open && $v) $v.hide(); }, 180); }
    return {
        open: function (i, customList) {
            if (!$v) build();
            list = customList || stripPhotos;
            idx = i; open = true; $('#photoPreview').hide();
            $v.show(); setTimeout(function () { $v.addClass('open'); }, 0); show();
            $v.find('.pv-close').focus();
        }
    };
})();
//#endregion

function GPXtoLatLng(urlGPX) {
    var result = "";
    if (window.XMLHttpRequest) {// code for IE7+, Firefox, Chrome, Opera, Safari
        xmlhttp = new XMLHttpRequest();
    }
    else {// code for IE6, IE5
        xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
    }
    xmlhttp.open("GET", urlGPX + "?" + Math.random(), false);
    xmlhttp.send();
    xmlDoc = xmlhttp.responseXML;

    var nodes = xmlDoc.getElementsByTagName("trkpt");
    for (var i = 0; i < nodes.length; i++) {
        if (result.length > 0)
            result += ",";
        result += "[" + nodes[i].getAttribute("lat").toString() + "," + nodes[i].getAttribute("lon").toString() + "]";
    }
    result = "[" + result + "]";
    return result;
}

function selectMapStyle() {
    window.sytMapStyle = $('#mapStyle').val() || 'osm';

    // At page load the map and its tile layer may not exist yet; they will pick up sytMapStyle when created.
    if (typeof map == "undefined" || typeof tileLayer == "undefined" || !tileLayer._map)
        return;

    map.removeLayer(tileLayer);
    tileLayer = L.tileLayer();
    tileLayer.addTo(map);
    if (tileLayer._map)
        tileLayer.bringToBack();
}
function fixTrackData(track) {
    var newTrackData = [];
    var totalDistance = 0.0;
    for (var i = 0; i < track.trackData.length; i++) {
        var told = track.trackData[i];
        var tnew = pointToLatLng(told)
        newTrackData.push(tnew);
        if (i > 0) {
            totalDistance = totalDistance + newTrackData[i].distanceTo(newTrackData[i - 1]);
        }
    }
    track.trackData = newTrackData;
    track.avgDistM = totalDistance / (i - 1);
}

function loadTrack(path, handler) {
    var url = path + "?" + Math.random();
    $.ajax({
        url: url,
        //async: false,
        dataType: 'json',
        error: function (XMLHttpRequest, textStatus, errorThrown) {
            console.log("loadTrack error: " + textStatus); console.log("Error: " + errorThrown);
        },
        success: function (data) {
          // the borders of the covered countries are needed to decide whether the track may be opened
          sytBlocked.load().always(function () {
            var tempTrack = data;
            if (tempTrack.trackGpx) {
                tempTrack.trackData = $.parseJSON(GPXtoLatLng(translateTracksContentPath(tempTrack.trackGpx)));
            }

            fixTrackData(tempTrack);

            var blockedIn = sytBlocked.trackCountry(tempTrack.trackData);
            if (blockedIn) {
                if (window.sytRevealMap) window.sytRevealMap();
                $("#trackLoading").remove();
                toastr.error(sytBlocked.message(blockedIn), "", { timeOut: 20000, extendedTimeOut: 20000, closeButton: true });
                return;
            }

            // the description is shown in the track details (Track tab); "Description" in Settings shows or hides it
            tempTrack._descHtml = "";
            if (!isNullOrEmpty(tempTrack.textToRead)) {
                var descText = $.ajax(
                    {
                        url: translateTracksContentPath(tempTrack.textToRead + "?" + Math.random()),
                        async: false
                    }
                ).responseText || "";
                // plain text (no HTML tags) keeps its paragraphs
                if (!/<\/?[a-z][^>]*>/i.test(descText))
                    descText = $("<div>").text(descText).html().replace(/\r?\n/g, "<br>");
                // authors may use HTML, but no scripts or event handlers
                var tmp = $("<div>").html(descText);
                tmp.find("script,iframe,object,embed,style,link,meta").remove();
                tmp.find("*").each(function () {
                    var el = this;
                    $.each(Array.prototype.slice.call(el.attributes), function (i, at) {
                        if (/^on/i.test(at.name) || /^\s*javascript:/i.test(at.value)) el.removeAttribute(at.name);
                    });
                });
                tempTrack._descHtml = tmp.html();
            }
            var hasDescription = $.trim(tempTrack._descHtml) != "";
            $('#scriptTextCheckBox').prop('disabled', !hasDescription);
            $('label[for=scriptTextCheckBox]').css('opacity', hasDescription ? '' : '0.4');

            handler(tempTrack);
          });
        }
    });
}

//function clearMap(m) {
//    for (i in m._layers) {
////        if (m._layers[i]._path != undefined) {
//            try {
//                m.removeLayer(m._layers[i]);
//            }
//            catch (e) {
//                console.log("problem with " + e + m._layers[i]);
//            }
////        }
//    }
//}

function init(filename, handler) {

    if (typeof map != "undefined") {
        //var mapNode = document.getElementById("map");
        //var mapContainerParent = mapNode.parentNode;
        //mapContainerParent.removeChild(mapNode);

        //mapNode = document.createElement('div');
        //mapNode.id = "map";
        //mapNode.style.zIndex = 10;
        //mapContainerParent.appendChild(mapNode);
        //map.removeLayer(tileLayer);
        markers.clearLayers();
        map.removeLayer(markers);
        //clearMap(map);
        //map = null;
    }
    else {
        map = L.map('map', { zoomControl: false });
        sytBlocked.cover(map);
        // a sensible start view (Europe): without it the map stays blank when no track is chosen and the location is unavailable
        map.setView([48, 14], 4);
        map.on('dragstart', function () { followPausedUntil = Date.now() + 10000; });
        if (trackRequested) {
            // keep the map hidden until the track has set the real view (no flash of Europe / the current location)
            var mapEl = map.getContainer();
            mapEl.classList.add('syt-loading');
            // a small "loading" notice while the map is hidden, so the page never looks dead
            var $loading = $('<div id="trackLoading"><span class="spin"></span><span class="txt i" data-i18n="LoadingTrack">Loading track\u2026</span></div>').appendTo('body');
            if ($.fn.i18n) $loading.find('.i').i18n();
            window.sytRevealMap = function () { mapEl.classList.remove('syt-loading'); $loading.fadeOut(200, function () { $loading.remove(); }); };
            setTimeout(window.sytRevealMap, 6000);   // safety net if the track cannot be loaded
        }
        tileLayer = L.tileLayer(mapTileUrl, {
            attribution: '© <a href="https://www.mapbox.com/about/maps/">Mapbox</a> © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> <strong><a href="https://www.mapbox.com/map-feedback/" target="_blank">Improve this map</a></strong>',
            tileSize: 512,
            maxZoom: 18,
            zoomOffset: -1,
            id: 'mapbox/streets-v11',
            accessToken: 'pk.eyJ1Ijoib2x0dXJ1YSIsImEiOiJlODQ4ZTI2MWI4OGZkZjUyNDRiNjY4MDFkZGI0ODc4NyJ9.iiCb_tZgs_ipvEv3s6Zx0A'
            });
        tileLayer.addTo(map);
        L.control.scale({ position: 'bottomleft' }).addTo(map);
        L.control.zoom({ position: 'bottomright' }).addTo(map);

        //Routing example
        //L.Routing.control({
        //    waypoints: [
        //      L.latLng(50.45, 30.52),
        //      L.latLng(50.56, 30.31)
        //    ]
        //}).addTo(map);
    }

    markers = new L.FeatureGroup();
    // Places (Wikipedia/SYT/Google) are grouped only gently: nearby markers merge into a small round badge, and
    // the grouping stops completely when zoomed in (zoom 13+).
    placeCluster = L.markerClusterGroup({
        maxClusterRadius: isCompact() ? 90 : 38,
        disableClusteringAtZoom: isCompact() ? 15 : 13,
        showCoverageOnHover: false,
        spiderfyOnMaxZoom: true,
        chunkedLoading: true,
        iconCreateFunction: function (cluster) {
            var kids = cluster.getAllChildMarkers(), thumb = '';
            for (var i = 0; i < kids.length && !thumb; i++) thumb = kids[i].options.thumb || '';
            var n = cluster.getChildCount();
            var html = (thumb ? '<img src="' + thumb.replace(/"/g, '%22') + '" alt="" onerror="this.style.display=\'none\'"/>' : '') + '<b>' + n + '</b>';
            var cs = isCompact() ? 40 : 50;
            return L.divIcon({ html: html, className: 'sytCluster' + (thumb ? ' withThumb' : ''), iconSize: [cs, cs] });
        }
    });
    markers.addLayer(placeCluster);
    map.addLayer(markers);
    if (typeof markersFriends == "undefined") {
        markersFriends = new L.FeatureGroup();
        markers.addLayer(markersFriends);
    }
    if (typeof markersTracks == "undefined") {
        markersTracks = new L.FeatureGroup();
        markers.addLayer(markersTracks);
    }

    markerWhereIAm = L.marker(new L.LatLng(1000, 1000), { icon: iconWhereIAm, zIndexOffset: 100 }).bindPopup(globalUserName);
    markers.addLayer(markerWhereIAm);
    if ($.fn.i18n) $('.youHere .i').i18n();   // otherwise the next $(".i").i18n() (translateAll) does it once the language is loaded

    //markerWhereIAmCircle = L.circleMarker(new L.LatLng(1000, 1000),
    //    {
    //        radius: 50,
    //        fillColor: "#ff7800",
    //        color: "#000",
    //        weight: 1,
    //        opacity: 1,
    //        fillOpacity: 0.8,
    //        title: "test"
    //    });
    //markers.addLayer(markerWhereIAmCircle);

    showLocation();

    if (!filename) {

    }
    else {
        var path = translateTracksPath(filename + ".js");
        loadTrack(path,
            function (tempTrack) {

                track = tempTrack
                photoSearch.clear();
                if (window.flyIn && flyIn.clear) flyIn.clear();
                applyDefaultSpeed(track);

                // the vehicle chosen in the editor ("Travel with"); tracks without one keep the target sign
                // the picture saved with the track, else the one for its "Travel with" (walking man, bike, car, ...), else the target sign
                var VEHICLE_ICONS = { WalkingMan: "aman.gif", Bike: "mybike.png", Car: "mycar.png", Bus: "mybus.png", Yacht: "myyacht.png", Plane: "myplane.png" };
                var iconFile = (track.icon && /^[\w.-]+\.(png|gif|jpg|jpeg|svg)$/i.test(track.icon)) ? track.icon : "currentposition.png";
                if (iconFile === "currentposition.png" && VEHICLE_ICONS[track.travelWith]) iconFile = VEHICLE_ICONS[track.travelWith];
                var vehicle = iconFile !== "currentposition.png";
                var iconSize = vehicle ? (/\.gif$/i.test(iconFile) ? 56 : 46) : markerSize * 1.5;   // the animated walking man is a little larger
                var myIcon = L.icon({
                    iconUrl: translateTracksContentPath(iconFile),
                    iconSize: [iconSize, iconSize],
                    iconAnchor: [iconSize / 2, iconSize / 2],
                    className: vehicle ? 'vehicleIcon' : '',
                    shadowUrl: null
                });
                if (vehicle) {   // missing file: use the target sign
                    var probe = new Image();
                    probe.onerror = function () { myIcon.options.iconUrl = translateTracksContentPath("currentposition.png"); if (animatedMarker) animatedMarker.setIcon(myIcon); };
                    probe.src = translateTracksContentPath(iconFile);
                }

                var lastUpdateTime = new Date(2000, 2);

                var amOptions = {
                    distance: getSpeedMps(), // meters
                    zIndexOffset: 1000,
                    interval: 1000, // milliseconds
                    icon: myIcon, // icon
                    autoStart: false,
                    onEnd: function () {
                        if ($("#loopTrackCheckBox").is(':checked')) {
                            if (window.flyIn && flyIn.clear) flyIn.clear();   // a new round: the photos may fly in again
                            animatedMarker.start();
                        }
                    },
                    onStep: function (p) {
                        counter++;
                        if (p.hasOwnProperty("syt_text") && p["syt_text"] != "") {
                            var pointTextMs = Math.min(30000, Math.max(6000, String(p["syt_text"]).length * 80));   // about 12 characters a second
                            toastr.info(p["syt_text"], "", { timeOut: pointTextMs, extendedTimeOut: 10000 });
                            //prependToSidePanel(p["syt_text"]);
                        }

                        if (p.hasOwnProperty("syt_audio")) {
                            audio.src = translateTracksContentPath(p["syt_audio"]);
                            safePlayAudio();
                        }
                        //markerSize = 2 + map.getZoom() * 5;

                        var currentDate = new Date();
                        if ((currentDate.getTime() - lastUpdateTime.getTime()) / 1000 > updateIntervalSeconds) {

                            if (followsTrack() && !(window.sytImmersive && sytImmersive.isOn())) map.setView([p.lat, p.lng], map.getZoom());   // the hidden 2D map is not moved in 3D mode
                            showPhotos(track, p);
                            //                    animatedMarker.bindPopup("".concat(p.lat, ",", p.lng)).openPopup();

                            lastUpdateTime = currentDate;
                        }
                    }
                };

                for (var i = 0; i < track.trackData.length; i++) {
                    var point = track.trackData[i];
                    if (point.hasOwnProperty("syt_text") && point["syt_text"] != "") {

                        var icon = L.icon({
                            iconUrl: "img/info.png",
                            //    shadowUrl: 'leaf-shadow.png',

                            iconSize: [25, 25] // size of the icon
                            //    shadowSize:   [50, 64], // size of the shadow
                            , iconAnchor: [13, 25] // point of the icon which will correspond to marker's location
                            //    shadowAnchor: [4, 62],  // the same for the shadow
                            //    popupAnchor:  [0, 0] // point from which the popup should open relative to the iconAnchor
                        });

                        var text = point["syt_text"].toString();
                        var domelem = document.createElement('a');
                        //domelem.href = place.name;
                        domelem.innerHTML = "<p>" + text + "</p>";//<img height='100px' width='100px' src='" + (isGoogle ? photos[0].getUrl({ 'maxWidth': 100, 'maxHeight': 100 }) : photos[0].raw_reference.fife_url) + "'/>";
                        domelem.alt = text;
                        //domelem.onclick = function () {
                        //    window.open("https://www.google.com.ua/search?q=" + place.name, "_blank");
                        //};
                        var marker = L.marker(new L.LatLng(point.lat, point.lng),
                            { icon: icon }).bindPopup(domelem);
                        markers.addLayer(marker);
                        //    myMarkers.push(marker);
                    }
                }
                animatedMarker = L.animatedMarker(track.trackData, amOptions);
                animatedMarker.setIcon(myIcon);
                markers.addLayer(animatedMarker);

                line = L.polyline(track.trackData, { color: 'green' });
                markers.addLayer(line);

                var startPopup = $("<div>").addClass("trackStartPopup");
                startPopup.append($("<b>").text(track.startName || "Start"));
                markerStart = L.marker(track.trackData[0]).bindPopup(startPopup[0]);
                if (track.trackImage && /^[^\/\\?#<>"']+\.(png|gif|jpe?g|webp)$/i.test(track.trackImage)) {
                    // the picture of the track: it is the start marker (round thumbnail), a click shows it large
                    var imgUrl = encodeURI(translateTracksContentPath(track.trackImage)), startMarker = markerStart, probeImg = new Image();
                    probeImg.onload = function () {
                        startPopup.prepend($("<img>").attr("src", imgUrl).addClass("trackStartImg"));
                        startMarker.setZIndexOffset(500);
                        startMarker.setIcon(L.divIcon({
                            className: "trackImageMarker",
                            html: $("<div>").append($("<img>").attr("src", imgUrl))[0].innerHTML,
                            iconSize: [58, 58], iconAnchor: [29, 29], popupAnchor: [0, -26]
                        }));
                    };
                    probeImg.src = imgUrl;
                }
                if (track.startName) markerStart.bindTooltip(track.startName, { permanent: true, direction: "right", offset: [8, -20], className: "trackEndLabel" });
                markers.addLayer(markerStart);

                markerFinish = L.marker(track.trackData[track.trackData.length - 1]).bindPopup(track.endName || "Finish");
                if (track.endName) markerFinish.bindTooltip(track.endName, { permanent: true, direction: "right", offset: [8, -20], className: "trackEndLabel" });
                markers.addLayer(markerFinish);

                setInitialTrackView(track);
                if (window.sytRevealMap) window.sytRevealMap();

                if (track.audioSrc && track.audioSrc.length > 0) {
                    audio.src = translateTracksContentPath(track.audioSrc);
                    if (track.audioVolume) {
                        audio.volume = track.audioVolume ? track.audioVolume : 0.8;
                        $("#slider").slider("value", audio.volume);
                    }
                }

                addMarkersNearAll(track.trackData, GOOGLE_TYPES);

                if (track && $('#helpPanel').is(':visible')) {
                    var elevator = new google.maps.ElevationService;
                    elevator.getElevationAlongPath({
                        'path': compactTrackData(track.trackData),
                        'samples': 128
                    }, plotElevation);
                }

                isTrackLoaded = true;

                // look for the photos of the starting place right away (the first step of the marker comes seconds later)
                try { showPhotos(track, pointToLatLng(track.trackData[0])); } catch (e) { console.log('first photos: ' + e); }

                if (handler) {
                    handler();
                }
            });
    }
}

var myMarkers = [];

//Google places search
function addMarkersNearAll(allData, types) {

    var i;

    for (i = 0; i < myMarkers.length; i++) {
        var marker = myMarkers[i];
        map.removeLayer(marker)
    }
    myMarkers = [];
    allMarkers = [];

    for (var i = 0; i < PIECES_COUNT; i++) {
        var from = Math.round(allData.length * i / PIECES_COUNT);
        var to = Math.round(allData.length * (i + 1) / PIECES_COUNT);
        var step = Math.round(allData.length / (STEPS_PER_PIECE * PIECES_COUNT));
        if (step == 0)
            step = 1;
        doSetTimeout(allData, types, from, to, step, i);

        if (!isCompact() || i % 2 === 0) addWeatherMarkers(allData, from);   // fewer labels on a phone
    }
    addWeatherMarkers(allData, allData.length - 1);
}

function doSetTimeout(allData, types, from, to, step, i) {
    setTimeout(function () { addMarkersNearRange(allData, types, from, to, step, (i % 2) == 1) }, i * 2000 + 1);
}

function addMarkersNearRange(allData, types, from1, to1, step1, odd) {
    var pending = [];
    for (var i = from1; i < to1; i += step1) {
        var x = allData[i];
        pending.push(addMarkersNear(x.lat, x.lng, types, odd));
    }
    // the first part of the track is what the ready gate waits for
    if (from1 === 0 && window.sytGate) {
        var g = window.sytGate;
        var settle = function (pr) { return Promise.resolve(pr).then(function () { }, function () { }); };
        Promise.all(pending.map(settle)).then(function () { g.places = true; });
    }
}

function addWeatherMarkers(allData, where) {
    var x = allData[where];
    addWeatherMarkersNear(x.lat, x.lng);
}

function addWeatherMarkersNear(nearLat, nearLng) {
    var here = new google.maps.LatLng(nearLat, nearLng);

    var request = {
        location: here,
        radius: MAX_GOOGLE_RADIUS,
        types: null
    };

    Promise.all([
        syt.api.searchWeather(request)
    ]).then(
        function (values) {
            weather_success(values[0]);
        });
}

function addMarkersNear(nearLat, nearLng, types, odd) {
    var here = new google.maps.LatLng(nearLat, nearLng);

    var request = {
        location: here,
        radius: MAX_GOOGLE_RADIUS,
        types: types
    };

    //if (odd) {
    //    $.ajax({
    //        dataType: "jsonp",
    //        url: "http://places.cit.api.here.com/places/v1/discover/explore?app_code=uEO7B5HdlYKIGSKmelLEtw&app_id=qiqSlXY6ilurDyZnKplJ&at=50.430837,30.539654&cat=accommodation, eat-drink&pretty=true&tf=html",
    //        success: function (data2) {
    //            console.log(data2);
    //            callbackHerePlacesSearch(data2);
    //        },
    //        error: function (XMLHttpRequest, textStatus, errorThrown) {
    //            console.log("Status: " + textStatus); console.log("Error: " + errorThrown);
    //            get_places_googlehere_success([]);
    //        }
    //    });
    //}
    //else {

    var googlePlacesService = new google.maps.places.PlacesService(map2);

    return Promise.all([
        syt.api.searchSYTPlaces(request),
        syt.api.searchWikiPlaces(request),
        syt.api.searchGooglePlaces(googlePlacesService, request)
    ]).then(
        function (values) {
            getplaces_success(values[0].concat(values[1]).concat(values[2]).concat(values[3]));
        });

    //    }
}

window.sytSeenWeather = window.sytSeenWeather || [];   // weather labels drawn on the map, kept for the chat assistant
function weather_success(place) {
    try { window.sytSeenWeather.push({ lat: +place.lat, lng: +place.lng, temperature: String(place.temperature), conditions: String(place.icon || '') }); if (window.sytSeenWeather.length > 60) window.sytSeenWeather.shift(); } catch (e) { }

    var iconImg;
    if (place.icon == "clear-day") {
        iconImg = "001lighticons-02.png";
    } else if (place.icon == "clear-night") {
        iconImg = "001lighticons-03.png";
    } else if (place.icon == "rain") {
        iconImg = "001lighticons-18.png";
    } else if (place.icon == "snow") {
        iconImg = "001lighticons-21.png";
    } else if (place.icon == "sleet") {
        iconImg = "001lighticons-23.png";
    } else if (place.icon == "wind") {
        iconImg = "001lighticons-06.png";
    } else if (place.icon == "fog") {
        iconImg = "001lighticons-12.png";
    } else if (place.icon == "cloudy") {
        iconImg = "001lighticons-14.png";
    } else if (place.icon == "partly-cloudy-day") {
        iconImg = "001lighticons-08.png";
    } else if (place.icon == "partly-cloudy-night") {
        iconImg = "001lighticons-09.png";
    } else {
        iconImg = "001lighticons-90.png";
    }

    // High-contrast label (HTML instead of the old picture with thin white text): dark text on a light pill
    var tempText = $("<div>").text(place.temperature).html();
    var icon = L.divIcon({
        className: 'wxIcon',
        html: '<div class="wxLabel"><img src="img/weather/' + iconImg + '" alt=""/><span>' + tempText + '</span></div>',
        iconSize: isCompact() ? [92, 24] : [112, 30],
        iconAnchor: isCompact() ? [46, 12] : [56, 15]
    });

    var domelem = document.createElement('a');
    //domelem.href = place.name;
    domelem.innerHTML = "<p><img style='height:50px; wisth: 50px;' src='" + "img/weather/" + iconImg + "'/></p><p>" + place.temperature + "</p>";//<img height='100px' width='100px' src='" + (isGoogle ? photos[0].getUrl({ 'maxWidth': 100, 'maxHeight': 100 }) : photos[0].raw_reference.fife_url) + "'/>";
    domelem.alt = place.temperature;
    domelem.onclick = function () {
        window.open("https://darksky.net/forecast/" + place.lat + "," + place.lng, "_blank");
        // do whatever else you want to do - open accordion etc
    };
    var marker = L.marker(new L.LatLng(
        place.lat,
        place.lng),
        { icon: icon, zIndexOffset: 800 }).bindPopup(domelem);
    myMarkers.push(marker);

    markers.addLayer(marker);
}

function getplaces_success(data) {
    for (var i = 0; i < Math.min(data.length, MAX_GOOGLE_PLACES * 3); i++) {
        if (data[i])
            createPhotoMarker(data[i]);
    }
}

window.sytSeenPlaces = window.sytSeenPlaces || {};   // places drawn on the map (name, source, short description), kept for the chat assistant
function createPhotoMarker(place) {

    if (allMarkers.indexOf(place.id) < 0)
        allMarkers.push(place.id);
    else
        return;

    try {
        var plat = place.lat != null ? place.lat : (place.geometry && place.geometry.location ? place.geometry.location.lat() : null);
        var plng = place.lng != null ? place.lng : (place.geometry && place.geometry.location ? place.geometry.location.lng() : null);
        if (plat != null && plng != null && place.name) {
            var ks = Object.keys(window.sytSeenPlaces); if (ks.length > 300) delete window.sytSeenPlaces[ks[0]];
            window.sytSeenPlaces[place.id] = { name: String(place.name).slice(0, 80), source: place.types.indexOf("wiki") >= 0 ? "Wikipedia" : place.types.indexOf("syt") >= 0 ? "SeeYourTravel user place" : "Google place", description: String(place.description || "").slice(0, 100), lat: +plat, lng: +plng };
        }
    } catch (e) { }

    // console.log (place);

    var photos = place.photos;
    if (!photos) {
        return;
    }

    var isGoogle = photos[0].getUrl ? true : false;
    var isWiki = place.types.indexOf("wiki") >= 0;
    var isSyt = place.types.indexOf("syt") >= 0;   // a place added by a SeeYourTravel user

    var isPremium = Math.random() < 0.1;
    var thumbIcon = null;
    if ((isWiki && place.thumb) || isSyt) {
        var safe = (place.thumb || 'img/something.png').replace(/"/g, '%22');
        thumbIcon = L.divIcon({
            className: isSyt ? 'wikiThumbIcon sytPlace' : 'wikiThumbIcon',
            html: '<img src="' + safe + '" alt="" loading="lazy" onerror="this.parentNode.classList.add(\'noimg\')"/><span>' + (isSyt ? '&#9733;' : 'W') + '</span>',
            iconSize: isCompact() ? [34, 34] : [46, 46], iconAnchor: isCompact() ? [17, 17] : [23, 23]
        });
    }
    var icon = thumbIcon || L.icon({
        iconUrl: (
            place.types.indexOf("lodging") >= 0 ? "img/lodging.png" :
            place.types.indexOf("restaurant") >= 0 ? "img/restaurant1.png" :
            place.types.indexOf("museum") >= 0 ? "img/museum.png" :
            place.types.indexOf("park") >= 0 ? "img/park.png" :
            place.types.indexOf("bakery") >= 0 ? "img/bakery.png" :
            place.types.indexOf("zoo") >= 0 ? "img/zoo.png" :
            isWiki ? "img/wiki.png" :
            "img/something.png"),
        //    shadowUrl: 'leaf-shadow.png',

        iconSize: isWiki ? [26, 26] : (!isPremium ? [26, 35] : [37, 52]) // size of the icon
        //    shadowSize:   [50, 64], // size of the shadow
        //    iconAnchor:   [0, 0], // point of the icon which will correspond to marker's location
        //    shadowAnchor: [4, 62],  // the same for the shadow
        //    popupAnchor:  [0, 0] // point from which the popup should open relative to the iconAnchor
    });

    var wikiLink = "https://" + getTwitterLanguage() + ".wikipedia.org/?curid=" + place.id;
    var buildPopup = function () {
    var domelem = document.createElement('div');
    domelem.className = 'placePopup';
    var title = document.createElement('p');
    title.className = 'pp-title';
    title.textContent = place.name;
    domelem.appendChild(title);
    if (isWiki && place.description) {
        var d = document.createElement('p');
        d.className = 'pp-desc';
        d.textContent = place.description;
        domelem.appendChild(d);
    }
    var pic = document.createElement('img');
    pic.alt = place.name;
    if (isSyt && !place.thumb) pic = document.createElement('span');   // no photo to show
    if (pic.tagName == "IMG") pic.src = isGoogle ? photos[0].getUrl({ 'maxWidth': 100, 'maxHeight': 100 }) : photos[0].raw_reference.fife_url;
    pic.style.maxWidth = '160px'; pic.style.maxHeight = '120px'; pic.style.borderRadius = '6px';
    domelem.appendChild(pic);
    var go = document.createElement('p');
    var link = document.createElement('a');
    link.target = '_blank'; link.rel = 'noopener';
    link.href = isWiki ? wikiLink : isSyt ? place.link : "https://www.google.com/search?q=" + encodeURIComponent(place.name);
    link.textContent = isWiki ? T('OpenInWikipedia', 'Open in Wikipedia') : isSyt ? T('OpenLink', 'Open link') : T('SearchOnGoogle', 'Search on Google');
    if (!isSyt || place.link) go.appendChild(link);
    domelem.appendChild(go);
    return domelem;
    };
    var marker = L.marker(new L.LatLng(
        isGoogle ? place.geometry.location.lat() : place.geometry.location.lat,
        isGoogle ? place.geometry.location.lng() : place.geometry.location.lng),
        { icon: icon, title: place.name, thumb: ((isWiki || isSyt) && place.thumb) ? place.thumb : '' }).bindPopup(buildPopup);
    myMarkers.push(marker);

    placeCluster.addLayer(marker);

}

//function createMarker(place) {
//  var placeLoc = place.geometry.location;
//  var marker = new google.maps.Marker({
//    map: map,
//    position: place.geometry.location
//  });

//  google.maps.event.addListener(marker, 'click', function() {
//    infowindow.setContent(place.name);
//    infowindow.open(map, this);
//  });
//}

function getFromCacheOrServer(url, obj, handler) {

    var data = $.jStorage.get(url);
    if (!data) {
        // if not - load the data from the server
        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.responseType = 'blob';
        xhr.onload = function (e) {
            if (this.status == 200) {
                // Note: .response instead of .responseText
                var blob = new Blob([this.response], { type: 'image/png' });
                var reader = new window.FileReader();
                reader.readAsDataURL(blob);
                reader.onloadend = function (event) {
                    var data = event.target.result;
                    // and save it
                    $.jStorage.set(url, data, { TTL: 1000 * 60 * 60 * 24 });
                    handler(obj, data);
                };
            }
        };
        xhr.send();
    }
    else {
        handler(obj, data);
    }
}

function clearElevation() {

    var chartDiv = document.getElementById('elevationChartDiv');
    //if (status !== 'OK') {
    //    // Show the error code inside the chartDiv.
    //    chartDiv.innerHTML = 'Cannot show elevation: request failed because ' +
    //        status;
    //    return;
    //}

    if (!chartDiv)
        return;
    chartDiv.innerHTML = "<canvas id=\"elevationChartCanvas\" style=\"max-height:" + (getIsMobile() ? 450 : 450) + "px\"></canvas>";
}

var chartJsPromise = null;
function ensureChartJs() {
    if (window.Chart) return Promise.resolve();
    if (!chartJsPromise) chartJsPromise = new Promise(function (resolve, reject) {
        var sc = document.createElement('script');
        sc.src = 'libs/Chart.bundle.js';
        sc.onload = resolve; sc.onerror = function () { chartJsPromise = null; reject(); };
        document.head.appendChild(sc);
    });
    return chartJsPromise;
}

function plotElevation(elevations) {
    ensureChartJs().then(function () { plotElevationNow(elevations); });
}

function plotElevationNow(elevations) {
    setTrackElevation(elevations);

    var chartDiv = document.getElementById('elevationChartDiv');
    //if (status !== 'OK') {
    //    // Show the error code inside the chartDiv.
    //    chartDiv.innerHTML = 'Cannot show elevation: request failed because ' +
    //        status;
    //    return;
    //}
    if (!chartDiv)
        return;

    chartDiv.innerHTML = "<canvas id=\"elevationChartCanvas\" style=\"max-height:" + (getIsMobile() ? 450 : 450) + "px\"></canvas>";
    var elevationChartCanvas = document.getElementById('elevationChartCanvas');

    var data = {
        labels: [],
        datasets: [
            {
                label: "Elevation",
                data: [],
            }
        ]
    };

    for (var i = 0; i < elevations.length; i++) {
        var label =
            (Math.round(elevations[i].location.lat() * 10000) / 10000).toString()
            + ", "
            + (Math.round(elevations[i].location.lng() * 10000) / 10000).toString();
        data.labels.push(label);
        data.datasets[0].data.push(Math.round(elevations[i].elevation));
    }

    myBarChart = new Chart(elevationChartCanvas, {
        type: 'bar',
        data: data,
        maintainAspectRatio: true,
        //responsive:true,
        options: {
            hover: {
                // Overrides the global setting
                mode: 'nearest'
            }
        }
    });

    // Create a new chart in the elevation_chart DIV.
    //var chart = new google.visualization.ColumnChart(chartDiv);

    // Extract the data from which to populate the chart.
    // Because the samples are equidistant, the 'Sample'
    // column here does double duty as distance along the
    // X axis.
    //var data = new google.visualization.DataTable();
    //data.addColumn('string', 'Sample');
    //data.addColumn('number', 'Elevation');
    //for (var i = 0; i < elevations.length; i++) {
    //    data.addRow(['', elevations[i].elevation]);
    //}

    //// Draw the chart using the data within its DIV.
    //chart.draw(data, {
    //    height: 150,
    //    legend: 'none',
    //    titleY: 'Elevation (m)'
    //});
}

function compactTrackData(trackData) {
    var result = [];
    var maxSize = 256;
    if (trackData.length <= maxSize)
        return trackData;

    for (var i = 0; i < maxSize; i++) {
        var j = Math.round(i * trackData.length / maxSize);
        result.push(trackData[j]);
    }
    return result;
}

//#region Photo hover preview
var dragMoved = false;
$(function () {
    var $preview = $('<div id="photoPreview"><img alt="" /><div class="pp-cap"></div></div>').css({
        position: 'fixed', display: 'none', zIndex: 5000, pointerEvents: 'none',
        background: '#fff', padding: '4px', border: '1px solid #888', borderRadius: '4px',
        boxShadow: '0 4px 16px rgba(0,0,0,0.5)'
    }).appendTo('body');
    var $previewImg = $preview.find('img').css({ display: 'block', maxWidth: '70vw', maxHeight: '60vh' });
    var $previewCap = $preview.find('.pp-cap');
    var lastTouch = 0, token = 0;
    function canHoverNow() { return !window.matchMedia || window.matchMedia('(hover: hover)').matches; }

    // The preview is only shown while the mouse is really over a photo; everything else hides it.
    window.hidePhotoPreview = function () { token++; $preview.hide(); };

    function place(e) {
        var w = $preview.outerWidth(), h = $preview.outerHeight();
        var left = Math.max(5, Math.min(e.clientX - w / 2, window.innerWidth - w - 5));
        var top = e.clientY - h - 20;
        if (top < 5)
            top = Math.min(e.clientY + 20, window.innerHeight - h - 5);
        $preview.css({ left: left, top: top });
    }

    $(document).on('touchstart pointerdown', function (e) {
        if (e.type === 'touchstart' || (e.originalEvent && e.originalEvent.pointerType && e.originalEvent.pointerType !== 'mouse')) lastTouch = Date.now();
        if (!$(e.target).closest('img.photo').length) window.hidePhotoPreview();
    });

    $(document).on('mouseenter', 'img.photo', function (e) {
        if (dragMoved || !canHoverNow() || Date.now() - lastTouch < 800) return;   // no hover preview on touch screens
        var src = this.getAttribute('data-full');
        if (!src)
            return;
        var my = ++token;
        $previewCap.text(this.getAttribute('data-credit') || '');
        $previewImg.off('load').one('load', function () { if (my === token) { place(e); $preview.show(); } });
        $previewImg.attr('src', src);
        if ($previewImg[0].complete)
            $previewImg.trigger('load');
    }).on('mouseleave', 'img.photo', function () {
        window.hidePhotoPreview();
    });

    // Safety nets: the photo under the mouse can disappear (strip reloads, scrolls) without a mouseleave.
    $(document).on('mousemove', function (e) {
        if (!$preview.is(':visible')) return;
        if ($(e.target).closest('img.photo').length) place(e); else window.hidePhotoPreview();
    });
    $(document).on('keydown', function (e) { if (e.key === 'Escape') window.hidePhotoPreview(); });
    $(document).on('mouseleave', 'html', window.hidePhotoPreview);
    $(window).on('blur scroll wheel resize', window.hidePhotoPreview);
    document.addEventListener('mouseout', function (e) { if (!e.relatedTarget) window.hidePhotoPreview(); });
    $('#imageDiv0 .innerScrollArea').on('scroll', function () {
        // the strip scrolls under a still mouse: re-check what is under it
        if (!$preview.is(':visible')) return;
        var el = document.elementFromPoint($preview.data('mx') || 0, $preview.data('my') || 0);
        if (!el || !$(el).closest('img.photo').length) window.hidePhotoPreview();
    });
    $(document).on('mousemove', function (e) { $preview.data({ mx: e.clientX, my: e.clientY }); });

    // Click opens the viewer (middle click / ctrl+click still open the source page)
    $(document).on('click', '#imageDiv0 a[data-index]', function (e) {
        if (e.ctrlKey || e.metaKey || e.shiftKey || e.which === 2) return;
        e.preventDefault();
        if (dragMoved) return;
        var li = $(this).closest('li')[0], list = stripViewerList();
        photoViewer.open(Math.max(0, list.indexOf(li && li._ph)), list);
    });
});

// Drag / swipe the strip by hand
$(function () {
    var el = document.querySelector('#imageDiv0 .innerScrollArea');
    if (!el) return;
    var down = false, startX = 0, startLeft = 0, pid = null;
    el.style.touchAction = 'pan-y';
    el.addEventListener('pointerdown', function (e) {
        if (e.button !== undefined && e.button !== 0) return;
        down = true; dragMoved = false; startX = e.clientX; startLeft = el.scrollLeft; pid = e.pointerId;
    });
    el.addEventListener('pointermove', function (e) {
        if (!down) return;
        var dx = e.clientX - startX;
        if (!dragMoved && Math.abs(dx) > 6) { dragMoved = true; $('#photoPreview').hide(); try { el.setPointerCapture(pid); } catch (x) { } }
        if (dragMoved) {
            el.scrollLeft = Math.max(0, startLeft - dx);
        }
    });
    function end() { down = false; setTimeout(function () { dragMoved = false; }, 0); }
    el.addEventListener('pointerup', end);
    el.addEventListener('pointercancel', end);
    el.addEventListener('wheel', function (e) {       // horizontal wheel / shift+wheel scrolls too
        var d = Math.abs(e.deltaX) > Math.abs(e.deltaY) ? e.deltaX : (e.shiftKey ? e.deltaY : 0);
        if (d) { el.scrollLeft += d; e.preventDefault(); }
    }, { passive: false });
});

// Resize the strip with a handle on its top edge: it stays at the bottom, full width, never taller than 60% of the window
$(function () {
    var $strip = $('#imageDiv0');
    if (!$strip.length) return;
    var MIN = 90, key = 'sytStripHeight';
    function maxH() { return Math.max(MIN, Math.min(560, Math.round(window.innerHeight * 0.6))); }
    function setH(h, save) {
        h = Math.max(MIN, Math.min(maxH(), Math.round(h)));
        $strip.css('height', h + 'px');
        $('#imageDiv').css('height', '100%');
        if (save) { try { localStorage.setItem(key, String(h)); } catch (e) { } }
        return h;
    }
    var saved = NaN; try { saved = parseInt(localStorage.getItem(key), 10); } catch (e) { }
    if (saved > 0) setH(saved, false);
    var $h = $('<div id="photoResize" title="' + T("ResizeStrip", "Drag to resize the photo strip") + '" role="separator" aria-orientation="horizontal"><span></span></div>').appendTo($strip);
    var startY = 0, startH = 0, active = false, timer = null;
    $h.on('pointerdown', function (e) {
        active = true; startY = e.clientY; startH = $strip.height(); window.hidePhotoPreview && window.hidePhotoPreview();
        try { this.setPointerCapture(e.pointerId); } catch (x) { } e.preventDefault(); $('body').addClass('resizingStrip');
    }).on('pointermove', function (e) {
        if (!active) return;
        pendingH = startH + (startY - e.clientY);
        if (!raf) raf = requestAnimationFrame(function () { raf = 0; applyLive(setH(pendingH, false)); });   // live, one update per frame
    }).on('pointerup pointercancel', function (e) {
        if (!active) return; active = false; $('body').removeClass('resizingStrip');
        applyLive(setH(pendingH != null ? pendingH : $strip.height(), true)); pendingH = null;
    });
    var raf = 0, pendingH = null;
    // resize the photos with the strip, keeping the same part of the strip in view
    function applyLive(h) {
        var oldH = stripH, left = scroller.scrollLeft(), items = stripItems(), base = items.length ? items[0]._left : 0;
        layoutStrip(h);
        if (oldH > 0 && h > 0) scroller.scrollLeft(base + (left - base) * h / oldH);
    }
    $(window).on('resize', function () {
        var h = $strip.height(); if (h > maxH()) { applyLive(setH(maxH(), false)); }
    });
});

// Re-layout the photos for the current strip height (photos are sized to the strip height when loaded)
function relayoutStrip() {
    if (lastStripArgs) get_photos_success(lastStripArgs.photos, lastStripArgs.p, lastStripArgs.tol, true);
}

// Show / hide handle for the strip
$(function () {
    var $strip = $('#imageDiv0');
    if (!$strip.length) return;
    var key = 'sytStripHidden';
    var $btn = $('<button type="button" id="photoToggle" aria-label="Show or hide photos"><span class="chev">▾</span> <span class="lbl i" data-i18n="Photos">Photos</span></button>').appendTo('body');
    function apply(hidden, animate) {
        $btn.toggleClass('collapsed', hidden).attr('aria-expanded', !hidden);
        if (animate) $strip.stop(true, true)[hidden ? 'slideUp' : 'slideDown'](200); else $strip.toggle(!hidden);
        try { localStorage.setItem(key, hidden ? '1' : '0'); } catch (e) { }
    }
    var hidden = false; try { hidden = localStorage.getItem(key) === '1'; } catch (e) { }
    if (hidden) apply(true, false);
    $btn.on('click', function () { apply(!$btn.hasClass('collapsed'), true); });
    if ($.fn.i18n) $btn.find('.i').i18n();
});
//#endregion

//#region Immediate execute
$(function () {
    onBodyResize();

    $.ajax({
        url: versionUrl,
        success: function (data) {
            var $hiddenInput = $('<input/>', { type: 'hidden', id: 'version', value: data });
            $hiddenInput.appendTo('form');
        },
        error: function (XMLHttpRequest, textStatus, errorThrown) {
            console.log("get version error: " + textStatus); console.log("Error: " + errorThrown);
        }
    });

    scroller = $('#imageDiv0 div.innerScrollArea');
    scrollerContent = scroller.children('ul');
    curX = 0;
    fullW = 1;

    // extracted...

    // Scrolling speed management
    var controller = { curSpeed: 0, fullSpeed: 2 };
    var $controller = $(controller);
    var tweenToNewSpeed = function (newSpeed, duration) {
        if (duration === undefined)
            duration = 600;
        $controller.stop(true).animate({ curSpeed: newSpeed }, duration);
    };

    // Pause on hover, so a photo can be looked at (and its enlarged preview stays put)
    scroller.hover(function () {
        tweenToNewSpeed(0, 250);
    }, function () {
        tweenToNewSpeed(controller.fullSpeed, 600);
    });

    // Scrolling management: frame-synced and time-based (the old 20ms timer moved in visible 2px steps)
    var scrollPos = 0, lastTime = null, scrollEl = scroller[0];
    var doScroll = function (time) {
        window.requestAnimationFrame(doScroll);
        if (lastTime === null)
            lastTime = time;
        var dt = Math.min(time - lastTime, 100);   // ms; capped so a background tab doesn't cause a jump
        lastTime = time;
        // nothing to do while the tab is in the background, the strip is hidden/empty or scrolling is off
        if (!scrollerEnabled || document.hidden || !fullW || !scrollEl.offsetParent) return;
        var cur = scrollEl.scrollLeft;
        if (Math.abs(cur - Math.round(scrollPos)) > 2)
            scrollPos = cur;   // something else moved it (drag, photos were reloaded)
        scrollPos += controller.curSpeed * dt / 20;   // curSpeed is "pixels per 20ms"
        if (time - lastStripTrim > 400) {             // keep the queue: photos ahead are added, photos long passed are removed
            lastStripTrim = time;
            ensureStripAhead();
            stripShifted = 0;
            trimStripPassed();
            if (stripShifted) { scrollPos -= stripShifted; cur = scrollEl.scrollLeft; }
        }
        var next = Math.round(scrollPos);
        if (next !== cur) scrollEl.scrollLeft = next;
    };
    window.requestAnimationFrame(doScroll);
    tweenToNewSpeed(controller.fullSpeed);
});
//#endregion ImmediateExecute

var tourSteps = [{
    "msg": "Welcome to See Your Travel. Let's take a simple tour!<br/>Click through the popups", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": "body", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "center", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
    "btnMsg": "Start Tour &raquo", // if you'd like a button on the dialog simply add a message here
    "nextSelector": "#tour_dialog_btn", // does the user need to do something specific to advance? For example, clicking the tour bubble ok button. Omit for any action click to advance.
    "waitForTrigger": false // should we pause the tour here? while the user does something? Pass a seletor as the trigger to resume the tour from this point
},
{
    "msg": "Choose your track", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": "#tracksList", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "bottom", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
},
{
    "msg": "Pause and resume the track, or press Space button", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": "#continuePauseButton ", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "left", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
}
    ,
{
    "msg": "Here you can mute and unmute the sound", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": "#mute", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "left", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
}
    ,
{
    get msg() { return window.sytTourMsg ? sytTourMsg('restart', "Restart the route from the beginning") : "Restart the route from the beginning"; },
    "actionName": false,
    "selector": "#restartButton",
    "position": "left",
}
    ,
{
    get msg() { return window.sytTourMsg ? sytTourMsg('d3', "3D flight: fly through the route with buildings, hills, photos and weather") : "3D flight: fly through the route with buildings, hills, photos and weather"; },
    "actionName": false,
    "selector": "#immersiveButton",
    "position": "left",
}
    ,
{
    get msg() { return window.sytTourMsg ? sytTourMsg('fs', "Fullscreen on and off") : "Fullscreen on and off"; },
    "actionName": false,
    "selector": "#fsButton",
    "position": "left",
}
    ,
{
    get msg() { return window.sytTourMsg ? sytTourMsg('help', "Help: short answers and this tour again") : "Help: short answers and this tour again"; },
    "actionName": false,
    "selector": "#helpButton",
    "position": "left",
}
    ,
{
    get msg() { return window.sytTourMsg ? sytTourMsg('seek', "Drag to jump to any place on the route") : "Drag to jump to any place on the route"; },
    "actionName": false,
    "selector": "#sytSeek",
    "position": "top",
}
    ,
{
    "msg": "Here you can choose the language for the site", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": "#langList", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "bottom", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
}
    ,
{
    "msg": "Sideseeings from where in a track you are now", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": "#imageDiv0", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "top", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
}
    ,
{
    "msg": "The main menu: login to edit and create your tracks", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": "#alogo", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "right", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
}
    ,
{
    "msg": "Scale the map in our out. Drag or swap to move", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": ".leaflet-control-zoom-out", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "left", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
}
    ,
{
    "msg": "Take this tour again, see track information, <br/>and discuss it with friends", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": "#imgComments", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "left", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
}
    ,
{
    "msg": "Share and save the track in Facebook, Twitter or Google", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": "#twitter-widget-0", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "top", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
}
    ,
{
    "msg": "Good luck!!", // tour bubble / dialog text
    "actionName": false, // name of Mixpanel event used for funnel analysis - spaces are fine, use friendly names. You'll need to setup MP yourself however and include the libs.
    "selector": "body", // selector for highlighted feature. Comma seperated list = (dialog target, additional items to pop above mask). Don't forget your '.' or '#'
    "position": "center", // dialog location in relation to target (selector). top, bottom, left, right, (or 'center' which centers to screen)
}





]



// Keep the map attribution/scale/zoom clear of the photo strip (it may be hidden, moved or resized).
// Only touches the page when the value really changed, and not at all in background tabs.
var lastStripH = -1;
setInterval(function () {
    if (document.hidden) return;
    var strip = document.getElementById('imageDiv0'), h = 0;
    if (strip && strip.offsetHeight > 0) {
        var r = strip.getBoundingClientRect();
        if (r.bottom > window.innerHeight - 40) h = Math.max(0, Math.round(window.innerHeight - r.top));
    }
    if (h !== lastStripH) {
        lastStripH = h;
        document.documentElement.style.setProperty('--syt-strip-h', h + 'px');
    }
}, 300);


//#region Position sharing (opt-in)
// Nobody's position is saved or shown unless the user switched sharing on; others' positions are only shown to users who share too.
$(function () {
    var $box = $('#shareLocationCheckBox'), $note = $('#shareLocationNote');
    if (!$box.length || typeof globalUserId === 'undefined' || !globalUserId) return;   // guests: stays disabled
    function reflect(on) {
        shareLocation = on;
        $box.prop('checked', on).prop('disabled', false).attr('title', '');
        $note.removeAttr('data-i18n').text(on ? T('ShareLocationOnNote', 'Your position (about 100 m accuracy) is visible to other users who share theirs. Turning this off deletes your saved positions.')
                      : T('ShareLocationOffNote', 'Off. Turn on to see other users who share, and to be seen by them (about 100 m accuracy, last hour only).'));
        if (!on && typeof markersFriends !== 'undefined') markersFriends.clearLayers();
    }
    $.getJSON('services/user_locations.aspx?action=getsharing&callback=?').done(function (d) {
        reflect(!!d.enabled);
        if (d.enabled) { locationTimer = null; lastSent = { t: 0, pos: null }; showLocation(); }
    });
    $box.on('change', function () {
        var want = this.checked;
        if (want && !confirm(T('ShareLocationConfirm', 'Share your position with other users who also share theirs?\n\n- Only your last position of the past hour is shown, rounded to about 100 m, with your user name.\n- Others can only see you if they share their own position.\n- You can switch it off at any time; this deletes your saved positions.')))
        {
            this.checked = false; return;
        }
        $box.prop('disabled', true);
        $.ajax({ type: 'POST', url: 'services/user_locations.aspx?action=setsharing', data: { enabled: want ? 1 : 0 }, dataType: 'text' })
            .done(function () { reflect(want); if (want) { locationTimer = null; lastSent = { t: 0, pos: null }; showLocation(); } })
            .fail(function () { reflect(!want); toastr.error(T('ShareLocationError', 'Could not change the setting. Please try again.')); });
    });
});
//#endregion


//#region Track name box
// The track list (top left) adapts to the selected name: it gets as wide as the name needs (but leaves room for the menu button and
// the language list); a name that is still too long is shown in a smaller font, then cut with "..." - the full name is the tooltip.
(function () {
    var ctx = document.createElement('canvas').getContext('2d');
    function fit() {
        var sel = document.getElementById('tracksList');
        if (!sel) return;
        var opt = sel.options[sel.selectedIndex];
        var text = opt ? opt.text : '';
        sel.title = text;
        var maxW = Math.max(150, window.innerWidth - 42 - 140);   // menu button on the left, language list on the right
        var family = getComputedStyle(sel).fontFamily, size = 14;
        function width(px) { ctx.font = px + 'px ' + family; return ctx.measureText(text).width + 52; }   // padding + arrow
        while (size > 11 && width(size) > maxW) size--;
        sel.style.fontSize = size + 'px';
        sel.style.width = Math.round(Math.min(maxW, Math.max(150, width(size)))) + 'px';
        // still too long for the box: show the full name under it (wrapped, with a light halo so it reads on the map)
        var cap = document.getElementById('trackNameFull');
        if (!cap) {
            cap = document.createElement('div'); cap.id = 'trackNameFull';
            sel.parentNode.appendChild(cap);
        }
        var cut = width(size) > maxW;
        cap.textContent = cut ? text : '';
        cap.style.display = cut ? 'block' : 'none';
        cap.style.maxWidth = Math.round(maxW) + 'px';
    }
    var last = null;
    $(function () {
        setInterval(function () {      // the selection is also set by script (no change event), so look for changes
            var sel = document.getElementById('tracksList');
            if (!sel || !sel.options) return;
            var now = sel.selectedIndex + '|' + sel.options.length + '|' + window.innerWidth;
            if (now !== last) { last = now; fit(); }
        }, 400);
        $(document).on('change', '#tracksList', fit);
    });
})();
//#endregion


//#region Track search
// The track list (top left) opens as a small panel with a search box on top instead of the plain browser list.
// The <select> stays the source of the entries and of the chosen track; a choice is passed on as an ordinary change.
(function () {
    function norm(t) { return String(t || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, ''); }
    var panel = null;

    function close() {
        if (!panel) return;
        $(document).off('.trackSearch');
        panel.remove();
        panel = null;
    }

    function open(sel) {
        if (panel) { close(); return; }
        var groups = [], cur = null;
        $.each(sel.children, function (i, el) {
            if (el.tagName === 'OPTGROUP') {
                cur = { label: el.label, items: [] };
                groups.push(cur);
                $.each(el.children, function (j, o) { cur.items.push({ value: o.value, text: o.text }); });
            } else if (el.tagName === 'OPTION' && i > 0) {   // entry 0 is "Choose a track"; the page adds the tracks after their category label
                if (!cur) { cur = { label: '', items: [] }; groups.push(cur); }
                cur.items.push({ value: el.value, text: el.text });
            }
        });
        var r = sel.getBoundingClientRect();
        panel = $('<div id="trackSearch" role="dialog"></div>').css({ left: Math.max(6, r.left), top: r.bottom + 4, width: Math.max(r.width, 300) });
        var input = $('<input type="search" class="ts-q" autocomplete="off" spellcheck="false">')
            .attr('placeholder', T('SearchTracks', 'Search tracks\u2026')).attr('aria-label', T('SearchTracks', 'Search tracks\u2026'));
        var list = $('<div class="ts-list" role="listbox"></div>');
        var hint = $('<div class="ts-hint"></div>').append('<i class="fa fa-magic"></i> ').append($('<span></span>').text(T('TrackSearchHint', 'Search by name, or describe what you look for, e.g. \u201ctracks in Italy with churches\u201d. ') + T('AiSearchNote', 'AI-based search: it can make mistakes, so check the results.')));
        var closeBtn = $('<button type="button" class="ts-x"></button>').html('&times;').attr('title', T('Close', 'Close')).attr('aria-label', T('Close', 'Close')).on('click', function () { close(); sel.focus(); });
        panel.append($('<div class="ts-head"></div>').append(input).append(closeBtn)).append(hint).append(list).appendTo('body');
        panel.css('max-height', Math.max(200, window.innerHeight - r.bottom - 16));
        var active = -1;

        // tracks that pass photos which look like the words (AI-based photo search); shown under the name matches
        var aiBox = $('<div class="ts-ai" style="display:none"></div>'), aiTimer = null, aiSeq = 0;
        function aiPhotoUrl(f) { return 'services/get_thumbnail.aspx?size=small&p=' + encodeURIComponent(f); }
        function aiShow(d, ask) {
            aiBox.empty();
            var head = $('<div class="ts-aihead"></div>').append('<i class="fa fa-magic"></i> ').append($('<span></span>').text(T('TracksByPhotos', 'Tracks with matching photos')));
            $('<button type="button" class="ts-ask"></button>').html('<i class="fa fa-comment-o"></i> ' + $('<div>').text(T('AskAi', 'Ask AI')).html()).appendTo(head);
            aiBox.append(head);
            var res = (d && d.tracks) || [];
            aiBox.append($('<div class="ts-ainote"></div>').text(T('AiSearchNote', 'AI-based search: it can make mistakes, so check the results.')));
            if (d && d.say) aiBox.append($('<div class="ts-say"></div>').text(d.say));
            if (d && d.error) aiBox.append($('<div class="ts-none"></div>').text(d.error === 'not signed in' ? T('SignInToAsk', 'Sign in to ask the assistant.') : T('AssistOff', 'The assistant is not available; searched by words instead.')));
            res.forEach(function (t) {
                var row = $('<div class="ts-item ts-aiitem" role="option"></div>').attr('data-v', t.file);
                row.append($('<div class="ts-aitt"></div>').text(t.desc).append(t.n ? $('<span class="ts-n"></span>').text(' \u00b7 ' + t.n + ' ' + T('Photos', 'photos').toLowerCase()) : ''));
                if (t.photos && t.photos.length) row.append($('<div class="ts-th"></div>').append(t.photos.map(function (f) { return $('<img alt="" loading="lazy">').attr('src', aiPhotoUrl(f))[0]; })));
                aiBox.append(row);
            });
            if (ask && !res.length && d && !d.error) aiBox.append($('<div class="ts-none"></div>').text(T('NoTracksFound', 'No tracks found')));
            aiBox.show();
        }
        function aiRun(ask) {
            var q = $.trim(input.val()), my = ++aiSeq;
            if (q.length < 3) { aiBox.hide().empty(); return; }
            if (ask) aiBox.find('.ts-ask').prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i>');   // the assistant takes a few seconds
            $.getJSON('services/track_search.aspx', { q: q, ask: ask ? 1 : 0, locale: (window.i18next && i18next.language) || '' })
                .done(function (d) { if (my === aiSeq) aiShow(d, ask); })
                .fail(function (x) { if (my === aiSeq) aiShow({ tracks: [], error: x.status === 403 ? 'not signed in' : 'off' }, ask); });
        }
        aiBox.on('click', '.ts-ask', function (e) { e.stopPropagation(); aiRun(true); });

        function render() {
            var q = norm(input.val()).split(/\s+/).filter(Boolean), shown = 0, html = '';
            aiBox.detach();
            list.empty();
            groups.forEach(function (g) {
                var cat = norm(g.label);
                var items = g.items.filter(function (it) {
                    var hay = norm(it.text) + ' ' + cat;
                    return q.every(function (w) { return hay.indexOf(w) >= 0; });
                });
                if (!items.length) return;
                if (g.label) list.append($('<div class="ts-cat"></div>').text(g.label));
                items.forEach(function (it) {
                    shown++;
                    $('<div class="ts-item" role="option"></div>').text(it.text).attr('data-v', it.value)
                        .toggleClass('sel', it.value === sel.value).appendTo(list);
                });
            });
            if (!shown) list.append($('<div class="ts-none"></div>').text(T('NoTracksFound', 'No tracks found')));
            list.append(aiBox);
            active = q.length && shown ? 0 : -1;
            mark();
        }
        function mark(scroll) {
            var items = list.children('.ts-item').removeClass('act');
            if (active >= 0 && items.length) {
                var el = items.eq(active).addClass('act')[0];
                if (scroll !== false && el.scrollIntoView) el.scrollIntoView({ block: 'nearest' });
            }
        }
        function choose(v) {
            close();
            if (v == null || v === sel.value) return;
            sel.value = v;
            sel.dispatchEvent(new Event('change', { bubbles: true }));
        }

        input.on('input', function () {
            render();
            hint.toggle(!$.trim(input.val()));
            clearTimeout(aiTimer); aiSeq++;
            if ($.trim(input.val()).length < 3) { aiBox.hide().empty(); return; }
            aiShow(null, false);   // the "Ask AI" button is there at once; matching tracks follow
            aiTimer = setTimeout(function () { aiRun(false); }, 500);
        }).on('keydown', function (e) {
            var n = list.children('.ts-item').length;
            if (e.key === 'ArrowDown') { active = Math.min(n - 1, active + 1); mark(); e.preventDefault(); }
            else if (e.key === 'ArrowUp') { active = Math.max(0, active - 1); mark(); e.preventDefault(); }
            else if (e.key === 'Enter') { var el = list.children('.ts-item').eq(Math.max(active, 0)); if (el.length) choose(el.attr('data-v')); else if ($.trim(input.val()).length >= 3) { clearTimeout(aiTimer); aiRun(true); } e.preventDefault(); }   // no track has that name: ask the assistant
            else if (e.key === 'Escape') { close(); sel.focus(); }
        });
        list.on('click', '.ts-item', function () { choose($(this).attr('data-v')); });
        $(document).on('mousedown.trackSearch touchstart.trackSearch', function (e) {
            if (!$(e.target).closest('#trackSearch, #tracksList').length) close();
        }).on('keydown.trackSearch', function (e) { if (e.key === 'Escape') close(); });
        render();
        var cur = list.find('.ts-item.sel')[0];
        if (cur && cur.scrollIntoView) cur.scrollIntoView({ block: 'center' });
        input.focus();
    }

    $(function () {
        var sel = document.getElementById('tracksList');
        if (!sel) return;
        $(sel).on('mousedown click', function (e) { e.preventDefault(); if (e.type === 'mousedown') { sel.focus(); open(sel); } })
            .on('keydown', function (e) {
                if (e.key === ' ' || e.key === 'Enter' || e.key === 'ArrowDown' || e.key === 'ArrowUp') { e.preventDefault(); open(sel); }
            });
    });
})();
//#endregion


//#region Track properties (Track tab of the information panel)
function trackDistanceMeters(t) {
    if (t._distance != null) return t._distance;
    var d = t.trackData || [], sum = 0, prev = null;
    for (var i = 0; i < d.length; i++) {
        var p = pointToLatLng(d[i]);
        if (prev) sum += prev.distanceTo(p);
        prev = p;
    }
    return (t._distance = sum);
}

function formatDuration(sec) {
    sec = Math.round(sec);
    if (sec < 60) return sec + " " + T("iseconds", "seconds");
    var m = Math.round(sec / 60);
    if (m < 60) return m + " " + T("iminutes", "minutes");
    var h = Math.floor(m / 60); m = m % 60;
    if (h < 48) return h + " " + T("ihours", "hours") + (m ? " " + m + " " + T("iminutes", "minutes") : "");
    return Math.round(h / 24) + " " + T("idays", "days");
}

function formatDistance(meters) {
    var km = T("UnitKm", "km");
    if (meters < 1000) return Math.round(meters) + " " + T("UnitM", "m");
    return (meters < 100000 ? (meters / 1000).toFixed(1) : Math.round(meters / 1000).toLocaleString()) + " " + km;
}

// elevations come from plotElevation (samples along the route)
function setTrackElevation(elevations) {
    if (typeof track == "undefined" || !track || !elevations.length) return;
    var min = Infinity, max = -Infinity, up = 0, down = 0, prev = null;
    elevations.forEach(function (e) {
        var h = Math.round(e.elevation);
        if (isFinite(h)) {
            min = Math.min(min, h); max = Math.max(max, h);
            if (prev !== null) { if (h > prev) up += h - prev; else down += prev - h; }
            prev = h;
        }
    });
    if (min === Infinity) return;
    track._elev = { min: min, max: max, up: up, down: down };
    try { track._elevProf = elevations.map(function (e) { return { lat: e.location.lat(), lng: e.location.lng(), m: Math.round(e.elevation) }; }); } catch (e) { }   // the profile behind the numbers, for the chat assistant
    updateTrackStats();
}

function placeNameOf(p) {
    return new Promise(function (resolve) {
        syt.api.throttle("nominatim|rev|" + p.lat.toFixed(2) + "|" + p.lng.toFixed(2) + "|" + getTwitterLanguage(), {
            dataType: "json",
            url: "https://nominatim.openstreetmap.org/reverse",
            data: { lat: p.lat, lon: p.lng, zoom: 10, format: "json", "accept-language": getTwitterLanguage() }
        }, function (d) {
            var a = (d && d.address) || {};
            var n = a.city || a.town || a.village || a.municipality || a.suburb || a.county || "";
            return { name: [n, a.country].filter(Boolean).join(", ") };
        }).then(function (r) { resolve(r.__empty ? "" : r.name); });
    });
}

function updateTrackStats() {
    var $box = $("#trackStats");
    if (!$box.length) return;
    if (typeof track == "undefined" || !track || !track.trackData || !track.trackData.length) {
        $box.html('<p class="ts-empty">' + $("<div>").text(T("NoTrackLoaded", "Choose a track to see its details.")).html() + "</p>");
        return;
    }
    var esc = function (t) { return $("<div>").text(t == null ? "" : String(t)).html(); };
    var dist = trackDistanceMeters(track), speed = getSpeedMps();
    var items = [];
    function add(label, value, wide) { if (value !== "" && value != null) items.push('<div class="ts-item' + (wide ? ' wide' : '') + '"><span class="ts-label">' + esc(label) + '</span><span class="ts-value">' + value + "</span></div>"); }

    var m = T("UnitM", "m");
    add(T("StatDistance", "Distance"), esc(formatDistance(dist)));
    add(T("StatPlayback", "Playback time at current speed"), esc(formatDuration(dist / speed)));
    if (track._elev) {
        add(T("StatHighest", "Highest point"), esc(track._elev.max + " " + m));
        add(T("StatLowest", "Lowest point"), esc(track._elev.min + " " + m));
        add(T("StatAscent", "Total ascent"), "↗ " + esc(track._elev.up + " " + m));
        add(T("StatDescent", "Total descent"), "↘ " + esc(track._elev.down + " " + m));
    }
    var first = pointToLatLng(track.trackData[0]), last = pointToLatLng(track.trackData[track.trackData.length - 1]);
    add(T("StatStart", "Start"), esc(track.startName || track._startName || first.lat.toFixed(4) + ", " + first.lng.toFixed(4)), true);
    add(T("StatFinish", "Finish"), esc(track.endName || track._endName || last.lat.toFixed(4) + ", " + last.lng.toFixed(4)), true);
    add(T("StatPoints", "Track points"), esc(track.trackData.length.toLocaleString()));
    if (track.category) add(T("StatCategory", "Category"), esc(T(track.category, track.category)));
    if (track.travelWith) add(T("StatTravelWith", "Travel with"), esc(track.travelWith));
    add(T("StatVisibility", "Visibility"), esc(track.isPublic == "No" ? T("StatPrivate", "Private") : T("StatPublic", "Public")));
    if (track.copyright && track.copyright !== "(c)") add(T("StatCopyright", "Copyright"), esc(track.copyright), true);

    var title = track.name ? '<h3 class="ts-title">' + esc(track.name) + "</h3>" : "";
    title += '<div id="tsLive" class="ts-live"></div>';
    var desc = "";
    if (track._descHtml && $("#scriptTextCheckBox").is(":checked"))
        desc = '<div class="ts-desc"><h4 class="ts-desc-title">' + esc(T("Description", "Description")) + '</h4><div class="ts-desc-text">' + track._descHtml + "</div></div>";
    var note = track._elev ? '<p class="ts-note">' + esc(T("StatElevationNote", "Elevations are estimated from a terrain model along the route.")) + "</p>" : "";
    $box.html(title + '<div class="ts-grid">' + items.join("") + "</div>" + desc + note);

    // names of the start and finish places (once per track)
    updateLiveStats();
    if (!track._namesRequested && !(track.startName && track.endName)) {
        track._namesRequested = true;
        var t = track;
        placeNameOf(first).then(function (n) { t._startName = n; if (t === track) updateTrackStats(); });
        placeNameOf(last).then(function (n) { t._endName = n; if (t === track) updateTrackStats(); });
    }
}
window.updateTrackStats = updateTrackStats;

// where the marker is now: distance and time done and left, coordinates (refreshed every second while the Info tab is open)
function trackProgress() {
    var am = window.animatedMarker, t = window.track;
    if (!am || !t || !t.trackData || !t.trackData.length || !am._latlngs) return null;
    var pts = am._latlngs;
    if (!t._cum || t._cum.length !== pts.length) {
        var c = [0];
        for (var i = 1; i < pts.length; i++) c.push(c[i - 1] + pts[i - 1].distanceTo(pts[i]));
        t._cum = c;
    }
    var cum = t._cum, total = cum[cum.length - 1], ti = Math.min(Math.max((am._i || 1) - 1, 0), pts.length - 1), pos = pts[ti], done = cum[ti], seg = am._seg;
    if (seg) {
        var f = seg.dur > 0 ? Math.min(1, Math.max(0, (Date.now() - seg.start) / seg.dur)) : 1;
        pos = new L.LatLng(seg.from.lat + f * (seg.to.lat - seg.from.lat), seg.from.lng + f * (seg.to.lng - seg.from.lng));
        done = Math.max(0, cum[ti] - pos.distanceTo(seg.to));
    }
    return { pos: pos, done: done, left: Math.max(0, total - done), total: total };
}

function formatClock(sec) {   // h:mm:ss, so that the value visibly runs every second
    sec = Math.max(0, Math.round(sec));
    var h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60), x = sec % 60;
    if (h >= 48) return formatDuration(sec);
    return (h ? h + ":" + ("0" + m).slice(-2) : m) + ":" + ("0" + x).slice(-2);
}

function updateLiveStats() {
    var box = document.getElementById("tsLive");
    if (!box) return;
    var pr = trackProgress();
    if (!pr) { box.innerHTML = ""; return; }
    var speed = getSpeedMps(), pct = pr.total > 0 ? Math.round(pr.done / pr.total * 100) : 0;
    var esc = function (x) { return $("<div>").text(x).html(); };
    function cell(l, v) { return '<div class="ts-item"><span class="ts-label">' + esc(l) + '</span><span class="ts-value">' + esc(v) + "</span></div>"; }
    box.innerHTML = '<div class="ts-progress"><i style="width:' + pct + '%"></i><span>' + pct + ' %</span></div><div class="ts-grid">' +
        cell(T("StatDone", "Done"), formatDistance(pr.done) + " · " + formatClock(pr.done / speed)) +
        cell(T("StatLeft", "Remaining"), formatDistance(pr.left) + " · " + formatClock(pr.left / speed)) +
        '<div class="ts-item wide"><span class="ts-label">' + esc(T("StatPosition", "Current position")) + '</span><span class="ts-value">' +
        pr.pos.lat.toFixed(5) + ", " + pr.pos.lng.toFixed(5) + "</span></div></div>";
}
setInterval(function () {
    if (document.hidden) return;
    var tab = document.getElementById("tab-info");
    if (tab && tab.offsetParent !== null) updateLiveStats();
}, 1000);
//#endregion


//#region Chat context
// What the chat assistant is told about the screen: the track on the map, where the marker and the map are, the photos in the strip. Plain data, read when a question is sent.
// elevation is only asked for when the Track panel is open; the assistant needs it whenever it is asked, so it is fetched on demand (waits at most 4 s)
window.sytChatPrepare = function () {
    var d = $.Deferred();
    try {
        var t = window.track;
        if (t && t.trackData && t.trackData.length && !t._elev && !t._elevAsked && window.google && google.maps && google.maps.ElevationService) {
            t._elevAsked = true;
            new google.maps.ElevationService().getElevationAlongPath({ path: compactTrackData(t.trackData), samples: 128 }, function (el, status) {
                try { if (el && el.length) setTrackElevation(el); else t._elevStatus = String(status); } catch (e) { }
                d.resolve();
            });
            setTimeout(function () { d.resolve(); }, 4000);
        } else d.resolve();
    } catch (e) { d.resolve(); }
    return d.promise();
};

window.sytChatContext = function () {
    var c = { page: 'map' };
    function ll(p) { return p ? { lat: +(+p.lat).toFixed(5), lng: +(+p.lng).toFixed(5) } : null; }
    try {
        var t = window.track;
        if (t && t.trackData && t.trackData.length) {
            var first = pointToLatLng(t.trackData[0]), last = pointToLatLng(t.trackData[t.trackData.length - 1]);
            c.track = { name: t.name, category: t.category || '', travel_with: t.travelWith || '', start_name: t.startName || t._startName || '', end_name: t.endName || t._endName || '',
                        length_km: +(trackDistanceMeters(t) / 1000).toFixed(1), start: ll(first), end: ll(last) };
            var pr = trackProgress();
            if (pr) c.track_marker_now = { position: ll(pr.pos), done_km: +(pr.done / 1000).toFixed(1), left_km: +(pr.left / 1000).toFixed(1), percent_done: pr.total > 0 ? Math.round(pr.done / pr.total * 100) : 0 };
        } else c.track = null;
        if (window.map) { var m = map.getCenter(); c.map_centre = ll(m); c.map_zoom = map.getZoom(); }
        if (window.markerWhereIAm) { var g = markerWhereIAm.getLatLng(); if (g && Math.abs(g.lat) <= 90) c.my_gps_position = ll(g); }
        // elevation: the numbers of the Track tab and the profile along the route (distance from the start, height), thinned to about 24 points
        if (t && t._elev) {
            var el = { lowest_m: t._elev.min, highest_m: t._elev.max, total_climb_m: t._elev.up, total_descent_m: t._elev.down };
            var pf = t._elevProf;
            if (pf && pf.length > 1) {
                var cum = [0]; for (var q = 1; q < pf.length; q++) cum.push(cum[q - 1] + L.latLng(pf[q - 1].lat, pf[q - 1].lng).distanceTo([pf[q].lat, pf[q].lng]));
                var hi = 0, lo = 0; pf.forEach(function (p, i) { if (p.m > pf[hi].m) hi = i; if (p.m < pf[lo].m) lo = i; });
                el.highest_point_at_km = +(cum[hi] / 1000).toFixed(1); el.lowest_point_at_km = +(cum[lo] / 1000).toFixed(1);
                var n = Math.min(24, pf.length), prof = [];
                for (var k = 0; k < n; k++) { var ix = Math.round(k * (pf.length - 1) / (n - 1)); prof.push({ km: +(cum[ix] / 1000).toFixed(1), m: pf[ix].m }); }
                el.profile_km_and_height_m = prof;
                if (c.track_marker_now) {
                    var mp = c.track_marker_now.position, bi = 0, bd = Infinity;
                    pf.forEach(function (p, i) { var d = L.latLng(p.lat, p.lng).distanceTo([mp.lat, mp.lng]); if (d < bd) { bd = d; bi = i; } });
                    el.elevation_at_marker_m = pf[bi].m;
                }
            }
            c.elevation = el;
        } else if (t) c.elevation = { status: t._elevStatus ? 'the elevation service gave no data (' + t._elevStatus + ')' : 'not loaded' };
        // what the information panel and the map show: track properties, weather labels and places (Wikipedia, user and Google places) inside the visible map
        try { if (window.updateTrackStats) window.updateTrackStats(); } catch (e) { }   // the Track tab is only filled when it is needed: fill it now
        var props = $('#trackStats').text().replace(/\s+/g, ' ').trim();
        if (props) c.track_properties_panel = props.slice(0, 1200);
        if (t) c.track_settings = { photos_to_show: t.numOfPhotos, photo_distance_tolerance: t.photoLocationTolerancy, speed_m_per_s: t.velocityMetersPerSec, default_zoom: t.defaultScale, copyright: t.copyright || '', has_audio: !!t.audioSrc };
        if (window.map) {
            var bb = map.getBounds();
            c.weather_on_map = (window.sytSeenWeather || []).filter(function (w) { return bb.contains([w.lat, w.lng]); }).slice(-8);
            c.places_on_map = Object.keys(window.sytSeenPlaces || {}).map(function (k) { return window.sytSeenPlaces[k]; })
                .filter(function (p) { return bb.contains([p.lat, p.lng]); }).slice(0, 30).map(function (p) { return { name: p.name, source: p.source, description: p.description }; });
        }
        // the photos in the strip: how many, and the ones that are on screen right now (title, author, own or public, who is on it, where it was taken)
        var imgs = $('#imageDiv img.photo'), area = document.querySelector('#imageDiv0 .innerScrollArea'), shown = [];
        try {
            stripItems().forEach(function (li) {
                var ph = li._ph; if (!ph || shown.length >= 15) return;
                if (area && !(li._left + li._w > area.scrollLeft && li._left < area.scrollLeft + area.clientWidth)) return;
                var lat = ph.latitude != null ? ph.latitude : ph.lat, lng = ph.longitude != null ? ph.longitude : ph.lng;
                shown.push({ title: (ph.photo_title && ph.photo_title !== 'TBD') ? String(ph.photo_title).slice(0, 80) : '', author: String(ph.owner_name || '').slice(0, 40),
                             source: ph.source === 'own' ? (ph.syt_public === false ? "the person's own photo (private)" : "the person's own photo (public)") : 'public photo from Wikimedia Commons',
                             people: ph.people && ph.people.length ? ph.people : undefined, lat: lat != null ? +(+lat).toFixed(3) : undefined, lng: lng != null ? +(+lng).toFixed(3) : undefined });
            });
        } catch (e) { }
        c.photo_strip = { count: imgs.length, on_screen_now: shown };
    } catch (e) { }
    return c;
};
//#endregion
