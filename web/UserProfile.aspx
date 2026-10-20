<%@ Page Title="See Your Travel: User Profile" Language="C#" MasterPageFile="MasterPage.master" CodeFile="UserProfile.aspx.cs" Inherits="UserProfile" %>

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
                    <div><%=Tools.GetUserName(this)%>: <span class="i" data-i18n="[title]MyProfile;MyProfile">My Profile</span></div>
                    <br />
                    <b href="UserProfile.aspx" class="i" data-i18n="[title]MyProfile;MyProfile">My Profile</b>
                    <a href="UserTracks.aspx" class="i" data-i18n="[title]MyTracks;MyTracks">My Tracks</a>
                    <a href="UserPhotos.aspx" class="i" data-i18n="[title]MyPhotos;MyPhotos">My photos</a>
                    <a href="UserPlaces.aspx" class="i" data-i18n="[title]MyPlaces;MyPlaces">My Places</a>
                    <br />
                    <br />
                    <span class="i" data-i18n="MyInformation">My information:</span> <%=Tools.GetUserInformation(this)%>
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

    <script>
        var photosList;
        $(function () {

            var imageDiv = $("#imageDiv");
            var polyline;
            var map;
            var markers;

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

            //    $("#imageDiv0").draggable().resizable({ minHeight: 50, minWidth: 50 });
            //    $("#textToReadArea0").draggable();
            //    $("#slider").slider({
            //        value: 0.8,
            //        min: 0,
            //        max: 1,
            //        step: 0.1,
            //        slide: function (event, ui) {
            //            audio.volume = ui.value;
            //        }
            //    });

            //    photosList = $("#photosList");

            //    fillPhotos();

            //    photosList.change(function () {
            //        var options = photosList.val();
            //        markers.clearLayers();
            //        var isMultiple = options.length > 1;
            //        $("#imageLatLng").val('');
            //        for (var i in options) {
            //            var parts = options[i].toString().split(';');
            //            var imgPath = "services/get_thumbnail.aspx?size=small&p=" + parts[0];
            //            $("#imageLatLng").val("".concat($("#imageLatLng").val(), parts[3], ",", parts[4], "; "));
            //            var ll = new L.LatLng(parseFloat(parts[3]), parseFloat(parts[4]))
            //            map.panTo(ll);


            //            var icon = L.icon({
            //                iconUrl: imgPath,
            //                //    shadowUrl: 'leaf-shadow.png',

            //                iconSize: [100, 100] // size of the icon
            //                //    shadowSize:   [50, 64], // size of the shadow
            //                    , iconAnchor: [50, 100] // point of the icon which will correspond to marker's location
            //                //    shadowAnchor: [4, 62],  // the same for the shadow
            //                //    popupAnchor:  [0, 0] // point from which the popup should open relative to the iconAnchor
            //            });

            //            //var text = '<img src>';
            //            //var domelem = document.createElement('div');
            //            //domelem.innerHTML = text;

            //            var marker = L.marker(ll,
            //                { icon: icon })
            //            //.bindPopup(domelem);
            //            markers.addLayer(marker);
            //        }
            //    });

            //    $("#buttonDelete").click(function () {
            //        if (photosList.val() != null) {
            //            var options = photosList.val();
            //            markers.clearLayers();
            //            var isMultiple = options.length > 1;
            //            $("#imageLatLng").val('');
            //            for (var i in options) {
            //                var parts = options[i].toString().split(';');
            //                var url = "services/delete_photobyfilename.aspx?fileName=" + parts[0];
            //                $.ajax({
            //                    //                    dataType: "jsonp",
            //                    url: url,
            //                    success: function (data) {
            //                        toastr.info("Photo is deleted", "", { timeOut: 5000, extendedTimeOut: 10000 });
            //                        fillPhotos();
            //                        $("#imageLatLng").val('');
            //                    },
            //                    error: function (XMLHttpRequest, textStatus, errorThrown) {
            //                        console.log("delete track error: " + textStatus); console.log("Error: " + errorThrown);
            //                        toastr.error(textStatus + "," + errorThrown, "ERROR", { timeOut: 5000, extendedTimeOut: 10000 });
            //                    }
            //                });
            //            }
            //        }
            //    });
            //});

            //function fillPhotos() {
            //    var fileListString = $.ajax(
            //{
            //    url: ('services/get_myphotos.aspx' + "?" + Math.random()),
            //    async: false,
            //    dataType: 'json'
            //}
            //).responseText;

            //    var fileList = fileListString.split('\n');
            //    photosList
            //            .find('option')
            //            .remove()
            //            .end();
            //    for (var i = 0; i < fileList.length; i++) {
            //        if (!isNullOrEmpty(fileList[i])) {
            //            var parts = fileList[i].split(';');
            //            photosList.append('<option value="' + fileList[i] + '">' + (parts[2] == 1 ? "" : "*") + parts[1] + '</option>');
            //        }
            //    }
        });
    </script>
</asp:Content>
