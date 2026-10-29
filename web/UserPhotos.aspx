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

            <h3 class="i" data-i18n="MyPhotos">My photos</h3>
            <div class="pfChips" id="photoFilter">
                <button type="button" data-f="all" class="on"><span class="i" data-i18n="All">All</span> <em>0</em></button>
                <button type="button" data-f="pub"><i class="fa fa-globe"></i> <span class="i" data-i18n="Public">Public</span> <em>0</em></button>
                <button type="button" data-f="priv"><i class="fa fa-lock"></i> <span class="i" data-i18n="Private">Private</span> <em>0</em></button>
            </div>
            <div class="pfChips" id="scopeFilter">
                <button type="button" data-s="all" class="on"><i class="fa fa-th"></i> <span class="i" data-i18n="ScopeAll">Whole list</span></button>
                <button type="button" data-s="view"><i class="fa fa-crosshairs"></i> <span class="i" data-i18n="ScopeView">In map view</span> <em>0</em></button>
            </div>
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
                <div class="pfNote"><i class="fa fa-map-marker"></i> <span class="i" data-i18n="ClickMapToPlace">Click the map to set where this photo was taken.</span></div>
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
            </div>

            <div id="photoView" style="display: none">
                <div class="pfRow" style="margin-top: 0; align-items: center">
                    <button type="button" class="pfBtn" id="pvBack"><i class="fa fa-arrow-left"></i> <span class="i" data-i18n="BackToPhotos">Back to photos</span></button>
                    <span id="pvCount" style="margin-left: auto; font-size: 12px; color: #7a8aa0"></span>
                </div>
                <div class="pvStage">
                    <img id="pvImg" alt="" />
                    <button type="button" class="pvNav prev" id="pvPrev" title="Previous"><i class="fa fa-chevron-left"></i></button>
                    <button type="button" class="pvNav next" id="pvNext" title="Next"><i class="fa fa-chevron-right"></i></button>
                </div>
                <div class="pvCaption"><span id="pvTitle"></span> <span class="pfBadge" id="pvStatus"></span></div>
                <div class="pfRow" style="margin-bottom: 0">
                    <button type="button" class="pfBtn" id="pvToggle"></button>
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
            showPhoto(p);
        }

        // thousands of photos: only the thumbnails that are (nearly) visible are requested
        function lazyThumbs(grid) {
            var set = function (el) { el.style.backgroundImage = 'url(' + el.getAttribute('data-bg') + ')'; };
            var btns = grid.querySelectorAll('button[data-bg]');
            if (!('IntersectionObserver' in window)) { btns.forEach(set); return; }
            var io = new IntersectionObserver(function (entries) {
                entries.forEach(function (e) { if (e.isIntersecting) { set(e.target); io.unobserve(e.target); } });
            }, { root: grid, rootMargin: '300px' });
            btns.forEach(function (b) { io.observe(b); });
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
                history.replaceState(null, '', location.pathname + '?' + q.toString() + location.hash);
            } catch (e) { }
        }
        var isPub = function (p) { return p.pub == '1'; };
        var inPreview = false, listScroll = 0;

        var scope = 'all';   // 'view' = only the photos inside the current map view
        function inView(p) { return hasLoc(p) && map.getBounds().contains([parseFloat(p.lat), parseFloat(p.lng)]); }
        function isShown(p) { return (filter === 'all' || (filter === 'pub') === isPub(p)) && (scope !== 'view' || inView(p)); }
        function shownPhotos() { return photos.filter(isShown); }

        // ---- one photo, big ----
        function renderPreview() {
            var p = current; if (!p) return;
            var list = shownPhotos(), i = list.indexOf(p);
            var base = encodeURIComponent(p.id.replace(/\.[^.]*$/, ''));
            var img = document.getElementById('pvImg'), big = 'data/thumbs/1600/' + base + '.jpg' + (p.v ? '?v=' + p.v : '');
            var vq = p.v ? '?v=' + p.v : '';
            img.src = 'data/thumbs/480/' + base + '.jpg' + vq;                 // the small copy shows at once ...
            var loader = new Image();
            loader.onload = function () { if (current === p && inPreview) img.src = big; };   // ... then the large one
            loader.onerror = function () { if (current === p && inPreview) img.src = 'data/images/' + encodeURIComponent(p.id); };
            loader.src = big;
            $('#pvTitle').text(p.desc);
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
            g.scrollTop = listScroll;                                     // back to where the list was
            var sel = $('#photosGrid button.sel')[0];
            if (sel && (sel.offsetTop < g.scrollTop || sel.offsetTop + sel.offsetHeight > g.scrollTop + g.clientHeight)) sel.scrollIntoView({ block: 'nearest' });
        }

        function stepPreview(d) {
            var list = shownPhotos(), i = list.indexOf(current) + d;
            if (i >= 0 && i < list.length) { select(list[i]); renderPreview(); }
        }

        // the grid and the map pins show the current filter; every photo carries a public (globe) or private (lock) flag
        function renderGrid(fit) {
            var nPub = photos.filter(isPub).length;
            $('#photoFilter [data-f=all] em').text(photos.length);
            $('#photoFilter [data-f=pub] em').text(nPub);
            $('#photoFilter [data-f=priv] em').text(photos.length - nPub);
            var shown = shownPhotos();
            $('#scopeFilter [data-s=view] em').text(photos.filter(inView).length);
            $('#bulkBar').css('display', scope === 'view' ? 'flex' : 'none');
            $('#bulkCount').text(shown.length + ' ' + T('PhotosInView', 'photos in the map view'));
            $('#bulkPrivate, #bulkDelete').prop('disabled', !shown.length);
            var grid = $('#photosGrid').empty();
            markersImages.clearLayers();
            shown.forEach(function (p) {
                var pub = isPub(p);
                $('<button type="button">').data('id', p.id).attr('title', p.desc + ' (' + (pub ? T('Public', 'Public') : T('Private', 'Private')) + ')')
                    .toggleClass('noloc', !hasLoc(p)).toggleClass('sel', !!current && current.id === p.id)
                    .attr('data-bg', 'data/thumbs/480/' + encodeURIComponent(p.id.replace(/\.[^.]*$/, '')) + '.jpg' + (p.v ? '?v=' + p.v : ''))   // ready-made copy, loaded when scrolled into view
                    .append('<span class="pfFlag ' + (pub ? 'pub' : 'priv') + '"><i class="fa fa-' + (pub ? 'globe' : 'lock') + '"></i></span>')
                    .click(function () { select(p); }).appendTo(grid);
                if (hasLoc(p)) L.marker([parseFloat(p.lat), parseFloat(p.lng)], { icon: L.divIcon({ className: 'pfDot ' + (pub ? 'pub' : 'priv'), iconSize: [14, 14] }) })
                    .on('click', function () { select(p); }).addTo(markersImages);
            });
            lazyThumbs(grid[0]);
            if (fit && scope !== 'view' && markersImages.getLayers().length) map.fitBounds(markersImages.getBounds(), { paddingTopLeft: [40, 40], paddingBottomRight: [440, 40], maxZoom: 12 });
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
                    if (q.length < 5 || seen[q[0]]) return;   // a description with a line break leaves a broken fragment
                    seen[q[0]] = 1;
                    photos.push({ id: q[0], desc: q[1], pub: q[2], lat: q[3], lng: q[4] });
                });
                var fit = firstFit; firstFit = false;   // fit the map to the photos only when the address did not say where to look
                renderGrid(fit);
                $('#noPhotos').toggle(!photos.length);
            });
        }

        $(function () {
            $('#photoFilter').on('click', 'button', function () {
                filter = $(this).data('f');
                $('#photoFilter button').removeClass('on'); $(this).addClass('on');
                renderGrid(false);   // the map stays where it is
                saveState();
            });
            init(null);
            var st = urlState(), lat0 = parseFloat(st.lat), lng0 = parseFloat(st.lng), z0 = parseInt(st.z, 10);
            if (isFinite(lat0) && isFinite(lng0) && isFinite(z0)) { map.setView([lat0, lng0], z0); firstFit = false; }
            else map.setView([50.430981, 30.539267], 6);
            if (st.f === 'pub' || st.f === 'priv') { filter = st.f; $('#photoFilter button').removeClass('on').filter('[data-f=' + filter + ']').addClass('on'); }
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
            $('#scopeFilter').on('click', 'button', function () {
                scope = $(this).data('s');
                $('#scopeFilter button').removeClass('on'); $(this).addClass('on');
                renderGrid(false);   // the map stays where it is
                saveState();
            });
            function bulk(action) {
                var list = shownPhotos(); if (!list.length) return;
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

            map.on('click', function (e) {
                if (!current || inPreview) return;
                if (!confirm(current.desc + '\n' + T('MovePhotoConfirm', 'Move this photo to the clicked place on the map?'))) return;
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

            function togglePublic() {
                if (!current) return;
                var making = current.pub != '1';
                if (making && !confirm(T('MakePublicConfirm', 'Make this photo public? Check that nobody is recognisable in it.'))) return;
                current.pub = making ? '1' : '0';
                updatePhotoData(current);
                select(current);
                renderGrid(false);
                if (inPreview) renderPreview();
            }

            function deleteCurrent() {
                if (!current) return;
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
                if (!current) return;
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
