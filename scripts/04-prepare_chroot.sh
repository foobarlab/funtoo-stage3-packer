#!/bin/bash -uex

cd /mnt/funtoo
mount -t proc none proc
mount --rbind /sys sys
mount --rbind /dev dev

cp -L /etc/resolv.conf /mnt/funtoo/etc/

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
ego sync
EOF