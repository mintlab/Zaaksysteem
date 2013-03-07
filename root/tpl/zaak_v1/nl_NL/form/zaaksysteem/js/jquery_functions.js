

// Put all your code in your document ready area
jQuery(document).ready(function($){
	show = 0;
	
	// print function
	$('div#tools').append('<div class="print"><a href="#print">Print</a></div>');
 	$('div#tools div.print a').click(function()  {
  		window.print();
  		return false;
 	});
 	
// Dropdown language 
$('#language li:not(.current)').hide();
	$('#language .current').click(function(){
		$('#language li:not(.current)').slideToggle(50);
});

// Dropdown subsites	
$('#subsite li:not(.current)').hide();
var handlerIn = function(){
		$('#subsite li:not(.current)').slideToggle(50);
}
var handlerOut = function(){
		$('#subsite li:not(.current)').delay(1200).slideToggle(50);
}
	$('#subsite .current').hover(handlerIn, handlerOut);
	
 	
// Uitgecomment MW 071010
/*	
	// top-navigation menu foldout
	$('#nav-top').hover(function() {
		show = 1;
		$('#nav-top .sub-desc').stop().clearQueue().show();
		$(this).clearQueue().animate({height: 113, top: 158}, 400);
		$('#nav-top .menu li a').clearQueue().animate({height:115}, 380, function() {
			show = 0;
		});
	}, function() {
		$('#nav-top .menu li a').stop().clearQueue().delay(500).animate({height:34}, 420);
		$(this).stop().clearQueue().delay(500).animate({top: 239, height: 32}, 400, function() {
			if(show == 0) {
				$('#nav-top .sub-desc').hide();
			}
		});
	});
*/

	// PDC tab functionality
	$('.tabcontainer .tablink').click(function(event) {
		$('.tabcontainer ul.tabnav li').each(function() {
			$(this).removeClass('tabactive');
		});
		$(this).parent().addClass('tabactive');
		// hide all content
		$('.tabcontainer .tabcontent').hide();
		// show active
		var target = event.target.toString();
		target = target.split('#');
		$('#' + target[1]).fadeIn();
		event.preventDefault();
	});
	$('.tabcontents').css('height', 'auto');
	// hide all
	$('.tabcontainer .tabcontent').hide();
	// check if a tab should be activated 
	href = window.location.href.toString();
	target = href.split('#');
	if(target[1] == undefined || target[1] == '') {
		// show first, default
		$('.tabcontainer .tabcontent:first').show();
		$('.tabcontainer .tabnav li:first').addClass('tabactive');
	} else {
		$('#' + target[1]).show();
		$('.tabcontainer ul.tabnav a').each(function() {
			if($(this).attr('href').indexOf('#' + target[1]) >0) {
				$(this).parent().addClass('tabactive');
			}
		});
	}
	
	// Styleswitch
        $('.styleswitch').click(function()
        {
            switchStylestyle(this.getAttribute("rel"));
            return false;
        });
        var c = readCookie('style');
        if (c) switchStylestyle(c);
        
        function switchStylestyle(styleName)
    	{
        	$('link[rel*=style][title]').each(function(i) 
        	{
            	this.disabled = true;
            	if (this.getAttribute('title') == styleName) this.disabled = false;
        	});
       	createCookie('style', styleName, 365);
    	}
	
	// cookie functions http://www.quirksmode.org/js/cookies.html
	function createCookie(name,value,days)
	{
    		if (days)
    		{
        		var date = new Date();
        		date.setTime(date.getTime()+(days*24*60*60*1000));
        		var expires = "; expires="+date.toGMTString();
    		}
    		else var expires = "";
    		document.cookie = name+"="+value+expires+"; path=/";
	}
	function readCookie(name)
	{
    	var nameEQ = name + "=";
    	var ca = document.cookie.split(';');
    	for(var i=0;i < ca.length;i++)
    	{
        	var c = ca[i];
        	while (c.charAt(0)==' ') c = c.substring(1,c.length);
        	if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    	}
    	return null;
	}
	function eraseCookie(name)
	{
    	createCookie(name,"",-1);
	}	
	
});
