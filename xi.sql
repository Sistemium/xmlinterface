--grant connect to xmlgate;

drop table if exists xmlgate.query;

create global temporary table if not exists xmlgate.query (
    id int default autoincrement,
    
    request text,
    response text,
    username varchar (32),
    conn varchar (32),
    ip varchar (15),
    path varchar (32),

    ts datetime default timestamp,
    cts datetime default current timestamp,
    xid uniqueidentifier default newid(),
    
    unique(xid),
    primary key (id)
    
) not transactional share by all;

create or replace function dba.xml_query (in @request xml default null)
returns xml
sql security invoker
begin

    declare @result xml;
    declare @sql text;
    declare @parms_where text;
    declare @parms_from text;
    declare @query_name varchar(128);
    declare @query_type varchar(10);
    declare @query_id int;
    declare @delimiter varchar(10);
    declare @show_sql int;
    declare @username varchar(128);
    declare @ip varchar(15);
    declare @path varchar(32);
    declare @log_id int;
    declare @xid uniqueidentifier;
    declare @async varchar(64);
 
    body: begin
        
        set @request=csconvert(@request,'os_charset','utf-8');
        
        message 'dba.xml_query @request = ', @request;
        
        select query_name, if show_sql is not null then 1 endif, sql_raw, username, ip, path, async
            into @query_name, @show_sql, @sql, @username, @ip, @path, @async
            from openxml(@request, '/*') with (
                query_name varchar(128) '@name',
                show_sql text '@show-sql',
                sql_raw text '*:sql',
                expect text '@expect',
                username varchar(128) '@username',
                ip varchar(128) '@ip',
                path varchar(128) '@path',
                async varchar(64) '@async'
            )
        ;
        
        if @username is not null then
            create variable @@username varchar(128);
            set @@username=@username;
        end if;
        
        set @xid = newid();
        
        insert into xmlgate.query with auto name
            select @sql as request, @username as username, connection_property ('number') as conn,
                @ip as ip, @path as path, @xid as xid
        ;
        set @log_id = @@identity;
        
        if isnull(@async,'false') = 'false' then
            set @result = dba.xml_sqlExecute(@sql);
            update xmlgate.query set response = isnull(@result,'') where xid = @xid;
        else
            message 'dba.xml_query @async = true';
            trigger event xmlgateAsyncQuery(query = @xid);
            set @result = xmlelement('asyncQuery', xmlattributes(@xid as "queryXid"));
        end if;
        
        -- async responses
        set @result = xmlconcat(@result,
                                (select xmlagg(xmlelement('result',
                                        xmlattributes(q.xid as "of", if q.response is null then  'true' else null endif as "not-ready" ),
                                        cast(q.response as xml)))
                                   from xmlgate.query q join (select xid
                                                                from openxml(@request, '/*/*:getResult')
                                                                     with(xid uniqueidentifier '@of'))  as t on q.xid = t.xid));
        
        
        
    exception when others then
    
        set @result=
          xmlelement('exception',
                     xmlconcat(xmlelement('ErrorText',errormsg())
                              ,xmlelement('SQLSTATE',SQLSTATE)
                     )
        );
        
        update xmlgate.query set response = @result where xid = @xid;
        
        set @show_sql=1;
        
    end;
    
    return xmlelement('response'
            ,xmlattributes('http://unact.net/xml/xi' as xmlns, now() as ts, @log_id as "log-id")
            ,@result
            ,if @show_sql is not null then xmlelement('sql',cast('<!['+'CDATA['+@sql+']'+']>' as xml)) endif
    );

end;

create table if not exists xmlgate.auth (

    id int default autoincrement,
    
    k uniqueidentifier,
    secret varchar (32),

    ts datetime default timestamp,
    cts datetime default current timestamp,
    
    primary key (id),
    unique (k)

);

create or replace function dba.auth_request (
    @request xml default null
) 
returns xml
begin

    declare @result xml;
    
    for a as a cursor for select * from openxml ( @request, '/*' ) with (
        @auth_key uniqueidentifier '@auth-key',
        @auth_sign varchar(32) '@auth-sign',
        @auth_body text '.'
    ) do
        if not hash(string((select secret from xmlgate.auth where k = @auth_key), @auth_body)) = isnull(@auth_sign,'') then
            set @result = xmlelement( 'not-authorised', @auth_body );
        end if;
    end for;

    if (@result is null) then for c as c cursor for
        select  * from openxml ( @request, '/*/*' ) with (
            @request_body xml '@mp:xmltext'
        )
    do
        set @result = xmlconcat( @result, dba.xml_query ( xmlelement('r',@request_body) ));
    end for end if;
    
    return xmlelement(
        'auth-response'
        ,xmlattributes( 'http://unact.net/xml/xi' as xmlns, now() as ts )
        ,@result
    );

end;

/*
for c as c cursor for 
    select 'set @result = ( select * from measures for xml auto )' as @q, k as @key, secret as @secret
    from xmlgate.auth where id = 1
 do
    select dba.auth_request ('<r auth-key="'+@key+'" auth-sign="'+hash(string(@secret,@q))+'"><sql>'+@q+'</sql></r> ')
end for
*/

sa_make_object 'service', 'xmlq';

alter service xmlq
 type 'RAW'
 authorization on
as call util.xml_for_http(dba.xml_query(:request))
;

sa_make_object 'service', 'xmlqa';

alter service xmlqa
 type 'RAW'
 authorization off
 user dba
as call util.xml_for_http(dba.auth_request( :request ) )
;


drop event xmlgateAsyncQuery
;
create event dba.xmlgateAsyncQuery
handler
begin
    declare @xid uniqueidentifier;
    declare @sql text;
    declare @result xml;

    set @xid = cast(event_parameter('query') as uniqueidentifier);
    set @sql = (select request from xmlgate.query where xid = @xid);
 
    set @result = dba.xml_sqlExecute(@sql);
    
    update xmlgate.query set response = @result where xid = @xid;

end
;


create or replace function dba.xml_sqlExecute(in @sql text)
returns xml
begin
    declare @result xml;

    execute immediate with result set off @sql;
    
    if nullif(trim(@result),'') is not null then
        set @result=xmlelement('result-set',@result);
    elseif @sql like '%into%@result%' or @sql like '%set%@result%'then
        set @result=xmlelement('exception', xmlelement('not-found'));
    else
        set @result=xmlelement('rows-affected',@@rowcount);
    end if;
    
    return @result;
    
    exception when others then
    
        set @result=
          xmlelement('exception',
                     xmlconcat(xmlelement('ErrorText',errormsg())
                              ,xmlelement('SQLSTATE',SQLSTATE)
                     )
        );
        
     return @result;

end;