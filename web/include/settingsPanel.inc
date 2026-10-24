
        <div id="settingsPanel" style="display: none; position:absolute; padding: 10px; z-index: 1001; top: 60px; left: 60px; width: 300px; height: auto; background: rgba(255,255,255,0.8); border-radius: 12px; border: 0px solid #000;">
            <input id="scriptTextCheckBox" type="checkbox" title="Description" onchange="SaveSettings();$('#textToReadArea0').toggle('fold', 1000);" />
            <label for="scriptTextCheckBox" class="i" data-i18n="Description">Description</label>
            <br />
            <input id="imagesCheckBox" type="checkbox" checked="checked" title="Images" onchange="SaveSettings(); $('#imageDiv0').toggle('fold', 1000);" />
            <label for="imagesCheckBox" class="i" data-i18n="Images">Images</label>
            <br />
<%--            <input id="sidePanelCheckBox" type="checkbox" title="Show Side Panel" onchange="switchSidePanel();" />
            <label for="sidePanelCheckBox" class="i" data-i18n="ShowSidePanel">Show Side Panel</label>
            <br />--%>
            <input id="loopTrackCheckBox" type="checkbox" checked="checked" title="Loop track infinitely"  onchange="SaveSettings();"/>
            <label for="loopTrackCheckBox" class="i" data-i18n="LoopTrack">Loop track infinitely</label>
            <br />
            <input id="useFlickrImagesCheckBox" type="checkbox" checked="checked" title="Use Flickr images"  onchange="SaveSettings();"/>
            <label for="useFlickrImagesCheckBox" class="i" data-i18n="useFlickrImagesCheckBox">Use public photos (Wikimedia Commons)</label>
            <br />
            <input id="useSYTImagesCheckBox" type="checkbox" checked="checked" title="Use SeeYourTravel images"  onchange="SaveSettings();"/>
            <label for="useSYTImagesCheckBox" class="i" data-i18n="UseCYTImages">Use SeeYourTravel images</label>
            <br />
            <input id="useGooglePlacesCheckBox" type="checkbox" checked="checked" title="Use Google Places"  onchange="SaveSettings();"/>
            <label for="useGooglePlacesCheckBox" class="i" data-i18n="UseGooglePlaces">Use Google Places</label>
            <br />
            <input id="useSYTPlacesCheckBox" type="checkbox" checked="checked" title="Use SeeYourTravel places"  onchange="SaveSettings();"/>
            <label for="useSYTPlacesCheckBox" class="i" data-i18n="UseCYTPlaces">Use SeeYourTravel places</label>
            <br />
            <input id="flyInCheckBox" type="checkbox" checked="checked" title="Photos fly in on the map" onchange="SaveSettings();"/>
            <label for="flyInCheckBox" class="i" data-i18n="FlyIn">Photos fly in on the map</label>
            <br />
            <input id="followCheckBox" type="checkbox" checked="checked" title="The map moves along with the marker" data-i18n="[title]FollowTrackHint" class="i" onchange="followChanged();"/>
            <label for="followCheckBox" class="i" data-i18n="[title]FollowTrackHint;FollowTrack" title="The map moves along with the marker">Follow the track on the map</label>
            <br />
            <input id="shareLocationCheckBox" type="checkbox" disabled="disabled" title="Sign in to share your position" />
            <label for="shareLocationCheckBox" class="i" data-i18n="ShareLocation">Share my position with others who share theirs</label>
            <div id="shareLocationNote" class="i" data-i18n="ShareLocationSignIn" style="font-size: 12px; color: #5a6675; margin: 0 0 4px 22px;">Sign in to use this. Off by default.</div>
<%--            <br />
            <label for="pictureHeight">Max Picture Height</label>
            <input id="pictureMaxHeight" type="number" value="100" />--%>
            <br />
            <label for="mapStyle" class="i" data-i18n="MapStyle">Map style</label>
            <select id="mapStyle" class="graySelect" onchange="SaveSettings();selectMapStyle()">
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
            <br />
            <input id="realisticSpeedCheckBox" type="checkbox" title="Overrides the speed of the track" data-i18n="[title]RealisticSpeedHint" class="i" onchange="onRealisticSpeedChange();"/>
            <label for="realisticSpeedCheckBox" class="i" data-i18n="[title]RealisticSpeedHint;RealisticSpeed" title="Overrides the speed of the track">Realistic speed for the means of transport</label>
            <br />
            <label for="speedSlider" class="i" data-i18n="MovingSpeed">Moving speed:</label>
            <span id="speedValue">1800 km/h</span>
            <br />
            <input id="speedSlider" type="range" min="5" max="3000" step="5" value="1800" style="width: 80%; margin-left: 10%" title="Moving speed"
                oninput="changeSpeed(this.value)" onchange="SaveSettings();" />
            <br />
            <span class="i" data-i18n="Volume">Volume:</span>
            <br />
            <div id="slider" style="left: 10%; width: 80%; vertical-align: top" ></div>
            <script>
                $("#slider").on("slidestop", function (event, ui) {
                    SaveSettings();
                });
            </script>
        </div>
