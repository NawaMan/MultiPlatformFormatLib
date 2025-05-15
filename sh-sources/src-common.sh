
# SOURCE ME - DO NOT RUN

download-src() {
    SRC_VERSION=$1
    SRC_FILE=$2

    if [ "$SRC_VERSION" == "" ]; then
        exit_with_error "SRC_VERSION is not set!"
    fi

    print "Ensure source"
    if [ ! -f "$SRC_FILE" ]; then
        SRC_URL="https://github.com/fmtlib/fmt/archive/refs/tags/$SRC_VERSION.zip"
        print "📥 Downloading SRC..."
        curl -L -o $SRC_FILE "$SRC_URL"
        print ""
    fi
}

extract-src() {
    SRC_FILE=$1
    SRC_DIR=$2

    print "📦 Extracting source to $SRC_DIR ..."
    rm -rf $SRC_DIR
    mkdir $SRC_DIR
    pushd $SRC_DIR 1> /dev/null

    unzip $SRC_FILE

    popd 1> /dev/null

    echo "END: extract-src"
}