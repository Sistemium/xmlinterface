call sa_make_object ('service', 'xmlb');

alter service xmlb
 type 'RAW'
 authorization on
as call util.xml_for_http(dba.xml_bulk(csconvert(http_body(),'os_charset','utf-8')))
;

create or replace function dba.xml_bulk_row (
    @xmlrow xml default null
    , @parent_id IDREF default null
    , @parent_name STRING default null
)   returns xml
begin

    declare @result xml;
    declare @sql text;
 
    for a as a cursor for
        with xmlcoldata as (
            select *
                from openxml (@xmlrow, '/*/@*') with (
                    table_name STRING '../@mp:localname'
                    , column_name STRING '@mp:localname'
                    , value STRING '.'
                ) as cd
        ) select
            string (creator, '.[', table_name, ']') as @name
            , list (string('[',column_name,']') order by column_id) as @columns
            , list (string('''',value, '''') order by column_id) as @values
            , (select max(table_name) from xmlcoldata) as @table_name
            , (select value from xmlcoldata where column_name = 'id') as @id
        from (
            select
                t.table_name, c.column_name
                , case
                    when d.domain_name regexp 'date.*|timestamp' then
                        string(convert(date, left(cd.value,10), 104), substring(cd.value, 11))
                    else cd.value
                end as value
                , c.column_id
                , user_name (t.creator) creator
            from (
                    select table_name, column_name, value from xmlcoldata
                    union all
                    select (select max(table_name) from xmlcoldata), @parent_name, string(@parent_id)
                    where @parent_name is not null and not exists (select * from xmlcoldata where column_name = @parent_name)
                ) cd
                join systable t on t.table_name = cd.table_name and t.creator = user_id ('iorders')
                join syscolumn c on c.table_id = t.table_id and c.column_name = cd.column_name
                left join sysdomain d on d.domain_id = c.domain_id
        ) as t
        group by creator, table_name
        having table_name is not null
    do
        
        set @sql = string (
            'insert into ', @name, ' ('
            , @columns
            , ') on existing update values ('
            , @values
            , ')'
        );
        
        --execute immediate with result set off @sql;
        
        set @result = xmlconcat (@result, xmlelement (@table_name));
        
        message 'xml_bulk: ', @sql to client;
        
        if @id is not null then
            set @parent_id = @id;
            set @parent_name = @table_name;
        end if;
        
    end for;
    
    for c as c cursor for
        select *
        from openxml (@xmlrow, '/*/*') with (
            @table_name STRING '@mp:localname'
            , @row_data xml '@mp:xmltext'
        )
    do
        
        set @result = xmlconcat (@result, dba.xml_bulk_row (@row_data, @parent_id, @parent_name));
        
    end for;
    
    return @result
    
end;


create or replace function dba.xml_bulk (
    @request xml default null
)   returns xml
    sql security invoker
begin

    declare @result xml;
    declare @log_id int;
    
    body: begin
        
        set @result = dba.xml_bulk_row (@request);
        
        select xmlagg(e) into @result from (
            select xmlelement (table_name, count (*)) e
                from openxml (xmlelement('r',@result), '/*//*') with (
                    table_name STRING '@mp:localname'
                )
            group by table_name
        ) as t;
        
    exception when others then
        
        set @result=
          xmlelement('exception',
                     xmlconcat(xmlelement('ErrorText',errormsg())
                              ,xmlelement('SQLSTATE',SQLSTATE)
                     )
        );
        
    end;
    
    return xmlelement('response'
            ,xmlattributes('http://unact.net/xml/xi' as xmlns)
            ,@result
    );
    
end;
