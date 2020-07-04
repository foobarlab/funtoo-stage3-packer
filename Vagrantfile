# -*- mode: ruby -*-
# vi: set ft=ruby :

system("./config.sh >/dev/null")

$script_guest_additions = <<SCRIPT
# copy iso and start install
sudo mkdir -p /mnt/temp
sudo mount -o loop /root/VBoxGuestAdditions.iso /mnt/temp
sudo /mnt/temp/VBoxLinuxAdditions.run
sudo umount /mnt/temp
sudo cat /var/log/vboxadd-setup.log
# add user vagrant to vboxsf group
sudo gpasswd -a vagrant vboxsf
# auto-load vboxsf (vboxguest already loaded by udev rule):
cat <<'DATA' | sudo tee -a /etc/conf.d/modules

# Virtualbox shared folders
modules="vboxsf"
DATA
# remove iso
sudo rm -f /root/VBoxGuestAdditions.iso
SCRIPT

$script_cleanup = <<SCRIPT
# clean stale kernel files
sudo eclean-kernel
sudo ego boot update
# clean kernel sources
cd /usr/src/linux
sudo make distclean
# /boot (initially not mounted)
sudo mount -o ro /dev/sda1
sudo zerofree /dev/sda1
# /
sudo mount -o remount,ro /dev/sda4
sudo zerofree /dev/sda4
# swap
sudo swapoff /dev/sda3
sudo bash -c 'dd if=/dev/zero of=/dev/sda3 2>/dev/null' || true
sudo mkswap /dev/sda3
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  config.vm.box = "#{ENV['BUILD_BOX_NAME']}"
  config.vm.hostname = "#{ENV['BUILD_BOX_NAME']}"
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "#{ENV['BUILD_BOX_MEMORY']}"
    vb.cpus = "#{ENV['BUILD_BOX_CPUS']}"
    # customize VirtualBox settings, see also 'virtualbox.json'
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
    vb.customize ["modifyvm", :id, "--rtcuseutc", "on"]
    vb.customize ["modifyvm", :id, "--chipset", "ich9"]
    vb.customize ["modifyvm", :id, "--vram", "12"]
    vb.customize ["modifyvm", :id, "--vrde", "off"]
    vb.customize ["modifyvm", :id, "--hpet", "on"]
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--vtxvpid", "on"]
    vb.customize ["modifyvm", :id, "--spec-ctrl", "on"]
    vb.customize ["modifyvm", :id, "--largepages", "off"]
  end
  config.ssh.pty = true
  config.ssh.insert_key = false
  config.vm.synced_folder '.', '/vagrant', disabled: true
  if ENV['BUILD_GUEST_ADDITIONS'] == 'true'
    config.vm.provision "guest-additions", type: "shell", inline: $script_guest_additions
  end
  config.vm.provision "cleanup", type: "shell", inline: $script_cleanup
end
