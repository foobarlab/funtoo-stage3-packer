#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

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
    params += root=auto rootfstype=auto
}
DATA
rm -f /boot/memtest86.bin
ego boot update
EOF
