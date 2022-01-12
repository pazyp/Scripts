#!/bin/ksh

###################################
##                               ##
##  Title: RMAN Backup Level 1   ##
##  Author: Andrew Pazikas       ##
##  Version: 2.0                 ##
##  Date: 21/12/2012             ##
##  Updates: 14/01/13            ##
###################################


## Variables used in Script ##
. ~/.profile

###### oracle_sid_upper=`echo ${ORACLE_SID} | tr '[a-z]' '[A-Z]' <<Doesnt work ###


## Script ##

$ORACLE_HOME/bin/rman target rman/rman log=/$ORACLE_BASE/data05/UAT1/rman_log/rman_`date +%Y%m%d`.log   <<OERMAN

RUN {
allocate channel c1 type disk;
allocate channel c2 type disk;
backup archivelog all delete input;
backup as compressed backupset incremental level 1 database
tag lvl1;
delete noprompt obsolete;
backup current controlfile;
release channel c1;
release channel c2;
}

exit

EORMAN

EOF
