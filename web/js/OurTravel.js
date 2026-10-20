
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
var MAX_PHOTO_WIDENINGS = 4;

function showPhotos(track, p, tolerancy) {
    if (!tolerancy)
        tolerancy = track.photoLocationTolerancy / 1000;
    if (!tolerancy)
        tolerancy = 0.1;

    var tryPhotos = function (tol, widenings) {
        Promise.all(
            [syt.api.searchSYTImages(track, p, tol),
            syt.api.searchFlickrImages(track, p, tol)]).then(function (values) {
                var photos = values[0].photos.concat(values[1].photos);
                if (photos.length < MIN_PHOTOS && widenings < MAX_PHOTO_WIDENINGS) {
                    tryPhotos(tol * 2, widenings + 1);
                }
                else {
                    get_photos_success(photos, p, tol);
                }
            });
    };
    tryPhotos(tolerancy, 0);
}

function get_photos_success(photos, p, tolerancy) {

    // remove?
    var divHeight = $("#imageDiv").height();
    var divWidth = $("#imageDiv").width();

    shuffle(photos);
    count = photos.length;
    $("#lblCoord").text(p.lat + " " + p.lng);
    var imageUl = imageDiv.children();
    imageUl.fadeOut(100);
    imageUl.empty();
    for (var i = 0; i < photos.length; i++) {
        var nextLi = document.createElement("li");
        var nextLink = document.createElement("a");
        var nextImage = document.createElement("img");
        nextLink.href = photos[i].photo_url;
        nextLink.target = "_blank";

        //var n = getNatural(nextImage);

        nextImage.width = photos[i].width * divHeight / photos[i].height;
        nextImage.height = divHeight;

        //if (isPortrait()) {
        //    nextImage.height = photos[i].height * ((divWidth + 0.0) / photos[i].width);
        //    nextImage.width = divWidth;
        //}
        //else {
        //    nextImage.width = photos[i].width * ((divHeight + 0.0) / photos[i].height);
        //    nextImage.height = divHeight;
        //}
        if (cacheImages == true) {
            getFromCacheOrServer(photos[i].photo_file_url, nextImage, function (obj, data) {
                obj.src = data;
            });
        }
        else {
            nextImage.src = photos[i].photo_file_url;
        }

        //nextImage.style.maxHeight = $("#pictureMaxHeight").val() + "px";
        //TODO: translate
        var template = $.t("Photo from {0} by {1}. Click to open the source.");
        nextImage.title = (template).format([photos[i].photo_title, photos[i].owner_name]);
        //nextImage.title = "Photo from: " + photos[i].photo_title + " by " + photos[i].owner_name + ". Click to open the source.";
        nextImage.classList.add("photo");
        // Own photos: the original file; public photos (Commons): the larger thumbnail.
        nextImage.setAttribute("data-full", /^\.?\/?data\/images\//.test(photos[i].photo_url) ? photos[i].photo_url : photos[i].photo_file_url);
        nextLink.appendChild(nextImage);
        nextLi.appendChild(nextLink);

        imageUl[0].appendChild(nextLi);
    }

    curX = 0;
    scrollerContent.children().clone().appendTo(scrollerContent);
    scrollerContent.children().each(function () {
        var $this = $(this);
        $this.css('left', curX);
        var img = $this.children().children()[0];
        curX += img.width;//$this.outerWidth(true);
    });
    fullW = curX / 2;
    viewportW = scroller.width();
    imageUl.fadeIn(100);
}

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

    var icon = L.icon({
        iconUrl: ("services/create_image.aspx?text=" + encodeURIComponent(place.temperature) + "&fontColor=White&backColor=Transparent&borderColor=Transparent&fontName=Arial&fontSize=10&fontStyle=Bold&height=30&width=100&imagePath=/img/weather/" + iconImg),
        //"img/weather/" + iconImg),
        //,shadowUrl: 'img/shadow-white.png',

        iconSize: [100, 30], // size of the icon
        //shadowSize:   [50, 50], // size of the shadow
        iconAnchor: [50, 15] // point of the icon which will correspond to marker's location
        //shadowAnchor: [25, 25],  // the same for the shadow
        //    popupAnchor:  [25, 0] // point from which the popup should open relative to the iconAnchor
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
    var icon = L.icon({
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

    var domelem = document.createElement('a');
    //domelem.href = place.name;
    domelem.innerHTML = "<p>" + place.name + "</p><img height='100px' width='100px' src='" + (isGoogle ? photos[0].getUrl({ 'maxWidth': 100, 'maxHeight': 100 }) : photos[0].raw_reference.fife_url) + "'/>";
    domelem.alt = place.name;
    domelem.onclick = function () {
        window.open(isWiki ?
            "https://" + getTwitterLanguage() + ".wikipedia.org/?curid=" + place.id :
            "https://www.google.com.ua/search?q=" + place.name, "_blank");
        // do whatever else you want to do - open accordion etc
    };
    var marker = L.marker(new L.LatLng(
        isGoogle ? place.geometry.location.lat() : place.geometry.location.lat,
        isGoogle ? place.geometry.location.lng() : place.geometry.location.lng),
        { icon: icon }).bindPopup(domelem);
    myMarkers.push(marker);

    markers.addLayer(marker);

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
$(function () {
    var $preview = $('<div id="photoPreview"><img alt="" /></div>').css({
        position: 'fixed', display: 'none', zIndex: 5000, pointerEvents: 'none',
        background: '#fff', padding: '4px', border: '1px solid #888', borderRadius: '4px',
        boxShadow: '0 4px 16px rgba(0,0,0,0.5)'
    }).appendTo('body');
    var $previewImg = $preview.find('img').css({ display: 'block', maxWidth: '70vw', maxHeight: '65vh' });

    function place(e) {
        var w = $preview.outerWidth(), h = $preview.outerHeight();
        var left = Math.max(5, Math.min(e.clientX - w / 2, window.innerWidth - w - 5));
        var top = e.clientY - h - 20;
        if (top < 5)
            top = Math.min(e.clientY + 20, window.innerHeight - h - 5);
        $preview.css({ left: left, top: top });
    }

    $(document).on('mouseenter', 'img.photo', function (e) {
        var src = this.getAttribute('data-full');
        if (!src)
            return;
        $previewImg.off('load').one('load', function () { place(e); $preview.show(); });
        $previewImg.attr('src', src);
        if ($previewImg[0].complete)
            $previewImg.trigger('load');
    }).on('mousemove', 'img.photo', function (e) {
        if ($preview.is(':visible'))
            place(e);
    }).on('mouseleave', 'img.photo', function () {
        $preview.hide();
    });
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
