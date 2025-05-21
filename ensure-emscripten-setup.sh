#!/bin/bash

set -e

print_section() {
    echo ""
    echo "===== $1 ====="
    echo ""
}

tool-version() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        echo "not_installed"
        return
    fi
    local version
    version=$( "$cmd" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1 )
    [[ -z "$version" ]] && echo "not_installed" || echo "$version"
}

# Load version
if [[ ! -f versions.env ]]; then
    echo "Error: versions.env not found"
    exit 1
fi

ENSDK_VERSION=$(grep ^ENSDK_VERSION versions.env | cut -d= -f2)

if [[ -z "$ENSDK_VERSION" ]]; then
    echo "Error: ENSDK_VERSION not set in versions.env"
    exit 1
fi

EMSDK_ROOT="/opt/emsdk"

print_section "Installing Emscripten SDK ($ENSDK_VERSION) to $EMSDK_ROOT"

# Clone emsdk into /opt
if [[ ! -d "$EMSDK_ROOT" ]]; then
    git clone https://github.com/emscripten-core/emsdk.git "$EMSDK_ROOT"
fi

cd "$EMSDK_ROOT"
git pull --rebase
./emsdk install "$ENSDK_VERSION"
./emsdk activate "$ENSDK_VERSION"

# Source environment (for current shell)
source "$EMSDK_ROOT/emsdk_env.sh"

# Generate config
[[ ! -f ~/.emscripten ]] && emcc --generate-config || true

print_section "Creating global wrapper scripts in /usr/local/bin"

TOOLS=("emcc" "em++" "emar" "emranlib" "wasm-opt")

for tool in "${TOOLS[@]}"; do
    WRAPPER_PATH="/usr/local/bin/$tool"
    echo "#!/bin/bash"                       | sudo tee "$WRAPPER_PATH" > /dev/null
    echo "source $EMSDK_ROOT/emsdk_env.sh > /dev/null 2>&1" | sudo tee -a "$WRAPPER_PATH" > /dev/null
    echo "exec $tool \"\$@\""               | sudo tee -a "$WRAPPER_PATH" > /dev/null
    sudo chmod +x "$WRAPPER_PATH"
    echo "Installed wrapper: $WRAPPER_PATH"
done

print_section "Emscripten Setup Complete"

echo "Emscripten $ENSDK_VERSION installed in $EMSDK_ROOT"
echo "Global wrappers installed for: ${TOOLS[*]}"
echo ""
echo "To use manually in other sessions, run:"
echo "    source $EMSDK_ROOT/emsdk_env.sh"
