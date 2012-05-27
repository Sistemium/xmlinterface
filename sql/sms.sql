concept sms;

create function sms.SendURL(
    in "login" varchar(128),
    in password varchar(128),
    in want_sms_ids integer,
    in phones long varchar,
    in "message" long varchar,
    in max_parts integer,
    in rus integer,
    in originator varchar(128) ) 
returns xml
url 'http://www.smstraffic.ru/multi.php' type 'HTTP:POST'
;


create table sms.data (
    id int default autoincrement,
    
    phone text not null,
    msg text not null,
    originator varchar(64) not null default 'Unact',
    
    result xml not null,
    
    creator varchar(128) default current user,
    
    xid uniqueidentifier default newid(),
    ts datetime default timestamp,
    primary key (id),
    unique (xid)
);

create or replace trigger tbi_sms_data
before insert on sms.data
referencing new as inserted
for each row
begin

 declare @response xml;
 declare @code integer;
 declare @description long varchar;

 declare @login varchar(128);
 declare @password varchar(128);
 declare @max_parts integer;
 declare @rus integer;
 declare @want_sms_ids integer;

 set @login = op.getUserOption('smsLogin');
 set @password = op.getUserOption('smsPassword');
 set @max_parts = 1;
 set @rus = 1;
 set @want_sms_ids = 1;

 set @response = sms.SendURL(@login, @password, @want_sms_ids, inserted.phone, inserted.msg, @max_parts, @rus, inserted.originator);

 select top 1 
        code,
        description
   into @code, @description 
   from openxml(@response,'/reply')
        with(code integer 'code', description long varchar 'description');

 if @code <> 0 then
  raiserror 55555 'Ошибка при отправке SMS: '+ @description;
  return;
 end if;
 
 set inserted.result=@response;

end;

create procedure sms.Send(in @phone long varchar, in @message long varchar, in @originator varchar(128) default 'Unact')
begin
 declare @response xml;
 declare @code integer;
 declare @description long varchar;

 declare @login varchar(128);
 declare @password varchar(128);
 declare @max_parts integer;
 declare @rus integer;
 declare @want_sms_ids integer;

 set @login = 'unact1';
 set @password = 'hawovofe';
 set @max_parts = 1;
 set @rus = 1;
 set @want_sms_ids = 1;

 set @response = sms.SendURL(@login, @password, @want_sms_ids, @phone, @message, @max_parts, @rus, @originator);

 select top 1 
        code,
        description
   into @code, @description 
   from openxml(@response,'/reply')
        with(code integer 'code', description long varchar 'description');

 if @code <> 0 then
  raiserror 55555 'Ошибка при отправке SMS: '+ @description;
 end if;

end