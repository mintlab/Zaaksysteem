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

    /* navigatie inklapbaar maken en cookies zetten */
    $('#leftcolumn').bind('contentChange', function() {
        $('.nav-title').click(function() {
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

        $('.vert-one').each(function() {
            var menuContent = $.cookie($(this).attr('id'));
            if (menuContent == "collapsed") {
                $("#" + $(this).attr('id')).hide();
                //$("#" + $(this).attr('id')).prev().children(".menuImgClose").addClass("menuIconOpen");
            }
        });
    });

    /* selectmenu rechtsboven */
    $('#topsection').bind('contentChange', function() {
        $('select#keuzes').selectmenu({
            transferClasses: true,
            width: 130,
            style: 'dropdown',
            maxHeight: 120
        });
    });

});
