#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# copy stage3 release info to vagrant home
cp /tmp/scripts/.$BUILD_BOX_NAME /mnt/funtoo/home/vagrant/
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
chown vagrant.vagrant ~vagrant/.$BUILD_BOX_NAME
EOF

# replace motd
rm -f /mnt/funtoo/etc/motd
cat <<'DATA' | tee -a /mnt/funtoo/etc/motd

Funtoo GNU/Linux Vagrant Box (BUILD_BOX_USERNAME/BUILD_BOX_NAME) - release BUILD_BOX_VERSION build BUILD_TIMESTAMP

DATA
sed -i 's/BUILD_BOX_NAME/'"${BUILD_BOX_NAME:-}"'/g' /mnt/funtoo/etc/motd
sed -i 's/BUILD_BOX_USERNAME/'"$BUILD_BOX_USERNAME"'/g' /mnt/funtoo/etc/motd
sed -i 's/BUILD_BOX_VERSION/'"${BUILD_BOX_VERSION:-}"'/g' /mnt/funtoo/etc/motd
sed -i 's/BUILD_TIMESTAMP/'"${BUILD_TIMESTAMP:-}"'/g' /mnt/funtoo/etc/motd
cat /mnt/funtoo/etc/motd

mv -f /mnt/funtoo/etc/issue /mnt/funtoo/etc/issue.old
cat <<'DATA' | tee -a /mnt/funtoo/etc/issue
This is a Funtoo GNU/Linux Vagrant Box (BUILD_BOX_USERNAME/BUILD_BOX_NAME BUILD_BOX_VERSION)

DATA
sed -i 's/BUILD_BOX_VERSION/'$BUILD_BOX_VERSION'/g' /mnt/funtoo/etc/issue
sed -i 's/BUILD_BOX_NAME/'$BUILD_BOX_NAME'/g' /mnt/funtoo/etc/issue
sed -i 's/BUILD_BOX_USERNAME/'"$BUILD_BOX_USERNAME"'/g' /mnt/funtoo/etc/issue
cat /mnt/funtoo/etc/issue

# add roots .bashrc initial skeleton
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
cat /mnt/funtoo/etc/skel/.bashrc > /mnt/funtoo/root/.bashrc
EOF

# fix PATH in roots .bashrc
cat <<'DATA' | tee -a /mnt/funtoo/root/.bashrc
# add /usr/local paths
export PATH=$PATH:/usr/local/bin:/usr/local/sbin
DATA

# eclean-kernel: required to remove stale files of replaced kernel
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -vt app-admin/eclean-kernel
EOF

# acpid: required for gracefully shutdown on close
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -v sys-power/acpid
rc-update add acpid default
EOF

# some utils required for advanced networking
# see: https://wiki.gentoo.org/wiki/VirtualBox#Gentoo_guests
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -v sys-apps/usermode-utilities net-misc/bridge-utils
EOF

# install virtualbox-guest-additions?
if [ -z ${BUILD_GUEST_ADDITIONS:-} ]; then
    echo "BUILD_GUEST_ADDITIONS was not set. Skipping Virtualbox Guest Additions install."
else
    if [ "$BUILD_GUEST_ADDITIONS" = false ]; then
        echo "BUILD_GUEST_ADDITIONS set to FALSE. Skipping Virtualbox Guest Additions install."
    else
        echo "BUILD_GUEST_ADDITIONS set to TRUE. Installing Virtualbox Guest Additions ..."
        chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -vt app-emulation/virtualbox-guest-additions
rc-update add virtualbox-guest-additions default
gpasswd -a vagrant vboxsf
gpasswd -a vagrant vboxguest
EOF
    fi
fi

# add up-to-date intel cpu microcode
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -vt sys-firmware/intel-microcode sys-apps/iucode_tool
EOF

# perl-cleaner
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
perl-cleaner --all
EOF

# perform @preserved-rebuild (just in case)
chroot /mnt/funtoo /bin/bash -uex <<'EOF'
emerge -v @preserved-rebuild
EOF
