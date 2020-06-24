#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
cat > /etc/fstab <<'DATA'
# <fs>        <mount>     <type>      <opts>              <dump/pass>
/dev/sda1     /boot       ext2        noauto,noatime      1 2
/dev/sda3     none        swap        sw                  0 0
/dev/sda4     /           ext4        noatime             0 1
/dev/cdrom    /mnt/cdrom  auto        noauto,ro           0 0
tmpfs	      /tmp	      tmpfs	      rw,nosuid,noatime,nodev,size=2G,mode=1777   0 0
DATA
EOF
