<%@ Page Title="See Your Travel Profile" Language="C#" MasterPageFile="MasterPage.master" CodeFile="UserPhotos.aspx.cs" Inherits="UserPhotos" %>

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

    <div id="textToReadArea0" class="ui-widget-content" style="position: absolute; padding: 10px; z-index: 1001; top: 40px; right: 50px; width: 350px; height: 800px; background: rgba(255,255,255,0.8); border-radius: 12px; border: 0 solid #000;">
        <table border="0">
            <tr>
                <td>
                    <div><%=Tools.GetUserName(this)%>: <span class="i" data-i18n="[title]MyPhotos;MyPhotos">My Photos</span></div>
                    <br />
                    <a href="UserProfile.aspx" class="i" data-i18n="[title]MyProfile;MyProfile">My Profile</a>
                    <a href="UserTracks.aspx" class="i" data-i18n="[title]MyTracks;MyTracks">My Tracks</a>
                    <b href="UserPhotos.aspx" class="i" data-i18n="[title]MyPhotos;MyPhotos">My photos</b>
                    <a href="UserPlaces.aspx" class="i" data-i18n="[title]MyPlaces;MyPlaces">My Places</a>
                    <br />
                    <br />
                    <span class="i" data-i18n="MyPhotos">My Photos</span>
                    <br />
                    <select style="vertical-align: central; width: 330px;" id="photosList" class="i" size="15"></select>
                    <br />
                    <br />
                    <button type="button" id="buttonDelete" class="i" data-i18n="[title]DeleteSelected ;DeleteSelected">Delete Selected</button>
                    <br />
                    <br />
                    <span class="i" data-i18n="Photocoordinates">Photo coordinates</span><br />
                    <input type="text" readonly="true" id="imageLatLng" value="" style="width: 330px" />
                    <br />
                    <br />
                    <input id="isPublic" name="isPublic" type="checkbox" value="isPublic" checked="checked" />
                    <label for="isPublic" class="i" data-i18n="Makepublic">Make public</label>
                    <br />
                    <br />
                    <%--        <span class="i" data-i18n="UploadPhotos">Upload photos:</span>--%>
                    <br />
                    <input name="file" type="file" id="files" multiple="multiple" />
                    <br />
                    <br />
                    <input type="submit" id="buttonUpload" class="i" data-i18n="[title]Upload;[value]Upload" value="Upload" />
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

    <div id="dialog" title="Basic dialog">
        <%--        <p>This is the default dialog which is useful for displaying information. The dialog window can be moved, resized and closed with the 'x' icon.</p>--%>
        <a id="dialoglink" href="" title="">
            <img style="max-width: 100%; max-height: 100%;" id="dialogimage" src="" />
        </a>
    </div>

    <%--    <div style="position: absolute; left: 10px; top: 50px; z-index: 101;">
    </div>--%>
    <script>

        var imageDiv = $("#imageDiv");
        var polyline;
        var map;
        var markers;
        var photosList;
        var markersImages;
        var markerPhoto;

        $(function () {


            function onMapClick(e) {

                $("#imageLatLng").val("".concat(e.latlng.lat, ";", e.latlng.lng));
                var options = photosList.val();
                var parts = options.toString().split(';');
                parts[2] = $("#isPublic").prop('checked') ? "1" : "0";
                parts[3] = e.latlng.lat.toString();
                parts[4] = e.latlng.lng.toString();
                var data = parts.join(';');
                $("#photosList option:selected").val(data);

                updatePhotoData(data);

                updateMap(e.latlng, parts[0], parts[1]);
            }

            var icon = L.icon({
                iconUrl: ("tracks/content/currentposition.png"),
                iconSize: [50, 50],
                iconAnchor: [1, 50],
                shadowUrl: null
            });

            init(null);
            map.setView([50.430981, 30.539267], 8);


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

            photosList = $("#photosList");

            fillPhotos();

            photosList.change(function () {
                var ddl = $(this);
                var previous = ddl.data('previous');
                ddl.data('previous', ddl.val());

                var oldImageLatLng = $("#imageLatLng").val();
                var options = photosList.val();
                var parts = options.toString().split(";");
                $("#isPublic").prop('checked', parts[2] == "1");
                var ll;
                try {
                    ll = new L.LatLng(parseFloat(parts[3]), parseFloat(parts[4]));
                }
                catch (error) {
                    ll = new L.LatLng(0, 0);
                }
                $("#imageLatLng").val("".concat(ll.lat, ";", ll.lng));

                updateMap(ll, parts[0], parts[1]);
            });

            function updateMap(ll, fileName, text) {
                //markers.clearLayers();
                map.panTo(ll);

                var imgPath2 = "services/get_thumbnail.aspx?size=small&p=" + fileName;

                var icon = L.icon({
                    iconUrl: imgPath2,
                    //    shadowUrl: 'leaf-shadow.png',

                    iconSize: [100, 100] // size of the icon
                    //    shadowSize:   [50, 64], // size of the shadow
                        , iconAnchor: [50, 50] // point of the icon which will correspond to marker's location
                    //    shadowAnchor: [4, 62],  // the same for the shadow
                    //    popupAnchor:  [0, 0] // point from which the popup should open relative to the iconAnchor
                });

                var domelem = document.createElement('a');
                domelem.innerHTML = "<p>" + text + "</p><img height='300px' width='300px' src='" + imgPath2 + "'/>";
                domelem.title = text;
                domelem.href = "data/images/" + fileName;
                domelem.target = "_blank";

                if (markerPhoto)
                    markers.removeLayer(markerPhoto);
                markerPhoto = L.marker(ll,
                    { icon: icon })
                .bindPopup(domelem);

                markers.addLayer(markerPhoto);

            }

            $("#isPublic").change(function () {
                var options = photosList.val();
                var parts = options.toString().split(';');
                parts[2] = $("#isPublic").prop('checked') ? "1" : "0";
                var data = parts.join(';');
                $("#photosList option:selected").val(data);
                updatePhotoData(data);

                var latlng = new L.LatLng(parseFloat(parts[3]), parseFloat(parts[4]));
                updateMap(latlng, parts[0], parts[1]);
            })

            function updatePhotoData(data) {
                var url = "services/update_photodata.aspx?data=" + data;
                $.ajax({
                    //                    dataType: "jsonp",
                    url: url,
                    success: function (data) {
                        toastr.info("Photo is updated", "", { timeOut: 5000, extendedTimeOut: 10000 });
                    },
                    error: function (XMLHttpRequest, textStatus, errorThrown) {
                        console.log("update photo error: " + textStatus); console.log("Error: " + errorThrown);
                        toastr.error(textStatus + "," + errorThrown, "ERROR", { timeOut: 5000, extendedTimeOut: 10000 });
                    }
                });
            }

            $("#buttonDelete").click(function () {
                if (photosList.val() != null) {
                    var options = photosList.val();
                    //markers.clearLayers();
                    var parts = options.toString().split(';');
                    var url = "services/delete_photobyfilename.aspx?fileName=" + parts[0];
                    $.ajax({
                        //                    dataType: "jsonp",
                        url: url,
                        success: function (data) {
                            toastr.info("Photo is deleted", "", { timeOut: 5000, extendedTimeOut: 10000 });
                            fillPhotos();
                            $("#imageLatLng").val('');
                        },
                        error: function (XMLHttpRequest, textStatus, errorThrown) {
                            console.log("delete photo error: " + textStatus); console.log("Error: " + errorThrown);
                            toastr.error(textStatus + "," + errorThrown, "ERROR", { timeOut: 5000, extendedTimeOut: 10000 });
                        }
                    });
                }
            });
        });

        function fillPhotos() {

            if (typeof markersImages == "undefined") {
                markersImages = new L.markerClusterGroup({
                    //spiderfyOnMaxZoom: false,
                    showCoverageOnHover: false,
                    //zoomToBoundsOnClick: false,
                    maxClusterRadius: 50,
                    iconCreateFunction: function (cluster) {
                        var markersCount = cluster.getChildCount();
                        return L.divIcon({ html: markersCount, className: 'mycluster', iconSize: L.point(50, 30) });
                    },
                    zIndexOffset: 10000
                });
            }

            //markersImages.clearLayers();

            var url = 'services/get_myphotos.aspx' + "?" + Math.random();
            $.ajax(
            {
                url: url,
                //async: false,
                //dataType: 'json',
                error: function (XMLHttpRequest, textStatus, errorThrown) {
                    console.log("get_my_photos error: " + textStatus); console.log("Error: " + errorThrown);
                },
                success: function (data) {

                    var fileList = data.split('\n');
                    photosList
                            .find('option')
                            .remove()
                            .end();
                    for (var i = 0; i < fileList.length; i++) {
                        if (!isNullOrEmpty(fileList[i])) {
                            var parts = fileList[i].split(';');
                            photosList.append('<option value="' + fileList[i] + '">' + parts[1] + '</option>');


                            //var imgPath = "services/get_thumbnail.aspx?size=small&p=" + parts[0];

                            var ll;
                            try {
                                ll = new L.LatLng(parseFloat(parts[3]), parseFloat(parts[4]));
                            }
                            catch (error) {
                                ll = new L.LatLng(0, 0);
                            }

                            var text = parts[1];
                            var fileName = parts[0];
                            var domelem = document.createElement('a');
                            domelem.className = "autoclick";
                            var imgPath = "services/get_thumbnail.aspx?size=medium&p=" + fileName;
                            domelem.innerHTML = "<p>" + text + "</p><img class='popup-image'  width='300px' src=''/>";
                            domelem.title = text;
                            domelem.href = "data/images/" + fileName;
                            domelem.target = "sytbigimage";

                            var iconImage = L.icon({
                                iconUrl: "img/picture.png",//(imgPath),
                                //iconUrl: (imgPath),
                                iconSize: [20, 20],
                                iconAnchor: [10, 10],
                                //shadowUrl: null
                            });

                            var markerImage = L.marker(new L.LatLng(ll.lat, ll.lng),
                                { icon: iconImage, zIndexOffset: 10000 })
                                    .bindPopup(domelem);


                            markersImages.addLayer(markerImage);

                        }
                    }
                    map.addLayer(markersImages);

                    map.on('popupopen', function (e) {
                        var href = e.popup._content.href;

                        var popupImage = e.popup._content.childNodes[1];
                        popupImage.src = href;


                        //$("#dialoglink").attr("src", href);
                        //$("#dialoglink").attr("target", "sytbigimage");
                        //$("#dialoglink").attr("title", "TBD");
                        //$("#dialogimage").attr("src", href);
                        //$("#dialog").dialog();
                    });
                }
            });


        }

    </script>
</asp:Content>
