## JDG Cluster
### node1

```
./clustered.sh -b 127.0.0.1 \
 -Djboss.node.name=jdg_node1 \
 -Djboss.socket.binding.port-offset=600 \
 -Djgroups.bind_addr=127.0.0.1

 15:14:07,138 INFO  [org.infinispan.server.endpoint] (MSC service thread 1-4) JDGS010001: HotRodServer listening on 127.0.0.1:11822

```

### node2

```
./clustered.sh -b 127.0.0.1 \
 -Djboss.node.name=jdg_node2 \
 -Djboss.socket.binding.port-offset=700 \
 -Djgroups.bind_addr=127.0.0.1

15:14:07,138 INFO  [org.infinispan.server.endpoint] (MSC service thread 1-4) JDGS010001: HotRodServer listening on 127.0.0.1:11922

```

> NOTE: on node1 console log you should see this entry:

```
15:28:23,510 INFO  [org.infinispan.remoting.transport.jgroups.JGroupsTransport] (Incoming-2,shared=udp) ISPN000094: Received new cluster view: [node1/clustered|1] (2) [node1/clustered, node2/clustered]
```

---

## EAP cluster
### standalone node1

Profile Configuration: `standalone-ha.xml`

Infinispan Subsystem configuration:
```

<!-- External web container  -->
<cache-container name="remote-webcache-container" aliases="remote-session-cache" default-cache="remote-repl-cache" module="org.jboss.as.clustering.web.infinispan" statistics-enabled="true">
    <transport lock-timeout="60000"/>
    <replicated-cache name="remote-repl-cache" mode="SYNC" batching="true">
        <remote-store cache="default" socket-timeout="60000" preload="true" passivation="false" purge="false" shared="true">
            <remote-server outbound-socket-binding="remote-jdg-node1"/>
            <remote-server outbound-socket-binding="remote-jdg-node2"/>
        </remote-store>
    </replicated-cache>
</cache-container>

```

Socket bindings configuration:
```
<socket-binding-group name="standard-sockets" default-interface="public" port-offset="${jboss.socket.binding.port-offset:0}">
...

  <!-- JDG remote cluster  -->
  <outbound-socket-binding name="remote-jdg-node1">
      <remote-destination host="${jdg.remoting.hothod.node1.addr:127.0.0.1}" port="${jdg.remoting.hothod.node1.port:11222}"/>
  </outbound-socket-binding>
  <outbound-socket-binding name="remote-jdg-node2">
      <remote-destination host="${jdg.remoting.hothod.node2.addr:127.0.0.1}" port="${jdg.remoting.hothod.node2.port:11222}"/>
  </outbound-socket-binding>

</socket-binding-group>
```

The above configuration instruct the JBoss EAP to automatically store the user's `Http Session` in the remote **JDG Clustered InMemory DataGrid**

Copy the `node1` server base dir

```
cp -r node1 node2
```

Start EAP nodes

```
./standalone.sh -b 127.0.0.1 -c standalone-ha.xml \
 -Djboss.server.base.dir=/home/rsoares/opt/EAP/jboss-eap-6.4/node1 \
 -Djboss.node.name=eap_node1 \
 -Djboss.socket.binding.port-offset=0 \
 -Djdg.remoting.hothod.node1.addr=127.0.0.1 \
 -Djdg.remoting.hothod.node1.port=11822 \
 -Djdg.remoting.hothod.node2.addr=127.0.0.1 \
 -Djdg.remoting.hothod.node3.port=11922

 ./standalone.sh -b 127.0.0.1 -c standalone-ha.xml \
  -Djboss.server.base.dir=/home/rsoares/opt/EAP/jboss-eap-6.4/node2 \
  -Djboss.node.name=eap_node2 \
  -Djboss.socket.binding.port-offset=100 \
  -Djdg.remoting.hothod.node1.addr=127.0.0.1 \
  -Djdg.remoting.hothod.node1.port=11822 \
  -Djdg.remoting.hothod.node2.addr=127.0.0.1 \
  -Djdg.remoting.hothod.node3.port=11922
```

##Deploy the web app project

> NOTE: make sure the `<distributable/>` flag is enabled in your `web.xml` descriptor.

```
cd payment-cdi-event/
```

deploy on eap_node1
```
mvn jboss-as:deploy -Djboss-as.port=9999
```

at this point you should see something like that in the eap_node1 console log output:
> NOTE: showing bellow only the important log entries...

```
16:57:20,825 INFO  [org.jboss.as.server.deployment] (MSC service thread 1-7) JBAS015876: Starting deployment of "jboss-payment-cdi-event.war" (runtime-name: "jboss-payment-cdi-event.war")
...

16:57:22,113 INFO  [org.infinispan.remoting.transport.jgroups.JGroupsTransport] (ServerService Thread Pool -- 25) ISPN000078: Starting JGroups Channel
...

16:57:22,215 INFO  [stdout] (ServerService Thread Pool -- 26) -------------------------------------------------------------------
16:57:22,216 INFO  [stdout] (ServerService Thread Pool -- 26) GMS: address=eap_node1/remote-webcache-container, cluster=remote-webcache-container, physical address=127.0.0.1:55200
16:57:22,216 INFO  [stdout] (ServerService Thread Pool -- 26) -------------------------------------------------------------------
...

16:57:24,279 INFO  [org.infinispan.remoting.transport.jgroups.JGroupsTransport] (ServerService Thread Pool -- 26) ISPN000094: Received new cluster view: [eap_node1/remote-webcache-container|0] [eap_node1/remote-webcache-container]
16:57:24,280 INFO  [org.infinispan.remoting.transport.jgroups.JGroupsTransport] (ServerService Thread Pool -- 26) ISPN000079: Cache local address is eap_node1/remote-webcache-container, physical addresses are [127.0.0.1:55200]
16:57:24,289 INFO  [org.jboss.as.clustering] (MSC service thread 1-5) JBAS010238: Number of cluster members: 1
...
16:57:24,439 INFO  [org.infinispan.client.hotrod.RemoteCacheManager] (ServerService Thread Pool -- 24) ISPN004021: Infinispan version: Infinispan 'Delirium' 5.2.11.Final
16:57:24,592 INFO  [org.infinispan.client.hotrod.impl.protocol.Codec12] (ServerService Thread Pool -- 24) ISPN004006: /127.0.0.1:11822 sent new topology view (id=2) containing 2 addresses: [/127.0.0.1:11822, /127.0.0.1:11922]
16:57:24,593 INFO  [org.infinispan.client.hotrod.impl.transport.tcp.TcpTransportFactory] (ServerService Thread Pool -- 24) ISPN004014: New server added(/127.0.0.1:11922), adding to the pool.
```

deploy on eap_node2
```
mvn jboss-as:deploy -Djboss-as.port=10099
```

at this point you should see something like that in the eap_node1 console log output:

```
17:10:05,076 INFO  [org.jboss.as.clustering] (Incoming-11,shared=udp) JBAS010225: New cluster view for partition remote-webcache-container (id: 1, delta: 1, merge: false) : [eap_node1/remote-webcache-container, eap_node2/remote-webcache-container]
17:10:05,077 INFO  [org.infinispan.remoting.transport.jgroups.JGroupsTransport] (Incoming-11,shared=udp) ISPN000094: Received new cluster view: [eap_node1/remote-webcache-container|1] [eap_node1/remote-webcache-container, eap_node2/remote-webcache-container]

```

and on eap_node2 log output you should see entries similar to eap_node1:

```

17:10:05,472 INFO  [org.infinispan.client.hotrod.impl.protocol.Codec12] (ServerService Thread Pool -- 61) ISPN004006: /127.0.0.1:11922 sent new topology view (id=2) containing 2 addresses: [/127.0.0.1:11822, /127.0.0.1:11922]
17:10:05,473 INFO  [org.infinispan.client.hotrod.impl.transport.tcp.TcpTransportFactory] (ServerService Thread Pool -- 61) ISPN004014: New server added(/127.0.0.1:11822), adding to the pool.

```
