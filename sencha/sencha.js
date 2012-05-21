Ext.regApplication({
    
    name: 'i',
    
    buttonHandler: function(b,e){
            Ext.dispatch({
                controller: 'main',
                action: 'userEvent',
				
                context: b,
                event: e
            })
    },
    
    listHandler: function(l,idx,el,ev){
            Ext.dispatch({
                controller: 'main',
                action: 'userEvent',
				
                context: l,
                event: ev,
				
                idx: idx,
                element: el
            })
    },
    
    launch: function() {
        
        this.viewport= new Ext.Panel({
            fullscreen: true,
            layout: 'card',
			cardSwitchAnimation: { type: 'slide', duration: 400 }
        });
        
        Ext.dispatch({controller: 'main', action: 'requestContext'});
	}
});