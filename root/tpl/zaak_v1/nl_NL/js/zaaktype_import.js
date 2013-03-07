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



$(document).ready(function() {


    initZaaktypeImportQtip();
    
    $('.import_dependency').on('click', '.options a.info', function() {
        if($(this).hasClass('active')) {
            $(this).removeClass('active');
        } else {
            $('.options a.info').removeClass('active');
            $(this).addClass('active');
        }
        return false;
    });
    
    $('.update_zaaktype_export').click( function() {
        var zaaktype_id = $('input[name="zaaktype_id"]').val();
        $('#zaaktypexmldoc').load(
            '/beheer/zaaktypen/' + zaaktype_id + '/export',
            function(responseText, textStatus, XMLHttpRequest) {
            }
        );
    });
    $('.import_zaaktype').click( function() {
        $(this).closest('form').submit();
    });

    
    $('.import_dependency').on('click', '.import_dependency_status .revert', function() {
        var item = $(this).closest('.import_dependency_item');
        var import_dependency_status = item.find('.import_dependency_status');
        var status_open = import_dependency_status.hasClass('open');
        var dependency_type = item.find('input[name="dependency_type"]').val();
        var id = item.find('input[name="id"]').val();
        var serialized = 'action=revert&dependency_type=' +dependency_type +'&id=' + id;
        import_dependency_status.find('.spinner-klein').show();
        import_dependency_status.find('.toggle').hide();

        item.load(
            '/beheer/zaaktypen/import/approve', 
            serialized,
            function(responseText, status) {
                initZaaktypeImportQtip();
                if(status_open) { // keep current state   
                    var ids = item.find('.import_dependency_status');
                    showAdjustment(ids);
                }
                import_dependency_status.find('.spinner-klein').hide();
                import_dependency_status.find('.toggle').show();

            }
        );
        return false;
    });

    $('.import_dependency').on('click', '.import_dependency_option', function(event) {
        activateOption($(this));
    });

    $('.import_dependency').on('click',  '.import_dependency_status', function(event) {
        showAdjustment($(this));
        return false;
    });
    

    $('.import_dependency_status').on('change', '.import_dependency_option select', function() {
        import_dependency_option = $(this).closest('.import_dependency_option');
        activateOption(import_dependency_option);
    });

    $('.import_dependency').on('click', '.import_dependency_option input[type="button"]', function(event) {
        var adjustment = $(this).closest('.import_dependency_adjustment');
        var action = $(this).closest('.import_dependency_option').attr('id');
        adjustDependency(adjustment, action);
        return false;
    });

    $('.import_dependency').on('keypress', '.import_dependency_option input[name=new_name]', function(event) {
        if(event.which == 13) {
            event.preventDefault();
            var adjustment = $(this).closest('.import_dependency_adjustment');        
            var action = $(this).closest('.import_dependency_option').attr('id');
            adjustDependency(adjustment, action);

            return false;
        }
    });

    $('.import_dependency_option input[type=text]').unbind('on');


    $('.import_dependency').on('click',  '.import_dependency_approve', function() {
        var adjustment = $(this).closest('.import_dependency_adjustment');
        adjustDependency(adjustment);
        return false;
    });

    $('.ezra_import_do_upload').click(function() {
        //var filestore_id = $('.ezra_import_mintloader').find('input[name="filestore_id"]').val();
        $(this).closest('form').attr('action', '/beheer/zaaktypen/import/upload');
    });
});


function activateOption(import_dependency_option) {
    import_dependency_option.closest('.import_dependency_adjustment').
        find('.import_dependency_option').
        removeClass('import_item_active');

    if(!import_dependency_option.hasClass('import_item_active')) {
        import_dependency_option.addClass('import_item_active');
    }
}

function showAdjustment(import_dependency_status) {
    var adjustment = import_dependency_status.closest('.import_dependency_item').find('.import_dependency_adjustment');
    var toggler = import_dependency_status.closest('.import_dependency_item').find('.import_dependency_status');
    
    var serialized = serializePartial(import_dependency_status);
    import_dependency_status.find('.spinner-klein').show();
    import_dependency_status.find('.toggle').hide();
    adjustment.load(
        '/beheer/zaaktypen/import/adjust',
        serialized,
        function(responseText, status) {
            adjustment.toggle();
            toggler.toggleClass('open');
            //dependency_status.toggle();
            load_selectmenu_import();
            import_dependency_status.find('.spinner-klein').hide();
            import_dependency_status.find('.toggle').show();
        }
    );
}

function initZaaktypeImportQtip() {
    $('.options a.info[title]').qtip({
	   position: {
          my: 'top right',  // Position my top left...
          at: 'bottom left', // at the bottom right of...
          adjust: {
                 x: 15,
                 y: 2
              }
        },
        style: {
              tip: {
                 corner: 'top right',
                 //mimic: 'right center',
                 offset:5
              }
        },
        show: {
            event: 'click',
            solo: true // Only show one tooltip at a time
         },
         hide: {
              event: 'click'
           }
    });
}


function adjustDependency(adjustment, action) {

    adjustment.find('input[name="action"][type="hidden"]').val(action);

    if(action == 'add') {
        var new_name_input = adjustment.find('input[name="new_name"]');
        new_name_input.val();

        var serialized = serializePartial(adjustment);
        $.getJSON('/beheer/zaaktypen/import/validate', serialized,
            function(data) {
                if(data.json.success) {
                    sendAdjustDependency(adjustment);
                } else {
                    var import_dependency_option = new_name_input.closest('.import_dependency_option');
                    if(data.json.categorie_error) {
                        import_dependency_option.find('.import_dependency_categorie_error').show().find('.import_error_tooltip_text').
                            html(data.json.categorie_error);                
                    }
                    if(data.json.sub_categorie_error) {
                        import_dependency_option.find('.import_dependency_sub_categorie_error').show().find('.import_error_tooltip_text').
                            html(data.json.sub_categorie_error);                
                    }
                    if(data.json.error) {
                        import_dependency_option.find('.import_dependency_error').show().find('.import_error_tooltip_text').
                            html(data.json.error);                
                    }
                }
        });

    } else if(action == 'use_existing') {
        var new_id_select = adjustment.find('select[name=new_id]');
        var new_id = new_id_select.val();

        if(new_id > 0) {
            sendAdjustDependency(adjustment);
        } else {
            new_id_select.closest('.import_dependency_option').find('.import_dependency_error').show().find('.import_error_tooltip_text').html('Maak een keuze');
        }
    } else {
        action('incorrect action ' + action + ' used');//TODO remove
    }
}



function sendAdjustDependency(adjustment) {
    // Inform the server of the new situation. Gather all input elements and send them.
    var serialized = serializePartial(adjustment);
//console.log('serialized: '  + serialized);
    var item = adjustment.closest('.import_dependency_item');
    var url = '/beheer/zaaktypen/import/approve';
    
    //checked
    var multi_cat = adjustment.find('input[name=multi_cat]').is(':checked');
    item.load(
        url,
        serialized,
        function(responseText, status) {
            if(multi_cat) {
                var import_dependency = item.closest(".import_dependency");
                reloadDependencyGroup(import_dependency);
            }
            initZaaktypeImportQtip();
        }
    );
}


function reloadDependencyGroup(import_dependency) {
    var dependency_type = import_dependency.find('input[name="dependency_type"]').val();
    import_dependency.find(".spinner-groot").css('visibility', 'visible');
    

    import_dependency.load(
        '/beheer/zaaktypen/import .ezra_' + dependency_type + ' .ezra_import_dependency_group_inner',
        function(responseText, status) {
            initZaaktypeImportQtip();
        }
    );
}




function serializePartial(parent) {
    var serialized = '';

    parent.find('input, select, textarea').each( function() {
        if(serialized) {
            serialized += "&";
        }
        serialized += $(this).serialize();
    });
    
    return serialized;
}
