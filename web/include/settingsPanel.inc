
        <div id="settingsPanel" role="dialog" aria-label="Settings" style="display: none; position:absolute; padding: 10px; z-index: 1001; top: 60px; left: 60px; width: 300px; height: auto; background: rgba(255,255,255,0.96); border-radius: 12px; border: 0px solid #000; box-shadow: 0 6px 24px rgba(0,0,0,.28);">
            <div class="sp-bar"><b class="i" data-i18n="Settings">Settings</b><button type="button" class="sp-x" data-i18n="[title]Close;Close" title="Close" onclick="$('#settingsPanel').hide('slide', { direction: 'up' }, 300)"><i class="fa fa-times"></i></button></div>
            <div class="sp-h i" data-i18n="SettingsMapContent">What is shown on the map</div>
            <input id="scriptTextCheckBox" type="checkbox" checked="checked" title="Description" onchange="SaveSettings(); updateTrackStats();" />
            <label for="scriptTextCheckBox" class="i" data-i18n="Description">Description</label>
            <br />
            <input id="imagesCheckBox" type="checkbox" checked="checked" title="Images" onchange="SaveSettings(); $('#imageDiv0').toggle('fold', 1000);" />
            <label for="imagesCheckBox" class="i" data-i18n="Images">Images</label>
            <br />
<%--            <input id="sidePanelCheckBox" type="checkbox" title="Show Side Panel" onchange="switchSidePanel();" />
            <label for="sidePanelCheckBox" class="i" data-i18n="ShowSidePanel">Show Side Panel</label>
            <br />--%>
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
            <div class="sp-h i" data-i18n="SettingsPlayback">Playback</div>
            <input id="loopTrackCheckBox" type="checkbox" checked="checked" title="Loop track infinitely"  onchange="SaveSettings();"/>
            <label for="loopTrackCheckBox" class="i" data-i18n="LoopTrack">Loop track infinitely</label>
            <br />
            <input id="flyInCheckBox" type="checkbox" checked="checked" title="Photos fly in on the map" onchange="SaveSettings();"/>
            <label for="flyInCheckBox" class="i" data-i18n="FlyIn">Photos fly in on the map</label>
            <br />
            <input id="followCheckBox" type="checkbox" checked="checked" title="The map moves along with the marker" data-i18n="[title]FollowTrackHint" class="i" onchange="followChanged();"/>
            <label for="followCheckBox" class="i" data-i18n="[title]FollowTrackHint;FollowTrack" title="The map moves along with the marker">Follow the track on the map</label>
            <br />
            <input id="realisticSpeedCheckBox" type="checkbox" title="Overrides the speed of the track" data-i18n="[title]RealisticSpeedHint" class="i" onchange="onRealisticSpeedChange();"/>
            <label for="realisticSpeedCheckBox" class="i" data-i18n="[title]RealisticSpeedHint;RealisticSpeed" title="Overrides the speed of the track">Realistic speed for the means of transport</label>
            <br />
            <label for="speedSlider" class="i" data-i18n="MovingSpeed">Moving speed:</label>
            <span id="speedValue">1800 km/h</span>
            <br />
            <input id="speedSlider" type="range" min="5" max="5000" step="5" value="1800" style="width: 80%; margin-left: 10%" title="Moving speed"
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
            <div class="sp-h i" data-i18n="SettingsMapLook">Map appearance</div>
<%--            <br />
            <label for="pictureHeight">Max Picture Height</label>
            <input id="pictureMaxHeight" type="number" value="100" />--%>
            <br />
            <div id="imStyleRow" class="imOnly">
                <label for="imStyle" class="i" data-i18n="ImmersiveStyle">3D map style</label>
                <select id="imStyle" class="graySelect">
                    <option value="liberty" class="i" data-i18n="ImStyleStreets">Streets</option>
                    <option value="bright" class="i" data-i18n="ImStyleBright">Bright</option>
                    <option value="positron" class="i" data-i18n="ImStyleLight">Light</option>
                    <option value="dark" class="i" data-i18n="ImStyleDark">Dark</option>
                    <option value="fiord" class="i" data-i18n="ImStyleFiord">Blue</option>
                </select>
            </div>
            <div class="imOnly">
                <input id="imTerrainCheck" type="checkbox" checked="checked" />
                <label for="imTerrainCheck" class="i" data-i18n="ImTerrain">Hills (3D terrain)</label>
                <br />
                <input id="imWxCheck" type="checkbox" checked="checked" />
                <label for="imWxCheck" class="i" data-i18n="ImWeather">Weather in the sky</label>
                <br />
                <input id="imTickerCheck" type="checkbox" checked="checked" />
                <label for="imTickerCheck" class="i" data-i18n="ImTicker">Running line with nearby places</label>
            </div>
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
            <div class="sp-h i" data-i18n="SettingsPrivacy">Privacy</div>
            <input id="shareLocationCheckBox" type="checkbox" disabled="disabled" title="Sign in to share your position" />
            <label for="shareLocationCheckBox" class="i" data-i18n="ShareLocation">Share my position with others who share theirs</label>
            <div id="shareLocationNote" class="i" data-i18n="ShareLocationSignIn" style="font-size: 12px; color: #5a6675; margin: 0 0 4px 22px;">Sign in to use this. Off by default.</div>
        </div>
