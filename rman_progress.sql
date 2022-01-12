set lines 140 pages 999
column operation            format a15        heading "RMAN Operation"
column megs_read            format 9,999,999  heading "Megs|Read|so far"
column total_megs           format 9,999,999  heading "Total|Datafile|Megs"
column perc_compl           format A5         heading "Perc|Comp"
column megs_written         format 999,999    heading "Megs|Written|so far"
column start_time           format a20        heading "Backup Step|start time"
column time_now             format a20        heading "Time|Now"
column est_comp_time        format a20        heading "Estimated|Compl Time"
column minutes              format 9,999      heading "Mins|Proc|so far"
column megs_read_per_min    format 9,999      heading "Megs|Read|Per|Min"
column megs_written_per_min format 999,999    heading "Megs|Written|Per|Min"
column compression_ratio    format a10        heading "Compression|Ratio"
column mins_remaining       format 99,999     heading "Mins|Remain"

alter session set nls_date_format='DD-MON-YYYY HH24:MI:SS';

with total_df
as (select round(sum(bytes)/1024/1024 ,0) total_megs
    from   dba_data_files)
select t0.operation operation,
       t0.input_bytes/1024/1024 megs_read,
       t1.total_megs            total_megs,
       lpad(round(t0.input_bytes/1024/1024/t1.total_megs*100,1)||'%',5) perc_compl,
       trunc(t0.output_bytes/1024/1024) megs_written ,
       to_char(t0.start_time, 'DD-MON-YYYY HH24MISS') start_time,
       to_char(sysdate + ((t1.total_megs/decode(t0.operation,'BACKUP',t0.input_bytes/1024/1024,null))*(sysdate-t0.start_time)), 'DD-MON-YYYY HH24MISS') est_comp_time,
       trunc((sysdate-t0.start_time)*24*60) minutes ,
       trunc((t0.input_bytes/1024/1024) / ((sysdate-t0.start_time)*24*60)) megs_read_per_min,
       trunc((t0.output_bytes/1024/1024) / ((sysdate-t0.start_time)*24*60)) megs_written_per_min,
       decode(t0.input_bytes,
              0,null,
              round(t0.input_bytes/t0.output_bytes,2)||':1') compression_ratio,
       round(nvl(t2.time_remaining,0)/60,0) mins_remaining
from   v$rman_status t0,
       total_df      t1,
       v$session_longops t2
where  t0.status = 'RUNNING'
and    t0.sid    = t2.sid (+)
order  by t0.start_time
/

--set lines 120
--col event format a65
--col client_info format a55
--select sid, spid, client_info, event, seconds_in_wait, p1, p2, p3
--from v$process p, v$session s
--where p.addr = s.paddr and client_info like 'rman channel=%';

select sid,
       start_time,
       sysdate time_now,
       start_time + (totalwork * (sysdate-start_time)/sofar) est_comp_time,
       ROUND((totalwork * (sysdate-start_time)/sofar) * 1440,0) minutes,
       round(totalwork*8/1024,0) total_megs,
       round(sofar*8/1024,0)            megs_read,
       round((sofar/totalwork) * 100,1)||'%' perc_compl
from   v$session_longops
where  totalwork > sofar
AND    opname NOT LIKE '%aggregate%'
AND    opname like 'RMAN%';

select sid, serial, device_type, type, status, filename,
round(nvl(total_bytes/1024/1024,(select bp.bytes/1024/1024 from v$backup_piece bp where bp.handle = filename) ),1) total_mb,
round(bytes/1024/1024,1) sofar_mb,
round(bytes/nvl(total_bytes, (select bp.bytes from v$backup_piece bp where bp.handle = filename) )*100,1) PCT,
io_count, open_time,
to_date(sysdate + (100 / (round(bytes/nvl(total_bytes, (select bp.bytes from v$backup_piece bp where bp.handle = filename) )*100,1)) * (sysdate - open_time) ) ) eta
from v$backup_async_io
where open_time > trunc(sysdate)
and type != 'AGGREGATE'
and status = 'IN PROGRESS'
order by type,open_time;
