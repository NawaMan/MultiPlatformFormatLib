#!/bin/bash

TARGET_DIR="$1"
COMPILER_NAME="$2"
COMPILER_VERSION="$3"
TARGET_OS="$4"
ARCH="$5"
FLAGS="$6"
LINK_FLAGS="$7"

cat > "$TARGET_DIR/build-flags.txt" <<EOF
# Build Flags
CFLAGS   = $FLAGS
CXXFLAGS = $FLAGS
LDFLAGS  = $LINK_FLAGS
Compiler = $COMPILER_NAME $COMPILER_VERSION
Target   = $TARGET_OS $ARCH
EOF

cat > "$TARGET_DIR/README.md" <<EOF
# fmt ${FMT_VERSION} ($TARGET_OS $ARCH, $COMPILER_NAME $COMPILER_VERSION)

This archive contains a statically compiled build of the [fmt](https://github.com/fmtlib/fmt) library.

## Build Info

- Compiler: $COMPILER_NAME $COMPILER_VERSION
- Target:   $TARGET_OS $ARCH
- CFLAGS:   $FLAGS
- CXXFLAGS: $FLAGS
- LDFLAGS:  $LINK_FLAGS

## Contents

- include/: Header files
- lib/: Static libraries
- version.txt, LICENSE, build-flags.txt: Metadata

---
Generated on $(date)
EOF
