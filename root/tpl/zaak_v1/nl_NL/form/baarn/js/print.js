jQuery(document).ready(function(){
    jQuery('.btn_print').show();
    jQuery('.btn_print').click(function(e) {
        window.print();
        e.preventDefault();
    });
});
