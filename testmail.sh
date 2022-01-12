#!/bin/ksh

oracle_sid_lower=`echo ${ORACLE_SID} | tr '[A-Z]' '[a-z]'`
oracle_sid_upper=`echo ${ORACLE_SID} | tr '[a-z]' '[A-Z]'`

cd /obid${oracle_sid_lower}/data05/${oracle_sid_upper}/rman_log/

