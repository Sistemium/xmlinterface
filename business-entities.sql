create or replace procedure dbo.agent(@username varchar(32) default null)
begin
 select id, name, tabnum
   from agents a left join employee e on e.person_id=a.person
  where a.loginname=@username 
//     or @username is null
//     or (@username='sasha' and loginname is not null)
end;

create or replace view dbo."expreturn-position"
as
 select sr.agent as "expeditor", srgoods.id, goods, goodvol as "volume", goodmeas as "package",
        'good' as "goods-condition", sr.sorder as "sale_order", sr.partner
   from srgoods join sale_return sr
  where goodvol>0
;

create or replace procedure dbo."expreturn-position" ()
begin
 select * from dbo."expreturn-position"
end;

create or replace procedure dbo."expreturn-position-update" (
  @id int, @expeditor int, @goods int, @package int, "@goods-condition" varchar(128),
  @sale_order int, @partner int, @volume decimal (18,4)
)
begin
 declare @sr_id int;
 declare @poorvol decimal (18,4);
 declare @goodvol decimal (18,4);
 declare @trashvol decimal (18,4);

 if @id is null then
   set @id=idgenerator('srgoods');
 end if;

 select id into @sr_id
   from sale_return
  where agent=@expeditor and ddate=today()
    and (partner=@partner or (partner is null and @partner is null))
    and (sorder=@sale_order or (sorder is null and @sale_order is null))
 ;
 
 if @sr_id is null then
   insert into sale_return (id, agent, ddate, partner, sorder)
   values (@sr_id, @expeditor, today(), @partner, @sale_order)
 end if;

 insert into srgoods on existing update 
  (id, sreturn, goods,
  values (@id, @sr_id, @goods,
 
 select * from dbo."expreturn-position" where id=@id;
end;

create or replace procedure dbo."goodspackage" (@searcher text default null)
begin
with goodspackage as (
 select goods.id as "goods", msr.ms_id as "package", msr.rel,
        gb.barcode,
        goods.code as "article"
   from goods join goods_groups gg on gg.id=goods.g_group
   join goods_barcode gb on  gb.goods=goods.id
   join ms_rel_sets msr on msr.msrh_id=goods.msrh_id and msr.ms_id=gb.measure
)
select goodspackage.goods, goodspackage."package", goodspackage.rel
  from goodspackage
 where (length(@searcher)>10 and barcode=@searcher)
    or (length(@searcher)<7 and goodspackage.article=@searcher)
    or @searcher is null
 
end;


create or replace procedure dbo."package" (@goods int default null)
begin
 select *
     from measures
 where @goods is null or exists (select * from gg_ms_set join goods_groups join goods where ms_id=measures.id and goods.id=@goods)
end;

create or replace procedure dbo."income-position" (@palette varchar(128))
begin
 select newid() as xid, @palette as "palette", null as "volume", null as "goods", null as "package"
end;

create or replace view dbo."storage-place" (id, name)
as
    select shelves.id, shelves.rowname+'.'+shelves.name
      from shelves join warehouse where warehouse.name='короба'
     order by shelves.ts desc
;

create table dbo."income-position" (
    id int default autoincrement,
    palette varchar(128),
    "production-date" date not null,
    volume int not null,
    not null foreign key ("goods") references dbo."goods",
    not null foreign key ("package") references dbo."measures",
    foreign key ("supply") references dbo."supply",
    not null foreign key ("income-place") references dbo."shelves" (id),

    xid uniqueidentifier default newid(),
    ts datetime default current timestamp,
    primary key (id),
    unique(xid), unique (palette)
);

create or replace view dbo."storage-place" (id, name)
as
select shelves.id, shelves.rowname+'.'+shelves.name
from shelves join warehouse where warehouse.name='короба'
order by shelves.ts desc
;

create table dbo."palette-placement" (
    id int default autoincrement,

    not null foreign key ("income-position") references dbo."income-position",
    not null foreign key ("storage-place") references dbo."shelves" (id),
    
    xid uniqueidentifier default newid(),
    ts datetime default current timestamp,
    primary key (id),
    unique(xid)
);

create or replace procedure spp.EncashmentAmendment (in @ddate timestamp default null)
begin
 select date(bd.ddate) encashment_date, old_value old_terminal, cast(e.wsumm as decimal(18,2)) summ, new_value new_terminal, trans_start amendment_date
     from dblog.dbevent join dblog.dbevent_column join encashment e on e.xid=dbevent.object join branch_day bd
  where creator='notriggers' and column_name='terminalid'
      and (trans_start>=@ddate or @ddate is null)
    order by trans_start desc;
end;

create table dbo.accessdate (id int default autoincrement, username varchar(256) not null, ddate timestamp,
 xid uniqueidentifier not null default newid(), ts timestamp default timestamp,
 primary key(id),
 unique(xid),
 unique(username)
);


drop trigger IU_catterminal
;

create or replace view "dbo"."catterminal" as
select 
 t.id, t.terminalid, t.code, t.address, t.name, t.isdeleted,
 t.ts, t.xid, b.id as branch, brt.broute,
 br.name as "branch-route.name", t.src_system, t.isBankAccount
from dbo.pps_terminal t
 left join dbo.branch b on b.subdealerid = t.main_subdealerid
 left outer join (dbo.branch_routeterm brt join dbo.branch_route br on br.id=brt.broute )
 on brt.terminalid = t.id and br.branch=branch
where t.ttp_id=4
;


create or replace trigger IU_catterminal instead of update on
dbo.catterminal
referencing old as deleted new as inserted
for each row
begin
  declare @new_broute integer;
  set @new_broute = inserted.broute;
  if isnull(inserted."branch-route.name",'') <> isnull(deleted."branch-route.name",'') then
    set @new_broute = (select id from branch_route where branch = inserted.branch and name = inserted."branch-route.name");
    if isnull(inserted."branch-route.name",'') <> '' and @new_broute is null then
      raiserror 55555 'Указано неверное название маршрута [%1!]',inserted."branch-route.name";
      return
    end if end if;
  -- insert
  if @new_broute is not null and deleted.broute is null then
    insert into dbo.branch_routeterm with auto name
      select inserted.id as terminalid,
        @new_broute as broute
  -- update
  elseif @new_broute is not null and deleted.broute is not null and @new_broute <> deleted.broute then
    update dbo.branch_routeterm
      set broute = @new_broute
      where terminalid = deleted.id
  -- delete
  elseif @new_broute is null and deleted.broute is not null then
    delete from dbo.branch_routeterm
      where terminalid = deleted.id
  end if;
  return
end;


create or replace procedure dbo."bday_route"
 (@bday int)
begin
   select bdr.id, @bday as bday, br.id as broute, bdr.collector, bdr.xid
     from branch_route br left join bday_route bdr on bdr.bday=@bday and bdr.broute=br.id
    where br.branch=(select branch from branch_day where id=@bday)
end;


create table xmlgate.agent (
    id int default autoincrement,

    name varchar(128) not null,
    deviceName varchar (128) null,
    
    xid uniqueidentifier default newid(), ts timestamp default timestamp,
    primary key (id), unique (xid), unique (name)
);


create or replace procedure xmlgate.agent 
    (in @name varchar(128) default null, in @deviceName varchar(128) default null)
begin
    if @name is not null then
        insert into agent with auto name
        select @name as name
         where not exists (select * from agent where name=@name)
        ;
        
        update agent set deviceName=@deviceName 
         where @deviceName is not null and name=@name
        ;
        
    end if;
    
    select * from agent where name=@name or @name is null;
    
end;



create table dbo.goods_barcode (
    id int default autoincrement,
    barcode varchar(128) not null,
    not null foreign key (goods) references dbo.goods on delete cascade,
    not null foreign key (measure) references dbo.measures on delete cascade,
    xid uniqueidentifier default newid(), ts timestamp default timestamp,
    primary key (id), unique (xid), 
);

alter table goods_barcode add unique(goods, measure, barcode)
;


create view dbo.subdealer
AS
	SELECT s.SubdealerID as id, s.name, etc.terminals_cnt, 
		   (select count(*) from Preprocessing..terminals where subdealerid=s.subdealerid and terminalid>0) active_terminals_cnt
      from Preprocessing..Subdealers s
      left join dbo.subdealer_etc etc on etc.subdealerid=s.subdealerid

go

alter trigger IU_subdealer on dbo.subdealer instead of update
AS
begin
    if update(terminals_cnt)
    begin
    	update dbo.subdealer_etc 
           set terminals_cnt=inserted.terminals_cnt
          from inserted 
         where subdealer_etc.subdealerid=inserted.id and inserted.terminals_cnt is not null
    
        insert into dbo.subdealer_etc (subdealerid, terminals_cnt)
        select id, terminals_cnt
          from inserted
         where not exists (select * from dbo.subdealer_etc where subdealerid=inserted.id)
    
    	delete dbo.subdealer_etc 
          from inserted 
         where subdealer_etc.subdealerid=inserted.id and inserted.terminals_cnt is null
    end
end


CREATE FUNCTION bpa_totals_change ()
RETURNS TABLE 
AS
RETURN 
(

   select * from paysystemetc_log
    where change_ddate> dateadd(d,-14,getdate())

)
