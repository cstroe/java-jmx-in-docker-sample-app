#!/usr/bin/env bash
set -x

JMX_PORT=9010
HOST="0.0.0.0"

java \
  -Dcom.sun.management.config.file=/opt/app/management.properties \
  -Djava.util.logging.config.file=/opt/app/logging.properties \
  -Dcom.sun.management.jmxremote.port=$JMX_PORT \
  -Dcom.sun.management.jmxremote.rmi.port=$JMX_PORT \
  -Dcom.sun.management.jmxremote.host=$HOST \
  -Djava.rmi.server.hostname=$HOST \
  -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 \
  -jar /opt/app/app.jar

