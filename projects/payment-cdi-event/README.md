# JDG WebSession Remote Server Demo
## Disclaimer

This is a fork of the `payment-cdi-event` quickstart project available in the official [JBoss Developer public Git Repository](https://github.com/jboss-developer).
The `payment-cdi-event` quickstart project is a simple webapp that uses CDI and JSF to show some JavaEE 6 capabilities in the JBoss EAP 6.
For more details about its implementation please see the [original project source code repo](https://github.com/jboss-developer/jboss-eap-quickstarts/tree/7.0.x-develop/payment-cdi-event)

## Demo description
In this demo I'll show the new capability available in the *JBoss Data Grid 6.5*: [**Externalize HTTP Session from JBoss**](https://access.redhat.com/documentation/en-US/Red_Hat_JBoss_Data_Grid/6.5/html-single/Administration_and_Configuration_Guide/index.html#chap-Externalize_Sessions)

This capability allow us to externalize the HTTP Web Sessions from the Application Server to a external (remote) Data Grid cluster.
In some scenarios this can alleviate the Application Server memory consumption and improve the *availability* and *failover* of your Web Application User State. There are other great benefit this approach can bring to your setup:
 - Cross data center state replication

The nice thing about this capability offered By JBoss EAP + JDG is that it can be completely transparent for your code.
You don't have to change your code or implement any specific API.
This integration can be enabled just with a couple of configuration in the EAP Caching subsystem.

## Software required for this demo

 * JDK >= 1.7
 * JBoss EAP 6.<last update>
 * JBoss JDG 6.<last update>
 * Apache Maven 3.x

## Environment

 * two JBoss EAP Standlone nodes (`standalone-ha.xml` configuration)
 * two JBoss JDG Clustered nodes (`clustered.xml` configuration)
 * two different Internet browsers
 * Terminal console

## JDG Cluster
### node1

```
./clustered.sh -b 127.0.0.1 -Djboss.node.name=jdg_node1 -Djboss.socket.binding.port-offset=600 -Djgroups.bind_addr=127.0.0.1

 15:14:07,138 INFO  [org.infinispan.server.endpoint] (MSC service thread 1-4) JDGS010001: HotRodServer listening on 127.0.0.1:11822

```

### node2

```
./clustered.sh -b 127.0.0.1 -Djboss.node.name=jdg_node2 -Djboss.socket.binding.port-offset=700 -Djgroups.bind_addr=127.0.0.1

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

---

### Inspecting the Remote JDG clustered cache

Connect to the cluster using the JDG CLI

```
./cli.sh
You are disconnected at the moment. Type 'connect' to connect to the server or 'help' for the list of supported commands.
[disconnected /] connect remoting://localhost:10599
[standalone@localhost:10599 cache-container=clustered] cache default
[standalone@localhost:10599 distributed-cache=default] ls
[standalone@localhost:10599 distributed-cache=default] stats
```

---

## Testing
###TODO

 * open the application in one browser window using the `eap_node1` instance: `http://localhost:8080/payment-cdi-event`
 ![payment-cdi-event web page](docs/payment-cdi-event-node3.png "App web page")


  * create some Payment entries to store some data in the user web session.
  * observe the session and cache info on the right side of the page.
  * kill the `eap_node1` instance.
   * you can use `kill -9 <jvm PID>` in a Linux box

  * access the app using the `eap_node2` instance: `http://localhost:8180/payment-cdi-event`
   * at this point you should see the same entries in the page.
   > NOTE: this is possible because the user session id (`JSESSIONID`) is persisted as a cookie in the browser.

 * now kill the `eap_node2` instance.
 * ok! all your JBoss EAP cluster is down!
 * make sure your sessions are still available in the JDG clustered cache:
  * use the JDG CLI to inspect the cache.
   * use the `stats` command to see the cache live information

 * Now bring the `eap_node1` instance up again.
 * open the app in the browser: `http://localhost:8080/payment-cdi-event`
 * you should see the same data!
