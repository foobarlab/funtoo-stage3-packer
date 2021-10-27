# -*- mode: ruby -*-
# vim: ts=2 sw=2 et ft=ruby :

system("./bin/config.sh >/dev/null")

Vagrant.require_version ">= 2.1.0"

$script_cleanup = <<SCRIPT
# clean stale kernel files
mount /boot || true
eclean-kernel -l
eclean-kernel -n 1
ego boot update
# clean kernel sources
cd /usr/src/linux
make clean
# clean all logs
shopt -s globstar
truncate -s 0 /var/log/*.log
truncate -s 0 /var/log/**/*.log
find /var/log -type f -name '*.[0-99].gz' -exec rm {} +
logfiles=( messages dmesg lastlog wtmp )
for i in "${logfiles[@]}"; do
  truncate -s 0 /var/log/$i
done
logfiles=( emerge emerge-fetch genkernel )
for i in "${logfiles[@]}"; do
    rm -f /var/log/$i.log
done
rm -f /var/log/portage/elog/*.log
# let it settle
sync && sleep 10
# debug: list running services
rc-status
# clean shell history
set +o history
rm -f /home/vagrant/.bash_history
rm -f /root/.bash_history
sync && sleep 5
# zerofree /boot
mount -v -n -o remount,ro /dev/sda1
zerofree /dev/sda1 && echo "zerofree: success on /dev/sda1 (boot)"
# zerofree root fs
mount -v -n -o remount,ro /dev/sda4
zerofree /dev/sda4 && echo "zerofree: success on /dev/sda4 (root)"
# swap
swapoff -v /dev/sda3
bash -c 'dd if=/dev/zero of=/dev/sda3 2>/dev/null' || true
mkswap /dev/sda3
SCRIPT

box_name = ENV["BUILD_BOX_NAME"] || "foobarlab/funtoo-stage3"
memory   = ENV['BUILD_BOX_MEMORY'] || 2048
cpus     = ENV['BUILD_BOX_CPUS'] || 2

Vagrant.configure("2") do |config|
  #config.vagrant.sensitive = ["MySecretPassword", ENV["MY_TOKEN"]] # TODO hide sensitive information
  config.vm.box_check_update = false
  config.vm.box = box_name
  config.vm.hostname = box_name
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = memory
    vb.cpus = cpus
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
    vb.customize ["modifyvm", :id, "--largepages", "on"]
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
  end
  config.ssh.insert_key = false
  config.ssh.connect_timeout = 60
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.provision "cleanup", type: "shell", inline: $script_cleanup, privileged: true
  # TODO add trigger for disk compaction?
end
