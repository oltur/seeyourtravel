<%@ Page Title="See Your Travel Profile" Language="C#" MasterPageFile="MasterPage.master" CodeFile="UserPlaces.aspx.cs" Inherits="UserPlaces" %>

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
            <h3 class="i" data-i18n="MyPlaces">My Places</h3>
            <!-- #Include virtual="include/pfSearch.inc" -->
            <ul class="pfList" id="placesList"></ul>
            <div class="pfRow" id="placeActions" style="display: none">
                <button type="button" class="pfBtn" id="buttonEditPlace"><i class="fa fa-pencil"></i> <span class="i" data-i18n="Edit">Edit</span></button>
                <button type="button" class="pfBtn danger" id="buttonDelete"><i class="fa fa-trash-o"></i> <span class="i" data-i18n="Delete">Delete</span></button>
            </div>

            <h3 id="formTitle"><span class="i" data-i18n="AddPlace">Add a place</span></h3>
            <div class="pfNote" style="margin-top: 0"><i class="fa fa-map-marker"></i> <span class="i" data-i18n="ClickMapForPlace">Click the map to choose where the place is.</span></div>
            <label for="placeDescription" class="i" data-i18n="Placedescription">Place description</label>
            <input type="text" name="placeDescription" id="placeDescription" value="" />
            <label for="placeLink" class="i" data-i18n="Placelink">Place Link</label>
            <div style="display: flex; gap: 6px">
                <input type="text" name="placeLink" id="placeLink" value="" placeholder="https://" />
                <button type="button" id="buttonCheckLink" class="pfBtn" title="Check link"><i class="fa fa-external-link"></i></button>
            </div>
            <label for="placeLatLng" class="i" data-i18n="Placecoordinates">Place coordinates</label>
            <input type="text" name="placeLatLng" id="placeLatLng" value="" readonly="readonly" />
            <div id="photoField">
                <label class="i" data-i18n="UploadPhoto">Upload photo:</label>
                <div class="pfFile"><input name="file" type="file" id="files" accept="image/*" /></div>
            </div>
            <label style="display: flex; align-items: center; gap: 8px; font-size: 13px; color: #1d2a3a; margin-top: 12px">
                <input id="isPublic" name="isPublic" type="checkbox" value="isPublic" style="width: auto" />
                <span class="i" data-i18n="PlacePublicHint">Show this place (and its photo) to all visitors on the map</span>
            </label>
            <div class="pfRow">
                <button type="submit" id="buttonUpload" class="pfBtn primary" disabled="disabled"><i class="fa fa-check"></i> <span class="i" data-i18n="Save">Save</span></button>
                <button type="button" id="buttonSaveEdit" class="pfBtn primary" style="display: none"><i class="fa fa-check"></i> <span class="i" data-i18n="SaveChanges">Save changes</span></button>
                <button type="button" id="buttonCancelEdit" class="pfBtn" style="display: none"><span class="i" data-i18n="Cancel">Cancel</span></button>
            </div>
        </div>
    </div>

    <div id="imageDiv0" class="ui-widget-content" style="visibility: hidden;">
        <div id="imageDiv" class="innerScrollArea">
            <ul></ul>
        </div>
    </div>

    <div id="map"></div>

    <script src="<%=Tools.V("js/pfsearch.js")%>"></script>
    <script>
        var map, markers;   // shadow the #map element so init() creates the map
        var places = [], current = null, newMarker = null, editing = null;

        function showPlace(p) {
            markers.clearLayers();
            var ll = new L.LatLng(p.Lat, p.Lng);
            var icon = p.FileName
                ? L.icon({ iconUrl: 'services/get_thumbnail.aspx?size=small&p=' + encodeURIComponent(p.FileName), iconSize: [90, 90], iconAnchor: [45, 45], className: 'photoPin' })
                : new L.Icon.Default();
            L.marker(ll, { icon: icon }).bindPopup($('<div>').text(p.Name).html()).addTo(markers);
            map.panTo(ll);
        }

        var aiRank = null;   // the assistant's answer {PlaceID: position}, or null while only the typed text filters
        function placeMatches(p) {
            if (aiRank) return aiRank[p.PlaceID] !== undefined;
            var q = $.trim($('#askText').val()).toLowerCase();
            return !q || String(p.Name || '').toLowerCase().indexOf(q) >= 0;
        }
        function renderPlaces() {
            var ul = $('#placesList').empty(), shown = places.filter(placeMatches);
            if (aiRank) shown.sort(function (a, b) { return aiRank[a.PlaceID] - aiRank[b.PlaceID]; });   // best match first
            shown.forEach(function (p) {
                var li = $('<li>').data('id', p.PlaceID);
                if (current && current.PlaceID === p.PlaceID) li.addClass('sel');
                $('<span class="nm">').text(p.Name).attr('title', p.Name).appendTo(li);
                $('<span class="pfBadge">').addClass(p.IsPublic ? 'pub' : 'priv').text(p.IsPublic ? T('Public', 'Public') : T('Private', 'Private')).appendTo(li);
                ul.append(li);
            });
            if (!shown.length) ul.append($('<li class="pfEmpty" style="display:block;cursor:default">').text(places.length ? T('NothingFound', 'Nothing found') : T('NoPlacesYet', 'No places yet.')));
        }

        function fillPlaces() {
            $.getJSON('services/get_myplaces.aspx?' + Math.random(), function (data) {
                places = $.map(data, function (v) { return v; });
                renderPlaces();
                current = null;
                setEditing(null);
                $('#placeActions').hide();
            });
        }

        function canSave() {
            var ok = !!($.trim($('#placeDescription').val()) && $('#placeLatLng').val());
            $('#buttonUpload,#buttonSaveEdit').prop('disabled', !ok);
        }

        function setEditing(p) {
            editing = p;
            $('#formTitle').html('<span>' + (p ? T('EditPlace', 'Edit place') : T('AddPlace', 'Add a place')) + '</span>');
            $('#photoField,#buttonUpload').toggle(!p);
            $('#buttonSaveEdit,#buttonCancelEdit').toggle(!!p);
            if (p) {
                $('#placeDescription').val(p.Name);
                $('#placeLink').val(p.Link || '');
                $('#placeLatLng').val(p.Lat + ';' + p.Lng);
                $('#isPublic').prop('checked', !!p.IsPublic);
                if (newMarker) map.removeLayer(newMarker);
                newMarker = L.marker([p.Lat, p.Lng]).addTo(map);
            } else {
                $('#placeDescription,#placeLink,#placeLatLng').val('');
                $('#isPublic').prop('checked', false);
                if (newMarker) { map.removeLayer(newMarker); newMarker = null; }
            }
            canSave();
        }

        $(function () {
            init(null);
            map.setView([50.430981, 30.539267], 6);
            markers = L.featureGroup().addTo(map);
            fillPlaces();
            sytPfSearch({ url: 'services/place_search.aspx', idsOf: function (d) { return (d.places || []).map(function (x) { return x.id; }); },
                          apply: function (rank) { aiRank = rank; renderPlaces(); } });

            $('#placesList').on('click', 'li', function () {
                var id = $(this).data('id');
                if (!id) return;
                current = places.filter(function (p) { return p.PlaceID === id; })[0];
                $('#placesList li').removeClass('sel'); $(this).addClass('sel');
                $('#placeActions').show();
                showPlace(current);
            });

            map.on('click', function (e) {
                $('#placeLatLng').val(e.latlng.lat + ';' + e.latlng.lng);
                if (newMarker) map.removeLayer(newMarker);
                newMarker = L.marker(e.latlng).addTo(map);
                canSave();
            });
            $('#placeDescription').on('input', canSave);
            $('#buttonCheckLink').click(function () { if ($.trim($('#placeLink').val())) window.open($('#placeLink').val(), 'linkPreview'); });

            $('#buttonEditPlace').click(function () { if (current) { setEditing(current); $('#placeDescription').focus(); } });
            $('#buttonCancelEdit').click(function () { setEditing(null); });
            $('#buttonSaveEdit').click(function () {
                if (!editing) return;
                var ll = $('#placeLatLng').val().split(';');
                $.ajax({
                    url: 'services/update_place.aspx', type: 'POST', headers: { 'X-Requested-With': 'XMLHttpRequest' },
                    data: { id: editing.PlaceID, name: $('#placeDescription').val(), link: $('#placeLink').val(), lat: ll[0], lng: ll[1], isPublic: $('#isPublic').prop('checked') ? 1 : 0 },
                    success: function () {
                        toastr.info(T('PlaceUpdated', 'Place is updated'), '', { timeOut: 3000 });
                        markers.clearLayers();
                        fillPlaces();
                    },
                    error: function (x, s, e) { toastr.error((x.responseText || s) + '', 'ERROR', { timeOut: 6000 }); }
                });
            });

            $('#buttonDelete').click(function () {
                if (!current) return;
                if (!confirm(T('DeletePlaceConfirm', 'Delete this place permanently? This cannot be undone.'))) return;
                $.ajax({
                    url: 'services/delete_placebyId.aspx?id=' + encodeURIComponent(current.PlaceID),
                    success: function (r) {
                        if ($.trim(String(r)) !== 'OK') { toastr.error(String(r)); return; }
                        toastr.info(T('PlaceDeleted', 'Place is deleted'), '', { timeOut: 3000 });
                        markers.clearLayers();
                        fillPlaces();
                    },
                    error: function (x, s, e) { toastr.error((x.responseText || s) + '', 'ERROR', { timeOut: 5000 }); }
                });
            });
        });
    </script>
</asp:Content>
