#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# copy stage3 release info to vagrant home
cp /tmp/scripts/.funtoo_stage3 /mnt/funtoo/home/vagrant/
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
chown vagrant.vagrant ~vagrant/.funtoo_stage3
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
