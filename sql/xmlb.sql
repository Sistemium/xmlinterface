call sa_make_object ('service', 'xmlb');

alter service xmlq
 type 'RAW'
 authorization on
as call util.xml_for_http(dba.xml_bulk(csconvert(:request,'os_charset','utf-8')))
;


create or replace function dba.xml_bulk (
    @request xml default null
    , @parent_id IDREF default null
    , @parent_name STRING default null
)   returns xml
    sql security invoker
begin

    declare @result xml;    
    declare @log_id int;
 
    body: begin
        
        for a as a cursor for
            with xmlcoldata as (
                select *
                    from openxml (@request, '/*/@*') with (
                        table_name STRING '../@mp:localname'
                        , column_name STRING '@mp:localname'
                        , value STRING '.'
                    ) as cd
            ) select
                string (creator, '.[', table_name, ']') as @name
                , list (string('[',column_name,']') order by column_id) as @columns
                , list (string('''',value, '''') order by column_id) as @values
                , (select table_name from xmlcoldata where column_name = 'id') as @table_name
                , (select value from xmlcoldata where column_name = 'id') as @id
            from (
                select
                    t.table_name, c.column_name, cd.value, c.column_id
                    , user_name (t.creator) creator
                from (
                        select table_name, column_name, value from xmlcoldata
                        union all
                        select (select max(table_name) from xmlcoldata), @parent_name, string(@parent_id)
                        where @parent_name is not null and not exists (select * from xmlcoldata where column_name = @parent_name)
                    ) cd
                    join systable t on t.table_name = cd.table_name and t.creator = user_id ('iorders')
                    join syscolumn c on c.table_id = t.table_id and c.column_name = cd.column_name
            ) as t
            group by creator, table_name
            having table_name is not null
        do
            
            message 'xml_bulk: ', string (
                'insert into ', @name, ' on existing update ('
                , @columns
                , ') values ('
                , @values
                , ')'
            ) to client;
            
            if @id is not null then
                set @parent_id = @id;
                set @parent_name = @table_name;
            end if;
            
        end for;
        
        for c as c cursor for
            select *
            from openxml (@request, '/*/*') with (
                @table_name STRING '@mp:localname'
                , @row_data xml '@mp:xmltext'
            )
        do
            
            set @result = string (@result, dba.xml_bulk (@row_data, @parent_id, @parent_name));
            
        end for;
        
    exception when others then
        
        set @result=
          xmlelement('exception',
                     xmlconcat(xmlelement('ErrorText',errormsg())
                              ,xmlelement('SQLSTATE',SQLSTATE)
                     )
        );
        
    end;
    
    return xmlelement('response'
            ,xmlattributes('http://unact.net/xml/xi' as xmlns, now() as ts, @log_id as "log-id")
            ,@result
    );
    
end;