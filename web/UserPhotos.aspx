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
            <div id="listView">
            <div class="pfNote" style="margin-top: 0"><i class="fa fa-lock"></i> <span class="i" data-i18n="PhotosPrivate">Your own photos are private: they are never shown to other visitors or on the map.</span></div>

            <div class="pfChips pfTabs" id="viewTabs">
                <button type="button" data-t="photos" class="on"><i class="fa fa-picture-o"></i> <span class="i" data-i18n="MyPhotos">My photos</span></button>
                <button type="button" data-t="people"><i class="fa fa-users"></i> <span class="i" data-i18n="People">People</span> <em>0</em></button>
            </div>

            <div id="peoplePane" style="display: none">
                <div class="pfNote" style="margin-top: 0"><i class="fa fa-info-circle"></i> <span class="i" data-i18n="PeopleHint">Faces are found and grouped automatically. Open a person to see their photos, give a name, merge groups that are the same person or block someone: blocked people disappear from all photos. To fix a single face, open the photo and click the face.</span></div>
                <input type="text" id="peopleSearch" placeholder="Search" data-i18n="[placeholder]SearchPeople" />
                <div class="pfPeople" id="peopleGrid"></div>
                <div class="pfEmpty" id="noPeople" style="display: none"><span class="i" data-i18n="NoPeople">No people found yet.</span></div>
            </div>

            <div id="personBar" class="pfPerson" style="display: none">
                <img id="personCover" alt="" />
                <div class="pnm"><b id="personName"></b> <span class="pfBadge" id="personBlocked" style="display: none"><i class="fa fa-ban"></i> <span class="i" data-i18n="Blocked">Blocked</span></span></div>
                <button type="button" class="pfBtn" id="personRename"><i class="fa fa-pencil"></i> <span class="i" data-i18n="Rename">Rename</span></button>
                <button type="button" class="pfBtn" id="personMerge"><i class="fa fa-compress"></i> <span class="i" data-i18n="MergeInto">Merge into…</span></button>
                <button type="button" class="pfBtn danger" id="personBlock"></button>
                <button type="button" class="pfBtn" id="personClose" title="Back"><i class="fa fa-times"></i></button>
            </div>

            <div id="photosPane">
            <!-- #Include virtual="include/pfSearch.inc" -->
            <div class="pfChips" id="photoFilter">
                <button type="button" data-f="all" class="on"><span class="i" data-i18n="All">All</span> <em>0</em></button>
                <button type="button" data-f="pub"><i class="fa fa-globe"></i> <span class="i" data-i18n="Public">Public</span> <em>0</em></button>
                <button type="button" data-f="priv"><i class="fa fa-lock"></i> <span class="i" data-i18n="Private">Private</span> <em>0</em></button>
            </div>
            <div class="pfChips" id="scopeFilter">
                <button type="button" data-s="all" class="on"><i class="fa fa-th"></i> <span class="i" data-i18n="ScopeAll">Whole list</span></button>
                <button type="button" data-s="view"><i class="fa fa-crosshairs"></i> <span class="i" data-i18n="ScopeView">In map view</span> <em>0</em></button>
            </div>
            <div class="pfChips" id="timeFilter" style="display: none"></div>
            <div class="pfChips" id="monthFilter" style="display: none"></div>
            <div class="pfNote" id="bulkBar" style="display: none; align-items: center; gap: 8px; flex-wrap: wrap">
                <span id="bulkCount"></span>
                <button type="button" class="pfBtn" id="bulkPrivate"><i class="fa fa-lock"></i> <span class="i" data-i18n="BulkPrivate">Make all private</span></button>
                <button type="button" class="pfBtn danger" id="bulkDelete"><i class="fa fa-trash-o"></i> <span class="i" data-i18n="BulkDelete">Delete all</span></button>
            </div>
            <div class="pfGrid" id="photosGrid"></div>
            <div class="pfEmpty" id="noPhotos" style="display: none"><span class="i" data-i18n="NoPhotosYet">No photos yet.</span></div>

            <div id="photoInfo" style="display: none">
                <div style="margin-bottom: 6px; display: flex; align-items: center; gap: 8px">
                    <span class="pfBadge" id="photoStatus"></span>
                    <button type="button" class="pfBtn" id="buttonTogglePub" style="padding: 3px 10px; font-size: 12px"></button>
                </div>
                <label for="imageLatLng" class="i" data-i18n="Photocoordinates">Photo coordinates</label>
                <input type="text" readonly="readonly" id="imageLatLng" value="" />
                <div class="pfRow">
                    <button type="button" class="pfBtn primary" id="buttonPreview"><i class="fa fa-search-plus"></i> <span class="i" data-i18n="Preview">Preview</span></button>
                    <a class="pfBtn" id="buttonOpenPhoto" target="_blank" href="#"><i class="fa fa-eye"></i> <span class="i" data-i18n="Open">Open</span></a>
                    <button type="button" class="pfBtn" id="buttonRotL" title="Rotate left (Shift+R)"><i class="fa fa-rotate-left"></i></button>
                    <button type="button" class="pfBtn" id="buttonRotR" title="Rotate right (R)"><i class="fa fa-rotate-right"></i></button>
                    <button type="button" class="pfBtn danger" id="buttonDelete" title="Delete (Del)"><i class="fa fa-trash-o"></i> <span class="i" data-i18n="Delete">Delete</span></button>
                </div>
            </div>

            <h3 class="i" data-i18n="UploadPhotos">Upload photos</h3>
            <div class="pfFile">
                <input name="file" type="file" id="files" multiple="multiple" accept="image/*" />
                <div class="pfRow" style="justify-content: center; margin-bottom: 0">
                    <button type="submit" id="buttonUpload" class="pfBtn primary"><i class="fa fa-upload"></i> <span class="i" data-i18n="Upload">Upload</span></button>
                </div>
            </div>
            </div><!-- /photosPane -->
            </div>

            <div id="photoView" style="display: none">
                <div class="pfRow" style="margin-top: 0; align-items: center">
                    <button type="button" class="pfBtn" id="pvBack"><i class="fa fa-arrow-left"></i> <span class="i" data-i18n="BackToPhotos">Back to photos</span></button>
                    <span id="pvCount" style="margin-left: auto; font-size: 12px; color: #7a8aa0"></span>
                </div>
                <div class="pvStage">
                    <img id="pvImg" alt="" />
                    <div id="pvFaces"></div>
                    <button type="button" class="pvNav prev" id="pvPrev" title="Previous"><i class="fa fa-chevron-left"></i></button>
                    <button type="button" class="pvNav next" id="pvNext" title="Next"><i class="fa fa-chevron-right"></i></button>
                </div>
                <div class="pvCaption"><span id="pvTitle"></span> <span class="pvWho" id="pvWho"></span> <span class="pfBadge" id="pvStatus"></span></div>
                <div class="pfRow" style="margin-bottom: 0">
                    <button type="button" class="pfBtn" id="pvToggle"></button>
                    <button type="button" class="pfBtn" id="pvFacesBtn" title="Show / hide faces"><i class="fa fa-user-circle-o"></i> <span class="i" data-i18n="Faces">Faces</span></button>
                    <a class="pfBtn" id="pvOpen" target="_blank" href="#"><i class="fa fa-eye"></i> <span class="i" data-i18n="Open">Open</span></a>
                    <button type="button" class="pfBtn" id="pvRotL" title="Rotate left (Shift+R)"><i class="fa fa-rotate-left"></i></button>
                    <button type="button" class="pfBtn" id="pvRotR" title="Rotate right (R)"><i class="fa fa-rotate-right"></i></button>
                    <button type="button" class="pfBtn danger" id="pvDelete" title="Delete (Del)"><i class="fa fa-trash-o"></i> <span class="i" data-i18n="Delete">Delete</span></button>
                </div>
            </div>
        </div>
    </div>

    <div id="imageDiv0" class="ui-widget-content" style="visibility: hidden;">
        <div id="imageDiv" class="innerScrollArea">
            <ul></ul>
        </div>
    </div>

    <div id="picker" style="display: none">
        <div class="pkHead"><b id="pkTitle"></b><button type="button" id="pkClose" class="pfBtn" style="padding: 2px 8px">&times;</button></div>
        <div id="pkActions"></div>
        <input type="text" id="pkSearch" placeholder="Search" data-i18n="[placeholder]SearchPeople" />
        <div id="pkList"></div>
        <div class="pkNew"><input type="text" id="pkNewName" maxlength="100" placeholder="New person" data-i18n="[placeholder]NewPerson" /><button type="button" class="pfBtn primary" id="pkNewBtn"><i class="fa fa-plus"></i> <span class="i" data-i18n="Create">Create</span></button></div>
    </div>

    <div id="map"></div>

    <script>
        window.keepMapView = true;   // the shared location code must not re-centre this map on the user's position
        var map, markers;   // shadow the #map element so init() creates the map
        var markersImages, markerPhoto, photos = [], current = null;

        function esc(t) { return $('<div>').text(t).html(); }

        function hasLoc(p) { return isFinite(parseFloat(p.lat)) && isFinite(parseFloat(p.lng)); }

        function updatePhotoData(p) {
            // the service takes "file;description;isPublic;lat;lng"
            $.ajax({
                url: 'services/update_photodata.aspx?data=' + encodeURIComponent([p.id, String(p.desc).replace(/;/g, ','), p.pub, p.lat, p.lng].join(';')),
                success: function () { toastr.info(T('PhotoUpdated', 'Photo is updated'), '', { timeOut: 3000 }); },
                error: function (x, s, e) { toastr.error((x.responseText && x.responseText.length < 200 ? x.responseText : s + ',' + e), 'ERROR', { timeOut: 8000 }); }
            });
        }

        function showPhoto(p) {
            if (markerPhoto) { markers.removeLayer(markerPhoto); markerPhoto = null; }
            if (!hasLoc(p)) return;
            var ll = new L.LatLng(parseFloat(p.lat), parseFloat(p.lng));
            var thumb = 'services/get_thumbnail.aspx?size=small&p=' + encodeURIComponent(p.id);
            markerPhoto = L.marker(ll, { icon: L.icon({ iconUrl: thumb, iconSize: [90, 90], iconAnchor: [45, 45], className: 'photoPin' }), zIndexOffset: 20000 }).addTo(markers);
            if (!inPreview && !map.getBounds().contains(ll)) map.panTo(ll);   // only when picked in the list and off screen; paging through photos (preview, arrow keys) never moves the map
        }

        function select(p) {
            current = p;
            $('#photosGrid button').removeClass('sel').filter(function () { return $(this).data('id') === p.id; }).addClass('sel');
            $('#photoInfo').show();
            var isPub = p.pub == '1';
            $('#photoStatus').attr('class', 'pfBadge ' + (isPub ? 'pub' : 'priv'))
                .html('<i class="fa fa-' + (isPub ? 'globe' : 'lock') + '"></i> ' + esc(isPub ? T('Public', 'Public') : T('Private', 'Private')));
            $('#buttonTogglePub').text(isPub ? T('MakePrivate', 'Make private') : T('MakePublic', 'Make public'));
            $('#imageLatLng').val(hasLoc(p) ? parseFloat(p.lat).toFixed(5) + '; ' + parseFloat(p.lng).toFixed(5) : T('NoLocation', 'no location yet'));
            $('#buttonOpenPhoto').attr('href', 'data/images/' + p.id);
            $('#buttonTogglePub, #buttonDelete, #buttonRotL, #buttonRotR').toggle(!p.ext);   // somebody else's public photo can be looked at, not changed
            if (p.ext) $('#photoStatus').attr('class', 'pfBadge pub').html('<i class="fa fa-globe"></i> ' + esc(T('PublicOther', 'Public photo of someone else')));
            showPhoto(p);
        }

        var filter = 'all';
        var firstFit = true;
        // map position, scale and the two filters live in the address (?lat=&lng=&z=&f=&s=), so a reload or a shared link comes back to the same view
        function urlState() {
            var q = {};
            try { new URLSearchParams(location.search).forEach(function (v, k) { q[k] = v; }); } catch (e) { }
            return q;
        }
        function saveState() {
            try {
                var q = new URLSearchParams(location.search), c = map.getCenter();
                q.set('lat', c.lat.toFixed(5)); q.set('lng', c.lng.toFixed(5)); q.set('z', map.getZoom());
                if (filter !== 'all') q.set('f', filter); else q.delete('f');
                if (scope !== 'all') q.set('s', scope); else q.delete('s');
                if (yearSel) q.set('y', yearSel); else q.delete('y');
                if (monthSel) q.set('m', monthSel); else q.delete('m');
                history.replaceState(null, '', location.pathname + '?' + q.toString() + location.hash);
            } catch (e) { }
        }
        var isPub = function (p) { return p.pub == '1'; };
        var inPreview = false, listScroll = 0;

        var scope = 'all';   // 'view' = only the photos inside the current map view
        function inView(p) { return hasLoc(p) && map.getBounds().contains([parseFloat(p.lat), parseFloat(p.lng)]); }
        // people: a photo that shows a blocked person is hidden everywhere (except in that person's own list, so the block can be undone)
        var photoNames = {}, people = [], personFilter = null, personFiles = null, tab = 'photos', pvFacesOn = true, curFaces = [];
        function vis(p) { return p.blk !== '1' || (personFilter && personFilter.blocked); }
        // time taken: a year, and inside a year a month (the third way to narrow the list, next to person and map view)
        var yearSel = null, monthSel = null, rangeFrom = null, rangeTo = null, searchRank = null, searchVer = 0;
        function keyOf(p) { return p.id.replace(/\.[^.]*$/, '').toLowerCase(); }
        function inTime(p) { if (rangeFrom) return !!p.date && p.date >= rangeFrom && p.date <= rangeTo; return !yearSel || (p.date && p.date.substr(0, 4) === yearSel && (!monthSel || p.date.substr(5, 2) === monthSel)); }
        function isShown(p) { return vis(p) && inSearch(p) && inTime(p) && (personFiles === null || personFiles[p.id]) && (filter === 'all' || (filter === 'pub') === isPub(p)) && (scope !== 'view' || inView(p)); }
        function inSearch(p) { return searchRank === null || searchRank[keyOf(p)] !== undefined; }
        function shownPhotos() {
            var l = photos.filter(isShown);
            if (searchRank !== null) l.sort(function (a, b) { return searchRank[keyOf(b)] - searchRank[keyOf(a)]; });   // best match first
            return l;
        }

        // ---- one photo, big ----
        function renderPreview() {
            var p = current; if (!p) return;
            var list = shownPhotos(), i = list.indexOf(p);
            if (p.ext) { curFaces = []; $('#pvFaces').empty(); } else loadFaces(p);
            $('#pvToggle, #pvDelete, #pvRotL, #pvRotR').toggle(!p.ext);
            var base = encodeURIComponent(p.id.replace(/\.[^.]*$/, ''));
            var img = document.getElementById('pvImg'), big = 'data/thumbs/1600/' + base + '.jpg' + (p.v ? '?v=' + p.v : '');
            var vq = p.v ? '?v=' + p.v : '';
            img.src = 'data/thumbs/480/' + base + '.jpg' + vq;                 // the small copy shows at once ...
            var loader = new Image();
            loader.onload = function () { if (current === p && inPreview) img.src = big; };   // ... then the large one
            loader.onerror = function () { if (current === p && inPreview) img.src = 'data/images/' + encodeURIComponent(p.id); };
            loader.src = big;
            $('#pvTitle').text(p.desc); showWho();
            var pub = isPub(p);
            $('#pvStatus').attr('class', 'pfBadge ' + (pub ? 'pub' : 'priv')).html('<i class="fa fa-' + (pub ? 'globe' : 'lock') + '"></i> ' + esc(pub ? T('Public', 'Public') : T('Private', 'Private')));
            $('#pvToggle').text(pub ? T('MakePrivate', 'Make private') : T('MakePublic', 'Make public'));
            $('#pvOpen').attr('href', 'data/images/' + p.id);
            $('#pvCount').text((i + 1) + ' / ' + list.length);
            $('#pvPrev').prop('disabled', i <= 0); $('#pvNext').prop('disabled', i < 0 || i >= list.length - 1);
        }

        function openPreview(p) {
            if (!p) return;
            if (!inPreview) listScroll = $('#photosGrid')[0].scrollTop;
            inPreview = true;
            select(p);
            $('#listView').hide(); $('#photoView').show();
            $('.pfBody').scrollTop(0);
            renderPreview();
        }

        function closePreview() {
            if (!inPreview) return;
            inPreview = false;
            $('#photoView').hide(); $('#listView').show();
            var g = $('#photosGrid')[0];
            paintGrid(true);
            g.scrollTop = listScroll;                                     // back to where the list was
            paintGrid(false);
            if (current) gridReveal(current);
        }

        function stepPreview(d) {
            var list = shownPhotos(), i = list.indexOf(current) + d;
            if (i >= 0 && i < list.length) { select(list[i]); renderPreview(); }
        }

        // ---- the photo list is windowed: with tens of thousands of photos only the rows in view (plus a few) exist as elements ----
        var gridList = [], gridCols = 1, gridRowH = 90, gridFrom = -1, gridTo = -1, photosVer = 0, markerKey = '', pinRenderer = null;
        function paintGrid(force, toTop) {
            var g = $('#photosGrid')[0];
            if (!g.clientWidth) return;   // hidden (big preview open): painted again when it comes back
            var w = g.clientWidth - 4;
            gridCols = Math.max(1, Math.floor((w + 6) / 90));
            gridRowH = (w - (gridCols - 1) * 6) / gridCols + 6;
            if (toTop) g.scrollTop = 0;
            var rows = Math.ceil(gridList.length / gridCols);
            var r0 = Math.max(0, Math.floor(g.scrollTop / gridRowH) - 2), r1 = Math.min(rows, Math.ceil((g.scrollTop + g.clientHeight) / gridRowH) + 2);
            var from = r0 * gridCols, to = Math.min(gridList.length, r1 * gridCols);
            if (!force && from === gridFrom && to === gridTo) return;
            gridFrom = from; gridTo = to;
            var inner = document.createElement('div');
            inner.className = 'pfGridIn';
            inner.style.paddingTop = (r0 * gridRowH) + 'px';
            inner.style.paddingBottom = (Math.max(0, rows - r1) * gridRowH) + 'px';
            for (var i = from; i < to; i++) inner.appendChild(gridButton(gridList[i]));
            $('#photosGrid').empty().append(inner);
        }
        function gridButton(p) {
            var pub = isPub(p), names = photoNames[p.id];
            var b = $('<button type="button">').data('id', p.id).attr('title', p.desc + ' (' + (pub ? T('Public', 'Public') : T('Private', 'Private')) + ')' + (names ? ' \u2014 ' + names.join(', ') : ''))
                .toggleClass('noloc', !hasLoc(p)).toggleClass('sel', !!current && current.id === p.id)
                .css('background-image', 'url(data/thumbs/480/' + encodeURIComponent(p.id.replace(/\.[^.]*$/, '')) + '.jpg' + (p.v ? '?v=' + p.v : '') + ')')   // ready-made copy
                .append(names ? $('<span class="pfWho">').text(names.join(', ')) : null)
                .append('<span class="pfFlag ' + (pub ? 'pub' : 'priv') + '"><i class="fa fa-' + (pub ? 'globe' : 'lock') + '"></i></span>')
                .click(function () { select(p); });
            return b[0];
        }
        // scroll the list so that this photo is in view (it may not be an element at the moment)
        function gridReveal(p) {
            var g = $('#photosGrid')[0], i = gridList.indexOf(p);
            if (i < 0 || !g.clientWidth) return;
            var top = Math.floor(i / gridCols) * gridRowH;
            if (top < g.scrollTop || top + gridRowH > g.scrollTop + g.clientHeight) g.scrollTop = Math.max(0, top - gridRowH);
            paintGrid(false);
        }

        // the grid and the map pins show the current filter; every photo carries a public (globe) or private (lock) flag
        function renderGrid(fit) {
            var base = photos.filter(function (p) { return vis(p) && inSearch(p) && (personFiles === null || personFiles[p.id]); });
            renderTime(base);
            var pool = base.filter(inTime);
            var nPub = pool.filter(isPub).length;
            $('#photoFilter [data-f=all] em').text(pool.length);
            $('#photoFilter [data-f=pub] em').text(nPub);
            $('#photoFilter [data-f=priv] em').text(pool.length - nPub);
            var shown = shownPhotos();
            $('#scopeFilter [data-s=view] em').text(pool.filter(inView).length);
            $('#bulkBar').css('display', scope === 'view' ? 'flex' : 'none');
            $('#bulkCount').text(shown.filter(function (p) { return !p.ext; }).length + ' ' + T('PhotosInView', 'photos in the map view'));
            $('#bulkPrivate, #bulkDelete').prop('disabled', !shown.length);
            // the map pins do not depend on the map-view scope: they are built again only when the set of photos (or a public/private flag) changed.
            // All of them are added in one call: adding thousands one by one makes the cluster layer recalculate every time.
            var mkey = [photosVer, searchVer, rangeFrom, yearSel, monthSel, pool.length, nPub, pool.length ? pool[0].id : '', pool.length ? pool[pool.length - 1].id : ''].join('|');
            if (mkey !== markerKey) {
                markerKey = mkey;
                markersImages.clearLayers();
                var pins = [];
                pool.forEach(function (p) {
                    if (!hasLoc(p)) return;
                    pins.push(L.circleMarker([parseFloat(p.lat), parseFloat(p.lng)], { renderer: pinRenderer || (pinRenderer = L.canvas({ padding: 0.5 })), radius: 7, weight: 2, color: '#fff', fillColor: p.ext ? '#2f7de1' : isPub(p) ? '#23a455' : '#5b6b80', fillOpacity: 1 })   // light dots drawn on one canvas, not an element each
                        .on('click', function () { select(p); }));
                });
                markersImages.addLayers(pins);
            }
            gridList = shown;
            paintGrid(true, true);
            if (fit && scope !== 'view' && markersImages.getLayers().length) map.fitBounds(markersImages.getBounds(), { paddingTopLeft: [40, 40], paddingBottomRight: [440, 40], maxZoom: 12 });
        }

        // year (and month) chips with the number of photos; counts follow the person filter, so a chip never leads to an empty list
        function renderTime(base) {
            var years = {}, months = {};
            base.forEach(function (p) {
                if (!p.date) return;
                var y = p.date.substr(0, 4); years[y] = (years[y] || 0) + 1;
                if (y === yearSel) { var m = p.date.substr(5, 2); months[m] = (months[m] || 0) + 1; }
            });
            var ys = Object.keys(years).sort().reverse();
            if (base.length) {   // an empty list means the photos are not loaded yet: keep what the address asked for
                if (yearSel && !years[yearSel]) { yearSel = monthSel = null; }
                if (monthSel && !months[monthSel]) monthSel = null;
            }
            var h = rangeFrom ? '<button type="button" data-r="1" class="on"><i class="fa fa-calendar"></i> ' + esc(rangeFrom + ' – ' + rangeTo) + ' <i class="fa fa-times"></i></button>' : '';
            h += '<button type="button" data-y="" class="' + (yearSel || rangeFrom ? '' : 'on') + '"><i class="fa fa-calendar"></i> ' + esc(T('AllTime', 'Any time')) + '</button>';
            ys.forEach(function (y) { h += '<button type="button" data-y="' + y + '" class="' + (y === yearSel ? 'on' : '') + '">' + y + ' <em>' + years[y] + '</em></button>'; });
            $('#timeFilter').html(h).toggle(ys.length > 1 || !!yearSel || !!rangeFrom);
            var mh = '';
            if (yearSel) {
                var lang = (window.i18next && i18next.language) || navigator.language || 'en';
                for (var m = 1; m <= 12; m++) {
                    var k = (m < 10 ? '0' : '') + m; if (!months[k]) continue;
                    var nm; try { nm = new Date(2000, m - 1, 1).toLocaleDateString(lang, { month: 'short' }); } catch (e) { nm = k; }
                    mh += '<button type="button" data-m="' + k + '" class="' + (k === monthSel ? 'on' : '') + '">' + esc(nm) + ' <em>' + months[k] + '</em></button>';
                }
            }
            $('#monthFilter').html(mh).toggle(!!mh);
        }

        // what the chat assistant is told about this screen (see js/chat.js): the filters, how many photos are shown and which, the open photo, the map
        window.sytChatContext = function () {
            var c = { page: 'my photos' };
            try {
                var list = shownPhotos(), years = {}, who = {}, min = '', max = '';
                list.forEach(function (p) {
                    if (p.date) { var y = p.date.substr(0, 4); years[y] = (years[y] || 0) + 1; if (!min || p.date < min) min = p.date; if (p.date > max) max = p.date; }
                    (photoNames[p.id] || []).forEach(function (n) { who[n] = (who[n] || 0) + 1; });
                });
                var top = Object.keys(who).sort(function (a, b) { return who[b] - who[a]; }).slice(0, 8).map(function (n) { return n + ' (' + who[n] + ')'; });
                c.photos_in_library = photos.filter(function (p) { return !p.ext; }).length;
                c.photos_shown_now = list.length;
                c.filters = {
                    public_or_private: filter === 'all' ? 'all' : (filter === 'pub' ? 'public only' : 'private only'),
                    area: scope === 'view' ? 'only photos inside the current map view' : 'whole library',
                    year: yearSel, month: monthSel, from: rangeFrom, to: rangeTo,
                    person: personFilter ? personLabel(personFilter) : null,
                    ai_search_active: searchRank !== null, search_box_text: $.trim($('#askText').val()).slice(0, 120),
                    assistant_summary: $('#askBar').is(':visible') ? $('#askSay').text().slice(0, 160) : null
                };
                c.shown_photos_taken = { first: min, last: max, per_year: years };
                // the photos on screen right now (the visible part of the list): description, date, public/private, who is on it, where
                var vis = (typeof gridList !== 'undefined' && gridList) ? gridList.slice(Math.max(0, gridFrom), Math.min(Math.max(gridTo, 0), Math.max(0, gridFrom) + 40)) : list.slice(0, 40);
                c.photos_on_screen_now = vis.map(function (p) {
                    return { description: String(p.desc || '').slice(0, 60), taken: p.date || '', visibility: p.ext ? 'public photo of another person' : (p.pub == '1' ? 'public' : 'private'),
                             people: photoNames[p.id] && photoNames[p.id].length ? photoNames[p.id] : undefined, lat: hasLoc(p) ? +parseFloat(p.lat).toFixed(2) : undefined, lng: hasLoc(p) ? +parseFloat(p.lng).toFixed(2) : undefined };
                });
                if (top.length) c.people_in_shown_photos = top;
                if (window.map) { var m = map.getCenter(), b = map.getBounds(); c.map_centre = { lat: +m.lat.toFixed(4), lng: +m.lng.toFixed(4) }; c.map_zoom = map.getZoom(); c.map_view = { south: +b.getSouth().toFixed(3), west: +b.getWest().toFixed(3), north: +b.getNorth().toFixed(3), east: +b.getEast().toFixed(3) }; }
                if (current) c.open_photo = { description: String(current.desc || '').slice(0, 120), taken: current.date || '', public: current.pub == '1', lat: hasLoc(current) ? +parseFloat(current.lat).toFixed(5) : null, lng: hasLoc(current) ? +parseFloat(current.lng).toFixed(5) : null, people: photoNames[current.id] || [] };
            } catch (e) { }
            return c;
        };

        // ---- search by words and the assistant ----
        // Enter: the assistant (Gemini, through the site) turns the sentence into a person, a time, a place, public/private and "what it looks like";
        // the look is found by the local photo search. If the assistant is off or over its limit, the whole sentence is used as the look.
        var askSeq = 0, askSet = null, askRecent = [];   // askRecent: the last three requests, for follow-ups ("only from 2023")
        function matchPerson(name) {
            var n = $.trim(name).toLowerCase(); if (!n) return null;
            var c = people.filter(function (x) { return x.name; });
            return c.filter(function (x) { return x.name.toLowerCase() === n; })[0]
                || c.filter(function (x) { return x.name.toLowerCase().indexOf(n) === 0 || n.indexOf(x.name.toLowerCase()) === 0; })[0]
                || c.filter(function (x) { return x.name.toLowerCase().indexOf(n) >= 0; })[0] || null;
        }
        function clearAsk(quiet) {
            askSeq++;
            var a = askSet; askSet = null; if (!quiet) askRecent = [];
            searchRank = null; searchVer++; rangeFrom = rangeTo = null; dropForeign();
            $('#askBar').hide(); $('#askText').val(quiet ? $('#askText').val() : '');
            if (a) {
                if (a.person) { personFilter = null; personFiles = null; $('#personBar').hide(); }
                if (a.vis) { filter = 'all'; $('#photoFilter button').removeClass('on').filter('[data-f=all]').addClass('on'); }
                if (a.bbox) { scope = 'all'; $('#scopeFilter button').removeClass('on').filter('[data-s=all]').addClass('on'); }
            }
            if (markersImages) renderGrid(false);
            saveState();
        }
        // the photos of other people that the search found (public ones; for administrators every photo is in the list anyway) are added to the list for as long as the search lasts
        function dropForeign() { var n = photos.length; photos = photos.filter(function (p) { return !p.ext; }); if (photos.length !== n) photosVer++; }
        function mergeFound(files) {
            dropForeign();
            var have = {}, r = {}, added = 0; photos.forEach(function (p) { have[keyOf(p)] = 1; });
            (files || []).forEach(function (f, i) {
                var k = String(f[0]).toLowerCase(), m = f[2]; r[k] = f[1] || (files.length - i) / 1000;   // no score (the chat's list): keep its order
                if (m && !have[k]) { added++; photos.push({ id: m.file, desc: m.desc, pub: m.pub ? '1' : '0', lat: m.lat == null ? '' : String(m.lat), lng: m.lng == null ? '' : String(m.lng), blk: '0', date: m.date || '', ext: !m.mine }); }
            });
            if (added) photosVer++;
            return r;
        }
        // the chat found these photos: show exactly them (also used after the chat sent the person here from another page)
        window.sytApplyFound = function (files, label) {
            if (askSet) clearAsk(true);
            askSeq++; askSet = { person: false, vis: false, bbox: false };
            rangeFrom = rangeTo = null; yearSel = monthSel = null;
            searchRank = mergeFound(files); searchVer++;
            renderGrid(false); saveState();
            $('#askSay').text(label || ''); $('#askBar').css('display', 'flex');
        };
        function searchWords(words, done) {
            $.getJSON('services/photo_search.aspx?q=' + encodeURIComponent(words), function (d) {
                done(mergeFound(d.files), (d.files || []).length);
            }).fail(function () { done(null, 0); });
        }
        function runAsk(text) {
            var my = ++askSeq; text = $.trim(text); if (!text) { clearAsk(); return; }
            $('#askGo').prop('disabled', true);
            var finish = function () { if (my === askSeq) $('#askGo').prop('disabled', false); };
            function apply(f, note) {
                if (my !== askSeq) return;
                // forget what the last question set, then set the new one
                var old = askSet; askSet = { person: false, vis: false, bbox: false };
                searchRank = null; searchVer++; rangeFrom = rangeTo = null; yearSel = monthSel = null; dropForeign();
                if (old && old.person) { personFilter = null; personFiles = null; }
                var said = [f.say || ''];
                var go = function () {
                    if (my !== askSeq) return;
                    var fin = function (rank, n) {
                        if (my !== askSeq) return;
                        if (f.visual) { if (rank === null) said.push(T('SearchOff', 'Search by looks is not running.')); else { searchRank = rank; searchVer++; } }
                        renderGrid(false); saveState();
                        var left = shownPhotos().length;
                        if (!left) said.push(T('SearchNone', 'Nothing matches.'));
                        $('#askSay').text($.trim(said.concat(note ? [note] : []).join(' '))); $('#askBar').css('display', 'flex'); finish();
                    };
                    if (f.visual) searchWords(f.visual, fin); else fin(null, 0);
                };
                if (f.from && f.to) { rangeFrom = f.from; rangeTo = f.to; }
                if (f.visibility) { askSet.vis = true; filter = f.visibility === 'public' ? 'pub' : 'priv'; $('#photoFilter button').removeClass('on').filter('[data-f=' + filter + ']').addClass('on'); }
                else { filter = 'all'; $('#photoFilter button').removeClass('on').filter('[data-f=all]').addClass('on'); }
                if (f.bbox) {
                    askSet.bbox = true; scope = 'view'; $('#scopeFilter button').removeClass('on').filter('[data-s=view]').addClass('on');
                    map.fitBounds([[f.bbox[0], f.bbox[1]], [f.bbox[2], f.bbox[3]]], { animate: false });
                } else if (old && old.bbox) { scope = 'all'; $('#scopeFilter button').removeClass('on').filter('[data-s=all]').addClass('on'); }
                var who = f.person ? matchPerson(f.person) : null;
                if (f.person && !who) said.push(T('NoSuchPerson', 'There is no person named') + ' “' + f.person + '”.');
                if (who) { askSet.person = true; openPerson(who, go); } else { if (old && old.person) $('#personBar').hide(); go(); }
            }
            $.ajax({ url: 'services/assistant.aspx', method: 'POST', data: { text: text, prev: JSON.stringify(askRecent) }, dataType: 'json' })
                .done(function (f) {
                    if (f && f.ok) { askRecent.push(text); askRecent = askRecent.slice(-3); apply(f, ''); return; }
                    // the assistant is off, over its limit or failing: use the sentence as it is
                    var why = f && f.error === 'limit' ? T('AssistLimit', 'The assistant has reached its limit for now; searched by words instead.') : T('AssistOff', 'The assistant is not available; searched by words instead.');
                    apply({ say: '', visual: text }, why);
                })
                .fail(function () { apply({ say: '', visual: text }, T('AssistOff', 'The assistant is not available; searched by words instead.')); });
        }

        function fillPhotos() {
            if (!markersImages) {
                markersImages = new L.markerClusterGroup({
                    showCoverageOnHover: false, maxClusterRadius: 50,
                    iconCreateFunction: function (c) { return L.divIcon({ html: c.getChildCount(), className: 'mycluster', iconSize: L.point(50, 30) }); }
                });
                map.addLayer(markersImages);
            }
            $.get('services/get_myphotos.aspx?' + Math.random(), function (data) {
                photos = [];
                var seen = {};
                $.each($.trim(data) ? data.split('\n') : [], function (_, r) {
                    var q = r.split(';');
                    if (q.length < 5 || seen[q[0]]) return;   // a description with a line break leaves a broken fragment
                    seen[q[0]] = 1;
                    photos.push({ id: q[0], desc: q[1], pub: q[2], lat: q[3], lng: q[4], blk: q[5], date: q[6] || '' });
                });
                photosVer++;
                var fit = firstFit; firstFit = false;   // fit the map to the photos only when the address did not say where to look
                renderGrid(fit);
                $('#noPhotos').toggle(!photos.length);
                if (/[?&]chat=1/.test(location.search)) {   // sent here by the chat: show the photos it found
                    try { var c = JSON.parse(sessionStorage.getItem('sytChatPhotos') || 'null'); sessionStorage.removeItem('sytChatPhotos'); if (c && c.files) window.sytApplyFound(c.files, c.label); } catch (e) { }
                    try { history.replaceState(null, '', location.pathname + location.search.replace(/[?&]chat=1/, '').replace(/^&/, '?')); } catch (e) { }
                }
            });
        }


        // ---------------- people ----------------
        function personLabel(p) { return p.name || T('Unnamed', 'Unnamed'); }
        function coverUrl(id) { return 'services/face_crop.aspx?id=' + encodeURIComponent(id); }

        function loadNames() {
            $.getJSON('services/people.aspx?action=names&_=' + Date.now(), function (d) {
                photoNames = d.names || {};
                renderGrid(false); showWho();
            });
        }
        function showWho() { var n = current && photoNames[current.id]; $('#pvWho').text(n ? '· ' + n.join(', ') : ''); }

        function loadPeople(done) {
            loadNames();
            $.getJSON('services/people.aspx?action=list&_=' + Date.now(), function (d) {
                people = d.people || [];
                $('#viewTabs [data-t=people] em').text(people.filter(function (p) { return !p.blocked; }).length);
                if (tab === 'people') renderPeople();
                if (personFilter) { var again = people.filter(function (p) { return p.id === personFilter.id; })[0]; if (again) { personFilter = again; showPersonBar(); } }
                if (done) done();
            });
        }

        function renderPeople() {
            var q = $.trim($('#peopleSearch').val()).toLowerCase();
            var list = people.filter(function (p) { return !q || personLabel(p).toLowerCase().indexOf(q) >= 0; });
            list.sort(function (a, b) { return (a.blocked - b.blocked) || ((!!b.name) - (!!a.name)) || (b.count - a.count); });   // named first, blocked last
            var g = $('#peopleGrid').empty();
            list.forEach(function (p) {
                $('<button type="button" class="pcard">').toggleClass('blocked', p.blocked).toggleClass('unnamed', !p.name).attr('title', personLabel(p))
                    .append(p.cover ? $('<img alt="" loading="lazy">').attr('src', coverUrl(p.cover)) : '<span class="noface"><i class="fa fa-user"></i></span>')
                    .append($('<span class="pn">').text(personLabel(p))).append($('<span class="pc">').text(p.count))
                    .append(p.blocked ? '<span class="pb"><i class="fa fa-ban"></i></span>' : '')
                    .click(function () { openPerson(p); }).appendTo(g);
            });
            $('#noPeople').toggle(!list.length);
        }

        function setTab(t) {
            tab = t;
            $('#viewTabs button').removeClass('on').filter('[data-t=' + t + ']').addClass('on');
            $('#peoplePane').toggle(t === 'people'); $('#photosPane').toggle(t === 'photos');
            if (t === 'people') { closePersonFilter(); loadPeople(); }
        }

        function showPersonBar() {
            var p = personFilter; if (!p) { $('#personBar').hide(); return; }
            $('#personBar').show();
            $('#personName').text(personLabel(p) + ' (' + p.count + ')');
            if (p.cover) $('#personCover').attr('src', coverUrl(p.cover)).show(); else $('#personCover').hide();
            $('#personBlocked').toggle(p.blocked);
            $('#personBlock').html(p.blocked ? '<i class="fa fa-check"></i> ' + esc(T('Unblock', 'Unblock')) : '<i class="fa fa-ban"></i> ' + esc(T('Block', 'Block')));
        }

        function openPerson(p, done) {
            personFilter = p; personFiles = null;
            $.getJSON('services/people.aspx?action=photos&person=' + encodeURIComponent(p.id), function (d) {
                personFiles = {}; (d.files || []).forEach(function (f) { personFiles[f] = 1; });
                setTab('photos'); showPersonBar();
                filter = 'all'; $('#photoFilter button').removeClass('on').filter('[data-f=all]').addClass('on');
                renderGrid(false); saveState();
                if (done) done();
            });
        }

        function closePersonFilter() {
            if (!personFilter && personFiles === null) return;
            personFilter = null; personFiles = null; $('#personBar').hide();
            if (typeof renderGrid === 'function' && markersImages) renderGrid(false);
        }

        // a small window to pick a person (or type a new name); used for merging and for naming a face
        function pickPerson(title, opts, done) {
            var $p = $('#picker'); $p.data('done', done);
            $('#pkTitle').text(title); $('#pkSearch').val(''); $('#pkNewName').val('');
            var acts = $('#pkActions').empty();
            (opts.actions || []).forEach(function (a) { $('<button type="button" class="pfBtn">').toggleClass('danger', !!a.danger).html(a.html).click(function () { $p.hide(); a.run(); }).appendTo(acts); });
            function fill() {
                var q = $.trim($('#pkSearch').val()).toLowerCase(), l = $('#pkList').empty();
                people.filter(function (x) { return x.id !== opts.exclude && (!q || personLabel(x).toLowerCase().indexOf(q) >= 0); })
                    .sort(function (a, b) { return ((!!b.name) - (!!a.name)) || (b.count - a.count); }).slice(0, 80).forEach(function (x) {
                        $('<button type="button" class="pkItem">').append(x.cover ? $('<img alt="">').attr('src', coverUrl(x.cover)) : '').append($('<span>').text(personLabel(x) + ' (' + x.count + ')'))
                            .click(function () { $p.hide(); done({ person: x.id }); }).appendTo(l);
                    });
            }
            $('#pkSearch').off('input').on('input', fill);
            $('#pkNewBtn').off('click').on('click', function () { var n = $.trim($('#pkNewName').val()); if (!n) return; $p.hide(); done({ name: n }); });
            $('#pkNewName').off('keydown').on('keydown', function (e) { if (e.key === 'Enter') $('#pkNewBtn').click(); });
            $('.pkNew').toggle(!opts.noNew);
            fill(); $p.show(); $('#pkSearch').focus();
        }

        function peopleCall(data, ok) {
            $.ajax({ url: 'services/people.aspx', type: 'POST', data: data, dataType: 'json', success: function (r) { if (ok) ok(r); },
                error: function (x) { toastr.error((x.responseJSON && x.responseJSON.error) || x.statusText, 'ERROR', { timeOut: 5000 }); } });
        }

        // ---- faces on the big photo ----
        function layoutFaces() {
            var img = document.getElementById('pvImg'), box = $('#pvFaces').empty();
            if (!pvFacesOn || !img.naturalWidth || !curFaces.length) return;
            var cw = img.clientWidth, ch = img.clientHeight, sc = Math.min(cw / img.naturalWidth, ch / img.naturalHeight);
            var w = img.naturalWidth * sc, h = img.naturalHeight * sc, ox = (cw - w) / 2, oy = (ch - h) / 2;
            curFaces.forEach(function (f) {
                var $f = $('<div class="fbox">').toggleClass('known', !!f.person).toggleClass('blk', !!f.blocked).css({ left: ox + f.x * w, top: oy + f.y * h, width: f.w * w, height: f.h * h })
                    .attr('title', f.name || T('Unnamed', 'Unnamed'));
                $('<span>').text(f.name || '?').appendTo($f);
                $f.on('click', function (e) { e.stopPropagation(); faceMenu(f); }).appendTo(box);
            });
        }

        function loadFaces(p) {
            curFaces = []; $('#pvFaces').empty();
            $.getJSON('services/people.aspx?action=faces&file=' + encodeURIComponent(p.id), function (d) {
                if (current !== p) return;
                curFaces = d.faces || []; layoutFaces();
            });
        }

        function faceMenu(f) {
            var acts = [];
            if (f.person) acts.push({ html: '<i class="fa fa-user-times"></i> ' + esc(T('NotThisPerson', 'Not this person')), run: function () { peopleCall({ action: 'unmark', face: f.id }, afterFaceChange); } });
            acts.push({ html: '<i class="fa fa-ban"></i> ' + esc(T('NotAFace', 'Not a face')), danger: true, run: function () { peopleCall({ action: 'reject', face: f.id }, afterFaceChange); } });
            pickPerson(f.name ? f.name : T('WhoIsThis', 'Who is this?'), { actions: acts }, function (r) {
                peopleCall({ action: 'assign', face: f.id, person: r.person || '', name: r.name || '' }, afterFaceChange);
            });
        }

        function afterFaceChange() {
            loadPeople(function () { if (current) loadFaces(current); if (personFilter) refreshPersonFiles(); });
            fillPhotosKeep();
        }

        function refreshPersonFiles() {
            if (!personFilter) return;
            $.getJSON('services/people.aspx?action=photos&person=' + encodeURIComponent(personFilter.id), function (d) {
                personFiles = {}; (d.files || []).forEach(function (f) { personFiles[f] = 1; }); renderGrid(false);
            });
        }
        function fillPhotosKeep() { var id = current && current.id; fillPhotos(); $(document).one('ajaxStop', function () { var again = photos.filter(function (p) { return p.id === id; })[0]; if (again) current = again; }); }

        $(function () {
            $('#photoFilter').on('click', 'button', function () {
                filter = $(this).data('f');
                $('#photoFilter button').removeClass('on'); $(this).addClass('on');
                renderGrid(false);   // the map stays where it is
                saveState();
            });
            $('#photosGrid').on('scroll', function () { requestAnimationFrame(function () { paintGrid(false); }); });
            $(window).on('resize', function () { paintGrid(true); });
            $('#viewTabs').on('click', 'button', function () { setTab($(this).data('t')); });
            $('#peopleSearch').on('input', renderPeople);
            $('#personClose').click(closePersonFilter);
            $('#personRename').click(function () {
                var n = prompt(T('NameThisPerson', 'Name of this person:'), personFilter.name || '');
                if (n === null) return;
                peopleCall({ action: 'rename', person: personFilter.id, name: n }, function () { loadPeople(); });
            });
            $('#personBlock').click(function () {
                var making = !personFilter.blocked;
                if (making && !confirm(T('BlockConfirm', 'Block this person? All photos that show them will disappear from your lists and from the map.'))) return;
                peopleCall({ action: 'block', person: personFilter.id, v: making ? 1 : 0 }, function () { personFilter.blocked = making; loadPeople(function () { fillPhotosKeep(); renderGrid(false); }); });
            });
            $('#personMerge').click(function () {
                pickPerson(T('MergeInto', 'Merge into…'), { exclude: personFilter.id, noNew: true }, function (r) {
                    if (!confirm(T('MergeConfirm', 'Merge these two groups into one person?'))) return;
                    var target = people.filter(function (x) { return x.id === r.person; })[0];
                    peopleCall({ action: 'merge', from: personFilter.id, into: r.person }, function () { personFilter = target; loadPeople(function () { if (target) openPerson(target); }); });
                });
            });
            $('#pkClose').click(function () { $('#picker').hide(); });
            $('#pvFacesBtn').click(function () { pvFacesOn = !pvFacesOn; $(this).toggleClass('on', pvFacesOn); layoutFaces(); });
            $('#pvFacesBtn').addClass('on');
            $('#pvImg').on('load', layoutFaces); $(window).on('resize', layoutFaces);
            loadPeople();
            init(null);
            var st = urlState(), lat0 = parseFloat(st.lat), lng0 = parseFloat(st.lng), z0 = parseInt(st.z, 10);
            if (isFinite(lat0) && isFinite(lng0) && isFinite(z0)) { map.setView([lat0, lng0], z0); firstFit = false; }
            else map.setView([50.430981, 30.539267], 6);
            if (st.f === 'pub' || st.f === 'priv') { filter = st.f; $('#photoFilter button').removeClass('on').filter('[data-f=' + filter + ']').addClass('on'); }
            if (/^\d{4}$/.test(st.y || '')) { yearSel = st.y; if (/^\d{2}$/.test(st.m || '')) monthSel = st.m; }
            if (st.s === 'view') { scope = 'view'; $('#scopeFilter button').removeClass('on').filter('[data-s=view]').addClass('on'); }
            markers = L.featureGroup().addTo(map);

            // Movement log: records every map move that no mouse, touch, wheel or key press caused, with the code that made it,
            // and every page load / unload (a reload also puts the map back to its first position). Kept in localStorage 'sytMapLog'
            // (survives a reload), shown in the console as [map], read with  mapLog  and sent to the server (data/maplog.txt).
            var lastInput = 0, pending = [], sendTimer = null;
            function logMap(kind, extra) {
                var c = map.getCenter();
                var e = { t: new Date().toISOString().slice(11, 23), kind: kind, at: c.lat.toFixed(4) + ',' + c.lng.toFixed(4) + ' z' + map.getZoom(), url: location.search };
                for (var k in extra) e[k] = extra[k];
                mapLog.push(e); if (mapLog.length > 300) mapLog.shift();
                try { localStorage.setItem('sytMapLog', JSON.stringify(mapLog)); } catch (x) { }
                console.log('[map]', kind, e.at, extra && extra.by || '');
                pending.push(JSON.stringify(e));
                clearTimeout(sendTimer); sendTimer = setTimeout(flushLog, 1500);
            }
            function flushLog() {
                if (!pending.length) return;
                var body = pending.join('\n'); pending = [];
                try { if (!navigator.sendBeacon('services/client_log.aspx', body)) throw 0; } catch (x) { $.post('services/client_log.aspx', body); }
            }
            function callers() { return (new Error().stack || '').split('\n').slice(3, 7).map(function (l) { return l.trim().replace(/^at /, '').replace(/https?:\/\/[^/]+\//g, ''); }).join(' < '); }
            try { window.mapLog = JSON.parse(localStorage.getItem('sytMapLog') || '[]'); } catch (x) { window.mapLog = []; }
            var nav = (performance.getEntriesByType && performance.getEntriesByType('navigation')[0]) || {};
            logMap('PAGE LOAD', { nav: nav.type, ref: document.referrer.slice(0, 80) });
            window.addEventListener('pagehide', function () { logMap('PAGE UNLOAD', {}); flushLog(); });
            ['mousedown', 'touchstart', 'wheel', 'keydown', 'dblclick'].forEach(function (ev) { document.addEventListener(ev, function () { lastInput = Date.now(); }, true); });
            document.addEventListener('keydown', function (e) { if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') logMap('key ' + e.key, { target: e.target.tagName + (e.target.id ? '#' + e.target.id : ''), preview: inPreview }); }, true);
            // every move and every zoom goes through _move / _resetView inside Leaflet
            ['_move', '_resetView'].forEach(function (fn) {
                var orig = map[fn];
                map[fn] = function (center, zoom) {
                    if (Date.now() - lastInput > 600) {
                        var c = map.getCenter(), z = map.getZoom(), nc = center && (center.lat !== undefined ? center : null);
                        if (fn === '_resetView' || zoom !== z || (nc && (Math.abs(nc.lat - c.lat) > 1e-7 || Math.abs(nc.lng - c.lng) > 1e-7)))
                            logMap('MOVE ' + fn, { to: nc ? nc.lat.toFixed(4) + ',' + nc.lng.toFixed(4) + ' z' + zoom : 'z' + zoom, by: callers() });
                    }
                    return orig.apply(map, arguments);
                };
            });

            var viewTimer = null;
            map.on('moveend', function () {   // the map-view list follows the map
                saveState();
                if (scope !== 'view' || inPreview || !markersImages) return;
                clearTimeout(viewTimer); viewTimer = setTimeout(function () { renderGrid(false); }, 250);
            });
            // not a <form>: the page already sits inside the server form, and Enter must not post it
            $('#askText').on('keydown', function (e) { if (e.which === 13) { e.preventDefault(); runAsk($('#askText').val()); } });
            $('#askGo').on('click', function () { runAsk($('#askText').val()); });
            $('#askClear').on('click', function () { clearAsk(); });
            $('#timeFilter').on('click', 'button', function () {
                if ($(this).data('r')) { rangeFrom = rangeTo = null; renderGrid(false); saveState(); return; }
                rangeFrom = rangeTo = null; yearSel = String($(this).data('y') || '') || null; monthSel = null;
                renderGrid(false); saveState();
            });
            $('#monthFilter').on('click', 'button', function () {
                var m = String($(this).data('m')); monthSel = monthSel === m ? null : m;
                renderGrid(false); saveState();
            });
            $('#scopeFilter').on('click', 'button', function () {
                scope = $(this).data('s');
                $('#scopeFilter button').removeClass('on'); $(this).addClass('on');
                renderGrid(false);   // the map stays where it is
                saveState();
            });
            function bulk(action) {
                var list = shownPhotos().filter(function (p) { return !p.ext; }); if (!list.length) return;   // never other people's photos
                var msg = action === 'delete'
                    ? T('BulkDeleteConfirm', 'Delete these photos permanently? This cannot be undone.')
                    : T('BulkPrivateConfirm', 'Make these photos private? Only you will see them.');
                if (!confirm(list.length + ' - ' + msg)) return;
                $('#bulkPrivate, #bulkDelete').prop('disabled', true);
                $.ajax({
                    type: 'POST', url: 'services/bulk_photos.aspx', data: { action: action, ids: list.map(function (p) { return p.id; }).join('\n') },
                    success: function (n) {
                        var set = {}; list.forEach(function (p) { set[p.id] = 1; });
                        if (action === 'delete') {
                            photos = photos.filter(function (p) { return !set[p.id]; });
                            if (current && set[current.id]) { current = null; $('#photoInfo').hide(); if (markerPhoto) { markers.removeLayer(markerPhoto); markerPhoto = null; } }
                        } else photos.forEach(function (p) { if (set[p.id]) p.pub = '0'; });
                        toastr.info(parseInt(n, 10) + ' ' + (action === 'delete' ? T('PhotoDeleted', 'Photo is deleted') : T('PhotoUpdated', 'Photo is updated')), '', { timeOut: 4000 });
                        renderGrid(false);
                        $('#noPhotos').toggle(!photos.length);
                    },
                    error: function (x, s, e) { toastr.error((x.responseText && x.responseText.length < 200 ? x.responseText : s + ',' + e), 'ERROR', { timeOut: 8000 }); renderGrid(false); }
                });
            }
            $('#bulkPrivate').click(function () { bulk('private'); });
            $('#bulkDelete').click(function () { bulk('delete'); });

            function fillPhotosKeepSelection() {
                var id = current && current.id;
                fillPhotos();
                $(document).one('ajaxStop', function () {
                    var again = photos.filter(function (p) { return p.id === id; })[0];
                    if (again) { current = again; $('#photosGrid button').filter(function () { return $(this).data('id') === id; }).addClass('sel'); }
                });
            }

            fillPhotos();

            function togglePublic() {
                if (!current || current.ext) return;
                var making = current.pub != '1';
                if (making && !confirm(T('MakePublicConfirm', 'Make this photo public? Check that nobody is recognisable in it.'))) return;
                current.pub = making ? '1' : '0';
                updatePhotoData(current);
                select(current);
                renderGrid(false);
                if (inPreview) renderPreview();
            }

            function deleteCurrent() {
                if (!current || current.ext) return;
                if (!confirm(T('DeletePhotoConfirm', 'Delete this photo permanently? This cannot be undone.'))) return;
                var gone = current, list = shownPhotos(), i = list.indexOf(gone);
                $.ajax({
                    url: 'services/delete_photobyfilename.aspx?fileName=' + encodeURIComponent(gone.id),
                    success: function () {
                        toastr.info(T('PhotoDeleted', 'Photo is deleted'), '', { timeOut: 3000 });
                        photos = photos.filter(function (p) { return p !== gone; });
                        if (markerPhoto) { markers.removeLayer(markerPhoto); markerPhoto = null; }
                        var rest = shownPhotos(), next = rest[Math.min(i, rest.length - 1)];
                        current = null; $('#photoInfo').hide();
                        renderGrid(false);
                        $('#noPhotos').toggle(!photos.length);
                        if (inPreview) { if (next) openPreview(next); else closePreview(); }
                    },
                    error: function (x, s, e) { toastr.error(s + ',' + e, 'ERROR', { timeOut: 5000 }); }
                });
            }

            function rotateCurrent(dir) {
                if (!current || current.ext) return;
                var p = current;
                $('#buttonRotL, #buttonRotR, #pvRotL, #pvRotR').prop('disabled', true);
                $.ajax({
                    url: 'services/rotate_photo.aspx', type: 'POST', data: { fileName: p.id, dir: dir },
                    success: function () {
                        p.v = Date.now();                                     // new address: the browser must not show the old picture
                        renderGrid(false);
                        if (inPreview && current === p) renderPreview();
                        else if (current === p) showPhoto(p);
                    },
                    error: function (x) { toastr.error(x.responseText || x.statusText, 'ERROR', { timeOut: 5000 }); },
                    complete: function () { $('#buttonRotL, #buttonRotR, #pvRotL, #pvRotR').prop('disabled', false); }
                });
            }
            $('#buttonRotL, #pvRotL').click(function () { rotateCurrent('ccw'); });
            $('#buttonRotR, #pvRotR').click(function () { rotateCurrent('cw'); });

            $('#buttonTogglePub, #pvToggle').click(togglePublic);
            $('#buttonDelete, #pvDelete').click(deleteCurrent);
            $('#buttonPreview').click(function () { openPreview(current); });
            $('#pvBack').click(closePreview);
            $('#pvPrev').click(function () { stepPreview(-1); });
            $('#pvNext').click(function () { stepPreview(1); });
            $('#photosGrid').on('dblclick', 'button', function () { openPreview(photos.filter(function (p) { return p.id === $(this).data('id'); }.bind(this))[0]); });
            $('#pvImg').on('click', function () { window.open($('#pvOpen').attr('href'), '_blank'); });
            $(document).on('keydown', function (e) {
                if (e.key === 'Escape' && $('#picker').is(':visible')) { $('#picker').hide(); return; }
                if ($('#picker').is(':visible')) return;
                if ($(e.target).is('input, textarea, select') || e.ctrlKey || e.metaKey || e.altKey) return;
                if (e.key === 'Delete') { if (current) { e.preventDefault(); deleteCurrent(); } return; }
                if (e.key === 'r' || e.key === 'R') { if (current) { e.preventDefault(); rotateCurrent(e.shiftKey ? 'ccw' : 'cw'); } return; }
                if (!inPreview) return;
                if (e.key === 'Escape') closePreview();
                else if (e.key === 'ArrowLeft') stepPreview(-1);
                else if (e.key === 'ArrowRight') stepPreview(1);
            });
        });
    </script>
</asp:Content>
