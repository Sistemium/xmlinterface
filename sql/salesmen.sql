create or replace view dbo.salesman_route
as
    select s.salesman_id as salesman, r.routetype_id as id, r.name
      from palm_routetype r
      join palm_salesman s on r.routetypegroup_id=s.routetypegroup_id
;

create or replace view sales.buyer
as
    select id, name, loadto, site, phone, partner, info,
           nullif(bonus_available(id,1),0) as bonusCost,
           nullif(bonus_forecast(id),0) as bonusForecast,
           xid
      from dbo.buyers
;



create or replace procedure dbo.buyer (
    @salesman int default null,
    @route int default null
)
begin

    select b.*
      from dbo.buyers b
     where (@route is null or exists (
            select * from palm_routepoint
             where client_id=b.id and salesman_id= @salesman and routetype_id= @route
            )
           ) and (
            @salesman is null or exists (
                select * from partners_groups_tree pgt join partners p on p.parent=pgt.id
                        join palm_salesman ps on ps.srv_pgroup = pgt.parent
                 where ps.salesman_id=@salesman and b.partner=p.id
            )
           )

end;

create or replace view sales.shipment as select
        so.*,
        sc.client,
        case
            when status4=1 and debtSumm>0 then 'debt'
            when status4=1 then 'done'
            when status1=0 then 'init'
            when status1=1 and status2=0 then 'accepted'
            when status2=1 and status4=0 then 'picking'
        end as "status",
        (select sum(csum) from dbo.paidpt join dbo.recgoods rg on rg.pays=paidpt.id join dbo.recept r on r.id=rg.id 
          where paidpt.partner=so.partner and r.sorder=so.id) as debtSumm,
        nullif($sale_order.summ(so.id),0) as summ
    from dbo.sale_order so join sordclient sc on sc.id = so.id
;


create or replace procedure sales.shipment (
    @salesman int,
    @since datetime default today() - 60,
    @top int default 1000,
    @start_at int default 1
) begin

    select top @top start at @start_at so.*
      from sales.shipment so
      join dbo.partners p on p.id = so.partner
      join dbo.partners_groups_tree pgt on pgt.id = p.parent
     where pgt.parent = (select srv_pgroup from dbo.palm_salesman where salesman_id = @salesman)
       and sddate>=@since
    order by so.id desc

end;


create or replace view sales.shipment_position as select
        sordgoods.*, vol*price/rel as summ
    from sordgoods join goods on goods.id=sordgoods.goods
    join ms_rel_sets msr on msr.msrh_id=goods.msrh_id and msr.ms_id=sordgoods.pmeas
;


create or replace function dbo.partner_price (
    @partner int, @ddate datetime, @goods int
)
returns decimal(18,4)
begin
    declare @res decimal(18,4);

    select price
      into @res
      from partner_price pp
     where @ddate between ddateb and ddatee and partner=@partner and goods=@goods;

    if @res is null then
        select pp.price*(1 - isnull(ppl.discount,0)/100.0)*
        (1 - isnull(
            (	select top 1 discount 
                from	partner_discount, price 
                where	partner_discount.pricelist=price.list and
                        price.goods=@goods and
                        partner_discount.partner =ppl.partner and
                        @ddate between partner_discount.ddateb and partner_discount.ddatee and
                        @ddate between price.ddateb and price.ddatee
            ),0)/100.0
        )
        into @res
        from partner_plist ppl 
                        join pricelist_prices pp on pp.list=ppl.plist
                        join goods on pp.goods=goods.id
                        and pp.goods=@goods
                        
                where ppl.partner=@partner and pp.ddate=@ddate
                 and (exists (select * from plset_ggroup, goods_groups_tree ggt 
                                where plset_ggroup.plset=ppl.plset
                                  and plset_ggroup.g_group=ggt.parent and ggt.id=goods.g_group
                                )
                        or not exists (select * from plset_ggroup where plset_ggroup.plset=ppl.plset)
                        ) 
    end if;

return @res;

end;


create or replace procedure dbo.pre_order_blank(
    @salesman int,
    @client int
)
begin
    select idgenerator('palm_ordorder','order_id') as id, today()+1 as toDate, 4 as processed,
           0 as print_sf, null as totalCost, 0 as cash_flag, 0 as bonus_flag,
           @salesman as salesman, @client as client, null as xid
      from dbo.palm_salesman s cross join dbo.buyers b
     where s.salesman_id=@salesman and b.id=@client
end;

drop trigger if exists tiI_pre_order
;

create or replace view dbo.pre_order
as
    select order_id as id,
           toDate,
           processed,
           case processed
                when 3 then 'draft'
                when 0 then 'processing'
                when 4 then 'processing'
                when 1 then 'done'
           end as processing,
           print_sf,
           cast (sumtotal/100.0 as decimal(18,2)) as totalCost,
           cash_flag,
           bonus_flag,
           xid,
           salesman_id as salesman,
           client_id as client,
           sordinfo,
           info,
           if source <> 0 and nsp_flag is not null then 'palm' else 'ipad' endif as origin,
           palm_ddatetime as device_ts,
           ddatetime as cts,
           ts
      from dbo.palm_ordorder
;

create or replace trigger dbo.tiI_pre_order
instead of insert, update on dbo.pre_order
referencing new as inserted old as deleted
for each row
begin
    insert into dbo.palm_ordorder on existing update with auto name
    select isnull(inserted.id, dbo.idgenerator('palm_ordorder','order_id')) as order_id,
           dateadd(day,if inserted.toDate = '2012-05-07' then -1 else 0 endif, inserted.toDate) toDate,
           inserted.print_sf,
           cast(isnull(inserted.totalCost,0)*100.0 as int) as sumtotal,
           inserted.cash_flag,
           inserted.bonus_flag,
           inserted.xid,
           inserted.salesman as salesman_id,
           inserted.client as client_id,
           0 as source,
           inserted.info,
           
           case when inserted.processed in (0,1) then inserted.processed
           else isnull(
            case inserted.processing
                when 'draft'  then 3
                when 'upload' then  (
                    select 0 from dbo.pre_order_item
                    where pre_order = inserted.id
                    having sum(cost) = inserted.totalcost
                )
                else inserted.processed
            end
           ,4) end as processed,
           
           inserted.device_ts as palm_ddatetime
end;

drop trigger if exists tiI_pre_order_item
;
create or replace view dbo.pre_order_item
as
    select order_id as pre_order,
           cat_goods_id as goods,
           vol1+vol2 as volume,
           vmeas,
           cast (poi.cost/100.0 as decimal(18,2)) as cost,
           isabsent,
           isfactor,
           comments,
           xid
      from dbo.palm_ordorderitem poi
;

create or replace trigger dbo.tiI_pre_order_item
instead of insert, update on dbo.pre_order_item
referencing new as inserted old as deleted
for each row
begin
    declare totalRows int;
    
    insert into dbo.palm_ordorderitem on existing update with auto name
    select inserted.pre_order as order_id,
           inserted.goods as cat_goods_id,
           inserted.goods as goods_id,
           isnull(inserted.volume,0) as vol1,
           0 as vol2,
           isnull(cast(inserted.cost*100.0 as int),0) as cost,
           isnull(inserted.vmeas,
                    (select package from sales.category
                       join dbo.goods on goods.g_group=category.id
                      where goods.id=inserted.goods)
            ) as vmeas,
           inserted.xid
    ;
    
    set totalRows = (select sum(cost) from dbo.palm_ordorderitem where order_id = inserted.pre_order);
    
    update dbo.palm_ordorder set processed = 0
     where order_id = inserted.pre_order and sumtotal = totalRows and processed = 4 and totalRows>0
    
end;

create or replace procedure sales.create_pre_order_item (
    @pre_order varchar(128) default null,
    @goods int default null,
    @volume int default null,
    @cost decimal(18,2) default null,
    @vmeas int default null,
    @xid uniqueidentifier
) begin
    declare totalRows int;

    if isnumeric (@pre_order) <> 1 then
        set @pre_order = isnull(
            (select id from dbo.pre_order where xid = @pre_order),
            (select pre_order from dbo.pre_order_item where xid = @xid)
        );
    end if;
    
    insert into dbo.palm_ordorderitem on existing update with auto name
    select isnull(@pre_order, pi.order_id) as order_id,
           isnull(@goods, pi.cat_goods_id) as cat_goods_id,
           isnull(@goods, pi.goods_id) as goods_id,
           coalesce(@volume, pi.vol1, 0) as vol1,
           0 as vol2,
           coalesce(cast(@cost*100.0 as int), pi.cost, 0) as cost,
           coalesce(@vmeas, pi.vmeas, 
                    (select package from sales.category
                       join dbo.goods on goods.g_group=category.id
                      where goods.id=@goods)
            ) as vmeas,
           @xid as xid
      from dummy left join dbo.palm_ordorderitem pi on pi.xid = @xid
    ;
    
    set totalRows = (select sum(cost) from dbo.palm_ordorderitem where order_id = @pre_order);
    
    update dbo.palm_ordorder set processed = 0
     where order_id = @pre_order and sumtotal = totalRows and processed = 4 and totalRows>0
    
end;


create or replace procedure dbo.pre_order_available (
    @client int,
    @ddate date,
    @gg int,
    @goods int default null
)
begin

declare @site int;
declare @partner int;

select site, partner into @site, @partner
  from buyers where id=@client;

if @goods is null then
    select pp.goods,
           cast(round(pp.price,2) as decimal(18,2)) as price
      from partner_prices_gg pp join OrdGoodsInStockMulti() ga on ga.goods_id=pp.goods and ga.isvollow=0 and stock_id=@site
     where pp.partner=@partner and pp.ddate=@ddate and g_group=@gg and price>0
else
   select @goods as @goods, dbo.getprice(null, @ddate, @goods, 0, @partner) as price
     from OrdGoodsInStockMulti() ga
    where ga.goods_id=@goods and ga.isvollow=0 and stock_id=@site and price>0
end if;

 
end;

create or replace procedure sales.buyer_sorgoods_goods (
    @buyer int,
    @ddate date default today(),
    @daysback int default 90
)
begin
    select sg.goods, count(*) as cnt, datediff(day,max(sddate), @ddate) as days_since
      from dbo.sale_order so
      join sordgoods sg
      join dbo.sordclient sc
     where sddate >= dateadd(day, -@daysback, @ddate) and sddate<@ddate
       and so.partner = (select partner from buyers where id=@buyer)
       and sc.client=@buyer
     group by sg.goods
end;

create or replace procedure sales.client_category (
    @client int
)
begin
    select * from sales.category c
     where exists (select * from dbo.pre_order_available(@client, today(), c.id ))
end;

create or replace procedure sales.article_similar(
    @id int default null, @name varchar(1024) default null, @category int default null
)
begin
    declare @pos int;
    declare @cnt int;
    
    set @name=isnull(@name, (select name from article where id=@id));
    set @category=isnull(@category, (select category from article where id=@id));

    set @pos=locate(@name, ' ');
    
    /*
    while (@pos>0) loop
        select count(*) as cnt, locate(@name, ' ',@pos+1) as pos
          into @cnt, @pos
          from article where name like left(@name,@pos)+'%';
        
        set @pos=;
    end loop;
    */
    
    select * from article where name like left(@name,@pos)+'%' and category=@category;
    
end;


create or replace procedure sales.partner (
    @salesman int default null
)
begin
    select p.*
      from dbo.partners p
     where exists (
                select * from partners_groups_tree pgt 
                         join palm_salesman ps on ps.srv_pgroup = pgt.parent
                 where ps.salesman_id=@salesman and p.parent=pgt.id
           )
end;


create or replace procedure sales.plset (
    @salesman int
) begin
    select
        pls.id,
        pls.name,  
        ppls.ord     
    from dbo.pricelist_set pls 
        join dbo.partners_plset ppls on ppls.id = pls.id
    where @salesman is null or
        exists (
            select * from dbo.partner_plist where plset = pls.id
                and (@salesman is null or partner in (select id from sales.partner(@salesman))) //528
        )
end;

create or replace procedure sales.plset_pricelist (
    @salesman int
) begin
    select
        psplink.plist,
        psplink.plset,   
        psplink.ord
    from dbo.psplink 
        join dbo.partners_plset on psplink.plset = partners_plset.id
    where exists (
        select * from dbo.partner_plist pl
            join sales.partner (@salesman) p on p.id = pl.partner
        where pl.plist = psplink.plist
    )
end;

create or replace procedure sales.pricelist (
    @salesman int
) begin
    select p.*
    from dbo.pricelist p
    where exists (
        select * from sales.plset_pricelist (@salesman)
         where plist = p.id
    )
end;


create or replace procedure sales.price (
    @salesman int,
    @g_group int default null,
    @goods int default null,
    @ddate date default today()
) begin
    select
        psp.plist,
        psp.plset,
        goods.id as goods,
        cast(round(pp.price*r.ratio,2) as decimal(15,2)) as price
    from dbo.pricelist_prices pp
        join dbo.cbratio r on pp.currency = r.currency and r.ddate = pp.ddate
        join dbo.goods on pp.goods = goods.id
        join sales.plset_pricelist (@salesman) psp on pp.list = psp.plist
    where (goods.g_group = @g_group or @g_group is null)
        and (goods.id = @goods or @goods is null)
        and pp.ddate = @ddate
        and (goods.removed = 0 or exists (select * from goods g2 where sgpalm = goods.id and removed =0))
        and (
            not exists (
                select * from dbo.plset_ggroup where plset = psp.plset
            )
            or exists (
                select * 
                from dbo.plset_ggroup plg join dbo.goods_groups_tree ggt
                  on plg.g_group = ggt.parent
                where plset = psp.plset and ggt.id = goods.g_group
            )
        )
end;

create or replace view sales.psprice
as
    select
        pp.ddate,
        pp.goods,
        psp.plist,
        psp.plset,
        cast(round(pp.price*r.ratio,2) as decimal(15,2)) as price
    from dbo.pricelist_prices pp
        join dbo.cbratio r on pp.currency = r.currency and r.ddate = pp.ddate
        join dbo.goods on pp.goods = goods.id
        join dbo.psplink psp on pp.list = psp.plist
        join dbo.partners_plset on psp.plset = partners_plset.id
    where (
            not exists (
                select * from dbo.plset_ggroup where plset = psp.plset
            )
            or exists (
                select * 
                from dbo.plset_ggroup plg join dbo.goods_groups_tree ggt
                  on plg.g_group = ggt.parent
                where plset = psp.plset and ggt.id = goods.g_group
            )
        )
;


create or replace procedure sales.partner_price (
    @ddate date default today()
) begin
    select partner, goods, price, ddateb, ddatee
      from dbo.partner_price
     where @ddate between ddateb and ddatee
end;
