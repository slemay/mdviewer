#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

CONFIGURATION="release"
if [[ "${1:-}" == "--debug" ]]; then
    CONFIGURATION="debug"
fi

echo "==> Building MDViewer binary (${CONFIGURATION})..."
cd "${ROOT_DIR}"
swift build -c "${CONFIGURATION}"

BUILD_DIR="${ROOT_DIR}/.build/${CONFIGURATION}"
APP_DIR="${ROOT_DIR}/build/MDViewer.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Constructing MDViewer.app bundle..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

# 1. Copy executable
cp "${BUILD_DIR}/mdviewer" "${MACOS_DIR}/MDViewer"
chmod +x "${MACOS_DIR}/MDViewer"

# 2. Copy Info.plist
cp "${ROOT_DIR}/Info.plist" "${CONTENTS_DIR}/Info.plist"

# 3. Copy direct resources
cp -R "${ROOT_DIR}/Sources/MDViewer/Resources/"* "${RESOURCES_DIR}/"

# 4. Copy SPM module bundles if present
if compgen -G "${BUILD_DIR}/*.bundle" > /dev/null; then
    cp -R "${BUILD_DIR}/"*.bundle "${RESOURCES_DIR}/"
fi

# 5. Ad-hoc codesign
echo "==> Signing application bundle..."
codesign --force --deep --sign - "${APP_DIR}"

echo "==> Success! Application bundle created at: ${APP_DIR}"
echo "    You can run it with: open \"${APP_DIR}\""
echo "    Or test with a file: open -a \"${APP_DIR}\" path/to/file.md"
