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

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
ego sync
EOF
