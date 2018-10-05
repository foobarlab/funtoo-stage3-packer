#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

## this is a workaround for now
## upgrade to latest ego and re-sync
#chroot /mnt/funtoo /bin/bash -uex <<'EOF'
#emerge -s app-admin/ego
#emerge -vt app-admin/ego
#env-update
#source /etc/profile
#etc-update --preen
#etc-update --automode -5
#ego sync
#emerge --depclean
#EOF

# install bootloader
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -vt sys-boot/grub
grub-install --target=i386-pc --no-floppy /dev/sda
cat > /etc/boot.conf <<'DATA'
boot {
    generate grub
    default "Funtoo Linux"
    timeout 1
}
display { 
	gfxmode 800x600
}
"Funtoo Linux" {
    kernel kernel[-v]
    initrd initramfs[-v]
    params += real_root=auto rootfstype=auto
}
DATA
rm -f /boot/memtest86.bin
boot-update
EOF
