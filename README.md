# Java JMX with Docker

The purpose of this project is to present the configuration settings required to expose a JMX port from a JVM running inside a Docker container.

Docker requires ports to be declared before the application runs.  This conflicts with JMX over RMI (the default JMX protocol), which relies on establishing communication using random ports negotiated at connection time.  The randomly negotiated JMX ports can't be declared in the Docker config, causing JMX connections to fail.

If connecting from another container linked to the JVM container (same Docker network) then all ports will be accessible, including the randomly negotiated ones.  However, the typical use case for JMX monitoring is to connect from outside the docker network (via mapping to a host port).

We get around these limitations with careful configuration of the JMX properties.  The main tricks:
* set `com.sun.management.jmxremote.port` and `com.sun.management.jmxremote.rmi.port` to the exposed port, in our case `9010`, and
* set `com.sun.management.jmxremote.host` and `java.rmi.server.hostname` to the [catch-all IP address](https://en.wikipedia.org/wiki/0.0.0.0) `0.0.0.0`.

TL;DR -- [entrypoint.sh](https://github.com/cstroe/java-jmx-in-docker-sample-app/blob/master/bin/entrypoint.sh)

## Usage

    ./mvnw package
    docker-compose up --build

[Docker Compose](https://docs.docker.com/compose/install/) will start the application and expose port 9010 as a JMX port on the docker host.

Using [jconsole](doc/jconsole.md) or [VisualVM](https://visualvm.github.io/), you can connect to `localhost:9010`.

## Notes

The goal of this configuration is to connect with a JMX/RMI client
from outside of the Docker internal network, usually via a port
mapped to a host port. 

The RMI transport is included with the JVM, and therefore is supported
by all the JMX clients (JConsole, VisualVM, etc).

Here are some considerations when setting the JVM arguments:

1. `com.sun.management.jmxremote.port` and `com.sun.management.jmxremote.rmi.port`

   These properties are set to the same value for convenience.
   They don't have to be the same, but you have to expose one
   extra port if they're not equal.

   If you _don't_ declare the RMI port, the RMI protocol will choose
   a ***random port*** at connection time after the initial handshake.
   This will cause the JMX client to hang as the port will not
   be externally accessible.

2. `com.sun.management.jmxremote.host`

   This property is required if `java.rmi.server.hostname` is not set
   and represents the externally accessible hostname or IP of the
   JVM, used as part of the JmxConnectorUrl. If ConnectorBootstrap
   logging is enabled, the URL will be printed at JVM startup:

   > CONFIG: JMX Connector ready at: service:jmx:rmi:///jndi/rmi://172.18.0.2:9010/jmxrmi

   When running in Docker this hostname or IP should be
   externally accessible. The value is usually passed into
   the container through an environment variable, as Docker
   provides no mechanism for looking up the Docker host's
   hostname or IP.

   If neither this property nor `java.rmi.server.hostname` are set, you
   will get this error at JVM startup:

   > Error: Exception thrown by the agent : java.net.MalformedURLException: Cannot give port number without host name

   In our case, we set the host to `0.0.0.0` for the JVM to listen on any available interface.

3. `java.util.logging.config.file`

   The optional path to a [logging.properties](bin/logging.properties) file
   that configures the Java Logging framework to print RMI debugging messages.

   Example logging output:

   > Mar 23, 2017 8:56:26 AM ConnectorBootstrap startRemoteConnectorServer
   > FINEST: Starting JMX Connector Server:
   > 	com.sun.management.jmxremote.port=9010
   > 	com.sun.management.jmxremote.host=0.0.0.0
   > 	com.sun.management.jmxremote.rmi.port=9010
   > 	com.sun.management.jmxremote.ssl=false
   > 	com.sun.management.jmxremote.registry.ssl=false
   > 	com.sun.management.jmxremote.ssl.config.file=null
   > 	com.sun.management.jmxremote.ssl.enabled.cipher.suites=null
   > 	com.sun.management.jmxremote.ssl.enabled.protocols=null
   > 	com.sun.management.jmxremote.ssl.need.client.auth=false
   > 	com.sun.management.jmxremote.authenticate=false
   > 	No Authentication
   > Mar 23, 2017 8:56:26 AM ConnectorBootstrap startRemoteConnectorServer
   > CONFIG: JMX Connector ready at: service:jmx:rmi:///jndi/rmi://0.0.0.0:9010/jmxrmi
   
   JMX logging configuration happens early in the JVM startup and
   uses the Java Logging framework.  This logging is useful for debugging purposes.

4. `com.sun.management.config.file`

   This optional configuration option points to a file that
   is read in by ConnectorBootstrap at startup time
   to set `com.sun.management.jmxremote.*` properties.
   However, since no environment variable substitution is done
   any properties that must be set via environment variables
   cannot be specified in that file, and must be passed from this
   shell script (see below).
   
   The properties in the [management.properties](bin/management.properties)
   file can be passed directly to the JVM as command line arguments.
   See [entrypoint.sh](bin/entrypoint.sh).

5. `java.rmi.server.hostname`

   This is a critical property when using JMX with a JVM running 
   inside a Docker container.  It should be set to
   the externally accessible hostname or IP of the Docker container,
   same as `com.sun.management.jmxremote.host`.

   ***If this property is incorrect (or not set) all JMX connections will fail!***

   In our case, we use the catch-all IP `0.0.0.0` to have the JVM
   listen on any available address.  This avoids us having to specify
   the host IP of the Docker machine, and requires no further special
   configuration.

## Links

### GitHub

* [oracle/docker-images](https://github.com/oracle/docker-images/tree/master/OracleCoherence/docs/5.monitoring) - Very informative, talks about JMXMP too.
* [nolexa/docker-jmx-demo](https://github.com/nolexa/docker-jmx-demo) - Explains the same thing as this repository.
* [gimerstedt/jmx-to-spring-boot-in-docker](https://github.com/gimerstedt/jmx-to-spring-boot-in-docker) - Spring Boot centric
* [zacker330/Java-JMX-example](https://github.com/zacker330/Java-JMX-example) - adds simple authentication, Jolokia agent
* [jolokia/jolokia](https://github.com/jolokia/jolokia) - a JVM agent that uses JSON over HTTP, instead of RMI, has other [features](https://jolokia.org/features-nb.html)
* [prometheus/jmx\_exporter](https://github.com/prometheus/jmx_exporter) - a JVM agent that exposes JMX metrics for [Prometheus](https://github.com/prometheus/prometheus)

### Blog Posts

* [JMX Ports (Baeldung)](https://www.baeldung.com/jmx-ports) - for local apps not Docker, also describes `-XX:+DisableAttachMechanism` and `com.sun.management.jmxremote`
* [Remote Java Debugging With Docker](https://ptmccarthy.github.io/2014/07/24/remote-jmx-with-docker/)
* [Monitoring Java Applications Running Inside Docker Containers](http://www.jamasoftware.com/blog/monitoring-java-applications/)
* [Monitoring JVM apps in a Docker environment](http://mintbeans.com/jvm-monitoring-docker/)
* [JMX Monitoring with Docker and the ELK Stack](https://www.ivankrizsan.se/2015/09/27/jmx-monitoring-with-the-elk-stack/)
* [How to connect VisualVM to Docker](http://www.ethanjoachimeldridge.info/tech-blog/connect-visualvm-docker)
* [JMX: RMI vs. JMXMP](https://meteatamel.wordpress.com/2012/02/13/jmx-rmi-vs-jmxmp/) - Outdated, but talks about why JMXMP fits better with Docker

### Forums

* https://forums.docker.com/t/enable-jmx-rmi-access-to-a-docker-container/625/5

### StackOverflow

* [Why Java opens 3 ports when JMX is configured?](https://stackoverflow.com/questions/20884353/why-java-opens-3-ports-when-jmx-is-configured)
* [How to activate JMX on my JVM for access with jconsole?](http://stackoverflow.com/questions/856881/how-to-activate-jmx-on-my-jvm-for-access-with-jconsole)
* [How to access JMX interface in docker from outside?](http://stackoverflow.com/questions/31257968/how-to-access-jmx-interface-in-docker-from-outside)
* [Access through jmx to java application into Docker container on remote host in local network](http://serverfault.com/questions/789976/access-through-jmx-to-java-application-into-docker-container-on-remote-host-in-l) - Very concise explanation of using JMXMP
* [multiple app nodes how to expose jmx in kubernetes?](https://stackoverflow.com/questions/35184558/multiple-app-nodes-how-to-expose-jmx-in-kubernetes/39927197#39927197)
* [Profiling Java application in kubernetes](https://stackoverflow.com/questions/41720185/profiling-java-application-in-kubernetes?noredirect=1&lq=1)
* [JConsole over ssh local port forwarding](https://stackoverflow.com/questions/15093376/jconsole-over-ssh-local-port-forwarding)
* [How to use VisualVM and JMX?](https://stackoverflow.com/questions/30104142/how-to-use-visualvm-and-jmx)

### YouTube

* [Using JMX to monitor an Application Server running on Docker](https://www.youtube.com/watch?v=tVL3hkA149o) - This video sets `java.rmi.server.hostname` to the Docker host IP address, which is not what we recommend in this repo.  It's also using some specific Dell JMX web interface.  Consider removing this link.

### Other documentation

* [confluent](http://docs.confluent.io/3.0.1/cp-docker-images/docs/operations/monitoring.html#using-jmx)
* [Oracle Guide](https://docs.oracle.com/javase/8/docs/technotes/guides/management/agent.html)
