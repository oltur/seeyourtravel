<%@ Page Title="Please login to start" Language="C#" MasterPageFile="MasterPage.master" CodeFile="Login.aspx.cs" Inherits="Login" %>

<%@ Import Namespace="System.IO" %>

<asp:Content ID="headContent" ContentPlaceHolderID="HeadPlaceholder" runat="Server">
    <script>
        var messageId = "<%=Message.ClientID%>";
        // This is called with the results from from FB.getLoginStatus().
        function statusChangeCallback(response) {
            //                debugger;
            console.log('statusChangeCallback');
            console.log(response);
            // The response object is returned with a status field that lets the
            // app know the current login status of the person.
            // Full docs on the response object can be found in the documentation
            // for FB.getLoginStatus().
            if (response.status === 'connected') {
                // Logged into your app and Facebook.
                document.getElementById("<%=Token.ClientID%>").value = response.authResponse.accessToken;
                    FB.api('/me', function (response2) {
                        document.getElementById("<%=Data.ClientID%>").value = JSON.stringify(response2);
                        document.getElementById("<%=LoginButton.ClientID%>").click();
                    });
                    //testAPI();
                } else if (response.status === 'not_authorized') {
                    // The person is logged into Facebook, but not your app.
                    //document.getElementById(messageId).innerHTML = 'Please log ' +
                    //  'into this app.';
                } else {
                    // The person is not logged into Facebook, so we're not sure if
                    // they are logged into this app or not.
                    //    document.getElementById(messageId).innerHTML = 'Please log ' +
                    //      'into Facebook.';
                }
            }

            // This function is called when someone finishes with the Login
            // Button.  See the onlogin handler attached to it in the sample
            // code below.
            function checkLoginState() {
                FB.getLoginStatus(function (response) {
                    statusChangeCallback(response);
                });
            }

            window.fbAsyncInit = function () {
                FB.init({
                    appId: '1475574289425791',
                    cookie: true,  // enable cookies to allow the server to access 
                    // the session
                    xfbml: true,  // parse social plugins on this page
                    version: 'v2.2' // use version 2.2
                });

                // Now that we've initialized the JavaScript SDK, we call 
                // FB.getLoginStatus().  This function gets the state of the
                // person visiting this page and can return one of three states to
                // the callback you provide.  They can be:
                //
                // 1. Logged into your app ('connected')
                // 2. Logged into Facebook, but not your app ('not_authorized')
                // 3. Not logged into Facebook and can't tell if they are logged into
                //    your app or not.
                //
                // These three cases are handled in the callback function.

                $(function () {
                    FB.getLoginStatus(function (response) {
                        statusChangeCallback(response);
                    });
                });

            };

            // Load the SDK asynchronously
            (function (d, s, id) {
                var js, fjs = d.getElementsByTagName(s)[0];
                if (d.getElementById(id)) return;
                js = d.createElement(s); js.id = id;
                js.src = "//connect.facebook.net/en_US/sdk.js";
                fjs.parentNode.insertBefore(js, fjs);
            }(document, 'script', 'facebook-jssdk'));

            // Here we run a very simple test of the Graph API after login is
            // successful.  See statusChangeCallback() for when this call is made.
            //function testAPI() {
            //    console.log('Welcome!  Fetching your information.... ');
            //    FB.api('/me', function (response) {
            //        console.log('Successful login for: ' + response.name);
            //        document.getElementById(messageId).innerHTML =
            //          'Thanks for logging in, ' + response.name + '!';
            //    });
            //}

            function translateAll(err, t) {
                $(".i").i18n();
                $("option.i").i18n();
            }

    </script>

    <style type="text/css">
        #loginform {
            width: 300px;
            height: 300px;
            position: absolute; /*it can be fixed too*/
            left: 0;
            right: 0;
            top: 0;
            bottom: 0;
            margin: auto;
            /*this to solve "the content will not be cut when the window is smaller than the content": */
            max-width: 100%;
            max-height: 100%;
            overflow: hidden;
        }
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
                <img src="img/SiteLogo.png" style="height: 50px; vertical-align: middle;" /></a>
        </span>
    <%--        <span style="position: absolute; right: 0;"><a href="#">
                <img src="img/help.png" style="height: 50px; width: 50px" alt="Need assistance?" onclick="$('#helpPanel').toggle('fold', 1000);" /></a>&nbsp;</span>
            <span style="position: absolute; left: 70px;"></span>--%>
    </div>
    <!-- #Include virtual="include/profileHelpPanel.inc" -->

    <div id="loginform" title="Login">

        <table>
            <tr>
                <td class="i" data-i18n="Username_">Username:
                </td>
                <td>
                    <asp:TextBox ID="UserName" runat="server" class="i glow" data-i18n></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td class="i glow" data-i18n="Password_">Password:
                </td>
                <td>
                    <asp:TextBox ID="Password" runat="server" TextMode="Password" class="i glow" data-i18n></asp:TextBox>
                </td>
            </tr>
            <tr>
                <td></td>
                <td>
                    <asp:CheckBox ID="RememberMe" class="glow" runat="server" />
                    <span class="i" data-i18n="RememberMe">Remember Me</span>
                    <asp:HiddenField ID="Token" runat="server" />
                    <asp:HiddenField ID="Data" runat="server" />
                </td>
            </tr>
            <tr>
                <td colspan="2" style="text-align:center">
                    <script>
                        var fbButtonHtml = '<fb:login-button data-size="xlarge" scope="public_profile,email" onlogin="checkLoginState();"></fb:login-button>';
                        if (!IS_ANDROID_WEBVIEW) {
                            document.writeln(fbButtonHtml);
                        }
                        else {
                            if (window.JSInterface && window.JSInterface.getFacebookToken) {
                                var token = window.JSInterface.getFacebookToken();
                                var info = window.JSInterface.getFacebookInfo();
                                if (info != "") {
                                    document.getElementById("<%=Token.ClientID%>").value = token;
                                    document.getElementById("<%=Data.ClientID%>").value = info;
                                    document.getElementById("<%=LoginButton.ClientID%>").click();
                                }
                            }
                        }
                    </script>
                    
                </td>
            </tr>
            <tr>
                <td colspan="2" style="text-align:center">
                    <asp:Button ID="LoginButton" Style="font-size: large" runat="server" Text="LoginWithPassword" OnClick="LoginButton_Click" class="i" data-i18n="[value]LoginWithPassword;" />
                </td>
                <td></td>
            </tr>
            <tr>
                <td colspan="2">
                    <asp:Label ID="Message" runat="server" ForeColor="Red" Text="" class="i" data-i18n></asp:Label>
                </td>
            </tr>
            <tr>
                <td colspan="2" style="text-align: center; padding-top: 30px;">
                    <asp:Button ID="DemoButton" runat="server" Text="Try it now!" OnClick="DemoButton_Click" style="width: 100px; height: 50px; font-size: large" class="i" data-i18n="[value]Demo;" />
                </td>
            </tr>
        </table>
    </div>
</asp:Content>
