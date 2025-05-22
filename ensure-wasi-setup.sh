#!/bin/bash

set -e

print_section() {
    echo ""
    echo "===== $1 ====="
    echo ""
}

# Load version
if [[ ! -f versions.env ]]; then
    echo "Error: versions.env not found"
    exit 1
fi

WASI_VERSION=$(grep ^WASI_SDK_VERSION versions.env | cut -d= -f2)

if [[ -z "$WASI_VERSION" ]]; then
    echo "Error: WASI_SDK_VERSION not set in versions.env"
    exit 1
fi

WASI_ROOT="/opt/wasi-sdk"
WASI_RELEASE="wasi-sdk-${WASI_VERSION}"
WASI_VERSION=20.0
WASI_TAG="wasi-sdk-$(echo "$WASI_VERSION" | cut -d. -f1)"  # => wasi-sdk-20
WASI_FILENAME="wasi-sdk-${WASI_VERSION}-linux.tar.gz"      # => wasi-sdk-20.0-linux.tar.gz
WASI_URL="https://github.com/WebAssembly/wasi-sdk/releases/download/${WASI_TAG}/${WASI_FILENAME}"



print_section "Installing WASI SDK ${WASI_VERSION} to ${WASI_ROOT}"

if [[ ! -d "$WASI_ROOT" ]]; then
    wget "$WASI_URL" -O /tmp/${WASI_RELEASE}.tar.gz
    sudo mkdir -p "$WASI_ROOT"
    sudo tar -xzf /tmp/${WASI_RELEASE}.tar.gz -C /opt
    sudo mv /opt/${WASI_RELEASE}/* "$WASI_ROOT"
    rm /tmp/${WASI_RELEASE}.tar.gz
else
    echo "WASI SDK already installed at $WASI_ROOT"
fi

print_section "Creating global wrapper scripts in /usr/local/bin"

TOOLS=("clang" "clang++" "wasm-ld" "llvm-ar" "llvm-ranlib")

for tool in "${TOOLS[@]}"; do
    WRAPPER_PATH="/usr/local/bin/wasi-${tool}"
    TOOL_PATH="$WASI_ROOT/bin/${tool}"

    if [[ -f "$TOOL_PATH" ]]; then
        echo "#!/bin/bash"                       | sudo tee "$WRAPPER_PATH" > /dev/null
        echo "exec $TOOL_PATH \"\$@\""           | sudo tee -a "$WRAPPER_PATH" > /dev/null
        sudo chmod +x "$WRAPPER_PATH"
        echo "Installed wrapper: $WRAPPER_PATH"
    else
        echo "Warning: Tool not found: $TOOL_PATH"
    fi
done

print_section "WASI Setup Complete"

echo "WASI SDK ${WASI_VERSION} installed in ${WASI_ROOT}"
echo "Global wrappers installed as: wasi-clang, wasi-clang++, etc."
