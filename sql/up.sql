create table if not exists xmlgate.agent (
    id int default autoincrement,

    name varchar(128) not null,
    deviceName varchar (128) null,
    isAdmin int default 0,
    
    xid uniqueidentifier default newid(),
    cts datetime default current timestamp,
    ts timestamp default timestamp,

    primary key (id), unique (xid), unique (name)
);


if exists (select * from systable where table_name='person' and creator=user_id('dbo')) then
    alter table xmlgate.agent add
    foreign key (person) references dbo.person
        on delete set null
    ;
end if;


create or replace procedure xmlgate.agent (
    @name varchar(128) default null,
    @deviceName varchar(128) default null
) begin

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


create table if not exists xmlgate.agent_client (

    client integer not null,
    agent integer not null,
    
    not null foreign key (client) references op.client on delete cascade,
    not null foreign key (agent) references xmlgate.agent on delete cascade,

    id integer default autoincrement,
    cts datetime default current timestamp,
    ts datetime default timestamp,
    xid uniqueidentifier default newid(),
    
    unique (xid),
    unique(agent, client),
    primary key (id)  

);


COMMENT ON TABLE xmlgate.clientAgent
IS 'Разрешенные пользователю клиенты';


create or replace procedure xmlgate.client (
    @agent int
)
begin

    select * from op.client
     where id in (select client from agent_client where agent = @agent)
        or exists (select * from agent where id = @agent and isAdmin = 1)
    ;

end;


create or replace view xmlgate.client
as
    select cast(null as varchar(128)) processingPwd, cast(null as varchar(128)) as processingPwdNew, c.*
      from op.client c
;

create or replace trigger xmlgate.tii_client
instead of update on xmlgate.client
referencing new as inserted old as deleted
for each row
begin

    if update(processingPwdNew) and isnull(inserted.processingPwdNew,'')<>'' then
        if not exists (select * from op.client where pwd=hash(inserted.processingPwd) and id=inserted.id) then
            raiserror 55555 'Текущий платежный пароль указан неверно';
            return;
        end if;
        update op.client set
            pwd=hash(inserted.processingPwdNew)
         where id=inserted.id
        ;
    end if;
    
    if update("login") then
        update op.client set
            "login"=inserted."login"
         where id=inserted.id
    end if;
    
end;


create or replace procedure xmlgate.clientDate (
    @client int,
    @ddateb date default today() - 31,
    @ddatee date default today() + 1
)
begin

    select ddate, sum(fundsIncome) fundsIncome, sum(paymentsSum) paymentsSum from (
        select date(pp.finalizingDate) as ddate,
               cast (null as decimal(18,2)) as fundsIncome, sum(pp.summ) as paymentsSum
          from paymentprocess pp join payment p
         where p.client=@client and pp.final=1 and pp.error=0
           and pp.finalizingDate between @ddateb and @ddatee
         group by ddate
         
         union all
         
        select date(ddate) as ddate,
               sum(summ) as fundsIncome,
               cast (null as decimal(18,2)) as paymentsSum
          from  op.replenishment
         where client=@client
           and ddate between @ddateb and @ddatee
         group by ddate
    ) as t group by ddate;

end;


create or replace xmlgate.prepaymentByFileType (
    @id int
) begin

    select op.prepayment.*
      from op.prepayment
     where exists (select * from op.csvfile where type=@id and id = prepayment.csvfile)

end;
