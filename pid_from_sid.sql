set pages 1000
set lines 200
col username for a10
select b.status,a.inst_id,a.PID "Ora PID",a.SPID "Server PID",
a.LATCHWAIT,b.Program, b.Username,b.Osuser,b.machine,
b.terminal,a.terminal,b.Process "Client Process"
from gv$process a,gv$session b where a.addr=b.paddr and b.sid=&SID
/
