#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

chroot /mnt/funtoo /bin/bash <<'EOF'
emerge -v sys-fs/zerofree
EOF

chroot /mnt/funtoo /bin/bash <<'EOF'
emerge --depclean
find /etc/ -name '._cfg*'              # DEBUG: list all config files needing an update
etc-update --verbose --preen           # auto-merge trivial changes
EOF

# FIXME: clean kernel sources if BUILD_CUSTOM_KERNEL is "true"?
#chroot /mnt/funtoo /bin/bash <<'EOF'
#cd /usr/src/linux && make distclean
#EOF

rm -f /mnt/funtoo/etc/resolv.conf
rm -f /mnt/funtoo/etc/resolv.conf.bak
rm -rf /mnt/funtoo/var/cache/portage/distfiles/*
rm -rf /mnt/funtoo/var/git/meta-repo
rm -rf /mnt/funtoo/tmp/*

cat /dev/null > ~/.bash_history && history -c

mount -o remount,ro /mnt/funtoo
chroot /mnt/funtoo /bin/bash <<'EOF'
zerofree /dev/sda4
EOF

mount -o remount,ro /mnt/funtoo/boot
chroot /mnt/funtoo /bin/bash <<'EOF'
zerofree /dev/sda1
EOF

swapoff /dev/sda3
dd if=/dev/zero of=/dev/sda3 || true
mkswap /dev/sda3
