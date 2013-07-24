Ext.data.XmlInterface = Ext.extend( Ext.util.Observable, {
    
    isXmlInterface: true,
    
    listeners: {
        tableload: function(t) {
            console.log ('XmlInterface.tableload complete: ' + t + ', remainging requests: ' + (this.downloadSession ? this.downloadSession.activeRequests.length : 0));
            if (this.downloadSession && this.downloadSession.activeRequests.length == 0) {
                console.log ('XmlInterface download complete');
                delete this.downloadSession;
                this.fireEvent ('downloadfull');
            }
        }
    },
    
    remoteParams: function(c) {
        
        if (c.command == undefined) return c;
        
        var params = {
            
            login: { command: 'authenticate' },
            logoff: { command: 'logoff' },
            openView: { views: this.view },
            metadata: { pipeline: 'metadata', metadata: 'view' },
            download: { pipeline: 'download' },
            upload: { pipeline: 'rawpost' }
            
        }[c.command];
        
        if (c.command=='login') {
            if (this.accessToken) {
                params['access_token'] = this.accessToken;
            } else {
                params.username=this.username;
                params.password=this.password;
            }
        }
        
        var options = {
            params: Ext.apply (c.params || {}, params)
        };

        if (c.command!='upload' && this.noServer) {
            var url = location.protocol+'//'+location.host+location.pathname,
                urlp = '';
            
            switch (c.command) {
                case 'login':
                case 'logoff':
                case 'openView':
                    urlp = 'main.out';
                    break;
                case 'metadata':
                    urlp = 'metadata.clean';
                    break;
                case 'download':
                    urlp = 'download.out';
                    break;
                default:
                    urlp = 'main.out';
            }
            
            if (c.command != 'metadata')
                url += '../SampleData/iorders/'
            ;
            
            options = {
                url: url+'dump.datasync.'+urlp+'.xml'
            };
            
        }
        
        return options;
    },
    
    constructor: function(config){
        
        var me = this;
        
        me.addEvents(
            'login',
            'logoff',
            'authenticate',
            'response',
            'remotelogin',
            'remotelogoff',
            'uploadrecord',
            'upload',
            'tableload',
            'tableloadfull',
            'downloadfull'
        );
        
        me.timeouts = {};
        
        Ext.apply(this, config || {}, { sessionData: {} } );
        
        Ext.data.XmlInterface.superclass.constructor.call(this, config);
        
        var url = location.protocol+'//'+location.host
                +location.pathname.slice(0,location.pathname.substr(0,location.pathname.length - 1).lastIndexOf('/'))
        ;
        
        if (this.urlPrePath) url += this.urlPrePath;
        
        url += '/XML/?config=datasync';
        
        this.connection = new Ext.data.Connection ({
            url: url,
                
            listeners: {
                
                beforerequest: function(c,o) {
                    console.log('XmlInterface.request dispatch ('+(o.command || '')+')')
                },
                
                requestcomplete: function(c, r, o) {
                    console.log('XmlInterface.request complete ('+(o.command || '')+'); response length: ' + r.responseText.length);
                    
                    me.lastSuccess = new Date();
                    
                    if (typeof o.command == 'string'){
                        me.fireEvent(o.command,r);
                    }
                },
                
                requestexception: function(c, r, o) {
                    console.log('XmlInterface.request exception ('+(o.command || '')+'); status: ' + r.status + ' ('+r.statusText+')')
                    me.cleanDownloadSession (r);
                    
                    if (typeof o.command == 'string')
                        setTimeout( function () {
                                var rr = me.connection.request(
                                    Ext.applyIf({ failure: false }, o)
                                );
                                
                                if (me.downloadSession && o.command=='download')
                                    me.downloadSession.activeRequests.push (rr)
                                ;
                            }, me.retryDelay() + (r.timedout === true ? o.timeout : 0)
                        )
                    ;
                }
                
            },
            
            abort : function(r) {
                if (r && this.isLoading(r)) {
                    if (!r.timedout) {
                        r.aborted = true;
                    }
                    
                    r.xhr.abort();
                }
                else if (!r) {
                    var id;
                    for(id in this.requests) {
                        if (!this.requests.hasOwnProperty(id)) {
                            continue;
                        }
                        this.abort(this.requests[id]);
                    }
                }
            }
            
        });
        
    },
    
    retryDelay: function(){
        return location.protocol == 'https' ? 20000 : 6000;
    },
    
    cleanDownloadSession: function(r) {
        if (this.downloadSession) {
            Ext.each(this.downloadSession.activeRequests, function(cr, i, ar){
                if (cr.id == r.requestId) {
                    ar.splice(i,1);
                    return false;
                } else return true
            })
        }
    },
    
    request: function(options) {
        
        if (! Ext.isObject(options))
            options = {command: options};
        
        var r = this.connection.request(Ext.apply({
                scope: this
            },
            Ext.apply( options || {}, this.remoteParams( options ) || {} ),
            { url: this.connection.url
                + (this.username
                   ? '&username=' + this.username
                   : ''
                )
                + ((this.downloadSession && this.downloadSession.requestsParams)
                    ? ('&ql=' + (this.downloadSession.requestsParams.length ? this.downloadSession.requestsParams.length : 0))
                    : ''
                )
                + ((options.params && options.params.filter)
                    ? ('&fv=' + options.params.filter)
                    : ''
                )
            }
        ));
        
        if (this.downloadSession && options.command=='download')
            this.downloadSession.activeRequests.push (r);
            
        return r;
        
    },
    
    isBusy: function() {
        var res = false;
        
        
        res || Ext.iterate (this.timeouts, function (r) {
            if (r) {
                res = true;
                return false;
            };
            
            return true;
        });
        
        res || Ext.iterate (this.connection.requests, function (r, idx, rs) {
            if (r) {
                res = true;
                return false;
            }
            return true;
        });
        
        return res;
    },

    reconnect: function(o) {
        
        if ( !this.sessionData.id ){
            console.log ('XmlInterface.reconnect logoff');
            this.request( {
                command: 'logoff',
                success: function() {
                    this.sessionData.id = false;
                    this.login(o)
                }
            })
        } else 
            this.login (o)
    },
    
    login: function(o) {
        
        var me=this;
        
        this.request (Ext.applyIf({
            command: 'login',
            success: function(response, so) {
                
                if (response && response.responseXML) {
                    var node = Ext.DomQuery.selectNode('session', response.responseXML);
                    
                    if (node && node.hasAttribute('id')){
                        console.log (
                            'XmlInterface.login success: session.id='
                            +(this.sessionData.id = String(node.getAttribute('id')))
                        );
                        
                        if (node.hasAttribute('username')) {
                            me.username=node.getAttribute('username');
                        } else {
                            console.log ('XmlInterface.login no-username');
                        }
                        
                        if (node.hasAttribute('user-label')) {
                            me.userLabel=node.getAttribute('user-label');
                        }
                        
                        this.request ( Ext.apply ({command: 'openView'}, o || {}));
                    }
                    else {
                        var etext = node.getAttribute('exception');
                        console.log ('XmlInterface.login exception: ' +etext );
                        console.log (response.responseXML);
                        if (so.failure)
                            so.failure.call(this, Ext.apply (response, {exception: etext} ), so);
                    }
                }
            }
        },o));
    },
    
    xml2obj: function (inputNode){
        var result = {},
            setOf = false,
            me = this;
            
        if (inputNode.attributes) {
            setOf = inputNode.getAttribute('set-of');
            
            if (setOf)
                result = []
            else
                Ext.each (inputNode.attributes, function(attr, idx, attrs) {
                    result [attr.nodeName] = attr.nodeValue
                })
            ;
        }
        
        Ext.each ( inputNode.childNodes, function(node,idx,nodes) {
            var o = node.nodeValue || true;
            
            if (node.nodeName=='tpl') {
                result['template'] = new XMLSerializer().serializeToString(node);
                result['template'] = result['template'].replace(/( xmlns="[^"]*")/,'');
                return;
            }
            
            if (node.childNodes.length > 0 || node.attributes)
                o = me.xml2obj(node);
            
            if (setOf && (setOf == node.nodeName))
                result.push( o )
            else {
                if (result[node.nodeName] == undefined)
                    result[node.nodeName] = o
                else {
                    if (Ext.isArray(result[node.nodeName]))
                        result[node.nodeName].push (o)
                    else
                        result[node.nodeName] = [result[node.nodeName],o]
                }
            }
        })
        
        return result;
    },
    
    requestDownload: function (table, engine) {
        
        var r = {
            
            command: 'download',
            scope: engine,
            timeout: 120000,
            xi: this,
            params: {filter: table},
            
            success: function (response, opts) {
                engine.processDowloadData (response, opts);
            }
        };
        
        r.params[table] = 'unchoose';
        
        this.request (r);
        
    },

    download: function( engine ) {
        
        var me = this;
        
        var processSuccessfullResponse = function(response, opts) {
            
            var nextRequestParams = me.downloadSession.requestsParams.pop();
            
            engine.processDowloadData (response, opts);
            
            if (nextRequestParams)
                me.request(nextRequestParams);
            else
                console.log ('Ext.data.XmlInterface processSuccessfullResponse error')
            ;
            
        }
        
        var requestsQueue = ( function() {
            
            var res = [],
                params = {
                    command: 'download' ,
                    timeout: 120000,
                    scope: engine,
                    success: processSuccessfullResponse,
                    xi: me
                }
            ;
            
            if ( !me.noServer && Ext.ModelMgr.getModel('Table').prototype.fields.get('level') )
                Ext.each (engine.tables, function(t) {
                    if ( t.level == 0 ) {
                        me.fireEvent ('beforetableload', t.id);
                        
                        params.params = {filter: t.id};
                        params.params[t.id] = 'unchoose';
                        
                        res.splice (0, 0, Ext.apply({},params));
                    }
                })
            ;
            
            if ( res.length == 0 )
                res.push (
                    params
                )
            ;
            
            return res;
            
        }) ();
        
        me.downloadSession = {
            
            id: Ext.id(),
            requestsParams: requestsQueue,
            activeRequests: [me.request(requestsQueue.pop())]
            
        };
        
    },

    upload: function( options ) {
        
        var xi = this, store = new Ext.data.Store ({
            
            proxy: { type: 'sql', engine: options.engine },
            xid: uuid(),
            model: 'ToUpload',
            storeId: 'ToUpload',
            pageSize: options.pageSize ? options.pageSize : 0,
            autoLoad: false,
            remoteFilter: true,
            remoteSort: true,
            
            recordSuccessCb: options.recordSuccess,
            successCb: options.success,
            failureCb: options.failure,
            
            sorters: [
                {
                    property : 'ts',
                    direction: 'ASC'
                },
                {
                    property : 'pid',
                    direction: 'ASC'
                }
            ]
        });
        
        store.load( function (records, operation, success) {
            
            if (success) {
                console.log ('Ext.data.XmlInterface upload: '+records.length);
                
                xi.fireEvent ('beforeupload',store);
                
                store.position = 0;
                
                xi.login ({
                    success: function(){
                        xi.uploadData (store)
                    },
                    failure: function () {
                        
                        var e = 'Обратитесь в теходдержку по инциденту SUP-99061';
                        
                        if (typeof store.failureCb == 'function')
                            store.failureCb.call (xi, store,e)
                        else
                            Ext.Msg.alert('Загрузка не удалась', e,
                                function() {options.btn.enable();
                            })
                        ;
                    }
                });
                
            } else {
                console.log ('Upload failure');
                if (typeof store.failureCb == 'function')
                    store.failureCb.call (xi, store, operation.error.message)
            }
            
        });
        
    },
    

    commitUpload: function(record) {
        console.log ('commitUpload: position = '+record.store.position);
        
        var me = this;
        
        record.constructor.proxy=record.store.proxy;
        record.set ('cs', record.uploadStamp);
        
        record.save ({
            success: function(){
                
                if (typeof record.store.recordSuccessCb == 'function')
                    record.store.recordSuccessCb.call (me, record);
                
                record.store.position++;
                me.uploadData (record.store);
                //record.store.destroyStore();
            }
        });
    },


    uploadData: function ( store ) {
        
        var me = this,
            record = store.getAt( store.position );
        
        if (record) new Ext.data.Store ({
            
            proxy: { type: 'sql', engine: store.proxy.engine },
            model: record.get('table_name'),
            pageSize: 1,
            remoteFilter: true,
            
            toUploadRecord: record,
            uploadStore: store,
            
            filters: [{
                property: 'xid',
                value   : record.get('id')
            }],
            
            autoLoad: true,
            
            listeners: {
                load: function (store1, records, success) {
                    
                    if (success) try {
                            me.uploadRecord (store1);
                        } catch (e) {
                            
                            Ext.Msg.alert(
                                'Инцидент SUP-99061',
                                (e.message || 'Обратитесь в техподдержку') + ' S=' + e.stack,
                                function() {
                                    //options.btn.enable();
                                    me.forwardUploadUponError (store1, e.message );
                                }
                            );
                            
                        }
                    else
                        console.log ('Upload get data failure')
                    ;
                    
                }
            }
            
        }); else {
            
            console.log ('Ext.data.XmlInterface upload end');
            
            if (typeof store.successCb == 'function')
                store.successCb.call (me, store);
                
            me.fireEvent('upload', store);
            
            store.destroyStore();
            
        }
    },

    forwardUploadUponError: function (store, exception) {
        if ( ++ store.toUploadRecord.store.position >= store.toUploadRecord.store.getCount() )
            store.toUploadRecord.store.failureCb.call (this, store, exception)
        else
            this.uploadData (store.toUploadRecord.store);
    },
    
    uploadRecord: function (store) {
        
        var xi = this, record = store.getAt(0),
            toUploadPid = store.toUploadRecord.get('pid'),
            isNew = store.toUploadRecord.get('wasPhantom'),
            xid =  store.toUploadRecord.get('id'),
            metadata = Ext.getStore('tables').getById(store.model.modelName)
        ;
        
        if (record && metadata && store.model && store.model.modelName) {
            var uploadXML = document.implementation.createDocument("http://unact.net/xml/xi", "upload", null),
                dataElement = uploadXML.createElement('data')
            ;
            
            dataElement.setAttribute ('name', store.model.modelName);
            uploadXML.documentElement.appendChild(dataElement);
            
            record.fields.each(function (field,i,d) {
                
                var rv = record.get(field.name),
                    metaField = metadata.columnsStore.getById(store.model.modelName+field.name)
                ;
                
                if (metaField && field.name[0] == lowercaseFirstLetter(field.name[0])){
                    switch (field.type.type) {
                        case 'bool':
                            rv = rv ? 1: 0;
                            break;
                        case 'date':
                            rv && (typeof rv.format == 'function') && (rv = rv.format('d.m.Y'))
                            break;
                    }
                    
                    var e = uploadXML.createElement ('datum'),
                        parentName = metaField.get('parent')
                    ;
                    
                    e.setAttribute('alias',field.name);
                    parentName && e.setAttribute('parent',parentName);
                    
                    if (rv != null) {
                        e.appendChild(uploadXML.createTextNode(rv));
                        dataElement.appendChild(e);
                    }
                }
            });
            
            xi.request({
                
                command: 'upload',
                xmlData: uploadXML,
                
                success: function(ur){
                    //console.log ('Upload request success: pid = '+ toUploadPid);
                    //console.log (ur.responseXML);
                    xi.uploadPut (store, record, ur.responseXML);
                }
                
            });
            
        } else xi.commitUpload (Ext.apply (store.toUploadRecord, {uploadStamp: 'no data'}))
    },
    
    uploadPut: function (store, record, xml) {
        
        var response = Ext.DomQuery.select ('response', xml) [0],
            xi = this
        ;
        
        if (response){
            var form = Ext.DomQuery.select (store.model.modelName, response) [0];
            
            if (form){
                console.log ('response received: xid = ' + form.getAttribute('xid') + ', ts = '+form.getAttribute('ts'));
                
                record.fields.each ( function(f) {
                    var newValue = Ext.DomQuery.select(f.name, form)[0];
                        
                    if ( newValue ) {
                        newValue = newValue.childNodes[0] ? newValue.textContent : null;
                        
                        if (f.type.type == 'date')
                            newValue =  Date.parseDate (newValue, 'd.m.Y');
                        else if (f.name == 'datetime')
                            newValue =  Date.parseDate (newValue, 'd.m.Y H:i:s').format('Y-m-d H:i:s');
                            
                        if ( newValue != record.get(f.name))
                            record.set(f.name,newValue);
                    }
                    
                    switch (f.name) {
                        case 'needUpload':
                        case 'serverPhantom':
                            record.set (f.name, false);
                    }
                })
                
                record.save({
                    
                    uploadStamp: form.getAttribute('ts'),
                    success: function(r,o) {
                        xi.commitUpload (Ext.apply (store.toUploadRecord, {uploadStamp: o.uploadStamp}));
                        xi.fireEvent ('uploadrecord', record);                
                    },
                    failure: function (r,o) {
                        var e = o.getError();
                        
                        //if (e.message.indexOf('constraint fail')!=-1)
                        //    xi.commitUpload (Ext.apply (store.toUploadRecord, {uploadStamp: o.uploadStamp}));
                        //else
                            store.toUploadRecord.store.failureCb.call (xi, store, e.message);
                    }
                    
                });
                
            }
            else {
                var exception = Ext.DomQuery.select('exception ErrorText', response)[0];
                if (exception) { exception = exception.textContent }
                else {
                    exception = 'No rows affected'
                }
                console.log ('Upload exception: ' + exception);
                
                if ( ++ store.toUploadRecord.store.position >= store.toUploadRecord.store.getCount() )
                    store.toUploadRecord.store.failureCb.call (xi, store, exception)
                else
                    xi.uploadData (store.toUploadRecord.store);
            }
            
        } else store.toUploadRecord.store.failureCb.call (xi, store, 'No response found')
    }
    
})