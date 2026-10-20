<%@ Page Title="See Your Travel Profile" Language="C#" MasterPageFile="MasterPage.master" CodeFile="UserPlaces.aspx.cs" Inherits="UserPlaces" %>

<%@ Import Namespace="System.IO" %>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadPlaceholder" runat="Server">

    <script>
        function clickCancel() {
            window.location = 'index.aspx';
        }

        function translateAll(err, t) {
            $(".i").i18n();
            $("option.i").i18n();
                        $("#profile").text($.t("Profile").replace("{0}",globalUserName));
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

    <div id="textToReadArea0" class="ui-widget-content" style="position: absolute; padding: 10px; z-index: 1001; top: 40px; right: 50px; width: 350px; height: 800px; background: rgba(255,255,255,0.8); border-radius: 12px; border: 0px solid #000;">
        <table border="0">
            <tr>
                <td>
                    <div><%=Tools.GetUserName(this)%>: <span class="i" data-i18n="[title]MyPlaces;MyPlaces">My Places</span></div>
                    <br />
                    <a href="UserProfile.aspx" class="i" data-i18n="[title]MyProfile;MyProfile">My Profile</a>
                    <a href="UserTracks.aspx" class="i" data-i18n="[title]MyTracks;MyTracks">My Tracks</a>
                    <a href="UserPhotos.aspx" class="i" data-i18n="[title]MyPhotos;MyPhotos">My photos</a>
                    <b href="UserPlaces.aspx" class="i" data-i18n="[title]MyPlaces;MyPlaces">My Places</b>
                    <br />
                    <br />
                    <span class="i" data-i18n="MyPlaces">My Places</span>
                    <br />
                    <select style="vertical-align: central; width: 330px;" id="placesList" class="i" size="15"></select>
                    <br />
                    <br />
                    <button type="button" id="buttonDelete" class="i" data-i18n="[title]DeleteSelected ;DeleteSelected">Delete Selected</button>
                    <br />
                    <br />
                    <span class="i" data-i18n="Placedescription">Place description</span><br />
                    <input type="text" name="placeDescription" id="placeDescription" value="" style="width: 330px" />
                    <br />
                    <br />
                    <span class="i" data-i18n="Placelink">Place Link</span><br />
                    <input type="text" name="placeLink" id="placeLink" value="" style="width: 240px" />&nbsp;
                    <button type="button" id="buttonCheckLink" class="i" data-i18n="[title]Checklink;Checklink">Check link</button>
                    <br />
                    <br />
                    <span class="i" data-i18n="Placecoordinates">Place coordinates</span><br />
                    <input type="text" name="placeLatLng" id="placeLatLng" value="" style="width: 330px" />
                    <br />
                    <br />
                    <span class="i" data-i18n="UploadPhoto">Upload photo:</span>
                    <br />
                    <input name="file" type="file" id="files" />
                    <br />
                    <br />
                    <input id="isPublic" name="isPublic" type="checkbox" value="isPublic" checked="checked" />
                    <label for="isPublic" class="i" data-i18n="Makepublic">Make public</label>
                    <br />
                    <br />
                    <input type="submit" id="buttonUpload" class="i" data-i18n="[title]Save;[value]Save" value="Save" />
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

        var placesList;
        var places = {};
        var imageDiv = $("#imageDiv");
        var polyline;
        var map;
        var markers;

        $(function () {

            function onMapClick(e) {
                $("#placeLatLng").val("".concat(e.latlng.lat, ";", e.latlng.lng));

                var imgPath = "";
                var placeId = placesList.val();
                if (placeId) {
                    var place = places[placeId];
                    //place.Name + ";" + place.Vicinity + ";" + (place.IsPublic ? 1 : 0) + ";" + place.Lat + ";" + place.Lng + ";" + place.Rating + place.FileName
                    imgPath = "services/get_thumbnail.aspx?size=small&p=" + place.FileName;
                    place.Name = $("#placeDescription").val();
                    place.IsPublic = $("#isPublic").prop('checked') ? "1" : "0";
                    place.Lat = e.latlng.lat.toString();
                    place.Lng = e.latlng.lng.toString();

                    updatePlaceData(placeId);
                }
                updateMap(e.latlng, imgPath);
            }

            var icon = L.icon({
                iconUrl: ("tracks/content/currentposition.png"),
                iconSize: [50, 50],
                iconAnchor: [1, 50],
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

            markers = new L.FeatureGroup();
            map.addLayer(markers);

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

            placesList = $("#placesList");

            fillPlaces();

            placesList.change(function () {
                var ddl = $(this);
                var previous = ddl.data('previous');
                ddl.data('previous', ddl.val());

                //var oldImageLatLng = $("#imageLatLng").val();
                var key = placesList.val();
                var place = places[key];
                var imgPath = "services/get_thumbnail.aspx?size=small&p=" + place.FileName;
                $("#isPublic").prop('checked', place.IsPublic);
                $("#placeDescription").val(place.Name);
                $("#placeLink").val(place.Link);
                $("#placeLatLng").val(place.Lat + ";" + place.Lng);
                var ll;
                try {
                    ll = new L.LatLng(parseFloat(place.Lat), parseFloat(place.Lng));
                }
                catch (error) {
                    ll = new L.LatLng(0, 0);
                }

                updateMap(ll, imgPath);
            });

            $("#buttonCheckLink").click(function () {
                window.open($("#placeLink").val(), "linkPreview");
            });

            $("#isPublic").change(function () {
                var options = placesList.val();
                var parts = options.toString().split(';');
                //var imgPath = "services/get_thumbnail.aspx?size=small&p=" + parts[0];
                parts[2] = $("#isPublic").prop('checked') ? "1" : "0";
                var data = parts.join(';');
                $("#placesList option:selected").val(data);
                updatePlaceData(data);

                //var latlng = new L.LatLng(parseFloat(parts[3]), parseFloat(parts[4]));
                //updateMap(latlng, imgPath);
            });

            function updatePlaceData(placeId) {
                //var url = "services/update_placedata.aspx?data=" + data;
                //$.ajax({
                //    //                    dataType: "jsonp",
                //    url: url,
                //    success: function (data) {
                //        toastr.info("Place is updated", "", { timeOut: 5000, extendedTimeOut: 10000 });
                //    },
                //    error: function (XMLHttpRequest, textStatus, errorThrown) {
                //        console.log("update place error: " + textStatus); console.log("Error: " + errorThrown);
                //        toastr.error(textStatus + "," + errorThrown, "ERROR", { timeOut: 5000, extendedTimeOut: 10000 });
                //    }
                //});
            }

            $("#buttonDelete").click(function () {
                if (placesList.val() != null) {
                    var options = placesList.val();
                    markers.clearLayers();
                    var parts = options.toString().split(';');
                    var url = "services/delete_placebyId.aspx?fileName=" + parts[7];
                    $.ajax({
                        //                    dataType: "jsonp",
                        url: url,
                        success: function (data) {
                            toastr.info("Place is deleted", "", { timeOut: 5000, extendedTimeOut: 10000 });
                            fillPlaces();
                            $("#imageLatLng").val('');
                        },
                        error: function (XMLHttpRequest, textStatus, errorThrown) {
                            console.log("delete place error: " + textStatus); console.log("Error: " + errorThrown);
                            toastr.error(textStatus + "," + errorThrown, "ERROR", { timeOut: 5000, extendedTimeOut: 10000 });
                        }
                    });
                }
            });

        });

        function fillPlaces() {
            var placesListString = $.ajax(
            {
                url: ('services/get_myplaces.aspx' + "?" + Math.random()),
                async: false,
                dataType: 'json'
            }).responseText;

            //var fileList = fileListString.split('\n');
            placesList
                    .find('option')
                    .remove()
                    .end();
            places = JSON.parse(placesListString);
            for (var key in places) {
                var place = places[key];
                //var parts = fileList[i].split(';');
                placesList.append('<option value="' + place.PlaceID + '">' + (place.IsPublic ? "" : "*") + place.Name + '</option>');
            }
        }

        function updateMap(ll, imgPath) {

            if (!imgPath)
                imgPath = "img/photoNotFound.png";

            //markers.clearLayers();
            map.panTo(ll);

            var icon = L.icon({
                iconUrl: imgPath,
                //    shadowUrl: 'leaf-shadow.png',

                iconSize: [100, 100] // size of the icon
                //    shadowSize:   [50, 64], // size of the shadow
                    , iconAnchor: [50, 100] // point of the icon which will correspond to marker's location
                //    shadowAnchor: [4, 62],  // the same for the shadow
                //    popupAnchor:  [0, 0] // point from which the popup should open relative to the iconAnchor
            });

            //var text = '<img src>';
            //var domelem = document.createElement('div');
            //domelem.innerHTML = text;

            var marker = L.marker(ll,
                { icon: icon })
            //.bindPopup(domelem);
            markers.addLayer(marker);
        }


    </script>
</asp:Content>
