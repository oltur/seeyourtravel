function initFacebook() {
    window.fbAsyncInit = function () {
        FB.init({
            appId: '1475574289425791',
            xfbml: true,
            version: 'v2.4'
        });

        FB.Event.subscribe('xfbml.render', function (response) {
            facebookAPIIsLoaded = true;
        });
    };


    (function (d, s, id) {
        var js, fjs = d.getElementsByTagName(s)[0];
        if (d.getElementById(id)) { return; }
        js = d.createElement(s); js.id = id;
        js.src = "//connect.facebook.net/" + globalFacebookLanguage + "/sdk.js";
        fjs.parentNode.insertBefore(js, fjs);
    }(document, 'script', 'facebook-jssdk'));

}

function fblogout() {
    //    debugger;
    if (typeof FB === "undefined") {
        setTimeout(function () { fblogout(); }, 300); // Retry after timeout
        return false;
    } else {
        try {
            FB.getLoginStatus(function (response) {
                if (response.status != "unknown") {
                    try {
                        FB.logout(function (response) {
                            window.location = "login.aspx?ReturnURL=" + returnURL;
                        });
                    }
                    catch (err) {
                        window.location = "login.aspx?ReturnURL=" + returnURL;
                    }
                }
                else {
                    window.location = "login.aspx?ReturnURL=" + returnURL;
                }
            });
        }
        catch (err) {
            window.location = "login.aspx";
        }
    }
}