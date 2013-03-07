/**
 * Javascript used for site element searchbox
 */
function searchbox() {
    var searchbox = jQuery('input[name=trefwoord]');
    var currentvalue = searchbox.val();
    searchbox.focus(
        function() {
            if(this.value != '' && jQuery(this).hasClass('searchbox')) {
                this.value = '';
            }
        }
    );

    searchbox.blur(
        function() {
            if(this.value == '') {
                this.value = currentvalue;
            }
        }
    );
}

jQuery(document).ready(searchbox);
