$(document).ready(function() {
    $('a[rel=new_window]').after('<span class="new_window">(Link opent in een nieuw venster)</span>');
    $('a[rel=new_window]').click(function() {
        window.open(this);
        return false;
    });

});
