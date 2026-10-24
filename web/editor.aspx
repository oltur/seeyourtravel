
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

    <div id="textToReadArea0" class="ui-widget-content editorPanel">
        <div class="edHeader"><span class="i" data-i18n="EditorTitle">Track editor</span><span class="edGrip" aria-hidden="true">⋮⋮</span></div>
        <div class="edBody">

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
                            <input id="name" name="name" type="text" value="<%="New track " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")  %>" style="width: 100%; min-width: 180px; max-width: 360px; box-sizing: border-box;" oninput="this.title = this.value" /></td>
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
                            <input id="category" name="category" list="categories" value="Other" style="width: 180px;" autocomplete="off" title="Choose a category from the list or type a new one" />
                            <datalist class="i" id="categories">
                                <option value="Ukraine" class="i" data-i18n="Ukraine" />
                                <option value="Germany" class="i" data-i18n="Germany" />
                                <option value="Europe" class="i" data-i18n="Europe" />
                                <option value="Israel" class="i" data-i18n="Israel" />
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
                        <td class="big i" data-i18n="TrackText" style="vertical-align: top;">Description:<br /><small class="i" data-i18n="TrackTextHint">shown in the panel; HTML allowed</small></td>
                        <td>
                            <textarea id="descriptionText" name="descriptionText" rows="7" style="width: 180px; resize: vertical;"></textarea>
                        </td>
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
                    <tr>
                        <td class="big i" data-i18n="AudioVolume">Audio volume:<br />0..1</td>
                        <td>
                            <input id="audioVolume" name="audioVolume" type="number" min="0" max="1" step="0.1" placeholder="0.8" style="width: 180px;" />
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
                    <textarea id="pointDescr" name="pointDescr" rows="2" placeholder="" style="resize: vertical;"></textarea>
                </p>
                <input type="button" value="Delete selected" id="buttonDeleteSelected" class="i" data-i18n="[title]DeleteSelected;[value]DeleteSelected" />
                <div class="big">
                    <br />
                    <table>
                        <tr>
                            <td class="i" data-i18n="From">From:</td>
                            <td>
                                <input id="fromLocation" name="startName" type="text" value="" class="i" data-i18n="[placeholder]FromPlaceholder" placeholder="Champs-Élysées, Paris" style="width: 200px" />
                            </td>
                        </tr>
                        <tr>
                            <td class="i" data-i18n="To">To:</td>
                            <td>
                                <input id="toLocation" name="endName" type="text" value="" class="i" data-i18n="[placeholder]ToPlaceholder" placeholder="Buckingham Palace, London" style="width: 200px" />
                            </td>
                        </tr>
                    </table>
                    <button type="button" id="createByRoute" class="i" data-i18n="[title]CreateByRoute;CreateByRoute">Create by Route</button>
                </div>
                <div class="big">
                    <br />
                    <div id="fileOperations">
                        <label for="fileGpx" class="i" data-i18n="[title]ImportGpxFile;ImportGpxFile">Import Gpx file:</label>
                        <input type="file" accept=".gpx,.kml,.kmz,.json,.geojson,application/json,application/vnd.google-earth.kml+xml,application/vnd.google-earth.kmz,application/gpx+xml" id="filesGpx" name="filesGpx" style="width: 180px;" />
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
                        <td class="big i" data-i18n="TextDescriptionFile">Fill the description from a file:</td>
                        <td>
                            <input type="hidden" id="textToRead" name="textToRead" />
                            <input type="file" accept=".txt,.htm,.html,text/plain,text/html" id="fileText" style="width: 180px;" />
                        </td>
                    </tr>
                </table>
            </div>
        </div>
        </div>
        <p class="big edFooter">
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
            <% if (IsExisting) { %>
            &nbsp;
            <input type="button" value="Delete track" id="deleteTrack" class="i" data-i18n="[title]DeleteTrack;[value]DeleteTrack" style="color: #b00020"
                onclick="deleteThisTrack()" />
            <% } %>
        </p>
    </div>

    <div id="imageDiv0" class="ui-widget-content">
        <div id="imageDiv" class="innerScrollArea">
            <ul></ul>
        </div>
    </div>

    <script src="<%=Tools.V("js/trackimport.js")%>"></script>
    <script lang="JavaScript">
        var trackname;
    </script>
    <%
        string trackname = Request.QueryString["trackname"];
        if (string.IsNullOrEmpty(trackname) && IsExisting) trackname = TrackFileName;   // opened by track id (e.g. after saving)
        if (!string.IsNullOrEmpty(trackname))
        {
            Response.Write(string.Format(@"<script language='javascript'>
    trackname = '{0}';
    </script>", trackname));
        }

    %>
    <script lang="JavaScript">

        // the text of the point being edited goes into its list entry (on every key, and before saving)
        function storePointText() {
            var $pts = $("#points"), idx = $pts.data("lastIndex");
            if (idx == null || typeof idx == "undefined") idx = $pts[0].selectedIndex;
            if (idx == null || idx < 0) return;
            var opt = $("option", $pts).eq(idx);
            if (!opt.length) return;
            var point = JSON.parse(opt.val());
            if (point.hasOwnProperty("lat"))
                point["syt_text"] = $("#pointDescr").val();
            else
                point[2] = $("#pointDescr").val();
            opt.val(JSON.stringify(point));
        }

        function beforeSubmit() {
            storePointText();
        }

        // floating editor panel: drag by its header, resize by any edge, size and place are remembered
        function initEditorPanel() {
            var $p = $("#textToReadArea0"), key = "syt_editorPanel", saved = null;
            try { saved = JSON.parse(localStorage.getItem(key) || "null"); } catch (e) { }
            var w = Math.min(window.innerWidth - 16, Math.max(300, saved && saved.w || 380));
            var h = Math.min(window.innerHeight - 16, Math.max(260, saved && saved.h || window.innerHeight - 56));
            var l = saved ? Math.min(Math.max(0, saved.l), window.innerWidth - 80) : Math.max(8, window.innerWidth - w - 50);
            var t = saved ? Math.min(Math.max(0, saved.t), window.innerHeight - 60) : 40;
            if (window.innerWidth < 600) { w = window.innerWidth - 16; l = 8; }
            $p.css({ left: l, top: t, width: w, height: h, right: "auto" });
            var save = function () {
                try { localStorage.setItem(key, JSON.stringify({ l: $p.position().left, t: $p.position().top, w: $p.outerWidth(), h: $p.outerHeight() })); } catch (e) { }
            };
            $p.draggable({ handle: ".edHeader", containment: "window", stop: save });
            $p.resizable({ handles: "all", minWidth: 300, minHeight: 260, stop: save });
            $(window).on("resize", function () {
                if ($p.outerHeight() > window.innerHeight - 8) $p.css("height", window.innerHeight - 16);
                if ($p.outerWidth() > window.innerWidth - 8) $p.css("width", window.innerWidth - 16);
            });
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

            if (!$.trim($("#fromLocation").val()) || !$.trim($("#toLocation").val())) {
                toastr.error(T("RouteNeedsPlaces", "Enter the start and the end place first."));
                return;
            }
            var directionsService = new google.maps.DirectionsService();

            var request = {
                origin: $("#fromLocation").val(),
                destination: $("#toLocation").val(),
                provideRouteAlternatives: false,
                travelMode: ({ WalkingMan: 'WALKING', Bike: 'BICYCLING' })[$("#travelWith").val()] || 'DRIVING',
                unitSystem: google.maps.UnitSystem.METRIC
            };

            var btn = $("#createByRoute").prop("disabled", true);
            toastr.info(T("RouteSearching", "Searching for a route…"));
            directionsService.route(request, function (result, status) {
                btn.prop("disabled", false);
                if (status == 'OK') {
                    setDirections(result);
                    toastr.success(T("RouteCreated", "Route created: {0} points").replace("{0}", $("#points option").length));
                } else if (status == 'ZERO_RESULTS' || status == 'NOT_FOUND') {
                    toastr.error(T("RouteNotFound", "Could not find one of the places or a route between them. Try a more general name, e.g. a city."));
                } else {
                    toastr.error(T("RouteUnavailable", "Route service is not available right now ({0}). Please try again.").replace("{0}", status));
                }
            });
        }

        // The browser only offers list entries that match the text in the box, so with "Other" typed in there is just "Other":
        // on focus the box is emptied (and restored if left empty) to offer every category.
        $(function () {
            var $c = $("#category"), keep = "";
            $c.on("focus mousedown", function () { if (this.value) { keep = this.value; this.value = ""; } })
              .on("blur change", function () { if (this.value === "") this.value = keep || "Other"; });
        });

        // A route recorded with the "Record route" button: bring it in as the track's points
        $(function () {
            if (!/[?&]recorded=1/.test(location.search) || !window.sytRecorder) return;
            var r = sytRecorder._done();
            if (!r || !r.points || r.points.length < 2) return;
            setTimeout(function () {
                var secs = Math.max(1, r.activeMs / 1000), mps = r.meters / secs;
                applyImported({ label: T("RecordedName", "Recorded route") + " " + new Date(r.startedAt).toLocaleDateString(), points: r.points });
                // the usual way of travel for the average speed: walking, bike, car or plane (also sets the picture and the speed)
                $("#travelWith").val(mps < 2.5 ? "WalkingMan" : mps < 8 ? "Bike" : mps < 40 ? "Car" : "Plane").trigger("change");
                sytRecorder.clearDone();
            }, 900);
        });

        function deleteThisTrack() {
            var trackLabel = $.trim($("#name").val()) || $("#trackFileName").val();
            if (!confirm(T("DeleteTracksConfirm", "Delete {0} permanently? This cannot be undone.").replace("{0}", '"' + trackLabel + '"'))) return;
            $.post("services/delete_trackbyfilename.aspx", { fileName: $("#trackFileName").val() })
                .done(function (r) {
                    if ($.trim(String(r)) === "OK") window.location = "index.aspx";
                    else toastr.error(T("DeleteTrackFailedWhy", "Could not delete the track: {0}").replace("{0}", r));
                })
                .fail(function (xhr) { toastr.error(T("DeleteTrackFailedWhy", "Could not delete the track: {0}").replace("{0}", (xhr.responseText || xhr.statusText || "").toString().slice(0, 80))); });
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

            // the photo strip is resized with its own top handle (see OurTravel.js)
            initEditorPanel();
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

            // a chosen description file is read into the box (the box is what gets saved)
            $("#fileText").on("change", function () {
                var f = this.files && this.files[0];
                if (!f) return;
                var r = new FileReader();
                r.onload = function () { $("#descriptionText").val(String(r.result).replace(/\r\n/g, "\n")); };
                r.readAsText(f);
                this.value = "";
            });

            $("#pointDescr").on("input", storePointText);

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

                        $("#fromLocation").val(initialTrack.startName || "");
                        $("#toLocation").val(initialTrack.endName || "");
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
                        // the description text is edited in place; it is loaded as the viewer loads it (the old files have mixed encodings)
                        if (initialTrack.textToRead) {
                            $.ajax({ url: "tracks/content/" + initialTrack.textToRead + "?" + Math.random(), dataType: "text" })
                                .done(function (t) { $("#descriptionText").val(String(t).replace(/\r\n/g, "\n")); });
                        }
                        $("#defaultScale").val(initialTrack.defaultScale);
                        map.setZoom(initialTrack.defaultScale);

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
                var t = "aman.gif";
                $("#velocityMetersPerSec").val(Math.round(5 * 10 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
            else if (x == "Bike") {
                var t = "mybike.png";
                $("#velocityMetersPerSec").val(Math.round(15 * 50 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
            else if (x == "Car") {
                var t = "mycar.png";
                $("#velocityMetersPerSec").val(Math.round(100 * 100 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
            else if (x == "Bus") {
                var t = "mybus.png";
                $("#velocityMetersPerSec").val(Math.round(80 * 100 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
            else if (x == "Yacht") {
                var t = "myyacht.png";
                $("#velocityMetersPerSec").val(Math.round(40 * 100 * 1000 / 3660));
                $("#icon").val(t);
                setAnimatedMarkerIcon(t);
            }
            else if (x == "Plane") {
                var t = "myplane.png";
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
        // Import a track from a file: GPX, KML/KMZ (Google My Maps), GeoJSON or a Google Timeline export (see js/trackimport.js).
        // A file with several tracks / days opens a small chooser; the chosen points replace the current ones
        // and very long tracks are thinned to about 1,000 points.
        function applyImported(c) {
            var pts = c.points, total = pts.length;
            if (total > 1000) pts = window.sytSimplifyPath(pts, 1000);
            points.empty();
            $.each(pts, function (i, p) {
                var arr = [+p[0].toFixed(6), +p[1].toFixed(6)];
                if (p[2]) arr.push(p[2]);
                var v = JSON.stringify(arr);
                points.append($("<option></option>").attr("value", v).text(v));
            });
            points[0].selectedIndex = 0;
            points.change();
            updateMap();
            var nameBox = $("#name");
            if (c.label && (!nameBox.val() || /^New track /.test(nameBox.val()))) nameBox.val(c.label);
            toastr.success(T("GpxImported", "Imported {0} points").replace("{0}", pts.length) + (total > pts.length ? T("GpxReducedFrom", " (reduced from {0})").replace("{0}", total) : ""));
        }

        function handleFileSelect(evt) {
            var input = evt.target, f = input.files && input.files[0];
            if (!f) return;
            var reset = function () { input.value = ""; };   // allows importing the same file again
            sytTrackImport.read(f).then(function (list) {
                if (!list.length) { toastr.error(T("GpxNone", "No track points found in this file.")); return null; }
                return list.length === 1 ? list[0] : sytTrackImport.choose(list);
            }).then(function (c) { if (c) applyImported(c); reset(); }).catch(function (err) {
                var m = { toobig: ["ImportTooBig", "This file is too large to read in the browser (over 250 MB). Export a shorter period."],
                          kmz: ["ImportKmz", "This browser cannot open KMZ files. Export plain KML or use a newer browser."],
                          unknown: ["ImportUnknown", "This file type is not recognised. Supported: GPX, KML/KMZ, GeoJSON and Google Timeline (JSON)."] }[err && err.code]
                        || ["ImportInvalid", "This file could not be read. Is it a valid GPX, KML, GeoJSON or Timeline file?"];
                toastr.error(T(m[0], m[1]));
                reset();
            });
        }
    </script>

</asp:Content>
