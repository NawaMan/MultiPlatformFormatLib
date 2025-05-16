#!/bin/bash

set -e
set -x

DIST_DIR=${1:-$(pwd)/dist}

PROJECT_DIR=$(pwd)
BUILD_DIR="$PROJECT_DIR/build/build-linux-x86-64"
BUILD_LOG="$BUILD_DIR/build.log"

mkdir -p "$BUILD_DIR"
touch    "$BUILD_LOG"

source versions.env
source sh-sources/common-source.sh
source sh-sources/src-common.sh

print "Clang       version: $(clang       --version)"
print "Clang++     version: $(clang++     --version)"
print "LLVM-ar     version: $(llvm-ar     --version)"
print "LLVM-ranlib version: $(llvm-ranlib --version)"

print_section "Check compiler version"
ACTUAL_CLANG_VERSION=$(clang --version | grep -o 'clang version [0-9]\+' | awk '{print $3}')
if [[ $BUILD_CLANG == "true" && $IGNORE_COMPILER_VERSION -eq 0 ]]; then
  if [[ "${ACTUAL_CLANG_VERSION%%.*}" != "$CLANG_VERSION" ]]; then
    exit_with_error "Clang version $CLANG_VERSION.x required, found $ACTUAL_CLANG_VERSION."
  fi
fi

print_status "Clang version: $ACTUAL_CLANG_VERSION"


print_section "Downloading Source ${FMT_VERSION}"
./prepare-src.sh "$BUILD_DIR"

print_section "Building fmt"

SOURCE_DIR="$BUILD_DIR/fmt-source/fmt-${FMT_VERSION}"
TARGET_DIR="$BUILD_DIR/fmt-target"

export CC=clang
export CXX=clang++

OPT_FLAGS="-O2 -flto -ffunction-sections -fdata-sections -fPIC"

mkdir -p "$SOURCE_DIR/build"
cd "$SOURCE_DIR/build"

CFLAGS="$OPT_FLAGS" \
CXXFLAGS="$OPT_FLAGS" \
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" \
    -DFMT_DOC=OFF \
    -DFMT_TEST=OFF \
    -DFMT_INSTALL=ON \
    -DBUILD_SHARED_LIBS=OFF \
    >> "$BUILD_LOG" 2>&1

make -j$(nproc) >> "$BUILD_LOG" 2>&1
make install    >> "$BUILD_LOG" 2>&1

print_section "Packaging"
mkdir -p "$DIST_DIR"
BUILD_ZIP="$DIST_DIR/fmt-${FMT_VERSION}_linux-x86-64_clang-${CLANG_VERSION}.zip"

cp "$PROJECT_DIR/version.txt"  "$TARGET_DIR"
cp "$PROJECT_DIR/versions.env" "$TARGET_DIR"
cp "$PROJECT_DIR/LICENSE"      "$TARGET_DIR"
cp "$PROJECT_DIR/README.md"    "$TARGET_DIR"

cd "$TARGET_DIR"
zip -r "$BUILD_ZIP" . >> "$BUILD_LOG"
chmod 777 "$BUILD_ZIP"

if [ -f "$BUILD_ZIP" ]; then
    print_status "Build succeeded!"
    print "File: $BUILD_ZIP"
    print "Size: $(du -h "$BUILD_ZIP" | cut -f1)"
else
    exit_with_error "Build failed!"
fi
