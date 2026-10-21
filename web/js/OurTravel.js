
//#region Variables
var ATTRIBUTION = 'SeeYourTravel.app &copy; Map data &copy; <a target="_blank" href= "http://openstreetmap.org" > OpenStreetMap</a >, <a target="_blank" href= "http://creativecommons.org/licenses/by-sa/2.0/" > CC - BY - SA</a >, Imagery © <a target="_blank" href= "http://flickr.com" > Flickr</a>; Powered by <a target="_blank" href="https://darksky.net/poweredby/">DarkSky</a> <img src="img/poweredbygoolge/desktop/powered-by-google-on-white.png" />';
var tracksFolder = 'tracks/';
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
var viewportW;
var myBarChart = null;

var versionUrl = "services/get_version.aspx";

var iconWhereIAm = L.icon({
    iconUrl: ("img/youarehere.png"),
    iconSize: [30, 50],
    iconAnchor: [15, 50],
    //shadowUrl: null
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

function loadTrackOnPageLoad() {
    //if (trackParam) {
    init(trackParam,
        function () {
            toastr.warning("Let's go!", "", { timeOut: 2000, extendedTimeOut: 3000 });
            setTimeout(doStartStop, 2000);
        });
    //}
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
    $('#menuPanel').toggle('slide', 500);
}

function search($input) {
    var service = new google.maps.Geocoder();
    service.geocode({ 'address': $input.val() }, function (results, status) {
        if (status === 'OK') {
            map.panTo(new L.LatLng(results[0].geometry.location.lat(), results[0].geometry.location.lng()));
        } else {
            toastr.error('Geocode was not successful for the following reason: ' + status);
        }
    });
    event.stopPropagation();
}

function onBodyResize() {
    if ($("#map").length) {
        $("#map").height(window.innerHeight);
    }
    if ($("#menuPanel").length) {
        $("#menuPanel").height(window.innerHeight - 100);
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

function showLocation() {
    //    console.log("before getting location");
    if (navigator.geolocation) {
        var options = {
            enableHighAccuracy: true,
            timeout: 5000,
            maximumAge: 300000
        };
        navigator.geolocation.getCurrentPosition(showPosition, errorPosition, options);
        setTimeout(arguments.callee, 60000);
    } else {
        console.log("Geolocation is not supported by this browser");
    }
}
function errorPosition(err) {
    console.warn('Cannot get position(' + err.code + '): ' + err.message);
};
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

        if (typeof track == "undefined")
            map.setView(newLatLng, 8);

        //console.log(window.navigator.standalone);
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
    if (typeof animatedMarker != "undefined")
    {
        animatedMarker.options.distance = getSpeedMps();
        animatedMarker.changeSpeed();
    }
}

// Without a saved setting, start at the track's own speed.
function applyDefaultSpeed(track) {
    if (parseFloat($.cookie("settings_speedKmh")) >= MIN_SPEED_KMH) return;
    changeSpeed(Math.round(track.velocityMetersPerSec * 3.6 / 5) * 5);
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
                toastr.info("Click anywhere on the page to enable the music", "", { timeOut: 5000 });
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
        $('#continuePauseButton').removeAttr('disabled');
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
        $('#continuePauseButton').attr('disabled', 'disabled');
    }
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

// Size every photo to the strip height and place them side by side (cheap: no reloading, used live while resizing)
function layoutStrip(h) {
    var x = 0;
    scrollerContent.children().each(function () {
        var img = this.getElementsByTagName("img")[0];
        if (!img) return;
        var ar = parseFloat(img.getAttribute("data-ar")) || (img.width / img.height) || 1.5;
        var w = Math.round(ar * h);
        img.style.width = w + "px"; img.style.height = h + "px";
        img.width = w; img.height = h;
        this.style.left = x + "px";
        x += w;
    });
    curX = x;
    fullW = x / 2;
}

var lastStripArgs = null;
function get_photos_success(photos, p, tolerancy) {
    lastStripArgs = { photos: photos, p: p, tol: tolerancy };
    if (window.hidePhotoPreview) window.hidePhotoPreview();
    var divHeight = $("#imageDiv").height();

    photos = arrangePhotos(photos);
    stripPhotos = photos;
    count = photos.length;
    $("#lblCoord").text(p.lat + " " + p.lng);
    var imageUl = imageDiv.children();
    imageUl.fadeOut(100);
    imageUl.empty();
    $("#photoEmpty").remove();
    for (var i = 0; i < photos.length; i++) {
        var ph = photos[i];
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
        var full = ph.source === "own" && /^\.?\/?data\/images\//.test(ph.photo_url) ? ph.photo_url : (ph.big_url || ph.photo_file_url);
        nextImage.setAttribute("data-full", full);
        nextImage.setAttribute("data-credit", photoCredit(ph));
        nextLink.appendChild(nextImage);
        nextLi.appendChild(nextLink);
        var badge = document.createElement("span");
        badge.className = "photoBadge " + (ph.source === "own" ? "own" : "pub");
        badge.textContent = ph.source === "own" ? "📍" : "🌍";
        badge.title = ph.source === "own" ? "Photo taken here" : "Public photo (Wikimedia Commons)";
        nextLi.appendChild(badge);

        imageUl[0].appendChild(nextLi);
    }

    if (!photos.length) {
        $('<div id="photoEmpty"></div>').text($.t("No photos here yet")).appendTo(scroller);
    }

    scrollerContent.children().clone().appendTo(scrollerContent);
    layoutStrip(divHeight);
    viewportW = scroller.width();
    imageUl.fadeIn(100);
}

//#region Photo viewer
var photoViewer = (function () {
    var $v, $img, $cap, idx = 0, open = false;

    function build() {
        $v = $(
            '<div id="photoViewer" role="dialog" aria-modal="true" aria-label="Photo viewer">' +
            '<button type="button" class="pv-btn pv-close" aria-label="Close" title="Close (Esc)">×</button>' +
            '<button type="button" class="pv-btn pv-prev" aria-label="Previous" title="Previous (←)">‹</button>' +
            '<button type="button" class="pv-btn pv-next" aria-label="Next" title="Next (→)">›</button>' +
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
        var ph = stripPhotos[idx];
        if (!ph) return;
        var full = ph.source === "own" && /^\.?\/?data\/images\//.test(ph.photo_url) ? ph.photo_url : (ph.big_url || ph.photo_file_url);
        $img.attr('src', ph.photo_file_url);                         // instantly show the strip thumbnail ...
        var big = new Image();
        big.onload = function () { if (stripPhotos[idx] === ph) $img.attr('src', full); };   // ... then the large one
        big.src = full;
        var title = ph.photo_title && ph.photo_title !== "TBD" ? ph.photo_title.replace(/\.[a-z]{3,4}$/i, "") : "";
        var html = (title ? '<strong>' + esc(title) + '</strong><br>' : '') + esc(photoCredit(ph));
        if (ph.source === "commons") {
            if (ph.license_url) html = html.replace(esc(ph.license), '<a href="' + esc(ph.license_url) + '" target="_blank" rel="noopener">' + esc(ph.license) + '</a>');
            html += ' · <a href="' + esc(ph.photo_url) + '" target="_blank" rel="noopener">Source: Wikimedia Commons</a>';
        }
        if (typeof ph.latitude === "number" && typeof ph.longitude === "number" && typeof map !== "undefined")
            html += ' · <a href="#" class="pv-map">Show on map</a>';
        html += '<span class="pv-count">' + (idx + 1) + ' / ' + stripPhotos.length + '</span>';
        $cap.html(html);
        $cap.find('.pv-map').on('click', function (e) {
            e.preventDefault(); close();
            map.setView([ph.latitude, ph.longitude], Math.max(map.getZoom(), 14));
        });
    }

    function go(d) { if (!stripPhotos.length) return; idx = (idx + d + stripPhotos.length) % stripPhotos.length; show(); }
    function close() { open = false; if ($v) $v.removeClass('open'); setTimeout(function () { if (!open && $v) $v.hide(); }, 180); }
    return {
        open: function (i) {
            if (!$v) build();
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
            var tempTrack = data;
            if (tempTrack.trackGpx) {
                tempTrack.trackData = $.parseJSON(GPXtoLatLng(translateTracksContentPath(tempTrack.trackGpx)));
            }

            fixTrackData(tempTrack);

            if ($("#textToReadArea").length > 0) {
                if (!isNullOrEmpty(tempTrack.textToRead)) {
                    textToReadArea.innerHTML = $.ajax(
                        {
                            url: translateTracksContentPath(tempTrack.textToRead + "?" + Math.random()),
                            async: false
                        }
                    ).responseText;
                    // COMMENTED THE AUTOREADING
                    //get_id('textToReadArea', 'en', 'ml');
                }
                else {
                    textToReadArea.innerHTML = "";
                }

                // Show the Description panel only when the track has a description.
                var hasDescription = $.trim(textToReadArea.innerHTML) != "";
                $('#scriptTextCheckBox').prop('disabled', !hasDescription);
                $('label[for=scriptTextCheckBox]').css('opacity', hasDescription ? '' : '0.4');
                if (hasDescription && $('#scriptTextCheckBox').is(':checked'))
                    $('#textToReadArea0').show();
                else
                    $('#textToReadArea0').hide();
            }

            handler(tempTrack);
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
        // a sensible start view (Europe): without it the map stays blank when no track is chosen and the location is unavailable
        map.setView([48, 14], 4);
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
        maxClusterRadius: 38,
        disableClusteringAtZoom: 13,
        showCoverageOnHover: false,
        spiderfyOnMaxZoom: true,
        chunkedLoading: true,
        iconCreateFunction: function (cluster) {
            var kids = cluster.getAllChildMarkers(), thumb = '';
            for (var i = 0; i < kids.length && !thumb; i++) thumb = kids[i].options.thumb || '';
            var n = cluster.getChildCount();
            var html = (thumb ? '<img src="' + thumb.replace(/"/g, '%22') + '" alt="" onerror="this.style.display=\'none\'"/>' : '') + '<b>' + n + '</b>';
            return L.divIcon({ html: html, className: 'sytCluster' + (thumb ? ' withThumb' : ''), iconSize: [50, 50] });
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
                applyDefaultSpeed(track);

                var myIcon = L.icon({
                    iconUrl: translateTracksContentPath("currentposition.png"),//track.icon),
                    iconSize: [markerSize * 1.5, markerSize * 1.5],
                    iconAnchor: [markerSize * 0.75, markerSize * 0.75],
                    shadowUrl: null
                });

                var lastUpdateTime = new Date(2000, 2);

                var amOptions = {
                    distance: getSpeedMps(), // meters
                    zIndexOffset: 1000,
                    interval: 1000, // milliseconds
                    icon: myIcon, // icon
                    autoStart: false,
                    onEnd: function () {
                        if ($("#loopTrackCheckBox").is(':checked')) {
                            animatedMarker.start();
                        }
                    },
                    onStep: function (p) {
                        counter++;
                        if (p.hasOwnProperty("syt_text") && p["syt_text"] != "") {
                            toastr.info(p["syt_text"], "", { timeOut: 5000, extendedTimeOut: 10000 });
                            //prependToSidePanel(p["syt_text"]);
                        }

                        if (p.hasOwnProperty("syt_audio")) {
                            audio.src = translateTracksContentPath(p["syt_audio"]);
                            safePlayAudio();
                        }
                        //markerSize = 2 + map.getZoom() * 5;

                        var currentDate = new Date();
                        if ((currentDate.getTime() - lastUpdateTime.getTime()) / 1000 > updateIntervalSeconds) {

                            map.setView([p.lat, p.lng], map.getZoom());
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

                markerStart = L.marker(track.trackData[0]).bindPopup("Start");//TODO
                markers.addLayer(markerStart);

                markerFinish = L.marker(track.trackData[track.trackData.length - 1]).bindPopup("Finish");//TODO
                markers.addLayer(markerFinish);

                map.setView(track.trackData[0], track.defaultScale ? track.defaultScale : 8);

                if (track.audioSrc && track.audioSrc.length > 0) {
                    audio.src = translateTracksContentPath(track.audioSrc);
                    if (track.audioVolume) {
                        audio.volume = track.audioVolume ? track.audioVolume : 0.8;
                        $("#slider").slider("value", audio.volume);
                    }
                }

                addMarkersNearAll(track.trackData, GOOGLE_TYPES);

                if (track) {
                    var elevator = new google.maps.ElevationService;
                    elevator.getElevationAlongPath({
                        'path': compactTrackData(track.trackData),
                        'samples': 128
                    }, plotElevation);
                }

                isTrackLoaded = true;

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

        addWeatherMarkers(allData, from);
    }
    addWeatherMarkers(allData, allData.length - 1);
}

function doSetTimeout(allData, types, from, to, step, i) {
    setTimeout(function () { addMarkersNearRange(allData, types, from, to, step, (i % 2) == 1) }, i * 2000 + 1);
}

function addMarkersNearRange(allData, types, from1, to1, step1, odd) {
    for (i = from1; i < to1; i += step1) {
        var x = allData[i];
        addMarkersNear(x.lat, x.lng, types, odd);
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

    Promise.all([
        syt.api.searchSYTPlaces(request),
        syt.api.searchWikiPlaces(request),
        syt.api.searchGooglePlaces(googlePlacesService, request)
    ]).then(
        function (values) {
            getplaces_success(values[0].concat(values[1]).concat(values[2]).concat(values[3]));
        });

    //    }
}

function weather_success(place) {

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
        iconSize: [112, 30],
        iconAnchor: [56, 15]
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

function createPhotoMarker(place) {

    if (allMarkers.indexOf(place.id) < 0)
        allMarkers.push(place.id);
    else
        return;

    // console.log (place);

    var photos = place.photos;
    if (!photos) {
        return;
    }

    var isGoogle = photos[0].getUrl ? true : false;
    var isWiki = place.types.indexOf("wiki") >= 0;

    var isPremium = Math.random() < 0.1;
    var thumbIcon = null;
    if (isWiki && place.thumb) {
        var safe = place.thumb.replace(/"/g, '%22');
        thumbIcon = L.divIcon({
            className: 'wikiThumbIcon',
            html: '<img src="' + safe + '" alt="" loading="lazy" onerror="this.parentNode.classList.add(\'noimg\')"/><span>W</span>',
            iconSize: [46, 46], iconAnchor: [23, 23]
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
    pic.src = isGoogle ? photos[0].getUrl({ 'maxWidth': 100, 'maxHeight': 100 }) : photos[0].raw_reference.fife_url;
    pic.style.maxWidth = '160px'; pic.style.maxHeight = '120px'; pic.style.borderRadius = '6px';
    domelem.appendChild(pic);
    var go = document.createElement('p');
    var link = document.createElement('a');
    link.target = '_blank'; link.rel = 'noopener';
    link.href = isWiki ? wikiLink : "https://www.google.com/search?q=" + encodeURIComponent(place.name);
    link.textContent = isWiki ? 'Open in Wikipedia' : 'Search on Google';
    go.appendChild(link);
    domelem.appendChild(go);
    var marker = L.marker(new L.LatLng(
        isGoogle ? place.geometry.location.lat() : place.geometry.location.lat,
        isGoogle ? place.geometry.location.lng() : place.geometry.location.lng),
        { icon: icon, title: place.name, thumb: (isWiki && place.thumb) ? place.thumb : '' }).bindPopup(domelem);
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

function plotElevation(elevations) {

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
        photoViewer.open(parseInt(this.getAttribute('data-index'), 10));
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
            var max = (fullW * 2) - el.clientWidth;
            var v = startLeft - dx;
            if (fullW > 0) { if (v < 0) v += fullW; if (v > max) v -= fullW; }
            el.scrollLeft = v;
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
    var $h = $('<div id="photoResize" title="Drag to resize the photo strip" role="separator" aria-orientation="horizontal"><span></span></div>').appendTo($strip);
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
        var oldFull = fullW, left = scroller.scrollLeft();
        layoutStrip(h);
        if (oldFull > 0 && fullW > 0) scroller.scrollLeft(left * fullW / oldFull);
    }
    $(window).on('resize', function () {
        var h = $strip.height(); if (h > maxH()) { applyLive(setH(maxH(), false)); }
    });
});

// Re-layout the photos for the current strip height (photos are sized to the strip height when loaded)
function relayoutStrip() {
    if (lastStripArgs) get_photos_success(lastStripArgs.photos, lastStripArgs.p, lastStripArgs.tol);
}

// Show / hide handle for the strip
$(function () {
    var $strip = $('#imageDiv0');
    if (!$strip.length) return;
    var key = 'sytStripHidden';
    var $btn = $('<button type="button" id="photoToggle" aria-label="Show or hide photos"><span class="chev">▾</span> <span class="lbl">Photos</span></button>').appendTo('body');
    function apply(hidden, animate) {
        $btn.toggleClass('collapsed', hidden).attr('aria-expanded', !hidden);
        if (animate) $strip.stop(true, true)[hidden ? 'slideUp' : 'slideDown'](200); else $strip.toggle(!hidden);
        try { localStorage.setItem(key, hidden ? '1' : '0'); } catch (e) { }
    }
    var hidden = false; try { hidden = localStorage.getItem(key) === '1'; } catch (e) { }
    if (hidden) apply(true, false);
    $btn.on('click', function () { apply(!$btn.hasClass('collapsed'), true); });
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
    var scrollPos = 0, lastTime = null;
    var doScroll = function (time) {
        if (lastTime === null)
            lastTime = time;
        var dt = Math.min(time - lastTime, 100);   // ms; capped so a background tab doesn't cause a jump
        lastTime = time;
        if (scrollerEnabled) {
            if (Math.abs(scroller.scrollLeft() - Math.round(scrollPos)) > 2)
                scrollPos = scroller.scrollLeft();   // something else moved it (e.g. photos were reloaded)
            scrollPos += controller.curSpeed * dt / 20;   // curSpeed is "pixels per 20ms"
            if (scrollPos > fullW * 2 - scroller.width())
                scrollPos -= fullW;
            scroller.scrollLeft(Math.round(scrollPos));
        }
        window.requestAnimationFrame(doScroll);
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
setInterval(function () {
    var strip = document.getElementById('imageDiv0'), h = 0;
    if (strip && strip.offsetHeight > 0 && $(strip).css('display') != 'none') {
        var r = strip.getBoundingClientRect();
        if (r.bottom > window.innerHeight - 40) h = Math.max(0, Math.round(window.innerHeight - r.top));
    }
    document.documentElement.style.setProperty('--syt-strip-h', h + 'px');
}, 300);
