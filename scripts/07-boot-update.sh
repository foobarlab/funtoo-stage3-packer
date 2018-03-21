#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -v boot-update
grub-install --target=i386-pc --no-floppy /dev/sda
cat > /etc/boot.conf <<'DATA'
boot {
    generate grub
    default "Funtoo Linux"
    timeout 1
}

"Funtoo Linux" {
    kernel bzImage[-v]
}

# FIXME is this unused? obviously defaults to entry above ...
"Funtoo Linux genkernel" {
    kernel kernel[-v]
    initrd initramfs[-v]
    params += real_root=auto rootfstype=auto
}
DATA
rm -f /boot/memtest86.bin
boot-update
EOF
