!#/bin/ksh
#
################################################################
#                                                              #
# Author - Andrew Pazikas                                      #
# Ver - 1.0                                                    #
# Desc - Script will resync OBIEE GUIDS and restart services   #
# Change Log :                                                 #
#            31/07/13      AP       Creation                   #
#                                                              #
#                                                              #
#                                                              #
################################################################
#
set -x

. ~/.profile

export BI_SERVER1=v06emzs131
export BI_SERVER2=v06emzs132
export BI_SERVER1_HOME='/obiaprd1/apps/obiee/MWHome/instances/instance'
export BI_SERVER2_HOME='/obiaprd1/apps/obiee/MWHome/instances/instance/instance2'
export EMAIL='andrew.pazikas@velos-it.com'
export DATE='date +%y%m%d'



echo 'Stopping OPMN services on $BI_SERVER1 and $BI_SERVER2 ...'
ssh $BI_SERVER1 '$BI_SERVER1_HOME/bin/opmnctl stopall'
sleep 5
exit
ssh $BI_SERVER2 '$BI_SERVER2_HOME/bin/opmnctl stopall'
sleep 5

echo 'Updating NQSConfig.ini to /tmp ...'
ssh $BI_SERVER1 'cat $BI_SERVER1_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI |sed -e 's/FMW_UPDATE_ROLE_AND_USER_REF_GUIDS = NO;/FMW_UPDATE_ROLE_AND_USER_REF_GUIDS = YES;/' > /tmp/NQSConfig.INI

ssh $BI_SERVER2 'cat $BI_SERVER2_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI |sed -e 's/FMW_UPDATE_ROLE_AND_USER_REF_GUIDS = NO;/FMW_UPDATE_ROLE_AND_USER_REF_GUIDS = YES;/' > /tmp/NQSConfig.INI

echo 'Backing up NQSConfig.ini...'
ssh $BI_SERVER1 'mv $BI_SERVER1_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI $BI_SERVER1_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI_$DATE'

ssh $BI_SERVER2 'mv $BI_SERVER2_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI $BI_SERVER1_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI_$DATE'

ssh $BI_SERVER1 'mv /tmp/NQSConfig.INI $BI_SERVER1_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI

ssh $BI_SERVER2 'mv /tmp/NQSConfig.INI $BI_SERVER2_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI
echo 'NQSConfig.INI Updated!'

echo 'Updating instanceconfig.xml to /tmp...'
ssh $BI_SERVER1 'cat $BI_SERVER1_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml |sed -e 's/<\/UpgradeAndExit>/<\/UpgradeAndExit>\n         UpdateAndExit<\/UpdateAccountGUIDs>/' > /tmp/instanceconfig.xml'

ssh $BI_SERVER2 'cat $BI_SERVER2_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml |sed -e 's/<\/UpgradeAndExit>/<\/UpgradeAndExit>\n         UpdateAndExit<\/UpdateAccountGUIDs>/' > /tmp/instanceconfig.xml'

echo 'Backing up insatnceconfig.xml...'
ssh $BI_SERVER1 'mv $BI_SERVER1_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml $BI_SERVER1_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml_$DATE'

ssh $BI_SERVER2 'mv $BI_SERVER2_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml $BI_SERVER2_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml_$DATE'

ssh $BI_SERVER1 'mv /tmp/instanceconfig.xml $BI_SERVER1_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml'

ssh $BI_SERVER2 'mv /tmp/instanceconfig.xml $BI_SERVER2_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml'
echo 'instanceconfig.xml Updated!'

echo 'Starting OPMN Services...'
ssh $BI_SERVER1 '$BI_SERVER1_HOME/bin/opmnctl startall'
sleep 20
ssh $BI_SERVER1 '$BI_SERVER1_HOME/bin/opmnctl startproc ias-component=coreapplication_obips1'
sleep 20

ssh $BI_SERVER2 '$BI_SERVER2_HOME/bin/opmnctl startall'
sleep 20
ssh $BI_SERVER2 '$BI_SERVER2_HOME/bin/opmnctl startproc ias-component=coreapplication_obips1'
sleep 20

echo 'Reverting changes to NQSConfig.ini...'
ssh $BI_SERVER1 'rm $BI_SERVER1_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI'

ssh $BI_SERVER1 'mv $BI_SERVER1_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI_$DATE $BI_SERVER1_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI'

ssh $BI_SERVER2 'rm $BI_SERVER2_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI'

ssh $BI_SERVER2 'mv $BI_SERVER2_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI_$DATE $BI_SERVER1_HOME/config/OracleBIServerComponent/coreapplication_obis1/NQSConfig.INI'
echo 'NQSConfig.INI changes reverted!'

echo 'Reverting changes to instanceconfig.xml...'
ssh $BI_SERVER1 'rm $BI_SERVER1_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml'
ssh $BI_SERVER1 'mv $BI_SERVER1_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml_$DATE $BI_SERVER1_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml'

ssh $BI_SERVER2 'rm $BI_SERVER2_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml'
ssh $BI_SERVER2 'mv $BI_SERVER2_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml_$DATE $BI_SERVER2_HOME/config/OracleBIPresentationServicesComponent/coreapplication_obips1/instanceconfig.xml'
echo 'instanceconfig.xml changes reverted!'

echo 'Restarting OPMN Services...'
ssh $BI_SERVER1 '$BI_SERVER1_HOME/bin/opmnctl stopall'
ssh $BI_SERVER2 '$BI_SERVER2_HOME/bin/opmnctl stopall'
ssh $BI_SERVER1 '$BI_SERVER1_HOME/bin/opmnctl startall'
sleep 20
ssh $BI_SERVER1 '$BI_SERVER1_HOME/bin/opmnctl startproc ias-component=coreapplication_obips1'
sleep 20
ssh $BI_SERVER2 '$BI_SERVER2_HOME/bin/opmnctl startall'
sleep 20
ssh $BI_SERVER2 '$BI_SERVER2_HOME/bin/opmnctl startproc ias-component=coreapplication_obips1'
sleep 20
echo 'Resync of User GUIDs was sucessfull!'

echo -e "`date +[%H:%M:%S]` ## Resync of User GUIDs was sucessfull." >obi_temp.tmp
ssh $BI_SERVER1 '$BI_SERVER1_HOME/bin/opmnctl status' >>obi_temp.tmp
ssh $BI_SERVER2 '$BI_SERVER2_HOME/bin/opmnctl status' >>obi_temp.tmp

mailx -s 'Refresh of OBIEE GUID's complete' $EMAIL <obi_temp.tmp

rm obi_temp.tmp

exit
end
EOF
