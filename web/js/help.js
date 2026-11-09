// Short, targeted help: a sheet with a few topics (bottom sheet on a phone, card on a computer). Opened from the "?" button, the
// menu, the "?" key or #help in the address; sytHelp.open('3d') opens one topic. Texts are in the four site languages.
(function () {
    var LANGS = {
        en: {
            title: 'Help', menu: 'Help', close: 'Close', tour: 'Take the tour', mail: 'Questions',
            topics: [
                ['start', 'Getting started', 'Choose a track in the list at the top left. The journey replays on the map: the vehicle moves, and photos and places appear along the way. Tap the play/pause button (or press Space) to pause.'],
                ['controls', 'Controls', 'On the right: sound, play/pause, restart, 3D and fullscreen. The bar at the bottom shows where you are on the route: drag it to jump to any point. The speed is in Settings.'],
                ['photos', 'Photos and places', 'The strip at the bottom shows photos near the vehicle; tap one to enlarge it. Round markers are places from Wikipedia and other users, and weather. Tap a marker for details. The Photos button hides the strip.'],
                ['3d', '3D flight', 'Press the cube button to fly along the route over a 3D map with buildings and hills. Photos fly past on both sides. Use + and − or pinch to change the scale. Settings has the 3D map style and options. Press the cube again to go back.'],
                ['ai', 'Search and assistant', 'In the menu, search for a place or describe what you want to see, for example “castles in Scotland”. The chat bubble at the bottom right answers questions about your tracks and photos.'],
                ['create', 'Your own tracks', 'Sign in with Google, then open the menu: New, Record route or Edit. Your photos stay private, and a track is shown to others only if you make it public.'],
                ['phone', 'On a phone', 'Turn the phone sideways for a wider map. Use the fullscreen button, or on an iPhone choose Share → Add to Home Screen to open the site without browser bars.'],
                ['privacy', 'Privacy and contact', 'No ads and no tracking cookies. The privacy policy, terms and imprint are in the menu.']
            ]
        },
        de: {
            title: 'Hilfe', menu: 'Hilfe', close: 'Schließen', tour: 'Rundgang starten', mail: 'Fragen',
            topics: [
                ['start', 'Erste Schritte', 'Wähle oben links eine Route aus der Liste. Die Reise läuft auf der Karte ab: Das Fahrzeug bewegt sich, Fotos und Orte erscheinen unterwegs. Mit der Play-/Pause-Taste (oder der Leertaste) hältst du an.'],
                ['controls', 'Bedienung', 'Rechts: Ton, Play/Pause, Neustart, 3D und Vollbild. Die Leiste unten zeigt, wo du auf der Route bist: Zieh sie, um an eine beliebige Stelle zu springen. Die Geschwindigkeit stellst du in den Einstellungen ein.'],
                ['photos', 'Fotos und Orte', 'Der Streifen unten zeigt Fotos in der Nähe des Fahrzeugs; tippe auf eines, um es zu vergrößern. Runde Markierungen sind Orte aus Wikipedia und von anderen Nutzern sowie das Wetter. Tippe auf eine Markierung für Details. Mit der Taste „Fotos“ blendest du den Streifen aus.'],
                ['3d', '3D-Flug', 'Mit dem Würfel-Knopf fliegst du über einer 3D-Karte mit Gebäuden und Hügeln entlang der Route. Fotos fliegen links und rechts vorbei. Mit + und − oder per Zwei-Finger-Geste änderst du den Maßstab. In den Einstellungen findest du den 3D-Kartenstil und weitere Optionen. Der Würfel bringt dich zurück.'],
                ['ai', 'Suche und Assistent', 'Im Menü suchst du einen Ort oder beschreibst, was du sehen möchtest, zum Beispiel „Burgen in Schottland“. Die Sprechblase unten rechts beantwortet Fragen zu deinen Routen und Fotos.'],
                ['create', 'Eigene Routen', 'Melde dich mit Google an und öffne dann das Menü: Neu, Route aufzeichnen oder Bearbeiten. Deine Fotos bleiben privat, und eine Route sehen andere nur, wenn du sie öffentlich machst.'],
                ['phone', 'Am Smartphone', 'Dreh das Smartphone quer für eine breitere Karte. Nutze den Vollbild-Knopf, oder wähle am iPhone Teilen → Zum Home-Bildschirm, um die Seite ohne Browserleisten zu öffnen.'],
                ['privacy', 'Datenschutz und Kontakt', 'Keine Werbung und keine Tracking-Cookies. Datenschutzerklärung, Nutzungsbedingungen und Impressum findest du im Menü.']
            ]
        },
        uk: {
            title: 'Довідка', menu: 'Довідка', close: 'Закрити', tour: 'Пройти екскурсію', mail: 'Питання',
            topics: [
                ['start', 'З чого почати', 'Оберіть маршрут у списку вгорі ліворуч. Подорож відтворюється на мапі: рухається транспорт, дорогою з’являються фото та місця. Натисніть кнопку «пауза/відтворення» (або пробіл), щоб зупинити.'],
                ['controls', 'Керування', 'Праворуч: звук, пауза/відтворення, початок спочатку, 3D і повний екран. Смуга внизу показує, де ви на маршруті: потягніть її, щоб перейти в будь-яке місце. Швидкість налаштовується в «Налаштуваннях».'],
                ['photos', 'Фото та місця', 'Стрічка внизу показує фото поблизу транспорту; торкніться фото, щоб збільшити. Круглі позначки — це місця з Вікіпедії та від інших користувачів, а також погода. Торкніться позначки, щоб побачити подробиці. Кнопка «Фото» ховає стрічку.'],
                ['3d', '3D-політ', 'Натисніть кнопку з кубом, щоб летіти вздовж маршруту над 3D-мапою з будівлями й пагорбами. Фото пролітають з обох боків. Кнопки + та − або жест двома пальцями змінюють масштаб. У «Налаштуваннях» є стиль 3D-мапи та інші опції. Натисніть куб ще раз, щоб повернутися.'],
                ['ai', 'Пошук і помічник', 'У меню шукайте місце або опишіть, що хочете побачити, наприклад «замки в Шотландії». Хмаринка чату внизу праворуч відповідає на питання про ваші маршрути й фото.'],
                ['create', 'Власні маршрути', 'Увійдіть через Google і відкрийте меню: «Новий», «Записати маршрут» або «Редагувати». Ваші фото залишаються приватними, а маршрут бачать інші лише тоді, коли ви зробите його публічним.'],
                ['phone', 'На телефоні', 'Поверніть телефон набік для ширшої мапи. Скористайтеся кнопкою повного екрана, а на iPhone оберіть «Поділитися» → «На початковий екран», щоб відкривати сайт без панелей браузера.'],
                ['privacy', 'Конфіденційність і контакти', 'Без реклами й без cookie для стеження. Політику конфіденційності, умови та вихідні дані можна знайти в меню.']
            ]
        },
        he: {
            title: 'עזרה', menu: 'עזרה', close: 'סגירה', tour: 'סיור קצר', mail: 'שאלות',
            topics: [
                ['start', 'איך מתחילים', 'בחרו מסלול ברשימה בפינה השמאלית העליונה. המסע מוצג על המפה: הרכב נע, ותמונות ומקומות מופיעים לאורך הדרך. לחצו על כפתור ההשמעה/השהיה (או על רווח) כדי לעצור.'],
                ['controls', 'בקרה', 'מימין: צליל, השמעה/השהיה, התחלה מחדש, תלת־ממד ומסך מלא. הפס בתחתית מראה איפה אתם במסלול: גררו אותו כדי לקפוץ לכל נקודה. את המהירות קובעים בהגדרות.'],
                ['photos', 'תמונות ומקומות', 'הרצועה בתחתית מציגה תמונות ליד הרכב; הקישו על תמונה כדי להגדיל. סמנים עגולים הם מקומות מוויקיפדיה ומשתמשים אחרים, וגם מזג אוויר. הקישו על סמן לפרטים. כפתור „תמונות” מסתיר את הרצועה.'],
                ['3d', 'טיסה בתלת־ממד', 'לחצו על כפתור הקובייה כדי לטוס לאורך המסלול מעל מפה תלת־ממדית עם בניינים וגבעות. תמונות חולפות משני הצדדים. כפתורי + ו־− או צביטה בשתי אצבעות משנים את קנה המידה. בהגדרות יש סגנון מפה תלת־ממדי ואפשרויות נוספות. לחצו שוב על הקובייה כדי לחזור.'],
                ['ai', 'חיפוש ועוזר', 'בתפריט אפשר לחפש מקום או לתאר מה רוצים לראות, למשל „טירות בסקוטלנד”. בועת הצ׳אט בפינה הימנית התחתונה עונה על שאלות על המסלולים והתמונות שלכם.'],
                ['create', 'מסלולים משלכם', 'התחברו עם Google ופתחו את התפריט: חדש, הקלטת מסלול או עריכה. התמונות שלכם נשארות פרטיות, ומסלול מוצג לאחרים רק אם הפכתם אותו לציבורי.'],
                ['phone', 'בטלפון', 'סובבו את הטלפון לרוחב למפה רחבה יותר. השתמשו בכפתור המסך המלא, ובאייפון בחרו שיתוף ← הוספה למסך הבית כדי לפתוח את האתר בלי סרגלי הדפדפן.'],
                ['privacy', 'פרטיות ויצירת קשר', 'בלי פרסומות ובלי עוגיות מעקב. מדיניות הפרטיות, תנאי השימוש ופרטי הספק נמצאים בתפריט.']
            ]
        }
    };
    var MAP = { 'en-US': 'en', 'de-DE': 'de', 'uk-UA': 'uk', 'he': 'he' };
    function lang() {
        var m = document.cookie.match(/(?:^|; )i18next=([^;]*)/), c = m ? MAP[decodeURIComponent(m[1])] : null;
        if (c) return c;
        var n = (navigator.language || 'en').slice(0, 2).toLowerCase(); if (n === 'iw') n = 'he';
        return LANGS[n] ? n : 'en';
    }
    var TOUR = {"en": {}, "de": {"restart": "Route von vorn starten", "d3": "3D-Flug: durch die Route fliegen, mit Gebäuden, Hügeln, Fotos und Wetter", "fs": "Vollbild an und aus", "help": "Hilfe: kurze Antworten und dieser Rundgang", "seek": "Ziehen, um zu einer beliebigen Stelle der Route zu springen"}, "uk": {"restart": "Почати маршрут спочатку", "d3": "3D-політ: пролетіть маршрутом з будівлями, пагорбами, фото та погодою", "fs": "Повноекранний режим увімк./вимк.", "help": "Довідка: короткі відповіді та ця екскурсія", "seek": "Перетягніть, щоб перейти до будь-якого місця маршруту"}, "he": {"restart": "התחלת המסלול מחדש", "d3": "טיסת תלת־ממד: טוסו לאורך המסלול עם מבנים, גבעות, תמונות ומזג אוויר", "fs": "מסך מלא פעיל/כבוי", "help": "עזרה: תשובות קצרות והסיור הזה", "seek": "גררו כדי לקפוץ לכל נקודה במסלול"}};
    window.sytTourMsg = function (k, en) { var t = TOUR[lang()]; return (t && t[k]) || en; };
    var $ov = null, lastFocus = null;
    function build(l, topic) {
        var L = LANGS[l], $o = $('<div id="sytHelp" role="dialog" aria-modal="true"></div>').attr({ lang: l, dir: l === 'he' ? 'rtl' : 'ltr', 'aria-label': L.title });
        var $s = $('<div class="hSheet"></div>').appendTo($o);
        $('<div class="hBar"></div>').append($('<b></b>').text(L.title), $('<button type="button" class="hX"></button>').attr('aria-label', L.close).html('&times;')).appendTo($s);
        var $b = $('<div class="hBody"></div>').appendTo($s);
        L.topics.forEach(function (t) {
            var $d = $('<details></details>').attr('data-t', t[0]);
            $('<summary></summary>').text(t[1]).appendTo($d);
            $('<p></p>').text(t[2]).appendTo($d);
            if (topic ? t[0] === topic : t[0] === 'start') $d.attr('open', '');
            $b.append($d);
        });
        var $f = $('<div class="hFoot"></div>').appendTo($s);
        $('<button type="button" class="hTour"></button>').text(L.tour).on('click', function () { close(); if (window.jQuery && jQuery.tour && window.tourSteps) jQuery.tour(tourSteps); }).appendTo($f);
        $('<a></a>').attr('href', 'mailto:info@seeyourtravel.app').text(L.mail + ': info@seeyourtravel.app').appendTo($f);
        $o.on('click', function (e) { if (e.target === this) close(); });
        $o.find('.hX').on('click', close);
        // one topic open at a time
        $b.find('details').on('toggle', function () { var me = this; if (me.open) $b.find('details').each(function () { if (this !== me) this.removeAttribute('open'); }); });
        return $o;
    }
    function open(topic) {
        if ($ov) close();
        lastFocus = document.activeElement;
        $ov = build(lang(), topic).appendTo('body');
        $('body').addClass('sytHelpOpen');
        setTimeout(function () { if ($ov) { $ov.addClass('on'); $ov.find('.hX').trigger('focus'); var d = $ov.find('details[open]')[0]; if (d && d.scrollIntoView) d.scrollIntoView({ block: 'nearest' }); } }, 10);
        try { if (!(window.sytImmersive && sytImmersive.isOn())) history.replaceState(null, '', location.pathname + location.search + '#help' + (topic ? '-' + topic : '')); } catch (e) { }
    }
    function close() {
        if (!$ov) return;
        var $o = $ov; $ov = null;
        $('body').removeClass('sytHelpOpen');
        $o.removeClass('on'); setTimeout(function () { $o.remove(); }, 180);
        try { if (/^#help/.test(location.hash)) history.replaceState(null, '', location.pathname + location.search); } catch (e) { }
        if (window.sytImmersive && sytImmersive.isOn() && sytImmersive.refreshHash) sytImmersive.refreshHash();
        if (lastFocus && lastFocus.focus) try { lastFocus.focus(); } catch (e) { }
    }
    window.sytHelp = { open: open, close: close, isOpen: function () { return !!$ov; } };

    $(function () {
        var l = lang();
        $('#menuHelp').text(LANGS[l].menu);
        $('#helpButton').attr({ title: LANGS[l].title, 'aria-label': LANGS[l].title });
        // Esc closes the help first (capture phase, before other handlers act on the same key)
        document.addEventListener('keydown', function (e) {
            if ($ov && e.key === 'Escape') { e.stopPropagation(); close(); return; }
            if (e.key === '?' && !/^(input|textarea|select)$/i.test((e.target.tagName || '')) && !e.target.isContentEditable) { e.preventDefault(); $ov ? close() : open(); }
        }, true);
        var m = /^#help(?:-(\w+))?$/.exec(location.hash || '');
        if (m) setTimeout(function () { open(m[1]); }, 600);
    });
})();
