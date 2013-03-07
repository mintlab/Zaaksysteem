/*	
 *	jQuery carouFredSel 1.3.3
 *	www.frebsite.nl
 *	Copyright (c) 2010 Fred Heusschen
 *	Licensed under the MIT license.
 *	http://www.opensource.org/licenses/mit-license.php
 */


(function($) {
	$.fn.carouFredSel = function(options) {
		return this.each(function() {
			var opts 			= $.extend(true, {}, $.fn.carouFredSel.defaults, options),
				$ul 			= $(this),
				$items 			= $("li", $ul),
				totalItems		= $items.length,
				nextItem		= opts.visibleItems,
				prevItem		= totalItems-1,
				itemWidth		= $items.outerWidth(),
				itemHeight		= $items.outerHeight(),
				autoInterval	= null,
				direction		= (opts.direction == "up" || opts.direction == "right") ? "next" : "prev";

			if (opts.visibleItems >= totalItems) {
				try { console.log('carouFredSel: Not enough items: terminating'); } catch(err) {}
				return;
			}

			if (opts.scroll.items == 0) 	opts.scroll.items = opts.visibleItems;
					
			opts.auto 		= $.extend({}, 	opts.scroll,	opts.auto);
			opts.buttons 	= $.extend({}, 	opts.scroll,	opts.buttons);
			opts.next 		= $.extend({}, 	opts.buttons,	opts.next);
			opts.prev 		= $.extend({}, 	opts.buttons,	opts.prev);

			if (!opts.auto.pauseDuration)	opts.auto.pauseDuration	= 2500;
			if ( opts.auto.pauseDuration == opts.auto.speed) opts.auto.speed--;

			opts.buttons = null;
			opts.scroll  = null;

			if (opts.direction == "right" ||
				opts.direction == "left"
			) {
				var cs1 = {
					width	: itemWidth * totalItems * 2
				}
				var cs2 = {
					width	: opts.width	|| itemWidth * opts.visibleItems,
					height	: opts.height 	|| itemHeight
				}
			} else {
				var cs1 = {
					height	: itemHeight * totalItems * 2
				}
				var cs2 = {
					height	: opts.height	|| itemHeight * opts.visibleItems,
					width	: opts.width	|| itemWidth
				}
			}

			$ul.css(cs1).css({
				position	: "absolute"
			}).wrap('<div class="caroufredsel_wrapper" />').parent().css(cs2).css({ 
				position	: "relative",
				overflow	: "hidden"
			});

			$ul
				.bind("pause", function() {
					if (autoInterval != null) {
						clearTimeout(autoInterval);
					}
				})
				.bind("play", function(e, d) {
					if (opts.autoPlay) {
						if (d == null	||
							d == '' 	||
							typeof(d) == 'undefined'
						) {
							d = direction;
						}

						autoInterval = setTimeout(function() {
							if ($ul.is(":animated")) 	$ul.trigger("pause").trigger("play", d);	//	still animating, wait
							else 						$ul.trigger(d, opts.auto);					//	scroll
						}, opts.auto.pauseDuration);
					}
				})
				.bind("next", function(e, sliderObj) {
					if ($ul.is(":animated")) return;

						 if (typeof(sliderObj) == 'undefined')	sliderObj = opts.next;
						 if (typeof(sliderObj) == 'object') 	numItems  = sliderObj.items;
					else if (typeof(sliderObj) == 'number') {
						numItems  = sliderObj;
						sliderObj = opts.next;
					}
					if (!numItems || typeof(numItems) != 'number') return;

					if (totalItems < opts.visibleItems+numItems) {
						$ul.find("li:lt("+((opts.visibleItems+numItems)-totalItems)+")").clone(true).appendTo($ul);
					}

					var currentItems = $.fn.carouFredSel.getCurrentItems($ul, opts, numItems);

					if (opts.direction == "right" ||
						opts.direction == "left"
					) {
						var pos = 'left',
							siz = itemWidth;
					} else {
						var pos = 'top',
							siz = itemHeight;
					}
					var ani = {},
						cal = {};

					ani[pos] = $ul.offset()[pos]-currentItems[0].offset()[pos] || -(siz * numItems);
					cal[pos] = 0;

					if (sliderObj.onBefore) {
						sliderObj.onBefore(currentItems[0], currentItems[1], "next");
					}

					$ul
						.data("numItems", 	numItems)
						.data("sliderObj", 	sliderObj)
						.data("oldItems", 	currentItems[0])
						.data("newItems", 	currentItems[1])
						.animate(ani, { 
							duration: sliderObj.speed,
							easing	: sliderObj.effect,
							complete: function() {
								if ($ul.data("sliderObj").onAfter) {
									$ul.data("sliderObj").onAfter($ul.data("oldItems"), $ul.data("newItems"), "next");
								}
								if (totalItems < opts.visibleItems+$ul.data("numItems")) {
									$ul.find("li:gt("+(totalItems-1)+")").remove();
								}
								$ul.css(cal).find("li:lt("+$ul.data("numItems")+")").appendTo($ul);
							}
						});

					//	auto-play
					$ul.trigger("pause").trigger("play", "next");
				})
				.bind("prev", function(e, sliderObj) {
					if ($ul.is(":animated")) return;

						 if (typeof(sliderObj) == 'undefined')	sliderObj = opts.prev;
						 if (typeof(sliderObj) == 'object') 	numItems  = sliderObj.items;
					else if (typeof(sliderObj) == 'number') {
						numItems  = sliderObj;
						sliderObj = opts.prev;
					}
					if (!numItems || typeof(numItems) != 'number') return;

					$ul.find("li:gt("+(totalItems-numItems-1)+")").prependTo($ul);

					if (totalItems < opts.visibleItems+numItems) {
						$ul.find("li:lt("+((opts.visibleItems+numItems)-totalItems)+")").clone(true).appendTo($ul);
					}

					var currentItems = $.fn.carouFredSel.getCurrentItems($ul, opts, numItems);

					if (opts.direction == "right" ||
						opts.direction == "left"
					) {
						var pos = 'left',
							siz = itemWidth;
					} else {
						var pos = 'top',
							siz = itemHeight;
					}

					var css = {},
						ani = {};

					css[pos] = $ul.offset()[pos]-currentItems[1].offset()[pos] || -(siz * numItems);
					ani[pos] = 0;

					if (sliderObj.onBefore) {
						sliderObj.onBefore(currentItems[1], currentItems[0], "prev");
					}

					$ul
						.data("numItems", 	numItems)
						.data("sliderObj", 	sliderObj)
						.data("oldItems", 	currentItems[1])
						.data("newItems", 	currentItems[0])
						.css(css)
						.animate(ani, { 
							duration: sliderObj.speed,
							easing	: sliderObj.effect,
							complete: function() {
								if (totalItems < opts.visibleItems+$ul.data("numItems")) {
									$ul.find("li:gt("+(totalItems-1)+")").remove();
								}
								if ($ul.data("sliderObj").onAfter) {
									$ul.data("sliderObj").onAfter($ul.data("oldItems"), $ul.data("newItems"), "next");
								}
							}
						});

					//	auto-play
					$ul.trigger("pause").trigger("play", "prev");					
				})
				.bind("slideTo", function(e, n, d) {
					if ($ul.is(":animated")) return;

					if (typeof(n) == 'object') n = $ul.find('li').index(n);
					if (typeof(n) == 'string') n = parseInt(n);
					if (typeof(d) == 'string') d = parseInt(d);
					if (typeof(d) != 'number') d = 0;

					if (typeof(n) != 'number') {
						try { console.log('carouFredSel: Not a valid number.'); } catch(err) {}
						return;
					}

					n += d;
					if (n < 0) 				n += totalItems;
					if (n >= totalItems)	n -= totalItems;
					if (n == 0) return;

					if (n < totalItems / 2) $ul.trigger("next", n);
					else					$ul.trigger("prev", totalItems-n);
				});


			if (opts.auto.pauseOnHover && opts.autoPlay) {
				$ul.hover(
					function() { $ul.trigger("pause"); },
					function() { $ul.trigger("play", direction); }
				);
			}

			//	via prev- en/of next-buttons
			if (opts.next.button != null) {
				opts.next.button.click(function() {
					$ul.trigger("next");
					return false;
				});
				if (opts.next.pauseOnHover && opts.autoPlay) {
					opts.next.button.hover(
						function() { $ul.trigger("pause"); },
						function() { $ul.trigger("play", direction); }
					);
				}
			}
			if (opts.prev.button != null) {
				opts.prev.button.click(function() {
					$ul.trigger("prev");
					return false;
				});
				if (opts.prev.pauseOnHover && opts.autoPlay) {
					opts.prev.button.hover(
						function() { $ul.trigger("pause"); },
						function() { $ul.trigger("play", direction); }
					);
				}
			}
			
			//	via keyboard
			if (opts.next.key != null ||
				opts.prev.key != null
			) {
				if (typeof(opts.next.key) == "string") opts.next.key = $.fn.carouFredSel.getKeyCode(opts.next.key);
				if (typeof(opts.prev.key) == "string") opts.prev.key = $.fn.carouFredSel.getKeyCode(opts.prev.key);

				$(window).keyup(function(event) {
					if (event.keyCode == opts.next.key)	$ul.trigger("next");
					if (event.keyCode == opts.prev.key)	$ul.trigger("prev");
				});
			}

			//	via auto-play
			$ul.trigger("play", direction);
		});
	}

	$.fn.carouFredSel.defaults = {
		height				: null,
		width				: null,
		visibleItems		: 5,
		autoPlay			: true,
		direction			: "right",
		scroll : {
			items				: 0,
			effect				: 'swing',
			speed				: 500,							
			pauseOnHover		: false,
			onBefore			: null,
			onAfter				: null
		}
	}
	
	$.fn.carouFredSel.getKeyCode = function(string) {
		if (string == "right")	return 39;
		if (string == "left") 	return 37;
		if (string == "up")		return 38;
		if (string == "down")	return 40;
		
		return -1;
	};
	
	$.fn.carouFredSel.getCurrentItems = function($u, o, n) {
		var oi = $u.find("li:lt("+o.visibleItems+")"),
			ni = $u.find("li:lt("+(o.visibleItems+n)+"):gt("+(n-1)+")");

		return [oi, ni];
	}
	
})(jQuery);