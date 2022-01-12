
select ss.tablespace_name, ts.mb "total MB", trunc(sum(ss.used_blocks * 8096/1024/1024)) "used MB",
trunc(sum(ss.used_blocks * (select value from v$parameter where name = 'db_block_size')/1024/1024) +
sum(ss.free_blocks * (select value from v$parameter where name = 'db_block_size')/1024/1024) ) "allocated MB",
trunc(sum(ss.used_blocks)/ (sum(ss.used_blocks) + sum(ss.free_blocks))*100,2) "%used"
from gv$sort_segment ss, (select tablespace_name, sum(bytes/1024/1024) mb from dba_temp_files group by tablespace_name) ts
where ss.tablespace_name = ts.tablespace_name
group by ss.tablespace_name, ts.mb;

