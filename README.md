# Toggle Vertical Tabs — Chrome Extension

> # ⚠️ Deprecated — Chrome does this natively now
>
> Chrome has shipped a **built-in keyboard shortcut** to collapse/expand the vertical tab strip, which is the only thing this extension existed to do. This project is no longer needed and is no longer maintained.
>
> | Platform | Native shortcut |
> |---|---|
> | macOS | `Cmd` + `Shift` + `L` |
> | Windows / Linux | `Ctrl` + `Shift` + `L` |
>
> 📺 **Video showing the feature:** [Google Chrome is Testing a Highly Requested Vertical Tabs Feature](https://www.youtube.com/watch?v=gucChIlnZok)
>
> If the shortcut doesn't work, update Chrome — on older builds the toggle is still behind `chrome://flags/#vertical-tabs`.
>
> 👉 **[Jump to uninstall instructions](#uninstall--full-cleanup)** to remove the extension and every file it installed on your system.

---

Keyboard shortcut (`Ctrl+S`) to collapse/expand the **native vertical tab bar** of Google Chrome on macOS.

Chrome doesn't expose any extension API or built-in shortcut to toggle the vertical tab strip. This extension works around that limitation by using **Native Messaging** to call an **AppleScript** that clicks the native "Collapse Tabs" / "Expand Tabs" button via macOS Accessibility.

Inspired by [this tweet from @sawyerhood](https://x.com/sawyerhood/status/2036944017146208402).

> Everything below is kept for historical reference only.

## How it works

```
Ctrl+S → Chrome Extension → Native Messaging → shell script → AppleScript → clicks "Collapse Tabs" button
```

1. The extension registers a keyboard shortcut via Chrome's `commands` API
2. On keypress, it sends a message to a local **native messaging host** (`com.tabbar.toggle`)
3. The host runs an AppleScript that navigates Chrome's accessibility tree and clicks the collapse/expand button
4. The button toggles between "Collapse Tabs" and "Expand Tabs" automatically

## Permissions

> **This extension requests only one permission and runs zero remote code.**

| Permission | Why | What it does |
|---|---|---|
| **`nativeMessaging`** | Required to communicate with the local shell script that performs the toggle | Allows the extension to send a JSON message to a pre-registered local process via stdio. **No network access, no tab data, no browsing history.** |

The native messaging host is a shell script that lives on your machine — you install it yourself and can read every line of it. It runs `osascript` (AppleScript) to click a button in Chrome's UI via macOS Accessibility.

### macOS Accessibility

The AppleScript uses **System Events** to interact with Chrome's UI. macOS requires explicit permission for this:

**System Settings > Privacy & Security > Accessibility** — add Google Chrome (or your terminal, if testing manually).

Without this permission the toggle silently fails.

## Requirements

- macOS (uses AppleScript + System Events)
- Google Chrome with vertical tabs enabled
- Node.js 18+ (build only)
- Accessibility permission for Chrome

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

This creates a manifest at `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.tabbar.toggle.json` pointing to the local `host/toggle-tabbar.sh` script.

### 4. Grant Accessibility permission

**System Settings > Privacy & Security > Accessibility** — make sure Google Chrome is listed and enabled.

### 5. Use it

Press `Ctrl+S` in any Chrome window to collapse or expand the vertical tab bar.

To change the shortcut: `chrome://extensions/shortcuts`.

## Uninstall — full cleanup

Since Chrome now has a native shortcut, here's how to remove the extension and every file it put on your system. Do the steps in order.

### 1. Remove the extension from Chrome

1. Open `chrome://extensions`
2. Find **Toggle Vertical Tabs** and click **Remove**
3. Confirm

This also clears its entry in `chrome://extensions/shortcuts`, freeing up `Ctrl+S` again.

### 2. Delete the native messaging host manifest

This is the file that let Chrome launch the local shell script. Check that it's there:

```bash
ls -l ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.tabbar.toggle.json
```

Then delete it:

```bash
rm ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.tabbar.toggle.json
```

If you also loaded the extension in another Chrome channel, check those directories too:

```bash
ls -l ~/Library/Application\ Support/Google/Chrome*/NativeMessagingHosts/com.tabbar.toggle.json ~/Library/Application\ Support/Chromium/NativeMessagingHosts/com.tabbar.toggle.json
```

> Only remove `com.tabbar.toggle.json`. Other files in that folder belong to unrelated apps (Google Drive, browser extensions from other tools) and must be left alone.

### 3. Delete the standalone AppleScript (Raycast users)

If you copied `toggle-vertical-sidebar.applescript` into your Raycast script-commands folder, remove it:

```bash
rm ~/Scripts/toggle-vertical-sidebar.applescript
```

Then open Raycast → **Extensions → Script Commands** and refresh, so the stale "Toggle vertical sidebar" command disappears. If you added the script to a different folder, remove it from there instead:

```bash
find ~ -maxdepth 5 -name 'toggle-vertical-sidebar.applescript' 2>/dev/null
```

### 4. Revoke the Accessibility permission (optional)

The AppleScript needed **System Settings → Privacy & Security → Accessibility**. If you granted it *only* for this project, you can now untoggle or remove **Google Chrome** (and/or your terminal) from that list. Leave it enabled if other tools of yours rely on it.

### 5. Delete the project folder

The native host script lived inside this repo, so deleting the clone removes the last piece:

```bash
rm -rf ~/Projects/tabbar-shortcut-chrome
```

Nothing else is written outside these locations — no launch agents, no login items, no files in `/usr/local`, and no data sent anywhere.

### 6. Verify

Nothing should be found by either command:

```bash
ls ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/ | grep tabbar
```

```bash
ls ~/Scripts 2>/dev/null | grep toggle-vertical-sidebar
```

## Scripts

| Command | Description |
|---|---|
| `npm run build` | Compile TypeScript + copy assets to `dist/` |
| `npm run watch` | Compile TypeScript in watch mode |
| `npm run typecheck` | Type-check without emitting |
| `npm run clean` | Remove `dist/` |

## Troubleshooting

**Nothing happens on Ctrl+S**
- Check `chrome://extensions/shortcuts` — make sure the shortcut is registered
- Open the extension's service worker console (click "Inspect views" in `chrome://extensions`) for errors
- Verify the native host is installed: `cat ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.tabbar.toggle.json`

**"Access not allowed" or native messaging errors**
- Re-run `./host/install.sh <extension-id>` with the correct ID
- Make sure `host/toggle-tabbar.sh` is executable (`chmod +x host/toggle-tabbar.sh`)

**AppleScript does nothing**
- Grant Accessibility permission to Chrome in System Settings
- Test manually: `osascript host/toggle-tabbar.sh` won't work (it expects stdin), but you can test the AppleScript directly:
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
- Change the shortcut in `chrome://extensions/shortcuts` to something else (e.g., `Ctrl+Shift+S`)

## Limitations

- **macOS only** — relies on AppleScript and System Events
- **Chrome only** — the accessibility tree path is specific to Google Chrome
- The accessibility tree structure may change across Chrome versions — if the toggle breaks after a Chrome update, run `host/discover.sh` to re-map the UI elements

## License

MIT
