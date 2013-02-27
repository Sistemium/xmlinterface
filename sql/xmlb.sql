call sa_make_object ('service', 'xmlb');

alter service xmlq
 type 'RAW'
 authorization on
as call util.xml_for_http(dba.xml_bulk(csconvert(:request,'os_charset','utf-8')))
;


create or replace function dba.xml_bulk (in @request xml default null)
returns xml
sql security invoker
begin

    declare @result xml;    
    declare @log_id int;
 
    body: begin
        
        for a as a cursor for
            with coldata as (
                select cd.*, c.column_id, user_name (t.creator) creator
                    from openxml (@request, '/*/@*') with (
                        table_name STRING '../@mp:localname'
                        , column_name STRING '@mp:localname'
                        , value STRING '.'
                    ) as cd
                        join systable t on t.table_name = cd.table_name and t.creator = user_id ('iorders')
                        join syscolumn c on c.table_id = t.table_id and c.column_name = cd.column_name
            ) select
                string (max(creator), '.[', max(table_name), ']') as @name
                , list (string('[',column_name,']') order by column_id) as @columns
                , list (string('''',value, '''') order by column_id) as @values
            from coldata
            having max(table_name) is not null
        do
            
            message 'xml_bulk: ', string (
                'insert into ', @name, ' on existing update (', @columns, ') values (', @values, ')'
            ) to client;
            
        end for;
        
        for c as c cursor for
            select *
            from openxml (@request, '/*/*') with (
                @table_name STRING '@mp:localname'
                , @row_data xml '@mp:xmltext'
            )
        do
            
            set @result = string (@result, dba.xml_bulk (@row_data));
            
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