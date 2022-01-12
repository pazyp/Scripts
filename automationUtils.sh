#!/bin/ksh
#set -x
#
# Author - Andrew Pazikas
# Date - 10-07-13
# Desc - Originaly a Windows tool automationUtils.bat converted to run as a shell script Linux
#
. ./dac_env.sh

JAVA_HOME=/usr/jdk/instances/jdk1.6.0;export JAVA_HOME;
JAVA=${JAVA_HOME}/bin/sparcv9/java;export JAVA

export SQLSERVERLIB=./lib/msbase.jar:./lib/mssqlserver.jar:./lib/msutil.jar:./lib/sqljdbc.jar
export ORACLELIB=./lib/ojdbc6.jar:./lib/ojdbc5.jar:./lib/ojdbc14.jar
export DB2LIB=./lib/db2java.zip
export TERADATALIB=./lib/teradata.jar:./lib/terajdbc4.jar:./lib/log4j.jar:./lib/tdgssjava.jar:./lib/tdgssconfig.jar:./lib
#export SQLSERVERLIB ; export ORACLELIB ; export DB2LIB ; export TERADATALIB

export DBLIBS=${SQLSERVERLIB}:${ORACLELIB}:${DB2LIB}:${TERADATALIB}
export DACLIB=./DAWSystem.jar:.:
export DACCLASSPATH=${DBLIBS}:${DACLIB}
#export DBLIBS ; export DACLIB ; export DACCLASSPATH;


$JAVA -Xmx1024m -cp $DACCLASSPATH com.siebel.etl.functional.AutomationUtils "$1" "$2" "$3"

