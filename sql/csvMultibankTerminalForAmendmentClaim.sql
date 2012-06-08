alter FUNCTION [dbo].[csvMultibankTerminalForAmendmentClaim] 
(	
	@date datetime,
	@summ datetime
)
RETURNS TABLE 
AS
RETURN 
(
select top(1) dt.terminalid
from dbo.distribday_trace dt join dbo.bankaccountterminal t on dt.terminalid = t.terminalid
where t.mainSubdealer = 7
  and dt.ddate = CONVERT(VARCHAR(10), @date, 121)
  and t.src_system in (1,2)
  and dt.today_summ > @summ
order by dt.today_summ desc
