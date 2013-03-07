var bytesUploaded = 0;
var bytesTotal = 0;
var previousBytesLoaded = 0;

    
$(document).ready(function(){

    $(document).bind('dragover',  function(e){FileDragHover(e); });
    $(document).bind('dragleave', function(e){FileDragHover(e); });
//    $(document).bind('drop',      function(e){FileSelectHandler(e); });

    bindDraggingEvents('filedrag');
//    $('#filedrag').bind('dragover',  function(e){FileDragHover(e); });
//    $('#filedrag').bind('dragleave', function(e){FileDragHover(e); });
//    $('#filedrag').bind('drop',      function(e){FileSelectHandler(e); });


 //   var filedrag = document.getElementById('filedrag');
 //   console.log(filedrag);
//		filedrag.addEventListener("dragover", FileDragHover, false);
//		filedrag.addEventListener("dragleave", FileDragHover, false);
//		filedrag.addEventListener("drop", FileSelectHandler, false);
//		filedrag.style.display = "block";

    $('.kiesbestand').click( function() {
        $(this).attr('value', 'Wijzig...');
        $('.fileToUpload').click();
        return false;
    });

});

function bindDraggingEvents(element) {
    $('#' + element).bind('dragover',  function(e){FileDragHover(e); });
    $('#' + element).bind('dragleave', function(e){FileDragHover(e); });
//    $('#filedrag').bind('drop',      function(e){FileSelectHandler(e); });

    var filedrag = document.getElementById(element);
    if(!filedrag) 
        return;

    // with the jquery bind the received event doesn't contain file info
	filedrag.addEventListener("drop", FileSelectHandler, false);
}


// file drag hover
function FileDragHover(e) {
    e.stopPropagation();
    e.preventDefault();
    
    if(e.type == 'dragover') {
        $('#filedrag').addClass('hover');
    } else {
        $('#filedrag').removeClass('hover');
        
    }
}


// file selection
function FileSelectHandler(e) {
    console.log(e);
    // cancel event and hover styling
    FileDragHover(e);

    // fetch FileList object
    var files = e.target.files || e.dataTransfer.files;
    console.log("files: " + files);
    fileSelected(files);
}


function fileSelected(files) {      
    var file;
    if(files) { 
        file = files[0];
    } else {
        file  = document.getElementById('fileToUpload').files[0];
    }
    console.log(file);
    
    document.getElementById('progressIndicator').style.display = 'block';
    
    var fileSize = 0;
    if (file.size > 1024 * 1024)
      fileSize = (Math.round(file.size / (1024 * 1024))).toString() + 'MB';
    else
      fileSize = (Math.round(file.size / 1024)).toString() + 'KB';

    //        document.getElementById('fileInfo').style.display = 'block';
//    document.getElementById('fileName').innerHTML = 'Name: ' + file.name;
//    document.getElementById('fileSize').innerHTML = 'Size: ' + fileSize;
//    document.getElementById('fileType').innerHTML = 'Type: ' + file.type;
    
    previousBytesLoaded = 0;
//    document.getElementById('uploadResponse').style.display = 'none';
    document.getElementById('progressNumber').innerHTML = '';
    var progressBar = document.getElementById('progressBar');
    progressBar.style.display = 'block';
    progressBar.style.width = '0px';        
    
    /* If you want to upload only a file along with arbitary data that
       is not in the form, use this */
    var fd = new FormData();
    fd.append("action", "upload");
    fd.append("fileToUpload", file);
    
    /* If you want to simply post the entire form, use this */
    //var fd = document.getElementById('form1').getFormData();
    
    var xhr = new XMLHttpRequest();        
    xhr.upload.addEventListener("progress", uploadProgress, false);
    xhr.addEventListener("load", uploadComplete, false);
    xhr.addEventListener("error", uploadFailed, false);
    xhr.addEventListener("abort", uploadCanceled, false);
    xhr.open("POST", "/testupload");
    xhr.send(fd);
}



function uploadProgress(evt) {
    if (evt.lengthComputable) {
        bytesUploaded = evt.loaded;
        bytesTotal = evt.total;
        var percentComplete = Math.round(evt.loaded * 100 / evt.total);
        var bytesTransfered = '';
        if (bytesUploaded > 1024*1024)
            bytesTransfered = (Math.round(bytesUploaded/(1024*1024))).toString() + 'MB';
        else if (bytesUploaded > 1024)
            bytesTransfered = (Math.round(bytesUploaded /1024)).toString() + 'KB';
        else
            bytesTransfered = (Math.round(bytesUploaded)).toString() + 'Bytes';
            
        //console.log("transfered: " + bytesTransfered);
        document.getElementById('progressNumber').innerHTML = percentComplete.toString() + '%';
//        console.log("width: " + (percentComplete * 3.55));
        document.getElementById('progressBar').style.width = (percentComplete * 3.55).toString() + 'px';
        document.getElementById('transferBytesInfo').innerHTML = bytesTransfered;
        if (percentComplete == 100) {
            document.getElementById('progressIndicator').style.display = 'none';
             var uploadResponse = document.getElementById('uploadResponse');
            // uploadResponse.innerHTML = '<span style="font-size: 18pt; font-weight: bold;">Please wait...</span>';
             uploadResponse.style.display = 'block';
        }
    }
    else {
      document.getElementById('progressBar').innerHTML = 'unable to compute';
    }  
}


function uploadComplete(evt) {
    var uploadResponse = document.getElementById('uploadResponse');
    uploadResponse.innerHTML = uploadResponse.innerHTML + evt.target.responseText;
    uploadResponse.style.display = 'block';
        bindDraggingEvents('uploadResponse');

}  


function uploadFailed(evt) {
    alert("An error occurred while uploading the file.");  
}  


function uploadCanceled(evt) {
    alert("The upload has been canceled by the user or the browser dropped the connection.");  
}
