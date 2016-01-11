#!/bin/sh 
DEMO="EAP + JDG for Http Session Offload"
AUTHORS="Rafael T. C. Soares"
PROJECT="git@github.com:rafaeltuelho/eap-jdg-httpsession-offload-demo.git"
PRODUCT="JBoss EAP and JDG"

TARGET_DIR=./target

JBOSS_HOME=$TARGET_DIR/jboss-eap-6.4
EAP_BASE_SERVER_DIR=$JBOSS_HOME/standalone
JDG_HOME=$TARGET_DIR/jboss-datagrid-6.5.1-server

SRC_DIR=./installs
SUPPORT_DIR=./support
PRJ_DIR=./projects/payment-cdi-event/

EAP=jboss-eap-6.4.0-installer.jar
JDG=jboss-datagrid-6.5.1-server.zip
VERSION="EAP 6.4 and JDG 6.5.1"

# wipe screen.
clear 

echo
echo "#################################################################"
echo "##                                                             ##"   
echo "##  Setting up the ${DEMO}          ##"
echo "##                                                             ##"   
echo "##                                                             ##"   
echo "##                                                             ##"
echo "## #######    #    ######                    # ######   #####  ##"
echo "## #         # #   #     #      #            # #     # #     # ##"
echo "## #        #   #  #     #      #            # #     # #       ##"
echo "## #####   #     # ######     #####          # #     # #  #### ##"
echo "## #       ####### #            #      #     # #     # #     # ##"
echo "## #       #     # #            #      #     # #     # #     # ##"
echo "## ####### #     # #                    #####  ######   #####  ##"
echo "##                                                             ##"
echo "##                                                             ##"   
echo "##  brought to you by,                                         ##"   
echo "##             ${AUTHORS}                             ##"
echo "##                                                             ##"   
echo "##  ${PROJECT} ##"
echo "##                                                             ##"   
echo "#################################################################"
echo

command -v mvn -q >/dev/null 2>&1 || { echo >&2 "Maven is required but not installed or not present in thet system PATH yet... aborting."; exit 1; }

# make some checks first before proceeding.	
if [ -r $SRC_DIR/$EAP ] || [ -L $SRC_DIR/$EAP ]; then
	echo EAP installer is present...
	echo
else
	echo Need to download $EAP package from the Customer Portal 
	echo and place it in the $SRC_DIR directory to proceed...
	echo
	exit
fi

if [ -r $SRC_DIR/$JDG ] || [ -L $SRC_DIR/$JDG ]; then
		echo JDG installer is present...
		echo
else
		echo Need to download $JDG installer from the Customer Portal 
		echo and place it in the $SRC_DIR directory to proceed...
		echo
		exit
fi

# Remove the old JBoss instance, if it exists.
if [ -x $TARGET_DIR/. ]; then
	echo "  - removing existing demo installation..."
	echo
	rm -rf $TARGET_DIR/*
fi

#read

# Run installers.
echo "JBoss EAP installer running now..."
echo
java -jar $SRC_DIR/$EAP $SUPPORT_DIR/installation-eap -variablefile $SUPPORT_DIR/installation-eap.variables

if [ $? -ne 0 ]; then
	echo
	echo Error occurred during JBoss EAP installation!
	exit
fi

echo
echo "JBoss JDG installer running now..."
echo
unzip -q $SRC_DIR/$JDG -d $TARGET_DIR/

if [ $? -ne 0 ]; then
	echo Error occurred during $PRODUCT installation
	exit
fi

#echo
#echo "JBoss JDG patch ($PATCH) installation now..."
#echo
#unzip $SRC_DIR/$PATCH -d ./target
#cd $PATCH_DIR
#./apply-updates.sh ../jboss-eap-6.4 eap6.x
#cd ../..
#rm -rf $PATCH_DIR

# Add execute permissions to the standalone.sh script.
echo "  - making sure all server scripts are executable..."
echo
chmod u+x $JBOSS_HOME/bin/*.sh
chmod u+x $JDG_HOME/bin/*.sh

echo Cloning the EAP standlone server base into eap_node1 and eap_node2
cp -r $EAP_BASE_SERVER_DIR $JBOSS_HOME/eap_node1
cp -r $EAP_BASE_SERVER_DIR $JBOSS_HOME/eap_node2

echo "  - EAP: setting up standalone-ha.xml configuration adjustments..."
echo
cp $SUPPORT_DIR/standalone-ha.xml $JBOSS_HOME/eap_node1/configuration/ 
cp $SUPPORT_DIR/standalone-ha.xml $JBOSS_HOME/eap_node2/configuration/

echo
echo Building the Payment CDI Event web application. 
echo
cd $PRJ_DIR
mvn clean install

echo
echo Deploying the Payment CDI Event web application. 
echo
cp target/jboss-payment-cdi-event.war ../../$JBOSS_HOME/eap_node1/deployments/jboss-payment-cdi-event.war
touch ../../$JBOSS_HOME/eap_node1/deployments/jboss-payment-cdi-event.war.dodeploy
cp target/jboss-payment-cdi-event.war ../../$JBOSS_HOME/eap_node2/deployments/jboss-payment-cdi-event.war
touch ../../$JBOSS_HOME/eap_node2/deployments/jboss-payment-cdi-event.war.dodeploy
cd ../..

echo -e "\n Now you need to start the cluster."
echo -e "\t Use the script ./startServers.sh all"
echo

echo "$PRODUCT $VERSION $DEMO Setup Complete."
echo

