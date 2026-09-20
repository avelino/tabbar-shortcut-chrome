#!/bin/bash
# Compiles the native messaging host into a signed app bundle.
#
# The bundle is not cosmetic: macOS keys an Accessibility grant to the code
# identity of the calling process. A bare unsigned binary is identified by its
# cdhash, which changes on every rebuild, so the grant silently dies while the
# settings pane still shows it enabled. A stable ad-hoc identity avoids that.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUNDLE_ID="com.tabbar.toggle"
APP="$SCRIPT_DIR/ToggleTabbar.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>toggle-tabbar</string>
	<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
	<key>CFBundleName</key><string>Toggle Tabbar</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

swiftc -O -o "$APP/Contents/MacOS/toggle-tabbar" "$SCRIPT_DIR/native/main.swift" \
  -framework AppKit -framework ApplicationServices
codesign --force --sign - --identifier "$BUNDLE_ID" "$APP"

# Registering lets the settings pane name the entry and `tccutil reset
# Accessibility com.tabbar.toggle` clear it.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

echo "Built $APP"
