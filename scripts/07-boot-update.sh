#!/bin/bash -uex

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge boot-update
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

"Funtoo Linux genkernel" {
    kernel kernel[-v]
    initrd initramfs[-v]
    params += real_root=auto rootfstype=auto
}
DATA
rm -f /boot/memtest86.bin
boot-update
EOF
