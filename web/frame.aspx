<%@ Page Title="See Your Travel" Language="C#" MasterPageFile="MasterPage.master" %>

<%@ Import Namespace="System.IO" %>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadPlaceholder" runat="Server">
    <script>
        var trackParam = '<%=Request["trackname"]%>';

        $(function () {
            if (trackParam == "") {
                window.location = "index.aspx";
            }
        });

        function translateAll(err, t) {
            $(".i").i18n();
            $("option.i").i18n();
        }

    </script>
</asp:Content>

<asp:Content ID="bodyContent" ContentPlaceHolderID="BodyPlaceholder" runat="Server">
    <div class="langButton">
        <select style="" id="langList" class="graySelect" onchange="selectLang()"></select>
    </div>
    <!--Content-->
    <div id='pageContent' style='height: 100%'>
        <div style="position: absolute; left: 5px; top: 15px; z-index: 1001">
            <a id="alogo" href="javascript:window.open('./corporate','_blank')">
                <img src="img/syt-icon-192.png" style="height: 50px; width: 50px; vertical-align: middle;" /></a>
            <span id="lblCoord" style="visibility: hidden; vertical-align: super; text-shadow: 1px 1px #ffffff;"></span>
        </div>
        <script>
            $("#alogo").attr("href", "javascript:window.open('" + window.location.toString().replace("frame.aspx", "index.aspx") + "','_blank')");
        </script>
        <div id="settingsPanel" style="display: none; position: absolute; padding: 10px; z-index: 100; top: 60px; left: 60px; width: 300px; height: 200px; background: rgba(255,255,255,0.8); border-radius: 12px; border: 0 solid #000;">
            <input id="scriptTextCheckBox" type="checkbox" title="Description" onchange="$('#textToReadArea0').toggle('fold', 1000);" />
            <label for="scriptTextCheckBox" class="i" data-i18n="Description">Description</label>
            <br />
            <input id="imagesCheckBox" type="checkbox" checked="checked" title="Images" onchange=" $('#imageDiv0').toggle('fold', 1000);" />
            <label for="imagesCheckBox" class="i" data-i18n="Images">Images</label>
            <br />
            <input id="loopTrackCheckBox" type="checkbox" checked="checked" title="Loop track infinitely" onchange="" />
            <label for="loopTrackCheckBox" class="i" data-i18n="LoopTrack">Loop track infinitely</label>
            <br />
            <input id="useFlickrImagesCheckBox" type="checkbox" checked="checked" title="Use Flickr images" onchange="" />
            <label for="useFlickrImagesCheckBox" class="i" data-i18n="useFlickrImages">Use public photos (Wikimedia Commons)</label>
            <br />
            <input id="useGooglePlacesCheckBox" type="checkbox" checked="checked" title="Use Google Places" onchange="" />
            <label for="useGooglePlacesCheckBox" class="i" data-i18n="UseGooglePlaces">Use Google Places</label>
            <br />
            <input id="useSYTPlacesCheckBox" type="checkbox" checked="checked" title="Use SeeYourTravel places" onchange="" />
            <label for="useSYTPlacesCheckBox" class="i" data-i18n="UseCYTPlaces">Use SeeYourTravel places</label>
            <%--            <br />
            <label for="pictureHeight">Max Picture Height</label>
            <input id="pictureMaxHeight" type="number" value="100" />
--%>
<%--
            <br />
            <label for="mapStyle" class="i" data-i18n="MapStyle">Map style</label>
            <select id="mapStyle" class="graySelect" onchange="selectMapStyle()">
                <option>mapbox.streets</option>
                <option>mapbox.light</option>
                <option>mapbox.dark</option>
                <option>mapbox.satellite</option>
                <option>mapbox.streets-satellite</option>
                <option>mapbox.wheatpaste</option>
                <option>mapbox.streets-basic</option>
                <option>mapbox.comic</option>
                <option>mapbox.outdoors</option>
                <option>mapbox.run-bike-hike</option>
                <option>mapbox.pencil</option>
                <option>mapbox.pirates</option>
                <option>mapbox.emerald</option>
                <option>mapbox.high-contrast</option>
            </select>
--%>
            <br />
            <span class="i" data-i18n="Volume">Volume:</span>
            <br />
            <div id="slider" style="left: 10%; width: 80%; vertical-align: top"></div>
        </div>
        <div style="position: absolute; right: 0px; top: 75px; z-index: 1001">
            <div>
                <button type="button" id="mute" style="width: 15px; background-image: url(img/unmute.png );" class="sideButton" onclick="clickMute();"></button>
                <br />
                <button type="button" id="continuePauseButton" disabled="disabled" class="sideButton" style="width: 15px; background-image: url(img/play.png );" onclick="doStartStop();"></button>
            </div>
        </div>


        <!--Map-->
        <div id="map"></div>
        <div id="map2"></div>

        <audio id="audio" loop="loop">
            <source type="audio/mpeg" />
            Your browser does not support the audio element.
        </audio>

        <div id="textToReadArea0" class="ui-widget-content" style="z-index: 100; background: rgba(100,100,100,0.2); border-width: 0; width: 25%; height: 25%; position: absolute; left: 2%; top: 35%">
            <br />
            <textarea id="textToReadArea" disabled="disabled" style="top: 25%; width: 99%; height: 88%; resize: none;"></textarea>
        </div>

        <div id="imageDiv0" class="ui-widget-content">
            <div id="imageDiv" class="innerScrollArea">
                <ul></ul>
            </div>
        </div>
    </div>

    <!-- Welcome splash -->
    <script>

        function loadTrackOnPageLoad() {
            init(trackParam,
                function () {
                    doStartStop();
                });
        }

    </script>

    <script>
        $(function () {

            map2 = document.getElementById("map2");
            audio = document.getElementById("audio");
            imageDiv = $("#imageDiv");
            tracksList = $("#tracksList");
            textToReadArea = document.getElementById("textToReadArea");

            $("#langList").hide();

            init();

            $("#imageDiv0").draggable().resizable();
            $("#textToReadArea0").draggable().resizable().hide();
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

            setTimeout(function () { loadTrackOnPageLoad() }, 10);

        });
    </script>


    <script lang="JavaScript">

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

    </script>

</asp:Content>

