#!/bin/ksh
#
# Author - Andrew Pazikas
# Desc - Cycles the OBIEE log files ever 4hours
# Ver - 1.0
# Change Log:
#           06/08/13 AP Creation
#
#
set -x
. ~/.profile

export LOG_HOME131=/obiaprd1/logs/bilogs131/Weblogic
export LOG_HOME132=/obiaprd1/logs/bilogs132/Weblogic
export BI1_LOG=bi_server1.log
export BI2_LOG=bi_server2.log
DATE=$(date +%d%m%y%H%M)
export DATE

cd $LOG_HOME131
cp $BI1_LOG bi_server1.log_$DATE
>bi_server1.log

cd $LOG_HOME132
cp $BI2_LOG bi_server2.log_$DATE
>bi_server2.log

exit
EOF

