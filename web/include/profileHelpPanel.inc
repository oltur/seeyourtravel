<div id="helpPanel" style="display: none; padding: 10px; position: absolute; z-index: 1000; right: 10px; top: 50px; background: rgba(255,255,255,0.8); border-radius: 12px; border: 0px solid #000;">
  <div id="tabs-movie">
    <ul>
      <li>
        <a href="#tab-welcome">Hello!</a>
      </li>
      <li>
        <a href="#tab-info">Track</a>
      </li>
      <li>
        <a href="#tab-cast">Comments</a>
      </li>
    </ul>
    <div id="tab-welcome" style="display: inline-block;">
      <img src="../img/syt-logo-small.png" style="height:50px; display: inline; margin: 0 5px;" alt=""/>
      <button id="takeATour" style="width: 200px; height: 50px; font-size: large" type="button" onClick="javascript:jQuery.tour(tourSteps)">Take a tour!</button>
      <div id="helpContext">
	  <!-- class="i" data-i18n="[html]help_content"-->
      </div>
      <input id="dontShowOnStartup" type="checkbox" title="Don't show on startup" onchange="$.cookie('visited',$('#dontShowOnStartup').prop('checked')?'yes':'no');if(IS_MOBILE_LIGHTWEIGHT) { clickHelp(); }"/>
      <label for="dontShowOnStartup">
        <b>Don't show a tour and welcome message on startup</b>
      </label>
      <script>
        $('#dontShowOnStartup').prop('checked',$.cookie('visited')=='yes');
      </script>
    </div>
    <div id="tab-info">
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
  $('#helpPanel').css("width", getIsMobile() ? (getScreenWidth()-50).toString() : '500px');

  $('#tabs-movie').tabs({
  create: function (e, ui) {
  $('#closeHelpPanel').click(function () {
  showHelpPanel(false);
  });
  }
  });

</script>