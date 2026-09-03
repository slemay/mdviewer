#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Ensure app is built
"${SCRIPT_DIR}/build_app.sh"

APP_PATH="${ROOT_DIR}/build/MDViewer.app"
TARGET_DIR="${HOME}/.local/bin"
CLI_TARGET="${TARGET_DIR}/mdviewer"

mkdir -p "${TARGET_DIR}"

cat << EOF > "${CLI_TARGET}"
#!/usr/bin/env bash
APP="${APP_PATH}"

if [ \$# -eq 0 ]; then
    open "\${APP}"
else
    for file in "\$@"; do
        FULL_PATH="\$(cd "\$(dirname "\$file")" 2>/dev/null && pwd)/\$(basename "\$file")"
        if [ -f "\${FULL_PATH}" ]; then
            open -a "\${APP}" "\${FULL_PATH}"
        else
            echo "File not found: \$file"
        fi
    done
fi
EOF

chmod +x "${CLI_TARGET}"

echo "==> CLI installed at: ${CLI_TARGET}"
echo "    Make sure ${TARGET_DIR} is in your PATH."
echo "    Usage: mdviewer [path/to/file.md]"
