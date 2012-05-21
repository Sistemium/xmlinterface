--grant connect to xmlgate;

drop table if exists xmlgate.query;

create global temporary table if not exists  xmlgate.query (
    id int default autoincrement,
    
    request text,
    response text,
    username varchar (32),
    conn varchar (32),
    ip varchar (15),
    path varchar (32),

    ts datetime default timestamp,
    cts datetime default current timestamp,
    
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
 
-- message 'xmlq request: ',@request;
 
body:  
 begin
 
    set @request=csconvert(@request,'os_charset','utf-8');

    select query_name, if show_sql is not null then 1 endif, sql_raw, username, ip, path
        into @query_name, @show_sql, @sql, @username, @ip, @path
        from openxml(@request, '/*') with (
            query_name varchar(128) '@name',
            show_sql text '@show-sql',
            sql_raw text '*:sql',
            expect text '@expect',
            username varchar(128) '@username',
            ip varchar(128) '@ip',
            path varchar(128) '@path'
        )
    ;
    
    if @username is not null then
        create variable @@username varchar(128);
        set @@username=@username;
    end if;
    
    if @sql is null then

        if @query_name is null then 
            set @result=xmlelement('exception','Query name not found');
            leave body;
        end if;
    
        select top 1 proc_id, 'proc', user_name(creator)+'.'+@query_name
           into @query_id, @query_type, @query_name
           from sysprocedure
          where proc_name=@query_name
        ;
        
        if @query_id is null then
            select top 1 table_id, 'table', user_name(creator)+'.'+@query_name
              into @query_id, @query_type, @query_name
              from systable
             where table_name=@query_name
        end if;
        
        if @query_id is null then 
            set @result=xmlelement('exception','Query named "'+@query_name+'" not found');
            leave body;
        end if;
    
        select list(if parm_type=0 then parm_name + ' = '+ parm_value endif, ', ' order by parm_id),
               nullif(list(if parm_type=1 then parm_name + ' = '+ parm_value endif
                           ,' and ' order by parm_id),'')
        into @parms_from, @parms_where
        from ( select meta.*, if request.parm_datatype<>'xml' and isnull(parm_value,'')=''
                              then 'null' else 
                                case request.parm_datatype
                                    when 'number' then request.parm_value
                                    when 'xml' then ''''+request.parm_xml+''''
                                    else ''''+request.parm_value+''''
                                end
                              end if parm_value
                from (
                            select parm_name,
                                   parm_type, parm_id, if "default" is null then 1 else null endif as is_required,
                                   substr(parm_name,if left(parm_name,1)='@' then 2 else 1 endif) as parm_name_join
                              from sysprocparm
                             where proc_id=@query_id and @query_type='proc'
                            union all
                            select column_name, 1, column_id, null, column_name
                              from syscolumn
                              where table_id=@query_id and @query_type='table'
                      ) as meta
                     join openxml(@request,'/*/*:parameter')
                          with (parm_name varchar(128) '@name',
                                parm_datatype varchar(128) '@type',
                                parm_value text '.',
                                parm_xml xml '*/@mp:xmltext'
                          ) as request
                     on request.parm_name = meta.parm_name_join
    --           where parm_type=0 or request.parm_name is not null
              ) as parms
        ;
        
        set @sql='select * into @result from '+@query_name 
            + if @query_type='proc' then '(' + @parms_from + ')' end if
            + if @parms_where is not null then ' where ' + @parms_where endif
            +' for xml auto'
        ;
    end if;
    
//    savepoint xiMain;
    
    insert into xmlgate.query with auto name
        select @sql as request, @username as username, connection_property ('number') as conn,
            @ip as ip, @path as path
    ;
    set @log_id = @@identity;
    
    execute immediate with result set off @sql;
    
    if nullif(trim(@result),'') is not null then
        set @result=xmlelement('result-set',@result);
    elseif @sql like '%into%@result%' or @sql like '%set%@result%'then
        set @result=xmlelement('exception', xmlelement('not-found'));
    else
        set @result=xmlelement('rows-affected',@@rowcount);
    end if;

    update xmlgate.query set response = isnull(@result,'') where id = @log_id;
    
 exception
   when others then
     set @result=
          xmlelement('exception',
                     xmlconcat(xmlelement('ErrorText',errormsg())
                              ,xmlelement('SQLSTATE',SQLSTATE)
                     )
     );
    update xmlgate.query set response = @result where id = @log_id;
//     rollback to savepoint xiMain;
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

