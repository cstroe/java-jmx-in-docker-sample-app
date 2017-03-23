# Java JMX with Docker

The purpose of this project is to present the configuration settings required to expose a JMX port from a JVM running inside a Docker container.

Docker requires ports to be declared before the application runs.  This conflicts with JMX over RMI (the default JMX protocol), which relies on establishing communication using random ports negotiated at connection time.  As these random ports won't be declared in the Docker config, JMX connections will fail because Docker won't dynamically open them.

If connecting from another container linked to the JVM container then careful selection of the JVM settings is not required as all ports will be accessible, including the randomly negotiated ones.

## Usage

    ./mvnw package
    docker-compose up --build

This will start the application and expose port 9010 as a JMX port on the docker host.

Using [jconsole](http://openjdk.java.net/tools/svc/jconsole/) or [VisualVM](https://visualvm.github.io/), you can connect to `localhost:9010`.

***Important:*** For Docker for Mac or Docker Machine users, you must set the `HOST` environment variable in `docker-compose.yml` to your Docker host IP, and use that host in the JMX client.

## Notes

The goal of this configuration is to connect with a JMX/RMI client
from outside of the Docker internal network.  

The RMI transport is included with the JVM, and therefore is supported
by all the JMX clients (JConsole, VisualVM, etc).

Here are some considerations when setting the JVM arguments:

1. `com.sun.management.jmxremote.port` and `com.sun.management.jmxremote.rmi.port`

   These properties are set to the same value for convenience.
   They don't have to be the same, but you have to expose one
   extra port if they're not equal.

   If you don't declare the RMI port, the RMI protocol will choose
   a random port at connection time after the initial handshake.
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

3. `java.util.logging.config.file`

   The optional `logging.properties` file configures the Java Logging
   framework to print RMI debugging messages.  Example:

   > Mar 23, 2017 8:56:26 AM ConnectorBootstrap startRemoteConnectorServer
   > FINEST: Starting JMX Connector Server:
   > 	com.sun.management.jmxremote.port=9010
   > 	com.sun.management.jmxremote.host=172.18.0.2
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
   > CONFIG: JMX Connector ready at: service:jmx:rmi:///jndi/rmi://172.18.0.2:9010/jmxrmi
   
   This is useful for debugging purposes.

4. `com.sun.management.config.file`

   This file is read in by ConnectorBootstrap at startup time
   to set `com.sun.management.jmxremote.*` properties.
   However, since no environment variable substitution is done
   any properties that must be set via environment variables
   cannot be specified in that file, and must be passed from this
   shell script (see below).
   
   This is optional.  The properties in the `management.properties` 
   file can be passed directly to the JVM as command line arguments.
   See `entrypoint.sh`.

5. `java.rmi.server.hostname`

   This is an optional but critical property when using JMX with
   a JVM running inside a Docker container.  It should be set to
   the externally accessible hostname or IP of the Docker container,
   same as `com.sun.management.jmxremote.host`.

   ***If this property is incorrect (or not set) all JMX connections will fail!***

