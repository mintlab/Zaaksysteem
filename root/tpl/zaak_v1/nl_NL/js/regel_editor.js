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

/**
 * Regel edit screen. You'll find this when configuring a zaaktype and adding or editing
 * or regel (rule)
 *
 * init: Div $('.whatever').regel_editor();
 *
 */
 

(function($) {
    var methods = {
        init : function( options ) {
            var defaults    = {
                draggable: 1,
                num_rows: 0
            };
            var options = $.extend(defaults, options);
            
            return this.each(function() {
                obj     = $(this);

                obj.find('input.numeric').ForceNumericOnly();
            	ezra_basic_zaaktype_functions();
                load_selectmenu();

                obj.find('select').change(function() {
                    var name = $(this).attr('name');
                    if(!name.match(/afhandeltermijntype/)) { 
                        obj.regel_editor('update_form', $(this));
                    }
                    return false;
                });
                
                obj.find('form input.save_regel').unbind('click').click(function() {
                    return obj.regel_editor('submit_form', $(this));
                });

                obj.find('.add_voorwaarde').click(function() {
                    obj.find('.regel_definitie_inner').append('<input type="hidden" name="add_voorwaarde" value="1"/>');
                    obj.regel_editor('update_form', $(this));                    
                    return false;
                });

                obj.find('.add_actie').click(function() {
                    obj.find('.regel_definitie_inner').append('<input type="hidden" name="add_actie" value="1"/>');
                    obj.regel_editor('update_form', $(this));                    
                    return false;
                });

                obj.find('.add_anders').click(function() {
                    obj.find('.regel_definitie_inner').append('<input type="hidden" name="add_anders" value="1"/>');
                    obj.regel_editor('update_form', $(this));                    
                    return false;
                });

                obj.find('.remove').click(function() {
                    $(this).closest('tr').remove();
                    obj.regel_editor('update_form', $(this));                    
                    return false;
                });
            });
        },

        // submit the whole form, have the backend send a re-rendered version
        update_form: function() {
            obj.find('.spinner-groot').css('visibility', 'visible');

            var params = obj.find('form').serialize() + '&update_regel_editor=1';
            var zaaktype_id = obj.find('input[name=zaaktype_id]').val();
            var milestone_number = obj.find('input[name=milestone_number]').val();
            obj.find('.regel_definitie_wrapper').load(
                '/beheer/zaaktypen/' + zaaktype_id + 
                '/bewerken/milestones/' + milestone_number + '/regel/bewerken' + ' .regel_definitie_inner', 
                params,
                function(responseText, textStatus, XMLHttpRequest) {
                    $.ztWaitStop();
                    if(textStatus == 'success') {
                        veldoptie_handling();
                        ezra_basic_zaak_intake();
                        $('#regel_definitie').regel_editor();
                    } else {
//                        console.log('Probleem opgetreden updateform');
                    }
                }
            );
        },

        // submit handler, update backend, then simply close the dialog.        
        submit_form: function() {
            var regel_title = obj.find('input[name=regels_naam]').val();
            if(regel_title.length == 0) {
                alert('Geef een naam op');
                return false;
            }
            $.ztWaitStart();

            var rownumber = obj.find('input[name=rownumber]').val();
            ezra_table_regel_edit_callback(obj.find('form'), null, 'ezra_table_regel_row_number_' + rownumber)

            var zaaktype_id = obj.find('input[name=zaaktype_id]').val();
            var milestone_number = obj.find('input[name=milestone_number]').val();
            var params = obj.find('form').serialize();

            // the result of this post is discarded, since the page is already visible and we just update it ajax style.
            obj.load('/beheer/zaaktypen/' + zaaktype_id + 
                '/bewerken/milestones/' + milestone_number + '/regel/bewerken #trash_the_results_we_just_want_to_inform_the_server',
                params,
                function(responseText, textStatus, XMLHttpRequest) {
                    $.ztWaitStop();
                    $('#dialog').dialog('close');
                }
            );
            return false;
        }
    };

    $.fn.regel_editor = function(method) {
        // Method calling logic
        if ( methods[method] ) {
            return methods[ method ].apply( this, Array.prototype.slice.call( arguments, 1 ));
        } else if ( typeof method === 'object' || ! method ) {
            return methods.init.apply( this, arguments );
        } else {
            $.error( 'Method ' +  method + ' does not exist on jQuery.regel_editor' );
        }
    };

})(jQuery);


// when editing a regel item, make sure its name is updated in the Ezra tabel after closing 
// the dialog. at the same time it's being transmitted to the backend.
function ezra_table_regel_edit_callback(formobj,editobj, rowid) {
    var ezra_table  = $('#' + rowid).parents('div.ezra_table');
    var rownaam     = formobj.find('[name="regels_naam"]').val();
    ezra_table.ezra_table('update_row', rowid, {
        '.rownaam'      : rownaam
    });
}



jQuery.fn.ForceNumericOnly =
function()
{
    return this.each(function()
    {
        $(this).keydown(function(e)
        {
            var key = e.charCode || e.keyCode || 0;
            // allow backspace, tab, delete, arrows, numbers and keypad numbers ONLY
            return (
                key == 8 || 
                key == 9 ||
                key == 46 ||
                (key >= 37 && key <= 40) ||
                (key >= 48 && key <= 57) ||
                (key >= 96 && key <= 105));
        });
    });
};


