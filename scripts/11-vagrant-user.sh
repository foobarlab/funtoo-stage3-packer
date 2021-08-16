#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
USE="-sendmail" emerge -v app-admin/sudo
USE="-keyutils" emerge -v net-fs/nfs-utils
useradd -m -G audio,video,cdrom,wheel,users -s /bin/bash vagrant
echo vagrant:vagrant | chpasswd
echo 'vagrant ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant
mkdir -p ~vagrant/.ssh
wget https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -O ~vagrant/.ssh/authorized_keys
chmod 0700 ~vagrant/.ssh
chmod 0600 ~vagrant/.ssh/authorized_keys
chown -R vagrant: ~vagrant/.ssh
rc-update add sshd default
EOF

chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -v sys-block/parted sys-apps/dmidecode sys-fs/growpart  
EOF
