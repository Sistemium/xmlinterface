Ext.regController('uiBuilder', {
    
    init: function(){
        this.app=i;
        this.uiState = '';
		
		Ext.regModel('Views',{
			fields: [
				{name: 'name', type: 'string'},
				{name: 'label', type: 'string'}
			],
			
			idProperty: 'name'
		});
		
		Ext.regStore ( 'views', {
			model: 'Views',
			proxy: {
				type: 'memory',
				reader: {
					type: 'json',
					root: 'views.menu.option'
				}
			}
		});
		
    },
    
	applyContext: function(options) {
		var c = this.serverContext = options.context;
		
		console.log ('uiBuilder.applyContext: ' + c);
		
        var viewState = (function() {
            var s = c.session;
            
            if (s) {
                if (s.id) {
                    if (c.views) {
                        if (c.views.view){
                            var vName='';
                            Ext.each(c.views.view, function(v){ vName = v.name; return false });
                            return  vName;
                        }
                        
                        var store = Ext.StoreMgr.get('views');
						
                        store.proxy.data = c;
                        store.load ({ synchronous: true });
                        
                        return 'mainMenu'
                    }
                }
            }
            
            return 'loginForm'
        })();
        
        if (viewState)
            Ext.dispatch({controller: 'uiBuilder', action: 'setUIState', state: viewState, context: c})
        else
            Ext.Msg.alert('uiBuilder', 'Undetermined ui state')
        ;
	},
	
    setUIState: function(options){
		
		var s = this.uiState = options.state;
		
		console.log ('uiBuilder.setUIState: ' + s);
		
		if (!(s && this.views[s])) {
			
            Ext.Msg.alert('uiBuilder', 'unknown state request: ' + s);
			
		}
		else {
			if (!this.app.views[s] || this.app.views[s].isDestroyed)
				this.app.views[s] = Ext.create(this.views[s]);
			this.app.viewport.setActiveItem( this.app.views[s] );
		}
        
        if (options.context.session && options.context.session.exception)
            Ext.Msg.alert(options.context.session.exception)
    },
    
    views: {
        
        loginForm: {
            xtype: 'form',
            layout: {type: 'vbox', pack: 'center'},
            submitOnAction: 'true',
            url: '../?pipeline=json&command=authenticate',
            items: [{
                    xtype: 'fieldset',
                    title: 'Пожалуйста, представьтесь',
                    items:[
                        {xtype: 'textfield', name: 'username', label: 'Имя', autoCapitalize:false, autoCorrect: false, autoComplete: false},
                        {xtype: 'passwordfield', name: 'password', label: 'Пароль'},
                ]},{
                    xtype: 'button',
                    text: 'Войти',
                    behaviour: 'submit',
                    handler: i.buttonHandler
            }],
            listeners:{
                exception: function(t,r){
					t.setLoading(false);
                    Ext.dispatch({controller:'main', action:'applyContext', context:t, response:r});
                },
                beforesubmit: function(t,v,o){
                    t.setLoading(true);
                }
            }
        },
        
        mainMenu: {
            xtype: 'panel',
            layout: 'fit',
            dockedItems:[{
                xtype: 'toolbar',
				layout: {type: 'hbox', pack: 'end'},
                items: [
                    {text: 'Выход', behaviour: 'logoff', handler: i.buttonHandler}
                ]
            }],
            items:[{
                xtype: 'list',
                itemTpl: '<div>{label}</div><small>{name}</small>',
                store: 'views',
                listeners: {
                    itemtap: i.listHandler,
                    refresh: function() {this.scroller.setOffset({y:0})}
                }
            }]
        }
        
    }
});