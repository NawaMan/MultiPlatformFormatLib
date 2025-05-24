#!/bin/bash

set -e

source ../sh-sources/common-source.sh

print_section "Installing dependencies"
apt-get update
apt-get install -y             \
    build-essential            \
    cmake                      \
    curl                       \
    gnupg                      \
    lsb-release                \
    software-properties-common \
    pkg-config                 \
    unzip                      \
    wget                       \
    2>&1                       \
    | grep -E 'is already the newest version|Setting up|Preparing to unpack|Installing'

cd ..
./ensure-linux-llvm-setup.sh
cd tests
