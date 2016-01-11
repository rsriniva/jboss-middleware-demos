#!/bin/sh

EAP_HOME="./target/jboss-eap-6.4"
JDG_HOME="./target/jboss-datagrid-6.5.1-server"
STARTUP_WAIT=6


function waitForStartup(){
  node_name=$1

  echo -e "\n\t wait for $node_name startup"
  count=0
  launched=false

  until [ $count -gt $STARTUP_WAIT ]
  do
    #grep 'JBAS015874:' ${node_name}.log > /dev/null
    log_entry=`grep 'JBAS015874:' ${node_name}.log`
    if [ $? -eq 0 ] ; then
      launched=true
      break
    fi
    echo -e "\t\t waiting 5s..."
    sleep 5
    let count=$count+1;
  done

  if [ "$launched" = "false" ] ; then
    echo "$node_name failed to startup in the time allotted"
    echo
    return 7
  fi
  
  echo -e "\n\t >> $log_entry"
}

function startJDGNode(){
   node_name=$1
   ports_offset=$2
   
   echo -e "\n\n---"
   echo -e "\tstarting >>> ${node_name} <<<"
   $JDG_HOME/bin/clustered.sh \
    -b 127.0.0.1 \
    -Djboss.node.name=$node_name \
    -Djava.net.preferIPv4Stack=true \
    -Djboss.socket.binding.port-offset=$ports_offset \
    -Djgroups.bind_addr=127.0.0.1 &> ./${node_name}.log&

   waitForStartup $node_name
   [[ $? != 0 ]] && echo -e "\t can't start ${node_name}. Please chech the ./$node_name.log file" && exit 1

   JVM_PID=$(ps -eo pid,command | grep "org.jboss.as.standalone" | grep "jboss.node.name=$node_name" | grep -v grep | awk '{print $1}')
   jdg_hotrod_port=$(bc -l <<< "11222 + $ports_offset")
   
   echo -e "\n\t $node_name is UP and RUNNING! JVM PID: $JVM_PID"
   echo -e "\t $node_name JVM PID: $JVM_PID" >> startup_summary
   echo -e "\t\t $node_name Hot Rod Service listening on port: $jdg_hotrod_port" >> startup_summary
   echo -e "---"
}

function startEAPNode(){
   node_name=$1
   ports_offset=$2
   
   echo -e "\n\n---"
   echo -e "\tstarting >>> ${node_name} <<<"

  $EAP_HOME/bin/standalone.sh \
  -b 127.0.0.1 -c standalone-ha.xml \
  -Djboss.server.base.dir=$EAP_HOME/$node_name \
  -Djboss.node.name=$node_name \
  -Djboss.socket.binding.port-offset=$ports_offset \
  -Djava.net.preferIPv4Stack=true \
  -Djgroups.bind_addr=127.0.0.1 \
  -Djdg.remoting.hothod.node1.addr=127.0.0.1 \
  -Djdg.remoting.hothod.node1.port=11822 \
  -Djdg.remoting.hothod.node2.addr=127.0.0.1 \
  -Djdg.remoting.hothod.node2.port=11922 &> ./${node_name}.log&

   waitForStartup $node_name
   [[ $? != 0 ]] && echo -e "\t can't start ${node_name}. Please chech the ./$node_name.log file" && exit 1

   JVM_PID=$(ps -eo pid,command | grep "org.jboss.as.standalone" | grep "jboss.node.name=$node_name" | grep -v grep | awk '{print $1}')
   eap_http_port=$(bc -l <<< "8080 + $ports_offset")
   
   echo -e "\n\t $node_name is UP and RUNNING! JVM PID: $JVM_PID"
   echo -e "\t $node_name JVM PID: $JVM_PID" >> startup_summary
   echo -e "\t\t $node_name Web Server listening on port: $eap_http_port " >> startup_summary
   echo -e "---"
}

function summary(){
  echo -e "\n\n---"
  echo -e "Summary\n"
  cat startup_summary
  echo -e "---"
  echo -e "\n Cluster nodes startup Finished!!!"
  echo -e "\t You can now access the webapp to test your cluster!"
  echo -e "\t\t Login to http://localhost:8080/jboss-payment-cdi-event \n\n\n"
}

function usage(){
  echo "Usage: $0 {all|eap_node<n> <port_offset>}"
  exit 1
}

case "$1" in
  all)
      clear
      > startup_summary

      startJDGNode jdg_node1 600
      startJDGNode jdg_node2 700
      echo -e "\n ====== \n" >> startup_summary
      startEAPNode eap_node1 0
      startEAPNode eap_node2 100

      summary
      ;;
  eap_node[1-9])
      [[ -z $2 ]] && usage
      startEAPNode $1 $2
      
      summary
      ;;
  jdg_node*)
      [[ -z $2 ]] && usage
      startJDGNode $1 $2

      summary
      ;;
  *)
      ## If no parameters are given, print which are avaiable.
      usage
      ;;
esac



