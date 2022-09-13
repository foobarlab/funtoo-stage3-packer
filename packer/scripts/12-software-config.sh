#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# backup any kernel config
cp /mnt/funtoo/usr/src/linux/.config /mnt/funtoo/usr/src/kernel.config.stage3-dist

# tweak sshd config (speed up logins) => "UseDNS no"
sed -i 's/#UseDNS/UseDNS/g' /mnt/funtoo/etc/ssh/sshd_config

# replace motd
rm -f /mnt/funtoo/etc/motd
cat <<'DATA' | tee -a /mnt/funtoo/etc/motd

Funtoo Linux (BUILD_BOX_USERNAME/BUILD_BOX_NAME) - release BUILD_BOX_VERSION build BUILD_TIMESTAMP

DATA
sed -i 's/BUILD_BOX_NAME/'"${BUILD_BOX_NAME:-}"'/g' /mnt/funtoo/etc/motd
sed -i 's/BUILD_BOX_USERNAME/'"$BUILD_BOX_USERNAME"'/g' /mnt/funtoo/etc/motd
sed -i 's/BUILD_BOX_VERSION/'"${BUILD_BOX_VERSION:-}"'/g' /mnt/funtoo/etc/motd
sed -i 's/BUILD_TIMESTAMP/'"${BUILD_TIMESTAMP:-}"'/g' /mnt/funtoo/etc/motd
cat /mnt/funtoo/etc/motd

rm -f /mnt/funtoo/etc/issue
cat <<'DATA' | tee -a /mnt/funtoo/etc/issue
Funtoo Linux (BUILD_BOX_USERNAME/BUILD_BOX_NAME-BUILD_BOX_VERSION)

DATA
sed -i 's/BUILD_BOX_VERSION/'$BUILD_BOX_VERSION'/g' /mnt/funtoo/etc/issue
sed -i 's/BUILD_BOX_NAME/'$BUILD_BOX_NAME'/g' /mnt/funtoo/etc/issue
sed -i 's/BUILD_BOX_USERNAME/'"$BUILD_BOX_USERNAME"'/g' /mnt/funtoo/etc/issue
cat /mnt/funtoo/etc/issue

# root's bashrc from skeleton
cp /mnt/funtoo/etc/skel/.bashrc /mnt/funtoo/root/.bashrc

# fix PATH in roots .bashrc
cat <<'DATA' | tee -a /mnt/funtoo/root/.bashrc

# add /usr/local paths
export PATH=$PATH:/usr/local/bin:/usr/local/sbin

DATA

# install recommended software
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
# eclean-kernel: required to remove stale files of replaced kernel
emerge -vt app-admin/eclean-kernel

# acpid: required for gracefully shutdown on close
emerge -vt sys-power/acpid
rc-update add acpid default

# some utils required for advanced networking
# see: https://wiki.gentoo.org/wiki/VirtualBox#Gentoo_guests
emerge -vt sys-apps/usermode-utilities net-misc/bridge-utils

# add up-to-date intel cpu microcode, uncomment if you want to run this vm on bare metal
#emerge -vt sys-firmware/intel-microcode sys-apps/iucode_tool

# grow filesystem partitions
emerge -vt sys-fs/growpart 

# perl-cleaner
perl-cleaner --reallyall
EOF

# install virtualbox-guest-additions?
if [ -z ${BUILD_GUEST_ADDITIONS:-} ]; then
    echo "BUILD_GUEST_ADDITIONS was not set. Skipping Virtualbox Guest Additions install."
else
    if [ "$BUILD_GUEST_ADDITIONS" = false ]; then
        echo "BUILD_GUEST_ADDITIONS set to FALSE. Skipping Virtualbox Guest Additions install."
    else
        echo "BUILD_GUEST_ADDITIONS set to TRUE. Installing Virtualbox Guest Additions ..."
        chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -vt app-emulation/virtualbox-guest-additions
rc-update add virtualbox-guest-additions default
gpasswd -a vagrant vboxsf
gpasswd -a vagrant vboxguest
EOF
    fi
fi

# cleanup, rebuild and finish installation
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -vt --update --newuse --deep --with-bdeps=y @world
emerge -v @preserved-rebuild
emerge --depclean
emerge -v @preserved-rebuild
revdep-rebuild
EOF
