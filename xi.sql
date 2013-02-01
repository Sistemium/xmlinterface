if user_id ('xmlgate') is null then
    grant connect to xmlgate;
    // don't forget to set pasword
end if;

drop table if exists xmlgate.query;

create global temporary table if not exists xmlgate.query (
    id int default autoincrement,
    
    request text,
    response xml,
    username varchar (32),
    conn varchar (32),
    ip varchar (25),
    path varchar (32),

    ts datetime default timestamp,
    cts datetime default current timestamp,
    xid uniqueidentifier default newid(),
    
    unique(xid),
    primary key (id)
    
) not transactional share by all;



create or replace procedure xmlgate.stats ()
begin

    select hour (ts) h, count(*) cnt, count(distinct username) username_cnt
    from xmlgate.query
    where ts > dateadd(hour, -24, now())
    group by h
    order by h desc

end;



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
    declare @ip varchar(32);
    declare @path varchar(32);
    declare @log_id int;
    declare @xid uniqueidentifier;
    declare @async varchar(64);
 
    body: begin
        
        set @request=csconvert(@request,'os_charset','utf-8');
        
        select query_name, if show_sql is not null then 1 endif, sql_raw, username, ip, path, async
            into @query_name, @show_sql, @sql, @username, @ip, @path, @async
            from openxml(@request, '/ *') with (
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
            trigger event xmlgateAsyncQuery(query = @xid);
            set @result = xmlelement('asyncQuery', xmlattributes(@xid as "queryXid"));
        end if;
        
        -- async responses
        set @result = xmlconcat(
            @result,
            (select
                xmlagg(xmlelement(
                    'result',
                    xmlattributes(
                        q.xid as "of",
                        if q.response is null then  'true' else null endif as "not-ready"
                    ),
                    cast(q.response as xml)
                ))
                from xmlgate.query q join (
                    select xid
                    from openxml(@request, '/ */ *:getResult')
                        with(xid uniqueidentifier '@of')
                )  as t on q.xid = t.xid
            )
        );
        
        
        
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


call sa_make_object ('service', 'xmlq');

alter service xmlq
 type 'RAW'
 authorization on
as call util.xml_for_http(dba.xml_query(:request))
;


drop event if exists xmlgateAsyncQuery
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