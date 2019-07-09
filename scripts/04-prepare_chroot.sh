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

# DEBUG: find out why we get a ModuleError on `ego sync`
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
echo 'DEBUG START'
eselect python list
cat  /etc/portage/make.profile/parent
echo 'DEBUG END'
EOF

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
ego sync
EOF
