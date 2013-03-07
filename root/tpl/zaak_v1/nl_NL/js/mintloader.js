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


(function($) {
    var options = {
        dragndrop: 1,
        multiple: 0,
        speed: -1
    };
    
    var backgroundposition = 0;
    var intervalID;
    var semaphore = 0;

    var methods = {
        init : function(custom_options) {

            // there!
            var hasXhr2 = window.XMLHttpRequest && ('upload' in new XMLHttpRequest());
            if(!hasXhr2) return;
            $.extend(options, custom_options);
            return this.each(function() {
                var obj = $(this);
                if(options.dragndrop) {
                    // check if document dragging is already bound. in that case don't do anything with it
                    // this is for the scenario of multiple upload units
                    $(document).bind('dragover',  function(e) {
                        obj.mintloader('doFileDragHover', e, true);
                    });

                    $(document).bind('dragleave', function(e){
                        obj.mintloader('doFileDragHover', e, true); 
                    });

                    obj.mintloader('doBindDraggingEvents');
                }

                obj.find('.kiesbestand').click( function() {
                    obj.find('.fileToUpload').click();
                    return false;
                });

                 obj.find('input[type="file"]').change(function(e) {
                    var name = obj.attr('id');
                    if(semaphore) return;
                    obj.mintloader('fileSelected', name, e.target.files);
                });
            });
        },
  
        
        doBindDraggingEvents : function() {
            var obj = $(this);
            obj.bind('dragover',  function(e){
                obj.mintloader('doFileDragHover', e); 
            });

            obj.bind('dragleave', function(e){
                obj.mintloader('doFileDragHover', e); 
            });
        
            obj.bind("drop", function(e) {
                obj.mintloader('doFileSelectHandler', e);
            });
        },


        fileSelected : function(name, files) {
            var obj = $(this);

            var file = files[0];
            obj.find('.progressIndicator').show();
            
            var fileSize = 0;
            if (file.size > 1024 * 1024) {
              fileSize = (Math.round(file.size / (1024 * 1024))).toString() + 'MB';
            } else {
              fileSize = (Math.round(file.size / 1024)).toString() + 'KB';
            }
            previousBytesLoaded = 0;
        //    document.getElementById('uploadResponse').style.display = 'none';
            obj.find('.progressNumber').html('');
            var progressBar = obj.find('.progressBar');
            progressBar.show();
            progressBar.css('width', '0px');
            
            /* If you want to upload only a file along with arbitary data that
               is not in the form, use this */
            var fd = new FormData();
            fd.append("action", "upload");
            fd.append("fileToUpload", file);
            fd.append("file_id", name);
            
            /* If you want to simply post the entire form, use this */
            //var fd = document.getElementById('form1').getFormData();
            
            var xhr = new XMLHttpRequest();        

            intervalID = setInterval(function(){
                backgroundposition += options.speed;
                obj.find('.progressBar').css('background-position', backgroundposition + 'px');
            }, 50);
            
            obj.closest('form').find('.formOverlay').css('visibility', 'visible');
            semaphore = 1;
            obj.addClass('active');

            xhr.upload.addEventListener("progress", function(e) { obj.mintloader('uploadProgress', e);}, false);
            xhr.addEventListener("load", function(e){obj.mintloader('uploadComplete', e);}, false);
            xhr.addEventListener("error", function(e) {obj.mintloader('uploadFailed', e);}, false);
            xhr.addEventListener("abort", function(e) {obj.mintloader('uploadCanceled',e);}, false);
            
            
            var zaak_id = '0';
            if($('#zaak_id').attr('class')) {
                zaak_id = $('#zaak_id').attr('class');
            }
            xhr.open("POST", "/fileupload/"+zaak_id);
            xhr.send(fd);
            
        },
        
        uploadComplete : function(e) {
            var obj = $(this);
            uploadResponse = obj.find('.uploadResponse');
            obj.find('.kiesbestand').attr('value', 'Wijzig...');
            obj.find('.slepen').html('of sleep hier een ander bestand');

            if(options.multiple) {
                var current = uploadResponse.html();
                uploadResponse.html(current + e.target.responseText);
            } else {
                uploadResponse.html(e.target.responseText);
            }
            uploadResponse.show();
            
            // todo fade out
            obj.find('.progressIndicator').hide();
            clearInterval(intervalID); 
            var uploadResponse = obj.find('.uploadResponse');
            obj.mintloader('doBindDraggingEvents');
            
            // the upload will not clear, so to prevent
            obj.find('.fileToUpload').html(obj.find('.fileToUpload').html());
            obj.closest('form').find('.formOverlay').css('visibility', 'hidden');
            semaphore = 0;
            obj.removeClass('active');
        },



        uploadFailed : function(evt) {
            alert("An error occurred while uploading the file.");  
        },
    
    
        uploadCanceled : function(evt) {
            alert("The upload has been canceled by the user or the browser dropped the connection.");  
        },
    
        uploadProgress : function(evt) {
            var obj = $(this);
            if (evt.lengthComputable) {
                bytesUploaded = evt.loaded;
                bytesTotal = evt.total;
                var percentComplete = Math.round(evt.loaded * 100 / evt.total);
                var bytesTransfered = '';
                if (bytesUploaded > 1024*1024)
                    bytesTransfered = (Math.round(bytesUploaded*100/(1024*1024))/100).toString() + 'MB';
                else if (bytesUploaded > 1024)
                    bytesTransfered = (Math.round(bytesUploaded /1024)).toString() + 'KB';
                else
                    bytesTransfered = (Math.round(bytesUploaded)).toString() + 'Bytes';

//                obj.find('.transferBytesInfo').css('width', (obj.width() + 60).toString() + 'px');
                obj.find('.progressBarOuter').css('width', obj.outerWidth().toString() - 5 + 'px');
                obj.find('.progressBar').css('width', (obj.width() * percentComplete/100).toString() + 'px');
                obj.find('.transferBytesInfo').html(bytesTransfered);
            }
            else {
              obj.find('.progressBar').html('unable to compute');
            }  
        },
    
        doFileSelectHandler : function(e) {
            var obj = $(this);
            // only allow one upload at a time - until we go into multiple files territory
            if(semaphore) return;

            var files = e.originalEvent.dataTransfer.files;
            var name = obj.attr('id');
            // cancel event and hover styling
            obj.mintloader('doFileDragHover', e);
        
            obj.mintloader('fileSelected', name, files);
        },
    
    
    // todo escape knopje
    // todo laten zien welk bestand wordt opgeupladen
    // todo icons
        doFileDragHover : function(e, nocandy) {
            var obj = $(this);

            e.stopPropagation();
            e.preventDefault();

            if(semaphore) return;
            
            if(nocandy) return;
            if(e.type == 'dragover') {
                obj.addClass('hover');
            } else {
                obj.removeClass('hover');                
            }
        }
    };


    $.fn.mintloader = function(method) {
        // Method calling logic
        if ( methods[method] ) {
            return methods[ method ].apply( this, Array.prototype.slice.call( arguments, 1 ));
        } else if ( typeof method === 'object' || ! method ) {
            return methods.init.apply( this, arguments );
        } else {
            $.error( 'Method ' +  method + ' does not exist on jQuery.mintloader' );
        }
    };

})(jQuery);



    

function submitFileUpload() {
    var my_form = $('form.webform');
    
    var zaak_id = '0';
    if($('#zaak_id').length) {
        zaak_id = $('#zaak_id').attr('class');
    }

    my_form.find('.spinner-groot .spinner-groot-message').html('Een moment geduld, het bestand wordt toegevoegd.');
    my_form.find('.spinner-groot').addClass('hasText').css('visibility', 'visible');
    my_form.unbind('submit').submit();
    
    $('input[type="file"]').html($('input[type="file"]').html());

    // clean up
    $.ztWaitStop();
}