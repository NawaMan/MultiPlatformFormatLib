#!/bin/bash

source sh-sources/common-source.sh

print_section "Checking LLVM Version"

# Load CLANG_VERSION from versions.env
if [[ -f versions.env ]]; then
    source versions.env
else
    exit_with_error "versions.env not found!"
fi

CLANG_VERSION=${CLANG_VERSION:-20}

# Helper: parse version from command
tool_version() {
    local cmd="$1"
    local pattern="${2:-version [0-9]+}"

    if ! command -v "$cmd" &>/dev/null; then
        echo "not_installed"
        return
    fi

    local output version
    output=$("$cmd" --version 2>/dev/null)
    version=$(echo "$output" | grep -o "$pattern" | awk '{print $NF}')

    if [[ -z "$version" ]]; then
        echo "not_installed"
    else
        echo "$version"
    fi
}

NEED_LLVM_INSTALL=false

[[ "$(tool_version clang       | cut -d. -f1)" != "$CLANG_VERSION" ]] && NEED_LLVM_INSTALL=true
[[ "$(tool_version clang++     | cut -d. -f1)" != "$CLANG_VERSION" ]] && NEED_LLVM_INSTALL=true
[[ "$(tool_version llvm-ar     | cut -d. -f1)" != "$CLANG_VERSION" ]] && NEED_LLVM_INSTALL=true
[[ "$(tool_version llvm-ranlib | cut -d. -f1)" != "$CLANG_VERSION" ]] && NEED_LLVM_INSTALL=true

if $NEED_LLVM_INSTALL; then
    print_status "Installing LLVM/Clang $CLANG_VERSION..."

    brew install llvm@$CLANG_VERSION || exit_with_error "Failed to install llvm@$CLANG_VERSION"

    # Detect Apple Silicon vs Intel paths
    LLVM_BASE="/opt/homebrew/opt/llvm@$CLANG_VERSION"
    if [[ ! -d "$LLVM_BASE" ]]; then
        LLVM_BASE="/usr/local/opt/llvm@$CLANG_VERSION"
    fi

    if [[ ! -d "$LLVM_BASE" ]]; then
        exit_with_error "LLVM path not found after install"
    fi

    export PATH="$LLVM_BASE/bin:$PATH"
    export CC="$LLVM_BASE/bin/clang"
    export CXX="$LLVM_BASE/bin/clang++"
    export AR="$LLVM_BASE/bin/llvm-ar"
    export RANLIB="$LLVM_BASE/bin/llvm-ranlib"

    print_status "LLVM $CLANG_VERSION installed and configured"
else
    print_status "LLVM $CLANG_VERSION already available"
fi

print_section "Compiler Information"

echo "which clang      : $(which clang)"
echo "which clang++    : $(which clang++)"
echo "which llvm-ar    : $(which llvm-ar)"
echo "which llvm-ranlib: $(which llvm-ranlib)"
echo ""
echo "Clang       version: $(clang       --version | head -n 1)"
echo "Clang++     version: $(clang++     --version | head -n 1)"
echo "LLVM-ar     version: $(llvm-ar     --version | head -n 1)"
echo "LLVM-ranlib version: $(llvm-ranlib --version | head -n 1)"

print_section "macOS LLVM Setup Complete"
