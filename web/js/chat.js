// AI chat assistant: a round button at the bottom right opens a small chat. The answers come from services/chat.aspx (a model that may look up tracks and photos
// through the site's own searches, with the permissions of the signed-in person). Tracks and photos it finds are shown as cards under its text.
// Only for signed-in people (window.sytSignedIn is set by the master page).
(function () {
    if (!window.sytSignedIn || !window.jQuery) return;
    var $ = window.jQuery;
    function t(k, d) { return (window.T ? window.T(k, d) : d); }
    function esc(s) { return $('<div>').text(s == null ? '' : s).html(); }
    var KEY = 'sytChat', history = [], busy = false, panel = null, msgs = null, input = null, reqId = 0;
    try { history = JSON.parse(sessionStorage.getItem(KEY) || '[]').slice(-30); } catch (e) { history = []; }
    function save() { try { sessionStorage.setItem(KEY, JSON.stringify(history.slice(-30))); } catch (e) { } }

    // ---- voice: speech recognition (microphone) and speech synthesis (read aloud), only where the browser has them ----
    var SR = window.SpeechRecognition || window.webkitSpeechRecognition, synth = window.speechSynthesis;
    var canListen = !!SR, canSpeak = !!synth && typeof window.SpeechSynthesisUtterance === 'function';
    var AUTO = 'sytChatReadAloud', readAuto = false, rec = null, listening = false, micBtn = null, spokenAsk = false, speakingBtn = null;
    try { readAuto = localStorage.getItem(AUTO) === '1'; } catch (e) { }
    function speechLang() {
        var l = String((window.i18next && window.i18next.language) || navigator.language || 'en'), m = { en: 'en-US', de: 'de-DE', uk: 'uk-UA', he: 'he-IL' };
        return m[l.split('-')[0].toLowerCase()] || l;
    }
    // the language of a text, for the voice: by script (Hebrew, Cyrillic), and for Latin text by a few telltale letters and words (German, French, Spanish), else English
    function textLang(tx) {
        if (/[\u0590-\u05FF]/.test(tx)) return 'he-IL';
        if (/[\u0400-\u04FF]/.test(tx)) return 'uk-UA';
        if (/[äöüß]/i.test(tx) || /\b(der|die|das|und|ist|nicht|ich|du|wir|ein|eine|mit|für|von|auf|dein|deine|hier|sind)\b/i.test(tx)) return 'de-DE';
        if (/[éèêàçùœ]/i.test(tx) || /\b(le|la|les|des|est|vous|pour|avec|dans|voici|une)\b/i.test(tx)) return 'fr-FR';
        if (/[ñ¿¡]/.test(tx) || /\b(el|los|las|una|está|aquí|para|con|tus)\b/i.test(tx)) return 'es-ES';
        return 'en-US';
    }
    function speakable(text) {   // no emoji, no marker lines: only what a person would read out
        return String(text || '').replace(/\n\[searches done:[\s\S]*\]$/, '').replace(/[\u{1F000}-\u{1FFFF}\u{2600}-\u{27BF}\uFE0F\u200D]/gu, '').replace(/\s+/g, ' ').trim();
    }
    function stopSpeaking() { if (canSpeak) { try { synth.cancel(); } catch (e) { } } if (speakingBtn) { speakingBtn.removeClass('on'); speakingBtn = null; } }
    function speak(text, btn) {
        if (!canSpeak) return;
        var again = btn && btn.hasClass('on'); stopSpeaking(); if (again) return;
        var tx = speakable(text); if (!tx) return;
        var u = new SpeechSynthesisUtterance(tx); u.lang = textLang(tx);   // the voice follows the language of the answer, not of the page
        try { var vs = synth.getVoices() || [], pre = u.lang.split('-')[0].toLowerCase(), v = vs.filter(function (x) { return x.lang && x.lang.toLowerCase() === u.lang.toLowerCase(); })[0] || vs.filter(function (x) { return x.lang && x.lang.toLowerCase().indexOf(pre) === 0; })[0]; if (v) u.voice = v; } catch (e) { }
        if (btn) { speakingBtn = btn; btn.addClass('on'); }
        u.onend = u.onerror = function () { if (btn) btn.removeClass('on'); if (speakingBtn === btn) speakingBtn = null; };
        synth.speak(u);
    }

    function bubble(role, text) {
        var b = $('<div class="ch-msg"></div>').addClass(role).appendTo(msgs);
        $('<span class="ch-tx"></span>').text(text).appendTo(b);
        if (canSpeak && /^bot\b/.test(role) && !/ch-wait|err|ch-where/.test(role) && text)   // a small speaker on every answer
            b.append($('<button type="button" class="ch-say"><i class="fa fa-volume-up"></i></button>').attr('title', t('ChatRead', 'Read aloud')).attr('aria-label', t('ChatRead', 'Read aloud'))
                .on('click', function () { speak(text, $(this)); }));
        msgs.scrollTop(msgs[0].scrollHeight);
        return b;
    }
    function trackCard(tr) {
        var c = $('<div class="ch-card" role="button" tabindex="0"></div>').attr('data-v', tr.file);
        c.append($('<div class="ch-ct"></div>').text(tr.desc).append(tr.n ? $('<span></span>').text(' · ' + tr.n + ' ' + t('Photos', 'photos').toLowerCase()) : ''));
        if (tr.photos && tr.photos.length) c.append($('<div class="ch-th"></div>').append(tr.photos.map(function (f) { return $('<img alt="" loading="lazy">').attr('src', 'services/get_thumbnail.aspx?size=small&p=' + encodeURIComponent(f))[0]; })));
        return c;
    }
    function openTrack(file) {
        var sel = document.getElementById('tracksList');
        if (sel && $(sel).find('option').filter(function () { return this.value === file; }).length) {
            sel.value = file; sel.dispatchEvent(new Event('change', { bubbles: true }));
            if (window.innerWidth < 700) panel.hide();
        } else location.href = 'index.aspx?trackname=' + encodeURIComponent(file);
    }
    function photosButton(p, label) {
        return $('<button type="button" class="ch-show"></button>').html('<i class="fa fa-picture-o"></i> ' + esc(t('ChatShowPhotos', 'Show these photos') + ' (' + p.count + (p.count > p.files.length ? ', ' + p.files.length : '') + ')'))
            .on('click', function () {
                if (window.sytApplyFound) { window.sytApplyFound(p.files, label); if (window.innerWidth < 700) panel.hide(); return; }
                try { sessionStorage.setItem('sytChatPhotos', JSON.stringify({ files: p.files, label: label })); } catch (e) { }
                location.href = 'UserPhotos.aspx?chat=1';
            });
    }

    // what is on the screen now (the page defines window.sytChatContext), so questions like "where am I" or "what is shown" can be answered
    function screenContext() {
        try {
            if (!window.sytChatContext) return '';
            var c = window.sytChatContext(), j = JSON.stringify(c);
            // too long for one request: shorten the long lists step by step (never cut the text, that would break it)
            var steps = [function () { if (c.photo_strip && c.photo_strip.on_screen_now) c.photo_strip.on_screen_now = c.photo_strip.on_screen_now.slice(0, 6); }, function () { if (c.places_on_map) c.places_on_map = c.places_on_map.slice(0, 12); },
                         function () { if (c.track_properties_panel) c.track_properties_panel = c.track_properties_panel.slice(0, 500); }, function () { if (c.elevation) delete c.elevation.profile_km_and_height_m; }, function () { delete c.places_on_map; delete c.weather_on_map; }];
            for (var i = 0; i < steps.length && j.length > 8500; i++) { steps[i](); j = JSON.stringify(c); }
            return j.length > 8500 ? '' : j;
        } catch (e) { return ''; }
    }

    // text = what the person typed (shown); sent = what the model gets (the map search box adds a marker in front)
    function send(text, sent, spoken) {
        text = $.trim(text); if (!text || busy) return;
        busy = true; input.val('');
        var my = ++reqId;   // a question still waiting when the chat is cleared must not answer into the empty chat
        bubble('me', text); history.push({ role: 'user', text: sent || text });
        var wait = bubble('bot ch-wait', '…');
        // the page may need a moment to fetch what the assistant should see (e.g. the elevation of the track)
        var prep = window.sytChatPrepare ? window.sytChatPrepare() : $.Deferred().resolve().promise();
        prep.then(function () {
            return $.ajax({ url: 'services/chat.aspx', method: 'POST', dataType: 'json', timeout: 90000,
                 data: { history: JSON.stringify(history.slice(-14)), locale: (window.i18next && window.i18next.language) || '', context: screenContext() } });
        })
            .done(function (d) {
                if (my !== reqId) return;
                wait.remove();
                if (d.error) {
                    var msg = d.error === 'limit' ? t('ChatLimit', 'I have talked enough for today (a limit protects the budget). Please come back later.')
                        : d.error === 'not signed in' ? t('SignInToAsk', 'Sign in to ask the assistant.') : t('ChatOff', 'The assistant is not available right now.');
                    bubble('bot err', msg); history.pop(); save(); return;
                }
                var b = bubble('bot', d.text || '');
                if ((spoken || readAuto) && canSpeak && d.text) speak(d.text, b.find('.ch-say'));   // asked by voice: answered by voice
                if (d.map && d.map.bbox && window.map && window.map.fitBounds) {   // the assistant moves the map to a place (nothing else on the page changes)
                    var bb = d.map.bbox;
                    try { window.map.fitBounds([[bb[0], bb[1]], [bb[2], bb[3]]], { animate: true, maxZoom: 15 }); $('<div class="ch-msg bot ch-where"></div>').text('\ud83d\udccd ' + (d.map.place || '')).appendTo(msgs); } catch (e) { }
                }
                // the model's turn is kept with a short note of the searches it did, so a follow-up ("only from 2023") knows what was searched; the person sees only the text
                history.push({ role: 'model', text: (d.text || '') + (d.used && d.used.length ? '\n[searches done: ' + d.used.join('; ') + ']' : '') }); save();
                if (d.tracks && d.tracks.length) {
                    var cards = $('<div class="ch-cards"></div>').appendTo(msgs);
                    d.tracks.slice(0, 6).forEach(function (tr) { cards.append(trackCard(tr)); });
                }
                if (d.photos && d.photos.count) $('<div class="ch-cards"></div>').append(photosButton(d.photos, d.text || '')).appendTo(msgs);
                msgs.scrollTop(msgs[0].scrollHeight);
            })
            .fail(function () { if (my !== reqId) return; wait.remove(); bubble('bot err', t('ChatOff', 'The assistant is not available right now.')); history.pop(); save(); })
            .always(function () { if (my === reqId) { busy = false; input.focus(); } });
    }

    function hello() { bubble('bot', t('ChatHello', 'Hi! I can find your tracks and photos (“beaches in Italy”, “Anna in 2023”) — or we can just chat. I only know what your library shows me, so I will say so when I do not know.')); }

    // a fresh start: forgets the conversation (in this tab too) and drops an answer that has not arrived yet
    function clearChat() {
        reqId++; busy = false; history = []; save(); stopSpeaking(); if (listening && rec) { try { rec.abort(); } catch (e) { } }
        msgs.empty(); hello(); input.val('').focus();
    }

    function toggleMic() {
        if (!canListen) return;
        if (listening && rec) { try { rec.stop(); } catch (e) { } return; }
        stopSpeaking();
        rec = new SR(); rec.lang = speechLang(); rec.interimResults = true; rec.continuous = false; rec.maxAlternatives = 1;
        spokenAsk = false; var heard = '';
        rec.onstart = function () { listening = true; micBtn.addClass('on').attr('title', t('ChatMicStop', 'Stop listening')); input.attr('placeholder', t('ChatListening', 'Listening…')); };
        rec.onresult = function (e) {
            heard = ''; for (var i = 0; i < e.results.length; i++) heard += e.results[i][0].transcript;
            input.val(heard); if (e.results[e.results.length - 1].isFinal) spokenAsk = true;
        };
        rec.onerror = function (e) {
            if (e.error === 'not-allowed' || e.error === 'service-not-allowed') bubble('bot err', t('ChatMicBlocked', 'The microphone is blocked: allow it in the browser to talk to me.'));
            else if (e.error === 'language-not-supported') bubble('bot err', t('ChatMicLang', 'Voice input is not available for this language in your browser.'));
        };
        rec.onend = function () {
            listening = false; micBtn.removeClass('on').attr('title', t('ChatMic', 'Speak'));
            input.attr('placeholder', t('ChatPlaceholder', 'Ask about your tracks and photos, or just chat…'));
            if (spokenAsk && $.trim(input.val())) { spokenAsk = false; send(input.val(), null, true); }
        };
        try { rec.start(); } catch (e) { }
    }

    // the window is anchored at the bottom right, so it grows to the left only (width, never height): the grip is the whole left edge
    var SIZE = 'sytChatSize';
    function fitSize(w, h) {
        var maxW = window.innerWidth - 24;
        return [Math.max(Math.min(280, maxW), Math.min(w, maxW))];
    }
    function applySize() {
        var sz = null; try { sz = JSON.parse(localStorage.getItem(SIZE) || 'null'); } catch (e) { }
        if (sz && sz.w) panel.css({ width: fitSize(sz.w)[0] });
    }
    function makeResizable(grip) {
        grip.on('pointerdown', function (e) {
            e.preventDefault();
            var x0 = e.clientX, w0 = panel.outerWidth();
            panel.addClass('resizing');   // no text selection and no map dragging while the mouse is down
            function move(ev) { panel.css({ width: fitSize(w0 + (x0 - ev.clientX))[0] }); msgs.scrollTop(msgs[0].scrollHeight); }
            function up() {
                $(document).off('pointermove.chRs', move).off('pointerup.chRs pointercancel.chRs', up);
                panel.removeClass('resizing');
                try { localStorage.setItem(SIZE, JSON.stringify({ w: panel.outerWidth() })); } catch (er) { }
            }
            $(document).on('pointermove.chRs', move).on('pointerup.chRs pointercancel.chRs', up);   // on the document: the pointer leaves the small grip at once
        });
        $(window).on('resize', function () { if (panel && panel.is(':visible')) panel.css({ width: fitSize(panel.outerWidth())[0] }); });
    }

    function build() {
        panel = $('<div id="chatPanel" role="dialog" aria-label="AI"></div>').appendTo('body');
        var grip = $('<div class="ch-grip" role="separator" aria-label="Resize"></div>').attr('title', t('ChatResize', 'Drag to resize')).appendTo(panel);
        var head = $('<div class="ch-head"></div>').append('<i class="fa fa-magic"></i> ').append($('<b></b>').text(t('ChatTitle', 'AI assistant')))
            .append(canSpeak ? $('<button type="button" class="ch-x ch-auto"><i class="fa fa-volume-up"></i></button>').toggleClass('off', !readAuto).attr('title', t('ChatReadAuto', 'Read answers aloud')).attr('aria-label', t('ChatReadAuto', 'Read answers aloud'))
                .on('click', function () { readAuto = !readAuto; $(this).toggleClass('off', !readAuto); if (!readAuto) stopSpeaking(); try { localStorage.setItem(AUTO, readAuto ? '1' : '0'); } catch (e) { } }) : '')
            .append($('<button type="button" class="ch-x ch-clear"><i class="fa fa-eraser"></i></button>').attr('title', t('ChatClear', 'Clear chat')).attr('aria-label', t('ChatClear', 'Clear chat')).on('click', clearChat))
            .append($('<button type="button" class="ch-x" title="Close"><i class="fa fa-times"></i></button>').on('click', function () { panel.hide(); stopSpeaking(); if (listening && rec) { try { rec.abort(); } catch (e) { } } }));
        var note = $('<div class="ch-note"></div>').text(t('AiSearchNote', 'AI-based search: it can make mistakes, so check the results.'));
        msgs = $('<div class="ch-msgs"></div>');
        input = $('<input type="text" maxlength="500" autocomplete="off" class="ch-in">').attr('placeholder', t('ChatPlaceholder', 'Ask about your tracks and photos, or just chat…'))
            .on('keydown', function (e) {
                if (e.which === 13) { e.preventDefault(); send(input.val()); return; }
                // the arrow and page keys scroll the conversation (the text field is one line, so they have nothing else to do there)
                var step = e.which === 38 ? -48 : e.which === 40 ? 48 : e.which === 33 ? -msgs.innerHeight() * 0.9 : e.which === 34 ? msgs.innerHeight() * 0.9 : 0;
                if (step) { e.preventDefault(); msgs.stop().animate({ scrollTop: msgs.scrollTop() + step }, 120); }
            });
        var go = $('<button type="button" class="ch-go"><i class="fa fa-paper-plane"></i></button>').on('click', function () { send(input.val()); });
        micBtn = canListen ? $('<button type="button" class="ch-mic"><i class="fa fa-microphone"></i></button>').attr('title', t('ChatMic', 'Speak')).attr('aria-label', t('ChatMic', 'Speak')).on('click', toggleMic) : $();
        panel.append(head, note, msgs, $('<div class="ch-bar"></div>').append(input, micBtn, go));
        makeResizable(grip); applySize();
        panel.on('click keydown', '.ch-card', function (e) { if (e.type === 'click' || e.which === 13) openTrack($(this).attr('data-v')); });
        if (!history.length) hello();
        else history.forEach(function (h) { bubble(h.role === 'user' ? 'me' : 'bot', String(h.text).replace(/\n\[searches done:[\s\S]*\]$/, '').replace(/^\[Map search box\] /, '')); });
    }

    // the map's search box hands a sentence (or a place Google could not find) to the assistant
    window.sytChatAsk = function (q) {
        if (!panel) build();
        panel.show(); msgs.scrollTop(msgs[0].scrollHeight);
        send(q, '[Map search box] ' + q);
    };

    $(function () {
        var btn = $('<button type="button" id="chatBtn" title="AI"><i class="fa fa-comments"></i></button>').appendTo('body')
            .on('click', function () {
                if (!panel) build();
                panel.toggle();
                if (panel.is(':visible')) { msgs.scrollTop(msgs[0].scrollHeight); input.focus(); }
            });
    });
})();
