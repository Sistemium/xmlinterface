drop table dbo.subdealer_legalentity;
drop table dbo.legalentity;

create table dbo.legalentity (
	id int identity,

	name varchar(64) not null,
	inn varchar(30)  null,

	xid uniqueidentifier not null default newid(),
	primary key (id),
	unique (name),
	--unique (inn),
	unique(xid)
);

create table dbo.subdealer_legalentity (
	id int identity,
	xid uniqueidentifier not null default newid(),

	legalentity int foreign key references dbo.legalentity (id),
	subdealer int not null,

	primary key (id),
	unique(xid),
	unique(subdealer),

);


ALTER view [dbo].[subdealer]
AS
SELECT s.SubdealerID as id, s.name, etc.terminals_cnt, 
	   cast(sum(t.terminalamount) as decimal(18,2)) terminals_cash,
	   cast(sum(1 - t.isdeleted) as int) active_terminals_cnt,
       s.parentid as parent,
       (select ms.id from main_subdealer ms join preprocessing..hierarchymap h on h.parentid=ms.id
         where h.subdealerid=s.subdealerid) main_subdealer
  from Preprocessing..Subdealers s
       left join dbo.terminal t on t.subdealerid=s.subdealerid
       left join dbo.subdealer_etc etc on etc.subdealerid=s.subdealerid
 group by s.SubdealerID, s.name, etc.terminals_cnt,s.parentid


alter procedure dbo.subdealer_set(@subdealer int, @legalentity int = null)
as
begin
	if (@legalentity is not null)
	begin
		delete subdealer_legalentity
		 where subdealer=@subdealer and legalentity<>@legalentity

		insert into subdealer_legalentity (legalentity, subdealer)
		select @legalentity, @subdealer
		  from subdealer
		 where id=@subdealer and not exists (select * from subdealer_legalentity where subdealer=subdealer.id)
	end
end

alter view dbo.main_subdealer
as
select s.subdealerid id, s.name, s.parentid as branch_subdealer
from preprocessing..subdealers s
  join branch_subdealer bs on bs.id=s.parentid
  

ALTER FUNCTION [dbo].[subdealer_func] (
	@username varchar(128) = null
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT *,
		  (select top 1 legalentity from subdealer_legalentity where subdealer=subdealer.id) legalentity
	  from dbo.subdealer
     where id in (select subdealerid from preprocessing..accountsubdealers where login=@username)
        or id=(select subdealerid from preprocessing..accounts where login=@username)
        or exists (select * from preprocessing..accounts a join preprocessing..roles r on r.roleid=a.roleid
                     join preprocessing..hierarchymap h on h.subdealerid=dbo.subdealer.id and h.parentid=a.subdealerid
                   where a.login=@username and r.permissions & 4 >0 )
        or @username is null
)




create FUNCTION [dbo].[terminalstate_func] 
	(@branch int = null)
RETURNS TABLE 
AS
RETURN 
(
 select terminals.terminalid terminalid, 
        case when terminals.flags & 512 > 0 then 'DISABLE' else 'ENABLE' end state,
        address,
        sd.name,
        terminals.lastconnecttime,
      [fulladdress]
      ,[administrativearea]
      ,[city]
      ,[street]
      ,[building]
      ,[districtadministrativearea]
      ,[districtcity]
      ,[latitude]
      ,[longitude]
      ,(select top 1 legalentity
          from ppscat..subdealer_legalentity 
         where subdealer=terminals.subdealerid) legalentity
   from preprocessing.dbo.terminals join preprocessing.dbo.hierarchymap hm on hm.subdealerid= terminals.subdealerid 
   join preprocessing.dbo.Subdealers sd on sd.parentid = isnull(@branch,6) and sd.subdealerid=hm.parentid
   left join ppscat..geoaddress g on g.terminalid=terminals.terminalid
    /* and exists(select * from dbo.preprocessingpayments 
                where serverDateTime >'2010-04-01' and TerminalID = dbo.terminals.TerminalID
              )*/ 
 where lastconnecttime>'2010-04-01'
)


  