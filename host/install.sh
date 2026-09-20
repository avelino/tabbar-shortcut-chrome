#!/bin/bash
# Registers the native messaging host with Chrome.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST_NAME="com.tabbar.toggle"
# Point at the executable inside the bundle so macOS reads its code identity.
HOST_BIN="$SCRIPT_DIR/ToggleTabbar.app/Contents/MacOS/toggle-tabbar"
MANIFEST_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"

EXTENSION_ID="${1:-}"
if [ -z "$EXTENSION_ID" ]; then
  echo "Usage: ./install.sh <extension-id>   (find it at chrome://extensions)"
  exit 1
fi
if [ ! -x "$HOST_BIN" ]; then
  echo "Missing $HOST_BIN — run ./host/build-native.sh first."
  exit 1
fi

mkdir -p "$MANIFEST_DIR"
cat > "$MANIFEST_DIR/$HOST_NAME.json" <<EOF
{
  "name": "$HOST_NAME",
  "description": "Toggle Chrome vertical tab bar",
  "path": "$HOST_BIN",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://$EXTENSION_ID/"]
}
EOF

echo "Installed $MANIFEST_DIR/$HOST_NAME.json -> $HOST_BIN"
echo "Press the shortcut once and approve the Accessibility prompt."
