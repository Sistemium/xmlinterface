create table xmlgate.agent_warehouse (
    id int default autoincrement,
    
    foreign key (warehouse) references dbo.warehouse on delete cascade,
    foreign key (agent) references xmlgate.agent on delete cascade,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
)
;


create or replace procedure dbo.warehouse ( @login varchar(128) default current user, @agent int default null)
begin

    select * from dbo.warehouse 
     where id in (select warehouse from xmlgate.agent_warehouse
                  where agent = @agent or (@agent is null and agent in (select id from xmlgate.agent(@login)))
                  )

end;


create or replace procedure dbo.warehouse_goods (
    @wh int default null,
    @goods int default null,
    @searcher varchar(32) default null
)
begin

    select whgoods.id, whgoods.wh as warehouse, goods, string(shelves.rowname, ' ', shelves.name, ' ', whgoods.name) as address,
           (select cast(sum(volume) as int) 
              from remains join storages on storages.id=remains.storage  
             where goods=@goods and storages.wh=@wh) as remains /*,
           (select cast(sum(volume) as int) 
              from supgoods key join supply join storages on storages.id=supply.storage  
             where goods=@goods and storages.wh=@wh and supply.status=0) as supply*/
      from dbo.whgoods join shelves
     where (@wh is null or whgoods.wh=@wh)
       and (@goods is null or goods=@goods)
 --      and (@searcher is null or ) 
    ;

end;


create or replace procedure dbo.warehouse_goods_set (
    @wh int default null,
    @goods int default null,
    @address varchar(32) default null
)
begin
  declare @whgoods int;
  declare @shelves int;
  declare @level int;
  
  if @address='0' then
     delete whgoods where wh=@wh and goods=@goods;
  else
      select id, substr(@address,5,1)
        into @shelves, @level
        from shelves
       where wh=@wh and right(rowname,2) = left (@address,2) and name=substr(@address,3,2);
      
      if @shelves is null or @level is null then
        raiserror 55555 'Неверный адрес. Укажите адрес в формате РРССЭ (ряд, стеллаж, этаж цифрами без пробелов).';
        return -1;
      end if;
          
      insert into whgoods (goods, wh, shelves, name)
      on existing update
       values (@goods, @wh, @shelves, @level)
  end if;

end;



alter FUNCTION dbo.cell_fn (
      @searcher varchar(128)
) RETURNS TABLE AS RETURN (
    SELECT * from dbo.cells
    where type=0 and (
        (len(@searcher) >= 5 and address like
        'B'+upper(left(@searcher,2))+'-'+substring(@searcher,3,2)+'_'+substring(@searcher,5,1)+'%'+substring(@searcher,6,1)+'%'
            and (not address like '%)' or
                 not exists (select * from dbo.cells c
                          where left(address,8)=left(cells.address,8) and address<cells.address and goods is null)
            )
        )
    )
)
;

create or replace procedure dbo.wms_cell (
      @searcher varchar(128) default null,
      @needempty int default 0,
      @wms_place int default null,
      @goods int default null
)
begin
 declare local temporary table cells (id int, address varchar(32), goods int, "comment" varchar(32), type int, productionDate datetime, ts datetime);

 insert into cells 
 SELECT id, address, goods, "comment", type, productionDate, ts
 from wms_cell
    where type=0 and (
        @searcher is null or
        (len(@searcher) >= 5 and address like
        'B'+upper(left(@searcher,2))+'-'+substring(@searcher,3,2)+'_'+substring(@searcher,5,1)+'%'+substring(@searcher,6,1)+'%'
        )
    )
    and (goods is not null or (@searcher is not null and address not like '%(_)%'))
    and (@goods is null or goods=@goods)
    and (@wms_place is null or address like
          (select string('B',rowname,'_',colname,'_',level,'%')
             from wms.place where id=@wms_place)
        )
    ;

    select * from cells
end;

create table dbo.wms_cell_operation (
    id int default autoincrement,
    
    operation varchar(16) not null,
    agent int not null,
    volume int not null default 1,
    goods_volume int null,
    remains int null,
    goods int,
    cell int,
    
    foreign key (worker) references dbo.agents on delete cascade,
    foreign key (wtd) references dbo.workteamday on delete cascade,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);  

alter table wms_cell_operation add goods_volume int null;

create or replace trigger dbo.tbI_wms_cell_operation
before insert on dbo.wms_cell_operation
referencing new as inserted
for each row
begin
    
    declare @name varchar(128);
    
    select name into @name from xmlgate.agent where id=inserted.agent;

    if inserted.worker is null then
        set inserted.worker = isnull(
                (select id from dbo.agents
                  where code=@name),
                (select id from dbo.agents
                  where loginname=@name)
        );
        if inserted.worker is null then
            raiserror 55555 'Сотрудник склада не найден для пользователя %1!', @name;
        end if
    end if;
    
    if inserted.wtd is null then
        set inserted.wtd = (
            select top 1 wtd.id
              from workteamday wtd join workteamtable wt
             where wtd.status1=0 and (
                        inserted.worker in (wt.worker,wtd.master)
                        or exists 
                            (select id from agents where id=inserted.worker and storage_master=wtd.master and position=2096)
                   )
             order by wtd.ddate desc, wtd.ndoc desc
        );
        if inserted.wtd is null then
            raiserror 55555 'Открытая смена не найдена для пользователя %1!, worker.id = %2!', @name, inserted.worker
        end if;
    end if;
    
end;


alter procedure dbo.cellinv (@cell int, @goods int, @volume int, @agent int = null)
as
begin
   if isnull(@volume,0)=0
   begin
      select @goods=null, @volume=null
   end
   
   update cells set goods=@goods, comment=@volume, ts=getdate()
    where id=@cell
    
   insert into dbo.wms_cell_operation (operation, agent, goods, cell, ts)
    values ('inventory', @agent, @goods, @cell, getdate())
end;


create or replace procedure dbo.cell_get (@cell int, @goods int default null, @agent int default null)
begin
 select id, "comment" as taken, null as xid
   from wms_cell where id=@cell
end;

create or replace procedure dbo.cell_set (
     @xid uniqueidentifier default null, @cell int, @taken int default 0, @remains int default null, @agent int default null, @goods int default null)
begin
    declare @newgoods int;
    declare @pdate datetime;
    
    select coalesce(@remains, cast("comment" as int) - @taken,0), isnull(@goods, goods), productionDate
        into @remains, @goods, @pdate
        from dbo.wms_cell where id=@cell and "comment" not like '%[^0123456789]%'
    ;
    if @remains<0 then 
        set @remains=0;
    end if;
    
    set @newgoods=if @remains=0 then null else @goods endif;
    
    if @newgoods is null then
        set @pdate=null
    end if;
    
    if @agent is not null then
       insert into dbo.wms_cell_operation (operation, agent, goods, cell, goods_volume, remains)
       values ('take', @agent, @goods, @cell, @remains, @remains + @taken)
    end if;

    update dbo.wms_cell set "comment"=@remains, ts=getdate(), goods=@newgoods, productionDate=cast(@pdate as datetime)
     where id=@cell
    ;
end;

create or replace procedure dbo.cell_placement (
    @agent int, @goods int default null, @volume int default null, @cell int default null,
    @xid uniqueidentifier default null, @pdate varchar(20) default null
)
begin
    declare @remains int;
    
    if @cell is not null then
        
        select cast("comment" as int)
          into @remains
          from dbo.wms_cell
         where id=@cell and "comment" not like '%[^0123456789]%'
        ;
        
        insert into dbo.wms_cell_operation (
            operation, agent, goods, cell, goods_volume, remains
        ) values (
            'placement', @agent, @goods, @cell, isnull (@volume, 0), isnull (@remains,0)
        );
        
        update dbo.wms_cell
           set goods=@goods, "comment"=@volume, ts=getdate(),
               productionDate=cast(@pdate as smalldatetime)
         where id=@cell;
         
        if @@rowcount=0 then
            raiserror 55555, 'Указан некорректный идентификатор ячейки';
            return -1;
        end if;

        return 1;
    end if;

    select @agent as "agent", @goods as "goods", @volume as "volume", @cell as "cell";
end;

