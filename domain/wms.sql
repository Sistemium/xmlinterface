concept wms;

grant dba to wms;


create or replace view wms.goods
as
 select 
  goods.id, short_name as "name", goods.code, msrv.rel vrel, msrb.rel brel,
        cast(isnull(g_parm.minvol,gg_parm.minvolume) as int) prel
   from dbo.goods
    	join dbo.my_ggroup mgg
            on mgg.id=goods.g_group and mgg.iam=user_id('dbo')
        join dbo.ms_rel_sets msrv
            on msrv.msrh_id=goods.msrh_id and
            msrv.ms_id=mgg.vmeas
        join dbo.ms_rel_sets msrb
            on msrb.msrh_id=goods.msrh_id and
            msrb.ms_id=mgg.pmeas
        left join dbo.gg_parm on gg_parm.id=1006 and gg_parm.g_group = goods.g_group
        left join dbo.g_parm on g_parm.id=1006 and g_parm.goods = goods.id
;


create or replace procedure wms."goods" (
    @barcode varchar(128),
    @warehouse int default null,
    @constrain varchar(32) default null
)
begin

    with byBarCode as (
        select goods from (
           select goods from dbo.goods_barcode where barcode=@barcode
            union
           select goods from goods_barcode
            where not exists (select * from goods_barcode b2 where barcode=@barcode)
              and barcode like left(@barcode,13)+'%' and length(@barcode)>10
        ) as goods where not exists (select * from wms.oldgoods where id=goods.goods)
    )
    select top 20 * --id, name, code, vrel, brel, prel,
/*          ,if (select count(*) as cnt from byBarCode)<=1
           then null
           else (select date(max(ddate)) from dbo.remains
                  where goods=goods.id and volume>0 and storage = (select inc_storage from dbo.warehouse where id=@warehouse)
                )
           endif */ ,null as lastSeen 
      from wms.goods goods 
     where (goods.id in (select goods from byBarCode bbc)
        or goods.code=@barcode
        or (charindex('*',@barcode)>0 and length(@barcode)>4 and goods.name like '%'+replace(@barcode,'*','%')+'%')
           ) and (
            @warehouse is null or @constrain is null or (@constrain = 'remains' and exists (
                   select * from dbo.remains
                    where goods=goods.id and volume>0
                      and storage = (select inc_storage from dbo.warehouse where id=@warehouse)
                   )
           ))
     order by --lastseen desc,
           name

end;


create table wms.place (
    id int default autoincrement,
    
    rowname varchar(5) not null,
    colname varchar(5) not null,
    level varchar(5) not null,
    name varchar(15) compute (string(rowname,colname,level)),
    
    outer_db varchar(10) null,
    
    ord varchar(10) null,

    foreign key (warehouse) references dbo.warehouse on delete cascade,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);



create table wms.place_goods (
    id int default autoincrement,
    
    foreign key (place) references wms.place on delete cascade,
    foreign key (goods) references dbo.goods on delete cascade,
    
    mcvol int not null default 0,
    blvol int not null default 0,
    pkvol int not null default 0,
    
    mdate date null,
    
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);

create or replace trigger wms.ti_place_goods
 after insert, update, delete on wms.place_goods
 referencing old as deleted new as inserted
 for each row
begin
    declare @inv int;
    declare @name varchar(32);
    declare @warehouse varchar(32);
    declare @invlist int;
    declare @place int;
    declare @goods int;
    declare @colname varchar(12);
    declare @outer_db varchar(12);
    declare @addr varchar(12);
    
    if deleting then
        set @goods=deleted.goods;
        set @place=deleted.place;
    else
        set @goods=inserted.goods;
        set @place=inserted.place;
    end if;
        
    select name, warehouse, outer_db, colname
      into @name, @warehouse, @outer_db, @colname
      from wms.place where id=inserted.place
    ; 
    
    select top 1 i.id
      into @inv 
      from dbo.inventory i join wms.place pl on i.wh=pl.warehouse
     where i.ddate>today()-3 and i.status2=0 and pl.id=@place
     order by i.ddate desc;
     
    if @inv is not null then
        
        select id into @invlist from dbo.inventory_list where inv=@inv and ndoc='wms.system.unact.ru';
        
        if @invlist is null then
            set @invlist=idgenerator('inventory_list');
            insert into dbo.inventory_list (id, inv, ndoc) values (@invlist, @inv, 'wms.system.unact.ru');
        end if;

        if update (goods) or deleting then
            update invgoods
               set volume =volume - deleted.mcvol,
                   bvolume=bvolume - deleted.blvol,
                   pvolume=pvolume - deleted.pkvol
             where goods=deleted.goods and invl=@invlist
        end if
        ;
        
        if not deleting then
            insert into invgoods on existing update with auto name
            select @invlist invl, pg.goods, sum(pg.mcvol) volume, sum(pg.blvol) bvolume, sum(pg.pkvol) pvolume
              from wms.place_goods pg join wms.place p on p.id=pg.place
             where pg.goods=inserted.goods and p.warehouse=@warehouse
             group by pg.goods
        end if;
        // update invlist, if status1 then update iremains
        // Два места пикинга и нецелые коробки наверху
    end if;
    
    case (select outer_db from wms.place where id=@place)
        when 'mozilla' then
            for c as c cursor for 
              select wc.id as wc_id, gp.goods g_goods, mcvol, gc_mdate
                from dbo.wms_cell wc left join 
                       (select goods, sum(mcvol) mcvol, min(mdate) gc_mdate, ROW_NUMBER() OVER (ORDER BY goods ASC) lev
                          from wms.place_goods where place=@place group by goods) as gp
                       on wc.address like '___-__-_'+if gp.lev>1 then string('(',gp.lev,')') else '' endif
               where wc.address like (select string('_',rowname+'-'+colname+'-'+level,'%') from wms.place where id=@place) 
            do
                update dbo.wms_cell 
                   set dbo.wms_cell.goods=g_goods, "comment"=mcvol,
                       productionDate=cast(gc_mdate as smalldatetime), ts=getdate()
                 where id=wc_id
            end for
        when 'cat' then
            if not deleting then
                select max(name)
                  into @addr
                  from wms.place_goods join wms.place
                 where goods=inserted.goods and name<@name and outer_db=@outer_db and (mcvol+pkvol+blvol)>0 
                ;
                if @outer_db='cat' and @addr is not null then
                    raiserror 55555 'Товар необходимо пернести в %1!', @addr;
                elseif inserted.mcvol+inserted.blvol+inserted.pkvol>0 then
                    call dbo.warehouse_goods_set (@wh=@warehouse, @goods=inserted.goods, @address=@name);
                end if
            end if
    end;
    
end;


insert into wms.place (rowname, colname, level) 
select str0(row.row_num,2,0), str0(col.row_num,2,0), lev.row_num
from rowgenerator row, rowgenerator col, rowgenerator lev
where col.row_num <=90 and row.row_num<=12 and lev.row_num<=5
;


update wms.place set warehouse = 1291 where rowname in ('01','02');
update wms.place set warehouse = 1143 where rowname not in ('01','02');

update wms.place set outer_db='mozilla' where level>2;
update wms.place set outer_db='cat' where level<3;



create or replace view wms.place_type (id, name)
as
    select 'cat', 'Пикинг'
    union all
    select 'mozilla', 'Сток'
;


create or replace procedure wms.inv (
    @wh int
)
begin
    select inventory.id as id , 
           string(date(inventory.ddate), ' - ', warehouse.name) as name
      from dbo.inventory join dbo.warehouse 
     where inventory.ddate>today()-28 and status1=0 and wh=@wh
     order by inventory.ddate desc, warehouse.name desc
end;

create or replace procedure wms.inv_cellset (
    @inv int
)
begin
    select rowname as id, rowname as name
      from dbo.zonerow
     where wh = (select wh from dbo.inventory where id=@inv)
     order by 1
end;

create or replace procedure wms.inv_cell (
    @inv int,
    @cellset varchar(32),
)
begin
    select string(shelves.rowname, shelves.name) as name
      from dbo.shelves
     where wh = (select wh from dbo.inventory where id=@inv)
       and rowname=@cellset
     order by shelves.ord
end;


create table wms.operation (
    id int default autoincrement,
    
    name varchar(32) not null,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);

create or replace view wms.operation (id, name) as
    select 'lift-down', 'Спуск'
     union all
    select 'lift-up', 'Подъем'
;

create table wms.operation_request (
    id int default autoincrement,
    
    foreign key (place) references wms.place on delete cascade,
    operation varchar(32) not null,
    
    is_done int not null default 0,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);

create or replace procedure wms.goods_recent_date (
    @goods int
)
begin
select productionDate as pdate, max(ts) ts
      from dbo.wms_cell
     where  productionDate is not null
        and id in (select cell 
                     from wms_cell_operation
                    where ts>dateadd(hour,-1,now()) and goods=@goods
                      and operation='placement'
                   )
     group by pdate
    order by ts desc
end;



create or replace procedure wms.progress()
as
select rowname,
(select max (colname)
     from wms.place_goods join wms.place p2 
  where p2.rowname=place.rowname and p2.level<=2 and outer_db<>'mozilla') 
as 'pick',

(select max (colname)
     from wms.place_goods join wms.place p2 
  where p2.rowname=place.rowname and p2.level=2 and outer_db='mozilla') 
as 'stock2',

(select max (colname)
     from wms.place_goods join wms.place p2 
  where p2.rowname=place.rowname and p2.level=3 and outer_db='mozilla') 
as 'stock3',

(select max (colname)
     from wms.place_goods join wms.place p2 
  where p2.rowname=place.rowname and p2.level=4 and outer_db='mozilla') 
as 'stock4',

(select max (colname)
     from wms.place_goods join wms.place p2 
  where p2.rowname=place.rowname and p2.level=5 and outer_db='mozilla') 
as 'stock5',

(select max (colname)
     from wms.place_goods join wms.place p2 
  where p2.rowname=place.rowname and p2.level=6 and outer_db='mozilla') 
as 'stock6'

from wms.place
group by rowname
order by 1
;


create procedure xmlgate.newagent()

as
insert into xmlgate.agent_warehouse (agent, warehouse)
 select id, 1143
 from xmlgate.agent a where not exists (select * from xmlgate.agent_warehouse where agent=a.id) and ts>today()
;


/*
-- select * 
delete
from invgoods 
 where invl=2962 and not exists
    (select * from wms.place_goods join wms.place
      where place.warehouse=1143 and goods=invgoods.goods)
;


with pg as 
(select warehouse, goods, sum(mcvol) mcvol, sum (blvol) blvol, sum(pkvol) pkvol 
     from wms.place_goods join wms.place
  where place.warehouse=1143
  group by goods, warehouse)
select * from pg where not exists 
 (select * from invgoods join inventory_list join inventory
   where ndoc='wms.system.unact.ru' and wh=pg.warehouse and goods=pg.goods and volume=mcvol and bvolume=blvol and pvolume=pkvol
  )
;
*/

create table wms.article (
    id int default autoincrement,
    
    name varchar(128) not null,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid),
    unique (name)
);

create table wms.package (
    id int default autoincrement,
    
    name varchar(16) not null,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid),
    unique (name)
);

create table wms.article_package (
    id int default autoincrement,
    
    foreign key (article) references wms.article,
    foreign key (package) references wms.package,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);


create table wms.ordr (
    id int default autoincrement,
    
    shipping_date date,
    allow_picking int not null default 0,
    
    null foreign key (picker) references xmlgate.agent,
    
    is_picked int not null default 0,
    is_loaded int not null default 0,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);

create table wms.ordr_article (
    id int default autoincrement,
    
    foreign key (ordr) references wms.ordr,
    foreign key (article) references wms.article,
    
    target_volume int not null,
    target_volume int not null,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);

create or replace view wms.defect_cause (id,name, ord) as
    select 'own', 'Собственный', 1
    union all
    select 'prod', 'Производственный', 2
    union all
    select 'other', 'Форс-мажор', 3
;

create or replace view wms.goods_condition (id,name) as
    select 'shop', 'Магазин'
    union all
    select 'util', 'Списание'
;


create or replace view wms.warehouse_defect_cause (
 warehouse, defect_cause, buyer, seller
) as
    select 1143, 'prod', 213017, 7017
    union all
    select 1143, 'own', 61143, 23143
    union all
    select 1143, 'other', 212017, 6017
;

create or replace view wms.warehouse_goods_condition (
 warehouse, goods_condition, storage
) as
    select 1143, 'shop', 8004
;

drop table if exists wms.picking_box;

create table wms.picking_box (
    id int default autoincrement,

    goods_condition varchar(16) not null,
    defect_cause varchar(16) not null,

    foreign key (agent) references xmlgate.agent,
    foreign key (warehouse) references dbo.warehouse,
    foreign key (recept) references dbo.recept,
    
    written_off int not null default 0,

    barcode varchar(32) not null,

    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid),
    unique (barcode)

);

create or replace trigger wms.tu_picking_box
 after update on wms.picking_box
 referencing old as deleted new as inserted
 for each row
begin
    if inserted.written_off=1 and deleted.written_off<>1 then
        call wms.picking_box_recept (inserted.id);
    elseif inserted.written_off<>1 and deleted.written_off=1 then
        update wms.picking_box
           set recept=null
         where id=inserted.id
        ;
        
        delete dbo.recept where id=inserted.recept;
        
    end if;
end;


drop table if exists wms.defect_sorted;

create table wms.defect_sorted (
    id int default autoincrement,
    
    not null foreign key (goods) references dbo.goods,
    not null foreign key (picking_box) references wms.picking_box on delete cascade,
    
    volume int not null,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)

);


create or replace procedure wms.picking_box (
    @barcode varchar(32),
    @agent int default null,
    @warehouse int
) begin

    set @barcode=replace(@barcode,'*','%');

    if (length(@barcode)<>15 and left(@barcode,1)<>'%') or length(@barcode)<6 then
        raiserror 55555 'Неверный номер этикетки';
        return;
    end if;
    
    select isnull(pb.id, idgenerator('picking_box','id','wms')) as id,
           @barcode barcode, isnull(pb.agent,@agent) as agent,
           @warehouse as warehouse, pb.goods_condition, pb.defect_cause, pb.xid
      from sys.dummy
      left join wms.picking_box pb on pb.barcode like @barcode
     where @agent is not null or pb.id is not null
    
end;



drop table if exists wms.consignment_accepted_goods;
drop table if exists wms.consignment_accepted;

create table wms.consignment_accepted (
    id int default autoincrement,
    
    isFinished int not null default 0,
    
    not null foreign key (agent) references xmlgate.agent,
    not null foreign key (picking_box) references wms.picking_box,
    not null foreign key (warehouse) references dbo.warehouse,
    
    foreign key (recept) references dbo.recept,
   
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)

);

create or replace trigger wms.tu_consignment_accepted
 after update on wms.consignment_accepted
 referencing old as deleted new as inserted
 for each row
begin
    if inserted.isFinished=1 and deleted.isFinished<>1 then
        call wms.consignment_recept (inserted.id);
    elseif inserted.isFinished<>1 and deleted.isFinished=1 then
        update wms.consignment_accepted
           set recept=null
         where id=inserted.id
        ;
        
        update dbo.rreturned set status1 = 0 where rec_id=inserted.recept;
        delete dbo.rreturned where rec_id=inserted.recept;
        delete dbo.recept where id=inserted.recept;
        
    end if;
end;

create table wms.consignment_accepted_goods (
    id int default autoincrement,
    
    not null foreign key (consignment_accepted) references wms.consignment_accepted on delete cascade,
    not null foreign key (goods) references dbo.goods,
    
    volume int not null,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)

);

create or replace procedure wms.consignment_expected(
    @picking_box int
)
begin
    select goods, sum (volume) as volume, max(ts) ts
      from wms.defect_sorted
     where picking_box=@picking_box
     group by goods
end;

create or replace procedure wms.consignment_accept(
    @picking_box int,
    @agent int default null,
    @warehouse int
) begin
    
    select isnull(ca.id,dbo.idgenerator('consignment_accepted', 'id', 'wms')) as id,
           ca.xid, isnull(ca.isFinished,0) isFinished
      from sys.dummy left join wms.consignment_accepted ca
        on ca.picking_box=@picking_box
    ;
    
end;

create or replace procedure wms.consignment_recept (
    @consignment_accepted int
)
begin

    declare @ddate date;
    
    for c as c cursor for
        select pb.barcode as @barcode, ca.isFinished as @isFinished, ca.recept as @recept,
               ca.warehouse as @warehouse, pb.goods_condition as @goods_condition,
               wdc.buyer as @buyer, wdc.seller as @seller, pb.id as @picking_box
          from wms.consignment_accepted ca join wms.picking_box pb
               join wms.warehouse_defect_cause wdc on wdc.warehouse=ca.warehouse and wdc.defect_cause=pb.defect_cause
         where ca.id=@consignment_accepted
    do
        case
            when isnull(@isFinished,0) <> 1 then
                raiserror 55555 'Приемка партии %1! еще не завершена', @barcode;
                return;
            when @recept is not null then
                raiserror 55555 'Партия %1! уже принята', @barcode;
                return;
        end;
        
        message 'wms.consignment_recept: checked' to client;
        
        set @recept = dbo.idgenerator('recept');
        set @ddate = today();
        
        update wms.picking_box set written_off=0
         where id=@picking_box and written_off=1
        ;
        
        insert into dbo.recept with auto name
        select @recept as id, @barcode as ndoc, @ddate as ddate, @buyer as client,
               wh.inc_storage as storage,
               5 as reason, 1970 org, 1 as paytype, 0 as stinc
          from dbo.warehouse wh
         where wh.id=@warehouse
        ;
        
        message 'wms.consignment_recept: recept:', @@rowcount to client;
        
        update wms.consignment_accepted
           set recept=@recept
         where id=@consignment_accepted
        ;
        
        insert into dbo.recgoods with auto name
        select @recept as id, number(*) as subid, cag.goods, cag.volume,
               (select top 1 gg.ms_id
                  from dbo.gg_ms_set gg 
                  join dbo.ms_rel_sets ms on ms.msrh_id = g.msrh_id and ms.ms_id = gg.ms_id
                 where g.g_group = gg.g_group and ms.rel = 1
                 order by gg.ms_id)
                 as measure, measure as pmeas, 0 as price, 0 as currency,
               (select summ from tax_value where id=g.tax and @ddate between ddateb and ddatee) as nds,
               1 as ndsin,
               1 as link
          from wms.consignment_accepted_goods cag
               join dbo.goods g on g.id=cag.goods
         where cag.consignment_accepted=@consignment_accepted and cag.volume>0
        ;
        
        message 'wms.consignment_recept: recgoods:', @@rowcount to client;
        
        for rr as rr cursor for
            select idgenerator('rreturned') as @rreturned,
                   wgc.storage as @rstorage
              from wms.warehouse_goods_condition wgc
             where wgc.warehouse=@warehouse and wgc.goods_condition=@goods_condition
        do
            
            insert into dbo.rreturned with auto name
            select @rreturned as id, @ddate as ddate, @seller as client,
                   @recept as rec_id, @rstorage as storage, 0 as status1, 0 as status2
            ;
            
            message 'wms.consignment_recept: rreturned:', @@rowcount to client;
            
            insert into dbo.incgoods with auto name
            select (select inc_id from dbo.rreturned where id=@rreturned) as id,
                   r.subid, r.goods, r.measure, r.pmeas,
                   r.price, r.currency, r.volume, r.nds, r.ndsin, r.link
              from dbo.rreturned rr join dbo.recgoods r on r.id=rr.rec_id
             where rr.id=@rreturned
            ;
            
            message 'wms.consignment_recept: incgoods:', @@rowcount to client;
            
            update rreturned set status1=1
             where id=@rreturned
            ;
            
        end for;
        
    end for;

    if @ddate is null then
        raiserror 55555 'Партия id=%1! не найдена', @consignment_accepted;
        return;
    end if;
    

end;


create or replace procedure wms.log (
    @cell int
)
begin
    select top 1 cts as ts, agent
      from dbo.wms_cell_operation
     where cell=@cell
     order by cts desc
end;



create or replace procedure wms.picking_box_recept (
    @picking_box int
)
begin

    declare @ddate date;
    
    for c as c cursor for
        select pb.barcode as @barcode, isnull(pb.recept, (select recept from wms.consignment_accepted where picking_box=pb.id)) as @recept,
               pb.warehouse as @warehouse, pb.goods_condition as @goods_condition,
               wdc.buyer as @buyer
          from wms.picking_box pb
               join wms.warehouse_defect_cause wdc on wdc.warehouse=pb.warehouse and wdc.defect_cause=pb.defect_cause
         where pb.id=@picking_box
    do
        case
            when @recept is not null then
                raiserror 55555 'Партия %1! уже списана', @barcode;
                return;
        end;
        
        message 'wms.picking_box_recept: checked' to client;
        
        set @recept = dbo.idgenerator('recept');
        set @ddate = today();
        
        insert into dbo.recept with auto name
        select @recept as id, @barcode as ndoc, @ddate as ddate, @buyer as client,
               wh.inc_storage as storage,
               5 as reason, 1970 org, 1 as paytype, 0 as stinc
          from dbo.warehouse wh
         where wh.id=@warehouse
        ;
        
        message 'wms.picking_box_recept: recept:', @@rowcount to client;
        
        update wms.picking_box
           set recept=@recept
         where id=@picking_box
        ;
        
        insert into dbo.recgoods with auto name
        select @recept as id, number(*) as subid, cag.goods, cag.volume,
               (select top 1 gg.ms_id
                  from dbo.gg_ms_set gg 
                  join dbo.ms_rel_sets ms on ms.msrh_id = g.msrh_id and ms.ms_id = gg.ms_id
                 where g.g_group = gg.g_group and ms.rel = 1
                 order by gg.ms_id)
                 as measure, measure as pmeas, 0 as price, 0 as currency,
               (select summ from tax_value where id=g.tax and @ddate between ddateb and ddatee) as nds,
               1 as ndsin,
               1 as link
          from wms.defect_sorted cag
               join dbo.goods g on g.id=cag.goods
         where cag.picking_box=@picking_box and cag.volume>0
        ;
        
        message 'wms.picking_box_recept: recgoods:', @@rowcount to client;
        
    end for;

    if @ddate is null then
        raiserror 55555 'Партия id=%1! не найдена', @picking_box;
        return;
    end if;
    

end;
