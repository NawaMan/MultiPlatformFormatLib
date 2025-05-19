#!/bin/bash

set -e

BUILD_DIR=$(pwd)/build
DIST_FILE=$1
DIST_DIR=${DIST_FILE%/*}

if [ -z "$DIST_FILE" ]; then
    echo "Usage: $0 <dist-file>"
    exit 1
fi

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
unzip "$DIST_FILE" -d "$BUILD_DIR"

echo "Compiling for macOS Universal (x86_64 + arm64)..."
echo "BUILD_DIR: $BUILD_DIR"

OUTPUT_NAME=simple-test
OUTPUT_X86="$BUILD_DIR/${OUTPUT_NAME}_x86_64"
OUTPUT_ARM="$BUILD_DIR/${OUTPUT_NAME}_arm_64"
OUTPUT_UNIVERSAL="./${OUTPUT_NAME}"

# ✅ Use Apple Clang
export CXX=/usr/bin/clang++

# ✅ Use macOS SDK
SDKROOT=$(xcrun --sdk macosx --show-sdk-path)

COMMON_FLAGS_X86="-std=c++2b -isysroot $SDKROOT -I$BUILD_DIR/include -L$BUILD_DIR/lib -lfmt -O2 -ffunction-sections -fdata-sections"
COMMON_FLAGS_ARM="-std=c++2b -isysroot $SDKROOT -I$BUILD_DIR/include -L$BUILD_DIR/lib -lfmt -O2 -ffunction-sections -fdata-sections"
LINK_FLAGS="-Wl,-dead_strip"

$CXX -arch x86_64 $COMMON_FLAGS_X86 $LINK_FLAGS simple-test.cpp -o "$OUTPUT_X86"
$CXX -arch arm64  $COMMON_FLAGS_ARM $LINK_FLAGS simple-test.cpp -o "$OUTPUT_ARM"

echo "Creating universal binary with lipo..."
lipo -create -output "$OUTPUT_UNIVERSAL" "$OUTPUT_X86" "$OUTPUT_ARM"

echo "BUILD_DIR: $BUILD_DIR"
ls -la "$BUILD_DIR"

echo "OUTPUT_UNIVERSAL: $OUTPUT_UNIVERSAL"
ls -la "$OUTPUT_UNIVERSAL"

echo ""
echo "✅ Success!"
echo "Test binary created: $OUTPUT_UNIVERSAL"
echo ""
echo "Run the test with: ./simple-test"
echo ""
