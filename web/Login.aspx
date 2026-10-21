<%@ Page Title="Sign in" Language="C#" MasterPageFile="MasterPage.master" CodeFile="Login.aspx.cs" Inherits="Login" %>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadPlaceholder" runat="Server">
    <script src="https://accounts.google.com/gsi/client" async defer></script>
    <script>
        var returnUrl = "<%= HttpUtility.JavaScriptStringEncode(ReturnUrl) %>";

        function onGoogleCredential(response) {
            $("#loginMessage").text(T("SigningIn", "Signing in…"));
            $.post("google_login.ashx", { credential: response.credential })
                .done(function () { window.location = returnUrl; })
                .fail(function (xhr) {
                    var msg = T("SignInFailed", "Sign-in failed");
                    try { msg = JSON.parse(xhr.responseText).error || msg; } catch (e) { }
                    $("#loginMessage").text(msg);
                });
        }

        window.onload = function () {
            var tries = 0;
            (function init() {
                if (window.google && google.accounts && google.accounts.id) {
                    google.accounts.id.initialize({ client_id: "<%= HttpUtility.JavaScriptStringEncode(Tools.GoogleClientId) %>", callback: onGoogleCredential });
                    google.accounts.id.renderButton(document.getElementById("googleButton"), { theme: "outline", size: "large", shape: "pill", text: "signin_with" });
                } else if (tries++ < 50) setTimeout(init, 200);
                else $("#loginMessage").text(T("GoogleLoadError", "Could not load Google sign-in. Check your connection."));
            })();
        };

        function translateAll(err, t) {
            $(".i").i18n();
            $("option.i").i18n();
        }
    </script>
    <style type="text/css">
        #loginform {
            position: absolute; left: 0; right: 0; top: 0; bottom: 0; margin: auto;
            width: 340px; height: 300px; max-width: 100%;
            background: rgba(255, 255, 255, 0.92); border-radius: 16px; padding: 28px 24px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, .35); text-align: center;
        }
        #loginform h2 { margin: 0 0 6px; }
        #googleButton { display: flex; justify-content: center; margin: 22px 0 10px; min-height: 44px; }
        #loginMessage { color: #b00020; min-height: 1.4em; }
    </style>
</asp:Content>

<asp:Content ID="bodyContent" ContentPlaceHolderID="BodyPlaceholder" runat="Server">
    <script>
        document.body.style.backgroundImage = "url('img/PipIvanDimmed.jpg')";
    </script>
    <div class="langButton">
        <select style="" id="langList" class="graySelect" onchange="selectLang()"></select>
    </div>
    <div class="mapheader">
        <span style="position: absolute; left: 0;">
            <a href="./corporate" target="_blank">
                <img src="img/syt-logo-small.png" style="height: 50px; vertical-align: middle;" /></a>
        </span>
    </div>

    <div id="loginform" title="Sign in">
        <img src="img/syt-logo-small.png" style="height: 60px;" alt="SeeYourTravel" />
        <h2 class="i" data-i18n="SignIn">Sign in</h2>
        <div class="i" data-i18n="SignInSub">to create and manage your travels</div>
        <div id="googleButton"></div>
        <div id="loginMessage"></div>
        <p style="margin-top: 18px"><a href="index.aspx" class="i" data-i18n="ContinueGuest">Continue as guest</a></p>
    </div>
</asp:Content>
