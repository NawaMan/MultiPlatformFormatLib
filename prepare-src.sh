#!/bin/bash

BUILD_DIR=${1:-$(pwd)/build}
BUILD_LOG=$BUILD_DIR/build.log

mkdir -p "$BUILD_DIR"
touch    "$BUILD_LOG"

source versions.env
source sh-sources/common-source.sh
source sh-sources/src-common.sh

FMT_ZIP=$BUILD_DIR/fmt-source.zip
download-src $FMT_VERSION $FMT_ZIP
extract-src  $FMT_ZIP     $BUILD_DIR/fmt-source
rm $FMT_ZIP
