// The search box of My tracks and My places (include/pfSearch.inc). Typing filters by name at once; Enter or "Ask" sends the sentence to the server, where the AI
// assistant turns it into words, a place and a time, and the site's own searches (photos that look like the words, country borders...) find the matches.
// The page passes: url (the search service), extra (more parameters), idsOf(answer) -> the matching ids best first, apply(rank, text) -> show them.
//   rank = {id: position} when the assistant's answer is shown, null for plain filtering by the text.
window.sytPfSearch = function (o) {
    var $ = window.jQuery, $in = $('#askText'), $bar = $('#askBar'), seq = 0, active = false;
    var KEY = 'sytPfRecent|' + location.pathname, recent = [];   // the last three requests: the assistant needs them for follow-ups ("only from 2023")
    try { recent = JSON.parse(sessionStorage.getItem(KEY) || '[]').slice(-3); } catch (e) { recent = []; }
    function remember(q) { recent.push(q); recent = recent.slice(-3); try { sessionStorage.setItem(KEY, JSON.stringify(recent)); } catch (e) { } }
    function t(k, d) { return window.T ? window.T(k, d) : d; }

    function clear() {
        seq++; active = false; recent = []; try { sessionStorage.removeItem(KEY); } catch (e) { }
        $in.val(''); $bar.hide(); o.apply(null, '');
    }
    function show(d, ask, note) {
        var ids = o.idsOf(d) || [], rank = {};
        ids.forEach(function (id, i) { rank[id] = i; });
        active = true; o.apply(rank, $.trim($in.val()));
        var parts = [];
        if (d && d.say) parts.push(d.say);
        parts.push(ids.length ? ids.length + ' ' + t('SearchMatches', 'matches') : t('SearchNone', 'Nothing matches.'));
        if (note) parts.push(note);
        $('#askSay').text(parts.join(' · ')); $bar.css('display', 'flex');
    }
    function run(ask) {
        var q = $.trim($in.val()); if (!q) { clear(); return; }
        var my = ++seq;
        $('#askGo').prop('disabled', true);
        var data = $.extend({ q: q, ask: ask ? 1 : 0, prev: JSON.stringify(recent), locale: (window.i18next && window.i18next.language) || '' }, o.extra || {});
        $.getJSON(o.url, data)
            .done(function (d) {
                if (my !== seq) return;
                if (d && d.error) { if (ask) { run(false); } return; }
                show(d, ask, ask && !d.say ? t('AssistOff', 'The assistant is not available; searched by words instead.') : '');
                if (ask && d.say) remember(q);
            })
            .fail(function (x) {
                if (my !== seq) return;
                if (ask) { run(false); return; }   // no assistant (not signed in, off, over its limit): the words themselves
                show({ places: [], tracks: [] }, false, t('SearchOff', 'Search by looks is not running.'));
            })
            .always(function () { if (my === seq) $('#askGo').prop('disabled', false); });
    }

    $in.on('input', function () { if (active) { active = false; $bar.hide(); } o.apply(null, $.trim($in.val())); });   // editing the text leaves the assistant's answer
    $in.on('keydown', function (e) { if (e.which === 13) { e.preventDefault(); run(true); } });
    $('#askGo').on('click', function () { run(true); });
    $('#askClear').on('click', clear);
    return { clear: clear };
};
