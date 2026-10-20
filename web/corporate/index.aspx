<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SeeYourTravel.com Corporate Site - Your travel planning community
    </title>
    <meta content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no' name='viewport'>
    <link rel="stylesheet" href="../styles/jquery-ui.css" />
    <script src="../libs/jquery.js"></script>
    <script src="../libs/jquery-ui.js"></script>
    <script src="../libs/jquery.cookie.js"></script>
    <link rel="SHORTCUT ICON" href="favicon.ico">
    <link href="css/bootstrap.min.css" rel="stylesheet">
    <link href="css/style.css" rel="stylesheet">
    <link href="css/animate.min.css" rel="stylesheet">
    <link href="font-awesome-4.1.0/css/font-awesome.min.css" rel="stylesheet" type="text/css">
    <link rel="stylesheet" href="../styles/ourTravel.css" />
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
     <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
     <![endif]-->

    <script>
        (function (i, s, o, g, r, a, m) {
            i['GoogleAnalyticsObject'] = r; i[r] = i[r] || function () {
                (i[r].q = i[r].q || []).push(arguments)
            }, i[r].l = 1 * new Date(); a = s.createElement(o),
                m = s.getElementsByTagName(o)[0]; a.async = 1; a.src = g; m.parentNode.insertBefore(a, m)
        })(window, document, 'script', '//www.google-analytics.com/analytics.js', 'ga');

        ga('create', 'UA-66626682-1', 'auto');
        ga('send', 'pageview');
    </script>

    <script src="../libs/i18next.js"></script>
    <script src="../js/OurTravel.Common.js"></script>

    <!-- Start Alexa Certify Javascript -->
    <script type="text/javascript">
        _atrk_opts = { atrk_acct: "va3Jo1IWhe10mh", domain: "seeyourtravel.com", dynamic: true };
        (function () { var as = document.createElement('script'); as.type = 'text/javascript'; as.async = true; as.src = "https://d31qbv1cthcecs.cloudfront.net/atrk.js"; var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(as, s); })();
    </script>
    <noscript>
        <img src="https://d5nxst8fruw4z.cloudfront.net/atrk.gif?account=va3Jo1IWhe10mh" style="display: none" height="1" width="1" alt="" /></noscript>
    <!-- End Alexa Certify Javascript -->

    <script type="application/ld+json">
{
  "@context": "http://schema.org",
  "@type": "Organization",
  "url": "https://www.seeyourtravel.com/corporate",
  "contactPoint": [{
    "@type": "ContactPoint",
    "telephone": "+972-58-7786265",
    "contactType": "sales"
  }]
}
    </script>

</head>

<body>
    <script>
        $(function () {

            var sel = $("#langList");
            sel.empty();
            sel.append('<option value="en-US" >En</option>');
            sel.append('<option value="de-DE" >De</option>');
            sel.append('<option value="he" >עברית</option>');
            sel.append('<option value="uk-UA" >Укр</option>');

            var c = $.cookie("i18next");
            if (typeof c != "undefined" && c != null && c != "") {
                sel.val(c);
            }

            $.i18n.init({
                fallbackLng: "en",
                resGetPath: "../locales/__lng__/__ns__.json"
                , debug: true
                //,useLocalStorage: true | false
                //,localStorageExpirationTime: 60000000 // in ms, default 1 week
            },
                function () { if (typeof translateAll != "undefined") translateAll(); }
            );

        });

        function translateAll(err, t) {
            $(".i").i18n();
            $("option.i").i18n();
            $("#vengage-feedback-btn").text($.t("Feedback"));
        }

        var _vengage = _vengage || [];
        (function () {
            var a, b, c;
            a = function (f) {
                return function () {
                    _vengage.push([f].concat(Array.prototype.slice.call(arguments, 0)));
                };
            };
            b = ['load', 'addRule', 'addVariable', 'getURLParam', 'addRuleByParam', 'addVariableByParam', 'trackAction', 'submitFeedback', 'submitResponse', 'close', 'minimize', 'openModal', 'helpers'];
            for (c = 0; c < b.length; c++) {
                _vengage[b[c]] = a(b[c]);
            }
            var t = document.createElement('script'),
                s = document.getElementsByTagName('script')[0];
            t.async = true;
            t.src = ('https:' == document.location.protocol ? 'https' : 'http') + '://s3.amazonaws.com/vetrack/init.min.js';
            s.parentNode.insertBefore(t, s);
            _vengage.push(['pubkey', '4b55d135-83d5-47be-bd15-183b4b09bc21']);
        })();

    </script>

    <div style="position: fixed; right: 55px; top: -2px; z-index: 1003">
        <select id="langList" class="graySelect" onchange="selectLang()"></select>
    </div>

    <!-- PRELOADER STARTS HERE -->
    <div class="jasm-preloader"></div>
    <!-- /PRELOADER ENDS HERE-->
    <!-- HEADER STARTS HERE -->
    <header>
        <div class="container">

            <div class="wrapper">

                <!-- LOGO STARTS HERE -->
                <div class="row">
                    <div class="col-xs-12 jasm-logo" data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s">
                        <div class="i lj-text-center" style="color: white; font-size: 24px; align: center; text-shadow: 1px 1px #005BBB;" data-i18n="Demo">Try it now!</div>
                        <a href="https://seeyourtravel.com/" title="">
                            <img src="../img/See Your Travels-01.png" class="jasm-logo-1x" alt="">
                        </a>
                    </div>
                </div>
                <!-- /LOGO ENDS HERE -->
                <!-- TITLE STARTS HERE -->
                <div class="row">
                    <div class="col-xs-12 jasm-title" data-scroll-reveal="wait 0.5s, then enter left and move 40px over 1s" style="text-shadow: 1px 1px #005BBB;">
                        <h1 class="jasm-text-center"><a class="i" style="font-size: 52px; color: white" data-i18n="Corporate_SeeYourTravelCom" href="https://seeyourtravel.com">SeeYourTravel.com</a></h1>
                    </div>
                </div>
                <!-- /TITLE  ENDS HERE-->
                <!-- LINE STARTS HERE -->
                <div class="row">
                    <div class="col-xs-12 jasm-line" data-scroll-reveal="wait 0.75s, then enter right and move 40px over 1s">
                        <div></div>
                    </div>
                </div>
                <!-- /LINE -->
                <!-- TITLE PARAGRAPH STARTS HERE -->
                <div class="row">
                    <div class="col-xs-12 col-sm-8 col-sm-offset-2 jasm-title-paragraph" data-scroll-reveal="wait 1s, then enter right and move 40px over 1s">
                        <p class="i lj-text-center" style="text-shadow: 1px 1px #005BBB;" data-i18n="[html]Corporate_Text1">
                            Experience the travels yourself from past, today and future!
                            <br />
                            We are eager to be with you. Our site is coming in...
                        </p>
                    </div>
                </div>
                <!-- /TITLE PARAGRAPH ENDS HERE-->
                <!-- COUNTDOWN STARTS HERE-->
                <!--
		<div class="row">
                    <div class="col-sm-12 jasm-countdown" data-scroll-reveal="wait 1.25s, then enter bottom and move 40px over 1s">
                        <div class="row">

                        </div>
                    </div>
                </div>
		-->
                <!-- /COUNTDOWN ENDS HERE-->

            </div>

            <!-- SCROLL DOWN ARROW STARTS HERE -->
            <div class="jasm-scroll-down" data-scroll-reveal="wait 1.75s, then enter top and move 20px over 1s">
                <a href="#" title="">
                    <i class="fa fa-chevron-down"></i>
                </a>
            </div>
            <!-- /SCROLL DOWN ARROW ENDS HERE -->

        </div>

    </header>
    <!-- /HEADER ENDS HERE-->

    <section class='description jasm-s'>
        <div class='container'>
            <!-- COLUMNS STARTS HERE -->
            <div class="row">
                <div class="col-sm-4 jasm-icon-container">
                    <span data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s"><i class="fa fa-support"></i></span>
                    <h3 class="i jasm-text-uppercase" data-i18n="Corporate_Global">Global</h3>
                    <p class="i" data-i18n="Corporate_Global1">Global coverage with no extra effort</p>
                    <!--          <a href="#" title="">Read More</a>-->
                </div>

                <div class="col-sm-4 jasm-icon-container">
                    <span data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s"><i class="fa fa-cogs"></i></span>
                    <h3 class="i jasm-text-uppercase" data-i18n="Corporate_Configurable">Configurable</h3>
                    <p class="i" data-i18n="Corporate_Configurable1">Adjustable for your needs</p>
                    <!--          <a href="#" title="">Read More</a>-->
                </div>

                <div class="col-sm-4 jasm-icon-container">
                    <span data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s"><i class="fa fa-users"></i></span>
                    <h3 class="i jasm-text-uppercase" data-i18n="Corporate_Friendly">Friendly</h3>
                    <p class="i" data-i18n="Corporate_Friendly1">Easy to use and pleasant to come back</p>
                    <!--          <a href="#" title="">Read More</a>-->
                </div>
            </div>
            <!-- /COLUMNS -->
        </div>
    </section>
    <!-- DESCRIPTION SECTION ENDS  HERE -->

    <section class="recent-works jasm-s">
        <div class="container">
            <div class="jasm-text-center ">
                <h2 class="i" data-i18n="Corporate_YouCanSee">You can see with us</h2>
                <p class="i jasm-lead" data-i18n="Corporate_MoreToCore">More to come!</p>
            </div>

            <div class="row">
                <div class="col-xs-6 col-sm-3 col-md-3">
                    <div class="jasm-recent-work-wrap" data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s">
                        <img class="img-responsive" src="../img/norway1.jpg" alt="">
                        <div class="jasm-overlay">
                            <div class="jasm-recent-work-inner">
                                <h3><a href="#" class="i" data-i18n="Corporate_Norway">Beautiful Norway</a></h3>
                                <p class="i" data-i18n="Corporate_Norway1">Severe nature and open-heart people - paradise in the North</p>
                                <a href="#" rel="prettyPhoto"><i class="fa fa-eye"></i><span class="i" data-i18n="Corporate_View">View</span></a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-xs-6 col-sm-3 col-md-3">
                    <div class="jasm-recent-work-wrap" data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s">
                        <img class="img-responsive" src="../img/germany1.jpg" alt="">
                        <div class="jasm-overlay">
                            <div class="jasm-recent-work-inner">
                                <h3><a href="#" class="i" data-i18n="Corporate_Germany">Old good Germany</a></h3>
                                <p class="i" data-i18n="Corporate_Germany1">Quiet and relaxing, busy and inspiring - the real Germany</p>
                                <a href="#" rel="prettyPhoto"><i class="fa fa-eye"></i><span class="i" data-i18n="Corporate_View">View</span></a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-xs-6 col-sm-3 col-md-3">
                    <div class="jasm-recent-work-wrap" data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s">
                        <img class="img-responsive" src="../img/ukraine1.jpg" alt="">
                        <div class="jasm-overlay">
                            <div class="jasm-recent-work-inner">
                                <h3><a href="#" class="i" data-i18n="Corporate_Ukraine">Exciting Ukraine</a></h3>
                                <p class="i" data-i18n="Corporate_Ukraine1">Nature, people, food - all what you need to enjoy the life</p>
                                <a href="#" rel="prettyPhoto"><i class="fa fa-eye"></i><span class="i" data-i18n="Corporate_View">View</span></a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-xs-6 col-sm-3 col-md-3">
                    <div class="jasm-recent-work-wrap" data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s">
                        <img class="img-responsive" src="../img/italy1.jpg" alt="">
                        <div class="jasm-overlay">
                            <div class="jasm-recent-work-inner">
                                <h3><a href="#" class="i" data-i18n="Corporate_Italy">Hearty Italy</a></h3>
                                <p class="i" data-i18n="Corporate_Italy1">See yourself the beauty of Italian life and history</p>
                                <a href="#" rel="prettyPhoto"><i class="fa fa-eye"></i><span class="i" data-i18n="Corporate_View">View</span></a>
                            </div>
                        </div>
                    </div>
                </div>

                <div align="center">
                    <p>&nbsp;</p>
                    <iframe src="https://www.youtube.com/embed/2bSKNKqO2Uo" width="300" height="315" allowfullscreen style="align: center; display: block"></iframe>
                    <p>&nbsp;</p>
                    <div id="fb-root"></div>
                    <script>
                        (function (d, s, id) {
                            var js, fjs = d.getElementsByTagName(s)[0];
                            if (d.getElementById(id)) return;
                            js = d.createElement(s); js.id = id;
                            js.src = "//connect.facebook.net/en_US/sdk.js#xfbml=1&version=v2.4&appId=1401150776795735";
                            fjs.parentNode.insertBefore(js, fjs);
                        }(document, 'script', 'facebook-jssdk'));
                    </script>

                    <div class="fb-page" data-href="https://www.facebook.com/seeyourtravel" data-width="300" data-small-header="false" data-adapt-container-width="false" data-hide-cover="false" data-show-facepile="true" data-show-posts="false">
                        <div class="fb-xfbml-parse-ignore">
                            <blockquote cite="https://www.facebook.com/seeyourtravel"><a href="https://www.facebook.com/seeyourtravel">Seeyourtravel.com</a></blockquote>
                        </div>
                    </div>
                </div>
                <p>&nbsp;</p>
                <p align="center">
                    <a href="https://twitter.com/share" class="twitter-share-button" data-url="http://seeyourtravel.com/corporate" data-via="SeeYourTravel">Tweet</a>
                    <script>!function (d, s, id) { var js, fjs = d.getElementsByTagName(s)[0], p = /^http:/.test(d.location) ? 'http' : 'https'; if (!d.getElementById(id)) { js = d.createElement(s); js.id = id; js.src = p + '://platform.twitter.com/widgets.js'; fjs.parentNode.insertBefore(js, fjs); } }(document, 'script', 'twitter-wjs');</script>
<!--
                    &nbsp;
                    <script src="https://apis.google.com/js/platform.js" async defer></script>
-->
                </p>

            </div>
            <!--/.container-->
    </section>
    <!--/recent-works-->
    <!-- /SUBSCRIBE FORM -->
    </div>
    </div>
    </section>
    <!-- /SUBSCRIBE -->
    <!--CONTACTS-->
    <footer class="contact jasm-s">

        <div class="parallax-back" data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s">
            <div class="opcaity">
                <div class="w-container wrap">

                    <div class="jasm-text-center">
                        <h1 class="i underline" data-i18n="Corporate_GETINTOUCH">GET IN TOUCH</h1>
                        <p><span class="i" data-i18n="Corporate_FeelFree">Feel free to contact us at</span> <a href="mailto:info@seeyourtravel.com">info@seeyourtravel.com</a></p>
                        <div class="social-footter">
                            <a target="_blank" href="https://twitter.com/seeyourtravel"><i class="fa fa-2x fa-twitter"></i></a>
                            <a target="_blank" href="https://facebook.com/seeyourtravel"><i class="fa fa-2x fa-facebook"></i></a>
                            <a target="_blank" href="https://plus.google.com/u/0/b/111330135415627573371/dashboard/overview"><i class="fa fa-2x fa-google-plus"></i></a>
                            <a target="_blank" href="https://www.youtube.com/channel/UCfSj_WKVFx0DrI5qmhLjo_A"><i class="fa fa-2x fa-youtube"></i></a>
                        </div>

                        <!--div align="center">
                        <br/>
                        Our thanks to:
                        <br/>
                        <div style="background: #00578e url('http://www.jetbrains.com/img/banners/Codebetter.png') no-repeat 0 50%; margin:0;padding:0;text-decoration:none;text-indent:0;letter-spacing:-0.001em; width:728px; height:90px">
                        <a href="http://www.jetbrains.com/youtrack" title="YouTrack by JetBrains" style="margin: 60px 0 0 190px;padding: 0; float: left;font-size: 14px; background-image:none;border:0;color: #acc4f9; font-family: trebuchet ms,arial,sans-serif;font-weight: normal;text-align:left;">keyboard-centric bug tracker</a>
                        <a href="http://www.jetbrains.com/teamcity" title="TeamCity by JetBrains" style="margin:0 0 0 400px;padding:60px 0 2px 0;font-size:14px; background-image:none;border:0;display:block; color: #acc4f9; font-family: trebuchet ms,arial,sans-serif;font-weight: normal;text-align:left;">continuous integration server</a>
                        </div>
                        </div-->

                    </div>

                </div>
            </div>
        </div>

    </footer>
    <!--/CONTACTS-->

    <!--<script src="js/jquery.js"></script>-->
    <script src="js/bootstrap.min.js"></script>
    <script src="js/jquerybackstretch.js"></script>
    <script src="js/jquery_002.js"></script>
    <script src="js/scrollReveal.js"></script>
    <script src="js/jquery_003.js"></script>
    <script src="js/jquery_004.js"></script>
    <script src="js/jasm-template.js"></script>
    <script type='text/javascript'>
        function overImage(a, b) {
            $(a).hover(function () {
                $(this).find(b).css({ "opacity": 1, "-webkit-transform": "scale(1,1)", "-ms-transform": "scale(1,1)", "-moz-transform": "scale(1,1)", "transform": "scale(1,1)" });

            }, function () {
                $(this).find(b).css({ "opacity": 0, "-webkit-transform": "scale(0,0)", "-ms-transform": "scale(0,0)", "-moz-transform": "scale(0,0)", "transform": "scale(0,0)" });
            }
            )

        }
        $(document).ready(function () {

            overImage("div.jasm-recent-work-wrap", "div.jasm-overlay")

        }
        )

    </script>

    <script type="text/javascript">
        var clicky_site_ids = clicky_site_ids || [];
        clicky_site_ids.push(100870997);
        (function () {
            var s = document.createElement('script');
            s.type = 'text/javascript';
            s.async = true;
            s.src = '//static.getclicky.com/js';
            (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(s);
        })();

    </script>

<%--    <script type="text/javascript">
        window._urq = window._urq || [];
        _urq.push(['initSite', '74067c72-36c1-4bde-a189-72fdcd4f2a60']);
        (function () {
            var ur = document.createElement('script'); ur.type = 'text/javascript'; ur.async = true;
            ur.src = ('https:' == document.location.protocol ? 'https://cdn.userreport.com/userreport.js' : 'http://cdn.userreport.com/userreport.js');
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ur, s);
        })();
    </script>--%>

<script>(function (e, t, o, n) { var c, s, i; e.SMCX = e.SMCX || [], t.getElementById(n) || (c = t.getElementsByTagName(o), s = c[c.length - 1], i = t.createElement(o), i.type = "text/javascript", i.async = !0, i.id = n, i.src = ["https:" === location.protocol ? "https://" : "http://", "widget.surveymonkey.com/collect/website/js/iG52UUUrFEhnXq1bZxRqTZkORidoOUGeZeNO2TdT3XUZjpoiRI2Vya76NMc4B_2FHq.js"].join(""), s.parentNode.insertBefore(i, s)) })(window, document, "script", "smcx-sdk");</script>
</body>
</html>
