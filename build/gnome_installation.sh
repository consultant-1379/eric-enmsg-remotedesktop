#!/bin/bash
echo "" > /var/log/zypper.log
zypper -v install --no-recommends -y \
mdadm e2fsprogs xfsprogs thin-provisioning-tools multipath-tools dracut device-mapper \
cryptsetup kpartx gvfs-backends dbus-1-x11 libgnome

if [ $? -eq 0 ]; then
   echo "SUCCESS"
   exit 0
elif [ $? -eq 107 ]; then
   echo "CODE 107"
   exit 0
fi
exit 0
