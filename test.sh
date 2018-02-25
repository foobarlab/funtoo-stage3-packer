#!/bin/bash -uex

# cleanup previous box, create new box and start ssh login
vagrant suspend
vagrant destroy -f
vagrant box remove -f funtoo-stage3
vagrant box add --name funtoo-stage3 funtoo-x86_64-generic_64-stage3.box
vagrant up
vagrant ssh
