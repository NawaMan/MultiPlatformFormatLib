#!/bin/bash
set -e


# === Input ===
ENV_PATH="$1"

# === Validate versions.env ===
if [[ ! -f "$ENV_PATH" ]]; then
  echo "❌ versions.env not found at: $ENV_PATH"
  exit 1
fi


echo "Unzipping all artifacts and removing zip files..."

for dir in build/*/; do
  echo "Processing directory: $dir"
  
  zipfile=$(find "$dir" -name "*.zip")
  
  if [[ -n "$zipfile" ]]; then
    echo "  Found zip file: $zipfile"
    unzip -o "$zipfile" -d "$dir"
    echo "  Deleting zip file: $zipfile"
    rm "$zipfile"
  else
    echo "  No zip file found in $dir"
  fi
done

echo "Done unzipping and cleaning up."


echo "Combining build outputs..."

OUTPUT_DIR="combined"
BUILD_DIR="build"

# Clean up if exists
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/lib"
mkdir -p "$OUTPUT_DIR/build-flags"

# Use the first found platform directory as the source for shared files
first_platform=$(find "$BUILD_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

# Copy shared files (headers, license, etc.)
echo "Copying shared files from: $first_platform"
cp -r "$first_platform/include" "$OUTPUT_DIR/"
cp "$first_platform/LICENSE" "$OUTPUT_DIR/"
cp "$first_platform/README.md" "$OUTPUT_DIR/"
cp "$first_platform/version.txt" "$OUTPUT_DIR/"
cp "$first_platform/versions.env" "$OUTPUT_DIR/"

# Process each platform
for dir in "$BUILD_DIR"/*/; do
    platform=$(basename "$dir")
    echo "Processing $platform..."

    # Copy build-flags.txt
    cp "$dir/build-flags.txt" "$OUTPUT_DIR/build-flags/${platform}.txt"

    # Copy lib-* directory
    libdir=$(find "$dir" -type d -name "lib-*")
    if [[ -n "$libdir" ]]; then
        cp -r "$libdir" "$OUTPUT_DIR/lib/"
    else
        echo "  Warning: No lib-* directory found for $platform"
    fi
done

echo "✅ All files combined into: $OUTPUT_DIR"


# === Parse versions ===
FMT_VERSION=$(grep '^FMT_VERSION=' "$ENV_PATH" | cut -d '=' -f2 | tr -d '[:space:]')
CLANG_VERSION=$(grep '^CLANG_VERSION=' "$ENV_PATH" | cut -d '=' -f2 | tr -d '[:space:]')

if [[ -z "$FMT_VERSION" || -z "$CLANG_VERSION" ]]; then
  echo "❌ Failed to extract FMT_VERSION or CLANG_VERSION from: $ENV_PATH"
  exit 1
fi

# === Create ZIP ===
OUTPUT_DIR="combined"
ZIP_NAME="fmt-${FMT_VERSION}_clang-${CLANG_VERSION}.zip"

echo "📦 Creating zip archive: $ZIP_NAME"

cd "$OUTPUT_DIR/.."
zip -r "$ZIP_NAME" "$(basename "$OUTPUT_DIR")"

echo "✅ Archive created: $(pwd)/$ZIP_NAME"
