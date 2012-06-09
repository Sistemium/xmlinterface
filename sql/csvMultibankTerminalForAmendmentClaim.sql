alter function dbo.csvMultibankTerminalForAmendmentClaim
(	
	@date datetime,
	@summ decimal(18,2)
)
returns table 
as
return 
(
select top(1) dt.terminalid
  from dbo.distribday_trace dt join dbo.bankaccountterminal t on dt.terminalid = t.terminalid
 where t.mainsubdealer = 7
   and dt.ddate = convert(varchar(10), @date, 121)
   and t.src_system in (1,2)
   and dt.today_summ > @summ
   and exists(select * 
                from dbo.paysystempayments
               where bank_ddate = dt.ddate
                 and terminalid = dt.terminalid
                 and paysystem = 9000000)
 order by case when today_summ > @summ*3 then 0 else 1 end, today_summ % 100 desc
)
