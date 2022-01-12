#!/bin/ksh

. $HOME/.profile 


/$ORACLE_HOME/bin/rman target rman/rman log=/obiduat1/data05/UAT1/rman_log/rman_`date +%Y%m%d`.log   <<OERMAN

RUN {
allocate channel c1 type disk;
allocate channel c2 type disk;
backup current controlfile;
backup archivelog all delete input;
backup as compressed backupset incremental level 0 database
tag lvl0_base;
crosscheck backup;
crosscheck archivelog all;
delete noprompt obsolete;
release channel c1;
release channel c2; 
}

mailx -s "($ORACLE_SID) Level 0 RMAN Log" andrew.pazikas@velos-it.com </$ORACLE_BASE/data05/UAT1/rman_log/rman_`date +%Y%m%d`.log

exit
EORMAN



