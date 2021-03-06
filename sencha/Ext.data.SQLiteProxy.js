Ext.data.SQLiteProxy = Ext.extend(Ext.data.ClientProxy, {
    
    constructor: function(config) {
        Ext.data.SQLiteProxy.superclass.constructor.call(this, config);
        
        this.engine = this.engine || config.engine || Ext.data.SQLiteProxy.engine;
        
        if (this.engine == undefined) {
            throw "No database reference was provided to the SQLite storage proxy. See Ext.data.SQLiteProxy documentation for details";
        };
        
        this.logging = config.logging;
        
    },

    update: function (operation, callback, scope) {
        this.create (operation, callback, scope)
    },
    
    create: function(operation, callback, scope) {
        var 
            me = this,
            cb = function(){
                operation.setCompleted();
                if (typeof callback == "function") {
                    callback.call(scope || this, operation, operation.wasSuccessful());
                }
            },
            
            scb = function(){
                if (!operation.error) {
                    operation.setSuccessful();
                    Ext.each (operation.records, function(record, i) {
                        record.phantom = false,
                        record.dirty = false;
                        record.editing = false;        
                        delete record.modified;
                    });
                    cb ();
                }
            },
            
            ecb = function(e){
                console.log('Ext.data.SQLiteProxy.setRecord error: ' +e.message);
                operation.setException(e);
                cb();
            }
        ;
        
        this.getNextId = window.uuid;
        
        this.engine.db.transaction(
            function(t){
                operation.setStarted();
                
                t.operation = operation;                
                t.proxy = me;
                
                Ext.each (operation.records, function(record, i) {
                    
                    var recId = record.getId();
                    
                    if (record.phantom && (!recId || recId === 0 || recId ==='')) {
                        var xid = me.getNextId();
                        record.setId (xid);
                        record.phantom = true;
                        record.set ('xid', xid);
                    }
                    
                    me.setRecord(record, t, ecb);
                })
            }, ecb, scb
        );
    },


    setRecord: function(record, t, ecb) {
        
        var 
            me = this,
            model   = me.model,
            tableName = this.tableName || this.model.modelName,
            meta = this.engine.tables[tableName]
        ;
        
        if (!meta) {
            var tableMeta = Ext.getStore('tables').getById(tableName),
                saveTo = tableMeta && tableMeta.get('saveTo')
            ;
            
            if (saveTo) {
                tableName = saveTo;
                meta = this.engine.tables[tableName];
            }
        }
        
        var 
            fields = (meta)? meta.columns : model.prototype.fields.items,
            
            keyMap = fields.keyMap || (typeof fields.map == 'object' && fields.map),
            sql='', hostVars=[], sqlValues = '',
            updateKey = !record.phantom
        ;
        
        if (updateKey){
            if (record.data['xid']) updateKey = 'xid'
            else { if (record.data['id']) updateKey = 'id'; else updateKey = false }
        }
        
        Ext.each (record.fields.items, function (field) {
            if ((!meta || keyMap && keyMap[field.name] && !keyMap[field.name].virtual)
                && !(field.name == 'ts' || field.name == updateKey)
            ){
                if (field.compute || (field.template && (!field.type || field.type.type == 'auto'))) return;
                sql += field.name
                    + (updateKey ? '=?' : '')
                    + ','
                ;
                
                var rv = record.get(field.name);
                
                if (field.type.type=='bool') {
                    rv = rv ? 1: 0;
                } else if (rv && field.type.type=='date') {
                    rv = rv.format('Y/m/d')
                }
                
                hostVars.push (rv);
                sqlValues += '?,'
            }
        });
        
        sql = sql.slice(0,sql.length - 1);
        sqlValues = sqlValues.slice(0,sqlValues.length - 1);
        
        sql = updateKey 
            ? 'UPDATE ' +tableName + ' set '
                +sql + ' WHERE ' + updateKey + ' = ?'
            : 'REPLACE into ' +tableName
                + ' ( ' +sql + ' ) values ( ' + sqlValues + ' )'
        ;
        
        if (updateKey)
            hostVars.push (record.get(updateKey))
        
        //console.log('Ext.data.SQLiteProxy.setRecord prepare: ' + sql);
        
        t.executeSql(
            sql, hostVars,
            function(){
                this.logging && console.log('Ext.data.SQLiteProxy.setRecord success: ' +sql);
                var xid = record.get('xid');
                
                if (!t.operation.uploadStamp && xid) {
                    var phantomSql = 'insert into Phantom (row_id, table_name, wasPhantom) values (?,?,?)'
                        phantomSqlValues= [xid, tableName, record.phantom];
                    t.executeSql( phantomSql, phantomSqlValues, function() {
                        //console.log ('Ext.data.SQLiteProxy.setRecord phantom added: ' + tableName + ' xid = ' +xid);
                    })
                }                
                
            } ,
            function(t,e){
                console.log('Ext.data.SQLiteProxy.setRecord error: ' +e+'; sql = ' + sql);
                ecb(e);
            }
        );
        
    },

    destroy: function(operation, callback, scope) {
        
        var 
            me = this,
            model   = this.model,
            tableName = this.tableName || operation.tableName || this.model.modelName,
            meta = this.engine.tables[tableName],
            
            fields = (meta)? meta.columns : model.prototype.fields.items,
            length  = fields.length,
            sqlWhere = '', hostVars = []
        ;
        
        scope || (scope = operation);
        operation.setStarted();
        
        
        Ext.each (operation.records, function(record) {
            
            var sql = 'DELETE FROM ' + tableName,
                updateKey
            ;
            
            if (record.data['xid']) {updateKey = 'xid'}
            else { if (record.data['id']) updateKey = 'id' };
            
            
            if (typeof updateKey != 'string' && meta)
                fields.forEach (function (f) {
                    var cnt = 0;
                    
                    if (f['key']) {
                        var fname = f['name'];
                        sqlWhere += cnt++ > 0 ? ' and ' : '' + fname;
                        
                        if (record.data[fname] == undefined)
                            sqlWhere += ' is null'
                        else {
                            sqlWhere += ' = ?';
                            hostVars.push(record.data[fname]);
                        }
                    }
                });
            else if (updateKey) {
                sqlWhere = updateKey + ' = ? '
                hostVars.push(record.data[updateKey])
            };
            
            if ( sqlWhere.length > 0 ) sql += ' WHERE '+sqlWhere;
            
            this.logging && console.log(sql);
            
            me.engine.db.transaction(
                function(t){
                    t.executeSql(
                        sql,
                        hostVars,
                        function(t,r) {
                            t.operation = operation;
                            t.proxy = me;
                            t.scope = scope;
                            t.callback = callback;
                            me.dataReady (t,r);
                        },
                        function(t,r) {
                            t.operation = operation;
                            t.proxy = me;
                            t.scope = scope;
                            t.callback = callback;
                            me.dataError (t,r);
                        }
                    )
                }
            )
        });
        
    },
    
    read: function(operation, callback, scope) {
        
        var 
            me = this,
            model   = this.model,
            tableName = this.tableName || operation.tableName || this.model.modelName,
            meta = this.engine.tables[tableName],
            
            fields = (meta)? meta.columns : model.prototype.fields.items,
            fieldsSrc = (typeof fields.keys == 'object') ? fields : model.prototype.fields,
            fieldNames = fieldsSrc.keyMap || fieldsSrc.map,
            length  = fields.length,
            i, field, name, sqlSelectList=''
        ;
        
        scope || (scope = operation);
        operation.setStarted();
        
        if (meta && meta.viewName)
            tableName = meta.viewName
        ;
        
        switch (operation.action){
            case 'aggregate':
                Ext.each (fields, function (field) {
                    if (field.aggregable)
                        sqlSelectList += field.aggregable + '('+field.name + ') as '+field.name +',';
                });
            case 'count':
                sqlSelectList += 'count(*) as cnt,';
                break;
            default:
                Ext.each (fields, function (field) {
                    if (field.compute || (field.template && (!field.type || field.type.type == 'auto'))) return;
                    if (field.name == 'serverPhantom')
                        sqlSelectList += '(select 1 from toUpload where hasPhantom = \'true\' and id = ' + tableName + '.xid) as '
                    ;
                    sqlSelectList += field.name + ',';
                });
        }
        
        var sql = 'SELECT ' + sqlSelectList.slice(0,sqlSelectList.length - 1) +
                  '  FROM ' + tableName,
            sqlWhere = '', filters = operation.filters, hostVars =[]
        ;
        
        if (!operation.remoteFilter && scope.isStore && !scope.remoteFilter) filters = false;
        
        Ext.each (filters, function (filter, i) {
            if (!fieldNames || fieldNames[filter.property]) {
                if (filter.useLike)
                    operation.postLimits = true;
                else {
                    
                    sqlWhere += filter.property;
                    
                    if (filter.value == undefined)
                        sqlWhere += ' is null'
                    else {
                        if (filter.useLike){
                            sqlWhere += " like ?";
                            hostVars.push('%'+filter.value+'%');
                        } else {
                            sqlWhere += ' '
                            if (filter.gte) sqlWhere += '>';
                            sqlWhere += '= ?';
                            hostVars.push(filter.value);
                        }
                    }
                    
                    sqlWhere += (i < filters.length-1) ? ' and ' : ' ';
                    
                }
            }
        });
        
        if (operation.id){
            sqlWhere += 'id = ?'
            hostVars.push(operation.id)
        }
        
        if ( sqlWhere.length > 0 ) sql += ' WHERE '+sqlWhere;
        
        var sqlOrderBy = '', sorters = operation.sorters;
        
        if (scope.isStore && !scope.remoteSort) sorters = false;
        
        if (sorters) for (i = 0; i < sorters.length; i++) {
            //var f = fieldNames[sorters[i].property];
            //f && !f.compute && (
                sqlOrderBy += sorters[i].property
                    +' '+ sorters[i].direction
                    +  ((i < sorters.length-1) ? ',' : '')
            //)
        }
        
        if ( sqlOrderBy.length > 0 ) sql += ' ORDER BY '+sqlOrderBy;
        
        if (!operation.postLimits) {
            if (operation.limit) sql += ' LIMIT '+operation.limit;
            if (operation.start) sql += ' OFFSET '+operation.start;
        }
        
        operation.sql = sql; 
        //console.log(sql);
        
        this.engine.db.transaction(
            function(t){
                t.executeSql(
                    sql,
                    hostVars,
                    function(t,r) {
                        t.operation = operation;
                        t.proxy = me;
                        t.scope = scope;
                        t.callback = callback;
                        me.dataReady (t,r);
                    },
                    function(t,r) {
                        t.operation = operation;
                        t.proxy = me;
                        t.scope = scope;
                        t.callback = callback;
                        me.dataError (t,r);
                    }
                )
            }
        )
        
    },
    
    dataReady: function(t, result){
        var rows = result.rows, records = [], recData={};
        
        //console.log ('Ext.data.SQLiteProxy.dataReady: '+result.rows.length);
        
        if (t.operation) {
            
            
            if (result) {
                var cnt = result.rows.length;
                t.proxy.lastRowCount = cnt;
                //console.log ('SQLite rowcount: ' + cnt);
            }
            
            switch (t.operation.action) {
                case 'aggregate':
                    t.operation.result = 0;
                    if (rows.length) t.operation.result = rows.item(0)['cnt'];
                case 'read':
                    
                    var postFilters = [], op = t.operation;
                    
                    
                    Ext.each (op.filters, function(f) {
                        if (f.useLike && f.property && f.value) postFilters.push ({
                            re: new RegExp(f.value,'i'),
                            property: f.property
                        });
                    });
                    
                    for(var i = 0; i < rows.length; i++) {
                        var data = new t.proxy.model(rows.item(i));
                        data.phantom = false;
                        
                        Ext.each (postFilters, function (f) {
                            var val = data.get(f.property);
                            if (!val || !val.match(f.re))
                                data = undefined;
                        });
                        
                        data && records.push(data);
                    };
                    
                    if (op.postLimits && op.limit) {
                        console.log ('Ext.data.SQLiteProxy.dataReady postLimits: '
                            + [records.length, op.start, op.limit].join(', ')
                        );
                        records = records.slice(op.start, op.start + op.limit)
                    }
                    
                    t.operation.resultSet = new Ext.data.ResultSet({
                        "records": records,
                        total  : t.proxy.lastRowCount = records.length,
                        loaded : true
                    });
                    
                    break;
                    
                case 'count':
                    t.operation.result = 0;
                    if (rows.length) t.operation.result = rows.item(0)['cnt'];
                    break;
                case 'destroy':
                    break;
                default:
                    console.log ('Ext.data.SQLiteProxy.dataReady: unknown action');
            }
            
            t.operation.setSuccessful();
            
        } else {
            console.log ('Ext.data.SQLiteProxy.dataReady: undefined operation');
            t.operation = new Ext.data.Operation ();
            t.operation.setException(t.exception ? t.exception : 'Unknown exception');
        }
        
        t.operation.setCompleted();
        
        if (typeof t.callback == "function") {
            t.callback.call(t.scope || t.proxy, t.operation, true);
        } else
            console.log ('Ext.data.SQLiteProxy.dataReady: undefined callback')
    },
    
    dataError: function(t, e){
        t.operation.setException(e);
        t.operation.setCompleted();
        
        console.log ('Ext.data.SQLiteProxy.dataError:'+e.message);
        
        t.operation.resultSet = new Ext.data.ResultSet({
            "records": [],
            total  : 0,
            loaded : true
        })
        
        if (typeof t.callback == "function") {
            t.callback.call(t.scope || t.proxy, t.operation, false);
        } else
            console.log ('Unknown dataError')
    },
    
    count: function (operation, callback, scope) {
        operation.action = 'count';
        this.read (operation, callback, scope);
    },

    aggregate: function (operation, callback, scope) {
        operation.action = 'aggregate';
        this.read (operation, callback, scope);
    }

});


Ext.data.ProxyMgr.registerType('sql', Ext.data.SQLiteProxy);