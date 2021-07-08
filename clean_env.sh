#!/bin/bash -ue

vboxmachinefolder="~/.VirtualBox/Machines"

vboxmanage=VBoxManage
command -v $vboxmanage >/dev/null 2>&1 || vboxmanage=vboxmanage   # try alternative

. config.sh quiet

require_commands vagrant $vboxmanage

echo "------------------------------------------------------------------------------"
echo "  ENVIRONMENT CLEANUP"
echo "------------------------------------------------------------------------------"

# do some more system cleanup:
# => suspend all VMs as seen by the current user
# => delete temporary files as seen by the current user
echo ">>> Suspend any running Vagrant VMs ..."
vagrant global-status | awk '/running/{print $1}' | xargs -r -d '\n' -n 1 -- vagrant suspend
echo ">>> Prune invalid Vagrant entries ..."
vagrant global-status --prune >/dev/null
echo ">>> Delete temporary Vagrant files ..."
rm -rf ~/.vagrant.d/tmp/*
echo ">>> Forcibly shutdown any running VirtualBox VMs ..."
$vboxmanage list runningvms | sed -r 's/.*\{(.*)\}/\1/' | awk '{print "$vboxmanage controlvm "$1" acpipowerbutton\0"}' | xargs -0 >/dev/null
$vboxmanage list runningvms | sed -r 's/.*\{(.*)\}/\1/' | awk '{print "$vboxmanage controlvm "$1" poweroff\0"}' | xargs -0 >/dev/null
echo ">>> Delete all inaccessible VMs ..."
$vboxmanage list vms | grep "<inaccessible>" | sed -r 's/.*\{(.*)\}/\1/' | awk '{print "$vboxmanage unregistervm --delete "$1"\0"}' | xargs -0 >/dev/null
echo ">>> Force remove of appliance from VirtualBox machine folder ..."
# FIXME assumed path ~/.VirtualBox/Machines/ might be incorrect, better get this from VirtualBox config somehow
rm -rf $vboxmachinefolder/$BUILD_BOX_NAME/ || true
echo ">>> Drop build number ..."
rm -f build_number || true

# basic cleanup
echo
. clean.sh
