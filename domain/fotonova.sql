create or replace procedure fnova.remains()
begin
    declare local temporary table #g (goods int, remains int, income int, recept int, init int, accp int, comp int)
    ;
    insert into #g with auto name
    select goods, sum(volume) remains
    from remains r join storages s on r.storage=s.id 
    where s.wh=1291
    group by goods
    ;
    insert into #g with auto name
    select goods, sum(vol) income
    from income d join incgoods g join storages s on d.storage=s.id 
    where s.wh=1291 and d.ddate>=today()
    group by goods
    ;
    insert into #g with auto name
    select goods, sum(vol) recept
    from recept d join recgoods g join storages s on d.storage=s.id 
    where s.wh=1291 and d.ddate>=today()
    group by goods
    ;
    insert into #g with auto name
    select goods, 
     if so.status1=0 then vol endif init,
     if so.status1=1 and status2=0 then vol endif accp,
     if so.status2=1 and status4=0 then vol endif comp
     from sordgoods sg join sale_order so on so.id=sg.id
    where so.ddate>=today() and so.status4=0
     and sg.storage in (select id from storages where wh=1291)
    ;
    select pg.code as goods, sum(remains) remains, sum(income) income, sum(recept) recept, sum(init) init, sum(accp) accp, sum(comp) comp
    from #g join partner_goods pg on pg.goods=#g.goods and pg.partner=6969
    group by goods;
end;


alter service fotonova
TYPE 'RAW' URL elements
AUTHORIZATION OFF USER "dba" 
as call util.xml_for_http(dbo.fotonovaSvc(:url1));

create or replace function dbo.fotonovaSvc(@entity varchar(128))
returns xml
begin
    declare @xml xml;
    declare @sql text;
    
    if @entity is null then
        return xmlelement ('exception','Уточните сущность');
    end if;
    
    set @sql=string('select * into @xml from fnova.',@entity,
                    if not exists (select * from systable where table_name=@entity and creator=user_id('fnova')) then '()' endif,' ',
                    case @entity
                        when 'goods' then if http_variable('url2')='emptyCode' then
                            ' where fotonovaCode is null'
                        end if
                    end,
                    ' for xml auto')
    ;
    
    execute immediate WITH RESULT SET OFF @sql;
    
    return xmlelement ('fotonovadata', @xml);
exception when others then
    return xmlelement ('exception',xmlattributes(SQLCODE as "SQLCODE", SQLSTATE as "SQLSTATE"),errormsg());
end;

create or replace function dbo.fotonova_orders(@ddateb date default today(), @ddatee date default today(), @fotonumber varchar(32) default null)
returns xml
begin

    declare @result xml;
    
    select isnull(@ddateb,today()), isnull(@ddatee,today())
      into @ddateb,@ddatee
    from dummy where @fotonumber is null
    ;
    
     
    if @ddatee - @ddateb > 13 then
        return xmlelement ('exception','Указан период более 14 дней') 
    end if;
   
    select xmlelement('orders',
               xmlattributes (@ddateb as "startDate", @ddatee as "endDate"),
               xmlagg(xmlelement('order',
                    xmlattributes (so.ndoc, date(so.sddate) as "shipping-date", b.name as "client-name", b.loadto as "client-address",
                                    case when status1=0 then 'init'
                                        when status1=1 and status2=0 then 'accepted'
                                        when status2=1 and status4=0 then 'picking'
                                        when status4=1 then 'done'
                                    end as "state", _extra.getvalue(so.id,'fotonovaorder') as "fotonova-number", 
                                    so.info as "comment", so.ts
                                    
                    ),
                    (select xmlagg(xmlelement('delivery',
                                    xmlattributes (d.ndoc, 
                                                    case when status1=0 then 'init'
                                                        when status1=1 and status2=0 then 'ready'
                                                        when status2=1 and status3=0 then 'in-progress'
                                                        when status3=1 then 'done'
                                                    end as "state", d.ddateb as "started", d.ddatee as "finished",
                                                    t.name as "truck-number", d.ts
                                )))
                        from dbo.delivery d
                        join dbo.delord dlo on dlo.id=d.id
                        left join dbo.truck t on t.id=d.truck
                        where dlo.sorder=so.id
                    ),
                    (select xmlagg(xmlelement('order-position',
                                    xmlattributes (pg.code as goods, cast(sg.vol as int) as donevol,
                                                   cast(sg.volume as int) as initvol,
                                                   g.short_name as "name" --, sg.ts
                                    )
                            ) order by sg.subid)
                        from dbo.sordgoods sg
                        join dbo.partner_goods pg on pg.goods=sg.goods and pg.partner=6969
                        join dbo.goods g on g.id=sg.goods
                        where sg.id=sc.id and sg.sordclient=sc.subid and sg.client=sg.client
                    )
               ) order by so.ndoc)
    )
      into @result
      from dbo.sale_order so
      join dbo.sordclient sc on sc.id=so.id
      join dbo.buyers b on b.id=sc.client
     where so.sdep=1622 and
         ( (so.sddate between @ddateb and @ddatee and @fotonumber is null)
        or (@fotonumber is not null and so.id in (select record_id from dbo.extra join dbo.etype where etype.code='fotonovaorder' and extra.value=@fotonumber))
        )
    ;

    return xmlelement ('fotonova',@result);
end;


create service "fotonova-orders"
TYPE 'RAW' 
AUTHORIZATION OFF USER "dba" 
as call util.xml_for_http(dbo.fotonova_orders(:startDate,:endDate,:fotonovaNumber));


create or replace function dbo.fotonova_changes(@ddate date default today())
returns xml
begin

    declare @result xml;
    
    set @ddate=isnull(@ddate,today());
    
    select xmlelement('changes',
               xmlattributes (@ddate as "toDate"),
                    (select xmlagg(xmlelement('order-position',
                                    xmlattributes (pg.code as goods, cast(sg.vol as int) as donevol, cast(sg.volume as int) as initvol, sg.ts,
                                                   so.ndoc, date(so.sddate) as "shipping-date",
                                                   _extra.getvalue(so.id,'fotonovaorder') as "fotonova-number"
                                    )
                            ) order by sg.ts)
                        from dbo.sordgoods sg
                        join dbo.sale_order so on sg.id=so.id
                        join dbo.partner_goods pg on pg.goods=sg.goods and pg.partner=6969
                        where so.sdep=1622 and so.sddate<@ddate and sg.ts between @ddate and @ddate+1
                    )
    )
      into @result

    ;

    return xmlelement ('fotonova',@result);
end;



alter  service "fotonova-changes"
TYPE 'RAW' 
AUTHORIZATION OFF USER "dba" 
as call util.xml_for_http(dbo.fotonova_changes(:toDate));





create FUNCTION dbo."fotonova_supply"(@ddateb date default null, @ddatee date default null, @fotonumber varchar(32) default null)
returns xml
begin

    declare @result xml;
    
    select isnull(@ddateb,today()), isnull(@ddatee,today())
      into @ddateb,@ddatee
    from dummy where @fotonumber is null
    ;
    
//    return xmlelement('trace',csconvert('utf8',
     
    if @ddatee - @ddateb > 20 then
        return xmlelement ('exception','Указан период более 21 дней') 
    end if;

   
    select xmlelement('orders',
               xmlattributes (@ddateb as "startDate", @ddatee as "endDate"),
               xmlagg(xmlelement('supply',
                    xmlattributes (so.ndoc, datetime(so.ddate) as "shipping-date", 
                                    case when status=1 then 'done'
                                         when status0=0 then 'init'
                                         when status0=1 then 'arrived'
                                         else 'unknown'
                                    end as "state", _extra.getvalue(so.id,'fotonovasupply') as "fotonova-number", 
                                    so.info as "comment", so.ts
                                    
                    ),

                    (select xmlagg(xmlelement('supply-position',
                                    xmlattributes (pg.code as goods, cast(sg.vol as int) as donevol,
                                                   cast(sg.volume as int) as initvol,
                                                   g.short_name as "name" --, sg.ts
)
                            ) order by sg.subid)
                        from dbo.supgoods sg
                        join dbo.partner_goods pg on pg.goods=sg.goods and pg.partner=6969
                        join dbo.goods g on g.id=sg.goods
                        where sg.id=so.id
                    )
               ) order by so.ndoc)
    )
      into @result
      from dbo.supply so
     where so.storage in (select id from storages where wh=1291) and
         ( (date(so.ddate) between @ddateb and @ddatee and @fotonumber is null)
        or (@fotonumber is not null and so.id in (select record_id from dbo.extra join dbo.etype where etype.code='fotonovasupply' and extra.value like @fotonumber))
        )
    ;

    return xmlelement ('fotonova',@result);
end


create service "fotonova-supply"
TYPE 'RAW' 
AUTHORIZATION OFF USER "dba" 
as call util.xml_for_http(dbo.fotonova_supply(:startDate,:endDate,:fotonovaNumber));


create view fnova.goods as
select goods.id, short_name as name, goods.code, pg.code fotonovaCode, width, height, length, weight, goods.ts
 from goods join goods_groups_tree ggt on ggt.id=goods.g_group and ggt.parent=5087
left join partner_goods pg on pg.goods=goods.id and pg.partner=6969;



create or replace procedure fnova.orders_agg ()
begin
with sorder as (
    select so.id, date(so.sddate) ddate, so.ndoc, b.name client_name, b.loadto,
           sum(sg.vol) vol, cast(sum(sg.vol/g.vrel) as decimal(18,2)) mcvol, sum(g.weight*sg.vol/g.vrel) weight, count(*) cnt
      from sale_order so
      join sordgoods sg on sg.id=so.id join my_goods g on g.id=sg.goods and g.iam=user_id('dbo')
      join dbo.sordclient sc on sc.id=so.id
      join dbo.buyers b on b.id=sc.client
     where sdep=1622
     group by so.id, ddate, so.ndoc,client_name, b.loadto
),
dl as (
    select d.id, date(d.ddate) ddate, if t.name like '%аренда%' then 'rent' else 'own' endif truck_type, isnull(tt2.name,tt.name) truck_name,
          sum(hrent) hrent, sum(delrent.hrent*tariff) rent_cost, list(comm) rent_comment
      from delivery d
      join truck t left join truck_type tt
      left join (delrent join truck_type tt2) on delrent.delivery=d.id and partner=18969
     group by d.id, ddate, truck_name, truck_type, d.id
)
select d.ddate, truck_type, truck_name, hrent, rent_cost, rent_comment,
       sum(vol) vol, sum(mcvol) mcvol, sum(weight) weight, sum(cnt) rows_cnt, count(*) orders_cnt, count(distinct loadto) addrs_cnt, d.id,
           list(distinct so.client_name) clients, list(distinct so.loadto) addrs
  from sorder so 
  join (delord dlo join dl d on d.id=dlo.id
       ) on dlo.sorder=so.id
 group by d.id, d.ddate, truck_type, truck_name, hrent, rent_cost, rent_comment
order by 1,2
end