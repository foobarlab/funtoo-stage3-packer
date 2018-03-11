# -*- mode: ruby -*-
# vi: set ft=ruby :

system("./config.sh >/dev/null")

Vagrant.configure("2") do |config|
  config.vm.box = "#{ENV['BUILD_BOX_NAME']}"
  config.vm.hostname = "#{ENV['BUILD_BOX_NAME']}"
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "#{ENV['BUILD_GUEST_MEMORY']}"
    vb.cpus = "#{ENV['BUILD_GUEST_CPUS']}"
  end
  config.vm.synced_folder '.', '/vagrant', disabled: true
end
