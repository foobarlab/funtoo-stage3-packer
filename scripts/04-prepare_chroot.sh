#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

cd /mnt/funtoo
mount -t proc none proc
mount --rbind /sys sys
mount --rbind /dev dev

cp -L /etc/resolv.conf /mnt/funtoo/etc/

# ensure to use Python 3.7
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
eselect python list
eselect python set python3.7
eselect python list
EOF

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
ego sync
emerge --update --newuse --deep --with-bdeps=y @world
EOF
