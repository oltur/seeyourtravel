<div style="position: absolute; left: 5px; top: 2px; z-index: 1001">
  <a id="alogo" href="javascript:clickMenu()" class="menu3lines">
    <i class="fa fa-bars" aria-hidden="true"></i>
  </a>
</div>
<div id="menuPanel" style="display: none; position: absolute; z-index: 1000; left: 0px; width: 265px; height: 570px; background: rgba(255,255,255,0); border: 0px solid #000;">
            <div style="position: absolute; left: -2px; top: 50px;">
                <button type="button" data-i18n="[title]Cancel;Cancel" id="cancelButton" title="Cancel changes" class="i headerButton" style="background-image: url(img/cancel.png );" onclick="clickCancel()">Cancel</button>
            </div>
            <div style="position: absolute; left: -2px; top: 100px;">
                <button type="button" data-i18n="[title]Settings;Settings" id="settingsCheckBox" title="Settings" class="i headerButton" style="background-image: url(img/settings1.png );" onclick="clickSettings()">Settings</button>
                <button type="button" data-i18n="[title]AboutSeeYourTravel;AboutSeeYourTravel" id="corporateSite" title="Corporate site" class="i headerButton" style="background-image: url(img/corporate.png );" onclick="window.open('./corporate','_blank')">About SeeYourTravel</button>
            </div>
            <div style="position: absolute; left: -2px; top: 195px;">
                <button type="button" <%--data-i18n="[title]Profile;Profile" --%>id="profile" title="Profile" class="headerButton" style="background-image: url(img/profile.png );" onclick="window.location = 'UserProfile.aspx'"></button>
                <button type="button" data-i18n="[title]Logout;Logout" id="logout" title="Logout" class="i headerButton" style="background-image: url(img/logoff.png );" onclick="window.location = 'Logout.aspx'">Logout</button>
                <!--<button type="button" data-i18n="[title]Help;Help" id="helpButton" style="background-image: url(img/help.png);" class="i headerButton" title="Need help?" onclick="clickHelp()">Help</button>-->
            </div>
        </div>
