#!/bin/bash

set -e
# set -x

DIST_DIR=${1:-$(pwd)/dist}

PROJECT_DIR=$(pwd)
BUILD_DIR="$PROJECT_DIR/build/build-wasm64"
BUILD_LOG="$BUILD_DIR/build.log"

mkdir -p "$BUILD_DIR"
touch    "$BUILD_LOG"

source versions.env
source sh-sources/common-source.sh
source sh-sources/src-common.sh

print_section "Checking Emscripten Environment"

EMCC=/usr/local/bin/emcc
if ! command -v "$EMCC" &>/dev/null; then
    exit_with_error "emcc not found in PATH. Please source emsdk_env.sh or install Emscripten."
fi

EMCC_VERSION=$("$EMCC" --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
print_status "Emscripten version: $EMCC_VERSION"

print_section "Downloading Source ${FMT_VERSION}"
./prepare-src.sh "$BUILD_DIR"

print_section "Building fmt for WASM64"

SOURCE_DIR="$BUILD_DIR/fmt-source/fmt-${FMT_VERSION}"
TARGET_DIR="$BUILD_DIR/fmt-target"

OPT_FLAGS="-O2 -flto -ffunction-sections -fdata-sections -fPIC"
LINK_FLAGS="-Wl,--gc-sections"

source /opt/emsdk/emsdk_env.sh

export EM_CACHE="$BUILD_DIR/.emscripten_cache"
mkdir -p "$EM_CACHE"

mkdir -p "$SOURCE_DIR/build"
cd "$SOURCE_DIR/build"

emcmake cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" \
  -DFMT_DOC=OFF \
  -DFMT_TEST=OFF \
  -DFMT_INSTALL=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_CXX_FLAGS="-s MEMORY64=1 -s WASM_BIGINT=1 $OPT_FLAGS" \
  -DCMAKE_EXE_LINKER_FLAGS="$LINK_FLAGS" \
#   >> "$BUILD_LOG" 2>&1

emmake make -j$(nproc) #>> "$BUILD_LOG" 2>&1
emmake make install    #>> "$BUILD_LOG" 2>&1

# Rename lib directory to lib-linux-wasm64
mv "$TARGET_DIR/lib" "$TARGET_DIR/lib-linux-wasm64"

print_section "Packaging..."
mkdir -p "$DIST_DIR"
BUILD_ZIP="$DIST_DIR/fmt-${FMT_VERSION}_wasm64_emscripten-${ENSDK_VERSION}.zip"

cp "$PROJECT_DIR/version.txt"   "$TARGET_DIR"
cp "$PROJECT_DIR/versions.env"  "$TARGET_DIR"
cp "$PROJECT_DIR/LICENSE"       "$TARGET_DIR"
cp "$PROJECT_DIR/README.md"     "$TARGET_DIR"

"$PROJECT_DIR/write-build-metadata.sh" \
    "$TARGET_DIR"                      \
    "Emscripten"                       \
    "$EMCC_VERSION"                    \
    "WASM"                             \
    "wasm64"                           \
    "$OPT_FLAGS"                       \
    "$LINK_FLAGS"

cd "$TARGET_DIR"
pwd
tree

zip -r "$BUILD_ZIP" . >> "$BUILD_LOG"
chmod 777 "$BUILD_ZIP"

if [ -f "$BUILD_ZIP" ]; then
    print_status "Build succeeded!"
    print "File: $BUILD_ZIP"
    print "Size: $(du -h "$BUILD_ZIP" | cut -f1)"
else
    exit_with_error "Build failed!"
fi
