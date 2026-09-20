# Toggle Vertical Tabs — Chrome Extension

Keyboard shortcut (`Cmd+S`) to collapse/expand the **native vertical tab bar** of Google Chrome on macOS.

Chrome doesn't expose any extension API or built-in shortcut to toggle the vertical tab strip. This extension works around that limitation by using **Native Messaging** to run a small native helper that clicks the native "Collapse Tabs" / "Expand Tabs" button via macOS Accessibility.

Inspired by [this tweet from @sawyerhood](https://x.com/sawyerhood/status/2036944017146208402).

## How it works

```
Cmd+S → Chrome Extension → Native Messaging → ToggleTabbar.app → AXUIElement API → clicks "Collapse Tabs" button
```

1. The extension registers a keyboard shortcut via Chrome's `commands` API
2. On keypress, it sends a message to a local **native messaging host** (`com.tabbar.toggle`)
3. The host walks Chrome's accessibility tree and presses the collapse/expand button
4. The button toggles between "Collapse Tabs" and "Expand Tabs" automatically

The host talks to the Accessibility API directly rather than going through AppleScript. Starting `osascript` and reaching System Events costs around 130ms before any work happens; the native helper completes a press in under 10ms. It caches the button's child-index path in `~/Library/Caches/com.tabbar.toggle.path`, re-verifying on each press that the path still lands on the toggle button, and falling back to a full tree search if a Chrome update moves it.

## Permissions

> **This extension requests only one permission and runs zero remote code.**

| Permission | Why | What it does |
|---|---|---|
| **`nativeMessaging`** | Required to communicate with the local helper that performs the toggle | Allows the extension to send a JSON message to a pre-registered local process via stdio. **No network access, no tab data, no browsing history.** |

The native messaging host is built from source on your machine — you can read every line of `host/native/main.swift`. It reads the tab strip's accessibility tree and presses one button.

### macOS Accessibility

Reading another application's accessibility tree requires explicit permission. macOS grants this per code identity, which is why `host/build-native.sh` wraps the binary in an ad-hoc signed app bundle: an unsigned binary is identified by its cdhash, so the grant would silently die on every rebuild while the settings pane still showed it enabled.

The first keypress triggers the system prompt. To reset the grant later:

```bash
tccutil reset Accessibility com.tabbar.toggle
```

## Requirements

- macOS (uses the Accessibility API)
- Google Chrome with vertical tabs enabled
- Node.js 18+ and the Xcode command line tools (build only)

## Enabling vertical tabs in Chrome

If you don't have vertical tabs yet:

1. Open `chrome://flags/#vertical-tabs`
2. Set the flag to **Enabled**
3. Restart Chrome
4. Right-click the tab bar and select **"Move Tabs To The Side"**

After that the vertical tab strip appears on the left side of the window with a collapse/expand button at the top.

## Install

### 1. Build

```bash
npm install
npm run build          # extension → dist/
./host/build-native.sh # native host → host/ToggleTabbar.app
```

### 2. Load the extension in Chrome

1. Open `chrome://extensions`
2. Enable **Developer mode** (toggle in the top right)
3. Click **Load unpacked** and select the `dist/` folder
4. Copy the **extension ID** shown under "Toggle Vertical Tabs"

### 3. Register the native messaging host

```bash
./host/install.sh <your-extension-id>
```

This writes a manifest to `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.tabbar.toggle.json` pointing at the app bundle.

### 4. Bind the shortcut

Chrome reserves `Cmd+S` for Save Page, so it won't take the suggested binding automatically. Open `chrome://extensions/shortcuts`, find **Toggle Vertical Tabs**, click the field and press `Cmd+S`. A manual binding overrides Save Page.

Note that in Chrome's `commands` API, `"Ctrl"` means Command on macOS — the actual Control key is `"MacCtrl"`.

### 5. Use it

Press `Cmd+S` in any Chrome window. The first press raises the Accessibility prompt; approve it and press again.

### Where to install

The host has to be built and signed on the machine that runs Chrome, since its Accessibility grant is tied to the local code identity and does not travel with a copied binary.

## Scripts

| Command | Description |
|---|---|
| `npm run build` | Compile TypeScript + copy assets to `dist/` |
| `npm run watch` | Compile TypeScript in watch mode |
| `npm run typecheck` | Type-check without emitting |
| `npm run clean` | Remove `dist/` |
| `./host/build-native.sh` | Build and sign the native messaging host |
| `./host/install.sh <extension-id>` | Register the host with Chrome |

## Troubleshooting

**Nothing happens on the shortcut**
- Check `chrome://extensions/shortcuts` — if the field is blank, Chrome refused the binding as a conflict. Set it manually.
- Open the extension's service worker console ("Inspect views" in `chrome://extensions`) for native host errors

**It keeps asking for Accessibility permission**
- Remove any stale entries in **System Settings > Privacy & Security > Accessibility**, then `tccutil reset Accessibility com.tabbar.toggle` and press the shortcut again
- Rebuilding the host changes its signature, so the grant may need re-approving

**Toggle button not found**
- The helper searches the accessibility tree by button label, so it survives most Chrome updates. If it still fails, confirm the vertical tab strip is actually visible.

## Testing the host directly

Run the binary with no input; without a native message frame it performs one toggle and reports errors on stderr:

```bash
./host/ToggleTabbar.app/Contents/MacOS/toggle-tabbar
```

Accessibility is granted per calling process, so a run from your terminal needs your terminal granted too — separate from the grant Chrome's spawned copy uses.

## Limitations

- **macOS only** — relies on the macOS Accessibility API
- **Chrome only** — looks for Chrome's specific button labels

## License

MIT
