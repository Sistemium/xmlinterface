create or replace procedure dbo.wan_sale (
    @state varchar(64) default 'done',
    @client int default null,
    @pricelist int default null,
    @saleperiod int
) begin

    update palm_sale
        set pricelist_id=@pricelist
     where iscomplete=0
       and saleperiod_id=@saleperiod
       and client_id=@client
       and isnull(@pricelist,0)<>isnull(pricelist_id,0)
    ;

    select isnull(sale_id,idgenerator('palm_sale','sale_id')) as sale_id,
           isnull(pricelist_id, @pricelist) as pricelist_id,
           @saleperiod as saleperiod_id,
           isnull (printdocset, 0) as printdocset,
           isnull (iscash,1) as iscash,
           isnull (oncredit,0) as oncredit,
           isnull (client_id, @client) as client_id,
           isnull (iscomplete, 0) as iscomplete,
           isnull (ddate, now()) as ddate,
           sumtotal,
           ndoc,
           s.xid,
           case when iscomplete=1 then 'done'
                else 'draft'
           end as state
      from dummy
      left join palm_sale s
           on (s.client_id=@client and s.iscomplete=0)
              or @state<>'draft'
     where (@state='draft' or s.saleperiod_id=@saleperiod) and state=@state

end;

create or replace view dbo.wan_pos (
as
    select 
           b.id as client,
           p.plist as pricelist,
           b.id as id
      from buyers b join partners p on p.id=b.partner
;

create or replace trigger dbo.tii_wan_pos
instead of update on dbo.wan_pos
referencing new as inserted old as deleted
for each row
begin
    if update(pricelist) then
        update partners set plist=inserted.pricelist
          from buyers b 
         where b.id=inserted.id
           and partners.id=b.partner
    end if;
end;

create or replace procedure dbo.wan_pos (
    @salesman int default null,
    @id int default null
) begin

    select wp.*, @salesman as salesman           
      from wan_pos wp
     where id=isnull(@id,28019)

end;


create or replace procedure dbo.wan_pricelist (
    @salesman int
) begin

    select @salesman as salesman,
           p.plist as pricelist
      from palm_salesman ps join psplink p on p.plset=ps.plset
     where ps.salesman_id=@salesman

end;

create or replace procedure dbo.wan_stock (
    @salesman int
) begin

    select @salesman as salesman,
           r.goods,
           ceiling(sum(r.volume)) remains
      from palm_salesman ps join remains r on r.storage=ps.srv_storage
     where ps.salesman_id=@salesman
    group by r.goods

end;



create or replace procedure dbo.pos_debt (
    @partner int,
    @salesman int default null
)
begin

with ext_partner (id) as (
    select @partner
     union
    select partner
      from payers join partners
     where inn in (select inn from payers where partner=@partner and inn <>'')
       and not exists (
           select * from dbo.cat_info
            where iproot in (select parent from dbo.partners_groups_tree where id=partners.parent)
       )
)
 select payspt.id,   
        payspt.partner,
        payspt.ddate,
        payspt.info,
        payspt.summ,
        cast(paidpt.csum as decimal(18,2)),
        if @partner=payspt.partner then 1 else 0 endif as own,
        0 as color,
        0 as overdue,
        (select min(id) from buyers where partner=payspt.partner) as client,
        dateadd(day,payspt.plong, payspt.ddate) as date_until
   from payspt join paidpt on payspt.id = paidpt.id
  where payspt.type <> 1 and paidpt.partner in (select id from ext_partner)
  
  union all
  
 select isnull(if not exists (select * from recept r2 where r2.sorder = r.sorder and r2.id <> r.id) then r.sorder else null endif, min(payspt.id)) as pid,   
        payspt.partner,
        payspt.ddate,
        payspt.info,
        (select sum(payspt.summ) from payspt join recgoods where recgoods.id=r.id) as summ,
        cast(sum(paidpt.csum) as decimal(18,2)),
        if @partner=payspt.partner then 1 else 0 endif as own,
        if payspt.org= 1084 then 1 
        else if payspt.org = 1143
               then 0
               else 2
              endif
        endif as color,
        if(dateadd(dd, min(payspt.plong),payspt.ddate)<today()) then 1 else 0 endif as overdue,
        max(r.client),
        dateadd(day,min(payspt.plong), payspt.ddate) as date_until
   from payspt join paidpt on payspt.id = paidpt.id
               join recgoods rg on rg.pays = paidpt.id
               join recept r on r.id = rg.id
  where payspt.type = 1
    and paidpt.partner in (select id from ext_partner)
  group by   
        r.sorder,
        r.id,
        payspt.partner,
        payspt.ddate,
        payspt.info,
        payspt.org
        
  union all
  
 select cast(sin(cast(value as int))*1000000 as int)*1000+isnull(@salesman,@partner),
    @partner partner,
    today(),
    'ОСМП',
    null,
    null,
    0 as own,
    2 as color,
    0 as overdue,
    (select min(id) from buyers where buyers.partner=@partner) client,
    null
   from partners_sp_strings 
  where partners_sp_strings.sp_tp  =(select id from sp_types where code = 'osmp') and
        partners_sp_strings.partner= @partner

end;