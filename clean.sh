#!/bin/bash -uex
vagrant destroy -f && true
rm -rf .ssh/
rm -rf .vagrant/
rm -rf packer_cache/
rm -f *.iso
rm -f *.tar.xz
rm -f *.tar.xz.hash.txt
rm -f *.box
