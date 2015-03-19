create or replace procedure xmlgate.userActivity (
    @date date default today()
)
begin

    select username,
        list(distinct path) paths,
        //list (distinct ip) as ips,
        //list (distinct host) as hosts, 
        min(ts) mints, max(ts) maxts, count(*) cnt,
        sum(datediff (millisecond, cts, ts))/1000.0 lnth,
        count(if request like 'insert%' or request like 'update%' then 1 endif) cntupd
     from xmlgate.query
    where cts between @date and @date+1
    group by username
    order by maxts desc;

end;