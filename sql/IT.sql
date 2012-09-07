grant connect to IT;

create table if not exists IT.salary (
    id int default autoincrement,
    
    for_year int not null,
    for_month int not null,
    
    fio varchar(64) not null,

    sla int,
    overwork int,
    projects int,
    jobprice int,
    
    xid uniqueidentifier default newid(),
    cs datetime default current timestamp,
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);


create or replace procedure it.sync_pay_sheet (
    @year int,
    @month int
) begin

    for c as c cursor for select
        pay_sheet_id as @pay_sheet
        from dbo.pay_sheet
        where emp_group_id = 36 and psf_id = 2
            and date(string(@year,str0(@month,2,0),'15')) between ddateb and ddatee
    do
        insert into dbo.pay_sheet_item on existing update with auto name select
            @pay_sheet as pay_sheet_id,
            (select p.person_id from person p join employee
                where shortened = fio or lname = fio
                  and exists (select * from emp_rel join emp_dept
                               where person_id = p.person_id and path like '0000/0104/0093/%')
            ) as person_id,
            i.item_id, 
            case i.code
                when 'pooshr' then sla
                when 'premia2' then projects
                when 'premia' then jobprice
                when 'pererabs' then overwork
            end as "value",
            now() as manual_set
        from it.salary s cross join pay_sheet_item_pool i 
        where i.code in ('premia','premia2','pooshr', 'pererabs')
            and "value" >0
    end for

end;
