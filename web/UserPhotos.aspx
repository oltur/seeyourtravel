<%@ Page Title="See Your Travel Profile" Language="C#" MasterPageFile="MasterPage.master" CodeFile="UserPhotos.aspx.cs" Inherits="UserPhotos" %>

<%@ Import Namespace="System.IO" %>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadPlaceholder" runat="Server">
    <link rel="stylesheet" href="<%=Tools.V("styles/profile.css")%>" />


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

    <div id="textToReadArea0" class="profilePanel">
        <!-- #Include virtual="include/profileTabs.inc" -->
        <div class="pfBody">
            <div class="pfNote" style="margin-top: 0"><i class="fa fa-lock"></i> <span class="i" data-i18n="PhotosPrivate">Your own photos are private: they are never shown to other visitors or on the map.</span></div>

            <h3 class="i" data-i18n="MyPhotos">My photos</h3>
            <div class="pfGrid" id="photosGrid"></div>
            <div class="pfEmpty" id="noPhotos" style="display: none"><span class="i" data-i18n="NoPhotosYet">No photos yet.</span></div>

            <div id="photoInfo" style="display: none">
                <label for="imageLatLng" class="i" data-i18n="Photocoordinates">Photo coordinates</label>
                <input type="text" readonly="readonly" id="imageLatLng" value="" />
                <div class="pfNote"><i class="fa fa-map-marker"></i> <span class="i" data-i18n="ClickMapToPlace">Click the map to set where this photo was taken.</span></div>
                <div class="pfRow">
                    <a class="pfBtn" id="buttonOpenPhoto" target="_blank" href="#"><i class="fa fa-eye"></i> <span class="i" data-i18n="Open">Open</span></a>
                    <button type="button" class="pfBtn danger" id="buttonDelete"><i class="fa fa-trash-o"></i> <span class="i" data-i18n="Delete">Delete</span></button>
                </div>
            </div>

            <h3 class="i" data-i18n="UploadPhotos">Upload photos</h3>
            <div class="pfFile">
                <input name="file" type="file" id="files" multiple="multiple" accept="image/*" />
                <div class="pfRow" style="justify-content: center; margin-bottom: 0">
                    <button type="submit" id="buttonUpload" class="pfBtn primary"><i class="fa fa-upload"></i> <span class="i" data-i18n="Upload">Upload</span></button>
                </div>
            </div>
        </div>
    </div>

    <div id="imageDiv0" class="ui-widget-content" style="visibility: hidden;">
        <div id="imageDiv" class="innerScrollArea">
            <ul></ul>
        </div>
    </div>

    <div id="map"></div>

    <script>
        var map, markers;   // shadow the #map element so init() creates the map
        var markersImages, markerPhoto, photos = [], current = null;

        function esc(t) { return $('<div>').text(t).html(); }

        function hasLoc(p) { return isFinite(parseFloat(p.lat)) && isFinite(parseFloat(p.lng)); }

        function updatePhotoData(p) {
            // the service takes "file;description;isPublic;lat;lng"
            $.ajax({
                url: 'services/update_photodata.aspx?data=' + encodeURIComponent([p.id, String(p.desc).replace(/;/g, ','), p.pub, p.lat, p.lng].join(';')),
                success: function () { toastr.info(T('PhotoUpdated', 'Photo is updated'), '', { timeOut: 3000 }); },
                error: function (x, s, e) { toastr.error(s + ',' + e, 'ERROR', { timeOut: 5000 }); }
            });
        }

        function showPhoto(p) {
            if (markerPhoto) { markers.removeLayer(markerPhoto); markerPhoto = null; }
            if (!hasLoc(p)) return;
            var ll = new L.LatLng(parseFloat(p.lat), parseFloat(p.lng));
            var thumb = 'services/get_thumbnail.aspx?size=small&p=' + encodeURIComponent(p.id);
            markerPhoto = L.marker(ll, { icon: L.icon({ iconUrl: thumb, iconSize: [90, 90], iconAnchor: [45, 45], className: 'photoPin' }), zIndexOffset: 20000 }).addTo(markers);
            map.panTo(ll);
        }

        function select(p) {
            current = p;
            $('#photosGrid button').removeClass('sel').filter(function () { return $(this).data('id') === p.id; }).addClass('sel');
            $('#photoInfo').show();
            $('#imageLatLng').val(hasLoc(p) ? parseFloat(p.lat).toFixed(5) + '; ' + parseFloat(p.lng).toFixed(5) : T('NoLocation', 'no location yet'));
            $('#buttonOpenPhoto').attr('href', 'data/images/' + p.id);
            showPhoto(p);
        }

        function fillPhotos() {
            if (!markersImages) {
                markersImages = new L.markerClusterGroup({
                    showCoverageOnHover: false, maxClusterRadius: 50,
                    iconCreateFunction: function (c) { return L.divIcon({ html: c.getChildCount(), className: 'mycluster', iconSize: L.point(50, 30) }); }
                });
                map.addLayer(markersImages);
            }
            markersImages.clearLayers();
            $.get('services/get_myphotos.aspx?' + Math.random(), function (data) {
                photos = [];
                var seen = {};
                $.each($.trim(data) ? data.split('\n') : [], function (_, r) {
                    var q = r.split(';');
                    if (seen[q[0]]) return;
                    seen[q[0]] = 1;
                    photos.push({ id: q[0], desc: q[1], pub: q[2], lat: q[3], lng: q[4] });
                });
                var grid = $('#photosGrid').empty();
                photos.forEach(function (p) {
                    $('<button type="button">').data('id', p.id).attr('title', p.desc).toggleClass('noloc', !hasLoc(p))
                        .css('background-image', 'url(services/get_thumbnail.aspx?size=small&p=' + encodeURIComponent(p.id) + ')')
                        .click(function () { select(p); }).appendTo(grid);
                    if (hasLoc(p)) L.marker([parseFloat(p.lat), parseFloat(p.lng)], { icon: L.icon({ iconUrl: 'img/picture.png', iconSize: [20, 20], iconAnchor: [10, 10] }) })
                        .on('click', function () { select(p); }).addTo(markersImages);
                });
                $('#noPhotos').toggle(!photos.length);
                if (markersImages.getLayers().length) map.fitBounds(markersImages.getBounds(), { paddingTopLeft: [40, 40], paddingBottomRight: [440, 40], maxZoom: 12 });
            });
        }

        $(function () {
            init(null);
            map.setView([50.430981, 30.539267], 6);
            markers = L.featureGroup().addTo(map);

            map.on('click', function (e) {
                if (!current) return;
                current.lat = e.latlng.lat; current.lng = e.latlng.lng;
                updatePhotoData(current);
                select(current);
                fillPhotosKeepSelection();
            });

            function fillPhotosKeepSelection() {
                var id = current && current.id;
                fillPhotos();
                $(document).one('ajaxStop', function () {
                    var again = photos.filter(function (p) { return p.id === id; })[0];
                    if (again) { current = again; $('#photosGrid button').filter(function () { return $(this).data('id') === id; }).addClass('sel'); }
                });
            }

            fillPhotos();

            $('#buttonDelete').click(function () {
                if (!current) return;
                if (!confirm(T('DeletePhotoConfirm', 'Delete this photo permanently? This cannot be undone.'))) return;
                $.ajax({
                    url: 'services/delete_photobyfilename.aspx?fileName=' + encodeURIComponent(current.id),
                    success: function () {
                        toastr.info(T('PhotoDeleted', 'Photo is deleted'), '', { timeOut: 3000 });
                        current = null; $('#photoInfo').hide();
                        if (markerPhoto) { markers.removeLayer(markerPhoto); markerPhoto = null; }
                        fillPhotos();
                    },
                    error: function (x, s, e) { toastr.error(s + ',' + e, 'ERROR', { timeOut: 5000 }); }
                });
            });
        });
    </script>
</asp:Content>
