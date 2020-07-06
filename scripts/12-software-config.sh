#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# copy stage3 release info to vagrant home
cp /tmp/scripts/.$BUILD_BOX_NAME /mnt/funtoo/home/vagrant/
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
chown vagrant.vagrant ~vagrant/.$BUILD_BOX_NAME
EOF

# replace motd
rm -f /mnt/funtoo/etc/motd
cat <<'DATA' | tee -a /mnt/funtoo/etc/motd
Funtoo GNU/Linux (BUILD_BOX_NAME) - release BUILD_BOX_VERSION build BUILD_TIMESTAMP
DATA
sed -i 's/BUILD_BOX_NAME/'"${BUILD_BOX_NAME:-}"'/g' /mnt/funtoo/etc/motd
sed -i 's/BUILD_BOX_VERSION/'"${BUILD_BOX_VERSION:-}"'/g' /mnt/funtoo/etc/motd
sed -i 's/BUILD_TIMESTAMP/'"${BUILD_TIMESTAMP:-}"'/g' /mnt/funtoo/etc/motd
cat /mnt/funtoo/etc/motd

# eclean-kernel: required to remove stale files of replaced kernel
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -vt app-admin/eclean-kernel
EOF

# acpid: required for gracefully shutdown on close
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -v sys-power/acpid
rc-update add acpid default
EOF

# some utils required for advanced networking
# see: https://wiki.gentoo.org/wiki/VirtualBox#Gentoo_guests
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -v sys-apps/usermode-utilities net-misc/bridge-utils
EOF

# install virtualbox-guest-additions?
if [ ${BUILD_GUEST_ADDITIONS:"false"} == "true" ]; then
    chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -vt app-emulation/virtualbox-guest-additions
rc-update add virtualbox-guest-additions default
gpasswd -a vagrant vboxsf
gpasswd -a vagrant vboxguest
EOF
fi

# perform @preserved-rebuild (just in case)
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -v @preserved-rebuild
EOF
