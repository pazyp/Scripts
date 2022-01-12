Rem
Rem $Header: crusrlk.sql 03-apr-2007 $
Rem
Rem Author: raymond.wauben@gmail.com
Rem    NAME
Rem      crusrlk.sql
Rem    DESCRIPTION
Rem      Create a new database schema/user like an existing database schema/user.
Rem    RETURNS
Rem
Rem    NOTES
Rem      This script must be run while connected as a user with DBA privileges.
Rem      In case of directory users, new users reside in the same directory
Rem      information tree as existing users and database account equals to
Rem      directory account.
Rem      This script does not completely clone user SYS.
Rem      This script has been tested successfully against the following
Rem      Oracle Server version(s):
Rem        - Oracle Server 10g Release 1;
Rem        - Oracle Server 10g Release 2.
Rem    MODIFIED   (MM/DD/YY)
Rem     rwauben    04/03/07 - Creation

set define '%'
set echo off
set feedback off
set heading off
set linesize 160
set pagesize 0
set pause on
set trimspool on
set verify off

clear screen

prompt --------------------------------------------------------------------------------;
prompt Create a new schema/user like an existing schema/user.;
prompt Defaults are shown between brackets [].;
prompt --------------------------------------------------------------------------------;

accept OriginalUser prompt "Enter existing database schema/user [%_USER]: " default %_USER
accept NewUser      prompt "Enter new database schema/user [SCOTT]: " default SCOTT
accept NewPassword  prompt "Enter password for new database schema/user (Leave blank to copy): " hide

prompt ================================================================================;
prompt You entered the following information:
prompt ;

prompt Existing database schema/user     : %OriginalUser
prompt New database schema/user          : %NewUser

prompt ;
prompt If this is correct, press ENTER to generate SQL and PL/SQL statements and
prompt create the new schema/user, otherwise press CTRL+C to cancel and return to the
prompt SQL*Plus prompt.;
prompt ;
prompt Make sure you have DBA privileges before continuing!;
prompt ================================================================================;
pause

undefine v_file_name
column v_file_name new_value v_file_name

undefine v_remove_command
column v_remove_command new_value v_remove_command

set termout off

select to_char(sysdate,'YYYYMMDD_HH24MISS') || '_' || user || '.sql' as v_file_name from dual;

Rem Determine use of either Windows 'del' command or Linux/Unix 'rm' command.
select case when lower(program) like '%.exe' then 'del'
       else 'rm'
       end as v_remove_command
from v$session
where sid = (select distinct sid
from v$mystat);

set termout on

spool %v_file_name


Rem Build CREATE USER statement. --------------------------------------------------

select 'CREATE USER %NewUser ' ||
       case when password = 'EXTERNAL' then 'IDENTIFIED EXTERNALLY'
            when password = 'GLOBAL'   then 'IDENTIFIED GLOBALLY AS ''' ||
              replace (external_name,'%OriginalUser','%NewUser') || ''''
            else 'IDENTIFIED BY ' ||
              decode(upper('%NewPassword'),null,'VALUES ''' || password || '''','%NewPassword') 
       end
       || ' DEFAULT TABLESPACE ' || default_tablespace ||
       ' TEMPORARY TABLESPACE ' || temporary_tablespace ||
       ' PROFILE ' || profile || ' ACCOUNT ' ||
       decode(account_status,'OPEN','UNLOCK',
                             'EXPIRED','UNLOCK PASSWORD EXPIRE',
                             'EXPIRED(GRACE)','UNLOCK',
                             'LOCKED(TIMED)','UNLOCK',
                             'LOCKED','LOCK',
                             'EXPIRED & LOCKED(TIMED)','UNLOCK PASSWORD EXPIRE',
                             'EXPIRED(GRACE) & LOCKED(TIMED)','UNLOCK',
                             'EXPIRED & LOCKED','LOCK PASSWORD EXPIRE',
                             'EXPIRED(GRACE) & LOCKED','LOCK',
                             'LOCK') || ';'
from dba_users
where username = upper('%OriginalUser');

Rem -------------------------------------------------------------------------------


Rem Check tablespace quotas and build ALTER USER statements. ----------------------

select 'ALTER USER %NewUser QUOTA ' ||
       decode(max_bytes,-1,'UNLIMITED',max_bytes) ||
       ' ON ' || tablespace_name || ';'
from sys.dba_ts_quotas
where username = upper('%OriginalUser');

Rem -------------------------------------------------------------------------------


Rem Check SYSDBA and/or SYSOPER privileges and build GRANT statement. -------------

select decode(sysdba, 'TRUE', 'GRANT SYSDBA TO %NewUser;', null) sysdba
from v$pwfile_users
where username = upper('%OriginalUser');

select decode(sysoper, 'TRUE', 'GRANT SYSOPER TO %NewUser;', null) sysoper
from v$pwfile_users
where username = upper('%OriginalUser');

Rem -------------------------------------------------------------------------------


Rem Check system privileges and build GRANT statements. ---------------------------

select 'GRANT ' || privilege || ' TO %NewUser' ||
       decode(admin_option,'YES',' WITH ADMIN OPTION;',';')
from sys.dba_sys_privs
where grantee = upper('%OriginalUser');

Rem -------------------------------------------------------------------------------


Rem Check roles and build GRANT statements. ---------------------------------------

select 'GRANT ' || granted_role || ' TO %NewUser' ||
       decode(admin_option,'YES',' WITH ADMIN OPTION;',';')
from sys.dba_role_privs
where grantee = upper('%OriginalUser');

Rem -------------------------------------------------------------------------------


Rem Check default roles and build ALTER USER ... DEFAULT ROLE ... statement. ------

set serveroutput on

declare
  v_default_roles varchar2(4000) := null;
begin
  for c1 in (select * from sys.dba_role_privs 
             where grantee = upper('%OriginalUser')
             and default_role = 'YES')
  loop
    if length(v_default_roles) > 0 then
      v_default_roles := v_default_roles || ',' || c1.granted_role;
    else
      v_default_roles := v_default_roles || c1.granted_role;
    end if;
  end loop;

  if length(v_default_roles) > 0 then
    dbms_output.put_line('ALTER USER %NewUser DEFAULT ROLE ' || v_default_roles || ';');
  end if;
end;
/

set serveroutput off

Rem -------------------------------------------------------------------------------


Rem Check table and column privileges and build GRANT statements. -----------------

select 'GRANT ' || privilege || ' ON ' || owner || '.' || table_name ||
       ' TO %NewUser' || decode(grantable,'YES',' WITH GRANT OPTION;',';')
from (select usrge.name grantee, usr.name owner, obj.name table_name, null column_name,
      usrgr.name grantor, tabprivmap.name privilege,
      decode(mod(objauth.option$,2), 1, 'YES', 'NO') grantable,
      decode(bitand(objauth.option$,2), 2, 'YES', 'NO') hierarchy,
      decode(obj.type#, 2, 'TABLE', 4, 'VIEW', 6, 'SEQUENCE', 7, 'PROCEDURE',
                        8, 'FUNCTION', 9, 'PACKAGE', 13, 'TYPE', 22, 'LIBRARY',
                        23, 'DIRECTORY', 24, 'QUEUE', 28, 'JAVA SOURCE',
                        29, 'JAVA CLASS', 30, 'JAVA RESOURCE', 32, 'INDEXTYPE',
                        33, 'OPERATOR', 42, 'MATERIALIZED VIEW',
                        'UNDEFINED') object_type
from sys.objauth$ objauth, sys.obj$ obj, sys.user$ usr, sys.user$ usrgr, sys.user$ usrge,
     sys.table_privilege_map tabprivmap
where objauth.obj# = obj.obj#
and objauth.grantor# = usrgr.user#
and objauth.grantee# = usrge.user#
and objauth.col# is null
and objauth.privilege# = tabprivmap.privilege
and usr.user# = obj.owner#
and obj.type# in (2, 4, 6, 7, 8, 9, 13, 22, 24, 28, 29, 30, 32, 33, 42)
and usrge.name = upper('%OriginalUser')
union all
select usrge.name, usr.name, obj.name, col.name, usrgr.name, tabprivmap.name,
       decode(mod(objauth.option$,2), 1, 'YES', 'NO'),
       null hierarhy,
       decode(obj.type#, 2, 'TABLE', 4, 'VIEW', 42, 'MATERIALIZED VIEW')
from sys.objauth$ objauth, sys.obj$ obj, sys.user$ usr, sys.user$ usrgr, sys.user$ usrge,
     sys.col$ col, sys.table_privilege_map tabprivmap
where objauth.obj# = obj.obj#
and objauth.grantor# = usrgr.user#
and objauth.grantee# = usrge.user#
and objauth.obj# = col.obj#
and objauth.col# = col.col#
and objauth.col# is not null
and objauth.privilege# = tabprivmap.privilege
and usr.user# = obj.owner#
and obj.type# in (2, 4, 42)
and bitand(col.property, 32) = 0
and usrge.name = upper('%OriginalUser'));

Rem -------------------------------------------------------------------------------


Rem Check Java privileges and build PL/SQL statements. ----------------------------

set serveroutput on

declare
  i integer := 1;
begin
  for c1 in (select kind, grantee, type_schema, type_name,
             name, action, enabled, seq
             from sys.dba_java_policy
             where grantee = upper('%OriginalUser')
             order by seq)
  loop
    if i = 1 then
      dbms_output.put_line('DECLARE');
      dbms_output.put_line('KEYNUM NUMBER;');
      dbms_output.put_line('BEGIN');
      i := 2;
    end if;

    if c1.kind = 'GRANT' then
      dbms_output.put_line('SYS.DBMS_JAVA.GRANT_PERMISSION(GRANTEE => ''' ||
                                  upper('%NewUser') || ''', PERMISSION_TYPE => ''' ||
                                  c1.type_schema || ':' || c1.type_name ||
                                  ''', PERMISSION_NAME => ''' || c1.name ||
                                  ''', PERMISSION_ACTION => ''' || c1.action ||
                                  ''', KEY => KEYNUM);');
    elsif c1.kind = 'RESTRICT' then
      dbms_output.put_line('SYS.DBMS_JAVA.RESTRICT_PERMISSION(GRANTEE => ''' ||
                                  upper('%NewUser') || ''', PERMISSION_TYPE => ''' ||
                                  c1.type_schema || ':' || c1.type_name ||
                                  ''', PERMISSION_NAME => ''' || c1.name ||
                                  ''', PERMISSION_ACTION => ''' || c1.action ||
                                  ''', KEY => KEYNUM);');
    end if;
  end loop;

  if i = 2 then
    dbms_output.put_line('END;');
    dbms_output.put_line('/');
  end if;
end;
/

set serveroutput off

Rem -------------------------------------------------------------------------------


Rem Check resource group privileges and build PL/SQL statements. ------------------

set serveroutput on

declare
  i integer := 1;
  v_initial_group varchar2(30) := null;
begin
  for c1 in (select grantee,
                    granted_group,
                    decode(grant_option,'YES','TRUE','FALSE') grant_option,
                    initial_group
             from dba_rsrc_consumer_group_privs
             where grantee = upper('%OriginalUser'))
  loop
    if i = 1 then
      dbms_output.put_line('BEGIN');
      dbms_output.put_line('SYS.DBMS_RESOURCE_MANAGER.CLEAR_PENDING_AREA();');
      dbms_output.put_line('SYS.DBMS_RESOURCE_MANAGER.CREATE_PENDING_AREA();');
      i := 2;
    end if;

    dbms_output.put_line('SYS.DBMS_RESOURCE_MANAGER_PRIVS.GRANT_SWITCH_CONSUMER_GROUP(''%NewUser'',''' || c1.granted_group || ''',' || c1.grant_option || ');');

    if c1.initial_group = 'YES' then
      v_initial_group := c1.granted_group;
    end if;
  end loop;

  if i = 2 then
    dbms_output.put_line('SYS.DBMS_RESOURCE_MANAGER.SUBMIT_PENDING_AREA();');
    dbms_output.put_line('END;');
    dbms_output.put_line('/');
  end if;

  if v_initial_group is not null then
    dbms_output.put_line('BEGIN');
    dbms_output.put_line('SYS.DBMS_RESOURCE_MANAGER.SET_INITIAL_CONSUMER_GROUP(''%NewUser'',''' || v_initial_group || ''');');
    dbms_output.put_line('END;');
    dbms_output.put_line('/');
  end if;
end;
/

set serveroutput off

Rem -------------------------------------------------------------------------------


Rem Check proxy authentication and build ALTER USER ... statements. ---------------

set serveroutput on

declare
  v_proxy_roles varchar2(4000);
begin
  for c1 in (select distinct decode(proxy,null,'ENTERPRISE USERS',proxy) proxy,
                    client,
                    decode(authentication,'YES',' AUTHENTICATION REQUIRED') authentication
             from sys.dba_proxies
             where client = upper('%OriginalUser'))
  loop
    v_proxy_roles := null;

    for c2 in (select role
             from sys.dba_proxies
             where nvl(proxy,'ENTERPRISE USERS') = c1.proxy
             and client = c1.client
             and role is not null)
    loop
      if v_proxy_roles is null then
        v_proxy_roles := ' WITH ROLES ' || c2.role;
      else
        v_proxy_roles := v_proxy_roles || ', ' || c2.role;
      end if;
    end loop;

    dbms_output.put_line('ALTER USER %NewUser GRANT CONNECT THROUGH ' || c1.proxy || v_proxy_roles || c1.authentication || ';');
  end loop;
end;
/

set serveroutput off

Rem -------------------------------------------------------------------------------


spool off


prompt --------------------------------------------------------------------------------;
prompt Creating new database schema/user %NewUser like %OriginalUser ...;
prompt Only error messages are displayed.
prompt --------------------------------------------------------------------------------;

@%v_file_name

prompt --------------------------------------------------------------------------------;
prompt Ready.;
prompt --------------------------------------------------------------------------------;

host %v_remove_command %v_file_name       