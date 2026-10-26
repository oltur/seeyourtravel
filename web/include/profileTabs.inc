<%
    var pfCounts = Tools.GetUserCounts(this);
    var pfName = Tools.GetUserName(this);
%>
<div class="pfHead">
    <div class="pfAvatar"><%= HttpUtility.HtmlEncode(string.IsNullOrEmpty(pfName) ? "?" : pfName.Substring(0, 1).ToUpper()) %></div>
    <div class="pfWho">
        <div class="pfName"><%= HttpUtility.HtmlEncode(pfName) %></div>
        <a class="pfBack" href="index.aspx"><i class="fa fa-arrow-left"></i> <span class="i" data-i18n="BackToMap">Back to the map</span></a>
    </div>
</div>
<nav class="pfTabs">
    <a href="UserProfile.aspx" data-tab="UserProfile"><i class="fa fa-user"></i> <span class="i" data-i18n="MyProfile">My Profile</span></a>
    <a href="UserTracks.aspx" data-tab="UserTracks"><i class="fa fa-road"></i> <span class="i" data-i18n="MyTracks">My Tracks</span> <em><%= pfCounts[0] %></em></a>
    <a href="UserPhotos.aspx" data-tab="UserPhotos"><i class="fa fa-picture-o"></i> <span class="i" data-i18n="MyPhotos">My photos</span> <em><%= pfCounts[1] %></em></a>
    <a href="UserPlaces.aspx" data-tab="UserPlaces"><i class="fa fa-map-marker"></i> <span class="i" data-i18n="MyPlaces">My Places</span> <em><%= pfCounts[2] %></em></a>
</nav>
<script>
    (function () {
        var cur = location.pathname.split('/').pop().replace(/\.aspx$/i, '').toLowerCase();
        $('.pfTabs a').each(function () { if ($(this).data('tab').toLowerCase() === cur) $(this).addClass('active'); });
    })();
</script>
<script>
    // the panel can be dragged by its header and resized from any edge; position and size are remembered for all four pages
    $(function () {
        var $p = $('.profilePanel'), key = 'syt_profilePanel';
        if (!$p.length || !$.fn.resizable || window.innerWidth < 700) return;
        var detached = false;
        var detach = function () {   // from "right: 16px" to explicit left/top so jQuery UI can move and size it
            if (detached) return;
            detached = true;
            var o = $p.position();
            var w = $p.outerWidth(), h = $p.outerHeight();
            $p.css({ left: o.left, top: o.top, right: 'auto', maxHeight: 'none' }).outerWidth(w).outerHeight(h);
        };
        var save = function () {
            try { localStorage.setItem(key, JSON.stringify({ l: $p.position().left, t: $p.position().top, w: $p.outerWidth(), h: $p.outerHeight() })); } catch (e) { }
        };
        var saved = null;
        try { saved = JSON.parse(localStorage.getItem(key) || 'null'); } catch (e) { }
        if (saved && saved.w) {
            var w = Math.min(window.innerWidth - 16, Math.max(320, saved.w));
            var h = Math.min(window.innerHeight - 16, Math.max(260, saved.h));
            $p.css({ left: Math.min(Math.max(0, saved.l), window.innerWidth - 80), top: Math.min(Math.max(0, saved.t), window.innerHeight - 60), right: 'auto', maxHeight: 'none' }).outerWidth(w).outerHeight(h);
            detached = true;
        }
        $p.draggable({ handle: '.pfHead', containment: 'window', start: detach, stop: save });
        $p.resizable({ handles: 'n, e, s, w, ne, nw, se, sw', minWidth: 320, minHeight: 260, start: detach, stop: save });
        $(window).on('resize', function () {
            if (!detached) return;
            if ($p.outerHeight() > window.innerHeight - 8) $p.css('height', window.innerHeight - 16);
            if ($p.outerWidth() > window.innerWidth - 8) $p.css('width', window.innerWidth - 16);
        });
    });
</script>
