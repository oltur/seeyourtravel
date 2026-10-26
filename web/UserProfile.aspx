<%@ Page Title="See Your Travel: User Profile" Language="C#" MasterPageFile="MasterPage.master" CodeFile="UserProfile.aspx.cs" Inherits="UserProfile" %>

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
    <%
        var pfSignIn = Tools.GetUserSignIn(this);
        var pfRole = Tools.GetUserRole(this);
    %>
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
            <div class="pfStats">
                <a class="pfStat" href="UserTracks.aspx"><b><%= pfCounts[0] %></b><span class="i" data-i18n="MyTracks">My Tracks</span></a>
                <a class="pfStat" href="UserPhotos.aspx"><b><%= pfCounts[1] %></b><span class="i" data-i18n="MyPhotos">My photos</span></a>
                <a class="pfStat" href="UserPlaces.aspx"><b><%= pfCounts[2] %></b><span class="i" data-i18n="MyPlaces">My Places</span></a>
            </div>

            <h3 class="i" data-i18n="Account">Account</h3>
            <dl class="pfKV">
                <dt class="i" data-i18n="Name">Name</dt>
                <dd><%= HttpUtility.HtmlEncode(Tools.GetUserName(this)) %></dd>
                <dt class="i" data-i18n="SignedInWith">Signed in with</dt>
                <dd><%= HttpUtility.HtmlEncode(pfSignIn.Replace("|", " · ")) %></dd>
                <dt class="i" data-i18n="Role">Role</dt>
                <dd><span class="pfBadge"><%= pfRole %></span></dd>
            </dl>

            <h3 class="i" data-i18n="RecentTracks">Your tracks</h3>
            <ul class="pfRecent" id="recentTracks"><li class="pfEmpty">…</li></ul>
            <div class="pfRow">
                <a class="pfBtn primary" href="editor.aspx"><i class="fa fa-plus"></i> <span class="i" data-i18n="New">New</span></a>
                <a class="pfBtn" href="UserTracks.aspx"><span class="i" data-i18n="AllTracks">All tracks</span></a>
            </div>

            <div class="pfNote"><i class="fa fa-lock"></i> <span class="i" data-i18n="PhotosPrivate">Your own photos are private: they are never shown to other visitors or on the map.</span></div>

            <h3 class="i" data-i18n="YourData">Your data</h3>
            <div class="pfNote" style="margin-top: 0"><span class="i" data-i18n="DownloadHint">Download a ZIP with your tracks, places and original photos.</span></div>
            <div class="pfRow">
                <a class="pfBtn" id="buttonDownload" href="services/export_mydata.aspx"><i class="fa fa-download"></i> <span class="i" data-i18n="DownloadMyData">Download my data</span></a>
            </div>

            <% if (pfRole != "Administrator" && pfRole != "Guest") { %>
            <h3 class="i" data-i18n="DangerZone">Delete account</h3>
            <div class="pfNote" style="margin-top: 0; background: #fdf1f0">
                <i class="fa fa-exclamation-triangle" style="color: #b3261e"></i>
                <span class="i" data-i18n="DeleteAccountHint">This permanently deletes your account, tracks, places and photos. Download your data first. It cannot be undone.</span>
            </div>
            <div id="deleteBox" style="display: none">
                <label for="deleteConfirm"><span class="i" data-i18n="TypeYourName">Type your name to confirm:</span> <b><%= HttpUtility.HtmlEncode(Tools.GetUserName(this)) %></b></label>
                <input type="text" id="deleteConfirm" autocomplete="off" />
                <div class="pfRow">
                    <button type="button" class="pfBtn danger" id="buttonDeleteAccount" disabled="disabled"><i class="fa fa-trash-o"></i> <span class="i" data-i18n="DeleteMyAccount">Delete my account</span></button>
                    <button type="button" class="pfBtn" id="buttonDeleteCancel"><span class="i" data-i18n="Cancel">Cancel</span></button>
                </div>
            </div>
            <div class="pfRow" id="deleteStart">
                <button type="button" class="pfBtn danger" id="buttonDeleteStart"><i class="fa fa-trash-o"></i> <span class="i" data-i18n="DeleteMyAccount">Delete my account</span></button>
            </div>
            <% } %>

            <div class="pfRow">
                <a class="pfBtn" href="index.aspx"><i class="fa fa-arrow-left"></i> <span class="i" data-i18n="BackToMap">Back to the map</span></a>
                <a class="pfBtn danger" href="Logout.aspx"><i class="fa fa-sign-out"></i> <span class="i" data-i18n="Logout">Logout</span></a>
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
        $(function () {
            init(null);
            map.setView([50.430981, 30.539267], 6);

            var myName = <%= Newtonsoft.Json.JsonConvert.SerializeObject(Tools.GetUserName(this)) %>;
            $('#buttonDeleteStart').click(function () { $('#deleteStart').hide(); $('#deleteBox').show(); $('#deleteConfirm').focus(); });
            $('#buttonDeleteCancel').click(function () { $('#deleteBox').hide(); $('#deleteStart').show(); $('#deleteConfirm').val(''); });
            $('#deleteConfirm').on('input', function () { $('#buttonDeleteAccount').prop('disabled', $.trim($(this).val()) !== $.trim(myName)); });
            $('#buttonDeleteAccount').click(function () {
                if (!confirm(T('DeleteAccountConfirm', 'Really delete your account and everything in it? This cannot be undone.'))) return;
                $.ajax({ url: 'services/delete_account.aspx', type: 'POST', data: { confirm: $('#deleteConfirm').val() }, headers: { 'X-Requested-With': 'XMLHttpRequest' } })
                    .done(function (r) { toastr.info(T('AccountDeleted', 'Your account is deleted'), '', { timeOut: 4000 }); setTimeout(function () { window.location = 'index.aspx'; }, 1500); })
                    .fail(function (x) { toastr.error((x.responseText || x.statusText || '').toString().slice(0, 120), 'ERROR', { timeOut: 8000 }); });
            });

            $.get('services/get_mytracks.aspx?' + Math.random(), function (data) {
                var ul = $('#recentTracks').empty();
                var seen = {}, rows = ($.trim(data) ? data.split('\n') : []).filter(function (r) { var k = r.split(';')[0]; return seen[k] ? false : (seen[k] = true); });
                if (!rows.length) { ul.append('<li class="pfEmpty">' + T('NoTracksYet', 'No tracks yet. Create your first one!') + '</li>'); return; }
                rows.slice(0, 6).forEach(function (r) {
                    var p = r.split(';');
                    var li = $('<li>');
                    $('<a class="nm">').attr('href', 'index.aspx?trackname=' + encodeURIComponent(p[0])).text(p[1]).appendTo(li);
                    $('<span class="pfBadge">').addClass(p[2] == 1 ? 'pub' : 'priv').text(p[2] == 1 ? T('Public', 'Public') : T('Private', 'Private')).appendTo(li);
                    $('<a class="ed" title="Edit"><i class="fa fa-pencil"></i></a>').attr('href', 'editor.aspx?trackname=' + encodeURIComponent(p[0])).appendTo(li);
                    ul.append(li);
                });
                if (rows.length > 6) ul.append('<li class="pfEmpty"><a href="UserTracks.aspx">+ ' + (rows.length - 6) + '</a></li>');
            });
        });
    </script>
</asp:Content>
