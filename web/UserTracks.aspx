<%@ Page Title="See Your Travel Profile" Language="C#" MasterPageFile="MasterPage.master" CodeFile="UserTracks.aspx.cs" Inherits="UserTracks" %>

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
    <div id='pageContent' style='height: 100%;'>
        <!-- #Include virtual="include/profileMenu.inc" -->
    </div>
    <!-- #Include virtual="include/profileHelpPanel.inc" -->
    <!-- #Include virtual="include/settingsPanel.inc" -->


    <div id="textToReadArea0" class="ui-widget-content" style="position: absolute; padding: 10px; z-index: 1001; top: 40px; right: 50px; width: 350px; height: 950px; background: rgba(255,255,255,0.8); border-radius: 12px; border: 0 solid #000;">
        <table border="0">
            <tr>
                <td>
                    <div><%=Tools.GetUserName(this)%>: <span class="i" data-i18n="[title]MyTracks;MyTracks">My Tracks</span></div>
                    <br />
                    <a href="UserProfile.aspx" class="i" data-i18n="[title]MyProfile;MyProfile">My Profile</a>
                    <b href="UserTracks.aspx" class="i" data-i18n="[title]MyTracks;MyTracks">My Tracks</b>
                    <a href="UserPhotos.aspx" class="i" data-i18n="[title]MyPhotos;MyPhotos">My photos</a>
                    <a href="UserPlaces.aspx" class="i" data-i18n="[title]MyPlaces;MyPlaces">My Places</a>
                    <br />
                    <br />
                    <span class="i" data-i18n="MyTracks">My Tracks</span>
                    <br />
                    <select style="vertical-align: central; width: 330px;" id="tracksList" size="15"></select>
                    <br />
                    <button type="button" id="buttonNew" class="i" data-i18n="[title]New;New">New</button>
                    <button type="button" id="buttonEdit" class="i" data-i18n="[title]Edit;Edit">Edit</button>
                    <button type="button" id="buttonDelete" class="i" data-i18n="[title]DeleteSelected;DeleteSelected">Delete Selected</button>
                    <br />
                    <br />
                    <div id="elevationChartDiv">
                    </div>
                    <input type="text" id="frameUrl" value="" style="width: 250px" />
                    <button type="button" id="buttonShow" class="i" data-i18n="[title]Show;Show">Show</button>
                    <br />
                    <div id="divframe"></div>
                </td>
            </tr>
        </table>
    </div>

    <div id="imageDiv0" class="ui-widget-content" style="visibility: hidden;">
        <div id="imageDiv" class="innerScrollArea">
            <ul></ul>
        </div>
    </div>

    <div id="map"></div>

    <%--    <div style="position: absolute; left: 10px; top: 50px; z-index: 101;">
    </div>--%>
    <script>
        var tracksList;
        var imageDiv = $("#imageDiv");
        var polyline;
        var map;
        var markers;
        var markersTracks;
        var line;

        function onMapClick(e) {
            //updateTrackData(e);
            //updateMap();
        }

        var icon = L.icon({
            iconUrl: ("tracks/content/currentposition.png"),
            iconSize: [50, 50],
            iconAnchor: [1, 50],
            shadowUrl: null
        });

        function fillTracks() {
            $.ajax(
            {
                url: ('services/get_mytracks.aspx' + "?" + Math.random()),
                error: function (XMLHttpRequest, textStatus, errorThrown) {
                    console.log("fillTracks error: " + textStatus); console.log("Error: " + errorThrown);
                    toastr.error(textStatus + "," + errorThrown, "ERROR", { timeOut: 5000, extendedTimeOut: 10000 });
                },
                success: function (data) {
                    var fileListString = data;
                    markersTracks.clearLayers();

                    var fileList = fileListString.split('\n');
                    tracksList
                            .find('option')
                            .remove()
                            .end();
                    for (var i = 0; i < fileList.length; i++) {
                        if (!isNullOrEmpty(fileList[i])) {
                            var parts = fileList[i].split(';');
                            tracksList.append('<option value="' + parts[0] + '">' + (parts[2] == 1 ? "" : "*") + parts[1] + '</option>');

                            var location = JSON.parse(parts[3]);

                            var text = parts[1];
                            var fileName = parts[0];
                            var imgPath = (parts[4]) ? ("tracks/content/" + parts[4]) : ("img/track.png");
                            var domelem = document.createElement('a');
                            //domelem.href = place.name;
                            domelem.innerHTML = "<p>" + text + "</p><img height='100px' width='100px' src='" + imgPath + "'/>";
                            domelem.alt = text;
                            domelem.href = "./index.aspx?trackname=" + fileName;
                            domelem.target = "_blank";

                            var iconTrack = L.icon({
                                iconUrl: ('img/track.png'),
                                iconSize: [40, 40],
                                iconAnchor: [20, 20],
                                //shadowUrl: null
                            });

                            var markerTrack = L.marker(new L.LatLng(location.lat - 0.0002 + Math.random() * 0.0004, location.lng - 0.0002 + Math.random() * 0.0004),
                                { icon: iconTrack })
                                    .bindPopup(domelem);

                            markersTracks.addLayer(markerTrack);
                        }
                    }
                }
            });
        }

        $(function () {

            init(null);
            map.setView([50.430981, 30.539267], 8);

            //map = L.map('map', { zoomControl: false }).setView([50.430981, 30.539267], 8);
            //L.control.zoom({ position: 'topright' }).addTo(map);
            //L.control.scale({ position: 'bottomleft' }).addTo(map);
            //tileLayer = L.tileLayer(mapTileUrl, {
            //    attribution: 'SeeYourTravel.com &copy; Map data &copy; <a href="https://www.mapbox.com/">MapBox</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://cloudmade.com">CloudMade</a> <img src="img/poweredbygoolge/desktop/powered-by-google-on-white.png"/>',
            //    maxZoom: 18,
            //    id: "mapbox.streets"
            //});

            //tileLayer.addTo(map);
            markerPosition = L.marker(new L.LatLng(1000, 1000), { icon: icon }).addTo(map);

            //markers = new L.FeatureGroup();
            //map.addLayer(markers);

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

            tracksList = $("#tracksList");

            fillTracks();

            tracksList.change(function () {
                var s = '<iframe style="width: 330px; height: 250px;" src="' + '<%=Request.Url.GetLeftPart(UriPartial.Authority) + Request.ApplicationPath%>' + "frame.aspx?trackname=" + tracksList.val() + '"></iframe>'
                $("#frameUrl").val(s);
                $("#divframe").html("");

                var path = translateTracksPath(tracksList.val() + ".js");
                track = loadTrack(path,
                    function (tempTrack) {
                        track = tempTrack;
                        //markers.clearLayers();
                        if (line)
                            markers.removeLayer(line);

                        var elevator = new google.maps.ElevationService;
                        elevator.getElevationAlongPath({
                            'path': compactTrackData(track.trackData),
                            'samples': 128
                        }, plotElevation);

                        line = L.polyline(track.trackData, { color: 'green' });
                        markers.addLayer(line);

                        map.panTo(track.trackData[0]);

                    });
            });
            $("#buttonShow").click(function () {
                $("#divframe").html($("#frameUrl").val());
            });
            $("#buttonNew").click(function () {
                window.location = "editor.aspx";
            });
            $("#buttonEdit").click(function () {
                window.location = "editor.aspx?trackname=" + tracksList.val();
            });
            $("#buttonDelete").click(function () {
                var names = tracksList.val();
                if (names == null || names.length === 0) return;
                if (!$.isArray(names)) names = [names];
                var labels = tracksList.find('option:selected').map(function () { return $(this).text(); }).get();
                var what = names.length === 1 ? '"' + labels[0] + '"' : T("TracksCount", "{0} tracks").replace("{0}", names.length);
                if (!confirm(T("DeleteTracksConfirm", "Delete {0} permanently? This cannot be undone.").replace("{0}", what))) return;
                var done = 0, failed = [];
                (function next() {
                    if (!names.length) {
                        if (done) toastr.info(done === 1 ? T("TrackDeleted", "Track is deleted") : T("TracksDeleted", "{0} tracks are deleted").replace("{0}", done), "", { timeOut: 5000, extendedTimeOut: 10000 });
                        failed.forEach(function (f) { toastr.error(T("DeleteTrackFailedWhy", "Could not delete the track: {0}").replace("{0}", f), "", { timeOut: 8000 }); });
                        fillTracks();
                        $("#frameUrl").val("");
                        $("#divframe").html("");
                        return;
                    }
                    var name = names.shift();
                    $.post("services/delete_trackbyfilename.aspx", { fileName: name })
                        .done(function (r) { if ($.trim(String(r)) === "OK") done++; else failed.push($.trim(String(r))); })
                        .fail(function (xhr) { failed.push((xhr.responseText || xhr.statusText || "").toString().slice(0, 80)); })
                        .always(next);
                })();
            });
        });

    </script>
</asp:Content>
