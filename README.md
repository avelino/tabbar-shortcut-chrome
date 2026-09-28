# Toggle Vertical Tabs — Chrome Extension

Keyboard shortcut (`Cmd+S`) to collapse/expand the **native vertical tab bar** of Google Chrome on macOS.

Chrome doesn't expose any extension API or built-in shortcut to toggle the vertical tab strip. This extension works around that limitation by using **Native Messaging** to call an **AppleScript** that clicks the native "Collapse Tabs" / "Expand Tabs" button via macOS Accessibility.

Inspired by [this tweet from @sawyerhood](https://x.com/sawyerhood/status/2036944017146208402).

## How it works

```
Cmd+S → Chrome Extension → Native Messaging → shell script → TabbarToggle.app (AppleScript) → clicks "Collapse Tabs" button
```

1. The extension registers a keyboard shortcut via Chrome's `commands` API
2. On keypress, it sends a message to a local **native messaging host** (`com.tabbar.toggle`)
3. The host launches `TabbarToggle.app`, a compiled AppleScript, that navigates Chrome's accessibility tree and clicks the collapse/expand button
4. The button toggles between "Collapse Tabs" and "Expand Tabs" automatically

## Permissions

> **This extension requests only one permission and runs zero remote code.**

| Permission | Why | What it does |
|---|---|---|
| **`nativeMessaging`** | Required to communicate with the local shell script that performs the toggle | Allows the extension to send a JSON message to a pre-registered local process via stdio. **No network access, no tab data, no browsing history.** |

The native messaging host is a shell script that lives on your machine — you install it yourself and can read every line of it. It launches `host/TabbarToggle.app`, compiled by `install.sh` from `host/toggle.applescript`, to click a button in Chrome's UI via macOS Accessibility.

### macOS Accessibility

The AppleScript uses **System Events** to interact with Chrome's UI. macOS requires explicit permission for this:

Grant it to **TabbarToggle** (macOS asks the first time it runs):

- **macOS 27:** System Settings > Privacy & Security > Device Control and Data Access
- **macOS 26 and earlier:** System Settings > Privacy & Security > Accessibility

The AppleScript runs as its own app because macOS 27 checks `osascript` itself, not Chrome, so Chrome's grant doesn't cover it. Re-running `install.sh` rebuilds the app; if the toggle stops working afterwards, remove TabbarToggle from the list and add it again.

Without this permission the toggle silently fails.

## Requirements

- macOS (uses AppleScript + System Events)
- Google Chrome with vertical tabs enabled
- Node.js 18+ (build only)
- Accessibility permission for TabbarToggle

## Enabling vertical tabs in Chrome

If you don't have vertical tabs yet:

1. Open `chrome://flags/#vertical-tabs`
2. Set the flag to **Enabled**
3. Restart Chrome
4. Right-click the tab bar and select **"Move Tabs To The Side"**

After that the vertical tab strip appears on the left side of the window with a collapse/expand button at the top.

## Install

### 1. Build the extension

```bash
npm install
npm run build
```

### 2. Load in Chrome

1. Open `chrome://extensions`
2. Enable **Developer mode** (toggle in the top right)
3. Click **Load unpacked** and select the `dist/` folder
4. Copy the **extension ID** shown under "Toggle Vertical Tabs"

### 3. Install the native messaging host

```bash
./host/install.sh <your-extension-id>
```

This builds `host/TabbarToggle.app` and creates a manifest at `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.tabbar.toggle.json` pointing to the local `host/toggle-tabbar.sh` script. It also runs the app once, so macOS asks for Accessibility (and toggles the tab bar in the front Chrome window).

### 4. Grant Accessibility permission

Make sure **TabbarToggle** is listed and enabled under Device Control and Data Access (macOS 27) or Accessibility (macOS 26 and earlier), both in System Settings > Privacy & Security.

### 5. Use it

Press `Cmd+S` in any Chrome window to collapse or expand the vertical tab bar.

To change the shortcut: `chrome://extensions/shortcuts`.

## Scripts

| Command | Description |
|---|---|
| `npm run build` | Compile TypeScript + copy assets to `dist/` |
| `npm run watch` | Compile TypeScript in watch mode |
| `npm run typecheck` | Type-check without emitting |
| `npm run clean` | Remove `dist/` |

## Troubleshooting

**Nothing happens on Cmd+S**
- Check `chrome://extensions/shortcuts` — make sure the shortcut is registered
- Open the extension's service worker console (click "Inspect views" in `chrome://extensions`) for errors
- Verify the native host is installed: `cat ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.tabbar.toggle.json`

**"Access not allowed" or native messaging errors**
- Re-run `./host/install.sh <extension-id>` with the correct ID
- Make sure `host/toggle-tabbar.sh` is executable (`chmod +x host/toggle-tabbar.sh`)

**AppleScript does nothing**
- Grant Accessibility permission to TabbarToggle (see step 4)
- Test the app directly: `open -g -W host/TabbarToggle.app`
- Or test the AppleScript from a terminal that has Accessibility:
  ```bash
  osascript -e '
  tell application "System Events"
      tell process "Google Chrome"
          set base to group 1 of group 1 of group 1 of group 1 of window 1
          click button 1 of group 1 of UI element 3 of base
      end tell
  end tell'
  ```

**Shortcut conflicts with "Save Page"**
- Change the shortcut in `chrome://extensions/shortcuts` to something else (e.g., `Cmd+Shift+S`)

## Limitations

- **macOS only** — relies on AppleScript and System Events
- **Chrome only** — the accessibility tree path is specific to Google Chrome
- The accessibility tree structure may change across Chrome versions — if the toggle breaks after a Chrome update, run `host/discover.sh` to re-map the UI elements

## License

MIT
