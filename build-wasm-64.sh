#!/bin/bash

set -e
# set -x

DIST_DIR=${1:-$(pwd)/dist}
PROJECT_DIR=$(pwd)
BUILD_DIR="$PROJECT_DIR/build/build-wasi-wasm64"
BUILD_LOG="$BUILD_DIR/build.log"

mkdir -p "$BUILD_DIR"
touch "$BUILD_LOG"

source versions.env
source sh-sources/common-source.sh
source sh-sources/src-common.sh

print_section "Checking WASI SDK Environment"

WASI_CLANG=/usr/local/bin/wasi-clang
WASI_CXX=/usr/local/bin/wasi-clang++
if ! command -v "$WASI_CXX" &>/dev/null; then
    exit_with_error "wasi-clang++ not found in PATH. Run ensure-wasi-setup.sh first."
fi

WASI_VERSION=$("$WASI_CXX" --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
print_status "WASI Clang version: $WASI_VERSION"

print_section "Downloading Source ${FMT_VERSION}"
./prepare-src.sh "$BUILD_DIR"

print_section "Building fmt for WASM64 (WASI)"

SOURCE_DIR="$BUILD_DIR/fmt-source/fmt-${FMT_VERSION}"
TARGET_DIR="$BUILD_DIR/fmt-target"

OPT_FLAGS="-O2 -flto -ffunction-sections -fdata-sections -fPIC"
LINK_FLAGS="-Wl,--gc-sections"

mkdir -p "$SOURCE_DIR/build"
cd "$SOURCE_DIR/build"

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" \
  -DCMAKE_C_COMPILER=wasi-clang \
  -DCMAKE_CXX_COMPILER=wasi-clang++ \
  -DCMAKE_SYSTEM_NAME=Generic \
  -DCMAKE_SYSTEM_PROCESSOR=wasm64 \
  -DCMAKE_CXX_FLAGS="--target=wasm64-wasi $OPT_FLAGS" \
  -DCMAKE_EXE_LINKER_FLAGS="$LINK_FLAGS" \
  -DFMT_DOC=OFF \
  -DFMT_TEST=OFF \
  -DFMT_INSTALL=ON \
  -DBUILD_SHARED_LIBS=OFF \
  # >> "$BUILD_LOG" 2>&1

make -j$(nproc) # >> "$BUILD_LOG" 2>&1
make install    # >> "$BUILD_LOG" 2>&1

# Rename lib directory
mv "$TARGET_DIR/lib" "$TARGET_DIR/lib-linux-wasi-wasm64"

print_section "Packaging..."
mkdir -p "$DIST_DIR"
BUILD_ZIP="$DIST_DIR/fmt-${FMT_VERSION}_wasi-wasm64_clang-${WASI_VERSION}.zip"

cp "$PROJECT_DIR/version.txt"  "$TARGET_DIR"
cp "$PROJECT_DIR/versions.env" "$TARGET_DIR"
cp "$PROJECT_DIR/LICENSE"      "$TARGET_DIR"
cp "$PROJECT_DIR/README.md"    "$TARGET_DIR"

"$PROJECT_DIR/write-build-metadata.sh" \
    "$TARGET_DIR"                      \
    "WASI"                             \
    "$WASI_VERSION"                    \
    "WASM"                             \
    "wasm-64"                          \
    "$OPT_FLAGS"                       \
    "$LINK_FLAGS"

cd "$TARGET_DIR"
tree

zip -r "$BUILD_ZIP" . # >> "$BUILD_LOG"
chmod 777 "$BUILD_ZIP"

if [ -f "$BUILD_ZIP" ]; then
    print_status "Build succeeded!"
    print "File: $BUILD_ZIP"
    print "Size: $(du -h "$BUILD_ZIP" | cut -f1)"
else
    exit_with_error "Build failed!"
fi
