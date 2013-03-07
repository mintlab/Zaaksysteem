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
    $('form.zvalidate').submit( function() {
        return zvalidate($(this));
    });

    $('form').each(function() {
        if (!$(this).hasClass('zvalidate')) {
            $(this).submit(function() {
               $.ztWaitStart();
            });
        }
    });
});

function request_validation(formelem, extraopt, options) {
    var action = formelem.attr('action');

    /* Loop prevention */
    if (formelem.hasClass('validated'))         { return true; }
    if (formelem.hasClass('invalidation'))      { return false; }

    /* Validation in progress */
    formelem.addClass('invalidation');

    var serialized = validate_serialize_items(formelem, extraopt);

    //$.ztWaitStart();

    $.getJSON(
        action + '?do_validation=1&' + serialized,
        function(rawdata) {
            var data = rawdata.json;

            if (data.success) {
                //$.ztWaitStop();

                formelem.addClass('validated');
                formelem.removeClass('invalidation');

                if (options && options['events']['submit']) {
                    options['events']['submit'](formelem);
                } else {
                    formelem.submit();
                }

                return true;
            }

            validate_form_items(formelem, data);

            $.ztWaitStop();

            formelem.removeClass('invalidation');
            return false;
        }
    );

    return false;
}


function zvalidate(container, extraopt) {
    var action = container.attr('action');

    /* Loop prevention */
    if (container.hasClass('validated')) {
        if (container.hasClass('ezra_spiffy_spinner')) {
            ezra_spiffy_spinner_submit(container);
        }

        return true;
    }
    if (container.hasClass('invalidation')) {
        return false;
    }

    container.addClass('invalidation');

    /* Make sure we disable the button, time being */
//    container.find('input[type="submit"]').attr('disabled','disabled');

    /* Remove invalids */
    container.find('span.invalid').removeClass('invalid');
    container.find('span.valid').removeClass('valid');

    var serialized = validate_serialize_items(container, extraopt);

    if (!container.hasClass('ezra_spiffy_spinner')) {
        $.ztWaitStart();
    }

    $.getJSON(
        action + '?do_validation=1&' + serialized,
        function(rawdata) {
            var data = rawdata.json;

            if (data.success || (extraopt && extraopt.match(/&allow_cheat=1/))) {
                if (container.hasClass('ezra_spiffy_spinner')) {
                    $.ztWaitStop();
                }

                if (extraopt) {
                    extraopt = extraopt.replace(/&allow_cheat=1/, '');

                    if (container.attr('action').match(/\?/)) {
                        container.attr('action',
                            container.attr('action') + '&' + extraopt
                        );
                    } else {
                        container.attr('action',
                            container.attr('action') + '?' + extraopt
                        );
                    }
                }

                container.unbind('submit').submit();
                return true;
            }

            validate_form_items(container, data);

            $.ztWaitStop();
            container.removeClass('invalidation');
            return false;
        }
    );

    return false;
}


function validate_serialize_items(container, extraopt) {
    var serialized = container.serialize();

    /* Make sure we disable the button, time being */
//    container.find('input[type="submit"]').attr('disabled','disabled');
//    if (container.attr('class').match(/use_submit/) == 'use_submit' && extraopt) {
//        if (serialized) {
//            serialized += '&';
//        }
//
//        serialized += extraopt;
//    }

    if (extraopt) {
        if (serialized) {
            serialized += '&';
        }

        serialized += extraopt;
    }

    /* Ok, check file data */
    container.find('input[type="file"]').each(function() {
        serialized += '&' + $(this).attr('name')
            + '=' + $(this).val();
    });

    return serialized;
}


function validate_form_items(container, data) {
    container.find('input[type="submit"]').attr('disabled',null);
    container.find('span.validator,div.validator').hide();

    for (var i in data.missing) {
        var constraint_key = data.missing[i];
        var containingtd = container.find('[name="' + constraint_key + '"], .' + constraint_key).closest('td');
        if (data.msgs[constraint_key]) {
            if (containingtd.parents('tr').find('.validator').length) {
                containingtd.parents('tr').find('.validator').show().addClass('invalid').find('.validate-content').html('<span></span>' + data.msgs[constraint_key]);
            } else {
                containingtd.find('span').addClass('invalid').html(data.msgs[constraint_key]);
            }
        }
        containingtd.find('span.validator').show();
    }

    for (var i in data.invalid) {
        var constraint_key = data.invalid[i];
        var containingtd = container.find('[name="' + constraint_key + '"], .' + constraint_key).closest('td');
        if (data.msgs[constraint_key]) {
            if (containingtd.parents('tr').find('.validator').length) {
                containingtd.parents('tr').find('.validator').show().addClass('invalid').find('.validate-content').html('<span></span>' + data.msgs[constraint_key]);
            } else {
                containingtd.find('span').addClass('invalid').html(data.msgs[constraint_key]);
            }
        }
        containingtd.find('span.validator').show();
    }

    for (var i in data.valid) {
        var constraint_key = data.valid[i];
        var containingtd = container.find('[name="' + constraint_key + '"], .' + constraint_key).closest('td');
        if (!containingtd.parents('tr').hasClass('ignore-field-' + constraint_key)) {
            if (containingtd.parents('tr').find('.validator').length) {
                containingtd.parents('tr').find('.validator').hide().addClass('valid').find('.validate-content').html('<span></span>');
            } else {
                containingtd.find('span').addClass('valid');
            }
            containingtd.find('span.validator').show();
        }
    }
}
