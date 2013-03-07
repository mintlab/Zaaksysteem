
var isplaying = true;
function show_controls() {
	var T = '    ';
	var output = '';

	output += T+T+'<div id="carrousel_controls">'+"\n";
	output += T+T+T+'<div id="carrousel_start_stop">'+"\n";
    output += T+T+T+T+'<a id="btn_stop" class="btn_stopstart_carrousel" title="Druk op de spatiebalk om de animatie stoppen."><img src="templates/images/portal/carrousel_pauze.png" alt="Stop"></a>'+"\n";
    output += T+T+T+T+'<a id="btn_start" class="btn_stopstart_carrousel" title="Druk op de spatiebalk om de animatie starten."><img src="templates/images/portal/carrousel_start.png" alt="Start"></a>'+"\n";
    output += T+T+T+'</div>'+"\n";
	output += T+T+T+'<div id="carrousel_pager"></div>'+"\n";
	output += T+T+T+'</div>'+"\n";
	document.write(output);
}

var stop = function() {
    isplaying = false;
    jQuery('div#carrousel').cycle('pause');
    jQuery('div#carrousel_controls a#btn_stop').hide();
    jQuery('div#carrousel_controls a#btn_start').show();
}

var start = function() {
    isplaying = true;
    jQuery('div#carrousel').cycle('resume');
    jQuery('div#carrousel_controls a#btn_start').hide();
    jQuery('div#carrousel_controls a#btn_stop').show();
}

jQuery(window).load(function() {
    jQuery('div#carrousel').cycle({
        fx:         'fade',
        speed:      'slow',
        timeout:    6000,
        pager:      '#carrousel_pager'
    });
    
    jQuery('div#carrousel_controls a#btn_start').hide();
    
    jQuery('div#carrousel_controls a#btn_stop').click(stop);  
    jQuery('div#carrousel_controls a#btn_start').click(start);

    var focusflag = false;
    jQuery("input, textarea").focus(function() {
        focusflag = true;
    });

    jQuery("input, textarea").blur(function() {
        focusflag = false;
    });

    jQuery(document).keypress(function(e) {
        if (e.which == 32 && focusflag === false) {
            e.preventDefault();
            (isplaying === true) ? stop() : start();
        }
    });

});