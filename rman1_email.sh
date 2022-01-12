#!/bin/ksh

###################################
##                               ##
##  Title: Run Rman &  email log ## 
##  Author: Andrew Pazikas       ##
##  Version: 1.0                 ##
##  Date: 14/01/2013             ##
##                               ##
###################################




sh /export/home/obiduat1/paz/lvl1_rman.sh   <<RMANLVL1


##### MAIL RMAN LOG FILE #####

mailx -s "($ORACLE_SID) Level 1 RMAN Log" andrew.pazikas@velos-it.com </$ORACLE_BASE/data05/UAT1/rman_log/rman_`date +%Y%m%d`.log

exit

EOF
