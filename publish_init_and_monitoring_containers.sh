#!/bin/bash
###########################################################################
# COPYRIGHT Ericsson 2021                                                 #
#                                                                         #
# The copyright to the computer program(s) herein is the property of      #
# Ericsson Inc. The programs may be used and/or copied only with written  #
# permission from Ericsson Inc. or in accordance with the terms and       #
# conditions stipulated in the agreement/contract under which the         #
# program(s) have been supplied.                                          #
###########################################################################

VERSION=1.14.0-16

#tag and push monitoring image
docker pull armdocker.rnd.ericsson.se/proj-enm/eric-enm-monitoring-eap7:${VERSION}
docker tag armdocker.rnd.ericsson.se/proj-enm/eric-enm-monitoring-eap7:${VERSION} armdocker.rnd.ericsson.se/proj_oss_releases/eric-enm-monitoring-eap7:${VERSION}

docker push armdocker.rnd.ericsson.se/proj_oss_releases/eric-enm-monitoring-eap7:${VERSION}

## tag and push init image
docker pull armdocker.rnd.ericsson.se/proj-enm/eric-enm-init-container:${VERSION}
docker tag armdocker.rnd.ericsson.se/proj-enm/eric-enm-init-container:${VERSION} armdocker.rnd.ericsson.se/proj_oss_releases/eric-enm-init-container:${VERSION}

docker push armdocker.rnd.ericsson.se/proj_oss_releases/eric-enm-init-container:${VERSION}
