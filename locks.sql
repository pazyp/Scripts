SET LINESIZE 500
SET PAGESIZE 1000

COLUMN username FORMAT A15
COLUMN machine FORMAT A25
COLUMN logon_time FORMAT A20

SELECT LPAD(' ', (level-1)*2, ' ') || NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       s.lockwait,
       s.status,
       s.module,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time
FROM   v$session s
CONNECT BY PRIOR s.sid = s.blocking_session
START WITH s.blocking_session IS NULL;

SET PAGESIZE 14

-- Search for locked objects
-- To be executed under the SYSTEM account
-- Compatible with Oracle10.1.x and higher
 
select
            distinct to_name object_locked
from
            v$object_dependency
where
            to_address in
(
select /*+ ordered */
        w.kgllkhdl address
from
            dba_kgllock w,
            dba_kgllock h,
            v$session w1,
            v$session h1
where
            (((h.kgllkmod != 0) and (h.kgllkmod != 1)
            and ((h.kgllkreq = 0) or (h.kgllkreq = 1)))
            and
            (((w.kgllkmod = 0) or (w.kgllkmod= 1))
            and ((w.kgllkreq != 0) and (w.kgllkreq != 1))))
and  w.kgllktype          =  h.kgllktype
and  w.kgllkhdl            =  h.kgllkhdl
and  w.kgllkuse     =   w1.saddr
and  h.kgllkuse     =   h1.saddr
)
/
