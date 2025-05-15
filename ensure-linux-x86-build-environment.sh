#!/bin/bash

source sh-sources/common-source.sh

print_section "Installing dependencies"
apt-get update -qq
apt-get install -y             \
    build-essential            \
    cmake                      \
    curl                       \
                               \
    pkg-config                 \
                               \
    unzip                      \
    wget                       \
    zip                        \
    2>&1 | grep -E 'is already the newest version|Setting up|Preparing to unpack|Installing'


./ensure-linux-llvm-setup.sh
