clear
 
column sid           format a10
column username      format a10  truncate
column logon_time    format a12  truncate
column terminal      format a10  truncate
column last_call_et  format 999  truncate
column sql_text      format a30  wrap
column prev_sql_text format a40  wrap

alter session set nls_date_format = 'DDMM HH24MISS';

set lines 140 pages 999 trimout on tab off trimspool on

prompt --------------------

prompt - Active Session SQL

prompt --------------------


select t0.sid||','||serial# sid,
       t0.username,
       t0.logon_time,
       t0.terminal,
       t0.last_call_et,
       t1.sql_text sql_text,
       t2.sql_text prev_sql_text
from   v$session t0,
       v$sqlarea t1,
       v$sqlarea t2
where  t0.username      is not null
and    t0.status        = 'ACTIVE'
and    t0.username      not in ('SYS','SYSTEM')
and    t0.sql_address   = t1.address (+)
and    t0.prev_sql_addr = t2.address (+)
order  by t0.last_call_et asc;



-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
column sid               format 999999
column operation_type    format a10    heading "Op|Type"
column operation_id      format 999999
column max_mem_used_k    format 999999 heading "MaxMem|UsedK"
column actual_mem_used_k format 999999 heading "ActualMem|UsedK"
column work_area_size_k  format 999999 heading "WorkArea|SizeK"
---- column sql_text          format a30  
set long 4000
prompt ----------------------

prompt - Session Memory Usage

prompt ----------------------


select t0.sid,
       t0.sql_hash_value,
       t0.operation_Type,
       t0.operation_id,
       t0.max_mem_used/1024    max_mem_used_k,
       t0.actual_mem_used/1024 actual_mem_used_k,
       t0.work_area_size/1024  work_area_size_k,
       t1.SQL_FULLTEXT
from   V$SQL_WORKAREA_ACTIVE t0,
       V$SQLAREA             t1
where  t0.SQL_HASH_VALUE = t1.HASH_VALUE (+);



-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
column sid               format a10
column opname            format a10 truncate;
column target            format a20 truncate;
column time_remaining    format 999999 heading "Time|Remain"
column perc_compl        format 99     heading "%|Compl"
--- column sql_text          format a40  wrap

prompt ------------------

prompt - Large Operations

prompt ------------------


select t0.sid||','||t0.serial# sid,
       t0.opname,
       t0.target,
       t0.start_time,
       t0.last_update_time,
       t0.time_remaining,
       round(t0.sofar/t0.totalwork*100,0) perc_compl,
       t1.sql_text
from   v$session_longops t0,
       v$sqlarea         t1
where  t0.time_remaining != 0
and    t0.sql_hash_value = t1.hash_value (+);

