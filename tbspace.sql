set lines 200
set pagesize 50
col file_name for a50
col tablespace_name for a30
break on TABLESPACE_NAME skip 1
compute sum label 'Total Space per Tablespace' of Actual_MB on TABLESPACE_NAME
select TABLESPACE_NAME, FILE_NAME, AUTOEXTENSIBLE, MAXBYTES/1024/1024 Max_Mb, BYTES/1024/1024 Actual_Mb
from dba_data_files
order by TABLESPACE_NAME, FILE_NAME;

