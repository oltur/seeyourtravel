<%
    // The one search box of the account pages (My photos, My tracks, My places): type to filter, press Enter or "Ask" to let the AI assistant understand a sentence.
    // The ids are the ones the pages' scripts use (#askText, #askGo, #askBar, #askSay, #askClear).
    string pfsPage = System.IO.Path.GetFileNameWithoutExtension(Request.Path).ToLowerInvariant();
    string pfsKey = pfsPage == "usertracks" ? "AskPlaceholderTracks" : pfsPage == "userplaces" ? "AskPlaceholderPlaces" : "AskPlaceholder";
    string pfsText = pfsPage == "usertracks" ? "Search or ask: “tracks with beaches in Italy”" : pfsPage == "userplaces" ? "Search or ask: “cafes in Rome”" : "Search or ask: “beach at sunset”, “Anna in Italy, summer 2023”";
%>
<div id="askForm" class="pfAsk">
    <i class="fa fa-search"></i>
    <input type="text" id="askText" maxlength="300" placeholder="<%= pfsText %>" data-i18n="[placeholder]<%= pfsKey %>" />
    <button type="button" class="pfBtn" id="askGo"><span class="i" data-i18n="Ask">Ask</span></button>
</div>
<div class="pfAiNote"><i class="fa fa-info-circle"></i> <span class="i" data-i18n="AiSearchNote">AI-based search: it can make mistakes, so check the results.</span></div>
<div id="askBar" class="pfNote" style="display: none; align-items: center; gap: 8px"><i class="fa fa-magic" title="AI"></i> <span id="askSay" style="flex: 1"></span> <button type="button" class="pfBtn" id="askClear"><i class="fa fa-times"></i> <span class="i" data-i18n="ClearSearch">Clear</span></button></div>
