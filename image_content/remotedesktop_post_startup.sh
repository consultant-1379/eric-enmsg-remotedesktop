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

_LN=/usr/bin/ln
_MKDIR=/usr/bin/mkdir
_MV=/usr/bin/mv
_RM=/usr/bin/rm
_ECHO=/usr/bin/echo
_CHMOD=/usr/bin/chmod
_TOUCH=/usr/bin/touch
_SED=/usr/bin/sed

PROG="remotedesktop_post_startup.sh"

CREATE_CERTIFICATES_LINKS=/certScript/createCertificatesLinks.sh

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


info "removing default certificate for tlwebaccess"
rm -f /opt/thinlinc/etc/tlwebaccess/server.crt
if [ $? -eq 0 ]; then
  info "default server.crt removed successfully"
else
  error "removal of default server.crt failed"
fi

info "removing default certificate key for tlwebaccess"
rm -f /opt/thinlinc/etc/tlwebaccess/server.key
if [ $? -eq 0 ]; then
  info "default server.key removed successfully"
else
  error "removal of default server.key failed"
fi

info "creating linux symb. links to locations where app looks for certs"
$CREATE_CERTIFICATES_LINKS
if [ $? -eq 0 ]; then
  info "execution of $CREATE_CERTIFICATES_LINKS completed successfully"
else
  error "execution of $CREATE_CERTIFICATES_LINKS failed"
fi

## remove audio support, as we don't require it
rm -rf /opt/thinlinc/etc/xstartup.d/43-tl-pulseaudio-launch.sh

#Cendio
info "Fix http to https to fix rdesktop-session-management-web"
sed -i 's/http:\/\/$UI_PRES_SERVER/https:\/\/$UI_PRES_SERVER/g' /ericsson/ERICcendiothinlinc_CXP9031953/scripts/application_launcher.sh
sed -i 's/http:\/\/$UI_PRES_SERVER/https:\/\/$UI_PRES_SERVER/g' /opt/thinlinc/etc/xstartup.d/60-record-desktop-session.sh

## fixing updates for cleanup of user sessions in desktop session management
sed -i 's/http:\/\/$HOSTNAME/http:\/\/elementmanager/g' /ericsson/ERICcendiothinlinc_CXP9031953/scripts/control_thinlinc_services.sh
sed -i 's/http:\/\/$HOSTNAME/http:\/\/elementmanager/g' /opt/thinlinc/etc/xlogout.d/lt-sessmang-end.sh
sed -i 's/http:\/\/$HOSTNAME/http:\/\/elementmanager/g' /ericsson/ERICcendiothinlinc_CXP9031953/scripts/resource_usage.sh


#############################################################################################
### main code from postinstall.sh for Cendio
#############################################################################################
## create RHEL 7 compatible folder/symbolic link for Firefox preferences and copy preferences
CUSTOM_JS_FILE=/ericsson/ERICcendiothinlinc_CXP9031953/configuration/custom.js
FIREFOX_PREF_PATH=/usr/lib64/firefox/defaults/preferences

$_LN -s /usr/lib64/firefox/defaults/pref/ ${FIREFOX_PREF_PATH}

if [ -d ${FIREFOX_PREF_PATH} ]; then
   $_CHMOD 550 ${CUSTOM_JS_FILE}
   $_MV ${CUSTOM_JS_FILE} ${FIREFOX_PREF_PATH}
else
   error "${FIREFOX_PREF_PATH} directory is not present"
fi

#############################################################################
# Tint2 sttings
#############################################################################
if [ -f /etc/xdg/tint2/tint2rc ]; then
  $_SED -i 's/gedit.desktop/org.gnome.gedit.desktop/g' /etc/xdg/tint2/tint2rc
fi

$_SED -i 's/gedit.desktop/org.gnome.gedit.desktop/g' /ericsson/ERICcendiothinlinc_CXP9031953/configuration/openbox/multipleWorkspaces/tint2rc

/ericsson/ERICcendiothinlinc_CXP9031953/scripts/configure_cendio_thinlinc.sh

#/////////
#mlcraft script removal using pib
#/////////
# Declare a variable "rdesktopMLcraftRemoval" and fetch the rdesktopMLcraftRemoval key value from /home/shared/common/rdesktop/remote_desktop.properties path
rdesktopMLcraftRemoval=$(grep -oP '(?<=rdesktopMLcraftRemoval=).*' /home/shared/common/rdesktop/remote_desktop.properties)
info "After fetching the PIB value from properties file: ${rdesktopMLcraftRemoval}"
# Check if the variable value is true
if [ "$rdesktopMLcraftRemoval" = "true" ]; then
  # Check if the mlcraft folder exists in /opt/ericsson/ path
  if [ -d /opt/ericsson/mlcraft ]; then
    # Remove the mlcraft folder from /opt/ericsson/ path
    sudo rm -rf /opt/ericsson/mlcraft
    info "MLCraft folder exist and attempt to remove the folder is successful."
  else
    info "The mlcraft folder does not exist."
  fi
fi

