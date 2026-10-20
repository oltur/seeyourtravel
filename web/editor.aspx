
<%@ Page ValidateRequest="false" Title="See Your Travel - Editor" Language="C#" MasterPageFile="MasterPage.master" CodeFile="Editor.aspx.cs" Inherits="Editor" %>

<%@ Import Namespace="System.IO" %>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadPlaceholder" runat="Server">

    <script>
        function clickCancel() {
            window.location = 'index.aspx';
        }

        function translateAll(err, t) {
            $(".i").i18n();
            $("option.i").i18n();
            $("#profile").text($.t("Profile").replace("{0}", globalUserName));
        }

    </script>
</asp:Content>

<asp:Content ID="bodyContent" ContentPlaceHolderID="BodyPlaceholder" runat="Server">
    <!-- #Include virtual="include/profileLangPanel.inc" -->
    <!--Content-->
    <div id='pageContent' style='height: 100%'>
        <!-- #Include virtual="include/profileMenu.inc" -->
    </div>

    <!-- #Include virtual="include/settingsPanel.inc" -->

    <div id="map"></div>

    <div id="textToReadArea0" class="ui-widget-content" style="overflow: auto; position: absolute; padding: 10px; z-index: 1001; top: 40px; right: 50px; width: 350px; height: 770px; background: rgba(255,255,255,0.8); border-radius: 12px; border: 0 solid #000;">

        <input type="hidden" id="trackId" name="trackId" value="<%=this.TrackId%>" />
        <input type="hidden" id="trackFileName" name="trackFileName" value="<%=this.TrackFileName%>" />

        <script>
            $(function () {
                $("#tabs").tabs();
            });
        </script>
        <div id="tabs">
            <ul>
                <li><a class="big i" data-i18n="Basic" href="#basic">Basic</a></li>
                <li><a class="big i" data-i18n="Advanced" href="#advanced">Advanced</a></li>
            </ul>
            <div id="basic">
                <table border="0">
                    <tr>
                        <td class="big i" data-i18n="TrackName">Track name:</td>
                        <td>
                            <input id="name" name="name" type="text" value="<%="New track " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")  %>" style="width: 180px;" /></td>
                    </tr>
                    <tr>
                        <td class="big i" data-i18n="Maketrackpublic">Make track public?</td>
                        <td>
                            <input id="isPublic" name="isPublic" type="checkbox" value="isPublic" checked="checked" />
                        </td>
                    </tr>
                    <tr>
                        <td class="big i" data-i18n="Category">Category:</td>
                        <td>
                            <input id="category" name="category" list="categories" value="Other" style="width: 180px;" />
                            <datalist class="i" id="categories">
                                <option value="Ukraine" class="i" data-i18n="Ukraine" />
                                <option value="Germany" class="i" data-i18n="Germany" />
                                <option value="Europe" class="i" data-i18n="Europe" />
                                <option value="Asia" class="i" data-i18n="Asia" />
                                <option value="America" class="i" data-i18n="America" />
                                <option value="Other" class="i" data-i18n="Other" />
                            </datalist>
                        </td>
                    </tr>
                    <tr>
                        <td class="big i" data-i18n="Copyright">Copyright:</td>
                        <td>
                            <input id="copyright" name="copyright" type="text" value="(c)" style="width: 180px;" /></td>
                    </tr>
                    <tr>
                        <td class="big i" data-i18n="Travelwith">Travel with:</td>
                        <td>
                            <select id="travelWith" name="travelWith" style="width: 180px;">
                                <option value="WalkingMan">Walking Man</option>
                                <option value="Bike">Bike</option>
                                <option value="Car" selected="selected">Car</option>
                                <option value="Bus">Bus</option>
                                <option value="Yacht">Yacht</option>
                                <option value="Plane">Plane</option>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td class="big i" data-i18n="Audiofile">Audio file:</td>
                        <td>
                            <input type="text" id="audioSrc" name="audioSrc" style="width: 180px;" />
                            <input type="file" accept=".mp3" id="fileAudio" name="fileAudio" style="width: 180px;" />

                            <input id="defaultScale" name="defaultScale" type="hidden" max="20" min="1" step="1" value="8" style="width: 180px;" />
                        </td>
                    </tr>
                    <%--            <tr>
                <td class="big i" data-i18n="Defaultscale">Default scale:<br />
                    1(largest).20(smallest)</td>
                <td></td>
            </tr>--%>
                </table>
                <p class="big">
                    <input name="trackData" id="trackData" type="hidden" />
                </p>
                <p class="big">
                    <span class="big  i" data-i18n="Trackpoints">Track points:</span>
                    <br />
                    <select id="points" name="points" size="10" style="width: 250px" multiple="multiple">
                    </select>
                </p>
                <p class="big">
                    <span class="big  i" data-i18n="Currentpointdescriptionoptional">Current point description (optional):</span>
                    <br />
                    <input id="pointDescr" name="pointDescr" type="text" value="" style="width: 250px" />
                </p>
                <input type="button" value="Delete selected" id="buttonDeleteSelected" class="i" data-i18n="[title]DeleteSelected;[value]DeleteSelected" />
                <div class="big">
                    <br />
                    <table>
                        <tr>
                            <td>From:</td>
                            <td>
                                <input id="fromLocation" type="text" value="Champs Elysee 1 Paris" style="width: 200px" />
                            </td>
                        </tr>
                        <tr>
                            <td>To:</td>
                            <td>
                                <input id="toLocation" type="text" value="Bukingham Palace London" style="width: 200px" />
                            </td>
                        </tr>
                    </table>
                    <button type="button" id="createByRoute" class="i" data-i18n="[title]CreateByRoute;CreateByRoute">Create by Route</button>
                </div>
                <div class="big">
                    <br />
                    <div id="fileOperations">
                        <label for="fileGpx" class="i" data-i18n="[title]ImportGpxFile;ImportGpxFile">Import Gpx file:</label>
                        <input type="file" accept=".gpx" id="filesGpx" name="filesGpx" style="width: 180px;" />
                        <%--multiple="multiple"--%>
                        <!--input type="button" value="Import data" id="importGpx"/-->
                    </div>
                </div>
            </div>
            <div id="advanced">
                <table border="0">
                    <tr>
                        <td class="big i" data-i18n="Photolocationdistance">Photo location distance:<br />
                            degree/1000, 2..1000</td>
                        <td>
                            <input id="photoLocationTolerancy" name="photoLocationTolerancy" type="number" max="1000" min="1" step="1" value="100" style="width: 180px;" /></td>
                    </tr>
                    <%--                    <tr>
                        <td class="big i" data-i18n="Stepstoredraw">Steps to redraw:<br />
                            2..1000</td>
                        <td>
                            <input id="stepsToRedraw" name="stepsToRedraw" type="number" max="1000" min="2" step="1" value="100" style="width: 180px;" /></td>
                    </tr>
                    <tr>
                        <td class="big i" data-i18n="Stepstoshowphotos">Steps to show photos:<br />
                            2..1000</td>
                        <td>
                            <input id="stepsToShowPhoto" name="stepsToShowPhoto" type="number" max="1000" min="2" step="1" value="10" style="width: 180px;" /></td>
                    </tr>--%>
                    <tr>
                        <td class="big i" data-i18n="Speed">Speed:<br />
                            meters/sec, 1..100000</td>
                        <td>
                            <input id="velocityMetersPerSec" name="velocityMetersPerSec" type="number" max="100000" min="1" step="1" value="100" style="width: 180px;" /></td>
                    </tr>
                    <%--            <tr>
                <td class="big i" data-i18n="Numberofphotostoload">Number of photos to load:<br />
                    1..50</td>
                <td></td>
            </tr>--%>
                    <input id="numOfPhotos" name="numOfPhotos" type="hidden" max="50" min="1" step="1" value="20" style="width: 180px;" />
                    <tr>
                        <td class="big i" data-i18n="Animatedmarkericon">Animated marker icon:</td>
                        <td>
                            <select id="icon" name="icon" style="width: 180px;" onchange="setAnimatedMarkerIcon(this.value)">
                                <option value="man.png">man.png</option>
                                <option value="aman.gif">aman.gif</option>
                                <option value="mybike.png">mybike.png</option>
                                <option value="mycar.png" selected="selected">mycar.png</option>
                                <option value="mybus.png">mybus.png</option>
                                <option value="myyacht.png">myyacht.png</option>
                                <option value="myplane.png">myplane.png</option>
                            </select>
                        </td>
                    </tr>
                    <tr>
                        <td class="big i" data-i18n="Trackimage">Track image:</td>
                        <td>
                            <input type="text" id="trackImage" name="trackImage" style="width: 180px;" />
                            <input type="file" accept="image/*" id="fileImage" name="fileImage" style="width: 180px;" />
                        </td>
                    </tr>
                    <tr>
                        <td class="big i" data-i18n="TextDescriptionFile">Text description file:</td>
                        <td>
                            <input type="text" id="textToRead" name="textToRead" style="width: 180px;" />
                            <input type="file" accept="text/plain" id="fileText" name="fileText" style="width: 180px;" />
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <label for="useFlickrImages" class="i" data-i18n="useFlickrImages">Use Panoramio images</label>
                        </td>
                        <td>
                            <input id="useFlickrImages" name="useFlickrImages" type="checkbox" checked="checked" title="Use Panoramio images" onchange="SaveSettings();" />
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <label for="useSYTImagesTrack" class="i" data-i18n="UseCYTImages">Use SeeYourTravel images</label>
                        </td>
                        <td>
                            <input id="useSYTImagesTrack" name="useSYTImagesTrack" type="checkbox" checked="checked" title="Use SeeYourTravel images" onchange="SaveSettings();" />
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <label for="useGooglePlaces" class="i" data-i18n="UseGooglePlaces">Use Google Places</label>
                        </td>
                        <td>
                            <input id="useGooglePlaces" name="useGooglePlaces" type="checkbox" checked="checked" title="Use Google Places" onchange="SaveSettings();" />
                        </td>
                    </tr>
                    <tr>
                        <td>
                            <label for="useSYTPlaces" class="i" data-i18n="UseCYTPlaces">Use SeeYourTravel places</label>
                        </td>
                        <td>
                            <input id="useSYTPlaces" name="useSYTPlaces" type="checkbox" checked="checked" title="Use SeeYourTravel places" onchange="SaveSettings();" />
                        </td>
                    </tr>
                </table>
            </div>
        </div>
        <br />
        <p class="big">
            <asp:Button
                ID="Button1"
                PostBackUrl="saveTrack.aspx"
                runat="server"
                Text="Submit"
                data-i18n="TrackDescription"
                class="i"
                OnClientClick="beforeSubmit()" />
            &nbsp;
    <input type="button" value="Cancel" class="i" data-i18n="[title]Cancel;[value]Cancel" id="gotoMain" onclick="window.location = 'index.aspx?trackname=' + trackname" />
        </p>
    </div>

    <div id="imageDiv0" class="ui-widget-content">
        <div id="imageDiv" class="innerScrollArea">
            <ul></ul>
        </div>
    </div>

    <script lang="JavaScript">
        var trackname;
    </script>
    <%
        string trackname = Request.QueryString["trackname"];
        if (!string.IsNullOrEmpty(trackname))
        {
            Response.Write(string.Format(@"<script language='javascript'>
    trackname = '{0}';
    </script>", trackname));
        }

    %>
    <script lang="JavaScript">

        function beforeSubmit() {
            var idx = this.selectedIndex;

            if (idx != null && typeof idx != "undefined") {
                var optionSelected = $("option", this).eq(idx);
                var valueSelected = optionSelected.val();
                var point = JSON.parse(valueSelected);
                if (point.hasOwnProperty("lat"))
                    point["syt_text"] = $("#pointDescr").val();
                else
                    point[2] = $("#pointDescr").val();
                optionSelected.val(JSON.stringify(point));
            }
        }

        function setDirections(directions) {
            var i = 0;
            for (; i < directions.routes[0].overview_path.length; i++) {
                if (i == 0) {
                    points
                        .find('option')
                        .remove()
                        .end();
                }
                var p = directions.routes[0].overview_path[i];
                var p2 = new L.LatLng(p.lat(), p.lng());

                var t = JSON.stringify(p2);

                points
                    .append($("<option></option>")
                    .attr("value", t)
                    .text(t));
            }

            if (i > 0) {
                points[0].selectedIndex = 0;
                points.change();

                updateMap();
            }
        }

        function createTrackByRoute() {

            var directionsService = new google.maps.DirectionsService();

            var request = {
                origin: $("#fromLocation").val(),
                destination: $("#toLocation").val(),
                provideRouteAlternatives: false,
                travelMode: 'DRIVING',
                unitSystem: google.maps.UnitSystem.METRIC
            };

            directionsService.route(request, function (result, status) {
                if (status == 'OK') {
                    setDirections(result);
                }
            });
        }

        $(function () {

            points = $("#points");
            $('form').submit(function () {
                var t = JSON.stringify(getTrackPoints());
                $("#trackData").val(t);
                return true;
            });

            icon = L.icon({
                iconUrl: ("tracks/content/currentposition.png"),
                iconSize: [50, 50],
                iconAnchor: [25, 25],
                shadowUrl: null
            });

            map = L.map('map', { zoomControl: false }).setView([50.430981, 30.539267], 8);
            L.control.zoom({ position: 'topright' }).addTo(map);
            L.control.scale({ position: 'bottomleft' }).addTo(map);
            tileLayer = L.tileLayer(mapTileUrl, {
        attribution: '© <a href="https://www.mapbox.com/about/maps/">Mapbox</a> © <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a> <strong><a href="https://www.mapbox.com/map-feedback/" target="_blank">Improve this map</a></strong>',
        tileSize: 512,
        maxZoom: 18,
        zoomOffset: -1,
        id: 'mapbox/streets-v11',
        accessToken: 'pk.eyJ1Ijoib2x0dXJ1YSIsImEiOiJlODQ4ZTI2MWI4OGZkZjUyNDRiNjY4MDFkZGI0ODc4NyJ9.iiCb_tZgs_ipvEv3s6Zx0A'
        });

            tileLayer.addTo(map);
            markerPosition = L.marker(new L.LatLng(1000, 1000), { icon: icon }).addTo(map);

            map.on('click', onMapClick);

            $("#imageDiv0").draggable().resizable({ minHeight: 50, minWidth: 50 });
            $("#textToReadArea0").draggable();
            $("#slider").slider({
                value: 0.8,
                min: 0,
                max: 1,
                step: 0.1,
                slide: function (event, ui) {
                    audio.volume = ui.value;
                }
            });

            points
                .data("lastIndex", this.selectedIndex)
                .on('change', function (event) {
                    var idx = this.selectedIndex;
                    var prevIdx = $(this).data("lastIndex");

                    if (prevIdx != null && typeof prevIdx != "undefined") {
                        var oldOptionSelected = $("option", this).eq(prevIdx);
                        var oldValueSelected = oldOptionSelected.val();
                        var oldPoint = JSON.parse(oldValueSelected);
                        if (oldPoint.hasOwnProperty("lat"))
                            oldPoint["syt_text"] = $("#pointDescr").val();
                        else
                            oldPoint[2] = $("#pointDescr").val();
                        oldOptionSelected.val(JSON.stringify(oldPoint));
                    }

                    var optionSelected = $("option:selected", this);
                    var valueSelected = this.value;
                    var point = JSON.parse(valueSelected);
                    var newLatLng = pointToLatLng(point);
                    markerPosition.setLatLng(newLatLng);
                    map.setView(newLatLng);
                    $("#pointDescr").val(point.hasOwnProperty("syt_text") ? point["syt_text"] : (point.length > 2 ? point[2] : ""));
                    track = { numOfPhotos: parseInt(numOfPhotos.value), photoLocationTolerancy: parseInt(photoLocationTolerancy.value) };
                    showPhotos(track, newLatLng);

                    // Set new index as old index
                    $(this).data("lastIndex", idx);
                });

            document.getElementById('filesGpx').addEventListener('change', handleFileSelect, false);

            $('#buttonDeleteSelected').click(function () {
                $('#points option:selected').remove();
                updateMap();
            });

            $("#createByRoute").click(function () {
                createTrackByRoute();
            });

            // Check for the various File API support.
            if (window.File && window.FileReader && window.FileList && window.Blob) {
                // Great success! All the File APIs are supported.
            } else {
                $("#fileOperations").hide();
            }

            map.on('zoomend', function () {
                $("#defaultScale").val(map.getZoom());
            });

            //$("#stepsToRedraw").spinner({
            //    min: 1,
            //    max: 1000,
            //    step: 1,
            //    height: 30
            //}).on('input', function () {
            //    if ($(this).data('onInputPrevented')) return;
            //    var val = this.value,
            //        $this = $(this),
            //        max = $this.spinner('option', 'max'),
            //        min = $this.spinner('option', 'min');
            //    if (!val.match(/^\d+$/)) val = min; //we want only number, no alpha
            //    this.value = val > max ? max : val < min ? min : val;
            //}).on('keydown', function (e) { // to allow 'Backspace' key behaviour
            //    $(this).data('onInputPrevented', e.which === 8 ? true : false);
            //});

            $("#travelWith").change(function () { travelWithChanged(); });
            if (!trackname) {
                setAnimatedMarkerIcon("mycar.png");
            }
            else {
                loadTrack(translateTracksPath(trackname + ".js"),
                    function (tempTrack) {
                        var initialTrack = tempTrack;
                        $("#name").val(initialTrack.name);
                        if (initialTrack.isPublic == "No") {
                            $("#isPublic").prop('checked', false);
                        }
                        else {
                            $("#isPublic").prop('checked', true);
                        }

                        if (!isNullOrEmpty(initialTrack.travelWith)) {
                            $("#travelWith").val(initialTrack.travelWith);
                        }

                        $("#copyright").val(initialTrack.copyright);
                        $("#category").val(initialTrack.category);
                        $("#photoLocationTolerancy").val(initialTrack.photoLocationTolerancy);
                        //                $("#stepsToRedraw").val(initialTrack.stepsToRedraw);
                        //                $("#stepsToShowPhoto").val(initialTrack.stepsToShowPhoto);
                        $("#velocityMetersPerSec").val(initialTrack.velocityMetersPerSec);
                        $("#numOfPhotos").val(initialTrack.numOfPhotos);
                        $("#icon").val(initialTrack.icon);
                        setAnimatedMarkerIcon(initialTrack.icon);
                        $("#trackImage").val(initialTrack.trackImage);
                        $("#audioSrc").val(initialTrack.audioSrc);
                        $("#audioVolume").val(initialTrack.audioVolume);
                        $("#textToRead").val(initialTrack.textToRead);
                        $("#defaultScale").val(initialTrack.defaultScale);
                        map.setZoom(initialTrack.defaultScale);

                        $("#useFlickrImages").prop('checked', initialTrack.useFlickrImages != "No");
                        $("#useSYTImagesTrack").prop('checked', initialTrack.useSYTImagesTrack != "No");
                        $("#useGooglePlaces").prop('checked', initialTrack.useGooglePlaces != "No");
                        $("#useSYTPlaces").prop('checked', initialTrack.useSYTPlaces != "No");

                        if (!isNullOrEmpty(initialTrack.trackGpx)) {
                            $("#trackGpx").val(initialTrack.trackGpx);
                        }
                        else {
                            initialTrack.trackData.forEach(function (point) {
                                if (point.hasOwnProperty("lat") && (point.hasOwnProperty("syt_text") == null || point.hasOwnProperty("syt_text") == ""))
                                    point["syt_text"] = "";
                                if (!point.hasOwnProperty("lat") && point.length < 3)
                                    point[2] = "";
                                var t = JSON.stringify(point);
                                points
                                    .append($("<option></option>")
                                    .attr("value", t)
                                    .text(t));
                            });

                            if (initialTrack.trackData.length > 0) {
                                points[0].selectedIndex = 0;
                                points.change();
                            }

                        }

                        drawTrack();
                    });
            }
        });

        function travelWithChanged() {

            var x = $('#travelWith').find(":selected").val();
            if (x == "WalkingMan") {
                var t = "currentposition.png";//("aman.gif");
                $("#velocityMetersPerSec").val(Math.round(5 * 10 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
            else if (x == "Bike") {
                var t = "currentposition.png";//("mybike.png");
                $("#velocityMetersPerSec").val(Math.round(15 * 50 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
            else if (x == "Car") {
                var t = "currentposition.png";//"mycar.png";
                $("#velocityMetersPerSec").val(Math.round(100 * 100 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
            else if (x == "Bus") {
                var t = "currentposition.png";//("mybus.png");
                $("#velocityMetersPerSec").val(Math.round(80 * 100 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
            else if (x == "Yacht") {
                var t = "currentposition.png";//("myyacht.png");
                $("#velocityMetersPerSec").val(Math.round(40 * 100 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
            else if (x == "Plane") {
                var t = "currentposition.png";//("myplane.png");
                $("#velocityMetersPerSec").val(Math.round(800 * 100 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
        }

        function setAnimatedMarkerIcon(t) {
            icon = L.icon({
                iconUrl: ("tracks/content/" + t),
                iconSize: [50, 50],
                iconAnchor: [1, 50],
                shadowUrl: null
            });
            markerPosition.setIcon(icon);
        }

        function drawTrack() {
            var points = getTrackPoints();
            if (points.length > 0) {
                if (polyline)
                    map.removeLayer(polyline);
                polyline = L.polyline(points, { color: 'green' }).addTo(map);
            }
        }

        function getTrackPoints() {
            var points = [];
            $("#points > option").each(function () {
                var point = JSON.parse(this.value);
                if (point.length < 3)
                    point[2] = "";
                points.push(point);
            });
            return points;
        }

        var imageDiv = $("#imageDiv");
        var polyline;
        var map;
        var track;
        var markerPosition;
        var map2 = document.getElementById("map2");
        var animatedMarker;
        var tileLayer;
        var markers;
        var markersFriends;
        var markersTracks;
        var line;
        var icon;
        var markerStart;
        var markerFinish;
        var points;

        function onMapClick(e) {
            updateTrackData(e);
            updateMap();
        }

        function updateMap() {
            drawTrack();
        }

        function updateTrackData(e) {
            if (!e) {
            }
            else if (e.latlng) {
                var point = JSON.stringify([e.latlng.lat, e.latlng.lng, $("#pointDescr").val()]);
                var selectedItem = $("#points option:selected").first();
                if (selectedItem.index() >= 0) {
                    $("#points option").eq(selectedItem.index()).after($("<option></option>")
                     .attr("value", point)
                     .text(point));
                }
                else {
                    points
                        .append($("<option></option>")
                        .attr("value", point)
                        .text(point));
                }

                track = { numOfPhotos: parseInt(numOfPhotos.value), photoLocationTolerancy: parseInt(photoLocationTolerancy.value) };
                showPhotos(track, e.latlng);
            }
            else {
            }
        }

    </script>

    <script>
        function handleFileSelect(evt) {
            var files = evt.target.files; // FileList object

            // Loop through the FileList and render image files as thumbnails.
            for (var i = 0; i < files.length; i++) {

                var f = files[i];

                //// Only process image files.
                //if (!f.type.match('image.*')) {
                //    continue;
                //}

                var reader = new FileReader();

                reader.onload = function () {
                    var text = reader.result;
                    //alert(reader.result);

                    $xmlDoc = $.parseXML(text);
                    $features = $('trkpt', $xmlDoc);

                    var s = "";
                    var t = 0;
                    $features.each(function () {
                        var $this = $(this);
                        var point = [$this.attr('lat'), $this.attr('lon')];
                        $(points)
                            .append($("<option></option>")
                            .attr("value", "[" + point[0] + "," + point[1] + "]")
                            .text("[" + point[0] + "," + point[1] + "]"));
                        //                        console.log(t);
                        t = t + 1;
                    });
                    onMapClick(s);
                };
                reader.readAsText(f);
            }
        }
    </script>

</asp:Content>
