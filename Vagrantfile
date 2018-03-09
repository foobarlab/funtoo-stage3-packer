# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "funtoo-stage3"
  config.vm.hostname = "funtoo-stage3"
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "2048"
    vb.cpus = "4"
  end
 config.vm.synced_folder '.', '/vagrant', disabled: true
end
