<div id="helpPanel" style="display: none; padding: 10px; position: absolute; z-index: 1000; right: 10px; top: 50px; background: rgba(255,255,255,0.8); border-radius: 12px; border: 0px solid #000;">
  <div id="tabs-movie">
    <ul>
      <li>
        <a href="#tab-welcome" class="i" data-i18n="HelloTab">Hello!</a>
      </li>
      <li>
        <a href="#tab-info" class="i" data-i18n="TrackTab">Track</a>
      </li>
      <li>
        <a href="#tab-cast" class="i" data-i18n="CommentsTab">Comments</a>
      </li>
    </ul>
    <button type="button" id="closeHelpPanel" class="hpClose i" data-i18n="[title]Close;[aria-label]Close" aria-label="Close" title="Close">&times;</button>
    <div id="tab-welcome" style="display: inline-block;">
      <img src="../img/syt-logo-small.png" style="height:42px; display: inline; margin: 0 5px;" alt=""/>
      <button id="takeATour" class="i" data-i18n="TakeATour" style="width: 180px; height: 42px; font-size: medium" type="button" onClick="javascript:jQuery.tour(tourSteps)">Take a tour!</button>
      <div id="helpContext">
	  <!-- class="i" data-i18n="[html]help_content"-->
      </div>
      <input id="dontShowOnStartup" type="checkbox" title="Don't show on startup" onchange="$.cookie('visited',$('#dontShowOnStartup').prop('checked')?'yes':'no');if(IS_MOBILE_LIGHTWEIGHT) { clickHelp(); }"/>
      <label for="dontShowOnStartup">
        <b class="i" data-i18n="DontShowTour">Don't show a tour and welcome message on startup</b>
      </label>
      <script>
        $('#dontShowOnStartup').prop('checked',$.cookie('visited')=='yes');
      </script>
    </div>
    <div id="tab-info">
      <div id="trackStats" class="trackStats"></div>
      <div id="elevationChartDiv">
      </div>
    </div>
    <div id="tab-cast">
      <div class="fb-comments" data-href=""
        <%=Request.Url.ToString()%>"
        data-width="400"
        data-numposts="5">
      </div>
    </div>
  </div>
</div>
<script>
  $('#helpPanel').css("width", getIsMobile() ? (getScreenWidth()-50).toString() : '400px');

  $('#tabs-movie').tabs({
  activate: function (e, ui) {
    // the Track tab is wide: it shows the track's figures and the elevation chart
    var wide = ui.newPanel.attr('id') === 'tab-info';
    $('#helpPanel').toggleClass('wide', wide);
    if (wide) { if (window.updateTrackStats) updateTrackStats(); setTimeout(function () { if (window.myBarChart && myBarChart.resize) myBarChart.resize(); }, 80); }
  },
  create: function (e, ui) {
  $('#closeHelpPanel').click(function () {
  showHelpPanel(false);
  });
  }
  });

</script>