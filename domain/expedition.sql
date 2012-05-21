create or replace procedure dbo."salesman_workday" (
    @palm_salesman int default null,
    @ddate date default null,
    @saleperiod int default null
) begin
    
    if @saleperiod is null then
        if not exists (select * from palm_saleperiod
                        where salesman_id=@palm_salesman
                          and ddate=@ddate) then
            update palm_saleperiod
               set processed=1, closed=1
             where salesman_id=@palm_salesman
               and ddate=(select max(ddate) from palm_saleperiod p2 where salesman_id=@palm_salesman and ddate<@ddate)
               and processed=0
               and ddate<today()
               and not exists (select * from palm_repayment where saleperiod_id=palm_saleperiod.saleperiod_id)
               and not exists (select * from palm_sale where saleperiod_id=palm_saleperiod.saleperiod_id)
        end if;
    end if;
    
    select * from palm_saleperiod
     where (salesman_id=@palm_salesman
       and ddate=@ddate) or (@ddate is null and @palm_salesman is null and saleperiod_id=@saleperiod)
end;

create or replace procedure dbo.expedition (@agent int, @ddate date)
begin
    with expedition as (
        select d.id, d.ndoc as name,
               d.xid,
               if d.ddateb is null then 0 else 1 endif started,
               if d.ddatee is null then 0 else 1 endif finished
          from dbo.delivery d join dbo.agents a on a.id=d.securer
         where a.id=@agent
           and ddate >= @ddate and ddate < @ddate+1
    )
    select * from expedition
 --    where started = 1 or not exists (select * from expedition where started=1 and not finished=0)
     order by name desc
end;

create or replace procedure dbo.expedition_destination_test (@expedition int)
begin
    
    select d.*, da.id, da.xid, da.isComplete
      from 
           (select @expedition as delivery, loadto as address, max(ord) ord, max(client.id) destination,
                   sum(order_cnt) as ordersCnt,
                   sum(doc_cnt) as documentsCnt,
                   sum(inc_cnt) as encashmentsCnt
              from (select max(b.id) id, b.loadto, b.partner, count(*) as order_cnt, max(dlo.ord) ord, null as doc_cnt, null as inc_cnt
                      from dbo.delord dlo
                      join dbo.sordclient sc on sc.id=dlo.sorder
                      join dbo.buyers b on b.id=sc.client
                     where dlo.id=@expedition
                     group by b.loadto, b.partner
                     union 
                     select max(b.id), b.loadto, b.partner, 0, 0, sum(docstatus) , sum(incstatus)
                       from dbo.delinc di
                       join dbo.buyers b on b.id=di.client
                      where di.id=@expedition
                      group by b.loadto, b.partner
                    ) as client
             group by address, partner
           ) as d
           left join dbo.expedition_destination da on da.expedition=@expedition and da.destination=d.destination 
        
end;


drop trigger if exists tIU_expedition_destination
;

create or replace view dbo.expedition_destination
as
    select  da.*, d.id as expedition, b.id as destination,
            if da.departure is not null then 1 else 0 endif isComplete
      from  dbo.delivery d cross join dbo.buyers b
            left join dbo.deladdr da on da.delivery=d.id and da.client=b.id
;


create or replace trigger dbo.tIU_expedition_destination
instead of insert, update on dbo.expedition_destination
referencing new as inserted old as deleted
for each row
begin
    if update(isComplete) then
        insert into dbo.deladdr on existing update with auto name
        select if inserted.isComplete>0 then now() else null endif departure,
               inserted.xid,
               inserted.destination as client,
               inserted.delivery as delivery,
               isnull(inserted.id,idgenerator('deladdr')) as id
    end if;
end;


create or replace procedure dbo.expedition_order_task (@expedition int, @destination int)
begin
    select so.id, so.sddate, so.ndoc, so.info,
           cast(sum(sg.summ) as decimal(18,2)) as summ,
           cast(sum(sg.mcvol) as decimal(18,1)) as mcvol,
           count(distinct sg.goods) as goodsCnt
      from dbo.delivery d join dbo.delord dlo join dbo.sale_order so
      join dbo.sordclient sc on sc.id=dlo.sorder
      join (select sg.id as sorder, client, vol*price as summ, sg.vol/mgg.vrel mcvol, sg.goods
              from dbo.sordgoods sg join dbo.my_goods mgg on mgg.id=sg.goods and mgg.iam=user_id('dbo') and mgg.parent=0
           ) as sg on  sg.sorder=so.id and  sg.client=sc.client
     where d.id=@expedition and sc.client=@destination
    group by so.id, so.sddate, so.info, so.ndoc
end;


create or replace procedure dbo.expedition_encashment_task (@destination int, @saleperiod int, @expedition int default null)
begin
    select dbt.id, dbt.ddate, dbt.info,
           cast(dbt.summ/100 as decimal(18,2)) as summ,
           cast(dbt.csum/100 as decimal(18,2)) as csum,
           dbt.own, dbt.color, dbt.overdue 
      from dbo.palm_saleperiod sp
      join dbo.palm_salesman s on s.salesman_id=sp.salesman_id and sp.saleperiod_id=@saleperiod,
           lateral (dbo.Download_PartnerDebt (1, s.salesman_id, s.routetypegroup_id, @saleperiod)) dbt
           (id, saleperiod, partner, ddate, info, summ, csum, own, color, overdue)
     where dbt.partner in (select partner
                             from dbo.buyers
                            where buyers.id=@destination
                           )
end;


drop trigger if exists tIU_expedition_encashment
;

create or replace view dbo.expedition_encashment 
as 
    select repayment_id as id, saleperiod_id, debt_id as task, client_id, ddate, summ, xid, ts, kkmprinted
      from dbo.palm_repayment e
;


create or replace trigger dbo.tIU_expedition_encashment
instead of insert, update on dbo.expedition_encashment
referencing new as inserted old as deleted
for each row
begin

    if exists (select * from palm_saleperiod where saleperiod_id=inserted.saleperiod_id and closed=1) then
        raiserror 55555 'Рабочий день закрыт, нельзя вносить изменения';
        return;
    end if;
    
    insert into dbo.palm_repayment on existing update with auto name
    select isnull(inserted.ddate,now()) as ddate, inserted.summ, inserted.xid,
           inserted.saleperiod_id, inserted.task as debt_id,
           inserted.client_id,
           isnull(inserted.id,idgenerator('expedition_encashment')) as repayment_id,
           if isnull((select color
                        from dbo.expedition_encashment_task (inserted.client_id, inserted.saleperiod_id) 
                       where id=inserted.task
                      ),0)=1
           then 1 else 0 endif as kkmprinted
    ;
    
end;

create or replace trigger dbo.tID_expedition_encashment
instead of delete on dbo.expedition_encashment
referencing old as deleted
for each row
begin

    if exists (select * from palm_saleperiod where saleperiod_id=deleted.saleperiod_id and closed=1) then
        raiserror 55555 'Рабочий день закрыт, нельзя вносить изменения';
        return;
    end if;
    
    delete palm_repayment where xid=deleted.xid
    
end;


create or replace procedure dbo.expedition_item (@destination int)
begin
    select ei.xid, 
           if arrival is null then 0 else 1 endif arrive,
           if departure is null then 0 else 1 endif leave
      from dbo.deladdr ei
     where ei.id=@destination
end;

create or replace procedure dbo.expedition_item_save (@xid uniqueidentifier, @started int default null, @finished int default null)
begin

    update dbo.deladdr
       set arrival=case when arrival is null and @started=1 then now()
                        when arrival is not null and @started=0 then null
                        else arrival
                   end,
           departure=case when departure is null and @started=1 then now()
                          when departure is not null and @started=0 then null
                          else departure
                     end
     where xid=@xid and (@started is not null or @finished is not null)

end;


create or replace procedure dbo.expedition_save (
    @id int, @started int default null, @finished int default null, @xid uniqueidentifier default null)
begin
    update dbo.delivery
       set ddateb=case when @started=1 and ddateb is null then now()
                       when @started=0 and ddateb is not null then null
                       else ddateb
                  end,
           ddatee=case when @finished=1 and ddatee is null then now()
                       when @finished=0 and ddatee is not null then null
                       else ddatee
                  end
     where id=@id;
    
    if @started=1 and not exists (select * from dbo.deladdr where delivery=@id) then
        insert into dbo.deladdr with auto name
        select @id as delivery, b.loadto as addr, count(*) as order_cnt, max(dlo.ord) ord
          from dbo.delord dlo
          join dbo.sordclient sc on sc.id=dlo.sorder
          join dbo.buyers b on b.id=sc.client
         where dlo.id=@id
         group by addr
    elseif @started=0 then
        delete dbo.deladdr where delivery=@id
    end if;
    
end;


create table dbo.deladdr (
    
    arrival datetime null,
    departure datetime null,
    
    foreign key (delivery) references dbo.delivery on delete cascade,
    foreign key (client) references dbo.buyers on delete cascade,
        
    id int default autoincrement,
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid),

);

grant connect to geo;

create table geo.position (
    
    entity varchar(128) not null,
    
    longitude decimal(13,10) not null,
    latitude decimal(13,10) not null,
    accuracy decimal(7,2) null,
    speed decimal(9,6) null,
    device_ts timestamp not null,
    errorCode int, 
    
    id int default autoincrement,
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    cts datetime default current timestamp,
    
    primary key (id),
    unique (xid),

);


    
