#!/usr/bin/env bash

set -x

java \
  -Dcom.sun.management.config.file=/opt/loop/management.properties \
  -Djava.util.logging.config.file=/opt/loop/logging.properties \
  -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005 \
  -jar /opt/loop/loop.jar

