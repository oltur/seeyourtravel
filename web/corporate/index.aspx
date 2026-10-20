<%@ Page Language="C#" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>SeeYourTravel.app – Your travel planning community</title>
    <meta content='width=device-width, initial-scale=1' name='viewport'>
    <link rel="stylesheet" href="../styles/jquery-ui.css" />
    <script src="../libs/jquery.js"></script>
    <script src="../libs/jquery-ui.js"></script>
    <script src="../libs/jquery.cookie.js"></script>
    <link rel="SHORTCUT ICON" href="favicon.ico">
    <link rel="icon" type="image/png" sizes="192x192" href="../img/syt-icon-192.png">
    <link rel="apple-touch-icon" href="../img/apple-touch-icon.png">
    <meta property="og:title" content="SeeYourTravel.app - your travel planning community">
    <meta property="og:image" content="https://seeyourtravel.app/img/og-image.png">
    <meta name="twitter:card" content="summary_large_image">
    <link href="css/bootstrap.min.css" rel="stylesheet">
    <link href="css/style.css" rel="stylesheet">
    <link href="css/animate.min.css" rel="stylesheet">
    <link href="font-awesome-4.1.0/css/font-awesome.min.css" rel="stylesheet" type="text/css">
    <link rel="stylesheet" href="../styles/ourTravel.css" />
    <link href="css/corporate-modern.css" rel="stylesheet">
    <link href="../styles/fonts.css" rel="stylesheet">
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
     <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
     <![endif]-->

    

    <script src="../libs/i18next.js"></script>
    <script src="../js/OurTravel.Common.js"></script>

    

    <script type="application/ld+json">
{
  "@context": "http://schema.org",
  "@type": "Organization",
  "url": "https://seeyourtravel.app/corporate",
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
            
        }

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
                        <a href="../index.aspx" title="SeeYourTravel">
                            <img src="../img/syt-logo-small.png" class="jasm-logo-1x" alt="">
                        </a>
                    </div>
                </div>
                <!-- /LOGO ENDS HERE -->
                <!-- TITLE STARTS HERE -->
                <div class="row">
                    <div class="col-xs-12 jasm-title" data-scroll-reveal="wait 0.5s, then enter left and move 40px over 1s" style="text-shadow: 1px 1px #005BBB;">
                        <h1 class="jasm-text-center"><a style="font-size: 52px; color: white" href="../index.aspx">SeeYourTravel.app</a></h1>
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
                        <p class="i jasm-text-center" style="text-shadow: 1px 1px #005BBB;" data-i18n="[html]Corporate_Text1">
                            Experience the travels yourself from past, today and future!
                            <br />
                            We are happy to be with you.
                        </p>
                    </div>
                </div>
                <!-- /TITLE PARAGRAPH ENDS HERE-->
                <div class="row">
                    <div class="col-xs-12 jasm-cta" data-scroll-reveal="wait 1.25s, then enter bottom and move 30px over 1s">
                        <a class="btn-open-app i" href="../index.aspx" data-i18n="Demo">Try it now</a>
                    </div>
                </div>
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

    <section class='description jasm-s' id='features'>
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
                                <h3><a href="../index.aspx?trackname=53ff70b3-5e38-4073-9326-cb535fa640ac" class="i" data-i18n="Corporate_Norway">Beautiful Norway</a></h3>
                                <p class="i" data-i18n="Corporate_Norway1">Severe nature and open-heart people - paradise in the North</p>
                                <a href="../index.aspx?trackname=53ff70b3-5e38-4073-9326-cb535fa640ac"><i class="fa fa-eye"></i><span class="i" data-i18n="Corporate_View">View</span></a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-xs-6 col-sm-3 col-md-3">
                    <div class="jasm-recent-work-wrap" data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s">
                        <img class="img-responsive" src="../img/germany1.jpg" alt="">
                        <div class="jasm-overlay">
                            <div class="jasm-recent-work-inner">
                                <h3><a href="../index.aspx?trackname=39574bc3-c43b-4736-b122-dd9d69e3d31a" class="i" data-i18n="Corporate_Germany">Old good Germany</a></h3>
                                <p class="i" data-i18n="Corporate_Germany1">Quiet and relaxing, busy and inspiring - the real Germany</p>
                                <a href="../index.aspx?trackname=39574bc3-c43b-4736-b122-dd9d69e3d31a"><i class="fa fa-eye"></i><span class="i" data-i18n="Corporate_View">View</span></a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-xs-6 col-sm-3 col-md-3">
                    <div class="jasm-recent-work-wrap" data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s">
                        <img class="img-responsive" src="../img/ukraine1.jpg" alt="">
                        <div class="jasm-overlay">
                            <div class="jasm-recent-work-inner">
                                <h3><a href="../index.aspx?trackname=Ukraine-Kyiv-Pechersk" class="i" data-i18n="Corporate_Ukraine">Exciting Ukraine</a></h3>
                                <p class="i" data-i18n="Corporate_Ukraine1">Nature, people, food - all what you need to enjoy the life</p>
                                <a href="../index.aspx?trackname=Ukraine-Kyiv-Pechersk"><i class="fa fa-eye"></i><span class="i" data-i18n="Corporate_View">View</span></a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-xs-6 col-sm-3 col-md-3">
                    <div class="jasm-recent-work-wrap" data-scroll-reveal="wait 0.25s, then enter top and move 40px over 1s">
                        <img class="img-responsive" src="../img/italy1.jpg" alt="">
                        <div class="jasm-overlay">
                            <div class="jasm-recent-work-inner">
                                <h3><a href="../index.aspx?trackname=Italy-Pompei-Vesuvius" class="i" data-i18n="Corporate_Italy">Hearty Italy</a></h3>
                                <p class="i" data-i18n="Corporate_Italy1">See yourself the beauty of Italian life and history</p>
                                <a href="../index.aspx?trackname=Italy-Pompei-Vesuvius"><i class="fa fa-eye"></i><span class="i" data-i18n="Corporate_View">View</span></a>
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
                            <blockquote cite="https://www.facebook.com/seeyourtravel"><a href="https://www.facebook.com/seeyourtravel">Seeyourtravel.app</a></blockquote>
                        </div>
                    </div>
                </div>
                <p>&nbsp;</p>
                <p align="center">
                    <a href="https://twitter.com/share" class="twitter-share-button" data-url="https://seeyourtravel.app/corporate" data-via="SeeYourTravel">Tweet</a>
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
                        <p><span class="i" data-i18n="Corporate_FeelFree">Feel free to contact us at</span> <a href="mailto:info@seeyourtravel.app">info@seeyourtravel.app</a></p>
                        <div class="social-footter">
                            <a target="_blank" href="https://twitter.com/seeyourtravel"><i class="fa fa-2x fa-twitter"></i></a>
                            <a target="_blank" href="https://facebook.com/seeyourtravel"><i class="fa fa-2x fa-facebook"></i></a>
                            <a target="_blank" href="https://www.youtube.com/channel/UCfSj_WKVFx0DrI5qmhLjo_A"><i class="fa fa-2x fa-youtube"></i></a>
                        </div>

                        <!-- (removed: commented-out sponsor banner) -->

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

    




</body>
</html>
