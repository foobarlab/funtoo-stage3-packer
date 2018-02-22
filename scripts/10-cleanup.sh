#!/bin/bash -uex

chroot /mnt/funtoo /bin/bash <<'EOF'
emerge -v sys-fs/zerofree
cd /usr/src/linux && make clean
emerge --depclean
EOF

rm -f /mnt/funtoo/etc/resolv.conf
rm -f /mnt/funtoo/etc/resolv.conf.bak
rm -rf /mnt/funtoo/var/cache/portage/distfiles/*
rm -rf /mnt/funtoo/var/log/*
rm -rf /mnt/funtoo/tmp/*

mount -o remount,ro /mnt/funtoo
chroot /mnt/funtoo /bin/bash <<'EOF'
zerofree -v /dev/sda4
EOF

mount -o remount,ro /mnt/funtoo/boot
chroot /mnt/funtoo /bin/bash <<'EOF'
zerofree -v /dev/sda1
EOF

swapoff /dev/sda3
dd if=/dev/zero of=/dev/sda3 || true
mkswap /dev/sda3
