col ksppinm for a40;
col ksppstvl for a40;
set pagesize 100;
set lines 200;

select 
  ksppinm,
  ksppstvl 
from 
  x$ksppi a, 
  x$ksppsv b 
where 
  a.indx=b.indx and 
  substr(ksppinm,1,1) = '_'
  and ksppinm like '%&hidden_parameter%';
