grant connect to iorders;

create table if not exists iorders.eventlog (
    id int default autoincrement,
    
    module varchar(64) not null,
    action varchar(64) not null,
    data text null,
    
    palm_salesman int not null,
    
    device_cts smalldatetime not null,
    
    xid uniqueidentifier default newid(),
    cs datetime default current timestamp,
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);
