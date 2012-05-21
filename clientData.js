var mydb;

function loadClientData (){
    clientDataInit();
}


function clientData(idx, obj){
    
    var preload_id=$(obj).attr('id');
    
    mydb.transaction(
        function (transaction) { 
            transaction.executeSql(
                'select value from clientData where id=?;',
                [preload_id],
                function (t, results) {
                    if (results.rows.length){
                        clientDataDisplay(preload_id, results.rows.item(0)['value']);
                    } else
                        clientDataDownload(preload_id);
                }, errorHandler
            );
        }
    );
    
}


function clientDataDownload(preload_id){
    
    AjaxRequest.get(
      {
        'async': true
        ,'parameters': {pipeline: 'clientData', preload: preload_id }
        ,'onSuccess': clientDataReceived
        ,'onError': clientDataError
      }
    );    
}

function clientDataError (req){
    $(obj).parent().parent().parent().removeClass('ajaxloading');
    $(obj).parent().parent().parent().addClass('ajaxError');
    return false;
}

function clientDataSave(id, value){
    mydb.transaction(
        function (transaction) { 
            transaction.executeSql(
                'REPLACE INTO clientData (id, value) VALUES (?,?);',
                [id, value], nullDataHandler, errorHandler
            );
        }
    );
}

function clientDataReceived(req){
    var id=req.parameters.preload,
        value=req.responseXML.documentElement.innerHTML;
    clientDataSave(id, value);
    clientDataDisplay(id, value);
}


function clientDataDisplay (id, value) {
    obj=$('#'+id)
    $(obj).empty();
    $(obj).append(value);
    
    $(obj).removeClass('empty');
    $(obj).parents('.ajaxloading').removeClass('ajaxloading');

    $(obj).find('tr.group').addClass('collapsed');

    $(obj).delegate('tr.group', 'click', function() {
        $(this).nextUntil('.group').toggle();
        $(this).toggleClass('expanded');
        $(this).toggleClass('collapsed');
    });
    
    $(obj).find('tr.group').each(function(){
        if ($(this).nextUntil('.group','.featured').size() > 0)
            $(this).addClass('featured');
    });

    $(obj).filter(':has(.featured)').parents('.collapsable').addClass('featured');
    
    $(obj).find('.editable').each(function() {
        $(this).html('<span class="'
                     +$(this).attr('class')
                     +'"><input class="text '
                     +$(this).attr('class')
                     +'" id="'
                     +$(this).attr('xi:key')
                     +'"type="text" value="'
                     +$(this).text()
                     +'"/></span>'
                    );
    });


}


function clientDataInit(){
    mydb=dbinit();
    if (mydb)
        mydb.transaction(
            function (transaction) {
                transaction.executeSql(
                    'select count(*) as cnt from clientData',
                    [],
                    function (transaction, results) {
                        $('#clientDataControl').text('CD='+results.rows.item(0)['cnt']);
                        $('.collapsable .clientData.empty').each(clientData);
                    },
                    errorHandler
                )
            }
        );
}


function dropTables(t)
{
    t.executeSql(
        'DROP TABLE IF EXISTS clientData;',
        [], nullDataHandler, errorHandler
    );
    
    t.executeSql(
        'CREATE TABLE clientData (id VARCHAR(64) NOT NULL PRIMARY KEY, value TEXT NOT NULL, ts datetime not null default current_timestamp);',
        [], nullDataHandler, errorHandler
    );
}



function dbinit(){
    var targetVersion = '1.41';

    try {
        if (!window.openDatabase) {
            return false;
            alert('Databases not supported');
        } else {
            var shortName = 'system.client';
            var displayName = 'System local important data';
            var maxSize = 65536; // in bytes
 
            var db = openDatabase(shortName, "", displayName, maxSize);
            
            if (db.version<targetVersion)
                db.changeVersion (
                    db.version, targetVersion, dropTables,
                    function (err) {alert('error upgrading: '+err.message)},
                    nullDataHandler
                )
            ;
            
            return db;
        }
        
    } catch(e) {
        // Error handling code goes here.
        if (e == 2) {
            // Version number mismatch.
            alert("Invalid database version.");
        } else {
            alert("Unknown error at line "+e.line+', '+e+".");
        }
        return false;
    }
}


function nullDataHandler(transaction, results) { }
 
function errorHandler(transaction, error)
{
    // error.message is a human-readable string.
    // error.code is a numeric error code
    alert('Oops.  Error was '+error.message+' (Code '+error.code+')');
 
    // Handle errors here
    var we_think_this_error_is_fatal = true;
    if (we_think_this_error_is_fatal) return true;
    return false;
}

function progressHandler(percentComplete, name) {
    $('#canvas').append ('<div>'+name+'</div>') //text('Progress: '+percentComplete.toFixed(1) + '%');
}


function renderInput(){
    
}


/*
function loadTables(db) {
    AjaxRequest.get({
        'url': 'http://lamac.local/~sasha/XML/?pipeline=rawdata&concept=category'
        ,'onSuccess': function(req) { return loadCategory2(db, req);}
        ,'onError':function(req){ alert('Error!\nStatusText='+req.statusText+'\nContents='+req.responseText); }
    });
}

function loadCategory(db, req) {
    
    if (!req.responseXML) {
        alert ('Empty result');
        return;
    }
    
    var xmldata=req.responseXML.getElementsByTagName('category');
    
    for( var i = 0; i < xmldata.length; i++ )
    {
        var row = xmldata.item( i );
        
        (function saveItem(row,i) {
            db.transaction(
                function (transaction) {
                    transaction.executeSql(
                        'replace into category (id, name, [order-package]) values (?,?,?);',
                        [row.getAttribute('id'), row.getAttribute('name'), row.getAttribute('order-package')],
                        progressHandler ((i+1) * 100.0 / xmldata.length) , errorHandler
                    );
                }
            )
        })(row,i);
    }
    
}

function loadCategory2(db, req) {
    
    if (!req.responseXML) {
        alert ('Empty result');
        return;
    }
    
    var xmldata=req.responseXML.getElementsByTagName('category');
    
    db.transaction(
        function (transaction) {
            for(i = 0; i < xmldata.length; i++ ){
                row = xmldata.item( i );
                transaction.executeSql(
                            'replace into category (id, name, [order-package]) values (?,?,?);',
                            [row.getAttribute('id'), row.getAttribute('name'), row.getAttribute('order-package')],
                            progressHandler ((i+1) * 100.0 / xmldata.length, row.getAttribute('name')) , errorHandler
                );
            }
        }
    );
    
}

*/