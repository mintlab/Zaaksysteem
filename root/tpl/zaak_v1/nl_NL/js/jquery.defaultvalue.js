jQuery.fn.DefaultValue = function(default_text){
    return this.each(function(){
		//Make sure we're dealing with text-based form fields
		if(this.type != 'text' && this.type != 'password' && this.type != 'textarea')
			return;
		
		//Store field reference
		var fld_current=this;
		
		//Set value initially if none are specified
        if(this.value=='') {
			this.value=default_text;
			$(this).addClass('default_value');
		} else {
			//Other value exists - ignore
			return;
		}
		
		//Remove values on focus
		$(this).focus(function() {
			if(this.value==default_text || this.value=='')
				this.value='';
				$(this).removeClass('default_value');
		});
		
		//Place values back on blur
		$(this).blur(function() {
			if(this.value=='')
				$(this).addClass('default_value');
			if(this.value==default_text || this.value=='')
				this.value=default_text;
		});
		
		//Capture parent form submission
		//Remove field values that are still default
		$(this).parents("form").each(function() {
			//Bind parent form submit
			$(this).submit(function() {
				if(fld_current.value==text) {
					fld_current.value='';
				}
			});
		});
    });
};
