-- revoke connect from sales;
grant connect to sales;
grant dba to sales;


create or replace view sales.category (
    id, name, package, userPackage, ord, xid, ts, volOrder, parent, sales_shop_department
) as select
    gg.id, gg.name, mgg.vmeas, mgg.pmeas, ggt.ord, ggt.xid,
    ggt.ts, ggt.vol_order, gg.parent, sales_shop_department
  from dbo.gg_threshold ggt
  join dbo.goods_groups gg
  join my_ggroup mgg on mgg.id = ggt.id and mgg.iam = 123 -- dbo.getuseroption('ordr_goods_settings')
;


create or replace view sales.article (
    id, name, category, xid, ts, factor, rel, removed, extraLabel, cost, vmeas, packageRel
) as select
        g.id, g.short_name, g.g_group, g.xid, g.ts,
        ceiling(isnull(nullif(g_parm.minvol, msr.rel), 1)) as factor,
        if factor > 1 then 1 else cast(msr.rel as int) endif as rel,
        case g.removed when 0 then 0 else (select min(removed) from goods g2 where sgpalm = g.id) end removed,
        lbl.value,
        cc.price,
        if rel = 1 then c.userPackage else c.package endif,
        msr.rel
  from dbo.goods g join sales.category c on c.id=g.g_group 
       join dbo.ms_rel_sets msr on msr.msrh_id=g.msrh_id and msr.ms_id=c.package
       left join dbo.extra lbl on lbl.etype =  3354 and lbl.record_id = g.id
       left join dbo.cache_cost cc on cc.goods = g.id and today() between cc.ddateb and cc.ddatee
       left join g_parm on g_parm.id = 1 and g_parm.goods = g.id
;

create or replace procedure sales.article (
    @salesman int, @category int default null
) as select a.*
    from sales.article a join dbo.palm_salesman ps on ps.salesman_id = @salesman
    where (@category is null or a.category = @category)
      and (ps.srv_ord_goods_pref is null or a.id in (select p.id
                  from prefer  pr join prefs p on pr.concept = p.concept and pr.type = p.type 
                 where p.type = 8 and pset = ps.srv_ord_goods_pref
                union
                select vss.goods
                  from prefer  pr join prefs p on pr.concept = p.concept and pr.type = p.type 
                                  join valid_sp_sets vss on vss.spv_id = p.id
                 where p.type = 9 and pset = ps.srv_ord_goods_pref
                 )
          )
;

create or replace procedure sales.category (
    @salesman int
) as select *
    from sales.category c
    where exists (select * from sales.article (@salesman) where category = c.id)
;


create or replace view sales.categoryActive
as
select category, count(*) cnt
  from sales.article
 where removed=0
 group by category
;

create table sales.customer (
    id int default autoincrement,
    name varchar(128) not null,
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
)
;

create table sales.price (
    id int default autoincrement,
    foreign key (article) references dbo.goods,
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid),
    unique(article)
)
;

insert into sales.price (article, price)
select g.id ,
(select pp.price
from dbo.pricelist_prices pp join dbo.partner_plist ppl on pp.list = ppl.plist
where pp.goods = g.id
   and pp.ddate = today()
   and ppl.partner =744027
   and (exists(select * 
                                from dbo.plset_ggroup join dbo.goods_groups_tree on dbo.plset_ggroup.g_group = dbo.goods_groups_tree.parent
                             where dbo.plset_ggroup.plset = ppl.plset and dbo.goods_groups_tree.id = g.g_group)
or not exists(select * from dbo.plset_ggroup where plset = ppl.plset))) price
from dbo.goods g
where price is not null
;
commit

create table sales.customer_agent (
    not null foreign key (customer) references sales.customer,
    not null foreign key (agent) references  xmlgate.agent,
)
;
alter table sales.customer_agent add unique (agent, customer)
;


create table sales.customer_order (
    id int default autoincrement,
    code varchar(16),
    not null foreign key (customer) references sales.customer,
    
    null foreign key (palm_ordorder) references dbo.palm_ordorder,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    accepted timestamp null,
    primary key (id),
    unique (xid),
    unique (code)
)
;


create or replace trigger tbI_sales_customer_order
before insert on sales.customer_order
referencing new as inserted
for each row
when (inserted.code is null)
begin
    set inserted.code= inserted.id;
end
;


create or replace procedure sales.customer_order_create (@customer int)
begin
    insert into sales.customer_order
    (customer)
    select id
      from sales.customer where id=@customer
       and not exists (select * from sales.customer_order where customer=customer.id and accepted is null)
    ;
    select * from sales.customer_order 
     where customer=@customer and accepted is null
end;


create table sales.customer_order_position (
    id int default autoincrement,
    not null foreign key (customer_order) references sales.customer_order,
    not null foreign key (article) references dbo.goods,
    volume int not null,
    rel int not null,
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
)
;


create or replace view sales.order_position_available
as
select distinct a.id as article, c.package, c.id category, 
       a.factor as rel, a.name as name, null as volume,
       cast(round(p.price,2) as decimal(18,2)) as price
  from OrdGoodsInStockMulti() ga 
  join sales.article a on a.id=ga.goods_id
  join sales.category c on c.id=a.category
  join sales.price p on p.article=a.id
 where ga.isvollow=0 and ga.stock_id=1
;

create or replace view sales.territory
as
select * from dbo.palm_unit 
where parent=3006
;

create or replace view sales.salesman_group 
as 
select *, (select t.id from sales.territory t join dbo.palm_unit_tree 
    pst on pst.parent=t.id and pst.id=u.id) as territory 
from dbo.palm_unit u 
where parent in (select id from palm_unit_tree
                  where id in (select unit_id from dbo.palm_salesman)
                    and parent in (select id from sales.territory)
                 )
;

create or replace view sales.salesman
as
select
   cast(t.name as varchar(32)) as territory_name,
   t.id as territory,
   cast(_extra.getvalue(srv_pgroup,'partnersgroupsphone') as varchar(16) ) as mobilenum,
   g.id as salesman_group,
   g.name as salesman_group_name,
   ps.salesman_id as id,
   ps.*
 from sales.territory t join dbo.palm_unit_tree pst on pst.parent=t.id
      join dbo.palm_salesman ps on ps.unit_id=pst.id
      left join (dbo.palm_unit_tree pstg 
      join  sales.salesman_group g on g.id=pstg.parent) on pstg.id=ps.unit_id
where srv_pgroup is not null
;


create or replace trigger sales.tii_salesman
instead of update on sales.salesman
referencing new as inserted old as deleted
for each row
begin
    if isnull(inserted.mobilenum,'') <> isnull(deleted.mobilenum,'') then
        call _extra.setvalue(inserted.srv_pgroup, 'partnersgroupsphone', inserted.mobilenum)
    end if;
end;


// Pattern Enforces Logging

create table sales.sms (
    id int default autoincrement,
    msg text not null,

    salesman_group int not null,
    includeSupervisor int not null default 0,
//    result xml not null,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
)
;

create or replace trigger tbI_sales_sms
before insert on sales.sms
referencing new as inserted
for each row
begin
    insert into sms.data 
      with auto name
    select inserted.msg as msg,
           isnull(sm_phone,'')
           + if inserted.includeSupervisor = 1 and nullif(sm_phone,'') is not null then ', ' else '' endif
           + isnull(ss_phone,'') as phone
      from ( 
            select list (distinct mobilenum) as sm_phone,
                   list (distinct cast(_extra.getvalue(pg2.parent,'partnersgroupsphone') as varchar(16) )) as ss_phone
              from sales.salesman join dbo.partners_groups pg on pg.id=salesman.srv_pgroup join partners_groups pg2 on pg2.id=pg.parent
              where salesman_group=inserted.salesman_group and mobilenum<>''
            ) as t
      where "phone"<>'';
end
;

create or replace procedure sales.CreateCashOrder(@sale_order integer)
begin

    insert into dbo.orders_income with auto name
    select idgenerator('orders_income') as id,
           1007 as cdesk,
           $partner.anyCashclient(p.id) as client,
           today() as ddate,
           $sale_order.summ(so.id) as summ,
           string('Оплата товара заказа №',so.ndoc,' от ',convert(varchar(10),so.sddate,103)) as cause,
           18 as nds           
      from dbo.sale_order so join dbo.partners p
     where so.id=@sale_order
    ;
    
    return @@rowcount;

end;


create or replace procedure sales.CreatePalmOrder(@id integer)
begin
 declare @salesman_id integer;
 declare @order_id integer;
 declare @ddate datetime;
 declare @client_id integer;

 -- presets
 set @salesman_id = 100500;
 set @client_id = 1078027;
 -- дата заказа
 set @ddate = today();

 -- Заголовок заказа
 set @order_id = isnull((select max(order_id) from dbo.palm_OrdOrder where intuserid = 500),500)+1000;

 insert into dbo.palm_OrdOrder with auto name
 select @order_id as order_id,
        @salesman_id as salesman_id,  
        now() as ddatetime,
        @client_id as client_id,
        0 as sumtotal,
        0 as processed,
        0 as cash_flag,
        0 as nsp_flag,
        @ddate as toDate,
        0 as print_sf,
        0 as bonus_flag,       
        100 as source;

 insert into palm_OrdOrderItem with auto name
 select @order_id as order_id,  
        number(*) as goods_id,
        op.article as cat_goods_id,
        0 as vol1,
        op.volume as vol2,
        0 as cost,
        (select top 1       
                ms.ms_id
           from dbo.goods g join dbo.gg_ms_set gg on g.g_group = gg.g_group
                            join dbo.ms_rel_sets ms on ms.msrh_id = g.msrh_id and ms.ms_id = gg.ms_id
          where ms.rel = 1) as vmeas
   from sales.customer_order_position op 
  where customer_order = @id;
   
 update sales.customer_order
    set accepted = now(), palm_ordorder=@order_id
   where id = @id;
  
end;


with o as
(select sordinfo, co.code, co.accepted from sales.customer_order co join palm_ordorder po on po.order_id=co.palm_ordorder
where code in (9,10)
)
select  date(o.accepted), gg.name, goods.short_name, ceiling(vol) as vol, cast(vol*price/rel as decimal(12,2)) as summ
   from o join sale_order so on so.ndoc=o.sordinfo join sordgoods on sordgoods.id=so.id 
     join goods on goods.id=sordgoods.goods join goods_groups gg
     join ms_rel_sets msr
       on msr.msrh_id=goods.msrh_id and msr.ms_id=sordgoods.pmeas
order by gg.sortcolumn,3,1
;

create or replace view dbo.pricelist_prices ( list,goods,price,currency,ddate, ts)
as 
select pt1.parent as list,price.goods as goods,
    (100+pt1.discount)/100*price.price+
    isnull(pt1.eprice*(select ratio 
                         from dbo.cbratio 
                        where currency = pt1.ecurrency and ddate = ddates.ddate)/
                      (select ratio from dbo.cbratio
                        where currency = price.currency and ddate = ddates.ddate),0
    ) as price,
    price.currency as currency,
    ddates.ddate as ddate,
    greater(price.ts,pt1.ts) 
  from
    dbo.price,dbo.pricelist_tree as pt1,dbo.ddates 
 where  price.list = pt1.id and
    ddates.ddate between price.ddateb and price.ddatee and
    pt1.distance = 
       (select min(pt2.distance) 
          from dbo.pricelist_tree as pt2 
         where pt2.parent = pt1.parent and
               exists(select 1 from dbo.price as pr 
                       where pr.list = pt2.id and
                             ddates.ddate between pr.ddateb and pr.ddatee and
                             pr.goods = price.goods
                     )
        )
;


create or replace view dbo."partner_prices_gg" (partner, ddate, goods, g_group, price, currency, plist, ts)
as
select	ppl.partner, pp.ddate, goods, goods.g_group,
	pp.price * ( 1 - isnull(ppl.discount,0)/100.0) * (1 - isnull(pd.discount,0)/100.0 ) price,
	pp.currency,
	pp.list plist,
    greater(pp.ts,isnull(pd.ts,pp.ts))
from partner_plist ppl 
		join pricelist_prices pp on pp.list=ppl.plist
		join goods on goods.id=pp.goods
        outer apply (
            select top 1 discount, partner_discount.ts
              from partner_discount, price 
             where partner_discount.pricelist = price.list and
                   price.goods	= goods.id and
                   partner_discount.partner = ppl.partner and
                   pp.ddate between partner_discount.ddateb and partner_discount.ddatee and
                   pp.ddate between price.ddateb and price.ddatee
        ) as pd
	where (exists (select * from plset_ggroup, goods_groups_tree ggt 
					where plset_ggroup.plset=ppl.plset
		  			  and plset_ggroup.g_group=ggt.parent and ggt.id=goods.g_group
			)
		or not exists (select * from plset_ggroup where plset_ggroup.plset=ppl.plset)
		)
;

create or replace view sales.offer
as
select partner, ddate, goods, g_group, cast(round(price,2) as decimal(12,2)) as price,
       currency, plist
  from dbo.partner_prices_gg ppgg
 where exists (select * from cache_OrdGoodsInStockMulti where goods=ppgg.goods)
;

create table sales.shop_department (
    id int default autoincrement,
    
    name varchar(30) not null,
    ord int not null default 0,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);

alter table dbo.gg_threshold add null foreign key (sales_shop_department) references sales.shop_department;

create table sales.encashment (
    id int default autoincrement,
    
    ddate smalldatetime not null,
    isWhite int not null default 0,
    
    foreign key (palm_salesman) references dbo.palm_salesman,
    foreign key (client) references dbo.buyers,
    foreign key (palm_saleperiod) references dbo.palm_saleperiod,
    debt int null,
    
    summ decimal(18,4) not null,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);

alter table palm_repayment modify saleperiod_id null;
alter table palm_repayment drop foreign key palm_saleperiod_id;
alter table palm_repayment add foreign key (saleperiod_id) references palm_saleperiod;

create or replace trigger tUI_sales_encashment
after insert, update on sales.encashment
referencing new as inserted
for each row
begin

    if inserted.palm_saleperiod is not null then
        
        update dbo.palm_saleperiod
           set closed = 1
         where closed = 0
           and saleperiod_id = inserted.palm_saleperiod
           and totalSumm = (
            select sum(summ)
              from sales.encashment
             where palm_saleperiod = inserted.palm_saleperiod
        );
        
        insert into dbo.palm_repayment on existing update with auto name select
                isnull (r.repayment_id, idgenerator('expedition_encashment')) as repayment_id,
                inserted.palm_saleperiod as saleperiod_id,
                inserted.client as client_id, inserted.ddate, inserted.summ,
                inserted.debt as debt_id, inserted.iswhite as kkmprinted,
                inserted.xid
            from dummy left join dbo.palm_repayment r on r.xid = inserted.xid
            
        ;
        
    end if
    
end;

alter table dbo.palm_saleperiod add totalsumm decimal (18,2);
alter table dbo.palm_saleperiod add totalsummWhite decimal (18,2);

drop trigger if exists tbI_sales_uncashment
;

create or replace view sales.uncashment as select
    saleperiod_id as id, salesman_id as salesman, ddate as datetime,
    closed, processed, xid, ts, totalsumm, totalsummwhite, routetypegroup_id
    from dbo.palm_saleperiod
;

create or replace trigger tbI_sales_uncashment
instead of insert on sales.uncashment
referencing new as inserted
for each row
begin

    insert into dbo.palm_saleperiod on existing update with auto name
        select isnull (u.id, dbo.idgenerator('palm_saleperiod','saleperiod_id')) as saleperiod_id,
               inserted.xid as xid,
               isnull (u.closed,1) as closed,
               isnull (u.processed,0) as processed,
               inserted.totalsumm, inserted.totalsummwhite,
               inserted.salesman as salesman_id,
               1 as seller_id,
               inserted.datetime as ddate,
               isnull (u.routetypegroup_id,
                    (select routetypegroup_id from palm_salesman where salesman_id = inserted.salesman)
               ) as routetypegroup_id
          from dummy left join sales.uncashment u on u.xid = inserted.xid
    ;
    
end;

create or replace procedure sales.last_orders (@ddate smalldatetime default today()) 
begin
    select
        ps.name as salesman_name,
        (select count(*) from agents a join xmlgate.agent xa on xa.name= a.loginname where a.id = ps.agent and devicename = 'ipad') as salesman_has_ipad,
        (select sum(cost)/nullif(totalCost,0)*100 from pre_order_item where pre_order = po.id) complete_percent,
        po.*
    from pre_order po
        join palm_salesman ps on ps.salesman_id = po.salesman
        join buyers on buyers.id = po.client
    where 
        po.ts > @ddate
    order by po.ts desc;
end;

create or replace view sales.bprog as select
        id, name, ddateb, ddatee, descr, discount,
        
        if today() between ddateb and ddatee then 1 else 0 endif isActive,
        if discount like '%(%)' then left (discount, locate (discount,'(') - 1) else discount endif tagText,
        if discount like '%(%)' then right (discount, length (discount) - locate (p.discount,'(') +1) endif modifiers,
        if discount like 'Ф%' or modifiers like '%Ф%' then 1 else 0 endif isFocused,
        case 
            when isFocused = 1 or modifiers like '%red%' then 'red' 
            when modifiers like '%blue%' then 'blue' 
            when modifiers like '%black%' then 'black'
            else 'gray'
        end tagColor,
        if isFocused = 1 or modifiers like '%[1]%' then 1 endif isFirstScreen,
        if isFocused = 1 or modifiers like '%[^]%' then 1 endif isNonHidable,
        if modifiers like '%[?]%' then 1 endif isForNew,
        if modifiers like '%[ct]%' then 1 endif isCustomerTargeted,
        if modifiers like '%[!]%' then 1 endif isPopAtStart,
        d.goal, d.gain
    from bprog p, lateral (
        select goal, gain
          from openstring(value p.descr) with (
            goal varchar(1024), gain varchar(1024)
          ) option (delimited by '|') as normalized_terms
    ) as d
    where p.discount is not null
;


create or replace procedure sales.bprogBySalesman (
    @id int
) begin
    select * from sales.bprog where exists (
        select * from dbo.buyer (@salesman = @id)
            join bpb_link_v bpc on bpc.buyer = buyer.id
        where bpc.bp = bprog.id
    )
end;

create or replace view sales.bprog_customer as select
        v.buyer, v.bp
    from dbo.bpb_link_v v join sales.bprog bp on bp.id = v.bp
    where bp.isCustomerTargeted = 1 and not exists (
        select * 
            from cnt_coef cc 
            join bpcnt_link  bc on bc.cnt = cc.cnt 
            join counter c on c.id = cc.cnt
            join cnt_bp_result cr on cr.cnt = c.id and  cr.bp = bp.id
        where cr.client = v.buyer and  bp.id = bc.bp and cc.round = 1 and c.period = 1 and cr.value > 0 and 
            not exists (select 1
                          from bpcnt_link bci 
                               left join cnt_bp_result cri on cri.cnt = bci.cnt and cri.bp = bci.bp and cri.client = cr.client
                         where  bci.bp = bp.id and isnull(cri.value,0)=0
            )
    )
;

drop trigger if exists tbIU_sales_encashment_request;

create or replace view sales.encashment_request as select
        id, xid, ddate, ts, reason, client, agent,
        trim(replace (info, 'инкассация', '')) as info,
        case
            when reason is not null then 'Невыполнение'
            when exists ( 
                    select * from palm_repayment r join palm_saleperiod ps on ps.saleperiod_id = r.saleperiod_id
                     where client_id = ir.client and ps.ddate = ir.ddate
            ) then 'Выполнено'
            when ir.ddate < today() then 'Невыполнение'
            when exists (
                    select * from delinc join delivery on delivery.id = delinc.id
                     where delinc.client = ir.client and date(delivery.ddate) = ir.ddate
            ) then 'В маршруте'
            else 'Заявка'
        end as status
  from dbo.increquest ir
 where incstatus = 1
;

create or replace trigger tbIU_sales_encashment_request
instead of insert, update on sales.encashment_request
referencing new as inserted old as deleted
for each row
begin

    insert into dbo.increquest on existing update with auto name select
        isnull(inserted.id, idgenerator('increquest')) as id,
        inserted.xid, inserted.ddate, inserted.client,
        if isnull(inserted.info,'') like '%инкассация%' then inserted.info else 'инкассация ' + isnull(trim(inserted.info),'') endif as info
        
end;


create or replace procedure sales.logger (
    @salesman int,
    @version varchar(24) default null
) begin

    update dbo.palm_salesman set
        srv_lastsync = now(),
        last_version = isnull (@version, last_version)
    where
        salesman_id = @salesman
    ;
    
    select salesman_id as palm_salesman, last_version from palm_salesman
    where salesman_id = @salesman
    ;

end;

create or replace procedure sales.warehouseBySalesman (
    @id int
) begin
    select * from dbo.site where exists (
        select * from dbo.buyer (@salesman = @id)
        where buyer.site = site.id
    )
end;

