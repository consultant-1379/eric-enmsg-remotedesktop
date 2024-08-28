#!/bin/bash
###########################################################################
# COPYRIGHT Ericsson 2022                                                #
#                                                                         #
# The copyright to the computer program(s) herein is the property of      #
# Ericsson Inc. The programs may be used and/or copied only with written  #
# permission from Ericsson Inc. or in accordance with the terms and       #
# conditions stipulated in the agreement/contract under which the         #
# program(s) have been supplied.                                          #
###########################################################################

if [ $UID -gt 4999 ]; then
  if [ -d /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0 ]; then
     JAVA_HOME=/usr/lib64/jvm/java-1.8.0-openjdk-1.8.0
  else
     JAVA_HOME=/usr/java/latest
  fi
fi