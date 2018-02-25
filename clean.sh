#!/bin/bash -uex
vagrant destroy -f && true
rm -rf .ssh/ || true
rm -rf .vagrant/ || true
rm -rf packer_cache/ || true
rm -f *.tar.xz.hash.txt || true
rm -f *.box || true
