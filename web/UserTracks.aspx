<%@ Page Title="See Your Travel Profile" Language="C#" MasterPageFile="MasterPage.master" CodeFile="UserTracks.aspx.cs" Inherits="UserTracks" %>

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

    <div id="textToReadArea0" class="profilePanel">
        <!-- #Include virtual="include/profileTabs.inc" -->
        <div class="pfBody">
            <div class="pfRow" style="margin-top: 0">
                <a class="pfBtn primary" id="buttonNew" href="editor.aspx"><i class="fa fa-plus"></i> <span class="i" data-i18n="New">New</span></a>
                <button type="button" class="pfBtn" id="buttonEdit" disabled="disabled"><i class="fa fa-pencil"></i> <span class="i" data-i18n="Edit">Edit</span></button>
                <button type="button" class="pfBtn" id="buttonOpen" disabled="disabled"><i class="fa fa-play"></i> <span class="i" data-i18n="Open">Open</span></button>
                <button type="button" class="pfBtn danger" id="buttonDelete" disabled="disabled"><i class="fa fa-trash-o"></i> <span class="i" data-i18n="Delete">Delete</span></button>
            </div>
            <!-- #Include virtual="include/pfSearch.inc" -->
            <ul class="pfList" id="tracksList"></ul>
            <div class="pfRow" style="justify-content: space-between; font-size: 12px; color: #7a8aa0; margin: 4px 0">
                <span id="trackCount"></span>
                <a href="#" id="selectAll" class="i" data-i18n="SelectAll">Select all</a>
            </div>

            <div id="embedBox" style="display: none">
                <h3 class="i" data-i18n="EmbedTitle">Embed on your site</h3>
                <input type="text" id="frameUrl" readonly="readonly" value="" />
                <div class="pfRow">
                    <button type="button" class="pfBtn" id="buttonCopy"><i class="fa fa-clipboard"></i> <span class="i" data-i18n="Copy">Copy</span></button>
                    <button type="button" class="pfBtn" id="buttonShow"><i class="fa fa-eye"></i> <span class="i" data-i18n="Preview">Preview</span></button>
                </div>
                <div id="divframe"></div>
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
        var markersTracks, line, rows = [], selected = [];
        var iconTrack = L.icon({ iconUrl: 'img/track.png', iconSize: [40, 40], iconAnchor: [20, 20] });

        function esc(t) { return $('<div>').text(t).html(); }

        function loadRows() {
            $.get('services/get_mytracks.aspx?' + Math.random(), function (data) {
                rows = [];
                $.each($.trim(data) ? data.split('\n') : [], function (_, r) {
                    var p = r.split(';');
                    var loc = null;
                    try {
                        var j = JSON.parse(p.slice(3).join(';'));
                        var la = parseFloat($.isArray(j) ? j[0] : j.lat), ln = parseFloat($.isArray(j) ? j[1] : j.lng);
                        if (isFinite(la) && isFinite(ln)) loc = { lat: la, lng: ln };
                    } catch (e) { }
                    if (!rows.some(function (x) { return x.id === p[0]; })) rows.push({ id: p[0], name: p[1], pub: p[2] == 1, loc: loc });
                });
                markersTracks.clearLayers();
                rows.forEach(function (t) {
                    if (!t.loc) return;
                    var a = document.createElement('a');
                    a.innerHTML = '<p>' + esc(t.name) + '</p>';
                    a.href = './index.aspx?trackname=' + encodeURIComponent(t.id);
                    a.target = '_blank';
                    L.marker([t.loc.lat, t.loc.lng], { icon: iconTrack }).bindPopup(a).addTo(markersTracks);
                });
                selected = [];
                render();
            }).fail(function (x, s, e) { toastr.error(s + "," + e, "ERROR", { timeOut: 5000 }); });
        }

        var aiRank = null;   // the assistant's answer {id: position}, or null while only the typed text filters
        function matches(t) {
            if (aiRank) return aiRank[t.id] !== undefined;
            var q = $.trim($('#askText').val()).toLowerCase();
            return !q || t.name.toLowerCase().indexOf(q) >= 0;
        }

        function render() {
            var ul = $('#tracksList').empty();
            var shown = rows.filter(matches);
            if (aiRank) shown.sort(function (a, b) { return aiRank[a.id] - aiRank[b.id]; });   // best match first
            shown.forEach(function (t) {
                var on = selected.indexOf(t.id) >= 0;
                var li = $('<li>').toggleClass('sel', on).data('id', t.id);
                $('<input type="checkbox">').prop('checked', on).appendTo(li);
                $('<span class="nm">').text(t.name).attr('title', t.name).appendTo(li);
                $('<span class="pfBadge">').addClass(t.pub ? 'pub' : 'priv').text(t.pub ? T('Public', 'Public') : T('Private', 'Private')).appendTo(li);
                ul.append(li);
            });
            if (!shown.length) ul.append($('<li class="pfEmpty" style="display:block;cursor:default">').text(rows.length ? T('NothingFound', 'Nothing found') : T('NoTracksYet', 'No tracks yet. Create your first one!')));
            $('#trackCount').text(shown.length + ' / ' + rows.length);
            var one = selected.length === 1;
            $('#buttonEdit,#buttonOpen').prop('disabled', !one);
            $('#buttonDelete').prop('disabled', !selected.length);
            $('#embedBox').toggle(one);
        }

        function showOnMap(id) {
            $('#frameUrl').val('<iframe style="width: 330px; height: 250px;" src="' + location.href.replace(/[?#].*$/, '').replace(/[^\/]*$/, '') + 'frame.aspx?trackname=' + encodeURIComponent(id) + '"></iframe>');   // the address the browser used (the server only sees the internal http://host:8080 behind the tunnel)
            $('#divframe').html('');
            loadTrack(translateTracksPath(id + '.js'), function (tr) {
                if (line) { map.removeLayer(line); line = null; }
                if (selected.length !== 1 || selected[0] !== id) return;
                line = L.polyline(tr.trackData, { color: '#e8452c', weight: 4 }).addTo(map);
                map.fitBounds(line.getBounds(), { paddingTopLeft: [60, 60], paddingBottomRight: [440, 60] });
            });
        }

        $(function () {
            init(null);
            map.setView([50.430981, 30.539267], 6);
            markersTracks = L.featureGroup().addTo(map);
            loadRows();

            $('#tracksList').on('click', 'li', function (e) {
                var id = $(this).data('id');
                if (!id) return;
                var i = selected.indexOf(id);
                var multi = e.ctrlKey || e.metaKey || e.shiftKey || $(e.target).is('input');
                if (multi) { if (i >= 0) selected.splice(i, 1); else selected.push(id); }
                else selected = (i >= 0 && selected.length === 1) ? [] : [id];
                render();
                if (selected.length === 1) showOnMap(selected[0]); else if (line) { map.removeLayer(line); line = null; }
            });
            sytPfSearch({ url: 'services/track_search.aspx', extra: { limit: 500 }, idsOf: function (d) { return (d.tracks || []).map(function (x) { return x.file; }); },
                          apply: function (rank) { aiRank = rank; selected = []; render(); } });
            $('#selectAll').click(function (e) {
                e.preventDefault();
                selected = rows.filter(matches).map(function (t) { return t.id; });
                render();
            });
            $('#buttonEdit').click(function () { window.location = 'editor.aspx?trackname=' + selected[0]; });
            $('#buttonOpen').click(function () { window.location = 'index.aspx?trackname=' + selected[0]; });
            $('#buttonShow').click(function () { $('#divframe').html($('#frameUrl').val()); });
            $('#buttonCopy').click(function () {
                var f = $('#frameUrl')[0]; f.select();
                try { document.execCommand('copy'); toastr.info(T('Copied', 'Copied'), '', { timeOut: 2000 }); } catch (e) { }
            });
            $('#buttonDelete').click(function () {
                var names = selected.slice();
                if (!names.length) return;
                var labels = rows.filter(function (t) { return names.indexOf(t.id) >= 0; }).map(function (t) { return t.name; });
                var what = names.length === 1 ? '"' + labels[0] + '"' : T("TracksCount", "{0} tracks").replace("{0}", names.length);
                if (!confirm(T("DeleteTracksConfirm", "Delete {0} permanently? This cannot be undone.").replace("{0}", what))) return;
                var done = 0, failed = [];
                (function next() {
                    if (!names.length) {
                        if (done) toastr.info(done === 1 ? T("TrackDeleted", "Track is deleted") : T("TracksDeleted", "{0} tracks are deleted").replace("{0}", done), "", { timeOut: 5000, extendedTimeOut: 10000 });
                        failed.forEach(function (f) { toastr.error(T("DeleteTrackFailedWhy", "Could not delete the track: {0}").replace("{0}", f), "", { timeOut: 8000 }); });
                        if (line) { map.removeLayer(line); line = null; }
                        loadRows();
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
