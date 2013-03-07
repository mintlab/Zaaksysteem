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

/*

triggered by a change in any input element, the webform is submitted and reloaded

*/


$(document).ready(function(){

    installWebformListener();    

});

function installWebformListener() {
    if (!$('form input[name="plugin"]').val()) {
        $('form.webform .webformcontent').find(
            '.regels_enabled_kenmerk input, .regels_enabled_kenmerk select,.regels_enabled_kenmerk textarea').change(function() {
            updateWebform($(this).closest('form.webform'));
        });
    }

    $('form.webform .webformcontent').find('input, select, textarea').change(function() {
        $(this).closest('form.webform').data('changed', 1);
    });
    
    
    // TRAC 1270 - prevent enter key submitting form
    $('form.webform input').on('keypress', function(event) {
    	if(event.which == 13) {
     		event.preventDefault();
   		}
    });

    $('form.webform  .webformcontent input.submit_to_previous').click(function() {
        var container = $('form.webform');
        var extraopt = 'submit_to_previous=1';
        var action = container.attr('action');
    
        if (action.match(/\?/))
            action += '&' + extraopt;
        else
            action += '?' + extraopt;
        
        container.attr('action', action);
        container.unbind('submit').submit();
        return false;
    });

    $('form.webform .webformcontent').find('input.submit_to_next').click(function() {
    	var extraopts = 'submit_to_next=1';
    	if($('form.webform input[name=allow_cheat]').val() == '1' &&
    		$('form.webform input[name=do_cheat]').is(':checked')) {
    		extraopts += '&allow_cheat=1';
    	}
        zvalidate($(this).closest('form'), extraopts);
        return false;
    });


    $('form.webform .webformcontent input.cancel_webform').click(function() {
        if ($("input[name='externe_login'][type='hidden']").val() == '1') {
            location.href='/form/cancel';
        } else {
            location.href='/';
        }

        return false;
    });



//    $('form.webform .webformcontent .fileUpload input:file').bind(($.browser.msie && $.browser.version < 9) ? 'propertychange' : 'change', function(){ 
//    $('form.webform .webformcontent .fileUpload input:file').unbind('change').change( function() {
//        setTimeout(submitFileUpload, 0);
//        submitFileUpload();
//console.log('oldschool');
//    });
    
}

function submitFileUpload() {
//    console.log('dssddsdsds' + $(this).val());
    var my_form = $('form.webform');
//    my_form.attr('target', 'miframe');
//    var saved_action = my_form.attr('action');
//    console.log('dssddsdsds1');
    
    var zaak_id = '0';
    if($('#zaak_id').length) {
        zaak_id = $('#zaak_id').attr('class');
    }

//    my_form.attr('action', '/fileupload/' + zaak_id);
//    my_form.find('.webform_inner').append('<input type="hidden" class="fileuploadfield" name="fileuploadfield" value="' + $(this).attr('name') + '" />');
    my_form.find('.spinner-groot .spinner-groot-message').html('Een moment geduld, het bestand wordt toegevoegd.');
    my_form.find('.spinner-groot').css('visibility', 'visible');
//    console.log('dssddsdsds2');
//       my_form.find('.spinner-groot').css('visibility', 'hidden');
    my_form.unbind('submit').submit();
//    console.log('dssddsdsds3');
    
    // clean up
//    my_form.find('fileuploadfield').remove();
//    my_form.attr('action', saved_action);
    my_form.attr('target', '');
    $.ztWaitStop();
//    my_form.find('.spinner-groot').css('visibility', 'hidden');
}


function updateWebform(my_form, callback) {
    $('.spinner-groot').css('visibility', 'visible');
    var serialized = my_form.serialize();
    var action = my_form.attr('action');
    
    my_form.find('.webformcontent').load(action + ' .webform_inner',
        serialized,
        function(responseText, textStatus, XMLHttpRequest) {
//    console.log('updateWebform' + responseText);
            installWebformListener(); 
            ezra_tooltip_handling();
            ezra_basic_functions();
            initializeEverything();
            if(callback) {
                callback();
            }
            $('.spinner-groot .spinner-groot-message').html('');
        }
    );
    
    return false;
}


function notifyUploadFinish(fileuploadfield, filestore_id, filename) {
    updateWebform($('form.webform'));
}
