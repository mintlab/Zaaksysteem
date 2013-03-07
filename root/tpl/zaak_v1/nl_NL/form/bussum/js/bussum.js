$(document).ready(function(){

     $('#jpcarousel').carouFredSel({
            visibleItems: 5,
            direction	: 'right',
            autoPlay	: 0,
            scroll      : {
                items		: 1,
                effect		: 'jswing',
                speed		: 700,
                pauseOnHover: 1,
                onBefore	: '',
                onAfter		: ''
            },
            auto : {
                 pauseDuration:  1500
            },
            next : {
                button		: jQuery('.carouselnext'),
                key			: 'right'
            },
            prev : {
                button		: jQuery('.carouselprev'),
                key			: 'left'
            },
            buttons : {
                        items       : 2,
                        effect      : 'jswing',
                        speed       : 400
                    }
        }
     );
});