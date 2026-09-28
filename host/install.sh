#!/bin/bash
# Installs the native messaging host for Chrome
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST_NAME="com.tabbar.toggle"
HOST_SCRIPT="$SCRIPT_DIR/toggle-tabbar.sh"
MANIFEST_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
MANIFEST_PATH="$MANIFEST_DIR/$HOST_NAME.json"

# Get the extension ID from Chrome (user must provide or we use wildcard)
EXTENSION_ID="${1:-}"

if [ -z "$EXTENSION_ID" ]; then
  echo "Usage: ./install.sh <extension-id>"
  echo ""
  echo "To find your extension ID:"
  echo "  1. Go to chrome://extensions"
  echo "  2. Enable Developer mode"
  echo "  3. Copy the ID of 'Toggle Vertical Tabs'"
  exit 1
fi

# Compile the AppleScript into its own app: macOS 27 grants Accessibility to
# osascript itself, not to Chrome, so the app needs a grant of its own.
APP="$SCRIPT_DIR/TabbarToggle.app"
rm -rf "$APP"
osacompile -o "$APP" "$SCRIPT_DIR/toggle.applescript"
plutil -insert CFBundleIdentifier -string com.tabbar.toggle.applet "$APP/Contents/Info.plist"
plutil -insert LSUIElement -bool true "$APP/Contents/Info.plist"
codesign -f -s - "$APP"

mkdir -p "$MANIFEST_DIR"

cat > "$MANIFEST_PATH" <<EOF
{
  "name": "$HOST_NAME",
  "description": "Toggle Chrome vertical tab bar via AppleScript",
  "path": "$HOST_SCRIPT",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://$EXTENSION_ID/"]
}
EOF

echo "Installed native messaging host:"
echo "  Manifest: $MANIFEST_PATH"
echo "  Script:   $HOST_SCRIPT"
echo "  Extension: $EXTENSION_ID"
echo ""
echo "Grant Accessibility to TabbarToggle (it prompts on first run):"
echo "  macOS 27: System Settings > Privacy & Security > Device Control and Data Access"
echo "  macOS 26 and earlier: System Settings > Privacy & Security > Accessibility"
open -g "$APP"
