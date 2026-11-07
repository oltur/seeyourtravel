<%@ Page Title="SeeYourTravel – replay your journey on the map" Language="C#" MasterPageFile="MasterPage.master" CodeFile="Index.aspx.cs" Inherits="Index" %>

<%@ Import Namespace="System.IO" %>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadPlaceholder" runat="Server">
    <meta name="description" content="SeeYourTravel is a free web app to create, share and replay journeys on a map, with photos, places, weather and an AI travel companion." />
    <link rel="canonical" href="https://seeyourtravel.app/" />
    <script type="application/ld+json">
    {
      "@context": "https://schema.org",
      "@type": "WebApplication",
      "name": "SeeYourTravel",
      "url": "https://seeyourtravel.app/",
      "applicationCategory": "TravelApplication",
      "operatingSystem": "Any (web browser)",
      "description": "Create, share and replay journeys on a map, with photos, places, weather, the elevation profile and an AI travel companion.",
      "inLanguage": ["en", "uk", "de", "he"],
      "offers": { "@type": "Offer", "price": "0", "priceCurrency": "EUR" }
    }
    </script>
    <script>
        var sideMenuNo = 0;
        var errorMessage = '<%=Request["errorMessage"]%>';
        var trackParam = '<%=this.TrackFileName%>';
        var showSidePanel = "no";//'<%=Request["showSidePanel"]%>';

        var audio;
        var imageDiv;
        var tracksList;
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
    <!-- the same facts as text, for search engines and screen readers (the map itself is drawn by script) -->
    <div class="srOnly">
        <h1>SeeYourTravel – replay your journey on the map</h1>
        <p>SeeYourTravel is a free web app for creating, sharing and replaying journeys on a map. A route is played back with photos, places, weather and the elevation profile along the way.</p>
        <p><a href="/track/">Browse the public journeys</a> · <a href="/corporate/">About SeeYourTravel</a> · <a href="/press/">Press kit</a></p>
    </div>
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
                <select style="vertical-align: central; min-width: 150px; max-width: calc(100vw - 180px); height: 35px; text-overflow: ellipsis" id="tracksList" class="i graySelect" onchange="clickStart()"></select>
            </div>
            <div style="position: absolute; left: 240px; top: 15px; z-index: 1001">
                <div id="wrapper">
                    <span id="lblCoord" style="vertical-align: super; text-shadow: 1px 1px #ffffff;"></span>
                </div>
            </div>
            <!-- #Include virtual="include/mainMenu.inc" -->
            <!-- #Include virtual="include/profileHelpPanel.inc" -->
            <!-- #Include virtual="include/settingsPanel.inc" -->

            <div style="position: absolute; right: 0px; top: 75px; z-index: 1001">
                <img id="imgComments" src="img/comments.png" onclick="clickHelp()" title="Comments" />
            </div>

            <div style="position: absolute; right: 0px; top: 120px; z-index: 1001">
                <button type="button" id="mute" style="padding-left: 0; background-image: url(img/unmute.png );" class="sideButton" onclick="clickMute();SaveSettings();"></button>
                <br />
                <button type="button" id="continuePauseButton" disabled="disabled" class="sideButton" style="padding-left: 0; background-image: url(img/play.png );" onclick="doStartStop();"></button>
                <br />
                <button type="button" id="restartButton" disabled="disabled" class="sideButton i" data-i18n="[title]RestartRoute;[aria-label]RestartRoute" title="Restart route" aria-label="Restart route" style="padding-left: 0; background-image: url(img/restart.png );" onclick="restartRoute();"></button>
                <br />
                <button type="button" id="immersiveButton" class="sideButton" title="Immersive flight" aria-label="Immersive flight" style="padding-left: 0; background-image: url(img/immersive.svg);" onclick="sytImmersive.toggle();"></button>
                <br />
                <button type="button" id="fsButton" class="sideButton" title="Fullscreen" aria-label="Fullscreen" style="padding-left: 0; background-image: url(img/fullscreen.svg);" onclick="sytFullscreen.toggle();"></button>
            </div>


            <link rel="stylesheet" href="<%=Tools.V("styles/immersive.css")%>" />
            <script src="<%=Tools.V("js/immersive.js")%>"></script>
            <link rel="stylesheet" href="<%=Tools.V("styles/seek.css")%>" />
            <script src="<%=Tools.V("js/seek.js")%>"></script>
            <!--Map-->
            <div id="map"></div>
            <div id="map2"></div>


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
                $("#recordButton").attr("disabled", "disabled");
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
            if (visited != 'yes' && trackParam == "") {
                // welcome panel: only for a first visit without a track link, and only once
                clickHelp();
                $.cookie('visited', 'yes', { expires: 365, path: '/' });
                $('#dontShowOnStartup').prop('checked', true);
            }

            // the photo strip is resized with its own top handle (see OurTravel.js)
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
                        tracksList.append($('<option value="Choose a track" data-i18n="Chooseatrack"></option>').text((window.T ? T("Chooseatrack", "Choose a track:") : "Choose a track:")));
                        clearSidePanel();

                        markersTracks.clearLayers();

                        for (var i = 0; i < fileList.length; i++) {
                            var parts = fileList[i].split(';');
                            if (label != parts[3]) {
                                label = parts[3];
                                tracksList.append($('<optgroup style="color: black;"/>').attr('label', (window.T ? T(label, label) : label)));
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

