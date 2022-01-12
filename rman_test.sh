#!/bin/ksh

################Test RMAN Script###############



$ORACLE_HOME/bin/rman target rman/rman log=/$ORACLE_BASE/data05/UAT1/rman_log/rman_`date +%Y%m%d`.log <<EOR

RUN {
show all;
}
exit


EOF
