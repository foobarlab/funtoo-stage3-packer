#!/bin/bash -ue

command -v vagrant >/dev/null 2>&1 || { echo "Command 'vagrant' required but it's not installed.  Aborting." >&2; exit 1; }
command -v vboxmanage >/dev/null 2>&1 || { echo "Command 'vboxmanage' required but it's not installed.  Aborting." >&2; exit 1; }

. config.sh

# do a local folder clean before
. clean.sh

# do some more system cleanup:
# => suspend all vms as seen by the current user
# => delete temporary files as seen by the current user
echo "Suspend any running vagrant vms ..."
vagrant global-status | awk '/running/{print $1}' | xargs -r -d '\n' -n 1 -- vagrant suspend
echo "Forcibly shutdown any running virtualbox vms ..."
vboxmanage list runningvms | sed -r 's/.*\{(.*)\}/\1/' | xargs -L1 -I {} VBoxManage controlvm {} acpipowerbutton && true
vboxmanage list runningvms | sed -r 's/.*\{(.*)\}/\1/' | xargs -L1 -I {} VBoxManage controlvm {} poweroff && true
echo "Delete all inaccessible vms ..."
vboxmanage list vms | grep "<inaccessible>" | sed -r 's/.*\{(.*)\}/\1/' | xargs -L1 -I {} vboxmanage unregistervm --delete {}
echo "Force remove of appliance from Virtualbox folder ..."
rm -rf ~/.VirtualBox/Machines/$BUILD_BOX_NAME/
echo "Delete temporary vagrant files ..."
rm -rf ~/.vagrant.d/tmp/*
echo "Current Status for Virtualbox (if any): "
vboxmanage list vms
echo "Current Status for Vagrant (if any):"
vagrant global-status
echo "All done. Environment was cleaned. You may now run './build.sh' to build a fresh box."
