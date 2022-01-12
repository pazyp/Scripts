spool  /tmp/tempusage
set lines 700
set pages 500
column c1 heading "Table Space" Format a11
column c2 heading "segfile" Format a30
column c3 heading "segblk" Format a20
column c4 heading "Size MB" Format a15
column c6 heading "Serial" Format a20
column c7 heading "Username" Format a12
column c8 heading "OS User" Format a15
column c9 heading "Program" Format a40
column c10 heading "Status" Format a15
select to_char(sysdate, 'yyyymmdd') dt from dual;
SELECT   b.TABLESPACE c1
        , b.segfile#
        , b.segblk#
        , ROUND (  (  ( b.blocks * p.VALUE ) / 1024 / 1024 ), 2 ) size_mb
        , ROUND (  (  ( b.blocks * p.VALUE ) / 1024 / 1024 / 1024 ), 2 ) size_gb
        , a.SID
        , a.serial#
        , a.username c7
        , a.osuser c8
        , a.program c9
        , a.status c10
     FROM v$session a
        , v$sort_usage b
        , v$process c
        , v$parameter p
    WHERE p.NAME = 'db_block_size'
      AND a.saddr = b.session_addr
      AND a.paddr = c.addr
 ORDER BY b.blocks
        , b.TABLESPACE
        , b.segfile#
        , b.segblk#;

spool off

