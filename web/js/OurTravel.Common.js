function isPortrait() {
    var w = window.innerWidth;
    var h = window.innerHeight;
    return w < h;
}

function getScreenWidth() {
    return window.innerWidth;
}

function getScreenHeight() {
    return window.innerHeight;
}

function getIsMobile() {
    return Math.min(getScreenWidth(), getScreenHeight()) < 450;
}

function shuffle(array) {
    var currentIndex = array.length, temporaryValue, randomIndex;

    // While there remain elements to shuffle...
    while (0 !== currentIndex) {

        // Pick a remaining element...
        randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex -= 1;

        // And swap it with the current element.
        temporaryValue = array[currentIndex];
        array[currentIndex] = array[randomIndex];
        array[randomIndex] = temporaryValue;
    }

    return array;
}

function selectLang() {
    var val = getLanguage();
    $.i18n.setLng(val, function () { if (typeof translateAll != "undefined") translateAll(); });
    location.reload();
}

function getLanguage() {
    var sel = $("#langList");
    return sel.val();
}

function getFacebookLanguage() {
    var result;

    var sel = $("#langList");
    if (sel && sel.val())
        result = sel.val();
    else if ($.cookie("i18next"))
        result = $.cookie("i18next");
    else
        result = "en_US";

    if (result == "he")
        result = "he_IL";
    else result = result.replace("-", "_");

    return result;
}

function getTwitterLanguage() {
    var result = getFacebookLanguage();

    return result.substring(0, 2);
}

function isNullOrEmpty(s) {
    return s == null || s == "" || typeof s == "undefined"
}

String.prototype.format = function (args) {
    var str = this;
    return str.replace(String.prototype.format.regex, function (item) {
        var intVal = parseInt(item.substring(1, item.length - 1));
        var replace;
        if (intVal >= 0) {
            replace = args[intVal];
        } else if (intVal === -1) {
            replace = "{";
        } else if (intVal === -2) {
            replace = "}";
        } else {
            replace = "";
        }
        return replace;
    });
};

String.prototype.format.regex = new RegExp("{-?[0-9]+}", "g");

jQuery(function ($) {

    var _oldShow = $.fn.show;

    $.fn.show = function (speed, oldCallback) {
        return $(this).each(function () {
            var obj = $(this),
                newCallback = function () {
                    if ($.isFunction(oldCallback)) {
                        oldCallback.apply(obj);
                    }
                    obj.trigger('afterShow');
                };

            // you can trigger a before show if you want
            obj.trigger('beforeShow');

            // now use the old function to show the element passing the new callback
            _oldShow.apply(obj, [speed, newCallback]);
        });
    }
});