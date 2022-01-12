set lines 200 
select sid, serial#, start_time, last_update_time, time_remaining, elapsed_seconds from v$session_longops where time_remaining > 0;


col opname form a40 wrap word

select OPNAME, SOFAR, TOTALWORK
, round(SOFAR * 100 / TOTALWORK,1) pct
from v$session_longops
where SOFAR <> TOTALWORK
  and TOTALWORK > 0
/


