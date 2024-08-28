#!/bin/bash
###########################################################################
# COPYRIGHT Ericsson 2022                                                 #
#                                                                         #
# The copyright to the computer program(s) herein is the property of      #
# Ericsson Inc. The programs may be used and/or copied only with written  #
# permission from Ericsson Inc. or in accordance with the terms and       #
# conditions stipulated in the agreement/contract under which the         #
# program(s) have been supplied.                                          #
###########################################################################

_MKDIR=/usr/bin/mkdir
_CP=/usr/bin/cp
_CHOWN=/usr/bin/chown
_CHMOD=/usr/bin/chmod

COMMON_DIR="/home/shared/common"
RDESKTOP_DIR="/home/shared/common/rdesktop"
EM_LAUNCHER_PROP_DIR="/ericsson/ERICelementmgrsmartloader_CXP9032645/etc"

PROG="remotedesktop_startup.sh"
#############################################################
#                                                           #
# Logger Functions                                          #
#                                                           #
#############################################################
info() {
    logger -t "${PROG}" -p user.notice "INFO ( ${PROG} ): $1"
}

error() {
    logger -t "${PROG}" -p user.err "ERROR ( ${PROG} ): $1"
}
##############################################################

if [ ! -d ${RDESKTOP_DIR} ]; then
  $_MKDIR -p ${RDESKTOP_DIR}
  $_CHMOD 777 $COMMON_DIR
  info "/home/shared/common/rdesktop was created"
else
  info "/home/shared/common/rdesktop already exists"
fi

$_CP $EM_LAUNCHER_PROP_DIR/em_launcher* $RDESKTOP_DIR

if [ $? -eq 0 ]; then
  info "em_launcher properties files copied successfully"
  $_CHOWN root:root $RDESKTOP_DIR/em_launcher*.properties
  $_CHMOD 775 $RDESKTOP_DIR/em_launcher*.properties
else
  error "em_launcher properties files copy failed"
fi
