#!/bin/bash

set -e
# set -x

DIST_DIR=${1:-$(pwd)/dist}

PROJECT_DIR=$(pwd)
BUILD_DIR="$PROJECT_DIR/build/build-macos-universal"
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

ARCHS=("x86_64" "arm64")
UNIVERSAL_TARGET_DIR="$BUILD_DIR/fmt-universal"
UNIVERSAL_LIB_NAME="libfmt.a"
UNIVERSAL_LIB_PATH="$UNIVERSAL_TARGET_DIR/lib/$UNIVERSAL_LIB_NAME"

LIB_PATHS=()

for ARCH in "${ARCHS[@]}"; do
    print_section "Building fmt for $ARCH"

    SOURCE_DIR="$BUILD_DIR/fmt-source/fmt-${FMT_VERSION}"
    TARGET_DIR="$BUILD_DIR/fmt-target-$ARCH"
    BUILD_SUBDIR="$SOURCE_DIR/build-$ARCH"

    export CC=clang
    export CXX=clang++

    OPT_FLAGS="-O2 -flto -ffunction-sections -fdata-sections -fPIC -arch $ARCH"
    LINK_FLAGS="-Wl,-dead_strip"

    mkdir -p "$BUILD_SUBDIR"
    cd "$BUILD_SUBDIR"

    CFLAGS="$OPT_FLAGS"                      \
    CXXFLAGS="$OPT_FLAGS"                    \
    LDFLAGS="$LINK_FLAGS"                    \
    cmake ..                                 \
        -DCMAKE_BUILD_TYPE=Release           \
        -DCMAKE_INSTALL_PREFIX="$TARGET_DIR" \
        -DFMT_DOC=OFF                        \
        -DFMT_TEST=OFF                       \
        -DFMT_INSTALL=ON                     \
        -DBUILD_SHARED_LIBS=OFF              \
        >> "$BUILD_LOG" 2>&1

    make -j$(sysctl -n hw.logicalcpu) >> "$BUILD_LOG" 2>&1
    make install                       >> "$BUILD_LOG" 2>&1

    LIB_PATHS+=("$TARGET_DIR/lib/$UNIVERSAL_LIB_NAME")
done

print_section "Creating macOS Universal Binary"
mkdir -p "$UNIVERSAL_TARGET_DIR/lib"

lipo -create -output "$UNIVERSAL_LIB_PATH" "${LIB_PATHS[@]}"

print_section "Packaging..."
mkdir -p "$DIST_DIR"
BUILD_ZIP="$DIST_DIR/fmt-${FMT_VERSION}_macos-universal_clang-${CLANG_VERSION}.zip"

cp "$PROJECT_DIR/version.txt"  "$UNIVERSAL_TARGET_DIR"
cp "$PROJECT_DIR/versions.env" "$UNIVERSAL_TARGET_DIR"
cp "$PROJECT_DIR/LICENSE"      "$UNIVERSAL_TARGET_DIR"
cp "$PROJECT_DIR/README.md"    "$UNIVERSAL_TARGET_DIR"

"$PROJECT_DIR/write-build-metadata.sh" \
    "$UNIVERSAL_TARGET_DIR"            \
    "Clang"                            \
    "$ACTUAL_CLANG_VERSION"            \
    "macOS"                            \
    "universal"                        \
    "-arch x86_64/arm64 $OPT_FLAGS"    \
    "$LINK_FLAGS"

cd "$UNIVERSAL_TARGET_DIR"
zip -r "$BUILD_ZIP" . >> "$BUILD_LOG"
chmod 777 "$BUILD_ZIP"

if [ -f "$BUILD_ZIP" ]; then
    print_status "Build succeeded!"
    print "File: $BUILD_ZIP"
    print "Size: $(du -h "$BUILD_ZIP" | cut -f1)"
else
    exit_with_error "Build failed!"
fi
