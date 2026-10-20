<%@ Page Title="See Your Travel" Language="C#" MasterPageFile="MasterPage.master" CodeFile="Index.aspx.cs" Inherits="Index" %>

<%@ Import Namespace="System.IO" %>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadPlaceholder" runat="Server">
    <script>
        var sideMenuNo = 0;
        var errorMessage = '<%=Request["errorMessage"]%>';
        var trackParam = '<%=this.TrackFileName%>';
        var showSidePanel = "no";//'<%=Request["showSidePanel"]%>';

        var audio;
        var imageDiv;
        var tracksList;
        var textToReadArea;
        var counter = 0;
        var markerSize = 30;
        var track;
        var map = undefined;
        var map2;
        var animatedMarker;
        var tileLayer;
        var markers;
        var markersFriends;
        var markersTracks;
        var line;
        var markerStart;
        var markerFinish;

        function translateAll(err, t) {
            $(".i").i18n();
            $("option.i").i18n();
            $("#profile").text($.t("Profile").replace("{0}", globalUserName));

            if ("True" == "<%=Tools.IsGuest(this)%>") {
                $("#logout").text($.t("Login"));
            }
            else {
                $("#logout").text($.t("Logout"));
            }

            $("#helpContext").html($.t("help_content"));

        }

        function clickStart() {
            if (tracksList[0].selectedIndex > 0) {
                window.location = 'index.aspx?trackname=' + tracksList.val();
            }
            else {
                window.location = 'index.aspx';
            }
        }
        function clickEdit() {
            if (tracksList[0].selectedIndex > 0) {
                window.location = 'editor.aspx?trackname=' + tracksList.val();
            }
        }
        function clickNew() {
            window.location = 'editor.aspx';
        }

        $(document).click(function (e) {
            if ((e.target.id != 'alogo' && !$('#alogo').find(e.target).length)
                && (e.target.id != 'menuPanel' && !$('#menuPanel').find(e.target).length)) {
                $("#menuPanel").hide('slide', 500);

                if (e.target.id != 'helpPanel' && !$('#helpPanel').find(e.target).length &&
                    e.target.id != 'imgComments' && !$('#imgComments').find(e.target).length
                ) {
                    showHelpPanel(false);
                }

                if (e.target.id != 'settingsPanel' && !$('#settingsPanel').find(e.target).length) {
                    $("#settingsPanel").hide('slide', { direction: "up" }, 500);
                }
            }
        });

        function switchSidePanel() {
            switchSidePanel(null);
        }

        function switchSidePanel(on) {
            if (on == null) {
                on = $("#sidePanel").css("display") == "none";
            }

            if (on) {
                $("#sidePanel").css("display", "inline");
                $("#sidePanel").css("width", "".concat(sidePanelWidth, "px"));
                $("#pageContent").css("margin-left", "".concat(sidePanelWidth, "px"));
            }
            else {
                $("#sidePanel").css("display", "none");
                $("#sidePanel").css("width", "0%");
                $("#pageContent").css("margin-left", "0px");
            }
        }

        var slider1;
        $(function () {
            map2 = document.getElementById("map2");
            audio = document.getElementById("audio");
            imageDiv = $("#imageDiv");
            tracksList = $("#tracksList");
            textToReadArea = document.getElementById("textToReadArea");

            if (errorMessage != "") {
                toastr.error(errorMessage, "ERROR", { timeOut: 5000, extendedTimeOut: 10000 });
            }

            $('#slider1').tinycarousel({
                axis: 'y'
                //,interval: true
                , infinite: false
            });
            slider1 = $("#slider1").data("plugin_tinycarousel");
            slider1.start();
        });

        function makeSideMenuItem(html, href, image) {
            var dynamicCSSId = "dynamicCSS" + (sideMenuNo).toString();
            var sideMenuId = "sideMenuId" + (sideMenuNo).toString();

            r = '<li style="width:' + (sidePanelWidth - 30) + 'px; height:' + (sidePanelWidth - 30) / 4 * 3 + 'px;">';
            if (href != null && href != '')
                r = r + '<a style="text-decoration: none; background: inherit;" href="' + href + '">';
            r = r + '<div id="' + sideMenuId + '" class="sideMenuItem'
            if (href != null && href != '') {
                r = r + ' withA';
            }
            else {
                r = r + ' withoutA';
            }
            if (image != null && image != '') {
                $("<style type='text/css' id='" + dynamicCSSId + "' />").appendTo("head");
                $("#" + dynamicCSSId).text("#" + sideMenuId + ":after {background-size: cover;  background-repeat:no-repeat; background: url('../tracks/content/" + image + "');}");
            }
            else {
                var t = 0;
            }
            r = r + '"><br/>' + html + '</div>';
            if (href != null && href != '')
                r = r + '</a>';
            r = r + '</li>';

            sideMenuNo++;

            return r;
        }


        function prependToSidePanel(html, href, image) {
            $('.overview').prepend(makeSideMenuItem(html, href, image));
            slider1.update();
        }

        function appendToSidePanel(html, href, image) {
            $('.overview').append(makeSideMenuItem(html, href, image));
            slider1.update();
        }

        function clearSidePanel() {
            $('.overview').empty();
            slider1.update();
        }
    </script>

</asp:Content>

<asp:Content ID="bodyContent" ContentPlaceHolderID="BodyPlaceholder" runat="Server">
    <!--Content-->
    <div class="langButton">
        <select style="" id="langList" class="graySelect" onchange="selectLang()"></select>
    </div>
    <input id="showGoesOn" type="hidden" value="0" />
    <div id="splitterContainer">
        <div id='sidePanel' style='display: none; height: 100%; width: 0; float: left;'>
            <div id="slider1">
                <%--                <span data-i18n="Chooseatrack">Choose a track:</span>--%>
                <br />
                <a class="prev" href="#">
                    <img class="prevImage" alt="Up" src="img/up.png" /></a>
                <div class="viewport">
                    <ul class="overview">
                    </ul>
                </div>
                <a class="next" href="#">
                    <img class="nextImage" alt="Down" src="img/down.png" /></a>
                <br />
                <%--    <button type="button" data-i18n="[title]Clear;Clear" id="clearSidePanelButton" title="Clear" class="i headerButton" style="width:100px; background-image: url(img/clear.png );" onclick="clearSidePanel()">Clear</button>--%>
            </div>
        </div>
        <div id='pageContent' style='height: 100%; position: relative; margin-left: 0;'>
            <div style="position: absolute; left: 5px; top: 2px; z-index: 1001">
                <a id="alogo" href="javascript:clickMenu()" class="menu3lines"><i class="fa fa-bars" aria-hidden="true"></i></a>
            </div>
            <div style="position: absolute; left: 42px; top: -2px; z-index: 1001">
                <select style="vertical-align: central; width: 200px; height: 35px" id="tracksList" class="i graySelect" onchange="clickStart()"></select>
            </div>
            <div style="position: absolute; left: 240px; top: 15px; z-index: 1001">
                <div id="wrapper">
                    <span id="lblCoord" style="vertical-align: super; text-shadow: 1px 1px #ffffff;"></span>
                </div>
            </div>
            <div style="position: absolute; right: 5px; bottom: 15px; z-index: 1001">
                <div class="fb-like" data-width="50" data-layout="button" data-action="like" data-show-faces="false" data-share="false" style="top: 4px;"></div>
                <%--<div class="fb-save" data-uri="<%=Request.Url.ToString()%>" data-size="small"></div>--%>
                <a href="https://twitter.com/share" class="twitter-share-button" data-via="turevskiy" data-lang="en">Tweet</a>
                <script>$(".twitter-share-button").attr("data-lang", getTwitterLanguage());</script>
	                <script>!function (d, s, id) { var js, fjs = d.getElementsByTagName(s)[0], p = /^http:/.test(d.location) ? 'http' : 'https'; if (!d.getElementById(id)) { js = d.createElement(s); js.id = id; js.src = p + '://platform.twitter.com/widgets.js'; fjs.parentNode.insertBefore(js, fjs); } }(document, 'script', 'twitter-wjs');</script>
            </div>

            <div id="menuPanel" class="menuPanel">
                <div>
                    <div class="searchBox"><input type="text" id="searchForPlace" data-i18n="[placeholder]Search for places" class="i" autocomplete="off" aria-label="Search for place"  placeholder="Search for place" onkeydown="if(event.keyCode == 13) {search($(this)); return false;} return true;" /><button type="button" onclick="search($('#searchForPlace'));return false;" data-i18n="Go" id="searchButton" title="Search" class="i" >Go</button></div>
                    <button type="button" data-i18n="[title]New;New" id="newTrackButton" title="New" class="i headerButton" style="background-image: url(img/new.png );" onclick="clickNew()">New</button>
                    <button type="button" data-i18n="[title]Edit;Edit" id="editTrackButton" title="Edit" class="i headerButton" style="background-image: url(img/edit.png );" onclick="clickEdit()">Edit</button>
                    <button type="button" data-i18n="[title]Settings;Settings" id="settingsCheckBox" title="Settings" class="i headerButton" style="background-image: url(img/settings1.png );" onclick="clickSettings()">Settings</button>
                    <button type="button" data-i18n="[title]AboutSeeYourTravel;AboutSeeYourTravel" id="corporateSite" title="Corporate site" class="i headerButton" style="background-image: url(img/corporate.png );" onclick="window.open('./corporate','_blank')">About SeeYourTravel</button>
                    <button type="button" <%--data-i18n="[title]Profile;Profile" --%>id="profile" title="Profile" class="headerButton" style="background-image: url(img/profile.png );" onclick="window.location = 'UserProfile.aspx'"></button>
                    <button type="button" data-i18n="[title]Logout;Logout" id="logout" title="Logout" class="i headerButton" style="background-image: url(img/logoff.png );" onclick="window.location = 'Logout.aspx?ReturnURL='+window.location.href">Logout</button>
                    <%--                    <button type="button" data-i18n="[title]Help;Help" id="helpButton" style="background-image: url(img/help.png);" class="i headerButton" title="Need help?" onclick="clickHelp()">Help</button>--%>
                </div>
            </div>
            <!-- #Include virtual="include/profileHelpPanel.inc" -->
            <!-- #Include virtual="include/settingsPanel.inc" -->

            <div style="position: absolute; right: 0px; top: 75px; z-index: 1001">
                <img id="imgComments" src="img/comments.png" onclick="clickHelp()" title="Comments" />
            </div>

            <div style="position: absolute; right: 0px; top: 120px; z-index: 1001">
                <button type="button" id="mute" style="padding-left: 0; background-image: url(img/unmute.png );" class="sideButton" onclick="clickMute();SaveSettings();"></button>
                <br />
                <button type="button" id="continuePauseButton" disabled="disabled" class="sideButton" style="padding-left: 0; background-image: url(img/play.png );" onclick="doStartStop();"></button>
            </div>


            <!--Map-->
            <div id="map"></div>
            <div id="map2"></div>

            <div id="textToReadArea0" class="ui-widget-content" style="z-index: 100; min-height: 50px; min-width: 50px; background: rgba(100,100,100,0.2); border-width: 0; width: 25%; height: 25%; position: absolute; left: 2%; top: 35%">
                <div id="textToReadArea" style="position: absolute; overflow: scroll; background: rgba(240,240,240,0.9); padding: 0; top: 2px; bottom: 2px; left: 2px; right: 2px; margin: 0 auto; resize: none;"></div>
            </div>

            <div id="imageDiv0" class="ui-widget-content">
                <div id="imageDiv" class="innerScrollArea">
                    <ul></ul>
                </div>
            </div>
        </div>
    </div>

    <script>
        $(function () {

            if ("True" == "<%=Tools.IsGuest(this)%>") {
                $("#newTrackButton").attr("disabled", "disabled");
                $("#profile").attr("disabled", "disabled");
            }

            //init();
            loadTrackOnPageLoad()
            //init(null, function () {
            //    doStartStop();
            //});
            //if (trackParam != '') {
            //    //loadTrackOnPageLoad();
            //}
            //else {
            //    //init();
            //}


            if (trackParam == "" || "True" == "<%=Tools.IsGuest(this)%>") {
                $("#editTrackButton").attr("disabled", "disabled");
            }

            var visited = $.cookie('visited'); // create cookie 'visited' with no value
            if (visited != 'yes') {
                //jQuery.tour(tourSteps);
                clickHelp();
            }

            $("#imageDiv0").draggable().resizable({ minHeight: 50, minWidth: 50 });
            $("#textToReadArea0").draggable().resizable({ minHeight: 50, minWidth: 50 }).hide();
            //$("#scriptTextCheckBox").button();
            //$("#imagesCheckBox").button();
            //$("#useFlickrImagesCheckBox").button();
            //$("#useSYTImagesCheckBox").button();
            //$("#useGooglePlacesCheckBox").button();
            //$("#useSYTPlacesCheckBox").button();
            $("#slider").slider({
                value: 0.8,
                min: 0,
                max: 1,
                step: 0.1,
                slide: function (event, ui) {
                    audio.volume = ui.value;
                }
            });
            audio.volume = $("#slider").slider("value");

            LoadSettings();


            //$('.owl-carousel').owlCarousel({
            //    autoWidth:true,
            //    loop: true,
            //    margin: 10,
            //    responsiveClass: true,
            //    responsive: {
            //        0: {
            //            items: 1,
            //            nav: true
            //        },
            //        600: {
            //            items: 3,
            //            nav: false
            //        },
            //        1000: {
            //            items: 5,
            //            nav: true,
            //            loop: false
            //        }
            //    }
            //});

            $.ajax(
                {
                    url: ("services/get_myandpublictracks.aspx?locale=" + $("#langList").val() + "&rnd=" + Math.random()),
                    //async: false,
                    //dataType: 'json'
                    error: function (XMLHttpRequest, textStatus, errorThrown) {
                        console.log("get_myandpublictracks error: " + textStatus); console.log("Error: " + errorThrown);
                    },
                    success: function (data) {
                        var fileList = data.split('\n');
                        tracksList
                            .find('option')
                            .remove()
                            .end()
                        var label = "";
                        tracksList.append('<option value="Choose a track" data-i18n="Chooseatrack">Choose a track:</option>');
                        clearSidePanel();

                        markersTracks.clearLayers();

                        for (var i = 0; i < fileList.length; i++) {
                            var parts = fileList[i].split(';');
                            if (label != parts[3]) {
                                label = parts[3];
                                tracksList.append('<optgroup label="' + label + '" style="color: black;"/>');
                            }
                            tracksList.append('<option value="' + parts[0] + '">' + (parts[2] == 1 ? "" : "*") + parts[1] + '</option>');
                            var isSelected = (trackParam == parts[0]);
                            //                        var sidePanelHtml = (isSelected ? '<b>' : '') +
                            //                            label + ':<br/>' + (parts[2] == 1 ? '' : '*') + parts[1]
                            //                            + (trackParam == parts[0] ? '</b>' : '');
                            //                        var sidePanelHref = (isSelected ? '' : 'index.aspx?trackName=' + parts[0]);
                            //                        appendToSidePanel(sidePanelHtml, sidePanelHref, parts[4]);
                            if (parts[5].length > 0) {
                                var location = JSON.parse(parts[5]);

                                var iconTrack = L.icon({
                                    iconUrl: (parts[4] ? 'tracks/content/' + parts[4]:'img/track.png'),
                                    iconSize: [30, 30],
                                    iconAnchor: [15, 15],
                                    shadowUrl: 'img/shadow.png',
                                    shadowSize: [32, 32],
                                    shadowAnchor: [16, 16]
                                });

                                var fileName = parts[0];
                                var text = parts[1];
                                var imgPath = (parts[4] != "") ? ("tracks/content/" + parts[4]) : ("img/track.png");
                                var domelem = document.createElement('a');
                                //domelem.href = place.name;
                                domelem.innerHTML = "<p>" + text + "</p><img height='100px' width='100px' src='" + imgPath + "'/>";
                                domelem.alt = text;
                                domelem.href = "./index.aspx?trackname=" + fileName;
                                domelem.target = "_blank";

                                if (!location.lat && !location.lng) {
                                    location.lat = location[0];
                                    location.lng = location[1];
                                }

                                var markerTrack = L.marker(new L.LatLng(location.lat - 0.0002 + Math.random() * 0.0004, location.lng - 0.0002 + Math.random() * 0.0004),
                                    { icon: iconTrack })
                                    .bindPopup(domelem);

                                markersTracks.addLayer(markerTrack);
                            }
                        }

                        if (trackParam != '') {
                            //                        setTimeout(loadTrackOnPageLoad, 1);
                            tracksList.val(trackParam);
                        }

                        if (window.JSInterface && window.JSInterface.notifyPageLoaded)
                            window.JSInterface.notifyPageLoaded();

                    }
                });

        });
    </script>
</asp:Content>

