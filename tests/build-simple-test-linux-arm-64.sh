#!/bin/bash

set -e

BUILD_DIR=$(pwd)/build
DIST_FILE=$1
DIST_DIR=${DIST_FILE%/*}

if [ "$DIST_FILE" == "" ]; then
    echo "Usage: $0 <dist-file>"
    exit 1
fi

rm    -Rf "$BUILD_DIR"
mkdir -p  "$BUILD_DIR"
unzip     "$DIST_FILE" -d "$BUILD_DIR"


echo "Compiling..."
echo "BUILD_DIR: $BUILD_DIR"

clang++ simple-test.cpp           \
  -std=c++23                      \
  -I"$BUILD_DIR/include"          \
  -L"$BUILD_DIR/lib-linux-arm-64" \
  -lfmt                           \
  -O2                             \
  -flto                           \
  -ffunction-sections             \
  -fdata-sections                 \
  -Wl,--gc-sections               \
  -o simple-test

echo ""
echo "Success!"
echo ""

echo "Test are ready to run: ./simple-test"
echo ""
