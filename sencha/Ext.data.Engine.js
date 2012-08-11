Ext.data.Engine = Ext.extend(Ext.util.Observable, {
    
    isEngine: true,
    
    db: false,
    
    name: 'SQL Database Engine',
    
    metadata: false,
    
    constructor: function(config) {
        
        this.addEvents(
            'dbstart',
            'metadataload',
            'loadtable',
            'fill',
            'fail',
            'upgradefail'
        );
        
        Ext.apply(this, config || {} );
        
        Ext.data.Engine.superclass.constructor.call(this, config);
        
        if (this.metadata) this.startDatabase (this.metadata);
        
    },
    
    nullDataHandler: Ext.emptyFn,
 
    errorHandler: function (transaction, error) {
        var msg = transaction.message ;
        
        if (!msg && error) msg = error.message;
        console.log('Database error: ' + msg);
        return true;
    },

    startDatabase: function (metadata, forceRebuild){
        var targetVersion = metadata.version,
            name = metadata.name,
            me = this,
            targetSize = metadata['expect-megabytes'] || 10,
            ok = function () {
                
                Ext.each (metadata.views, function (view) {
                    me.tables.push (Ext.apply(view, {type: 'view'}))
                });
                
                Ext.each (me.tables, function(t,i,tables) {
                    t.viewName = t.id+'_browse';
                    
                    if (targetVersion >= 1.722 && t.extendable) t.columns.push({
                            name: 'needUpload',
                            id: t.id+'needUpload',
                            type: 'boolean',
                            virtual: true
                        },{
                            name: 'serverPhantom',
                            id: t.id+'serverPhantom',
                            type: 'boolean',
                            virtual: true                        
                    })
                    
                    Ext.each (t.columns, function(c) {
                        var pname = '';
                        if (c.parent)
                            tables[c.parent].columns.forEach ( function (pcol, idx) {
                                if (pcol.title || pcol.name == 'name' || pcol.name == 'ord') {
                                    pname = c.parent+'_'+pcol.name;
                                    t.columns.push ({
                                        name: pname,
                                        id: t.id+pname,
                                        type: 'string',
                                        virtual: true
                                    });
                                }
                            })
                        ;
                    })
                });
                
                me.fireEvent ('dbstart', me.db = db);
            }
        ;
        
        me.metadata = metadata;
        me.tables = me.metadata.tables;
        
        if (!targetVersion || !name) {
            me.fireEvent ('fail');
            return false;
        }
        
        Ext.each (me.tables, function(t,i,tables) {
            tables[t.id] = t;
            t.columns.map = {};
            Ext.each (t.columns, function(c) {
                t.columns.map[c.name] = c;
            })
        });
        
        if (!window.openDatabase) {
            console.log  ('Ext.data.Engine: Browser does not support Databases');
            return false
        } else {
            var shortName = name;
            var displayName = name;
            var maxSize = targetSize*1024*1024; // in bytes
            var db = openDatabase(shortName, "", displayName, maxSize);
            
            if (db.version<targetVersion || forceRebuild)
                db.changeVersion (
                    db.version, targetVersion,
                    function (t) {
                        console.log ('Ext.data.Engine rebuild '+name+' db version: '+db.version+' to metadata version: '+targetVersion);
                        me.rebuildTables (t, metadata);
                        db.clean = true;
                    },
                    function (err) {
                        console.log('Ext.data.Engine: error upgrading: '+err.message);
                        me.fireEvent ('upgradefail')
                        return false;
                    },
                    ok
                )
            else ok();
            
            return db;
        }            
    },
    
    executeDDL: function (t, ddl) {
        
        t.debug && console.log('Ext.data.Engine.executeDDL: '+ ddl);
        return t.executeSql (ddl, [], this.nullDataHandler, this.errorHandler)
        
    },
    
    executeSQL: function (t, sql, vars) {
        
        if(t.debug) {
            console.log('Ext.data.Engine.executeSQL: '+ sql);
            console.log(vars);
        }
        
        if (!vars) vars=[];
        
        return t.executeSql (sql, vars, this.nullDataHandler, this.errorHandler)
        
    },
    
    rebuildTables: function (t, dbSchema) {
        
        var me = this;
        
        console.log('Ext.data.Engine: rebuildTables start');
        
        t.debug = true;
        
        me.executeDDL (t, 'DROP table IF EXISTS Entity');
        me.executeDDL (t, 'Create table Entity ('
            +'name string primary key'
            +', hidden boolean'
            +', ts datetime default current_timestamp)')
        ;
        
        me.executeDDL (t, 'DROP table IF EXISTS Phantom');
        me.executeDDL (t, 'Create table Phantom ('
            +'id integer primary key autoincrement, table_name string, row_id string'
            +', wasPhantom int'
            +', cs string'
            +', ts datetime default current_timestamp)')
        ;
        
        me.executeDDL (t, 'DROP view IF EXISTS ToUpload');
        me.executeDDL (t, 'create view ToUpload as select '
            + 'table_name, row_id id, count(*) cnt, min (ts) ts, max(wasPhantom) hasPhantom, max(p.id) pid, max(cs) cs'
            + ' from Phantom p where p.cs is null group by p.row_id, p.table_name'
        );
        
        me.executeDDL (t, 'create trigger commitUpload instead of update on ToUpload begin '
            + 'delete from Phantom where row_id = new.id and id <= new.pid; '
            + 'end'
        );
        
        Ext.each( dbSchema.tables, function (table, idx, tables) {
            
            me.executeSQL(t, 'insert into Entity (name, hidden) values (?,?)', [table.id, table.name ? 1: 0]);
            
            me.executeDDL(t, 'DROP TABLE IF EXISTS '+table.id+';');
            
            var columnsDDL='', fkDDL='', pkDDL='';
            
            Ext.each (table.columns, function (column, idx, columns) {
                
                columnsDDL += column.name + ' ' + (column.type || 'string') + ', ';
                //if (column.parent) fkDDL += ', foreign key ('+column.name+') references '+ column.parent;
                if (column.name == 'id' && !table.extendable ) pkDDL = 'primary key (id)';
                if (column.name == 'xid' && table.extendable) pkDDL = 'primary key (xid)';
                
            });
            
            var ddl = 'CREATE TABLE IF NOT EXISTS '+table.id+' ( '+columnsDDL
                +' ts datetime default current_timestamp';
            
            if (!pkDDL) {
                Ext.each (table.columns, function (column, idx, columns) {
                    if (column.parent) pkDDL += column.name + ',';
                });
                if (pkDDL) pkDDL = 'primary key (' + pkDDL.slice(0,pkDDL.length - 1) + ')'
            }
            
            if (pkDDL) ddl+=', '+pkDDL;
            
            ddl += fkDDL+' );'
            
            me.executeDDL(t, ddl);
            
            var 
                viewDDL = 'create view '+table.id+'_browse as select ' + table.id +'.*',
                fromDDL =' from '+table.id
            ;
            
            me.executeDDL(t, 'DROP VIEW IF EXISTS '+table.id+'_browse;');    
            
            Ext.each (table.columns, function (column, idx, columns) {
                
                var idxDDL = '', viewDDLplus = '';
                
                if (column.parent || column.name == 'id') 
                    idxDDL = 'create index '+table.id+'_'+column.name+' on '+ table.id + '('+column.name+')';
                
                if (idxDDL) me.executeDDL (t, idxDDL);
                
                if (column.parent && tables[column.parent].extendable)
                    me.executeDDL (t,
                        'create trigger '+column.parent+'_cascade_'+table.id
                        +' before update on '+column.parent
                        +' begin update ' + table.id +' set '+column.name
                        +' = new.id where ' + column.name + ' = old.id; end')
                ;
                
                if (column.parent)
                    tables[column.parent].columns.forEach ( function (pcol, idx) {
                        viewDDLplus += ', '+column.parent+'.'+pcol.name+ ' as '+column.parent+'_'+pcol.name;
                    })
                ;
                
                if (viewDDLplus){
                    viewDDL += viewDDLplus;
                    fromDDL += (column.editable ? ' left' : '') +
                            ' join ' + column.parent + ' on ' + column.parent + '.id = ' + table.id + '.' + column.name;
                }
                
            })
            
            if (table.extendable)
                viewDDL += ', (select 1 from toUpload where id = ' + table.id + '.xid ) as needUpload ';
                
            me.executeDDL(t, viewDDL + fromDDL);
            
            Ext.each (table.deps, function (dep, idx, deps) {
                if (dep.contains)
                    me.executeDDL (t,
                        'create trigger td_'+table.id+'_cascade_'+dep.table_id
                        +' before delete on '+table.id
                        +' begin delete from ' + dep.table_id 
                        +' where ' + table.id + ' = old.id; end')
            });
            
            if (table.extendable) me.executeDDL (t,
                'create trigger td_'+table.id+'_cascade_Phantom'
                +' before delete on '+table.id
                +' begin delete from Phantom' 
                +' where row_id = old.xid; end')
            ;
        });
        
        Ext.each ( dbSchema.views, function (table, idx) {
            
            me.executeDDL(t, 'DROP VIEW IF EXISTS '+table.id+';');
            
            var ddl = 'CREATE VIEW IF NOT EXISTS '+table.id+' as '
                + table.sql['#text'];
            
            me.executeDDL(t, ddl);
            
        });
        
    },

    processDowloadData: function( response, opts ) {
        
        var me = this,
            xml = response.responseXML,
            xi = opts.xi,
            p = function (t) {
                me.persistTableData (t, xml, xi, response)
            }
        ;
        
//        if ( xi.noServer && opts.params.filter )
//            p (this.metadata.tables[opts.params.filter]);
//        else        
            Ext.each (this.metadata.tables, p)
        ;
        
    },
    
    persistTableData: function(table, rowsetXML, xi, request) {
        
        var 
            downloadData=Ext.DomQuery.select(table.id, rowsetXML),
            me = this
        ;
        
        if (!table || downloadData.length<=0) return;
        
        console.log ('Ext.data.Engine.persistTableData: '+table.id+' length='+downloadData.length);
        
        var firstDataChildren=downloadData[0].childNodes,
            firstDataParent = downloadData[0].parentNode
        ;
        
        if (firstDataParent && firstDataParent.nodeName=='paged'){
            
            var currentPos=parseInt(firstDataParent.getAttribute('page-start'));
            
            request.willContinue = true;
            
            me.requestChoise(table.id, currentPos, 0, xi, currentPos+1);
            
        } else for (var ei=0; ei<firstDataChildren.length; ei++){
            var elem=firstDataChildren[ei];
            switch (elem.tagName) {
                case 'choise':
                    var totalPos=parseInt(elem.getAttribute('options-count')),
                        currentPos=parseInt(elem.getAttribute('current-position')),
                        nextId = elem.getAttribute('next')
                    ;
                    
                    if ( nextId.length == 0 ) nextId = false;
                    
                    if (!currentPos || currentPos < totalPos)
                        request.willContinue = true;
                    
                    me.requestChoise(table.id, currentPos, totalPos, xi, nextId);
            }
        }
        
        me.db.transaction(
            function(t){
                var rowsProcessed = 0;
                
                for (var i=0; i<downloadData.length; i++){
                    var columns = table.columns, columnsList='', qList='', dataArray=[], xid = false;
                    
                    if (!downloadData[i].hasAttributes()) continue;
                    
                    Ext.each (table.columns, function (column, idx, columns) {
                        if (!column.virtual) {
                            columnsList += column.name + ', ';
                            qList += '?,';
                            var datum = downloadData[i].getAttribute(column.name);
                            
                            if (!datum) {
                                var parent=downloadData[i].parentNode;
                                
                                if (parent.tagName.toLowerCase()==column.name)
                                    datum=parent.getAttribute('id');
                            }
                            
                            if (column.type == 'date'){
                                datum = Date.parseDate (datum, 'd.m.Y');
                                if (datum) datum = datum.format ('Y/m/d');
                            }
                            
                            dataArray.push(datum);
                            
                            if (column.name == 'xid' && table.extendable)
                                xid = datum
                            ;    
                        }
                    });
                    
                    columnsList=columnsList.slice(0, columnsList.length - 2);
                    qList=qList.slice(0, qList.length - 1);
                    
                    var sqlStatement='replace into '+table.id+'('+columnsList+') select '+qList;
                    
                    if (xid) {
                        dataArray.push (xid);
                        sqlStatement += ' where not exists (select * from phantom where row_id = ?)';
                    }
                    
                    t.executeSql(sqlStatement, dataArray);
                    rowsProcessed++;
                }
                
                console.log('Ext.data.Engine.persistTableData: processed: '+rowsProcessed+' '+table.id+' rows');
                
            }, me.errorHandler, function () {
                xi.cleanDownloadSession (request);
                xi.fireEvent ( 'tableload', table.id, request.willContinue );
                if ( !request.willContinue ) xi.fireEvent ('tableloadfull', table.id);
            }
        );
        
    },

    requestChoise: function(tableName, currentPos, totalPos, xi, nextId) {
        var params = { filter: tableName },
            label = tableName+' '+currentPos.toString()+'/'+totalPos.toString();
        
        params[tableName]= nextId ? nextId : 'next';
        
        if (!currentPos) currentPos=0;
        
        
        xi.request ({
            label: label,
            command: 'download',
            
            params: params,
            timeout: 120000,
            
            scope: this,
            success: this.processDowloadData,
            
            xi: xi
        });
     
        console.log('Ext.data.Engine.requestChoise: '+label);
    }
    
})
