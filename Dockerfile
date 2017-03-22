FROM openjdk:8-jdk

# to check for open ports in the container: docker run <container id> netstat -tan
RUN apt update && apt install net-tools

RUN mkdir -p /opt/loop

# Configure JMX over RMI
ADD bin/management.properties /opt/loop/management.properties

# Enables JVM logging for ConnectorBootstrap
ADD bin/logging.properties /opt/loop/logging.properties

# An executable jar that will run in this Docker container
# Run `mvn package` to create it
ADD target/loop-app-0.0.1-SNAPSHOT.jar /opt/loop/loop.jar

# A simple shell script to pass JVM arguments
ADD bin/entrypoint.sh /opt/loop/entrypoint.sh

# JMX
EXPOSE 9010

# JVM debugging port
EXPOSE 5005

ENTRYPOINT [ "/opt/loop/entrypoint.sh" ]
