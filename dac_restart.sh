#!/bin/ksh

#########################################################
#  NAME:email_dac_restart.sh                            #
#  AUTHOR: Andrew Pazikas                               #
#  DESC: Makes sure dac is running and restarts if not  #
#  VERSION: 18/1/13                                     #
#  CHANGE LOG:                                          #
#########################################################


. ~/.profile



if ps -ef | grep '/usr/jdk/instances/jdk1.6.0/bin/sparcv9/java -server -Xmn500m -Xms2048m -Xmx204'
then
     echo 'do nothing'
    ## tail -1 $DAC_HOME/nohup.out |  mailx -s 'DAC Running TST1 ' andrew.pazikas@velos-it.com
else
         cd $DAC_HOME
                   nohup $DAC_HOME/startserver.sh &
                   tail -200 $DAC_HOME/nohup.out | mailx -s 'DAC Restarted TST1 ' andrew.pazikas@velos-it.com
fi



exit
EOF
