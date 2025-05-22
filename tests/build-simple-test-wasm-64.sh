#!/bin/bash

set -e

DIST_FILE=$1
BUILD_DIR=$(pwd)/build
DIST_DIR=${DIST_FILE%/*}

if [[ -z "$DIST_FILE" ]]; then
    echo "Usage: $0 <dist-file>"
    exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
unzip "$DIST_FILE" -d "$BUILD_DIR"

export EM_CACHE="$BUILD_DIR/.emscripten_cache"
mkdir -p "$EM_CACHE"

# Ensure emcc is set up
source /opt/emsdk/emsdk_env.sh

echo "Compiling to WASM64..."
em++ simple-test.cpp               \
  -std=c++23                       \
  -s MEMORY64=1                    \
  -s WASM_BIGINT=1                 \
  -s STANDALONE_WASM               \
  -I"$BUILD_DIR/include"           \
  -L"$BUILD_DIR/lib-linux-wasm-64" \
  -lfmt                            \
  -O2                              \
  -o simple-test.wasm

echo ""
echo "✅ Build successful!"
echo "Output: simple-test.wasm"
echo ""
