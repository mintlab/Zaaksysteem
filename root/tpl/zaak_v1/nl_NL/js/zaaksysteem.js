/* ***** BEGIN LICENSE BLOCK ********************************************
 * Version: EUPL 1.1
 *
 * The contents of this file are subject to the EUPL, Version 1.1 or
 * - as soon they will be approved by the European Commission -
 * subsequent versions of the EUPL (the "Licence");
 * you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://joinup.ec.europa.eu/software/page/eupl
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Zaaksysteem
 *
 * The Initial Developer of the Original Code is
 * Mintlab B.V. <info@mintlab.nl>
 * 
 * Portions created by the Initial Developer are Copyright (C) 2009-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 * Michiel Ootjers <michiel@mintlab.nl>
 * Jonas Paarlberg <jonas@mintlab.nl>
 * Jan-Willem Buitenhuis <jw@mintlab.nl>
 * Peter Moen <peter@mintlab.nl>
 *
 * ***** END LICENSE BLOCK ******************************************** */



$(document).ready(function(){



    /* Veldoptie runnings */
	//ezra_basic_functions();
    //ezra_basic_zaak_functions();
	ezra_basic_zaaktype_functions();
	ezra_basic_beheer_functions();

    $("a > input[type=button].link").click(function() {
        window.location = $(this).closest("a").attr("href");
    });

    $('form.webform .webformcontent').find('input.submit_to_pip').click(function() {
        if (!confirm('Weet u zeker dat u deze zaak later wilt afronden?')) {
            return false;
        }
    });


    $("#digidknop").click(function() {
        window.location = $("a",this).attr("href");	
    });

    $('.go_back').click(function() {
        var action = $(this).parents('form').attr('action');
        window.location = action + '?goback=1';
    });
    
    $('.sysmessage .close').click(function() {
      $(this).parent().hide('slow');
    });

    $('.ezra_spiffy_spinner:not(.zvalidate)').each(function() {
        //ezra_spiffy_spinner($(this));
        //ezra_spiffy_spinner_submit($(this));
    });
 
    if ($('form input[name="plugin"]').val() == 'parkeergebied') {
        ezra_plugin_parkeergebied();
    }

    if ($('form.aanvrager_form') && $('input[name="betrokkene_type"]')) {
        var form    = $('form.aanvrager_form');
        set_interne_medewerker_ztc_aanvrager_id = form.ztc_aanvrager_id;
        set_interne_medewerker_aanvrager_naam   = form.interne_aanvrager_naam;
        set_interne_medewerker();

        $('input[name="betrokkene_type"]').click(function() {
                if (this.value == 'medewerker') {
                    set_interne_medewerker();
                }

            // Resetten van de form
            $(":input").not(":button, :submit, :reset, :hidden").each( function() {
                this.value = this.defaultValue;     
            });

        });
    }
});


function Dumper(object) {
    var output = '';
    for (property in object) {
      output += property + ': ' + object[property]+";\n";
    }
    return output;
}


var set_interne_medewerker_ztc_aanvrager_id  = '';
var set_interne_medewerker_aanvrager_naam    = '';
function set_interne_medewerker() {
    var form    = $('form.aanvrager_form');

    $('form.input[name="ztc_aanvrager_id"]').val(set_interne_medewerker_ztc_aanvrager_id);
    $('form.input[name="interne_aanvrager_naam"]').val(set_interne_medewerker_aanvrager_naam);
}


function ezra_plugin_parkeergebied() {
    var form    = $('form.webform');

    // parkeergebied
    var parkeergebied_kenmerk   = 'kenmerk_id_'
        + form.find('input[name="plugin_parkeergebied_id"]').val();

    var prijs_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_prijs"]').val();

    var vergunninghouder_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_vergunninghouder_id"]').val();

    if (form.find('input[name="' + vergunninghouder_kenmerk + '"]').length) {
        ezra_plugin_parkeergebied_extreme(form,parkeergebied_kenmerk,prijs_kenmerk);
    } else {
        ezra_plugin_parkeergebied_bezoeker(form,parkeergebied_kenmerk,prijs_kenmerk);
    }
}

function ezra_plugin_parkeergebied_bezoeker(form,parkeergebied_kenmerk,prijs_kenmerk) {
    var input_parkeergebied;

    var vergunningen_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_aantal_vergunningen"]').val();

    form.bind('reloadParkeer', function() {
        if (form.find('input[name="' + parkeergebied_kenmerk + '"]').attr('type') == 'hidden') {
            input_parkeergebied = form.find('input[name="' + parkeergebied_kenmerk + '"]').val();
        } else {
            input_parkeergebied = form.find('input[name="' + parkeergebied_kenmerk + '"]:checked').val();
        }

        $.getJSON(
            '/plugins/parkeergebied/get_parkeergebied',
            {
                ztc_aanvrager_id: form.find('input[name="ztc_aanvrager_id"]').val(),
                parkeergebied: input_parkeergebied,
                parkeergebied_vergunningen: form.find('select[name="' + vergunningen_kenmerk + '"] :selected').val(),
                parkeergebied_bezoeker: 1
            },
            function(data) {
                var parkeergebied = data.json;

                if (!parkeergebied.success) {
                    return;
                }

                form.find('input[name="' + parkeergebied_kenmerk + '"]').closest('td')
                    .html(
                        '<input type="hidden" name="' + parkeergebied_kenmerk + '" value="'
                        + parkeergebied.parkeergebied + '" />'
                        + parkeergebied.parkeergebied
                    );

                var prijzen_html = '<select name="' + prijs_kenmerk + '">';
                for (var i in parkeergebied.prijzen) {
                    var prijs=parkeergebied.prijzen[i];

                    prijs_human = Number(prijs).toFixed(2).replace('.',',');

                    prijzen_html += '<option value="' + prijs + '">'
                        + '&euro; ' + prijs_human + '</option>'
                }

                prijzen_html += '</select>';

                form.find('select[name="' + prijs_kenmerk + '"]').closest('td')
                    .html(prijzen_html);

                form.find('select[name="' + vergunningen_kenmerk + '"]').change(function() {
                    form.trigger('reloadParkeer');
                });
            }
        );
    });

    form.ready(function() {
        form.trigger('reloadParkeer');
    });
}

function ezra_plugin_parkeergebied_extreme(form,parkeergebied_kenmerk,prijs_kenmerk) {
    var geldigheid_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_geldigheid_id"]').val();

    var betaalwijze_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_betaalwijze_id"]').val();

    var vergunningtype_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_vergunningtype_id"]').val();

    var startdatum_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_startdatum_id"]').val();

    var einddatum_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_einddatum_id"]').val();

    var geldigheidsdagen_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_geldigheidsdagen_id"]').val();

    var kenteken_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_kenteken_id"]').val();

    var vergunninghouder_kenmerk = 'kenmerk_id_'
        + form.find('input[name="plugin_vergunninghouder_id"]').val();

    var only_once = 0;
    form.bind('reloadParkeer', function() {
        var input_parkeergebied;
        if (form.find('input[name="' + parkeergebied_kenmerk + '"]').attr('type') == 'hidden') {
            input_parkeergebied = form.find('input[name="' + parkeergebied_kenmerk + '"]').val();
        } else {
            input_parkeergebied = form.find('input[name="' + parkeergebied_kenmerk + '"]:checked').val();
        }

        $.getJSON(
            '/plugins/parkeergebied/get_parkeergebied',
            {
                ztc_aanvrager_id: form.find('input[name="ztc_aanvrager_id"]').val(),
                geldigheid: form.find('select[name="' + geldigheid_kenmerk + '"] :selected').val(),
                vergunningtype: form.find('input[name="' + vergunningtype_kenmerk + '"]:checked').val(),
                startdatum: form.find('input[name="' + startdatum_kenmerk + '"]').val(),
                parkeergebied: input_parkeergebied
            },
            function(data) {
                var parkeergebied = data.json;

                if (!only_once) {
                    only_once=1;

                    form.find('input[name="' + startdatum_kenmerk + '"]').change(function() {
                        form.trigger('reloadParkeer');
                    });

                    form.find('input[name="' + vergunningtype_kenmerk + '"]').click(function() {
                        form.trigger('reloadParkeer');
                    });

                    form.find('input[name="' + parkeergebied_kenmerk + '"]').click(function() {
                        form.trigger('reloadParkeer');
                    });
                }

                if (!parkeergebied.success) {
                    return;
                }

                var vorige_geldigheid = form.find('select[name="' + geldigheid_kenmerk + '"] :selected').val();

                var geldigheid_html = '<select name="' + geldigheid_kenmerk + '">';
                for (var i in parkeergebied.geldigheden) {
                    var geldigheid=parkeergebied.geldigheden[i];

                    geldigheid_html += '<option value="' + geldigheid + '"'
                        + (vorige_geldigheid == geldigheid ? ' selected="selected"' : '') + '>'
                        + (geldigheid ? geldigheid + ' maanden' : 'Niet van toepassing') + '</option>'
                }

                geldigheid_html += '</select>';

                form.find('input[name="' + parkeergebied_kenmerk + '"]').closest('td')
                    .html(
                        '<input type="hidden" name="' + parkeergebied_kenmerk + '" value="'
                        + parkeergebied.parkeergebied + '" />'
                        + parkeergebied.parkeergebied
                    );

                form.find('select[name="' + geldigheid_kenmerk + '"]').closest('td')
                    .html(geldigheid_html);

                form.find('select[name="' + geldigheid_kenmerk + '"]').change();

                var prijzen_html = '<select name="' + prijs_kenmerk + '">';
                var heeft_prijzen = 0;
                for (var i in parkeergebied.prijzen) {
                    if (heeft_prijzen) {
                        prijzen_html += '<option value=""></option>';
                        heeft_prijzen = 1;
                    }
                    var prijs=parkeergebied.prijzen[i];

                    prijs_human = Number(prijs).toFixed(2).replace('.',',');

                    prijzen_html += '<option value="' + prijs + '">'
                        + '&euro; ' + prijs_human + '</option>'
                }

                prijzen_html += '</select>';

                form.find('select[name="' + prijs_kenmerk + '"]').closest('td')
                    .html(prijzen_html);

                if (parkeergebied.betaalwijze) {
                    form.find('select[name="' + betaalwijze_kenmerk + '"]').closest('td')
                        .html(
                            '<input type="hidden" name="' + betaalwijze_kenmerk + '" value="'
                            + parkeergebied.betaalwijze + '" />'
                            + parkeergebied.betaalwijze
                        );
                }

                if (!parkeergebied.toon_geldigheidsdagen) {
                    form.find('input[name="' + geldigheidsdagen_kenmerk + '"]').closest('tr').remove();
                }

                var einddatum = 'Selecteer een begindatum';
                if (parkeergebied.einddatum) {
                    if (parkeergebied.einddatum == '-') {
                        einddatum = 'Gelijk aan originele vergunning';
                    } else {
                        einddatum = parkeergebied.einddatum;
                    }
                }

                form.find('input[name="' + einddatum_kenmerk + '"]').closest('td')
                    .html(
                        '<input type="hidden" name="' + einddatum_kenmerk + '" value="'
                        + (parkeergebied.einddatum == '-' ? '' : einddatum) + '" />'
                        + einddatum
                    );


                form.find('select[name="' + geldigheid_kenmerk + '"]').change(function() {
                    form.trigger('reloadParkeer');
                });



                if (typeof(parkeergebied.heeft_vergunninghouder)=='undefined') {
                    form.find('input[name="' + vergunninghouder_kenmerk + '"]').closest('tr').remove();
                } else {
                    if (!parkeergebied.parkeergebied.match(/Centrum/)) {
                        form.find('input[name="' + kenteken_kenmerk + '"]').val(
                            'ALGEMEEN'
                        );
                        form.find('input[name="' + kenteken_kenmerk + '"]').attr(
                            'readonly','readonly'
                        );
                    }
                }
            }
        )
    });

    form.ready(function() {
        form.trigger('reloadParkeer');
    });
}

/*** ezra_beheer_functions
 *
 * functions which will be reloaded on beheer specific windows
 */

function ezra_spiffy_spinner(formelement) {
    formelement.submit(function() {
        ezra_spiffy_spinner_submit($(this));
    });

}

function ezra_spiffy_spinner_submit(formelement) {
    var action = formelement.attr('action');

    $.getJSON(
        action,
        {
            spiffy_spinner: 1
        },
        function(data) {
            var spinnerinfo = data.json.spinner;

            $('.milestoneSpinner .spinner_header').html(spinnerinfo.title);
            $('.milestoneSpinner .spinner_content').html('');

            var totaltime = 0;
            var totalheight = 96;
            $.each(spinnerinfo.checks, function(key, val) {
                var newcheck = $(
                    '<span class="element" id="' + val.naam + '">'
                    + val.label + '<span class="ajax checking spinner_anim_'
                    + val.naam + '"></span></span>'
                );

                $('.milestoneSpinner .spinner_content').append(newcheck);

                totaltime = (totaltime + val.timer);
                totalheight = (totalheight + 32);
                setTimeout(
                    function() {
                        $('.milestoneSpinner .spinner_content .spinner_anim_' + val.naam)
                           .removeClass('checking').addClass('valid');
                    },
                    totaltime
                );
            });

            $('.milestoneSpinner div.spinner_wrap').css('height', totalheight + 'px');

            $('.milestoneSpinner').show();

            formelement.unbind().submit();
        }
    );

    return false;
}

function ezra_basic_beheer_functions() {
    ezra_basic_beheer_kenmerk_naam();

    /* Multiple options */
    $('#kenmerk_definitie').each(function() {
        $('#kenmerk_invoertype').change(function() {
            if (
                (
                    $(this).attr('type') == 'hidden' &&
                    $(this).hasClass('has_options')
                ) ||
                $(this).find(':selected').hasClass('has_options')
            ) {
                $('.multiple-options').show();
            } else {
                $('.multiple-options').hide();
            }

            if (
                (
                    $(this).attr('type') == 'hidden' &&
                    $(this).hasClass('allow_default_value')
                ) ||
                $(this).find(':selected').hasClass('allow_default_value')
            ) {
                $('.default-value').show();
            } else {
                $('.default-value').hide();
            }

            if (
                (
                    $(this).attr('type') == 'hidden' &&
                    $(this).hasClass('file')
                ) ||
                $(this).find(':selected').hasClass('file')
            ) {
                $('.ezra_is_for_document').show();
                $('.ezra_is_not_for_document').hide();
            } else {
                $('.ezra_is_for_document').hide();
                $('.ezra_is_not_for_document').show();

            }
            if ($(this).find(':selected').hasClass('allow_multiple_instances')) {
                $('#kenmerk_definitie .edit_kenmerk_multiple').show();
            } else {
                $('#kenmerk_definitie .edit_kenmerk_multiple').hide();
                $('#kenmerk_definitie input[name=kenmerk_type_multiple]').removeAttr('checked');
            }
        });

        $('#kenmerk_invoertype').change();
    });

    /* Notificatie options */
    $('.ezra_notificatie_rcpt').change(function() {
        $('.ezra_notificatie_rcpt_behandelaar').hide();
        $('.ezra_notificatie_rcpt_overig').hide();
        if ($(this).val() == 'behandelaar') {
            $('.ezra_notificatie_rcpt_behandelaar').show();
        }
        if ($(this).val() == 'overig') {
            $('.ezra_notificatie_rcpt_overig').show();
        }
    });
    $('.ezra_notificatie_rcpt').change();
}

function ezra_basic_beheer_kenmerk_naam() {
    $('.ezra_kenmerk_naam').blur(function() {
        if ( $('.ezra_kenmerk_magic_string').length &&
            !$('.ezra_kenmerk_magic_string').val()
        ) {
            $.ajax({
                url: '/beheer/bibliotheek/kenmerken/get_magic_string',
                data: {
                    naam: $('.ezra_kenmerk_naam').val()
                },
                success: function(data) {
                    $('.ezra_kenmerk_magic_string').val(data);
                }
            });
        }
    });

    $('.ezra_sjabloon_suggest').change(function() {
        var currentform   = $('.ezra_sjabloon_suggest').parents('form');
        var currentaction = currentform.attr('action').replace(/add/,'suggest');

        if (!$('.ezra_sjabloon_suggest').val()) { return false; }

        $.ajax({
            url: currentaction,
            data: {
                naam: $('.ezra_sjabloon_suggest').val()
            },
            success: function(data) {
                $('.ezra_sjabloon_naam').val(data.json.suggestie);
                if (data.json.toelichting) {
                    $('.ezra_sjabloon_toelichting').val(data.json.toelichting);
                }
            }
        });
    });
    $('.ezra_sjabloon_suggest').change();
}

/* JQuery extensions */

/*** CLASS: ztAjaxUpdate
 *
 * ztAjaxUpdate, use:
 * $('.tableclass').ztAjaxUpdate();
 *
 * class: ztAjaxUpdate_update on update button
 * class: ztAjaxUpdate_dest on to updated html
 *
 * place div: ztAjaxUpdate_loader after title or something,
 *            which will show a spinner
 */

jQuery.fn.ztAjaxUpdate = function() {
    return this.each(function() {
        jQuery.ztAjaxUpdate.load($(this));
    });
}

jQuery.ztWaitStart = function() {
    $('.custom_overlay').show();
    $('.custom_overlay_loader').show();

    //$('#globalSpinner').show();
    //$('#globalSpinner').animate({ opacity: 0.9});
}

jQuery.ztWaitStop = function() {
    $('.custom_overlay').hide();
    $('.custom_overlay_loader').hide();
}

jQuery.ztAjaxUpdate = {
    load: function(elem) {
        // Make sure destination is a block
    	elem.find('.ztAjaxUpdate_dest').css('display', null);
        elem.find('.ztAjaxUpdate_loader').hide();

        // Update button working
        if (elem.find('.ztAjaxUpdate_update').attr('action')) {
            elem.find('.ztAjaxUpdate_update').submit(function() {

                var container   = $(this).closest('.ztAjaxUpdate');
                var destination = container.find('.ztAjaxUpdate_dest');

                if (container.hasClass('ztAjaxUpdate_loading')) {
                    return false;
                }

                var serialized = $(this).serialize();

                /* Loading */
                container.addClass('ztAjaxUpdate_loading');
                //container.find('.ztAjaxUpdate_loader').show();
                $.ztWaitStart();

                destination.load(
                    $(this).attr('action'),
                    serialized,
                    function() {
                        //container.find('.ztAjaxUpdate_loader').hide();
                        $.ztWaitStop();
                        container.removeClass('ztAjaxUpdate_loading');
                        $(this).closest('.ztAjaxUpdate')
                            .find('.ztAjaxUpdate_update button, .ztAjaxUpdate_update input[type="submit"]')
                            .attr('disabled', null);

                        container.find('form.ztAjaxUpdate_update')[0].reset();

                        ezra_basic_functions();
                    }
                );

                return false;
            });
        } else {
            elem.find('.ztAjaxUpdate_update').click(function() {
                var options     = getOptions($(this).attr('rel'));
                var container   = $(this).closest('.ztAjaxUpdate');
                var destination = container.find('.ztAjaxUpdate_dest');

                if (container.hasClass('ztAjaxUpdate_loading')) {
                    return false;
                }

                var serialized = '';
                if (options.form) {
                    var serialized = container.find('form').serialize();
                }

                /* Loading */
                container.addClass('ztAjaxUpdate_loading');
                //container.find('.ztAjaxUpdate_loader').show();
                //$('#globalSpinner').show();
                //$('#maincontainer').animate({ opacity: 0.25}, 600)
                $.ztWaitStart();


                destination.load(
                    $(this).attr('href'),
                    serialized,
                    function() {
                        //container.find('.ztAjaxUpdate_loader').hide();
                        $.ztWaitStop();
                        container.removeClass('ztAjaxUpdate_loading');
                        $(this).closest('.ztAjaxUpdate')
                            .find('.ztAjaxUpdate_update button')
                            .attr('disabled', null);

                        ezra_basic_functions();
                    }
                );

                return false;
            });
        }

    }
}



/*** CLASS: ztAjaxTable
 * ztAjaxTable, use:
 * $('.tableclass').ztAjaxTable();
 *
 * class: ztAjaxTable_template on template <tr>
 * class: ztAjaxTable_row on 'real' rows <tr>
 * class: ztAjaxTable_del on delete button
 * class: ztAjaxTable_add on add button
 *
 * optional:
 * class: ztAjaxTable_ignore for rows to ignore in table
 */

jQuery.fn.ztAjaxTable = function() {
    return this.each(function() {
        jQuery.ztAjaxTable.load($(this));
        jQuery.ztAjaxTable.init($(this));
    });
};

jQuery.ztAjaxTable = {
    load: function(elem) {
        // { Load ignored rows in table
        elem.ztAjaxTable.config = {
            ignored_rows: [],
            num_rows: 0
        };

        elem.find('.ztAjaxTable_ignore').each(function() {
            if (!elem) { return; }

            elem.ztAjaxTable.config.ignored_rows.push($(this));
        });
        // }
    },
    init: function(elem) {
		
        /* Hide ignored rows */
        jQuery.each(
            elem.ztAjaxTable.config.ignored_rows,
            function(index, ignored_row) {
                ignored_row.hide();
            }
        );

        // {{{ TEMPLATE ROW

        // Hide
        elem.find('.ztAjaxTable_template').hide();

        elem.closest('div').find('.ztAjaxTable_del').click(function() {
            $(this).closest('tr.ztAjaxTable_row').remove();
        	//updateSearchFilterKenmerkenTable();
            updateSearchFilters();
            return false;
        });

        // }}}

        /* Count visible rows */
        elem.ztAjaxTable.config.num_rows = elem.find('tr.ztAjaxTable_row').length;

        /* Search for row creation button within prev. handler */
        elem.closest('div').find('.ztAjaxTable_add').unbind().click(function() {
            var row = jQuery.ztAjaxTable.row_add(elem);
            /* Start callback after adding row */
            var options     = getOptions($(this).attr('rel'));

            /* Create callback */
            if (options.rowcallback) {
                /* Find unique hidden */
                var unique_hidden_value = null;
                if (row.find('.ztAjaxTable_uniquehidden').length) {
                    var unique_hidden_value = row.find('.ztAjaxTable_uniquehidden').attr('name');
                }

                var callbackfunction = options.rowcallback;                
                var rownumber        = jQuery.ztAjaxTable.get_row_number(row);
                window[callbackfunction]($(this),row,unique_hidden_value,rownumber);
            }

            return false;
        });

        // Find callbackfunction
        elem.closest('div').find('.ztAjaxTable_add').each(function() {
            var options     = getOptions($(this).attr('rel'));
            if (options.initcallback) {
                var callbackfunction = options.initcallback;

                window[callbackfunction]($(this));
            }

        });

    },
    get_row_number: function(rowelem) {

        var trclass     = rowelem.attr('class');
        if (!trclass.match(/ztAjaxTable_rownumber/)) {
            return 0;
        }
        var trnumber    = trclass.replace(/.*ztAjaxTable_rownumber_(\d+).*/g, '$1');

        return trnumber;
    },
    get_new_rownumber: function(rowelem) {

        var highest = 0;
        var table   = rowelem.closest('table');

        table.find('.ztAjaxTable_row').each(function() {
            var rownumber = jQuery.ztAjaxTable.get_row_number($(this));

            if (parseInt(rownumber) > parseInt(highest)) {
                highest = parseInt(rownumber);
            }
        });

        if (highest < 1) {
            returnval = 1;
        } else {
            returnval = parseInt(highest) + parseInt(1);
        }

        return returnval;
    },
    row_add: function(elem) {
        var nextrow = (elem.ztAjaxTable.config.num_rows + 1);
        var clone   = elem.find('.ztAjaxTable_template').clone(true);
        var parent  = elem.find('.ztAjaxTable_template').parent();

        /* Change row basics */
        if (clone.attr('id')) {
            clone.attr('id', clone.attr('id') + '_' + nextrow);
        }

        clone.removeClass('ztAjaxTable_template').addClass('ztAjaxTable_row');


        /* show row */
        clone.show();
        parent.append(clone);

        var nextrownumber = jQuery.ztAjaxTable.get_new_rownumber(clone);
        clone.addClass('ztAjaxTable_rownumber_' + nextrownumber);

        /* Set config */
        elem.ztAjaxTable.config.num_rows = nextrow;

        return clone;
    }
};

/* NOTIFICATIES
 *
 *
 *
 *
 */

function ezra_zaaktype_add_notificatie(add_elem,add_row,uniquehidden, rownumber) {
    var fire_elem = add_elem.clone();

    ezra_zaaktype_notificatie_edit(add_elem);

    add_row.find('input').each(function() {
        var inputname = $(this).attr('name');
        inputname = inputname + '_' + rownumber;
        $(this).attr('name', inputname);
    });
}

function ezra_zaaktype_notificatie_edit(add_elem) {
    var container = add_elem.closest('div');

    container.find('.edit').unbind().click(function() {
        var container   = $(this).closest('tr');
        var uniqueidr   = container.find('.ztAjaxTable_uniquehidden').attr('name');

        $(this).attr('rel', 'callback: ezra_zaaktype_add_notificatie_definitie_dialog; uniqueidr: ' + uniqueidr);

        fireDialog($(this));

        return false;
    });
}

function ezra_zaaktype_add_notificatie_definitie_dialog() {
    $('#notificatie_definitie').find('form').submit(function() {
        var postaction = '/zaaktype/status/notificatie_definitie';
        if ($(this).attr('action')) {
            postaction = $(this).attr('action');
        }

        /* Do Ajax call */
        var serialized = $(this).serialize();
        var container  = $(this).closest('#notificatie_definitie');

        $.post(
            postaction,
            serialized,
            function(data) {
                $('#dialog').dialog('close');
            }
        );

        return false;
    });
    ezra_basic_selects();
}

/* SJABLONEN
 *
 *
 *
 */

function ezra_zaaktype_sjabloon_edit(add_elem) {
    var container = add_elem.closest('div');

    container.find('.edit').unbind().click(function() {
        var container   = $(this).closest('tr');
        var uniqueidr   = container.find('.ztAjaxTable_uniquehidden').attr('name');

        $(this).attr('rel', 'callback: ezra_zaaktype_add_sjabloon_definitie_dialog; uniqueidr: ' + uniqueidr);

        fireDialog($(this));

        return false;
    });
}

function ezra_zaaktype_add_sjabloon_definitie_dialog() {
    $('#sjabloon_definitie').find('form').submit(function() {
        /* Do Ajax call */
        var serialized = $(this).serialize();
        var container  = $(this).closest('#sjabloon_definitie');

        $.post(
            '/zaaktype/status/sjablonen_definitie',
            serialized,
            function(data) {
                $('#dialog').dialog('close');
            }
        );

        return false;
    });
}

function ezra_zaaktype_add_sjabloon(add_elem,add_row,uniquehidden, rownumber) {
    var fire_elem = add_elem.clone();

    ezra_zaaktype_sjabloon_edit(add_elem);

    uniquehidden = uniquehidden + '_' + rownumber;
    add_row.find('.ztAjaxTable_uniquehidden').attr('name', uniquehidden);

    fire_elem.attr(
        'rel',
        'hidden_name: ' + uniquehidden + '; callback: ezra_zaaktype_add_sjabloon_create'
    );
    fireDialog(fire_elem);
    $('#dialog').bind( 'dialogclose', function (event,ui) {
            add_row.remove();
        }
    );
}

function ezra_zaaktype_add_sjabloon_create(jaja) {
    /* Search accordion */
    $('.ztAccordion').each(function() {
        $(this).accordion({
            autoHeight: false
        });
    });

    $('#sjabloon_definitie').find('form').unbind().submit(function() {

        var serialized = $(this).serialize();
        var container  = $(this).closest('#sjabloon_definitie');

        $.getJSON(
            '/beheer/bibliotheek/sjablonen/skip/0/bewerken?' + serialized + '&json_response=1',
            function(data) {
                var sjabloon = data.json;

                var rownaam      = container.find('input[name="naam"]').val();

                var uniqueid = sjabloon.id;

                /* { NEW ZTB STYLE */
                container.find('input[name="row_id"]').each(function() {
                    /* Shoot info to this row */
                    var row_id      = $(this).val();

                    var ezra_table  = $('#' + $(this).val()).parents('div.ezra_table');

                    ezra_table.ezra_table('update_row', row_id, {
                        '.rownaam'  : rownaam,
                        '.rowid'    : uniqueid
                    });
                });
                /* } ZTB */
                $('#dialog').unbind( 'dialogclose');
                $('#dialog').dialog('close');
            }
        );

        return false;
    });
}


function ezra_zaaktype_select_sjabloon(add_elem,add_row,uniquehidden, rownumber) {
    var fire_elem = add_elem.clone();

    ezra_zaaktype_sjabloon_edit(add_elem);

    uniquehidden = uniquehidden + '_' + rownumber;
    add_row.find('.ztAjaxTable_uniquehidden').attr('name', uniquehidden);

    fire_elem.attr(
        'rel',
        'hidden_name: ' + uniquehidden + '; callback: ezra_zaaktype_select_sjabloon_search'
    );
    fireDialog(fire_elem);
    $('#dialog').bind( 'dialogclose', function (event,ui) {
            add_row.remove();
        }
    );
}

function ezra_zaaktype_select_sjabloon_search(jaja) {
    /* Search accordion */
    $('.ztAccordion').each(function() {
        $(this).accordion({
            autoHeight: false
        });
    });

    /* Nieuw button */
    $('.ezra_bibliotheek_nieuw').click(function() {
        var currentclass = $(this).attr('class');
        var bib_type      = currentclass.replace(/.*bib_type_(.+)/, '$1');

        $('#dialog').unbind( 'dialogclose');
        $('#dialog').dialog('close');

        var url = '/beheer/bibliotheek/' + bib_type + '/1/0/bewerken';
        var aelem = $('<a href="' + url + '">');
        aelem.attr('rel',
            'row_id: ' + $(this).parents('div').find('[name="row_id"]').val() +
            '; callback: ezra_zaaktype_add_sjabloon_create'
        );

        fireDialog(aelem);


        return false;
    });


    $('#search_bibliotheek_sjablonen').find('form').submit(function() {
        /* Do Ajax call */
        var serialized = $(this).serialize();
        var container  = $(this).closest('.ztAccordion');

        $.getJSON(
            '/beheer/bibliotheek/sjablonen/search?' + serialized,
            function(data) {
                var sjablonen = data.json;

                if (!data.json.length) {
                    container.find('#resultaten').html('Geen resultaten gevonden');
                }

                /* Create table */
                var newtable = $('<table class="sjabloon_resultaten"></table>');
                var newtable_header = $(
                    '<tr class="table_zaken_title_tr">'
                    + '<td class="table_zaken_title_td250">Naam:</td>'
                    + '<td class="table_zaken_title_td250">Categorie:</td>'
                    + '</tr>');

                newtable.append(newtable_header);

                /* Create rows */
                for (var i in sjablonen) {
                    var sjabloon=sjablonen[i];

                    var newrow = $(
                        '<tr class="table_zaken_tr" id="sjabloon-id-' + sjabloon.id + '">'
                        + '<td class="table_zaken_td250 sjabloon_naam">' + sjabloon.naam + '</td>'
                        + '<td class="table_zaken_td150">' + sjabloon.categorie + '</td>'
                        + '</tr>'
                    );

                    newtable.append(newrow);
                }

                /* Add some logic to the table, when clicked */
                newtable.find('tr').click(function() {
                    var uniquehidden = container.find('input[name="uniquehidden"]').val();
                    var rownaam      = $(this).find('.sjabloon_naam').html();

                    var uniqueid = $(this).attr('id');
                    uniqueid = uniqueid.replace('sjabloon-id-', '');

                    /* { NEW ZTB STYLE */
                    container.find('input[name="row_id"]').each(function() {
                        /* Shoot info to this row */
                        var row_id      = $(this).val();

                        var ezra_table  = $('#' + $(this).val()).parents('div.ezra_table');

                        ezra_table.ezra_table('update_row', row_id, {
                            '.rownaam'      : rownaam,
                            '.rowid'    : uniqueid
                        });
                    });
                    /* } ZTB */

                    $('input[name="' + uniquehidden + '"]').val(uniqueid);

                    $('input[name="' + uniquehidden + '"]')
                        .closest('td')
                        .find('.description')
                        .html(rownaam);

                    $('#dialog').unbind( 'dialogclose');
                    $('#dialog').dialog('close');

                });

                container.find('#resultaten').html(newtable);
                container.accordion('activate', 1);
            }
        );

        return false;
    });
}

function ezra_zaaktype_kenmerk_edit(add_elem) {
    var container = add_elem.closest('div');

    container.find('.edit').unbind().click(function() {
        var container   = $(this).closest('tr');
        var uniqueidr   = container.find('.ztAjaxTable_uniquehidden').attr('name');
        var uniqueidrval = container.find('.ztAjaxTable_uniquehidden').attr('value');

        $(this).attr('rel', 'callback: ezra_zaaktype_add_kenmerk_definitie_dialog; uniqueidr: ' + uniqueidr + '; uniqueidrval: ' + uniqueidrval);

        fireDialog($(this));

        return false;
    });
}


//
// when a new zaaktype kenmerk regel is created, automatically open the dialog
//
function ezra_zaaktype_regel_edit(add_elem) {
    var container = add_elem.closest('div');
    container.find('.edit').last().click();
}


//-------------------------------------------------------------------------------



function ezra_zaaktype_add_kenmerk_definitie_dialog() {

    $('#kenmerk_definitie').find('form').submit(function() {
        /* Do Ajax call */
        var serialized = $(this).serialize();
        var container  = $(this).closest('#kenmerk_definitie');

        $.post(
            '/zaaktype/status/kenmerken_definitie',
            serialized,
            function(data) {
                $('#dialog').dialog('close');
            }
        );

        return false;
    });
}


function ezra_zaaktype_add_kenmerk_create(jaja) {
    /* Search accordion */
    $('.ztAccordion').each(function() {
        $(this).accordion({
            autoHeight: false
        });
    });

    $('#kenmerk_definitie').find('form').unbind().submit(function() {

        var serialized = $(this).serialize();
        var container  = $(this).closest('#kenmerk_definitie');

        $.getJSON(
            '/beheer/bibliotheek/kenmerken/skip/0/bewerken?' + serialized + '&json_response=1',
            function(data) {
                var kenmerk     = data.json;

                var rownaam     = container.find('input[name="kenmerk_naam"]').val();

                var uniqueid    = kenmerk.id;

                /* { NEW ZTB STYLE */
                container.find('input[name="row_id"]').each(function() {
                    /* Shoot info to this row */
                    var row_id      = $(this).val();

                    var ezra_table  = $('#' + $(this).val()).parents('div.ezra_table');

                    ezra_table.ezra_table('update_row', row_id, {
                        '.rownaam'  : rownaam,
                        '.rowid'    : uniqueid
                    });
                });
                /* } ZTB */

                $('#dialog').unbind( 'dialogclose');
                $('#dialog').dialog('close');
            }
        );

        return false;
    });
}




function ezra_zaaktype_select_kenmerk_with_search(add_elem,add_row,uniquehidden, rownumber) {
    ezra_zaaktype_select_kenmerk(add_elem,add_row,uniquehidden, rownumber);

}


function ezra_zaaktype_select_kenmerk(add_elem,add_row,uniquehidden, rownumber) {
    var fire_elem = add_elem.clone();

    ezra_zaaktype_kenmerk_edit(add_elem);

    uniquehidden = uniquehidden + '_' + rownumber;
    //add_row.find('.ztAjaxTable_uniquehidden').attr('name', uniquehidden);

    add_row.find('input').each(function() {
        var inputname = $(this).attr('name');
        inputname = inputname + '_' + rownumber;
        $(this).attr('name', inputname);
    });

	var search_filter_post = '';
	if($('form#search_filters .kenmerken_container').length) {
		search_filter_post = '; search_filter_post: 1';
	}
    fire_elem.attr(
        'rel',
        'hidden_name: ' + uniquehidden + '; callback: ezra_zaaktype_select_kenmerk_search' + search_filter_post
    );
    fireDialog(fire_elem);

    $('#dialog').bind( 'dialogclose', function (event,ui) {
        location.reload(); // necessary for search_filters. if you cancel adding a filter shit hits fan
        add_row.remove();
    });
}

function ezra_zaaktype_select_kenmerk_search(callback) {
    /* Search accordion */
    $('.ztAccordion').each(function() {
        $(this).accordion({
            autoHeight: false
        });
    });

    /* Nieuw button */
    $('.ezra_bibliotheek_nieuw').click(function() {
        var currentclass = $(this).attr('class');
        var bib_type      = currentclass.replace(/.*bib_type_(.+)/, '$1');

        $('#dialog').unbind( 'dialogclose');
        $('#dialog').dialog('close');

        var url = '/beheer/bibliotheek/' + bib_type + '/1/0/bewerken';
//        var aelem = $('<a href="' + url + '">');
//        aelem.attr('rel',
//            'row_id: ' + $(this).parents('div').find('[name="row_id"]').val() +
//            '; callback: ezra_zaaktype_add_kenmerk_create'
//        );
//        fireDialog(aelem);

        $('#dialog .dialog-content').load(
            url,
            options,
            function() {
                ezra_zaaktype_add_kenmerk_create();
                $.ztWaitStop();
                ezra_basic_functions();    
                openDialog(title, options['width'], options['height']);
            }
        );

        return false;
    });

    $('#search_bibliotheek_kenmerken').find('form').submit(function() {
        /* Do Ajax call */
        var serialized = $(this).serialize();
        var container  = $(this).closest('.ztAccordion');

        $.getJSON(
            '/beheer/bibliotheek/kenmerken/search?' + serialized,
            function(data) {
                var kenmerken = data.json;

                if (!data.json.length) {
                    container.find('#resultaten').html('Geen resultaten gevonden');
                }

                /* Create table */
                var newtable = $('<table class="kenmerk_resultaten"></table>');
                var newtable_header = $(
                    '<tr class="table_zaken_title_tr">'
                    + '<td class="table_zaken_title_td250">Naam:</td>'
                    + '<td class="table_zaken_title_td250">Invoertype:</td>'
                    + '<td class="table_zaken_title_td250">Categorie:</td>'
                    + '</tr>');

                newtable.append(newtable_header);

                /* Create rows */
                for (var i in kenmerken) {
                    var kenmerk=kenmerken[i];

                    var newrow = $(
                        '<tr class="table_zaken_tr" id="kenmerk-id-' + kenmerk.id + '">'
                        + '<td class="table_zaken_td250 kenmerk_naam">' + kenmerk.naam + '</td>'
                        + '<td class="table_zaken_td150">' + kenmerk.invoertype + '</td>'
                        + '<td class="table_zaken_td150">' + kenmerk.categorie + '</td>'
                        + '</tr>'
                    );

                    newtable.append(newrow);
                }

                /* Add some logic to the table, when clicked */
                newtable.find('tr').click(function() {
                    var uniquehidden = container.find('input[name="uniquehidden"]').val();
                    var rownaam      = $(this).find('.kenmerk_naam').html();
                    var uniquesearch = uniquehidden.replace('_id_','_search_');

                    var uniquehidden = container.find('input[name="uniquehidden"]').val();

                    var uniqueid = $(this).attr('id');
                    uniqueid = uniqueid.replace('kenmerk-id-', '');
                    
                    
                    /* { NEW ZTB STYLE */
                    if (container.find('input[name="row_id"]').val()) {
                        container.find('input[name="row_id"]').each(function() {
                            /* Shoot info to this row */
                            var row_id      = $(this).val();

                            var ezra_table  = $('#' + $(this).val()).parents('div.ezra_table');
                            ezra_table.ezra_table('update_row', row_id, {
                                '.rownaam'      : rownaam,
                                '.rowid'    : uniqueid
                            });
                        });
                    }
                    /* } ZTB */

                    $('input[name="' + uniquehidden + '"]').val(uniqueid);

                    $('input[name="' + uniquehidden + '"]')
                        .closest('td')
                        .find('.description')
                        .html(rownaam);

                    $('input[name="' + uniquehidden + '"]')
                        .closest('tr')
                        .find('.search_td').load(
                            '/beheer/bibliotheek/kenmerken/get_veldoptie',
                            {
                                kenmerk_id: uniqueid,
                                veldoptie_name: uniquesearch
                            },
                            function() {
                            	updateSearchFilters();
                            	updateSearchFilterKenmerkenTable();
                                veldoptie_handling();
                            }
                        );

                    // call callback function if supplied
                    if(callback) {
                        eval(callback)($(this));
                    }
                    

                    $('#dialog').dialog({
                        beforeclose: null
                    });
                    $('#dialog').unbind( 'dialogclose');
                    $('#dialog').dialog('close');
                });

                container.find('#resultaten').html(newtable);
                container.accordion('activate', 1);
            }
        );

        return false;
    });
}

function updateSearchFilterKenmerkenTable() {
	if($('#search_filter_holder_kenmerk')) {
		$('#search_filters input[name=current_filter_type]').val('kenmerk');

		var count = $('.kenmerken_container tr').size() - 2;

		if(count > 0) {
			$('#search_filter_holder_kenmerk').show();
			$('#search_filter_div_kenmerk').show();
			$('#search_filter_holder_kenmerk .number').html(count);
		} else {
			$('#search_filter_holder_kenmerk').hide();
			$('#search_filter_div_kenmerk').hide();
		}
	}
}

/* JQuery functions */
function ezra_basic_zaaktype_functions() {
    $('.ezra_direct_finish').click(function() {
        var current_form = $(this).closest('form');
        current_form.find('input[name="direct_finish"]').val(1);
        if($(this).hasClass('novalidation')) {
            return true;
        }
        return zvalidate(current_form);
    });

    $('.ztAjaxTable').ztAjaxTable();

    /* Terms */
    $('.widget_term_select').change(function() {
        ezra_basic_widget_term($(this), 1);
    }).each(function() {
        ezra_basic_widget_term($(this));
    });

	/*	
		sortable tabellen 
	*/
    $("table.sortable tbody").sortable({update:
            function(event,ui) {
                $("tr",this).each(
                    function( index, element ){
                        $("input",this).val(index+1);
                    }
                );
                
                $("tr",this).css({border: '1px solid #000'});
                $("tr",this).removeClass('lastrow');
                $("tr:last-child",this).addClass('lastrow');
                
                if($(this).parent('table').hasClass('search_query_table')) {
                    var params = $("table.search_query_table.sortable").closest('form').serialize();
                    $.getJSON('/search/dashboard?action=update_sort_order&' + params, function(data) {
                        if(data && data.json && data.json.result) {
//                            log('result: ' + data.json.result);
                        } else {
//                            log('error communicating with JSON backend');
                        }
                    });  
                }
            }
        });
        $("table.sortable tbody ").disableSelection();
		
		
    ezra_basic_widget_auth();

}

var zaaktype_data = {};
function _load_zaaktypen(trigger,betrokkene_type,activate) {

    if (zaaktype_data[trigger] && zaaktype_data[trigger][betrokkene_type]) {
        if (activate) {
            _activate_zaaktype_autocomplete(activate);
        }
        return zaaktype_data[trigger][betrokkene_type];
    }

    $.getJSON(
        '/zaaktype/search',
        {
            jsbetrokkene_type: betrokkene_type,
            jstrigger: trigger,
            search: 1,
            json_response: 1
        },
        function(data) {
            var zaaktypen = data.json.zaaktypen;

            if (!zaaktype_data[trigger]) {
                zaaktype_data[trigger] = {};
            }

            zaaktype_data[trigger][betrokkene_type] = {
                'raw'   : [],
                'hash'  : {}
            };

            for (var i in zaaktypen) {
                var zaaktype=zaaktypen[i];

                zaaktype_data[trigger][betrokkene_type].raw.push(zaaktype.naam);
                zaaktype_data[trigger][betrokkene_type].hash[zaaktype.naam] = zaaktype.id;
            }

            if (activate) {
                _activate_zaaktype_autocomplete(activate);
            }
        }
    );
}


function _activate_zaaktype_autocomplete(activate) {
    $('.ezra_zaaktype_keuze_textbox').autocomplete('destroy');
    $('.ezra_zaaktype_keuze_textbox').autocomplete({
        autoFocus: true,
        minLength: 0,
        delay: 100,
        source: zaaktype_data[activate.trigger][activate.betrokkene_type].raw,
        select: function(event, ui) {
            var zaaktype_id = zaaktype_data[activate.trigger][activate.betrokkene_type].hash[ui.item.value];
            activate.formcontainer.find('.ezra_zaaktype_keuze input[name="zaaktype_id"]').val(zaaktype_id);
            activate.formcontainer.find('.ezra_zaaktype_keuze input.zaaktype_id_finder').val(zaaktype_id);
        }
    }); //.focus(function() {
        //$(this).autocomplete("search");
    //});

}


// this function is called twice yield ajax congestion. if the second calling of this function
// is removed, this variable can be eliminated
var changed_aanvraag_type_yet = 0;

function ezra_basic_zaak_intake() {
    $('.ezra_simple_table').unbind('simpleTable').bind('simpleTable', function() {

        /* INITIALIZE THIS FUNCTIONALITY BELOW */
        if ($(this).hasClass('ezra_simple_table-refresh')) {
            $(this).find('.ezra_simple_table-table_container').load(
                $(this).find('.ezra_simple_table-add').attr('href')
            );

            $(this).removeClass('ezra_simple_table-refresh');
        }

        /* Return when already initialized */
        if (
            $(this)
                .hasClass('ezra_simple_table-initialized')
        ) {
            return true;
        }

        $(this).find('.ezra_simple_table-add').click(function() {
            // Load option
            var rel                     = $(this).attr('rel');
            var options                 = getOptions(rel);

            // Load necessary elements
            var current_simple_table    = $(this)
                .closest('.ezra_simple_table');

            // On submit of popup, do not submit, but transfer content over
            // post, and refresh simpletable
            var submit_event = function(formelem) {
                var post_options = validate_serialize_items(formelem);

                $.post(
                    formelem.attr('action'),
                    post_options,
                    function() {
                        current_simple_table.addClass(
                            'ezra_simple_table-refresh'
                        );
                        current_simple_table.trigger('simpleTable')
                        $('#dialog').dialog('close');
                    }
                );
            };


            /* Options ok, load popup */
            $('#dialog .dialog-content').load(
                $(this).attr('href') + '?add=1',
                options,
                function() {
                    initializeEverything();
                    ezra_basic_functions()

                    $('#dialog .dialog-content form')
                        .unbind('submit')
                        .bind('submit', function() {
                            if ($(this).hasClass('zvalidate')) {
                                request_validation(
                                    $(this),
                                    null,
                                    {
                                        events: {
                                            submit: submit_event
                                        }
                                    }
                                );
                                return false;
                            }
                            return false;
                        });

                    openDialog("", options['width'], options['height']);
                }
            );

            return false;
        });

        $(this).find('.ezra_simple_table-remove').live('click', function() {
            var identifier              = $(this)
                .closest('tr').find('input[name="row_identifier"]').val();

            container = $(this).closest('.ezra_simple_table');

            container.find('.ezra_simple_table-table_container').load(
                container.find('.ezra_simple_table-remove').attr('href')
                    + '?remove=' + identifier
            );

            return false;
        });

        $(this)
            .addClass('ezra_simple_table-initialized');
    });

    if ($('.ezra_simple_table').length) {
        $('.ezra_simple_table').addClass('ezra_simple_table-refresh');
        $('.ezra_simple_table').trigger('simpleTable');
    }

    $('.form .zaak_aanmaken').unbind('refreshForm').bind('refreshForm', function() {
        /* Retrieve trigger and betrokkene_type */
        var ztc_trigger     =
            $('.zaak_aanmaken .ezra_trigger input[type="radio"]:checked').val();
        var betrokkene_type = 'medewerker';
        var ontvanger_type  = 'natuurlijk_persoon';
        var remember_id     = '';
        var remember_naam   = '';

        current_class   = $('form .zaak_aanmaken').attr('class');

        if (ztc_trigger == 'extern') {
            $('.zaak_aanmaken .ezra_id_ontvanger_type').hide();
            $('.zaak_aanmaken .ezra_id_bestemming,'
                + '.zaak_aanmaken .ezra_id_ontvanger').hide();
            $('.zaak_aanmaken .ezra_id_aanvrager_type').show();

            betrokkene_type = $('.zaak_aanmaken .ezra_id_aanvrager_type '
               + ' .ezra_betrokkene_type input[type="radio"]:checked').val();

            if ($('.zaak_aanmaken .ezra_id_aanvrager .aanvragers').val().match('medewerker')) {
                $('.zaak_aanmaken .ezra_id_aanvrager .aanvragers').val('');
                $('.zaak_aanmaken .ezra_id_aanvrager .ezra_betrokkene_selector').val('');
            }

            // Remember zaaktype function
            if ($('.zaak_aanmaken')
                    .closest('form')
                    .find('input[name="remembered_zaaktype_extern"]')
                    .length
            ) {
                var remembered = $('.zaak_aanmaken')
                    .closest('form')
                    .find('input[name="remembered_zaaktype_extern"]').val();

                remembered = remembered.split(';');

                remember_id = remembered[0];
                remember_naam = remembered[1];
            }
        } else {
            $('.zaak_aanmaken .ezra_id_bestemming').show();
            $('.zaak_aanmaken .ezra_id_aanvrager_type').hide();
            var bestemming  =
                $('.zaak_aanmaken .ezra_id_bestemming input[type="radio"]:checked').val();

            if (!$('.zaak_aanmaken .ezra_id_aanvrager .aanvragers').val()) {
                $('.zaak_aanmaken .ezra_id_aanvrager .aanvragers').val(
                    $('.zaak_aanmaken .ezra_id_value_medewerker_naam').val()
                );
                $('.zaak_aanmaken .ezra_id_aanvrager .ezra_betrokkene_selector').val(
                    $('.zaak_aanmaken .ezra_id_value_medewerker_id').val()
                );

            }

            if (bestemming == 'extern') {
                $('.zaak_aanmaken .ezra_id_ontvanger').show();
                ontvanger_type = $('.zaak_aanmaken .ezra_id_ontvanger_type '
                   + ' .ezra_betrokkene_type input[type="radio"]:checked').val();
                $('.zaak_aanmaken .ezra_id_ontvanger_type').show();
            } else {
                $('.zaak_aanmaken .ezra_id_ontvanger_type').hide();
                $('.zaak_aanmaken .ezra_id_ontvanger').hide();
            }

            // Remember zaaktype function
            if ($('.zaak_aanmaken')
                    .closest('form')
                    .find('input[name="remembered_zaaktype_intern"]')
                    .length
            ) {
                var remembered = $('.zaak_aanmaken')
                    .closest('form')
                    .find('input[name="remembered_zaaktype_intern"]').val();

                remembered = remembered.split(';');

                remember_id = remembered[0];
                remember_naam = remembered[1];
            }
        }

        // Zaaktype onthouden
        $('.zaak_aanmaken input[name="zaaktype_name"]').val(remember_naam);
        $('.zaak_aanmaken input[name="zaaktype_id"]').val(remember_id);

        if (remember_id) {
            $('.zaak_aanmaken input[name="remember"]').attr('checked','checked');
        } else {
            $('.zaak_aanmaken input[name="remember"]').attr('checked',null);
        }

        /* Change betrokkene type in aanvrager selector */
        var rel = $('.zaak_aanmaken .ezra_id_aanvrager a').attr('rel');
        if (rel) {
            rel = rel.replace(
                /betrokkene_type: (.*?);/,
                'betrokkene_type: ' + betrokkene_type + ';'
            );

            $('.zaak_aanmaken .ezra_id_aanvrager a').attr('rel',rel);
        }
        rel = $('.zaak_aanmaken .ezra_id_ontvanger a').attr('rel');
        if (rel) {
            rel = rel.replace(
                /betrokkene_type: (.*?);/,
                'betrokkene_type: ' + ontvanger_type + ';'
            );

            $('.zaak_aanmaken .ezra_id_ontvanger a').attr('rel',rel);
        }

        /* Make sure triggers are enabled */
        $('.zaak_aanmaken .ezra_trigger input[type="radio"],'
            + '.zaak_aanmaken .ezra_id_aanvrager_type input[type="radio"],'
            + '.zaak_aanmaken .ezra_id_ontvanger_type input[type="radio"],'
            + '.zaak_aanmaken .ezra_id_bestemming input[type="radio"]'
        ).unbind().change(function() {
            $('form .zaak_aanmaken').trigger('refreshForm');
        });

        /* Change classes */
        var element = $('form .zaak_aanmaken');
        var classes = element.attr('class').split(/\s+/);

        var pattern = /^refreshform-/;

        for(var i = 0; i < classes.length; i++){
          var className = classes[i];

          if(className.match(pattern)){
            element.removeClass(className);
          }
        }

        $('form .zaak_aanmaken').addClass(
            'refreshform-trigger-' + ztc_trigger
        ).addClass(
            'refreshform-betrokkene_type-' + betrokkene_type
        );

        _load_zaaktypen(ztc_trigger, betrokkene_type,{
            formcontainer: '.zaak_aanmaken',
            trigger: ztc_trigger,
            betrokkene_type: betrokkene_type
        });

        $('.zaak_aanmaken').closest('form').unbind().submit(function() {
            return request_validation(
                $(this),
                null,
                {
                    events: {
                        submit: function (formelem) {
                            //formelem.find('input[type="submit"]').val('Bezig');
                            //formelem.find('input[type="submit"]').addClass('evenwachten');
                            //formelem.find('input[type="submit"]').attr('disabled','disabled');
                            formelem.submit();
                            $('#ezra_nieuwe_zaak_tooltip').trigger({
                                type: 'nieuweZaakTooltip',
                                hide: 1,
                                keeploader: 1
                                }
                            );
                        }
                    }
                }
            );
        });


        $('.ezra_zaaktype_keuze .ezra_kies_zaaktype')
            .addClass('ezra_zaaktype_keuze-initialized');
    });

    if ($('form .zaak_aanmaken').length) { $('.form .zaak_aanmaken').trigger('refreshForm'); }


    ezra_basic_selects();

    /* XXX Won't be used anymore on /zaak/create/balie, see above refreshForm.
     * this function is here for backwards compatibility
     */
    $('.ezra_zaaktype_keuze .ezra_kies_zaaktype').unbind().on('click', function() {
        var extra_options   = new Array();

        var formcontainer   = $(this).closest('form');

        var trigger         = formcontainer.find('input[name="ztc_trigger"]').val();
        var betrokkene_type = formcontainer.find('input[name="betrokkene_type"]:checked').val();

        extra_options['zt_trigger']         = trigger;
        extra_options['zt_betrokkene_type'] = betrokkene_type;


        /* Replace the above variables when we run this search through our new
         * zaak_aanmaken dialog
         */
        if (formcontainer.find('.zaak_aanmaken').length) {
            var zaak_aanmaken_classes = $('.zaak_aanmaken').attr('class').split(/\s+/);

            for (var i = 0; i < zaak_aanmaken_classes.length; i++) {
                if (zaak_aanmaken_classes[i].match(/refreshform-trigger/)) {
                    trigger = zaak_aanmaken_classes[i].match(/refreshform-trigger-(\w+)/);
                    trigger = trigger[1];
                    extra_options['zt_trigger']         = trigger;
                }

                if (zaak_aanmaken_classes[i].match(/refreshform-betrokkene_type/)) {
                    betrokkene_type = zaak_aanmaken_classes[i].match(/refreshform-betrokkene_type-(\w+)/);
                    betrokkene_type = betrokkene_type[1];
                    extra_options['zt_betrokkene_type'] = betrokkene_type;
                }
            }

            select_zaaktype('.zaak_aanmaken input[name="zaaktype_id"]', '.zaak_aanmaken .ezra_zaaktype_keuze_textbox', null, extra_options);
        } else {
            select_zaaktype('#start_' + trigger + ' .ezra_zaaktype_keuze input[name="zaaktype_id"]', '#start_' + trigger + ' .ezra_zaaktype_keuze_textbox', null, extra_options);
        }

        return false;
    });


    $('.ezra_zaaktype_keuze_textbox').unbind().focus(function() {
        var formcontainer   = $(this).closest('form');

        var trigger         = formcontainer.find('input[name="ztc_trigger"]').val();
        var betrokkene_type = formcontainer.find('input[name="betrokkene_type"]:checked').val();

        if (formcontainer.find('.zaak_aanmaken').length) {
            var zaak_aanmaken_classes = $('.zaak_aanmaken').attr('class').split(/\s+/);

            for (var i = 0; i < zaak_aanmaken_classes.length; i++) {
                if (zaak_aanmaken_classes[i].match(/refreshform-trigger/)) {
                    trigger = zaak_aanmaken_classes[i].match(/refreshform-trigger-(\w+)/);
                    trigger = trigger[1];
                }

                if (zaak_aanmaken_classes[i].match(/refreshform-betrokkene_type/)) {
                    betrokkene_type = zaak_aanmaken_classes[i].match(/refreshform-betrokkene_type-(\w+)/);
                    betrokkene_type = betrokkene_type[1];
                }
            }
        }

        _load_zaaktypen(trigger, betrokkene_type, {
            formcontainer: formcontainer,
            trigger: trigger,
            betrokkene_type: betrokkene_type
        });

    });

    $('.ezra_select_betrokkene input[type="text"]').attr('readonly','readonly');

    $(document).on('change', '.ezra_milestone_zaak_type', function() {
        var containingtr    = $(this).find(':selected').closest('tr');
        if (
            containingtr.hasClass('ezra_table_row_template') ||
            containingtr.hasClass('row_template') ||
            containingtr.is(':hidden')
        ) {
            return true;
        }

        var starten_input   = containingtr
            .find('.ezra_milestone_zaak_type_starten input[type="text"]');

        if (!starten_input.length) {
            return false;
        }

        if (containingtr.find(':selected').hasClass('has_start_delay')) {
            containingtr.find('.ezra_milestone_zaak_type_starten *').css('visibility','visible');
        } else {
            containingtr.find('.ezra_milestone_zaak_type_starten *').css('visibility','hidden');
        }

        if (containingtr.find(':selected').hasClass('vervolgzaak_datum')) {
            starten_input
                .attr('size','10')
                .datepicker({
                    dateFormat: 'dd-mm-yy',
                    changeYear: true,
                    'beforeShow': function(input, datepicker) {
                        setTimeout(function() {
                            $('#ui-datepicker-div').css('zIndex', 10000);
                        }, 250);
                    }
                });

            containingtr.find('.label_dagen').hide();

            if ( !starten_input.val().match(/^\d+\-\d+\-\d+$/) ) {
                starten_input.val('');
            }

            return true;
        } else {
            starten_input
                .attr('size','4')
                .datepicker('destroy');

            containingtr.find('.label_dagen').show();

            if (starten_input.val() && !starten_input.val().match(/^\d+$/) ) {
                starten_input.val('0')
            }
        }
    });

    $('.ezra_milestone_zaak_type').change();

}



function ezra_basic_selects() {

    /* LOOK BELOW FOR VERSION 3 EXAMPLE, this one sucks ass */
    $(document).on('click', '.ezra_search_betrokkene, #ezra_input_search_betrokkene_intern, #ezra_input_search_betrokkene_extern', function() {
    
        var formcontainer   = $(this).closest('form');

        var options         = getOptions($(this).attr('rel'));
    
        var trigger         = formcontainer.find('input[name="ztc_trigger"]').val();

        var betrokkene_type;
        if (options['betrokkene_type']) {
            betrokkene_type     = options['betrokkene_type'];
        } else {
            if (formcontainer.find('input[name="betrokkene_type"]').attr('type') == 'radio') {
                betrokkene_type = formcontainer.find('input[name="betrokkene_type"]:checked').val();
            } else {
                betrokkene_type = formcontainer.find('input[name="betrokkene_type"]').val();
            }
        }

        var title           = $(this).attr('title');

        $('#searchdialog .dialog-content').load(
            '/betrokkene/search',
            {
                jsfill: trigger,
                jstype: betrokkene_type,
                jsversion: 2
            },
            function() {
                openSearchDialog(title);
            }
        );
        return false;
    });
/*
    $('#ezra_input_search_betrokkene').click(function(){
           window.open($('.ezra_search_betrokkene').attr('href'));
              return false;
              });
*/


    /* VERSION 3 EXAMPLE!! */
    $('.ezra_betrokkene_selector').click(function() {
        var formcontainer   = $(this).closest('form');
        var aelem;

        /* Search for the href containing rel */
        if (!$(this).attr('rel')) {
            aelem   = $(this).closest('div').find('a.ezra_betrokkene_selector');
        } else {
            aelem   = $(this);
        }

        var options         = getOptions(aelem.attr('rel'));
        var title           = aelem.attr('title');

        if (!options['betrokkene_type'] && !options['betrokkene_type_selector']) {
            return false;
        }

        /* No betrokkene_type given OR no handler to a selector */
        if (options['betrokkene_type_selector']) {
            var selector = $(options['betrokkene_type_selector']);

            if (selector.find('input[type="radio"]').length) {
                options['betrokkene_type'] = selector.find('input[type="radio"]:checked').val();
            }
        }

        if (!options['selector_identifier']) { return false; }

        $('#searchdialog .dialog-content').load(
            '/betrokkene/search',
            {
                ezra_client_info_selector_identifier: options['selector_identifier'],
                ezra_client_info_selector_naam: options['selector_naam'],
                betrokkene_type: options['betrokkene_type'],
                jsversion: 3
            },
            function() {
                openSearchDialog(title);
            }
        );
        return false;
    });

    $('.ezra_org_eenheid').change(function() {
        var container = $(this).parents('div.ezra_select_betrokkene');

        container.find('input[name="ztc_aanvrager_id"]').val($(this).val());
    });
}


function trim(value) {
    value = value.replace(/^\s+/,'');
    value = value.replace(/\s+$/,'');
    return value;
}

function ezra_basic_widget_auth() {
    $('.widget_auth_select select.auth_select_ou').each(function() {
        $(this).change(function() {
            var container = $(this).closest('.widget_auth_select');
            $(this).find(':selected').each(function() {
                var elementcontent = trim($(this).html());
                elementcontent = elementcontent.replace(/^(&nbsp;)*/,'');
                elementcontent = elementcontent.replace(/&amp;/,'&');
                /* Refresh roles based on scope data */
                $.getJSON(
                    '/auth/retrieve_roles/' + $(this).val(),
                    function(data) {
                        var roles = data.json.roles;

                        var role_select = container.find('select.auth_select_role');

                        /* Remove old roles */
                        role_select.empty();
                        for (var i in roles) {
                            var role=roles[i];
                            if (role.ou_id) {
                                role_select.append('<option value="' + role.role_id
                                    + '"> &nbsp;&nbsp;' + role.label + '</option>');
                            } else {
                                role_select.append('<option value="' + role.role_id
                                    + '">' + role.label + '</option>');
                            }
                        }
                    }
                );
            });
        });

        //$(this).change();
    });
}


function beheer_zaaktype_auth_add() {
    $('.element_tabel_auth thead').show();
    $('.element_tabel_auth .auth_message').hide();
}

function beheer_zaaktype_auth_delete() {
    var count = $('.element_tabel_auth table tr').size();
    if(count < 3) {
        $('.element_tabel_auth thead').hide();
        $('.element_tabel_auth .auth_message').show();
    }
}


function ezra_basic_widget_term(elem, changed) {
    widget_content  = elem.closest('div').find('.widget_term_content');
    widget_value    = elem.find(':selected').val();

    /* Remove value from datepicker */
    if (widget_value == 'einddatum') {
        widget_content.attr('size', '10');
        widget_content.datepicker({
            dateFormat: 'dd-mm-yy'
        });
        if (changed) {
            widget_content.val('');
            widget_content.datepicker('show');
        }
    } else {
        if (changed && widget_content.attr('size') != 2) {
            widget_content.val('');
        }
        widget_content.attr('size', '2');
        widget_content.datepicker('destroy');
    }
}

function ezra_basic_zaak_functions() {
    if (!$('#zaak_zaakinformatie_accordion').hasClass('ui-accordion')) {
        $('#zaak_zaakinformatie_accordion').accordion({
            autoHeight: false,
            active: false,
            change: function(event,ui) {
                if (
                    ui.newHeader.hasClass('ezra_load_zaak_element') &&
                    !ui.newHeader.hasClass('ezra_load_zaak_element_loaded')
                ) {
                    ui.newHeader.find('img').show();

                    var match = ui.newHeader.attr('class').match(/zaak_nr_(\d+)/);
                    var zaaknr = match[1];

                    var element_url = '/zaak/' + zaaknr + '/view_element/' + ui.newHeader.attr('id');
                    if (ui.newHeader.hasClass('pip')) {
                        element_url = '/pip' + element_url;
                    }

                    ui.newContent.load(
                        element_url,
                        function(response,status,xhr) {
                            if (status!="error") {
                                ui.newHeader.find('img').hide();
                                if (ui.newHeader.hasClass('element_maps')) {
                                    ezra_gmaps();
                                }

                                ezra_basic_functions();
                            }
                        }
                    );

                    ui.newHeader.addClass('ezra_load_zaak_element_loaded');
                }
            },
            collapsible: true
        });
    }

    $('.submitWaiter').each(function() {
        $(this).find('form').submit(function() {
            $.ztWaitStart();
        });
    });
}

function ezra_document_functions() {
    $('.ezra_view_sjabloon form').unbind().submit(function() {
        $('#dialog').dialog('close');
        return true;
    });

    $('.select_zt_document').unbind().change(function() {
        var selected    = $(this).find(':selected');
        var currentform = $(this).closest('form');

        var zaaknr      = $(this).attr('class');
        zaaknr          = zaaknr.replace(/.*zaak_(\d+).*/, '$1');
        var zaakdef     = 0;

        if (!zaaknr.match(/^\d+$/)) {
            if (zaaknr.match(/zaakdefinitie/)) {
                zaakdef = zaaknr.replace(/.*zaakdefinitie_(\d+).*/, '$1');
                zaaknr  = '';
            }
        }

        currentform.find('.document_constraint_false').hide();
        currentform.find('.document_constraint_true').hide();

        if ($(this).val()) {
            currentform.find('.document_constraint_true').show();

            $.getJSON('/zaak/' + (zaaknr ? zaaknr : 'documents') + '/get_catalogus_waarden/'
                + selected.val(),
                {
                    zaakdefinitie: zaakdef
                },
                function(data) {
                    var catalogus = data.json.catalogus;

                    currentform.find('.document_constraint_pip').html(
                        (catalogus.pip ? 'Ja' : 'Nee')
                    );
                    currentform.find('.document_constraint_verplicht').html(
                        (catalogus.verplicht ? 'Ja' : 'Nee')
                    );
                    currentform.find('.document_constraint_categorie').html(
                        catalogus.categorie
                    );


                }
            );
        } else {
            currentform.find('.document_constraint_false').show();
        }
    });

    $('.select_zt_document').change();

    ezra_basic_zaak_functions();
}
var m;
 var map;var start;
 
 
 /*
 
 */


function js_include(filename)
{
	var head = document.getElementsByTagName('head')[0];
	
	script = document.createElement('script');
	script.src = filename;
	script.type = 'text/javascript';
	
	head.appendChild(script)
}

function ezra_gmaps()
{
 	ezra_openlayers();
}


var marker;

function ezra_openlayers()
{
    /*
        TODO Open layers integratie
    */

    OpenLayers.Layer.OSM.MapnikLocalProxy = OpenLayers.Class(OpenLayers.Layer.OSM, {
        /**
         * Constructor: OpenLayers.Layer.OSM.MapnikLocalProxy
         *
         * Parameters:
         * name - {String}
         * options - {Object} Hashtable of extra options to tag onto the layer
         */
        initialize: function(name, options) {
            var url = [
                "/maps-tiles/${z}/${x}/${y}.png"
            ];
            options = OpenLayers.Util.extend({ numZoomLevels: 19 }, options);
            var newArguments = [name, url, options];
            OpenLayers.Layer.OSM.prototype.initialize.apply(this, newArguments);
        },
     
        CLASS_NAME: "OpenLayers.Layer.OSM.MapnikLocalProxy"
    });

    var lat = $('input[name=latitude]').val();
    var lon = $('input[name=longitude]').val();
    var zoom = 3;

    if ($("#ezramap").hasClass('olMap')) {
        return;
    }
    $("#ezramap").css({width:"400px",height:"300px"})


    var map = new OpenLayers.Map("ezramap");

    if ("https:" == document.location.protocol) {
        mapnik = new OpenLayers.Layer.OSM.MapnikLocalProxy();
    } else {
        mapnik = new OpenLayers.Layer.OSM();
    }

    map.addLayer(mapnik);
    map.setCenter(new OpenLayers.LonLat(lon,lat) // Center of the map
         .transform(
            new OpenLayers.Projection("EPSG:4326"), // transform from WGS 1984
            new OpenLayers.Projection("EPSG:900913") // to Spherical Mercator Projection
          ), 13 // Zoom level
    );

    // Layer toevoegen voor de marker(s)
    markers = new OpenLayers.Layer.Markers( "Markers" );
    map.addLayer(markers);


    if (
        $('.ezramap_container input[type="text"]').length ||
        $('.ezramap_container input[type="hidden"]').length
    ) {
        var address = $('.ezramap_container input[type="text"]').val()
            || $('.ezramap_container input[type="hidden"]').val();

        $.getJSON('/plugins/maps/retrieve',
            {'query':address}, 
            function(data) {
                if (data.json.maps.succes == '1')
                {
                    var geo = data.json.maps.coordinates.split(' ');
                    lat = geo[0];
                    lon = geo[1];
                    var lonlat = new OpenLayers.LonLat(lon,lat);
                    map.setCenter(lonlat // Center of the map
                      .transform(
                        new OpenLayers.Projection("EPSG:4326"), // transform from WGS 1984
                        new OpenLayers.Projection("EPSG:900913") // to Spherical Mercator Projection
                      ), 15 // Zoom level
                    );
                    var size = new OpenLayers.Size(21,25);
                    var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
                    var icon    = new OpenLayers.Icon('/tpl/zaak_v1/nl_NL/images/marker.png', size, offset);
                    marker = new OpenLayers.Marker(lonlat,icon.clone());
                    markers.addMarker(marker);
                }
            }
        );
    }

        function handleMapClick(e) {

            var lonlat = map.getLonLatFromViewPortPx(e.xy);
            var popup;

            lonlat.transform(
                new OpenLayers.Projection("EPSG:900913"),
                new OpenLayers.Projection("EPSG:4326") // to Spherical Mercator Projection
            );
            $.getJSON('/plugins/maps/retrieve',
                {'query':lonlat.lat+' '+lonlat.lon}, 
                function(data) 	{
                    if (data.json.maps.succes == '1')
                    {
                        var geo = data.json.maps.coordinates.split(' ');
                        lat = geo[0];
                        lon = geo[1];
                        var lonlat = new OpenLayers.LonLat(lon,lat);
                        lonlat // Center of the map
                          .transform(
                            new OpenLayers.Projection("EPSG:4326"), // transform from WGS 1984
                            new OpenLayers.Projection("EPSG:900913") // to Spherical Mercator Projection
                          );
                        //setMarker(lonlat,1);
                        //return;
                        if (marker && marker.isDrawn()) {
                            marker.destroy();

                            if (popup) {
                                popup.destroy();
                            }
                        }

                        $('.ezramap_container input[type="text"]').val(data.json.maps.adres);
                        setMarker(lonlat);
                        var size = new OpenLayers.Size(21,25);
                        var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
                        var icon    = new OpenLayers.Icon('/tpl/zaak_v1/nl_NL/images/marker.png', size, offset);
                        marker = new OpenLayers.Marker(lonlat,icon.clone());
                        markers.addMarker(marker);
                        popup = new OpenLayers.Popup.AnchoredBubble("Test",
                            lonlat,
                             new OpenLayers.Size(150,60),
                             "<font size=-2>"+data.json.maps.adres);
                        map.addPopup(popup);
                        popup.hide();
                        popup.opacity=0.5;
                        marker.events.register('mouseover', marker, function (e) { popup.toggle(); OpenLayers.Event.stop (e); } );
                        marker.events.register('mouseout', marker, function (e) { popup.hide(); OpenLayers.Event.stop (e); } );
                    } else {
                        $('.ezramap_container input[type="text"]').val('Fout bij het ophalen van adres');
                    }
                }
            );
        }

        function setMarker(lonLatMarker){
            var feature = new OpenLayers.Feature(markers, lonLatMarker);
            feature.closeBox = true;
            feature.popupClass = OpenLayers.Class(OpenLayers.Popup.AnchoredBubble, {minSize: new OpenLayers.Size(300, 180) } );
            feature.data.popupContentHTML = 'Hello World';
            feature.data.overflow = "hidden";

            var size = new OpenLayers.Size(21,25);
            var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
            var icon    = new OpenLayers.Icon('/tpl/zaak_v1/nl_NL/images/marker.png', size, offset);
            var marker = new OpenLayers.Marker(lonLatMarker, icon);
            marker.feature = feature;

            var markerClick = function(evt) {
                if (this.popup == null) {
                    this.popup = this.createPopup(this.closeBox);
                    map.addPopup(this.popup);
                    this.popup.show();
                } else {
                    this.popup.toggle();
                }
                OpenLayers.Event.stop(evt);
            };
            marker.events.register("mousedown", feature, markerClick);

            markers.addMarker(marker);
        }

        map.events.register('click', map, handleMapClick);
//    }
}

var SHADOW_Z_INDEX = 10;
var MARKER_Z_INDEX = 11;
var DIAMETER = 200;
var NUMBER_OF_FEATURES = 15;

function drawFeatures() {
}

function ezra_maps_retrieve(query)
{
    $.getJSON('/plugins/maps/retrieve',
        {'query':query}, 
        function(data) 	{
            if (data.json.maps.succes == '1')
            {
                var address = $('.ezramap_container input[type="hidden"]').val(data.json.maps.adres);
            } else {
            }
        }
    );
}


function ezra_update_address(place, position) {
    $('.ezramap_container input[type="text"]').val(place.address);
}

function ezra_gmaps_initialize() {
    map = new GMap2(m);
    map.setCenter(start, 13);
    map.addControl(new GLargeMapControl());
    map.addControl(new GMapTypeControl());
    map.addControl(new GScaleControl());
    geocoder = new GClientGeocoder();

    if ($('.ezramap_container input[type="hidden"]').length) {
        var address = $('.ezramap_container input[type="hidden"]').val();
        geocoder.getLatLng(
          address,
          function(point) {
            if (!point) {
                return;
            } else {
              map.setCenter(point, 13);
              var marker = new GMarker(point);
              map.addOverlay(marker);
              // marker.openInfoWindowHtml(address);
            }
          }
        );
    } else {
        GEvent.addListener(map, "click", getAddress);
    }
    $('#tabinterface').bind('tabsshow', function(event, ui) {
        if (ui.panel.id == "zaak-elements-case") {
            map.checkResize();
        }
    });
    $('#zaak_zaakinformatie_accordion').bind(
            'accordionchange',
            function (event,ui) {
                map.checkResize();
            }
    );
}

function getAddress(overlay, latlng) {
    if (latlng != null) {
        address = latlng;
        geocoder.getLocations(latlng, showAddress);
    }
}

function showAddress(response) {
    map.clearOverlays();
    if (!response || response.Status.code != 200) {
        alert("Google kan momenteel niet aan deze aanvraag voldoen");
    } else {
        place = response.Placemark[0];
        point = new GLatLng(
            place.Point.coordinates[1],
            place.Point.coordinates[0]
        );

        marker = new GMarker(point, { draggable: true });
        map.addOverlay(marker);

        marker.openInfoWindowHtml(
            '<b>Exacte locatie: </b>' + place.Point.coordinates[1] + ", " + place.Point.coordinates[0] + '<br>' +
            '<b>Adres: </b>' + place.address + '<br>'
        );

        GEvent.addListener(marker, 'dragend', function(position) {
                // position is a GLatLng containing the position of
                // of where the marker was dropped
                getAddress(null, position);
        });

        ezra_update_address(place, point);
    }
}

function ezra_basic_functions() {
    veldoptie_handling();
    if ($('.ezramap_container').length) {
        ezra_gmaps();
    }

    ezra_document_functions();

    /* Documentenintake */
    ezra_documentenintake_functions();

    $('.ztAjaxUpdate').ztAjaxUpdate();
    $('.ztSpinnerWait').submit(function() {
        $.ztWaitStart();
    });

    $("input[type=radio], input[type=checkbox]").css({border:0});


    /* View betrokkene */
    $(document).on('click', '.betrokkene-get', function() {
        rel     = $(this).attr('rel');

        if (!rel) {
            return false;
        }

        options = getOptions(rel);

        id      = options['id'];
        zaak    = options['zaak'];

        title   = $(this).attr('title');
        var actueel = options['actueel'];

        if (!id) {
            return false;
        }

        $('#dialog .dialog-content').load('/betrokkene/get/'
            + id,
            {
                zaak: zaak,
                actueel: actueel
            },
            function() {
                openDialog(title, 600, 500);
            }
        );

        return false;
    });


    $('.fire-dialog').unbind().click(function() {
        fireDialog($(this));
        return false;
    });

    ezra_basic_beheer_functions();
    ezra_basic_zaak_intake();
    
    $('#regel_definitie').regel_editor();
}


function ezra_documentenintake_functions() {
    $('#ezra_documenten_wachrij_bijwerken').click(function() {
        $.ztWaitStart();
        var lochref= $(this).attr('href');
        $.post(
            '/zaak/intake/load',
            null,
            function() {
                window.location = lochref;
            }
        );

        return false;
    });
}


function veldoptie_handling() {
    /* multiple veldopties */
    $(document).off('click', '.veldoptie_multiple .add')
        .on('click', '.veldoptie_multiple .add', function() {
            var lastrow = $(this).closest('div').find('li:last');
            var clone = lastrow.clone();
            clone.find('input')
                .val('')
                .attr('selected', null)
                .attr('checked', null);
            clone.find('textarea').val('');
            clone.find('option').attr('selected',null);

            lastrow.after(clone);
            updateDeleteButtons();
            return false;
        });

    updateDeleteButtons();

    $(document).off('click', '.veldoptie_multiple .del')
        .on('click', '.veldoptie_multiple .del', function() {
            var myrow = $(this).closest('li');
            myrow.remove();
            updateDeleteButtons();
            return false;
        });
    /* ----------------- */

    $('.veldoptie_datepicker').each(function() {
        id  = $(this).attr('id');
        $('#' + id).datepicker({
            dateFormat: 'dd-mm-yy',
            changeYear: true,
            yearRange: '1900:c+20',
            regional: 'nl',
            'beforeShow': function(input, datepicker) {
                setTimeout(function() {
                    $('#ui-datepicker-div').css('zIndex', 10000);
                }, 250);
            }
        });
    });

    $('.veldoptie_datepicker_begindate').each(function() {
        id  = $(this).attr('id');
        $('#' + id).datepicker({
            dateFormat: 'dd-mm-yy',
            minDate: '+0',
            changeYear: true,
            regional: 'nl',
            'beforeShow': function(input, datepicker) {
                setTimeout(function() {
                    $('#ui-datepicker-div').css('zIndex', 10000);
                }, 250);
            }
        });
    });


    $('.veldoptie_valuta').each(function() {
        veldoptie_valuta_calc($(this));
        $(this).find('input').keyup(function() {
            /* Recalculate valuta */
            parentdiv = $(this).closest('div');
            veldoptie_valuta_calc(parentdiv);
        });
    });

    $(document).on('keyup', '.veldoptie_text_uc', function() {
        $(this).val($(this).val().toUpperCase());
    });
    $(document).on('keyup', '.veldoptie_numeric', function() {
        $(this).val($(this).val().replace(/[^0-9]/g,''));
    });

    var bag_results = {};
    if ($('.veldoptie_bag_adres_container').length) {
        //alert($('.veldoptie_bag_adres_uitvoer input[type="text"]:disabled').length);


        $('.veldoptie_bag_adres.invoer.huisnummer').keydown(function() {
            var postcodefield   = $(this).closest('div.veldoptie_bag_adres_container').find('.veldoptie_bag_adres.invoer.postcode');
            var straatfield     = $(this).closest('div.veldoptie_bag_adres_container').find('.veldoptie_bag_adres.invoer.straatnaam');

            var uitvoercontainer = $(this).parents('div.veldoptie_bag_adres_container').find('.veldoptie_bag_adres_uitvoer');

            if (postcodefield.length) {
                if (postcodefield.val() && postcodefield.val().match(/^\d{4} ?\w{2}$/)) {
                    if ($(this).attr('disabled')) {
                        $(this).attr('disabled',null);
                    }
                } else {
                    $(this).attr('disabled','disabled');
                    alert('Voer een geldige postcode in a.u.b., in de vorm 1400AA');
                }

                /* Wipe data from adres */
                uitvoercontainer.find('.huisnummer').val('');
                uitvoercontainer.find('.bagid').val('');
                uitvoercontainer.find('.straatnaam').val('');
            }


            if (straatfield.length) {
                if (straatfield.val() && uitvoercontainer.find('.straatnaam').val()) {
                    if ($(this).attr('disabled')) {
                        $(this).attr('disabled',null);
                    }
                } else {
                    $(this).attr('disabled','disabled');
                    alert('Voer een geldige straatnaam in a.u.b.');
                }
            }

            return true;

        });

        $('.veldoptie_bag_adres.invoer.huisnummer').unbind('blur').blur(function() {
            var uitvoercontainer = $(this).closest('div.veldoptie_bag_adres_container')
            var itemvalue = $(this).val();

            if (!bag_select_result(uitvoercontainer, itemvalue)) {
                $(this).val('');
            }
        });

        $('.veldoptie_bag_adres.invoer.huisnummer').click(function() {
            var postcodefield   = $(this).closest('div.veldoptie_bag_adres_container').find('.veldoptie_bag_adres.invoer.postcode');
            var straatfield     = $(this).closest('div.veldoptie_bag_adres_container').find('.veldoptie_bag_adres.invoer.straatnaam');

            var uitvoercontainer = $(this).parents('div.veldoptie_bag_adres_container').find('.veldoptie_bag_adres_uitvoer');

            if (postcodefield.length) {
                if (postcodefield.val() && postcodefield.val().match(/^\d{4} ?\w{2}$/)) {
                    if ($(this).attr('disabled')) {
                        $(this).attr('disabled',null);
                    }
                } else {
                    $(this).attr('disabled','disabled');
                    alert('Voer een geldig postcode in a.u.b., in de vorm 1400AA');
                }
            }

            if (straatfield.length) {
                if (straatfield.val() && uitvoercontainer.find('.straatnaam').val()) {
                    if ($(this).attr('disabled')) {
                        $(this).attr('disabled',null);
                    }
                } else {
                    $(this).attr('disabled','disabled');
                    alert('Voer een geldige straatnaam in a.u.b.');
                }
            }
        });

        $('.veldoptie_bag_adres.invoer.straatnaam').keydown(function() {
            /* Wipe data from adres */
            var uitvoercontainer = $(this).parents('div.veldoptie_bag_adres_container').find('.veldoptie_bag_adres_uitvoer');

            uitvoercontainer.find('.bagid').val('');
            uitvoercontainer.find('.straatnaam').val('');
        });


        $('.veldoptie_bag_adres.invoer.postcode').keydown(function() {
            $(this).closest('div.veldoptie_bag_adres_container').find('.veldoptie_bag_adres.invoer.huisnummer').attr('disabled',null);
        });
        $('.veldoptie_bag_adres.invoer.straatnaam').keydown(function() {
            $(this).closest('div.veldoptie_bag_adres_container').find('.veldoptie_bag_adres.invoer.huisnummer').attr('disabled',null);
        });

        $('.veldoptie_bag_adres_container .del').click(function() {
            $(this).closest('tr').remove();
            return false;
        });

        $('.veldoptie_bag_adres_container .add').click(function() {
            var uitvoer_container   = $(this).parents('div.veldoptie_bag_adres_container').find('div.veldoptie_bag_adres_uitvoer');
            var adressen_table      = uitvoer_container.parents('div.veldoptie_bag_adres_container')
                .find('table.bag_adressen');

            var veldoptie_type      = uitvoer_container.find('.veldoptie_type').val();

            var straatnaam          = uitvoer_container.find('.straatnaam').val();
            var adres               = straatnaam;

            if (veldoptie_type == 'bag_adres' || veldoptie_type == 'bag_adressen') {
                var nummeraanduiding    = uitvoer_container.find('.huisnummer').val();
                adres                   = adres + ' ' + nummeraanduiding;
            }

            var bagid               = uitvoer_container.find('.bagid').val();
            var bagid_veldoptie     = uitvoer_container.find('.bagid').attr('name');
            bagid_veldoptie         = bagid_veldoptie.replace('_not','');


            if (!bagid) {
                return false;
            }

            adressen_table.find('tr:last')
                .after(
                    '<tr>' +
                    '<td class="straatnaam">' +
                        '<input type="hidden" name="' + bagid_veldoptie
                            + '" value="' + bagid + '" />' + adres +
                       '</td>'
                    + '<td class="actie"><a href="#" class="del">'
		    + '</a></td>'
                    + '</tr>'
                );

            adressen_table.find('tr:last .del').click(function() {
                $(this).closest('tr').remove();
                if(adressen_table.find('tr').size() < 2) {
                    adressen_table.removeClass('bag_adressen_padding');
                }                
                return false;
            });

            if(adressen_table.find('tr').size() > 1) {
                adressen_table.addClass('bag_adressen_padding');
            }

            return false;
        });


        $('.veldoptie_bag_adres.invoer.autocomplete').autocomplete(
           {
                source: function (tag,response) {
                    var qparams         = {};
                    var searchtype      = 'hoofdadres';
                    if (this.element.hasClass('huisnummer')) {
                        if (this.element
                            .closest('div.veldoptie_bag_adres_invoer').find('.postcode')
                            .length
                        ) {
                            qparams.postcode    = this.element
                                .closest('div.veldoptie_bag_adres_invoer').find('.postcode')
                                .val();
                            qparams.postcode    = qparams.postcode.replace(' ','');
                        }
                        var straatnaam_element = this.element
                            .closest('div.veldoptie_bag_adres_invoer').find('.straatnaam');
                            
                        if (straatnaam_element.length) {
                        	var straatnaam = straatnaam_element.val();
                        	straatnaam = straatnaam.replace(/.*\> /, "");
                            qparams.straatnaam  = straatnaam;
                        }
                        qparams.huisnummer  = this.element.val();
                    } else {
                        qparams.straatnaam  = this.element.val();
                        searchtype          = 'openbareruimte';
                    }

                    $.ajax({
                        url: '/gegevens/bag/search?json_response=1&searchtype=' + searchtype,
                        dataType: 'json',
                        data: qparams,
                        async: false,
                        success: function (data) {
                            var results = data.json.entries;

                            var responsen = [];

                            for (var i in results) {
                                var bag=results[i];

                                var responsetag = '';

                                if (searchtype == 'hoofdadres') {
                                    responsetag = String(bag.nummeraanduiding);
                                    straatnaam  = String(bag.woonplaats + ' > ' + bag.straatnaam);
                                } else {
                                    straatnaam  = String(bag.woonplaats + ' > ' + bag.straatnaam);
                                    responsetag = String(straatnaam);
                                }

                                responsen.push(responsetag);

                                bag_results[responsetag] = {
                                    identificatie: bag.identificatie,
                                    nummeraanduiding: String(bag.nummeraanduiding),
                                    straatnaam: bag.straatnaam,
                                    woonplaats: bag.woonplaats
                                }
                            }

                            response(responsen);
                        }
                    });
                },
                select: function(event, ui) {
                    var uitvoercontainer = $(this).closest('div.veldoptie_bag_adres_container')
                        .find('.veldoptie_bag_adres_uitvoer');
                    bag_select_result(uitvoercontainer, ui.item.value);
                }
            }
        );
    }

    function bag_select_result(uitvoercontainer, itemvalue) {
        var veldoptie_type = uitvoercontainer.find('.veldoptie_type').val();

        if (!bag_results[itemvalue]) {
            var currenttr = uitvoercontainer.closest('tr');
            currenttr.find('.validator').addClass('invalid').show();

            var errormsg = '<span></span> Combinatie postcode + huisnummer niet gevonden';

            if (
                veldoptie_type == 'bag_straat_adres' || veldoptie_type == 'bag_straat_adressen'
            ) {
                errormsg = '<span></span> Adres onvolledig, of niet gevonden';
            }

            currenttr.find('.validate-content').html(errormsg);
            return false;
        }

        uitvoercontainer.find('.straatnaam').val(
            bag_results[itemvalue].straatnaam
        );

        var do_update = false;
        if (
            veldoptie_type == 'bag_adres' || veldoptie_type == 'bag_adressen' ||
            veldoptie_type == 'bag_straat_adres' || veldoptie_type == 'bag_straat_adressen'
        ) {
            if (bag_results[itemvalue].nummeraanduiding) {
                if (
                    bag_results[itemvalue].nummeraanduiding &&
                    bag_results[itemvalue].nummeraanduiding != 'null'
                ) {
                    uitvoercontainer.find('.huisnummer').val(
                        bag_results[itemvalue].nummeraanduiding
                    );
                    do_update = true;
                }
                uitvoercontainer.find('.bagid').val(
                    bag_results[itemvalue].identificatie
                );
            }
        } else {
            uitvoercontainer.find('.bagid').val(
                bag_results[itemvalue].identificatie
            );
        }

        var currenttr = uitvoercontainer.closest('tr');
        currenttr.find('.validator').addClass('invalid').hide();

        if($('form[name=search_filters]') && do_update == true) {
            //XXX 20111007 JW?? Waarom niet gewoon bij de knop: opslaan van de adres
            // dialog? Nu sluit het schermpje vanzelf, en krijgt het
            // klaarblijkelijk geen tijd om de waarden door te gevan

            //updateSearchFilters();
        }

        return true;
    }

}


//
// slightly different approach, html is created serverside, we only copy existing html
// that means we can't delete the last row.. we wouldn't have anything left to copy
//
function updateDeleteButtons() {
    $('.veldoptie_multiple').each( function() {
        var count = $(this).find('.del').length;
        if(count == 1) {
            $(this).find('.del').hide();
        } else {
            $(this).find('.del').show();
        }
    });
}



function veldoptie_valuta_calc(vname) {
    var eur = vname.find('input[name^="eur"]').val();
    var cnt = vname.find('input[name^="cnt"]').val();

    if (eur == '' && cnt == '') {
        vname.find('input[type="hidden"]').val(null);
        vname.find('.value').html(null);
        return;
    }

    if (!eur) {
        eur = 0;
    }

    if (!cnt) {
        cnt = 0;
    }

    if (eur == 0 && cnt == 0) {
        vname.find('input[type="hidden"]').val(0);
        vname.find('.value').html(0);
        return;
    }

    var valuta      = eur + '.' + cnt;
    var infovalue   = vname.find('.value');

    vname.find('input[type="hidden"]').val(valuta);

    if (infovalue.hasClass('exclbtw')) {
        infovalue.html(Math.round((valuta * 119)) / 100);
    } else if (infovalue.hasClass('inclbtw')) {
        infovalue.html(Math.round((valuta / 0.0119)) / 100);
    }
}
function openDialog(title, width, height) {
    if (!width) {
        width   = 960;
        height  = 'auto';
    }

    $('#dialog').dialog('option', 'width', width);
    $('#dialog').dialog('option', 'height', height);
    $('#dialog').dialog('option', 'maxHeight', 400);
    $('#dialog').dialog('option', 'resizable', false); 
    $('#dialog').dialog('option', 'zIndex', 3000); 
  
    $('#dialog').data('title.dialog', title);
    $('#dialog').addClass('smoothness').dialog('open')/*.parent().css({position:"fixed"})*/;

    
    $('#accordion').accordion({
        autoHeight: false
    });

    var d = $("#dialog").offset();
    window.scrollTo( d.left , (d.top - 80));

    ezra_tooltip_handling();
}

function openSearchDialog(title, width, height) {
    if (!width) {
        width   = 790;
        height  = 'auto';
    }

    $('#searchdialog').dialog('option', 'width', width);
    $('#searchdialog').dialog('option', 'height', height);

    $('#searchdialog').dialog('option', 'resizable', false);
    $('#searchdialog').dialog('option', 'maxHeight', 500);
    $('#searchdialog').dialog('option', 'zIndex', 3000);

    $('#searchdialog').data('title.dialog', title);
    $('#searchdialog').addClass('smoothness').dialog('open');
    
    $('#accordion').accordion({
       autoHeight: false
    });

    var d = $("#searchdialog").offset();
    window.scrollTo( d.left , (d.top - 80));
}

function getOptions(options) {
    var rv = {};

    if (!options) { return {}; }

    /* Get sets */
    sets = options.split(/;/);

    for(i = 0; i < sets.length; i++) {
        set     = sets[i];
        keyval  = set.split(/:/);
        key     = keyval[0];
        key     = key.replace(/^\s+/g, '');
        key     = key.replace(/\s+$/g, '');
        value   = keyval[1];
        if (!value) { continue; }
        value   = value.replace(/^\s+/g, '');
        value   = value.replace(/\s+$/g, '');
        rv[key] = value;
    }

    return rv;
}

function fireDialog(elem, callback) {
	
	$.ztWaitStart();
	
    /* Load options */
    rel     = elem.attr('rel');
    options = getOptions(rel);

    title = elem.attr('title');
    url   = elem.attr('href');
    
    if (!callback) {
        if (options['callback']) {
            callback = options['callback'] + '();';
        }
    }
    /* Options ok, load popup */
    $('#dialog .dialog-content').load(
        url,
        options,
        function() {
            if (callback) {
                eval(callback);
            }
            $.ztWaitStop();

            ezra_basic_functions();

            $('form.zvalidate').submit(function() {
                return zvalidate($(this));
            });

            openDialog(title, options['width'], options['height']);
        }
    );
}


function searchBetrokkene(elem) {
    id      = elem.parent('div').attr('id');
    rel     = elem.attr('rel');
    dtitle  = elem.attr('title');

    if (!rel) {
        return false;
    }

    options = rel.split(/;/);

    /* Load options */
    container_id = id;
    btype        = options[0];

    $('#searchdialog .dialog-content').load(
        '/betrokkene/search',
        {
            jsfill: container_id,
            jstype: btype,
            jsversion: 2
        },
        function() {
            title = 'Zoek  (' + btype + ')';
            openSearchDialog(dtitle);
        }
    );
}

function searchZaak(elem) {
    id      = elem.parent('div').attr('id');
    rel     = elem.attr('rel');
    dtitle  = elem.attr('title');

    options = getOptions(rel);

    /* Load options */
    container_id = id;

    $('#searchdialog .dialog-content').load(
        '/search',
        {
            jsfill: container_id,
            jsversion: 2
        },
        function() {
            openSearchDialog(dtitle);
        }
    );
}


// TODO: organise the init of all these things. when pages are refreshed with AJAX,
// loads of functions have to be called to get all the jquery stuff working. a strategy is necessary.
// options: 
// - every single init goes into one master function, this function is called with document.ready and
//   every AJAX load call (including dialogs)
// - inits are divided by subgroup.
// Currently the whole init takes only milliseconds, this is a vote for the first option.
// But for organisation through the code it would be cleaner to bundle init code with the actual logic.
// This calls for a custom event that can be triggered from document.ready or AJAX calls, then all the 
// parts of the app can just register a handler for that event. For now I'll do the big blast.
//
$(document).ready(function(){
    initializeEverything();
});



function initializeEverything() {
    ezra_basic_functions();
    ezra_basic_zaak_functions();

    if ($('#ezra_nieuwe_zaak_tooltip')) {
        $('#ezra_nieuwe_zaak_tooltip')
            .unbind('nieuweZaakTooltip')
            .bind('nieuweZaakTooltip', function(options) {
                if (options['show'] && options['action']) {
                    if (options['action'].match(/\?/)) {
                        options['action'] += '&tooltip=1';
                    } else {
                        options['action'] += '?tooltip=1';
                    }

                    $('.custom_overlay').show();
                    $('.custom_overlay_loader').show();

                    $('.ezra_nieuwe_zaak_tooltip-content').load(
                        options['action'],
                        function() {
                            initializeEverything();
                            $('.custom_overlay_loader').hide();

                            $('#ezra_nieuwe_zaak_tooltip').show();
                            $('.ezra_nieuwe_zaak_tooltip-button').addClass('active');
                        }
                    );

                }

                if (options['hide']) {
                    $('#ezra_nieuwe_zaak_tooltip').hide();

                    if (options['keeploader']) {
                        $('.custom_overlay_loader').show();
                    } else {
                        $('.custom_overlay').hide();
                    }
                    $('.ezra_nieuwe_zaak_tooltip-button').removeClass('active');
                }

                /* INITIALIZE THIS FUNCTIONALITY BELOW */

                /* Return when already initialized */
                if (
                    $('#ezra_nieuwe_zaak_tooltip')
                        .hasClass('ezra_nieuwe_zaak_tooltip-initialized')
                ) {
                    return true;
                }

                $('.ezra_nieuwe_zaak_tooltip-hide').click(function() {
                    $('#ezra_nieuwe_zaak_tooltip').trigger({
                        type: 'nieuweZaakTooltip',
                        hide: 1
                        }
                    );
                });

                $('.ezra_nieuwe_zaak_tooltip-button').click(function() {
                    if ($(this).hasClass('active')) {
                        $('#ezra_nieuwe_zaak_tooltip').trigger({
                            type: 'nieuweZaakTooltip',
                            hide: 1
                            }
                        );
                    } else {
                        $('#ezra_nieuwe_zaak_tooltip').trigger({
                            type: 'nieuweZaakTooltip',
                            show: 1,
                            action: $(this).attr('href')
                            }
                        );
                    }

                    return false;
                });

                $('.ezra_nieuwe_zaak_tooltip-show').click(function() {
                    $('#ezra_nieuwe_zaak_tooltip').trigger({
                        type: 'nieuweZaakTooltip',
                        show: 1,
                        action: $(this).attr('href')
                        }
                    );

                    return false;
                });

                $(document).bind("click", function(event) {
                    var clicked = $(event.target);

                    if (
                        clicked.hasClass('custom_overlay')
                    ) {
                        $('#ezra_nieuwe_zaak_tooltip').trigger({
                            type: 'nieuweZaakTooltip',
                            hide: 1
                            }
                        );
                    }
                });

                $(document).keyup(function(e) {
                    if (e.keyCode == 27) { 
                        $('#ezra_nieuwe_zaak_tooltip').trigger({
                            type: 'nieuweZaakTooltip',
                            hide: 1
                            }
                        );
                    }
                });


                $('#ezra_nieuwe_zaak_tooltip')
                    .addClass('ezra_nieuwe_zaak_tooltip-initialized');
            });

        $('#ezra_nieuwe_zaak_tooltip').trigger('nieuweZaakTooltip');
    }

    /* Dependency:
        Functions: post_dialog_by_ajax
    */
    if ($('#create_relatie').length) {
        /* Enable post dialog thru ajax, if ajax is not requested,
         * a return will be given and a normal post takes place
         */
        $('#create_relatie')
            .unbind('reloadSuggestion')
            .bind('reloadSuggestion', function() {
                if (
                    $('.ezra_id_rol').val() ||
                    $('.ezra_id_magic_string').val()
                ) {
                    $('#create_relatie .ezra_id_magic_spinner')
                        .show();

                    $.ajax({
                        url: $('#create_relatie form').attr('action')
                            + '/suggestion',
                        data: {
                            rol: $('.ezra_id_rol').val(),
                            magic_string: $('.ezra_id_magic_string').val()
                        },
                        success: function(data) {
                            if (data == 'NOK') { return false; }
                            $('#create_relatie .ezra_id_magic_spinner')
                                .hide();

                            $('.ezra_id_magic_string').val(data);
                        }
                    });
                }

                /* INITIALIZE THIS FUNCTIONALITY BELOW */

                /* Return when already initialized */
                if (
                    $('#create_relatie')
                        .hasClass('ezra_reloadsuggestion_initialized')
                ) {
                    return true;
                }

                $('#create_relatie').find('.ezra_id_magic_string').focus(
                    function() {
                        $('#create_relatie').trigger('reloadSuggestion');
                    }
                ).blur(
                    function() {
                        $('#create_relatie').trigger('reloadSuggestion');
                    }
                );

                $('#create_relatie')
                    .addClass('ezra_reloadsuggestion_initialized');

            });
        
        $('#create_relatie').trigger('reloadSuggestion');
    }

    $(document).on('click', '#groepeer-resultaten', function() {
        var myleft = $(this).offset().left;
        var mytop = $(this).offset().top + $(this).outerHeight();
        $('.dropdown').show();
        $('.dropdown').offset({ left:myleft, top: mytop});
        $(this).addClass('active');
    });

    /* At least this should have been a FREAKIN class
     * Michiel 20120201: fixed this from #show-zaaktypen
     * to more generic name .show-info-description
     
    $(document).on('click', '.show-info-description', function() {        
        var myleft = $(this).offset().left;
        var mytop = $(this).offset().top + $(this).outerHeight();

        $('.dropdown', this).show();
        $('.dropdown', this).offset({ left:myleft, top: mytop});
        $(this).addClass('active');
    });*/
    
    // document click closes menu
    $(document).bind("mousedown", function(event) {
        var clicked = $(event.target);
        $('#groepeer-resultaten').removeClass('active');
        if (!clicked.parents().hasClass("dropdown")) {
            $('.dropdown').hide();
        }

        $('.doc_preview').css('visibility', 'hidden');
        $('.doc-preview-init').removeClass('active');
        $('.doc_intake_row').removeClass('active');
        if (clicked.parents().hasClass(".doc-preview-init")) {
            clicked.parents().each(function() {
                $(this).find('.doc-preview-init').addClass('active')
                 .closest('.doc_intake_row').addClass('active');
            });
        }

        if ($('.checkbokses').length && !clicked.closest('.checkboxes-wrap').length) {
            $('.hide-checkbokses').click();
        }
    });
    
    

// zaakbeheer kenmerken labels


    // show & hide dropdown init
    $(document).on('mouseover', '.dropdown-init-hover', function() {  
        //var myparent = $(this).closest('div');
        var mydropdown = $(this).closest('.dropdown-wrap').find('.dropdown');
        /* var anotherd = $(this).parent().find('.dropdown-init');
        var myleft = myparent.offset().left;
        var mytop = myparent.offset().top + $(this).outerHeight(); */
        mydropdown.css('display','block');
        //mydropdown.offset({ left:myleft + 40, top: mytop + 5});
        $(this).addClass('active');
    });
    
    $(document).on('mouseout', '.dropdown-init-hover', function() {
        var mydropdown = $(this).closest('.dropdown-wrap').find('.dropdown');
        mydropdown.css('display','none');
        $(this).removeClass('active');
    });
    
    
    // show & hide dropdown
    $(document).on('mouseover', '.td-with-dropdown', function() {
        $(this).find('.dropdown-init').css('display','block');
    });

    $(document).on('mouseout', '.td-with-dropdown', function() {
        var dropdowninit = $(this).find('.dropdown-init-hide');
        dropdowninit.hide();
        $(this).find('.dropdown').hide();
        dropdowninit.removeClass('active');
    });
    
    
    

       
    
    
     
    // document click closes menu
    $(document).bind("mouseout", function(event) {
        var clicked = $(event.target);
       // $('#groepeer-resultaten').removeClass('active');
        if (!clicked.parents().hasClass("dropdown")) {
//            clicked.parents.find('.dropdown').hide();
        }
        
    });


    $('#search_results_accordion').accordion({autoHeight: false,collapsible: true, active: false});
    $('#search_results_accordion_all_results').accordion({autoHeight: false,collapsible: false, active: 0});
    $('#search_results_accordion_all_results').accordion('activate', 1);
    //$('#tab-wgt-zaken').accordion(/* {autoHeight: false,collapsible: true, active: false} */);
    

    $('#search_results_accordion').bind('accordionchange', function(event, ui) {
        var oldContentID = ui.oldContent.attr('id');
        if(oldContentID) {
            var oldElement = $("#search_results_accordion #" + oldContentID + ' .zaken_filter_inner');
            oldElement.html('');
        }
        
        ui.newHeader.find('img').show();

        var newContentID = ui.newContent.attr('id');
        var form_selector = 'form[name=zaken_results]';

        var current_path = $(location).attr('pathname');

        var grouping_field = $('input[name=grouping_field]').val();
        var data = 'nowrapper=1&grouping_choice=' + newContentID + '&grouping_field=' + grouping_field;

        if(!newContentID || !grouping_field) {
            ui.newHeader.find('img').hide();
            return false;
        }

        $("#search_results_accordion #" + newContentID + ' .zaken_filter_wrapper').load(current_path + ' .zaken_filter_inner', data,		
            function (responseText, textStatus, XMLHttpRequest) {
                if(textStatus == 'success') {
                    veldoptie_handling();
                    $(".progress-value").each(function() {
                        $(this).width( $(this).find('.perc').html() + "%");
                    });
                    var total_entries = $(form_selector + ' input[name=total_entries]').val();
                    if(total_entries) {
                        $(form_selector + ' span.total_entries').html(total_entries);
                    } else {
                        $(form_selector + ' span.total_entries').html('0');
                    }
                } else {
                    $(form_selector + ' .zaken_filter_inner').html('Er is iets misgegaan, laad de pagina opnieuw');
                }

                ui.newHeader.find('img').hide();
            });
    
        return false;
        
    });
        

    //initializeSpinners();
//     $(".fileUpload").fileUploader({
//        autoUpload: true,
//        selectFileLabel: 'Kies bestand',        
//    })
    
    
//    $("input:file").uniform({
//        fileDefaultText:'Geen bestand geselecteerd',
//        fileBtnText:'Kies bestand'
//    });
    
    
    /* ztb auth multiselectbox */
    
    $('.show').click(function() {
      $(this).next().toggle();
      $(this).toggleClass('ui-corner-all');
      $(this).toggleClass('ui-state-active');
    });
    
    $('.hide-checkbokses').click(function() {
        $(this).parent().hide();
        $(this).parent().prev().removeClass('ui-state-active');
        $(this).parent().prev().addClass('ui-corner-all');
    });
    
    $('.show').hover(
        function () {
          $(this).addClass('ui-state-hover');
        }, 
        function () {
          $(this).removeClass('ui-state-hover');
        }
      );
    
    
    /* sortable visual feedback */

    $('.ezra_table tr').hover(
      function () {
        $('.drag',this).addClass("hover");
      },
      function () {
        $('.drag',this).removeClass("hover");
      }
    );
    

    
    /* kenmerken groepen toggle */
    
    $('.ezra_table_row_heading').click(function() {
      $('.groep1').toggle();
      $(this).toggleClass('close')
    });

    activateTakenAccordion();

    // animatie voortgang zaakdossier
    //
     $(".progress-value").each(function() {
         $(this).width( $(this).find('.perc').html() + "%");
    });

    
    $(".progress-time .current").each(function() {
        $(this).css('left', $(this).parents('.progress-time').find('.perc').html() +"%");
    });

    // end animatie voortgang zaakdossier
    
    
    
    $('.doSubmit').click(function() {
        container = $(this).closest('form');

        container.trigger('submit');
        return false;
    });

    if ($('#map').length) {
        html_googlemaps_initialize();
    }


    $('select#keuzes').selectmenu({
        transferClasses: true,
        width: 130,
        style: 'dropdown',
        maxHeight: 120
    });
    
    load_selectmenu();
    load_selectmenu_breedmenu();
    load_selectmenu_start_zaak();

	   $('.menu_heading').unbind().click(function() {
          var menuContentDiv = $(this).next();
          if (menuContentDiv.is(":hidden")) {
              menuContentDiv.slideDown("fast");
              //$(this).children(".menuImgClose").removeClass("menuIconOpen");
              $.cookie(menuContentDiv.attr('id'), 'expanded');
          }
          else {
              menuContentDiv.slideUp("fast");
              //$(this).children(".menuImgClose").addClass("menuIconOpen");
              $.cookie(menuContentDiv.attr('id'), 'collapsed');
          }
      });
    $('.menu-items').unbind().each(function() {
          var menuContent = $.cookie($(this).attr('id'));
          if (menuContent == "collapsed") {
              $("#" + $(this).attr('id')).hide();
              //$("#" + $(this).attr('id')).prev().children(".menuImgClose").addClass("menuIconOpen");
          }
      });


    
    $('.form select.replace-select-small').selectmenu({style:'dropdown',width:100});  
    $('.form select.replace-select-small-popup').selectmenu({style:'popup',width:100});  
	$('.form td:first-child').addClass('eerste');

    ezra_tooltip_handling();
	

    $.zaaknr = $('#zaak_id').attr('class');

	initialize_tabinterface();

    $('.chk-swapper').change(function() {
        match = $(this).attr('id').match(/\d+/g);
        $('.depper').attr('style', 'display: none;');
        $('.dependend-' + match[0]).attr('style', false);
    });



    /*
    if ($('#gmap')) {
        html_googlemaps_initialize()
    }
    */

    //$('#accordion').accordion();

    /** General dialog */
    $('#dialog').dialog({
        autoOpen: false,
        modal: true,
        resizable: true,
        draggable: true,
        width: 790,
        height: 430,
        zIndex: 3000
    });

    /** Search dialog */
    $('#searchdialog').dialog({
        autoOpen: false,
        modal: true,
        resizable: true,
        draggable: true,
        width: 790,
        height: 430,        
        position: ['center', 75],
        zIndex: 3000
    });


    /** :s Version 6.0 of popup handling */
    $('.dialog-post').click(function() {
        fireDialog($(this));
        return false;
    });


    /** Javascript for documents
     *
     * C::Zaak::Documents
     */
    $('.add-dialog').unbind().click(function(){
        $('.option-documenttype').each(function() {
            if ($(this).attr('checked')) {
                documenttype = $(this).attr('value');
            }
        });
        documentdepth = $('#option-documentdepth').attr('value');

        $('#dialog .dialog-content').load('/zaak/'
            + $.zaaknr
            + '/documents/' + documentdepth + '/add/' + documenttype,
            null,
            function() {
                openDialog('Een bestand toevoegen aan het zaakdossier', 690, 500);

                ezra_document_functions();
            }
        );

        return false;
    });

    $('input[name="afdeling-eigenaar"]').change(function() {
        parent_elem = $(this).parent('div');
        if ($(this).attr('checked') && $(this).attr('value') == 'afdeling') {
            $('#' + parent_elem.attr('id') + ' input[name="zaakeigenaar"]').css('display', 'none');
            $('#' + parent_elem.attr('id') + ' select[name="ztc_org_eenheid_id"]').css('display', 'inline');
            $('#' + parent_elem.attr('id') + ' a').css('display', 'none');
        } else {
            $('#' + parent_elem.attr('id') + ' select[name="ztc_org_eenheid_id"]').css('display', 'none');
            $('#' + parent_elem.attr('id') + ' input[name="zaakeigenaar"]').css('display', 'inline');
            $('#' + parent_elem.attr('id') + ' a').css('display', 'inline');
        }

    });

    /*
    $('select[name="ztc_afdeling_id"]').change(function() {
        parent = $(this).parent('div');
        $('#' + parent.attr('id') + ' input[name="ztc_eigenaar_id"]').attr(
            'value',
            $(this).attr('value')
        )
    });
    */


    $('.dialog-help-button').click(function() {
        elements = $(this).parent('div .dialog-help');
        elements.find('.dialog-help-text').each(function() {
            $('#dialog .dialog-content').html($(this).html());
        });
        openDialog($(this).attr('title'), 790, 350);

        return false;
    });

    /** Javascript for Checklist
     *
     * C::Zaak::Checklist
     */

    /*** yes/no selections functioning as radio buttons
     *
     */
    $("input[class^='yesno_']").change(function(){
        question        = $(this).attr('class');
        questionname    = $(this).attr('name');

        /* Now retrieve every other options, and turn them off when we
         * turned this option on */
        others = $("input[class='" + question + "']");

        /* Do nothing, we did not turn this selection on */
        if (!$(this).attr('checked')) { return; }

        others.each(function() {
            /* Make sure we do not uncheck ourself */
            if ($(this).attr('name') == questionname) { return; }

            /* Uncheck other options within this question/vraag */
            if ($(this).attr('checked')) { 
                $(this).attr('checked', false);
            }
        });
    });

    /** Javascript for Case
     *
     * C::Zaak
     */
/*
    $("#spec_kenmerk .update_dialog").parent('a').click(function() {
        alert('clicked');
        return false;
    });
*/

    $("#spec_kenmerk .update_dialog").click(function() {
        if (!$(this).attr('id')) {
            return false;
        }

        kenmerk = $(this).attr('id');
        $('#dialog .dialog-content').load(
            '/zaak/' + $.zaaknr + '/update',
            {
                kenmerk: $(this).attr('id')
            },
            function() {
                title = 'Specifieke zaakinformatie bijwerken (' + kenmerk + ')';
                openDialog(title);
            }
        );
     });

    /** Javascript for creation
     *
     * C::Zaak
     */
    $('#dialog').dialog({
        position: 'center',
        //show: 'fade',
        //hide: 'puff',
        autoOpen: false,
        modal: true,
        resizable: false,
        draggable: false,
        width: 520,
        height: 'auto',
        maxHeight: 400,
        zIndex: 3000,
        beforeclose: function() {
        }
    });

    $("#create_intern input[name='betrokkene_type']").change(function() {
        /* NOT DONE
        if ($(this).attr('checked')) {
            context     = $(this).closest('div').attr('id');
            if ($(this).attr('value')) {
                $("#" + context + " input[name='ztc_aanvrager']").css('visibility', 'visible');
            } else {
                $("#" + context + " input[name='ztc_aanvrager']").css('visibility', 'hidden');
            }
        }
        */
    });

    $(".ztc_search_popup").click(function() {
        context     = $(this).closest('div').attr('id');
        if ($(this).attr('name') == 'ztc_aanvrager') {
            jstype      = $("#" + context + " input[name='betrokkene_type']:checked").attr('value');
            if (!jstype) {
                return;
            }
        } else {
            jstype      = 'medewerker';
        }

        $('#dialog .dialog-content').load(
            '/betrokkene/search',
            {
                jsfill: $(this).attr('name'),
                jscontext: context,
                jstype: jstype
            },
            function() {
                title = 'Zoek betrokkene (' + jstype + ')';
                openDialog(title);
            }
        );
    });

    /*
		Actie container
	*/
    $(document).on('click', ".select_actie", function() {
	   var container  = $(this).closest('div.select_actie_container');
	  // var elem    = container.find('option:selected');
		var elem    = $('select option:selected',container);

		if (!elem.val()) {
            return false;
        }

		// URL in dialog openen?
        if (elem.hasClass('popup')) {
            title   = 'Actie';
			
			if (elem.text()) {
				title = elem.text();	
			}
            url  = elem.val();

            $('#dialog .dialog-content').load(
                url,
                null,
                function(responseText) {
                    $('form.zvalidate').submit(function() {
                        return zvalidate($(this));
                    });

                    ezra_basic_functions();
                    /* ARGH DIRTY!!! */
                    if (url.match(/update\/deelzaak/)) {
                        next_subzaak();
                    }

                    if ($('#dialog .dialog-content form').hasClass('hascallback')) {
                        var callbackfunction = $('#dialog .dialog-content form input[name="callback"]').val();
                        window[callbackfunction]($('#dialog .dialog-content form'));
                    }

                    initializeEverything();

                    openDialog(title);
                }
            );

            return false;
        }
        
        if(elem.hasClass('save')) {
            var changed = $('form.webform').data('changed');
            if(changed) {
                $('form.webform').append('<input type="hidden" name="redirect" value="' + elem.val() + '"/>');
                $('form.webform').submit();
                return false;
            }
        }

        if(elem.hasClass('ezra_nieuwe_zaak_tooltip-popup')) {
            $('#ezra_nieuwe_zaak_tooltip').trigger({
                type: 'nieuweZaakTooltip',
                show: 1,
                popup: 1,
                action: elem.val()
            });
            return false;
        }
		
		// Anders gewoon naar de url
        window.location = elem.val();

        return false;
    });



    /* New style betrokkene search */
    $('.search_betrokkene').click(function() {
        searchBetrokkene($(this));

        return false;
    });

    /* Make sure we empty values on load when field is disabled */
    /* TODO */
    /*
    $("input[type='text']").each(function() {
        if (!$(this).hasClass('no_empty')) {
            if ($(this).attr('disabled')) {
                $(this).val('');
            }
        }
    });
    */

    function reload_aanvrager_wgts() {
        /* Onload, disable every aanvrager */
        $("#tab-wgt-aanvrager .wgt-betrokkene-natuurlijk_persoon_search").attr('style', 'display: none;');
        $("#tab-wgt-aanvrager .wgt-betrokkene-bedrijf_search").attr('style', 'display: none;');
        $("#tab-wgt-aanvrager .wgt-betrokkene-medewerker_search").attr('style', 'display: none;');

        $("input[name='betrokkene_type']").each(function() {
            if ($(this).attr('checked')) {
                $(".wgt-betrokkene-" + $(this).attr('value') + "_search").attr('style', 'display: inline;');
            }
        });
    }
    reload_aanvrager_wgts();

    $("input[name='betrokkene_type']").click(function() {
        reload_aanvrager_wgts();
    });

    function loadBetrokkene(rel) {
        if (!rel) {
            return false;
        }

        options = rel.split(/;/);

        /* Load options */
        id          = options[0];
        btype       = options[1];
        inputname   = options[2];
        context     = options[3];

        if (!id) {
            return false;
        }

        $('#dialog .dialog-content').load(
            '/betrokkene/search',
            {
                jsfill: $(this).attr('name'),
                jscontext: context,
                jstype: jstype
            },
            function() {
                title = 'Zoek betrokkene (' + jstype + ')';
                openDialog(title);
            }
        );

    }

    reload_interne_aanvrager();
    $('#start_intern input[name="betrokkene_type"]').change(function() {
        reload_interne_aanvrager();
    });

    function reload_interne_aanvrager() {
        $('#intern_betrokkene_type').children('div').hide();

        

        $('#start_intern input[name="betrokkene_type"]:checked').each(function() {
            $('#new_interne_' + $(this).attr('value')).show();
        });
    }

    /* Graph */
    $('#graph-img-line').each(function() {
        $('#graph-img-line .error').hide();
        graph   = $(this);
        href    = $(this).children('a:first');

        img     = new Image();
        $(img).load(function() {
            $(this).hide();
            $('#graph-img-line').removeClass('ajaxloader');
            $('#graph-img-line').append(this);
            $(this).fadeIn();
        }).error(function() {
            $('#graph-img-line').removeClass('ajaxloader');
            $('#graph-img-line .error').show();
        }).attr('src',href.attr('rel'));
    });

    $('#graph-img-pie').each(function() {
        $('#graph-img-pie .error').hide();
        graph   = $(this);
        href    = $(this).children('a:first');

        img     = new Image();
        $(img).load(function() {
            $(this).hide();
            $('#graph-img-pie').removeClass('ajaxloader');
            $('#graph-img-pie').append(this);
            $(this).fadeIn();
        }).error(function() {
            $('#graph-img-pie').removeClass('ajaxloader');
            $('#graph-img-pie .error').show();
        }).attr('src',href.attr('rel'));
    });

    trigger = $("#change_aanvragers").val();
    if (trigger) {
        show_aanvragers(trigger);
    }

    function show_aanvragers(trigger) {
        if (trigger == 'intern') {
            $('.aanvragers_extern').hide();
            $('.aanvragers_intern').show();
        } else {
            $('.aanvragers_intern').hide();
            $('.aanvragers_extern').show();
        }
    }

    $('#change_aanvragers').change(function() {
        trigger = $("#change_aanvragers").val();
        show_aanvragers(trigger);
    });

/*
    document_count = 0;
    function clone_document_row() {
        doc = $('#document_row_template').clone();
        doc.addClass('document_row');

        if (!document_count) {
            count = ($('.document_row').size() + 1);
            document_count = count;
        } else {
            count = (document_count + 1);
            document_count = count;
        }

        doc.attr('id', 'document_row_' + count);

        doc.find('input').each(function() {
            $(this).attr('name', $(this).attr('name') + '_' + count);
        });
        doc.find('select').each(function() {
            $(this).attr('name', $(this).attr('name') + '_' + count);
        });

        doc.find('.document_row_del').attr('id', 'document_row_del_' + count);
        doc.show();

        $('#document_rows').append(doc);

        oldstyle_document_row_init();
    }

    if ($('#document_rows').length) {
        oldstyle_document_row_init();
    }
*/


    //if ($('#document_row_template').size()) {
        //$('#document_row_template').hide();
        /*
        clone_document_row();

        $('.add_kenmerken').click(function() {
            var thisrow = $(this).closest('tr');

            var questionname = thisrow.find('input[name^="document_description"]')
            $(this).attr('rel', 'destination: ' + questionname.attr('name'));

            fireDialog($(this), 'load_document_kenmerken();');
            return false;
        });

        */
    //}

    //$('#document_row_add').click(function() {
    //    clone_document_row();
    //    return false;
    //});

    kenmerk_count = 0;
    function clone_kenmerk() {
        kenmerk = $('#kenmerk_template').clone();
        kenmerk.addClass('kenmerk_row');

        if (!kenmerk_count) {
            count = ($('.kenmerk_row').size() + 1);
            kenmerk_count = count;
        } else {
            count = (kenmerk_count + 1);
            kenmerk_count = count;
        }

        kenmerk.attr('id', 'kenmerk_row_' + count);

        kenmerk.find('input').each(function() {
            $(this).attr('name', $(this).attr('name') + '_' + count);
        });
        kenmerk.find('select').each(function() {
            $(this).attr('name', $(this).attr('name') + '_' + count);
        });
        kenmerk.find('textarea').each(function() {
            $(this).attr('name', $(this).attr('name') + '_' + count);
        });
        kenmerk.find('.kenmerk_title').html('Kenmerk ' + count);

        kenmerk.find('.kenmerk_del').attr('id', 'kenmerk_del_' + count);
        kenmerk.show();

        $('#zaaktype_kenmerk_add').before(kenmerk);

        $('.kenmerk_del').click(function() {
            /* Get count */
            currentid = $(this).attr('id');
            currentcount = currentid.replace(/^kenmerk_del_/g, '');

            $('#kenmerk_row_' + currentcount).remove();
            return false;
        });

    }

//    $('#kenmerk_template').hide();
    if ($('#kenmerk_template').size()) {
        clone_kenmerk();
    }

    $('#zaaktype_kenmerk_add').click(function() {
        clone_kenmerk();
        return false;
    });

    $('#kenmerk_invoertype').change(function() {
        if ($(this).find(':selected').hasClass('has_options')) {
            $('#kenmerk_invoertype_options').show();
        } else {
            $('#kenmerk_invoertype_options').hide();
        }
    });



    /*** Zaaktype Events
     *
     * Functies voor zaaktype beheer, maar ook voor informatie van zaaktypes
     * (buiten zaaktype beheer)
     */

    /*
    $('.search_zaaktype').click(function() {
        fireDialog($(this), 'load_zaaktype');

        return false;
    });
    */

    /* zaaktype/status hide everything */
    $('#status_row_template').hide();
    $('#status_row_definitions_template').hide();
    $('.status_row_definitions').hide();

    /* Help out by giving the first status */

    if ($('#status_row_template').size()) {
        /* Magic, check for by De Don generated rows, and use this as a start */
        /* Count rows, and substract row_template + header + 1(so substract 1) */
        if ($('#status_rows').find('.status_name_row').size() < 2) {
            add_status_row();
            add_status_row('afgehandeld');
        }

        /* Do not show status_row_add in first instance */
        /* $('#status_row_add').hide(); */

        $('#status_row_add').click(function() {
            add_status_row();

            return false;
        });

        $('.validate-ok').hide();

        /*
        $('input[name^="status_naam_"]').change(function() {
            closest = $(this).closest('tr');
            if ($(this).val()) {
                closest.find('.status_define').show();
            } else {
                closest.find('.status_define').hide();
            }
        });
        */

        init_status_actions();
    }

    $(".kies_zaaktype").click(function() {
        /* Get container */
        var container = $(this).closest('div');

        var zt_row_id = container.attr('id');

        var zt_trigger = container.find('input[name="jstrigger"]').val();

        /* Form container */
        var form_container = $(this).closest('form');
        var zt_betrokkene_type = form_container.find('input[name="betrokkene_type"]:checked').val();

        var eoptions = new Array();

        eoptions['zt_trigger'] = zt_trigger;

        eoptions['zt_betrokkene_type'] = zt_betrokkene_type;

        select_zaaktype('#' + zt_row_id + ' input[name="zaaktype"]', '#' + zt_row_id + ' .zaaktype_keuze_description', null, eoptions);

        return false;
    });

    /*** Hoofd- en deelzaken
     *
     * Functies voor hoofd/deelzaken
     */

    if ($('#hoofddeelzaken_table').length) {
        $('#hoofddeelzaken_table').treeTable(
            {
                // initialState: "collapsed"
                initialState: "expanded"
            }
        );
    }

    if ($('#spec_zaakinformatie_container').size()) {
        dynamic_rows('#spec_zaakinformatie_container', 'spec_zaakinfo', 'input[name^="kenmerk_naam"]', 'load_zaakinformatie_kenmerken();');
    }

    if ($('#rol_kenmerken_container').length) {
        dynamic_rows('#rol_kenmerken_container', 'auth_roles', 'input[name^="role_group_id"]',null,'ezra_basic_zaaktype_functions();');
    }


    $('.change_betrokkene_type').change(function() {
        currentform = $(this).closest('form');

        currentform.find('a.search_betrokkene').attr('rel', $(this).val());
        currentform.find('#new_externe_aanvrager input[type="hidden"]').val(null);
        currentform.find('#new_externe_aanvrager input[type="text"]').val(null);

        currentform.find('#zaaktype_keuze_container_extern input[type="hidden"]').val(null);
        currentform.find('#zaaktype_keuze_container_extern .zaaktype_keuze_description').html(null);
    });

    $('table tbody tr:last-child').addClass('lastrow');
	

    /* SUBZAKEN */
    if ($('#next_status_subzaak').length) {
        next_subzaak();
    }
    
    
    $('.search_betrokkene2').unbind().click(function() {
        updateBetrokkeneSearch($(this));
    });
    
    
    $('.wijzig_bestand').click( function() {
        var fileupload = $(this).closest(".fileUpload");
        $(this).hide();
 //       fileupload.find('.existing_file').hide();
//        fileupload.find('.new_upload').show();
        fileupload.find('.new_upload').css('visibility', 'visible');
//        fileupload.find('.new_upload input[type="file"]').click();
        return false;
    });

    $('.mintloader').mintloader({dragndrop: 1});

    // For IE
    var hasXhr2 = window.XMLHttpRequest && ('upload' in new XMLHttpRequest());
    if(!hasXhr2) {
        $('.mintloader input:file').unbind('change').change( function() {
            submitFileUpload();
        });
    }

}

// only run this function once, otherwise the accordion will collapse again. 
// scenarion: ajax reload of a page, then a master initialize of the page.
var taken_accordion_active = 0;
function activateTakenAccordion() {
    if(taken_accordion_active) {
        return;
    }

    $('#accordion-taken').each(function() {
        var active  = 0;
        if ($('#accordion-taken .ui-accordion-content.ui-accordion-taken-kenmerken').length) {
            active = $('#accordion-taken .ui-accordion-content')
                .index('.ui-accordion-taken-kenmerken');
        }
        
        $(this).accordion({
            autoHeight: false,
            collapsible: true,
            active: active
        });
    });
    taken_accordion_active = 1;
}


function updateBetrokkeneSearch(obj) {
    
    var my_form = obj.closest('form');
    var serialized = my_form.serialize();
    var action = "/search/betrokkene";
    $('.spinner-groot').css('visibility', 'visible');
    
    
    $('.betrokkene_search_results_wrapper').load(action + ' .betrokkene_search_results_inner',
        serialized,
        function(responseText, textStatus, XMLHttpRequest) {
            initializeEverything();
            ezra_tooltip_handling();
            ezra_basic_functions();
        }
    );
    
    return false;
}




function initialize_tabinterface() {
    $('#tabinterface').tabs({
        cookie: { expires: 30 },
        show: function(event, ui) {
            if (ui.panel.id == "zaak-elements-case") {
            }
            if (
                $("#" + ui.panel.id).hasClass('ezra_load_zaak_element') &&
                !$("#" + ui.panel.id).hasClass('ezra_load_zaak_element_loaded')
            ) {
                $("#" + ui.panel.id + ' .tab-loader').css('display', 'block');

                var match = $("#" + ui.panel.id).attr('class').match(/zaak_nr_(\d+)/);
                var zaaknr = match[1];

                var element_url = '/zaak/' + zaaknr + '/view_element/' + ui.panel.id;

                if ($("#" + ui.panel.id).hasClass('pip')) {
                    element_url = '/pip' + element_url;
                }

                $("#" + ui.panel.id).load(
                    element_url,
                    function(response,status,xhr) {
                        if (status!="error") {
                            $("#" + ui.panel.id + ' .tab-loader').css('display', null);
                        }
                        ezra_basic_functions();
                    }
                );

                $("#" + ui.panel.id).addClass('ezra_load_zaak_element_loaded');
            }
        }
    });
    $('#tabinterface-1').tabs({spinner:''});
    $('#tabinterface-2').tabs();
}



function ezra_tooltip_handling() {
    $(".tooltip-test-wrap").hide();
    $('.form td:nth-child(1),.form td:nth-child(2)').addClass('guideline-hover');


    $(".form tr").children(".guideline-hover").hover(
      function () {
        $(this).parent('tr').find('td').children(".tooltip-test-wrap").show();
      },
      function () {
        $(".tooltip-test-wrap").hide();
      }
    );


    $(".form tr").children(".guideline-hover").click( function () {
        $(".tooltip-test-wrap").hide()
        $(this).parent('tr').find('td').children(".tooltip-test-wrap").show();
    });


    $(".form tr").find('td').children(".tooltip-test-wrap").hover(
      function () {
        $(this).show();
      }
    );
}




function oldstyle_document_row_init() {
    $('#document_rows .document_row').each(function() {
        $(this).find('.document_row_del').click(function() {
            var thisrow = $(this).closest('tr');
            thisrow.remove();
            return false;
        });

        $(this).find('.add_kenmerken').click(function() {
            var thisrow = $(this).closest('tr');

            var questionname = thisrow.find('input[name^="document_description"]');
            $(this).attr('rel', 'destination: ' + questionname.attr('name'));

            fireDialog($(this), 'load_document_kenmerken();');
            return false;
        });
    });
}


function next_subzaak() {
	
	
    /* Subzaken */
    $('#next_status_subzaak .subzaken .row_template').hide();

    /* Clone */
    /* var vraagid    = clone_row2('#' + defid + ' .document', defid + '_document'); */

    /* A nice click function, here it comes */
    $('#next_status_subzaak .edit').click(function() {
        /* Make up some destination options */
        var thisrow = $(this).closest('tr');

        var questionname = thisrow.find('input[name^="status_zaaktype_id"]');
        $(this).attr('rel',
            (
             $(this).attr('rel') ?
             $(this).attr('rel') + '; ' : ''
             ) + 'destination: ' + questionname.attr('name')
        );

        fireDialog($(this), 'load_subzaken_kenmerken();');
        return false;
    });

	
    $('#next_status_subzaak .subzaken .del').click(function() {
        /* Get count */
        var parentrow = $(this).closest('tr');

        parentrow.remove();

        return false;
    });
	

    /* Make 'add' button work */

    $('#next_status_subzaak .status_definition_add_subzaak').click(function()
    {
        /* Clone row */
        var zt_row_id = clone_row2('#next_status_subzaak .subzaken', 'next_status_subzaak_subzaken');

        /* Launch our zaaktype selection window */
        select_zaaktype('#' + zt_row_id + ' input[name^="status_zaaktype_id"],#' + zt_row_id + ' input[name^="status_zaaktype_open"]', '#' + zt_row_id + ' .description', '#' + zt_row_id);

        /* Make sure this one gets a 'vink' ;) */
        $('#' + zt_row_id + ' input[name^="status_zaaktype_run"]').attr('checked', 'checked');

        /* Make sure this option does not get an id appended */
        $('#' + zt_row_id + ' input[name^="status_zaaktype_open"]').attr('name', 'status_zaaktype_open');

        /* A nice click function, here it comes */
        $('#next_status_subzaak .edit').click(function() {
            /* Make up some destination options */
            var thisrow = $(this).closest('tr');

            var questionname = thisrow.find('input[name^="status_zaaktype_id"]');
            $(this).attr('rel',
                (
                 $(this).attr('rel') ?
                 $(this).attr('rel') + '; ' : ''
                 ) + 'destination: ' + questionname.attr('name')
            );

            fireDialog($(this), 'load_subzaken_kenmerken();');
            return false;
        });

        return false;
    });

}

function load_zaakinformatie_kenmerken() {

    $('#kenmerk_definitie select[name="kenmerk_type"]').change(function() {
        if ($(this).find(':selected').hasClass('has_options')) {
            $('#kenmerk_definitie .multiple-options').show();
        } else {
            $('#kenmerk_definitie .multiple-options').hide();
        }

        if ($(this).find(':selected').hasClass('allow_default_value')) {
            $('#kenmerk_definitie .default-value').show();
        } else {
            $('#kenmerk_definitie .default-value').hide();
        }

        if ($(this).find(':selected').hasClass('file')) {
            $('#kenmerk_definitie .file-options').show();
        } else {
            $('#kenmerk_definitie .file-options').hide();
        }
    });

    $('#kenmerk_definitie select[name="kenmerk_type"]').change();

    $('#kenmerk_definitie select[name="kenmerk_document_key"]').change(function() {
        $('#kenmerk_definitie .file-options-unknown').show();
        $('#kenmerk_definitie .file-options-known').hide();
        if ($(this).find(':selected').val()) {
            $('#kenmerk_definitie .file-options-unknown').hide();
            $('#kenmerk_definitie .file-options-known').show();
            $('#kenmerk_definitie .mandatory_document').hide();
            $('#kenmerk_definitie .no_mandatory_document').hide();

            if ($(this).find(':selected').hasClass('mandatory')) {
                $('#kenmerk_definitie .mandatory_document').show();
            } else {
                $('#kenmerk_definitie .no_mandatory_document').show();
            }
        }
    });
    $('#kenmerk_definitie select[name="kenmerk_document_key"]').change();

    $('#kenmerk_definitie input[type="button"]').click(function() {
        /* Harvest results */
        var postdata = {};
        $('#kenmerk_definitie select').each(function() {
            postdata[$(this).attr('name')] = $(this).val();
        });
        $('#kenmerk_definitie input').each(function() {
            if (
                $(this).attr('type') == 'checkbox' ||
                $(this).attr('type') == 'radio'
            ) {
                if ($(this).attr('checked') == true) {
                    postdata[$(this).attr('name')] = $(this).attr('value');
                }
                return;
            }
            postdata[$(this).attr('name')] = $(this).val();
        });
        $('#kenmerk_definitie textarea').each(function() {
            postdata[$(this).attr('name')] = $(this).val();
        });

        $.post(
            '/zaaktype/specifiek/kenmerk_definitie',
            postdata,
            function() {
                $('#dialog').dialog('close');
            }
        );
    });
}

function init_dynamic_row_functions(container_id,edit,editcallback) {
    if (edit) {
        $(container_id + ' .edit').click(function() {
            var thisrow = $(this).closest('tr');

            var questionname = thisrow.find(edit);

            $(this).attr('rel', 'destination: ' + questionname.attr('name'));

            fireDialog($(this), editcallback);
            return false;
        });
    }

    $(container_id + ' .del').click(function() {
        var thisrow = $(this).closest('tr');
        thisrow.remove();
        return false;
    });
}

function dynamic_rows(container_id, name, edit, editcallback,rowcallback) {
    /* Hide */
    $(container_id + ' .dynamic_rows .row_template').hide();

    /* Make 'add' button work */
    $(container_id + ' .add_row').each(function() {
        if ($(this).data('events')) { return; }

        $(this).click(function() {
            var dynrowid = clone_row2(container_id + ' .dynamic_rows', name);

            init_dynamic_row_functions(container_id,edit, editcallback);

            if (rowcallback) {
                eval(rowcallback);
            }
            return false;
        });
    });

    init_dynamic_row_functions(container_id,edit, editcallback);
}


function load_subzaken_kenmerken() {
    $('#zaaktype_definitie form').submit(function() {
        /* Harvest results */
        var postdata = $(this).serialize();

        var formuri = $('input[name="zaaknr"]').val();

        $.post(
            '/zaak/' + formuri + '/status/next/zaaktype_kenmerken',
            postdata,
            function() {
                $('#dialog').dialog('close');
            }
        );

        return false;
    });
}

function load_document_kenmerken() {
    $('#document_definitie input[type="button"]').click(function() {
        /* Harvest results */
        var postdata = {};
        $('#document_definitie select').each(function() {
            postdata[$(this).attr('name')] = $(this).val();
        });
        $('#document_definitie input').each(function() {
            if (
                $(this).attr('type') == 'checkbox' ||
                $(this).attr('type') == 'radio'
            ) {
                if ($(this).attr('checked') == true) {
                    postdata[$(this).attr('name')] = $(this).attr('value');
                }
                return;
            }
            postdata[$(this).attr('name')] = $(this).val();
        });
        $('#document_definitie textarea').each(function() {
            postdata[$(this).attr('name')] = $(this).val();
        });

        $.post(
            '/zaaktype/algemeen/doc_definitie',
            postdata,
            function() {
                $('#dialog').dialog('close');
            }
        );
    });
}

function init_status_actions() {
    /* Make edit button work */
    $('.status_define').each(function() {
        if ($(this).data('events')) { return ; }

        $(this).click(function() {
            /* Get id */
            var closestid = $(this).closest('tr').attr('id');
            var rownr     = closestid.replace(/status_row_/g, '');

            $('#status_row_definitions_' + rownr).toggle();

            return false;
        });
    });

    /* Make edit button work */
    $('.status_name_row .del').each(function() {
        if ($(this).data('events')) { return ; }

        $(this).click(function() {
            /* Get id */
            var closesttr = $(this).closest('tr');
            var closestid = closesttr.attr('id');
            var rownr     = closestid.replace(/status_row_/g, '');

            $('#status_row_definitions_' + rownr).remove();
            closesttr.remove();

            return false;
        });
    });

    /* Reshake statusses */
    var num_statusses = 0;
    $('#status_rows').find('.status_count').each(function() {
        var closestid = $(this).closest('tr').attr('id');
        var rownr     = closestid.replace(/status_row_/g, '');
        $(this).html('<input type="hidden" name="status_nr_' + rownr + '" value="' + num_statusses + '" /><p>' + num_statusses + '</p>');
        num_statusses = num_statusses + 1;
    });

    /* Make sure we can save this definition */
    $('.status_row_definitions input[type="button"]').each(function() {
        if ($(this).data('events')) { return ; }

        $(this).click(function() {
            /* Do some saving here */
            $(this).closest('tr').hide();

            /* Validate row */
            /* $(this).closest('tr').find('.validate-ok').show(); */
            var defrowid = $(this).closest('tr').attr('id');
            var parentrowid     = defrowid.replace(/_definition/g, '');
            parentrowid     = parentrowid.replace(/rows/g, 'row');

            $('#' + parentrowid).find('.validate-ok').show();

            /* add_status_row(); */

            return false;
        });
    });

    $('.status_row_definitions').each(function() {
        var defid = $(this).closest('tr').attr('id');
        var currentrowid = $(this);
        /* defid     = defid.replace(/status_row_definitions_/g, ''); */

        dynamic_rows(
            '#' + defid + ' .checklist_container',
            'checklist',
            'input[name^="status_checklist_vraag"]',
            'load_checklist_antwoorden();'
        );

        /* Make 'antwoorden' work */
        /* Docs */
/*
        dynamic_rows(
            '#' + defid + ' .document_container',
            'document'
        );
*/

        dynamic_rows('#' + defid + ' .document_container','documenten', 'input[name^="status_document_name"]', 'load_document_kenmerken();');

        /* Subzaken */
        $('#' + defid + ' .subzaken .row_template').hide();

        /* Clone */
        /* var vraagid    = clone_row2('#' + defid + ' .document', defid + '_document'); */

        /* Make 'add' button work */
        if (!$('#' + defid + ' .status_definition_add_subzaak').data('events')) {
         
		   
		    $('#' + defid + ' .status_definition_add_subzaak').unbind().click(function() {
               
				/* Clone row */
                var zt_row_id = clone_row2('#' + defid + ' .subzaken', defid + '_subzaken');

                /* Launch our zaaktype selection window */
                select_zaaktype('#' + zt_row_id + ' input[name^="status_zaaktype_id"]', '#' + zt_row_id + ' .description', '#' + zt_row_id);

                init_status_actions();
               
			    return false;

            });
        }

        $('#' + defid + ' .subzaken .edit').click(function() {
            var thisrow = $(this).closest('tr');

            var questionname = thisrow.find('input[name^="status_zaaktype_id"]');

            $(this).attr('rel', 'destination: ' + questionname.attr('name'));

            fireDialog($(this), 'load_zaaktype_kenmerken();');
            return false;
        });

        $('#' + defid + ' .subzaken .del').click(function() {
            /* Get count */
            var parentrow = $(this).closest('tr');

            parentrow.remove();

            return false;
        });


        dynamic_rows('#' + defid + ' .resultaatmogelijkheden_container','resultaten');

        /* Make sure we do not show afhandelstatus ;) */
        if ($('#' + defid  + ' [name^="status_type"]').length) {
            var statustype = $('#' + defid  + ' input[name^="status_type"]');
            if (statustype.val() == 'afhandelen') {
                /* Disable status_afhandel_block */
                $('#' + defid + ' .status_behandel_block').hide();
                $('#' + defid + ' .status_afhandel_block').show();
                $('#' + defid + ' .deelofsubs').html('vervolgzaken');
                $('#' + defid + ' .deelofsub').html('vervolgzaak');
            } else {
                $('#' + defid + ' .status_afhandel_block').hide();
                $('#' + defid + ' .status_behandel_block').show();
            }
        }


    });

    if ($('.status_count').length && ! cloned_rows['status_row']) {
        var numtrrows = $('.status_name_row').size();
        cloned_rows['status_row'] = numtrrows;
        numtrrows = $('.status_row_definitions').size();
        cloned_rows['status_row_definitions'] = numtrrows;
    }

    /* Make sure we define firststatus class */
    $('input[name="status_nr_1"]').each(function() {
        // Find container row
        var row_container   = $(this).closest('tr');

        // Get id from container
        var container_id    = row_container.attr('id');

        container_id        = container_id.replace(/.*(\d+)/, '$1');

        // Get row_definitie
        table_container     = row_container.closest('table');

        definitie           = table_container.find('#status_row_definitions_' + container_id);

        definitie.find('.firststatus').css('display', 'inline');
        definitie.find('.nextstatus').css('display', 'none');
    });

    $('.ztAjaxTable').ztAjaxTable();

}

var status_count = 1;
function add_status_row(type) {
    /* Clone template row */
    var newid    = clone_row('status_row');
    var newdefid = clone_row('status_row_definitions');

    $('#' + newdefid).hide();

    status_count = status_count + 1;
    /* Now make sure everything works in this definition */
    load_definition(newdefid);

    /* Make this status 'afgehandeld' */
    if (type == 'afgehandeld') {
        var oldinput = $('#' + newid).find('input[name^="status_naam"]');

        /* Some decorations */
        $('#' + newid).find('.input-naam').append('<p>Afgehandeld</p>');
        $('#' + newid).find('.input-naam')
            .append('<input type="hidden" name="' + oldinput.attr('name')
                        + '" value="Afgehandeld" />');

        /* Some class working */
        $('#' + newid).addClass('afgehandeld');

        /* And for future reference, drop the select box for choosing
         * type, and create a hidden containing this type */
        $('#' + newdefid).find('input[name^="status_type"]').val('afhandelen');

        oldinput.remove();
    }

    init_status_actions();
}

var cloned_rows2 = [];

function clone_row2(elemname, name, append) {

    /* Clone */
    clone  = $(elemname + ' .row_template').clone();
    parent_elem =  $(elemname + ' .row_template').parent();

    if (cloned_rows2[name]) {
        cloned_rows2[name] = cloned_rows2[name] + 1;
    } else {
        /* Magic, check for by De Don generated rows, and use this as a start */
        /* Count rows, and substract row_template + header + 1(so substract 1) */
        var numtrrows = parent_elem.find('tr').size();
        cloned_rows2[name] = (numtrrows - 1);
    }

    count = cloned_rows2[name];

    /* Change every input/select/textarea and append number */
    formelements = Array('input','select','textarea','checkbox');
    for (var i in formelements) {
        clone.find(formelements[i]).each(function() {
            $(this).attr('name',
                $(this).attr('name') + '_' + count
            );
        });
    }

    /* Change this id */
    var newid     = name + '_' + count;

    clone.attr('id', newid);

    /* Remove template class from clone */
    clone.removeClass('row_template');

    /* Make sure the delete button is gonna work */
    clone.find('.del').click(function() {
        /* Get count */
        var parentrow = $(this).closest('tr');

        parentrow.remove();

        return false;
    });

    /* Append the clone */
    parent_elem.append(clone);

    /* Show the clone */
    clone.show();

    return newid;
}

function load_definition(defid) {

    return;
    /* Checklist */

    /* Hide */
    $('#' + defid + ' .checklist .row_template').hide();

    /* Make 'add' button work */
    $('#' + defid + ' .status_definition_add_vraag').click(function() {
        var vraagid = clone_row2('#' + defid + ' .checklist', defid + '_checklist');

        $('#' + vraagid + ' .add_antwoorden').click(function() {
            var thisrow = $(this).closest('tr');

            var questionname = thisrow.find('input[name^="status_checklist_vraag"]');
            $(this).attr('rel', 'destination: ' + questionname.attr('name'));
            $(this).attr('title',
                thisrow.find('input[name^="checklist_vraag"]').val()
            );

            fireDialog($(this), 'load_checklist_antwoorden();');
            return false;
        });

        return false;
    });

/*
    var amatch = $('#' + defid).attr('id').match(/_1$/g);
    if (amatch) {
        $('#' + defid + ' .checklist_status_block').hide();
    }
*/

    /* Make 'antwoorden' work */
    /* Docs */

    /* Hidei OLD */
    //$('#' + defid + ' .document .row_template').hide();

    /* Clone */
    // var vraagid    = clone_row2('#' + defid + ' .document', defid + '_document');

    /* Make 'add' button work */
    // $('#' + defid + ' .status_definition_add_document').click(function() {
    //     clone_row2('#' + defid + ' .document', defid + '_document');
    //     return false;
    // });


    /* Subzaken */
    $('#' + defid + ' .subzaken .row_template').hide();

    /* Clone */
    /* var vraagid    = clone_row2('#' + defid + ' .document', defid + '_document'); */

    /* Make 'add' button work */
    $('#' + defid + ' .status_definition_add_subzaak').click(function() {
        /* Clone row */
        var zt_row_id = clone_row2('#' + defid + ' .subzaken', defid + '_subzaken');

        /* Launch our zaaktype selection window */
        select_zaaktype('#' + zt_row_id + ' input[name^="status_zaaktype_id"]', '#' + zt_row_id + ' .description', '#' + zt_row_id);

        return false;
    });


    //dynamic_rows('#' + defid + ' .document_container','documenten', 'input[name^="document_description"]', 'load_statusinformatie_documenten();');
    dynamic_rows('#' + defid + ' .resultaatmogelijkheden_container','resultaten');
}

function select_zaaktype(dest_id, dest_descr, dest_row, eoptions) {
    if (dest_row && dest_id) {
        $('#searchdialog').dialog(
            'option',
            'beforeclose',
            function() {
                if (! $(dest_id).val()) {
                    $(dest_row).remove();
                }

                $('#searchdialog').dialog(
                    'option',
                    'beforeclose',
                    function() { }
                );
            }
        );
    }

    if (!eoptions) {
        eoptions = new Array;
    }

    $('#searchdialog .dialog-content').load(
        '/zaaktype/search',
        {
            jsfillid: dest_id,
            jsfilldescr: dest_descr,
            jstrigger: eoptions['zt_trigger'],
            jsbetrokkene_type: eoptions['zt_betrokkene_type']
        },
        function() {
            title = 'Zoek zaaktype';

          
            $('#searchdialog').data('title.dialog', title);
            $('#searchdialog').addClass('smoothness').dialog('open');

            $('#accordion').accordion({
                autoHeight: false
            });

            load_zaaktype();
        }
    );
}

function load_checklist_antwoorden() {
    $('#antwoord_invoertype').change(function() {
        if ($(this).find(':selected').hasClass('has_options')) {
            $('#antwoord_mogelijkheden').show();
        } else {
            $('#antwoord_mogelijkheden').hide();
        }
    });


    if ($('#antwoord_invoertype').find(':selected').hasClass('has_options')) {
        $('#antwoord_mogelijkheden').show();
    } else {
        $('#antwoord_mogelijkheden').hide();
    }

    $('#antwoord_definitie input[type="button"]').click(function() {
        /* Harvest results */
        var postdata = {};
        $('#antwoord_definitie select').each(function() {
            postdata[$(this).attr('name')] = $(this).val();
        });
        $('#antwoord_definitie input').each(function() {
            postdata[$(this).attr('name')] = $(this).val();
        });
        $('#antwoord_definitie textarea').each(function() {
            postdata[$(this).attr('name')] = $(this).val();
        });

        $.post(
            '/zaaktype/status/antwoorden',
            postdata,
            function() {
                $('#dialog').dialog('close');
            }
        );
    });
}

function load_zaaktype_kenmerken() {
    $('#zaaktype_definitie input[type="button"]').click(function() {
        /* Harvest results */
        var postdata = {};
        $('#zaaktype_definitie select').each(function() {
            postdata[$(this).attr('name')] = $(this).val();
        });

        $('#zaaktype_definitie input').each(function() {
            if (
                $(this).attr('type') == 'checkbox' ||
                $(this).attr('type') == 'radio'
            ) {
                if ($(this).attr('checked') == true) {
                    postdata[$(this).attr('name')] = $(this).attr('value');
                }
                return;
            }
            postdata[$(this).attr('name')] = $(this).attr('value');
        });
        $('#zaaktype_definitie textarea').each(function() {
            postdata[$(this).attr('name')] = $(this).val();
        });

        $.post(
            '/zaaktype/status/zaaktype',
            postdata,
            function() {
                $('#dialog').dialog('close');
            }
        );
    });
}

/*** Zaaktype Static Functions
 *
 * Functies voor zaaktype beheer, maar ook voor informatie van zaaktypes
 * (buiten zaaktype beheer)
 */

function load_zaaktype() {
    $("#zoek_zaaktype form").submit(function(){
        $('#betrokkene_loader').removeClass('disabled');
        /*
        postdata = {
            search: 1,
            jsfill: "[% jsfill %]",
            jscontext: "[% jscontext %]",
            jstype: "[% jstype %]",
            jsversion: "[% jsversion %]",
            method: "[% method %]",
            url: "[% url %]"
        };
        */
        postdata = {};
        $("#zoek_zaaktype input").each(function(){
            if (
                $(this).attr('type') == 'checkbox' ||
                $(this).attr('type') == 'radio'
            ) {
                if ($(this).attr('checked') == true) {
                    postdata[$(this).attr('name')] = $(this).attr('value');
                }
                return;
            }
            postdata[$(this).attr('name')] = $(this).attr('value');
        });
        $("#zoek_zaaktype select").each(function(){
            chosenoption = $(this).find(':selected');
            postdata[$(this).attr('name')] = chosenoption.val();
        });

        $('#search_zaaktype_results').load(
            '/zaaktype/search',
            postdata,
            function() {
                $('#accordion').accordion('activate', 1);
                $('#betrokkene_loader').addClass('disabled');

                refresh_zaaktype_search_rows();
            }
        );

        return false;

    });
}

function refresh_zaaktype_search_rows() {

	$("#search_zaaktype_results .zaaktype_keuze").click(function() {

        var jsfillid    = $("#zoek_zaaktype input[name='jsfillid']").val();
        var jsfilldescr = $("#zoek_zaaktype input[name='jsfilldescr']").val();

        var result_id    = $(this).find("input[name='zaaktype_id']").val();

        var result_name    = $(this).find("input[name='zaaktype_name']").val();
        var result_descr = $(this).find("input[name='zaaktype_descr']").val();

        // if the purpose of this dialog is to add a zaaktype filter to uitgebreid zoeken
        // do
		var search_filter_post = $("#zoek_zaaktype input[name='search_filter_post']").val();
		
       	if(search_filter_post) {
       		var zaak_type_id = $(this).find("input[name=zaaktype_id]").val();
			var data = 'action=update_filter&filter_type=zaaktype&nowrapper=1&value=' + zaak_type_id;
			updateSearchFilters(data);
            $('#dialog').dialog('close');
		}

        if (jsfillid && jsfilldescr) {
            $(jsfillid).val(result_id);
            if ($(jsfilldescr)[0].tagName == 'INPUT') {
                $(jsfilldescr).val(result_descr);
            } else {
                $(jsfilldescr).html(result_descr);
            }
        }

        /* Close window */
        $('#searchdialog').dialog('close');
    });
}


/*** clone rows
 *
 * This function should work as a sharm, make sure you place one row in this
 * table, with an id like: [name]_template, and hide this one.
 *
 * Create a delete row button somewhere, with the class:
 * [name]_del
 *
 * And everyhting should do what you think it should do
 */
var cloned_rows = Array();
function clone_row(name, append) {
    /* Clone */
    clone  = $('#' + name + '_template').clone();
    parent_elem =  $('#' + name + '_template').parent();

    if (cloned_rows[name]) {
        cloned_rows[name] = cloned_rows[name] + 1;
    } else {
        /* Magic, check for by De Don generated rows, and use this as a start */
        /* Count rows, and substract row_template + header + 1(so substract 1) */
        if (name == 'status_row') {
            var numtrrows = parent_elem.find('.status_name_row').size();
        } else {
            var numtrrows = parent_elem.find('.status_row_definitions').size();
        }
        cloned_rows[name] = numtrrows;
    }

    count = cloned_rows[name];

    /* Change every input/select/textarea and append number */
    formelements = Array('input','select','textarea','checkbox');
    for (var i in formelements) {
        clone.find(formelements[i]).each(function() {
            $(this).attr('name',
                $(this).attr('name') + '_' + count
            );
        });
    }

    /* Change this id */
    var currentid = clone.attr('id');
    var newid     = currentid.replace(/template$/g, count);

    clone.attr('id', newid);

    /* Check for a delete button */
    $(clone).find('.' + name + '_del').each(function() {
        $(this).attr('id', name + '_del_' + count);
    });

    /* Make sure the delete button is gonna work */
    clone.find('.' + name + '_del').click(function() {
        /* Get count */
        currentid = $(this).attr('id');
        currentcount = currentid.replace(/.*(\d+)$/g, '$1');

        $('#' + name + '_' + currentcount).remove();

        return false;
    });

    /* Append the clone */
    var afhandelrow = parent_elem.find('.afgehandeld');
    if (afhandelrow.size()) {
        afhandelrow.before(clone);
    } else {
        parent_elem.append(clone);
    }

    /* Show the clone */
    clone.show();

    return newid;
}

/*
function load_status_definitions() {
    $('#document_row_template').hide();
    $('#status_def_document_add').click(function() {
        clone_row('document_row');
        return false;
    });
    $('#checklist_template').hide();
    $('#status_def_checklist_add').click(function() {
        clone_row('checklist');
        return false;
    });
}
*/

/** Search basics
 *
 * Loads all basic search functions:
 * - validation
 * - betrokkene
 * - zaaktype
 * - zaak
 */

function load_search_basics() {
    $('.search_betrokkene').click(function() {
        searchBetrokkene($(this));

        return false;
    });

    $('.search_zaak').click(function() {
        searchZaak($(this));

        return false;
    });

    $('form.zvalidate').submit(function() {
        return zvalidate($(this));
    });

}

function ezra_intake_link_details(formelem) {
    formelem.submit(function() {
        var serialized = formelem.serialize();
        $('#dialog .dialog-content').load(
            formelem.attr('action'),
            serialized,
            function() {
                ezra_document_functions();

                if ($('#dialog .dialog-content form').hasClass('hascallback')) {
                    ezra_intake_link_details($('#dialog .dialog-content form'));
                }
            }
        );


        return false;
    });
}


function load_selectmenu() {
    $('select.replace-select').selectmenu({
        style:'dropdown',
        width:150
        //maxHeight: '150'
    });  
}

function load_selectmenu_start_zaak() {
    $('select.replace-select-start-zaak').selectmenu({
        style:'dropdown',
        width:224
    });  
}


/* extra instantie van selectmenu met breder menu. Dit is nodig bij generieke categorie in "een zaaktype aanmaken". De categorieën zijn nl. erg lang… */
function load_selectmenu_breedmenu() {
    $('select.replace-select-breedmenu').selectmenu({
        style:'dropdown',
        width:310,
        menuWidth:500
    });  
}

function load_selectmenu_import() {
    $('select.replace-select-breedmenu').selectmenu({
        style:'dropdown',
        width:185,
        menuWidth:500
    });  
}


//function initializeSpinners() {
    /* kleine spinner
    var opts = {
      lines: 9, // The number of lines to draw
      length: 3, // The length of each line
      width: 2, // The line thickness
      radius:3, // The radius of the inner circle
      color: '#000', // #rbg or #rrggbb
      speed: 1, // Rounds per second
      trail: 100, // Afterglow percentage
      shadow: false // Whether to render a shadow
    };
    var target = document.getElementById('spinner');
    var spinner = new Spinner(opts).spin(target); */
   
    // grote spinner
/*
    var opts2 = {
      lines: 12, // The number of lines to draw
      length: 7, // The length of each line
      width: 4, // The line thickness
      radius:10, // The radius of the inner circle
      color: '#000', // #rbg or #rrggbb
      speed: 1, // Rounds per second
      trail: 60, // Afterglow percentage
      shadow: false // Whether to render a shadow
    };

    $('.spinner-groot').each(function() {
       var $this = $(this),
           data = $this.data();	

        if (data.spinner) {
            data.spinner.stop();
            delete data.spinner;
        }

        data.spinner = new Spinner(opts2).spin(this);
    });
}
*/


var Logger = new function() {
  this.log = function(str) {
    try {
      console.log(str);
    } catch(e) {
      // do nothing
    }
  };
};



var zaken_filter_form_name = '';


/** ready
 *
 */
$(document).ready(function(){
    ezra_zaaktypen_mijlpalen();
    ezra_zaaktypen_auth();
    ezra_zaaktypen_mijlpaaldefinitie();
    //ezra_zaaktypen();

//	$.ajaxSetup({
//		timeout: 10000
//	});

    $("#accordion_milestones").accordion({
        autoHeight: false,
        collapsible: true
    });


    $("#accordion_search_filters").accordion({
        autoHeight: false,
        collapsible: true
    });


	activateCurrentSearchFilter();     
      
	$(document).on('click', ".delete_search_filter", function(){
	    $.ztWaitStart();
		$(this).parents('tr').remove();

		updateSearchFilters();
		return false;
	});
	

	$(document).on('click', '.delete_search_query', function(){
		var search_query_id = $(this).attr('id');
		var data = 'action=delete_search_query&search_query_id=' + search_query_id;

        if(confirm('Zoekopdracht verwijderen?')) {
            $('.search_filters_dashboard_wrap').load("/search/dashboard" + ' .search_filters_dashboard_inner', data,		
                function () {
                    $.ztWaitStop();
            });
        }

		return false;
	});
	
	
	$('#select_search_grouping_field').change(function(){
		$('form#search_query_grouping').submit();
	});


	$(document).on('click', '.submit_search_query_form .grouping_link a', function(){
	    var destination = $(this).attr('id');
	    $('input[name=destination]').val(destination);
		$(this).closest('form').submit();
	});


	$(document).on('click', '.submit_search_query_form > ul > li > a', function(){
	    var destination = $(this).attr('id');
	    if(destination == 'results') {
	        $('input[name=grouping_field]').val('');
	    }
	    $('input[name=destination]').val(destination);
		$(this).closest('form').submit();
	});
	
	
	
	$(document).on('change', '.zaken_filter_form select#zaakfilter', function() {
		var form_name = $(this).closest('form').attr('name');
		return updateZaakResults(form_name);
	});


// avoid multiple server requests when typing a word. only when no character has been typed for
// more than 400 ms. the server will be invoked
// TODO: certain keystrokes generate an event, but do not change the query string. only re-POST
// when the form has changed. this could also be done in updateZaakResults
//
	$('.zaak_search_filter').data('timeout', null).live('keydown', function() {
		// a backdoor approach to getting the form to the function, since the timeout construct doesn't allow
		// for parameters.
		zaken_filter_form_name = $(this).closest('form').attr('name');
//		$('form[name=' + zaken_filter_form_name + '] .zaken_filter_hourglass').show();
        	$(this).closest('form').find('.spinner-groot').css('visibility', 'visible');

		clearTimeout($(this).data('timeout'));
        $(this).data('timeout', setTimeout(updateZaakResults, 400));
	});
	

	$(document).on('submit', '#update_search_filter', function(){
		return validateSearchFilters();
	});


	$(document).on('click', '.add_search_filter .element', function() {
		var filter_type = $(this).attr('id');
		if(filter_type == 'disabled') return false;
		
		var search_query_id = $('form input[name=SearchQuery_search_query_id]').val();

		// show the dialog to add a new filter
		if(filter_type == 'kenmerk') {
			//log('add kenmerk');
			addKenmerkFilter(search_query_id);
		} else {
			show_filter_popup(filter_type, '', search_query_id);
		}
	        
	        /// todo activate accordion branch
		return false;
    });

	// any changes in the kenmerken should be communicated to the back-end immediately.
	$(document).on(
	    'change',
	    'form#search_filters select, form#search_filters input, form#search_filters textarea', 
	    function(event, ui) {
            // except with the flipping bag-adres autocomplete stuff. in that case, first let the autocomplete finish
            // and update.
            if(!$(this).hasClass('veldoptie_bag_adres')) {
                updateSearchFilters();
            }
	});
	
	$(document).on('click', ".set_sort_order", function(){
		var form_name = $(this).closest('form').attr('name');
		var old_sort_field = $('form[name=' + form_name + '] input[name=sort_field]').val();
		var old_sort_direction = $('form[name=' + form_name + '] input[name=sort_direction]').val();

	    var sort_field = $(this).attr('id');		
		var sort_direction = 'DESC'; // default
		
		// if the sort field is the same as was clicked last time, flip the sort direction
		if(sort_field == old_sort_field) {
			sort_direction = old_sort_direction == 'ASC' ? 'DESC': 'ASC';
		}

		$('form[name=' + form_name + '] input[name=sort_field]').val(sort_field);
		$('form[name=' + form_name + '] input[name=sort_direction]').val(sort_direction);
		
		updateZaakResults(form_name);
		return false;
	});

	$(".search_query_reset").click(function(){
		return confirm('Alle instellingen wissen?');
	});

	$(document).on('click', '.set_page_number', function(){
		var page_number = $(this).attr('id');
		var form_name = $(this).closest('form').attr('name');
		$('form[name=' + form_name + '] input[name=page]').val(page_number);
		$('form[name=' + form_name + '] input[name=pager_request]').val(1);
	    updateZaakResults(form_name);
	    
		return false;
	});

	$(document).on('click', ".edit_search_filter", function(){
		var search_query_id = '';
		if( $('form input[name=SearchQuery_search_query_id]')) {
			search_query_id = $('form input[name=SearchQuery_search_query_id]').val();
		}

        show_filter_popup($(this).attr('type'), $(this).attr('value'), search_query_id);     
        return false;
	});
	

	$("ddfdfdf#search_query_save_button").click(function(){
	    $.ztWaitStop();
	    $(this).closest('form').submit();
	    return false;
	});

	//$.localise('ui-multiselect', {language: 'nl', path: 'js/multiselect/locale/'});
  	$(".search_fields_selector .multiselect").multiselect({searchable: false});

    $("table.sortable-element tbody").sortable(
        {
            items: 'tr',
            handle: '.drag',
            update: function(event,ui) {
                $("tr",this).each(
                    function( index, element ){
                        $(".roworder",this).val(index+1);
                    }
                );
            }
        }
    );

    $('div.element_tabel_kenmerk').each(function() {
        ezra_kenmerk_grouping($(this));
    });
    
    
    $('#search_query_chart_container').each(function(){
    	loadChart($('.chart_profile_selector select#chart_profile'));
    });

	$('.chart_profile_selector select#chart_profile').change(function(){
		loadChart($(this));
	});
	

	$(document).on('click', '.search_query_name .bewerk', function() {
	    
	    var html_obj = $('input[name=search_query_name_hidden]');
	    fireDialog(html_obj);
    	$('input[name=search_query_edit_name_input]').select();
	});
		

    $(document).on('click', 'input[name=search_query_cancel_button]', function() {
        $('#dialog').dialog('close');
        return false;
	});

    $(document).on('click', 'input[name=search_query_save_button]', function() {
        var value = $('input[name=search_query_edit_name_input]').val();
        $('#dialog').dialog('close');
        
        $('input[name=search_query_name_hidden]').val(value);
        var caller_form = $('input[name=search_query_name_hidden]').closest('form');
        
        
        $('<input>').attr({
            type: 'hidden',
            value: '1',
            name: 'save_settings'
        }).appendTo('form');

        caller_form.submit();
        return false;
    });
    
    
    $(document).on('click', '#new_search', function() {
        $(this).closest('form').find('input[name=action]').val('reset');
        $(this).closest('form').submit();
    });
    
    
    $(document).on('change', '.zaak_intake_edit_filename', function() {
        updateZaakintakeFilename($(this));
    });
    
    $("disabledtable.search_query_table.sortable").bind( "sortchange", function(event, ui) {


    });
    
    
    $(document).on('click', '.select_grouping_field', function() {
        var grouping_field = $(this).attr('id');
        $('input[name=grouping_field]').val(grouping_field);
		$('form#search_query_grouping').submit();       
		return false;
    });
    	
	
	$('.add_kenmerkveld').click(function(){
	   show_kenmerken_popup();
       return false;
	
	});
	
	$(document).on('click', '.search_query_name .nieuw', function() {
	    $(this).closest('form').find('input[name=action]').val('reset');
        $(this).closest('form').submit();
        return false;
	});

	$(document).on('click', '.search_query_name .bewerk', function() {
	    var html_obj = $('input[name=search_query_name_hidden]');
	    fireDialog(html_obj);
	    return false;
	});
	
	
    // 20120217: what the hell doet dit? Het is irritant bij het klikken op
    // een toelichting onder zaakbehandeling > taken > kenmerken. Dus klikken
    // op vraagteken en dan op de gegeven toelichting klikken.
    $(document).on('click', '.dropdown', function() {
        // Workaround for above comment
        if ($(this).find('.dropdown-content').length) { return false; }

        $.ztWaitStart();
    });


    var hoverIntentConfig = {    
         over: showPreview, // function = onMouseOver callback (REQUIRED)    
         timeout: 500, // number = milliseconds delay before onMouseOut    
         out: hidePreview // function = onMouseOut callback (REQUIRED)    
    };

    //$('.doc_intake_row .doc-preview-init').hoverIntent(hoverIntentConfig);
    $(document).on('click', '.doc-preview-init', function() {
	$(this).addClass('active');
	$(this).closest('.doc_intake_row').addClass('active');
        showPreview($(this));
    });




    $(document).on('click', '.search_query_access', function() {
        var current = $('input[name=search_query_access_hidden]').val();
        
        if(current == 'public') {
            $('input[name=search_query_access_hidden]').val('private');
            $(this).removeClass('search_query_access_public');
            $(this).addClass('search_query_access_private');
        } else {
            $('input[name=search_query_access_hidden]').val('public');
            $(this).removeClass('search_query_access_private');
            $(this).addClass('search_query_access_public');
        }
        return false;
    });


    $('.export_zaaktype').click(function() {
        document.location.href = '/beheer/zaaktypen/118/export';
    });
});


function showPreview(click_element) {
    //var my_offset = $(this).offset();
    var preview_container = click_element.closest('.doc_intake_row');
    var preview_div = preview_container.find('.doc_preview');
    //preview_div.offset({ top: my_offset.top + 10, left: my_offset.left + $(this).width()/2 - 80 });
    
    var document_id = preview_container.attr('id');
    if(preview_div.data('current_thumbnail') == document_id) {
        preview_div.css('visibility', 'visible');
        preview_div.addClass('doc_preview_visible');
        return;
    }

    preview_container.find('.doc_preview_pijl').css('visibility', 'visible');
    preview_div.css('visibility', 'visible');
    preview_div.addClass('doc_preview_visible');
    preview_div.find('img').show();
    var params = { document_id : document_id };
    preview_div.load(
        '/zaak/documentpreview', 
        params,
        function(responseText, textStatus, XMLHttpRequest) {
            preview_div.data('current_thumbnail', document_id);
            if(textStatus == 'success') {
            } else {
               preview_div.html('<span>Er is een probleem opgetreden, ververs de pagina</span>');
            }
        }
    );        
}


function hidePreview() {
    // mouseout is handled by 'normal' code.. we don't like delayed hiding, we dig
    // delayed showing though. kudos to http://cherne.net/brian/resources/jquery.hoverIntent.html   
  //  $(this).find('.doc_preview').css('visibility', 'hidden');
}


function handle_kenmerk_selection(item) {
    var kenmerk_id = item.attr('id');
    var kenmerk_naam = item.find('.kenmerk_naam').html();

    $('input[name=additional_kenmerk]').val(kenmerk_id);
    $('form#search_presentation').submit();
	return false;
}


function show_kenmerken_popup() {

	$('#dialog').dialog(
		'option',
		'beforeclose',
		function() {
			$('#dialog').dialog(
				'option',
				'beforeclose',
				function() { }
			);
		}
	);

	// default fallback
	var url = '/beheer/bibliotheek/kenmerken/search';

    var params = {
                ezra_client_info_selector_identifier: 'disabledfunctionality',
                ezra_client_info_selector_naam: 'disabledfunctionality',
                jsversion: 3
        };


    $('#dialog .dialog-content').load(
        url, 
        params,
        function(responseText, textStatus, XMLHttpRequest) {
			$('#dialog').data('title.dialog', 'Filter instellingen');
			$('#dialog').addClass('smoothness').dialog('open');

        	if(textStatus == 'success') {
				$('.ztAccordion').accordion({
					autoHeight: false
				});
                ezra_zaaktype_select_kenmerk_search('handle_kenmerk_selection');
                veldoptie_handling();
				load_zaaktype();
			} else {
			    $('#dialog .dialog-content').html('Er is een probleem opgetreden, ververs de pagina');
			}
        }
    );
}




function updateZaakintakeFilename(my_input) {
    var doc_id = my_input.attr('rel');
	$('span#zaak_intake_edit_filename_error_' + doc_id).html('');
    var new_filename = my_input.val();
    if(new_filename.length < 1) {
   		$('span#zaak_intake_edit_filename_error_' + doc_id).html('Geef tenminste 1 karakter');
   		return;
    }
    var old_filename = $('input[name=zaak_intake_old_filename_' + doc_id + ']').val();


    var params = 'old_filename=' + old_filename + '&new_filename=' + new_filename;
    
	$.getJSON('/zaak/intake/changefilename?' + params, function(data) {
		if(data && data.json && data.json.result) {
            $('input[name=zaak_intake_old_filename_' + doc_id + ']').val(new_filename);
		} else {
		    my_input.focus();
    		$('span#zaak_intake_edit_filename_error_' + doc_id).html(data.json.message);
        }
	});  
}


//
// if the kenmerken table is present, add a kenmerk filter to it.
// if not, reload the filter page and request the addition of a kenmerk filter
// then add it.
//
function addKenmerkFilter() {
	if($(".kenmerken_container .ztAjaxTable").length) {	
		$(".kenmerken_container a.add.ztAjaxTable_add.float").click();
	} else {
		updateSearchFilters("action=show_kenmerken_filters");
	}
	veldoptie_handling();
}


var search_query_chart1;

function loadChart(selector) {
	var search_query_id = $('form input[name=SearchQuery_search_query_id]').val();
	var url = search_query_id ? "/search/" + search_query_id + "/results/chart" : "/search/results/chart";
	var data = selector.closest('form').serialize();
	
    $('#search_query_chart_container').html('<div class="spinner-groot"><div></div></div>');
    $('#search_query_chart_container').find('.spinner-groot').css('visibility', 'visible');

	//see how wide the chart is, so the exported graph will look the same
	var chart_width = $('#search_query_chart_container').width();

	$.getJSON(url + "?" + data, function(data) {
		var chart_data = data.json;

		chart_data.exporting = { width : chart_width };
        if(selector.val() == 'afhandeltermijn') {
            chart_data.tooltip = {
                formatter: function() {
                    return '<b>'+ this.point.name +'</b>: '+ this.y +' %';
                }
            };
        }
        if(chart_data.series) {
    		search_query_chart1 = new Highcharts.Chart(chart_data);
    	} else {
            $('#search_query_chart_container').html('Geen resultaten');
        }
	});
}


//
// Master function to update the result list of 'zaken'.
// The resultset is defined in the Perl controller level. This adjusts a few 
// additional variables influencing output and a text-matching filter
//
// TODO: Because multiple views can be used on the same page, always refresh only the current one
// through a AJAX call. Only the HTML for the current view should be updated.
//
function updateZaakResults(form_name) {
	//initializeSpinners();

	if(!form_name || !$('form[name=' + form_name +']').length) {
		form_name = zaken_filter_form_name;
	}

	var form_selector = 'form[name=' + form_name + ']';
    $(form_selector).find('.spinner-groot').css('visibility', 'visible');


	var data = 'nowrapper=1&' + $(form_selector).serialize();
	var current_path = $(location).attr('pathname');

    var grouping_choice_selector = '';
    
    var grouping_choice_object = $(form_selector + ' input[name=grouping_choice]');
    if(grouping_choice_object && grouping_choice_object.val()) {
        grouping_choice_selector = " #" + grouping_choice_object.val();
    }
    $(form_selector + grouping_choice_selector + ' .zaken_filter_wrapper').load(current_path + ' ' + form_selector + ' .zaken_filter_inner', data,		
	//$(form_selector + grouping_choice_selector + ' .zaken_filter_wrapper').load('/zaak/create/balie?tooltip=1', data,		
		function (responseText, textStatus, XMLHttpRequest) {
			if(textStatus == 'success') {
				veldoptie_handling();
				$(".progress-value").each(function() {
					$(this).width( $(this).find('.perc').html() + "%");
				});
				var total_entries = $(form_selector + ' input[name=total_entries]').val();
				if(total_entries) {
					$(form_selector + ' span.total_entries').html(total_entries);
				} else {
					$(form_selector + ' span.total_entries').html('0');
				}
			} else {
				$(form_selector + ' .zaken_filter_inner').html('Er is iets misgegaan, laad de pagina opnieuw');
			}
		}
	);

	return false;
}





function updateSearchFilters(data) {
	//initializeSpinners();
        $('.spinner-groot').css('visibility', 'visible');

	var my_form = $('form#search_filters');
	var search_query_id = $('form#search_filters input[name=SearchQuery_search_query_id]').val();
	if(!data) {
		data = my_form.serialize();
	}
	var url = "/search";
	if(search_query_id) {
		url = url + "/" + search_query_id;
	}

	if(!validateSearchFilters()) {
		return false;
	}
	$('.search_filters_wrap').load(url + ' .search_filters_inner', data,
		function () {
			$('#dialog').dialog('close');
			$("#accordion_search_filters").accordion({
				autoHeight: false,
				collapsible: true
			});
			activateCurrentSearchFilter();
			initialize_tabinterface();
			$('.ztAjaxTable').ztAjaxTable();
	
			$.ztWaitStop();

			if(data == 'action=show_kenmerken_filters' && $(".kenmerken_container .ztAjaxTable").length) {			
				$(".kenmerken_container a.add.ztAjaxTable_add.float").click();
			}
			veldoptie_handling();
	//		$("#accordion_search_filters").accordion('active', 0);
	});
}


function validateSearchFilters() {

	var filter_class = $('#update_search_filter input[name=filter_class]').val();

	if(filter_class == 'period') {
		var period_type = $("input[@name=period_type]:checked").val();
		if(period_type == 'specific') {
			var start_date = $('#update_search_filter input[name=start_date]').val();
			var end_date = $('#update_search_filter input[name=end_date]').val();
			if(!start_date && !end_date) {
				$('#update_search_filter #error_message').html('Geef een begin- of einddatum');
				return false;
			}
		}
	}

	if(filter_class == 'aanvrager') {
	    var my_value = $("input[name=ztc_aanvrager_id]");
        var my_select_value = $("select[name=ztc_org_eenheid_id] :selected");

	    if(!my_value.val() && !my_select_value.val()) {
			$('#update_search_filter #error_message').html('Kies een ' + filter_class);
    	    return false;
    	}
    }

	return true;
}


function activateCurrentSearchFilter() {
	var current_filter_type = $('#search_filters input[name=current_filter_type]').val();
	if(current_filter_type && $('#search_filter_holder_' + current_filter_type).length && 
		!$('#search_filter_holder_' + current_filter_type + '.ui-state-active').length) {
		$('#accordion_search_filters').accordion('activate', '#search_filter_holder_' + current_filter_type);
	}
}


/** zaaktypen_milestone_definitie functionaliteiten
 *
 */

/**
 *
 * DYNTABLE CONFIG CLASS
 *
 * init: Div $('.ezra_table').ezra_table();
 *
 * Table must consist of:
 * 1 table with class   : ezra_table_table
 * 1 teplate row, class : ezra_table_row_template
 * n rows to be ignored : ezra_table_row_ignore
 * n rows already there : ezra_table_row
 *
 * Class for row add button: ezra_table_row_add
 * Class for row del button: ezra_table_row_del
 * Class for unique input identifier: ezra_table_row_edit_identifier
 *
 * Possible callback:
 * Create an add button, like this:
 * <a href="#" class="ezra_table_row_add"
 *    rel="callback: callback_function" />
 *  It will receive:
 *    ezra_table object, added row, current rownumber
 *
 * Methods:
 * $('.ezra_table').ezra_table('add_row');
 *
 * Manual add a row
 */
(function($) {
    var methods = {
        init : function( options ) {
            var defaults    = {
                draggable: 1,
                num_rows: 0
            };

            var options     = $.extend(defaults, options);

            return this.each(function() {
                obj     = $(this);

                var $this   = $(this),
                    data    = $this.data('ezra_table');

                if (! data) {
                    table   = obj.find('.ezra_table_table');

                    /* Hide rows */
                    table.find('tr.ezra_table_row_ignore').hide();
                    table.find('tr.ezra_table_row_template').hide();

                    /* Count visible rows */
                    $(this).data('ezra_table', {
                        num_rows: table.find('tr.ezra_table_row').length
                    });

                    /* Find row add href */
                    obj.find('.ezra_table_row_add').click(function() {

                        obj.ezra_table('add_row');
                        return false;
                    });

                    /* Find row del href */
                    obj.find('.ezra_table_row_del').click(function() {
                        var ezra_table_table = $(this).closest('.ezra_table');
                        $(this).closest('tr').remove();
                        var options = obj.ezra_table('get_options', $(this).attr('rel'));
                        if(options.callback) {
                            window[options.callback]($(this),obj);
                        }
                        //ezra_table_table.ezra_table('update_table_information');
                        return false;
                    });

                    /* Find row edit href */
                    obj.find('.ezra_table_row_edit').click(function() {
                        obj.ezra_table('edit_row', $(this));
                        return false;
                    });
                }
            });
        },
        update_table_information: function() {
            var $this = $(this),
                data = $this.data('ezra_table');
            var obj     = $(this);

            if (!data) {
                return;
            }

            /* Make sure we update the element counter */
            var number_of_rows  = obj.ezra_table('get_num_rows');
            var table_name      = obj.attr('class').replace(/.*element_tabel_([a-zA-Z]+).*/, '$1');

            $('#milestone_acc_' + table_name + ' span.number').html(number_of_rows);
        },
        get_new_rownumber: function() {
            var $this = $(this),
                data = $this.data('ezra_table');

            var highest = 0;
            var table   = $(this).find('table');
            var obj     = $(this);

            table.find('.ezra_table_row').each(function() {
                var trclass = $(this).attr('class');
                if (!trclass.match(/ezra_table_row_number/)) {
                    return 0;
                }
                var rownumber    = trclass.replace(/.*ezra_table_row_number_(\d+).*/g, '$1');

                if (parseInt(rownumber) > parseInt(highest)) {
                    highest = parseInt(rownumber);
                }
            });

            if (highest < 1) {
                returnval = 1;
            } else {
                returnval = parseInt(highest) + parseInt(1);
            }

            /* Last check, if row is lower than initial numrows, do numrows */
            if (returnval <= data.num_rows) {
                return (data.num_rows + 1);
            }

            $(this).data('ezra_table',{
                num_rows: returnval
            });

            return returnval;
        },
        get_num_rows : function() {
            var table   = $(this).find('table');

            return table.find('.ezra_table_row').length;
        },
        get_options: function(get_options) {
            var rv = {};

            if (!get_options) { return {}; }

            /* Get sets */
            sets = get_options.split(/;/);

            for(i = 0; i < sets.length; i++) {
                set     = sets[i];
                keyval  = set.split(/:/);
                key     = keyval[0];
                key     = key.replace(/^\s+/g, '');
                key     = key.replace(/\s+$/g, '');
                value   = keyval[1];
                if (!value) { continue; }
                value   = value.replace(/^\s+/g, '');
                value   = value.replace(/\s+$/g, '');
                rv[key] = value;
            }

            return rv;
        },
        add_row: function (different_add_row_class) {
            var $this = $(this),
                data = $this.data('ezra_table');

            var clone   = $(this).find('.ezra_table_row_template').clone(true);
            var parent  = $(this).find('.ezra_table_row_template').parent();


            var nextrownumber = $(this).ezra_table('get_new_rownumber');

            /* Change row basics */
            if (clone.attr('id').match('row_number')) {
                clone.attr('id', clone.attr('id') + '_' + nextrownumber);
            }

            clone.removeClass('ezra_table_row_template')
                .addClass('ezra_table_row');
            clone.addClass('ezra_table_row_number_' + nextrownumber);


            /* Change every 'input/textarea/select field' to reflect rownumber */
            clone.find('input').each(function() {
                $(this).attr('name',
                    $(this).attr('name') + '.' + nextrownumber
                );
            });
            clone.find('select').each(function() {
                $(this).attr('name',
                    $(this).attr('name') + '.' + nextrownumber
                );
            });
            clone.find('textarea').each(function() {
                $(this).attr('name',
                    $(this).attr('name') + '.' + nextrownumber
                );
            });

            clone.find('.roworder').val(nextrownumber);

            /* show row */
            clone.show();

            parent.append(clone);

            clone.find('select.replace-select').selectmenu({
                style:'dropdown',
                width:150,
                maxHeight: '150'
            });

            var obj = $(this);

            obj.ezra_table('update_table_information');

            /* There could be a possible callback, RUN IT */
            var add_row_class = '.ezra_table_row_add';
            if (different_add_row_class) {
                add_row_class = different_add_row_class;
            }

            obj.find(add_row_class).each(function() {
                var add_options = obj.ezra_table('get_options', $(this).attr('rel'));
                if (add_options.newcallback) {
                    obj.ezra_table('search_dialog',$(this),add_options.newcallback,clone);
                } else if (add_options.callback) {
                    window[add_options.callback]($(this),obj,clone,nextrownumber);
                }
            });

            return clone;
        },
        edit_row: function(editobj) {
            identifier    = editobj.parents('tr').find('.ezra_table_row_edit_identifier').val();
            rowidentifier = editobj.parents('tr').attr('id');
            rownumber     = rowidentifier.replace(/.*_(\d+)/, '$1');

            var fire_elem = editobj.clone();
            var new_rel   = fire_elem.attr('rel');

            var options   = editobj.parents('div.ezra_table').ezra_table('get_options', fire_elem.attr('rel'));

            options['row_id']       = rowidentifier;
            options['rownumber']    = rownumber;
            options['edit_id']      = identifier;

            /*
             * START OPENING DIALOG
             */
            $.ztWaitStart();

            title = editobj.attr('title');
            url   = editobj.attr('href');

            /* Options ok, load popup */
            $('#dialog .dialog-content').load(
                url,
                options,
                function() {
                    $.ztWaitStop();
                    ezra_basic_functions();
                    
                    /* Find edit button */
                    $(this).find('form').submit(function() {
                        var formcontainer = $(this);
                        var serialized = $(this).serialize();
                        if(options['callback']) {
                            $(this).find('form').data('callback', options['callback']);
                        }

                        $.post(
                            url,
                            serialized,
                            function(data) {
                                if (options['callback']) {
                                    window[options.callback](formcontainer,editobj,rowidentifier);
                                }
                                $('#dialog').dialog('close');
                            }
                        );

                        return false;
                    });

                    openDialog(title, options['width'], options['height']);
                }
            );
        },
        search_dialog: function(addelem, callbackrequest, rowobj) {
            var $this = $(this),
                data = $this.data('ezra_table');

            rowidentifier = rowobj.attr('id');

            /* Append some options to href object */
            var fire_elem = addelem.clone();
            var new_rel   = fire_elem.attr('rel');
            if (new_rel) {
                new_rel = new_rel + '; '
            }

            new_rel = new_rel + 'row_id: ' + rowidentifier;
            fire_elem.attr(
                'rel',
                new_rel
            );

            /* Find hidden */
            $('#dialog').bind( 'dialogclose', function (event,ui) {
                    var ezra_table_table = rowobj.closest('.ezra_table');
                    rowobj.remove();
                    ezra_table_table.ezra_table('update_table_information');
                }
            );

            fireDialog(fire_elem);
        },
        update_row: function(rowid, data) {
            var update_row = $('#' + rowid);

            for (var rowident in data) {
                var content = data[rowident];

                element = update_row.find(rowident).each(function() {
                    if ($(this).get(0).tagName.toLowerCase() == 'input') {
                        $(this).val(content);
                    } else {
                        $(this).html(content);
                    }
                });
            }
        }
    };

    $.fn.ezra_table = function( method ) {
        // Method calling logic
        if ( methods[method] ) {
            return methods[ method ].apply( this, Array.prototype.slice.call( arguments, 1 ));
        } else if ( typeof method === 'object' || ! method ) {
            return methods.init.apply( this, arguments );
        } else {
            $.error( 'Method ' +  method + ' does not exist on jQuery.ezra_mijlpaal_configureren' );
        }
    };

})(jQuery);

/**
 *
 * MILESTONE CONFIG CLASS
 *
 * methods:
 * - none
 *
 */
(function($) {
    var methods = {
        init : function( options ) {
            var defaults    = {
                draggable: 0
            };

            var options     = $.extend(defaults, options);

            /* Hide tables which contain no rows DEPRECATED */
            /*
            $('.ezra_table').each(function() {
                if (! $(this).ezra_table('get_num_rows')) {
                    $(this).hide();
                }
            });
            */

            return this.each(function() {
                obj = $(this);

                obj.find('.add_element .element').each(function() {
                    if (options.draggable) {
                        $(this).draggable({
                            revert: true
                        })
                    }
                    $(this).click(function() {
                        methods.activate_element($(this));

                        return false;
                    });
                });


                if (options.draggable) {
                    $('.mijlpaal_content').droppable({
                        activeClass: "ui-state-hover",
                        accept: '.add_element',
                        drop: function(event,ui) {
                            methods.activate_element(ui.draggable);
                        }
                    });
                }
            });
        },
        activate_element : function(element) {           
            $('.mijlpaal_content .element_tabel_' + element.attr('id')).show();
            $('.mijlpaal_content .element_tabel_' + element.attr('id')).ezra_table('add_row');

            if (!$('#milestone_acc_' + element.attr('id')).hasClass('ui-state-active')) {
                $('#accordion_milestones')
                    .accordion('activate', '#milestone_acc_' + element.attr('id'));
            }            
        },
        fire_search_dialog : function(abutton,elemobj,rowobj,rownumber) {


        }
    };

    $.fn.ezra_mijlpaal_configureren = function( method ) {
        // Method calling logic
        if ( methods[method] ) {
            return methods[ method ].apply( this, Array.prototype.slice.call( arguments, 1 ));
        } else if ( typeof method === 'object' || ! method ) {
            return methods.init.apply( this, arguments );
        } else {
            $.error( 'Method ' +  method + ' does not exist on jQuery.ezra_mijlpaal_configureren' );
        }
    };

})(jQuery);


function ezra_zaaktypen_mijlpaaldefinitie() {
    //$('.mijlpaal_definitie .ezra_table').ezra_table();
    
    $(document).on('click', '.ezra_ajax_action', function() {
        var options  = $(this).ezra_table('get_options', $(this).attr('rel'));

        if (options.action == 'add') {
            var formdata = $(this).parents('form').serialize();

            formdata = formdata.replace(/zaaktype_update=1&?/, '');

            var href = $(this).attr('href');

            $(this).parents('form')
                .find('.ezra_ajax_widget')
                .load(
                    $(this).attr('href'),
                    formdata + '&action=' + options['action'],
                    function() {
                        window.location = href;
                    }
                );
        } else if (options.action == 'del') {
            $(this).parents('tr').remove();
        }

        return false;
    });
}

function ezra_zaaktypen_mijlpaaldefinitie_addrow(addbutton, table, row) {
   // alert (row.attr('class'));


}





function ezra_zaaktypen_mijlpalen() {
    if (!$('.mijlpaal_configureren').length) {
        return false;
    }

    $('.mijlpaal_configureren').ezra_mijlpaal_configureren();
    $('.mijlpaal_configureren .ezra_table').ezra_table();

    /* Move to other javascript ding */
    $('.ezra_table_row_edit').click(function() {
        var current_row = $(this).parents('tr');
    });

    /*
    $('.ezra_table_table th').click(function() {
            var table   = $(this).parents('table');

            table.find('tr.ezra_table_row').toggle(200);


    });
    */
}

function ezra_zaaktype_select_zaaktype(element, table, row, rownumber) {
    //$(this),obj,clone,nextrownumber
    $('.ezra_milestone_zaak_type').change();
    select_zaaktype('#' + row.attr('id') + ' .ezra_table_row_edit_identifier', '#' + row.attr('id') + ' .rownaam', '#' + row.attr('id'));
}

function ezra_zaaktypen_auth() {
    if (!$('.auth_definitie').length) {
        return false;
    }

    $('.auth_definitie .ezra_table').ezra_table();
}

function ezra_kenmerk_grouping(table) {

    table.find('.ezra_kenmerk_grouping_add').click(function() {
        $(this).parents('div.ezra_table').ezra_table('add_row', '.ezra_kenmerk_grouping_add');
        return false;
    });
}

function ezra_kenmerk_grouping_add_dialog(addelem,obj,clone,nextrownumber) {
    clone.find('span.rownaam').html('<b>Testgroup</b>');
    clone.addClass('ezra_kenmerk_grouping_group');

    rowidentifier = clone.attr('id');
    rownumber     = rowidentifier.replace(/.*_(\d+)/, '$1');

    var current_edit_href   = clone.find('.ezra_table_row_edit').attr('href');

    current_edit_href       = current_edit_href.replace(/kenmerk\/bewerken/, 'kenmerkgroup/bewerken');

    clone.find('.ezra_table_row_edit').attr('rel', 'callback: ezra_kenmerk_grouping_update_row');

    clone.find('.ezra_table_row_edit').attr('href', current_edit_href);

    /* Append some options to href object */
    var fire_elem = addelem.clone();
    var new_rel   = '';

    new_rel = 'row_id: ' + rowidentifier + '; callback: ezra_kenmerk_grouping_add_dialog_submit;';
    new_rel = new_rel + '; rownumber: ' + rownumber + '; uniqueidr: ' + rowidentifier;

    fire_elem.attr(
        'rel',
        new_rel
    );

    /* Find hidden */
    $('#dialog').bind( 'dialogclose', function (event,ui) {
            var ezra_table_table = clone.closest('.ezra_table');
            clone.remove();
            ezra_table_table.ezra_table('update_table_information');
        }
    );

    fireDialog(fire_elem);

}

function ezra_kenmerk_grouping_update_row(formobj,editobj, rowid) {
    var currenttr = editobj.closest('tr');

    var ezra_table  = $('#' + rowid).parents('div.ezra_table');
    var rownaam     = formobj.find('[name="kenmerken_label"]').val();

    ezra_table.ezra_table('update_row', rowid, {
        '.rownaam'      : rownaam
    });
}

function ezra_kenmerk_grouping_add_dialog_submit() {
    $('#kenmerk_definitie').find('form').submit(function() {
        /* Do Ajax call */
        var serialized = $(this).serialize();
        var container  = $(this).closest('#kenmerk_definitie');

        $.post(
            $(this).attr('action'),
            serialized,
            function(data) {
                var current_row_id = container.find('[name="uniqueidr"]').val();
                var ezra_table  = $('#' + current_row_id).parents('div.ezra_table');
                rownaam = container.find('[name="kenmerken_label"]').val();

                ezra_table.ezra_table('update_row', current_row_id, {
                    '.rownaam'      : rownaam
                });

                $('#dialog').unbind( 'dialogclose');
                $('#dialog').dialog('close');
            }
        );

        return false;
    });
}


function show_filter_popup(ftype, fvalue, search_query_id) {

	$('#dialog').dialog(
		'option',
		'beforeclose',
		function() {
            $('#dialog .dialog-content').html('');
		}
	);

	// default fallback
	var url = '/search/filter/edit';
	var params = { filter_type: ftype, filter_value: fvalue, SearchQuery_search_query_id : search_query_id };

	if(ftype == 'behandelaar' || ftype == 'coordinator') {
 		url = '/betrokkene/search';
        params = {
                ezra_client_info_selector_identifier: 'disabledfunctionality',
                ezra_client_info_selector_naam: 'disabledfunctionality',
                betrokkene_type: 'medewerker',
                jsversion: 3,
                search_filter_post: ftype                
        };
	} else if(ftype == 'zaaktype') {
 		url = '/zaaktype/search';
        params = {
                ezra_client_info_selector_identifier: 'disabledfunctionality',
                ezra_client_info_selector_naam: 'disabledfunctionality',
                betrokkene_type: 'medewerker',
                jsversion: 3,
                search_filter_post: 1
        };
	}


    $('#dialog .dialog-content').load(
        url, 
        params,
        function(responseText, textStatus, XMLHttpRequest) {
			$('#dialog').data('title.dialog', 'Filter instellingen');
			$('#dialog').addClass('smoothness').dialog('open');

        	if(textStatus == 'success') {
				$("#update_search_filter #start_date").datepicker();
				$("#update_search_filter #end_date").datepicker();

				var straatnaam = $("#update_search_filter .veldoptie_bag_adres_uitvoer input[name=bag_value_straatnaam]").val();
				$("#update_search_filter .veldoptie_bag_adres_invoer input[name=bag_value_straatnaam]").val(straatnaam);

				var huisnummer = $("#update_search_filter .veldoptie_bag_adres_uitvoer input[name=bag_value_huisnummer]").val();
				$("#update_search_filter .veldoptie_bag_adres_invoer input[name=bag_value_huisnummer]").val(huisnummer);

				$('#accordion').accordion({
					autoHeight: false
				});
				veldoptie_handling();
				load_zaaktype();
			} else {
			    $('#dialog .dialog-content').html('Er is een probleem opgetreden, ververs de pagina');
			}
        }
    );
}

function ezra_search_opties() {
    var ezra_table  = $('div.ezra_table').ezra_table();
}




