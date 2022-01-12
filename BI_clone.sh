########## Clone OBIEE ############
# Move database, Middleware Home and Initial Config

. $INST_HOME/bifoundation/OracleBIApplication/coreapplication/setup/bi-init.sh
export MW_HOME=/obipw01/apps/obiee

$MW_HOME/oracle_common/bin/copyBinary.sh -javaHome $ORACLE_HOME/jdk -archiveLoc /export/ops/ebssupp/velos/obiee_clone/obipw01_bincopy.jar -sourceMWHomeLoc $MW_HOME -invPtrLoc $MW_HOME/Oracle_BI1/oraInst.loc

$MW_HOME/oracle_common/bin/copyConfig.sh -javaHome $ORACLE_HOME/jdk -archiveLoc /export/ops/ebssupp/velos/obiee_clone/obipw01_fmwconfig.jar -sourceDomainLoc $WL_DOMAIN_DIR -sourceMWHomeLoc $MW_HOME -domainHostName v06emzs134 -domainPortNum 7001 -domainAdminUserName weblogic -domainAdminPasswordFile $HOME/pwd.txt -silent true

$MW_HOME/oracle_common/bin/copyConfig.sh -javaHome $ORACLE_HOME/jdk -archiveLoc /export/ops/ebssupp/velos/obiee_clone/obipw01_inst_config.jar -sourceInstanceHomeLoc $ORACLE_INSTANCE

# extract move plans
export ORACLE_COMMON=$MW_HOME/oracle_common
$ORACLE_COMMON/bin/extractMovePlan.sh -javaHome $ORACLE_HOME/jdk -archiveLoc /export/ops/ebssupp/velos/obiee_clone/obipw01_fmwconfig.jar -planDirLoc /export/ops/ebssupp/velos/obiee_clone/obipw01_fmwconfig_plan -logDirLoc /tmp

$ORACLE_COMMON/bin/extractMovePlan.sh -javaHome $ORACLE_HOME/jdk -archiveLoc /export/ops/ebssupp/velos/obiee_clone/obipw01_inst_config.jar -planDirLoc /export/ops/ebssupp/velos/obiee_clone/obipw01_instanceplan -logDirLoc /tmp

#Edit the moves plan  -- changed hostnames, ports, updated password file locations
%s/v06emzs134.edi.emss.gov.uk/v10emzs134/g

#Copy scripts needed for source env
cd /export/ops/ebssupp/velos/obiee_clone/
cp $MW_HOME/oracle_common/jlib/cloningclient.jar .
cp $MW_HOME/oracle_common/bin/pasteBinary.sh .
cp $MW_HOME/oracle_common/bin/pasteConfig.sh .
cp $INST_HOME/bifoundation/OracleBIApplication/coreapplication/setup/bi-init.sh .

tar -zcEvf 14112014.tar.gz 14112014

scp 14112014.tar.gz ebssupp@172.21.129.110:/export/ops/ebssupp/velos/obiee_clone

# Apply to source
#update java
#Does /var/opt/oracle/oraInst.loc have correct locations? Would only be wrong if you have changed mounts.
cd /export/ops/ebssupp/velos/obiee_clone/14112014

export JAVA_HOME=/obipw01/apps/obiee/jdk1.8.0_25/

./pasteBinary.sh -javaHome $JAVA_HOME -archiveLoc /export/ops/ebssupp/velos/obiee_clone/14112014/obipw01_bincopy.jar -targetMWHomeLoc /obipw01/apps/obiee/middleware

#Execute pasteConfig.sh to configure the domain:
# open new shell
# export JAVA_HOME
# export PATH=$JAVA_HOME/bin:$PATH
# Change bi-init.sh to reflect new directory structure at target (if different)
# Comment call to user.sh in bi-init.sh

Source bi-init.sh (. /export/ops/ebssupp/velos/obiee_clone/14112014/bi-init.sh)

#pasteConfig.sh for domain (new moveplan and jar file from prior step)
#TIP: Ensure the move plan is updated to provide the explicit path to the password file for the stated datasource (i.e - DataSource1)

export JAVA_HOME=$ORACLE_HOME/jdk

cd /obipw01/apps/obiee/middleware/oracle_common/bin/

./pasteConfig.sh -javaHome $ORACLE_HOME/jdk -archiveLoc /export/ops/ebssupp/velos/obiee_clone/14112014/obipw01_fmwconfig.jar -targetDomainLoc /obipw01/apps/obiee/middleware/user_projects/domains/bifoundation_domain -targetMWHomeLoc /obipw01/apps/obiee/middleware -movePlanLoc /export/ops/ebssupp/velos/obiee_clone/14112014/obipw01_fmwconfig_plan/moveplan.xml -domainAdminPasswordFile /export/ops/ebssupp/velos/obiee_clone/14112014/pwd.txt -logDirLoc /tmp

mv /obipw01/apps/obiee/middleware/instances/instance1 /obipw01/apps/obiee/middleware/instances/instance_old

cd /obipw01/apps/obiee/middleware/oracle_common/bin/

./pasteConfig.sh -javaHome $ORACLE_HOME/jdk -archiveLoc /export/ops/ebssupp/velos/obiee_clone/14112014/obipw01_inst_config.jar -targetInstanceHomeLoc /obipw01/apps/obiee/middleware/instances/instance1 -targetInstanceName instance1 -targetOracleHomeLoc /obipw01/apps/obiee/middleware/Oracle_BI1 -domainHostName v10emzs133 -domainPortNum 7001 -domainAdminUserName weblogic -domainAdminPasswordFile /export/ops/ebssupp/velos/obiee_clone/14112014/pwd.txt -logDirLoc /tmp -movePlanLoc /export/ops/ebssupp/velos/obiee_clone/14112014/obipw01_instanceplan/moveplan.xml


#Clean up old logs

####### NOTES ########
#INFO : [PLUGIN][BI] Feb 5, 2015 16:07:38 - CLONE-27163   Successfully updated 2 OracleInstance element(s) in biee-domain.xml.
#INFO : [PLUGIN][BI] Unable to get CanonicalHostName for hosts : v06emzs135.edi.emss.gov.uk , v06emzs134.edi.emss.gov.uk
#INFO : [PLUGIN][BI] Unable to get CanonicalHostName for hosts : v06emzs135.edi.emss.gov.uk , v06emzs134.edi.emss.gov.uk
#INFO : [PLUGIN][BI] Failed to get target instance  host name details, post paste config update biee-domain.xml with proper mahcine details.
#
#SEVERE :  The instance home path specifed in domain move plan should be used. Any change requires a rerun of domain config.




2. ##### Patch-Merge the Repository File

3. ##### Configure Security in the New Target Environment

4. ##### Move the Configuration of the Oracle BI Enterprise Edition Components

5. ##### Copy and Scale Out to New Cluster Hosts in the Target Environment

6. ##### Enable New Agents and Oracle BI Publisher Scheduled Jobs

7. ##### Update Links to External Systems

8. ##### (Optional) Move Oracle Business Intelligence Related Applications

