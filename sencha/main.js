Ext.regController( 'main', {
    
    init: function(){
        this.initialized=true;
    },
    
    userEvent: function(options){
        console.log('main.userEvent');
        
        Ext.dispatch( Ext.apply( options, { action: options.context.xtype + 'Handler' } ));
        
    },
    
    buttonHandler: function(options){
        var b = options.context;
        
        console.log('main.button: '+b.text );
        
        switch (b.behaviour){
            case 'submit':
                b.up('form').submit();
                break;
            case 'logoff':
                Ext.dispatch( { controller: 'main', action: 'requestContext', params: {command: 'logoff'}});
                break;
        }
    },
    
    listHandler: function(options){
        var l = options.context,
            s = l.getStore(),
            r = s && s.getAt(options.idx),
            itemId = r && r.get(r.idProperty)
        ;
        
        console.log('main.list: '+s.storeId+' item.id: '+ (r && itemId));
        
        if (!s.storeId) return;
        
        Ext.dispatch( Ext.apply( options, {
            action: s.storeId+'Handler',
            itemId: itemId
        }));
        
    },
    
    viewsHandler: function(options) {
        var view = options.itemId;
        console.log ('main.viewsTap: '+view);
        
        if (view)
            this.requestContext( Ext.apply( options, { params: { views: view } } ))
    },

    applyContext: function(options)  {
        console.log('main.applyContext: '+ options.response);
        
        try {
			
			var c = options.response.context || Ext.decode(options.response.responseText).context;
			
        } catch (e) {
            if (options.response.request.params)
                Ext.Msg.alert('main.applyContext', 'decode fatal error')
            else {
                Ext.dispatch( { controller: 'main', action: 'requestContext' } );
                console.log('main.applyContext decode error, resend request');
            }
        }
		
		if (c) Ext.dispatch( Ext.apply ( options, {
			controller: 'uiBuilder',
			context: c
		}))
    },
    
    requestContext: function(o) {
		console.log ('main.requestContext: ' + o);
		
        var r = {
            url: '../?pipeline=json',
            params: o.params,
            success: function(r) {
                Ext.dispatch({controller: 'main', action: 'applyContext', response: r })
            }
        };
        
        if (o.context && o.context['setLoading']){
            o.context.setLoading(true);
            r.callback = function() {o.context.setLoading(false)};
        };
        
        Ext.Ajax.request(r)
    }
 
});