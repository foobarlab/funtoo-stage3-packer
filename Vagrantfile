# -*- mode: ruby -*-
# vi: set ft=ruby :

system("./config.sh >/dev/null")

# second run to free some space
$script_cleanup = <<SCRIPT
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
    vb.memory = "#{ENV['BUILD_GUEST_MEMORY']}"
    vb.cpus = "#{ENV['BUILD_GUEST_CPUS']}"
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
    vb.customize ["modifyvm", :id, "--rtcuseutc", "on"]
  end
  config.ssh.insert_key = false
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.provision "cleanup", type: "shell", inline: $script_cleanup
end
