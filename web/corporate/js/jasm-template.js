/*
  Author:Vijayan PP
  Template: JASM-Coming Soon Website Template
  Version: 1.0
  */

(function($) {
  "use strict"; 
  
  $(document).ready(function (){
    'use strict';

    // E-mail validation via regular expression
    function isValidEmailAddress(emailAddress) {
      var pattern = new RegExp(/^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.?$/i);
      return pattern.test(emailAddress);
    };

    
    
    $('#subscribe').ajaxChimp({
      language: 'lj',
      url: 'http://www.your-plugin.co'//enter url here
    });

    

    $.ajaxChimp.translations.lj = {
      'submit': 'Submitting...',
      0: '<i class="fa fa-check"></i> We will be in touch soon!',
      1: '<i class="fa fa-warning"></i> You must enter a valid e-mail address.',
      2: '<i class="fa fa-warning"></i> E-mail address is not valid.',
      3: '<i class="fa fa-warning"></i> E-mail address is not valid.',
      4: '<i class="fa fa-warning"></i> E-mail address is not valid.',
      5: '<i class="fa fa-warning"></i> E-mail address is not valid.'
    }

    // Contact form functions
    

    
    $(".jasm-scroll-down").click(function(e) { 
      e.preventDefault();
      $('html,body').animate({
        scrollTop: $("header").nextAll('.jasm-s').offset().top},
        1250);           
    });

    // Countdown
    // To change date, simply edit: var Datetoend = "Nov 26, 2015 20:39:00";
    $(function() {
      var Datetoend = "Sept 28, 2015 00:00:00";
      $('.jasm-countdown .row').countdown({
        date: Datetoend,
        render: function (data) {
            var idays = $.t("idays");
            var ihours = $.t("ihours");
            var iminutes = $.t("iminutes");
            var iseconds = $.t("iseconds");
            $(this.el).html('<div><div><span>' + (parseInt(this.leadingZeros(data.years, 2) * 365) + parseInt(this.leadingZeros(data.days, 2))) + '</span><span>' + idays + '</span></div><div><span>' + this.leadingZeros(data.hours, 2) + '</span><span>' + ihours + '</span></div></div><div class="lj-countdown-ms"><div><span>' + this.leadingZeros(data.min, 2) + '</span><span>' + iminutes + '</span></div><div><span>' + this.leadingZeros(data.sec, 2) + '</span><span>' + iseconds + '</span></div></div>');
        }
      });
    });

    // backstretch
    $("header").backstretch("../img/IMG_7219.jpg");

    
    
    $(function () {
      var wrapper_height = $('.wrapper').height();
      var negative_margin = -(wrapper_height / 2);
      $('.wrapper').css({'marginTop':negative_margin+'px'});
    });
	
	function fscrolldown() {
    var header_h = $('header').height();
    var scrolldown = $('.jasm-scroll-down');

    if( header_h >= 650 )
	{
      scrolldown.show();
	  }
    else
      scrolldown.show();
  }


    
    fscrolldown();

    
    (function($) {
      window.scrollReveal = new scrollReveal();
    })();

    
    $(function () {
      $.stellar({
        horizontalScrolling: false
      });
    });

  
    
  });

  // Scroll down button show/hide function re-init on window resize
  $(window).on('resize', function(){
      fscrolldown();
  });

  // Preloader
  
  $(window).load(function() {
    $(".jasm-preloader").delay(100).fadeOut(600);
  });

})(jQuery);