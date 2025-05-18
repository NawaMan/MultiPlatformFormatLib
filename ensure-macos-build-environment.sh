#!/bin/bash

source sh-sources/common-source.sh

print_section "Installing macOS dependencies"

# Check for Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
    print_status "Installing Xcode Command Line Tools..."
    xcode-select --install
else
    print_status "Xcode Command Line Tools already installed."
fi

# Check for Homebrew
if ! command -v brew &>/dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

print_status "Updating Homebrew..."
brew update > /dev/null

print_status "Installing packages..."

brew install -q cmake pkg-config curl unzip wget zip \
    2>&1 | grep -E 'Already installed|Installing|Pouring'

# Call LLVM setup (in a separate script)
./ensure-macos-llvm-setup.sh
