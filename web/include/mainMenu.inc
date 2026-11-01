<%
    // The one main menu, shared by the map page and the account pages (UserProfile/Tracks/Photos/Places, editor). Sections, in the usual order of an app menu:
    //   (back to the map, on the other pages) / search + Create (map page) / My library / Settings / Account / About.
    // The ids of the buttons and their handlers are the old ones: other scripts switch them on and off (guests, no track chosen, recording).
    string mmPage = System.IO.Path.GetFileNameWithoutExtension(Request.Path).ToLowerInvariant();
    bool mmMap = mmPage == "index" || mmPage == "default";
    bool mmGuest = Tools.IsGuest(this);
    Func<string, string> mmCur = p => mmPage == p ? " aria-current=\"page\" class=\"mm-row on\"" : " class=\"mm-row\"";
%>
<nav id="menuPanel" class="menuPanel mmPanel" aria-label="Main menu" style="display: none">
    <button type="button" class="mm-x i" data-i18n="[title]Close;[aria-label]Close" title="Close" aria-label="Close" onclick="clickMenu()">&times;</button>
<% if (mmMap) { %>
    <div class="searchBox"><input type="text" id="searchForPlace" data-i18n="[placeholder]Search for places;[aria-label]Search for places" class="i" autocomplete="off" aria-label="Search for place" placeholder="Search for place" onkeydown="if(event.keyCode == 13) {search($(this)); return false;} return true;" /></div>
    <div id="searchAiHint" class="mm-hint" style="display: none"><i class="fa fa-magic"></i> <span class="i" data-i18n="SearchAiHint">or describe it, e.g. “castles in Scotland” (AI)</span></div>
    <div class="mm-h i" data-i18n="MenuCreate">Create</div>
    <button type="button" id="newTrackButton" class="mm-row i" data-i18n="[title]New;New" title="New" onclick="clickNew()">New</button>
    <button type="button" id="recordButton" class="mm-row i" data-i18n="[title]RecordRoute;RecordRoute" title="Record route" onclick="sytRecorder.toggle()">Record route</button>
    <button type="button" id="editTrackButton" class="mm-row i" data-i18n="[title]Edit;Edit" title="Edit" onclick="clickEdit()">Edit</button>
<% } else { %>
    <button type="button" id="cancelButton" class="mm-row mm-back i" data-i18n="[title]BackToMap;BackToMap" title="Back to the map" onclick="clickCancel()">Back to the map</button>
<% } %>
<% if (!mmGuest) { %>
    <div class="mm-h i" data-i18n="MenuLibrary">My library</div>
    <a id="menuTracks" href="UserTracks.aspx" <%= mmCur("usertracks") %> data-i18n="MyTracks">My tracks</a>
    <a id="menuPhotos" href="UserPhotos.aspx" <%= mmCur("userphotos") %> data-i18n="MyPhotos">My photos</a>
    <a id="menuPlaces" href="UserPlaces.aspx" <%= mmCur("userplaces") %> data-i18n="MyPlaces">My places</a>
<% } %>
    <div class="mm-h i" data-i18n="Settings">Settings</div>
    <button type="button" id="settingsCheckBox" class="mm-row i" data-i18n="[title]Settings;Settings" title="Settings" onclick="clickSettings()" aria-haspopup="true">Settings</button>
    <div class="mm-h i" data-i18n="MenuAccount">Account</div>
    <button type="button" id="profile" class="mm-row" title="Profile" onclick="window.location = 'UserProfile.aspx'"></button>
    <button type="button" id="logout" class="mm-row i<%= mmGuest ? " mm-in" : "" %>" data-i18n="[title]Logout;Logout" title="Logout" onclick="window.location = 'Logout.aspx?ReturnURL='+window.location.href">Logout</button>
    <div class="mm-sep"></div>
    <button type="button" id="corporateSite" class="mm-row i" data-i18n="[title]AboutSeeYourTravel;AboutSeeYourTravel" title="About SeeYourTravel" onclick="window.open('./corporate','_blank')">About SeeYourTravel</button>
</nav>
