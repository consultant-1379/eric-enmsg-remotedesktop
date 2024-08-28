ARG ERIC_ENM_SLES_BASE_SCRIPTING_IMAGE_NAME=eric-enm-sles-base-scripting
ARG ERIC_ENM_SLES_BASE_SCRIPTING_IMAGE_REPO=armdocker.rnd.ericsson.se/proj-enm
ARG ERIC_ENM_SLES_BASE_SCRIPTING_IMAGE_TAG=1.64.0-33

FROM ${ERIC_ENM_SLES_BASE_SCRIPTING_IMAGE_REPO}/${ERIC_ENM_SLES_BASE_SCRIPTING_IMAGE_NAME}:${ERIC_ENM_SLES_BASE_SCRIPTING_IMAGE_TAG}

ARG BUILD_DATE=unspecified
ARG IMAGE_BUILD_VERSION=unspecified
ARG GIT_COMMIT=unspecified
ARG ISO_VERSION=unspecified
ARG RSTATE=unspecified
ARG KEEP_DOWNLOADED_RPMS

LABEL \
com.ericsson.product-number="CXC 174 2030" \
com.ericsson.product-revision=$RSTATE \
enm_iso_version=$ISO_VERSION \
org.label-schema.name="ENM Element Manager Service Group Remote Desktop" \
org.label-schema.build-date=$BUILD_DATE \
org.label-schema.vcs-ref=$GIT_COMMIT \
org.label-schema.vendor="Ericsson" \
org.label-schema.version=$IMAGE_BUILD_VERSION \
org.label-schema.schema-version="1.0.0-rc1"

# credentialmanagercli is no more executed inside remotedesktop container => eric-enm-credm-controller
# to have linux links to certificates where app looks for certs
RUN rpm -e --nodeps ERICcredentialmanagercli_CXP9031389 || echo "No ERICcredentialmanagercli_CXP9031389 installed" && \
mkdir -p /certScript/ && \
cp /image_content/createCertificatesLinks.sh /certScript/createCertificatesLinks.sh && \
chmod 750 /certScript/createCertificatesLinks.sh && \
cp /image_content/repos/*.repo /etc/zypp/repos.d/

#RUN if [[ ${KEEP_DOWNLOADED_RPMS} eq "true" ]]; then zypper modifyrepo -k --all; fi
#RUN zypper modifyrepo -k --all

## installing cendio thinlinc dependencies in multiple layers
## to avoid having one layer of size exceeding 1GB

RUN cp /build/gnome_installation.sh /root && \
mkdir -p /ericsson/elementmanager && chmod 750 /root/gnome_installation.sh && /root/gnome_installation.sh

RUN zypper install -y xorg*

#GConf2 in RHEL -> replaced with gconf2 in SLES
RUN zypper install -y firefox.x86_64 gconf2 \
    ORBit2 \
    libavahi-glib1 \
    arphic-uming-fonts \
    dejavu-* \
    xrdp \
    giflib-devel \
    gnome-icon-theme \
    gnome-themes \
    gnome-vfs2 \
    gtk2-engines \
    ghostscript \
    jline1 \
    keyutils \
    libIDL-2-0 \
    libXScrnSaver \
    #libasyncns \
    libbonobo \
    libevent \
    #libgssglue \
    libogg0 \
    libsndfile \
    libtirpc-netconfig \
    libtirpc3 \
    libtirpc3-32bit \
    libvorbis \
    lksctp-tools \
    libpoppler-cpp0 \
    libpoppler89 \
    poppler-tools \
    m4 \
    libGLU1 \
    openldap2-client \
    patch \
    libpcsclite1 \
    python3-cairo \
    #pygtk2 \
    #python-ldap:
    python3-ldap \
    #pytz-2010h \
    unzip \
    urw-fonts \
    #wdaemon \
    xterm \
    #xvattr \
    zip \
    mozilla-nss-tools \
    python3-gobject \
    python3-gobject-Gdk \
    typelib-1_0-Gtk-3_0 \
    python3-configobj \
    python3-requests \
    expect \
    gedit \
    python3-tk \
    bc

## disable jboss
RUN systemctl disable jboss.service && rm -rf /usr/lib/ocf/resource.d/jboss_healthcheck.sh && rm -rf /usr/lib/ocf/resource.d/infinispan_healthcheck.sh && rm -rf /ericsson/3pp/jboss/*

## env variables
ENV SG_STARTUP_SCRIPT="/ericsson/sg/remotedesktop_startup.sh"

## disable jboss and remove healthchecks applicable only for jboss deployment
## after decoupling Cendio of EM the HOSTNAME to EM needs to be addressed

RUN zypper install -y java-1_8_0-openjdk \
    java-1_8_0-openjdk-devel

RUN zypper install -y EXTRthinlinctlmisc_CXP9042602

RUN zypper install -y ERICminilinkcraft_CXP9032676 \
    EXTRthinlinctlmisclibs_CXP9042601 \
    EXTRthinlinctlprinter_CXP9042600 \
    EXTRthinlincvsm_CXP9042598 \
    EXTRthinlinctladm_CXP9042603 \
    EXTRthinlincvncserver_CXP9042599 \
    EXTRthinlincwebaccess_CXP9042597

RUN cp /image_content/tint2_repos/*.repo /etc/zypp/repos.d/ && \
    zypper install -y libImlib2-1 \
    imlib2-loaders \
    tint2 \
    tint2-lang && \
    zypper download ERICelementmgrsmartloader_CXP9032645 ERICenmsgelementmanager_CXP9031905 ERICcendiothinlinc_CXP9031953 && \
    zypper --no-gpg-checks install -y /var/cache/zypp/packages/enm_iso_repo/ERICelementmgrsmartloader_CXP9032645*.rpm && \
    rpm -ivh /var/cache/zypp/packages/enm_iso_repo/ERICcendiothinlinc_CXP9031953*.rpm --allfiles --nodeps --noscripts && \
    rpm -ivh /var/cache/zypp/packages/enm_iso_repo/ERICenmsgelementmanager_CXP9031905*.rpm --allfiles --nodeps --noscripts

RUN rm -rf /etc/cron.d/thinlinc_healthcheck /etc/cron.d/ldap_statuscheck /etc/cron.d/tmpcleanup \
    /usr/lib/ocf/resource.d/enm_microhealthcheck.sh && \
    rm -rf /usr/local/bin/screensaver && \
    sed -i 's/\$HOSTNAME/elementmanager/g' /ericsson/ERICelementmgrsmartloader_CXP9032645/bin/smart_loader.sh && \
    sed -i 's/\$HOSTNAME/elementmanager/g' /usr/local/bin/rdesktop/emgui.sh

RUN cp /image_content/remotedesktop_*.sh /ericsson/sg/ && \
cp /image_content/services/*.service /usr/lib/systemd/system && \
cp /image_content/python/screensaver /usr/local/bin && \
cp /image_content/scripts/thinlinc/xstartup/80-screensaver.sh /opt/thinlinc/etc/xstartup.d && \
cp /image_content/scripts/openjdk_enm_users.sh /etc/profile.d/ && \
cp /image_content/scripts/java.security /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/jre/lib/security/

RUN chown root:root /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/jre/lib/security/java.security && chmod 755 -R /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/jre/lib/security/java.security

RUN chown root:root /opt/thinlinc/etc/xstartup.d/80-screensaver.sh && chmod 755 -R /opt/thinlinc/etc/xstartup.d/80-screensaver.sh && \
    chown root:root /usr/local/bin/screensaver && chmod 555 -R /usr/local/bin/screensaver && \
    chmod 770 -R /ericsson/sg/*.sh && \
    systemctl enable remotedesktop-post-startup.service && \
    systemctl enable enm-cendiothinlinc-configuration.service && date

EXPOSE 22 80 111 443 830 1904 2023 2024 3528 4192 9000 9830 9831 9990 9999
