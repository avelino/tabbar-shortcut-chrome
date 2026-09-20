import AppKit
import ApplicationServices

// Native messaging host for the Toggle Vertical Tabs extension.
//
// Clicks Chrome's collapse/expand button through the AXUIElement C API. The
// AppleScript equivalent costs ~130ms per press just to start osascript and
// reach System Events; going direct keeps a press under 10ms.

let cachePath = NSString(string: "~/Library/Caches/com.tabbar.toggle.path").expandingTildeInPath
let labels: Set<String> = ["collapse tabs", "expand tabs"]

func attr(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
}

func children(of element: AXUIElement) -> [AXUIElement] {
    attr(element, kAXChildrenAttribute as String) as? [AXUIElement] ?? []
}

func role(of element: AXUIElement) -> String {
    attr(element, kAXRoleAttribute as String) as? String ?? ""
}

/// Chrome exposes the label as title on some builds and description on others.
func isToggle(_ element: AXUIElement) -> Bool {
    guard role(of: element) == kAXButtonRole as String else { return false }
    return [kAXTitleAttribute as String, kAXDescriptionAttribute as String].contains {
        (attr(element, $0) as? String).map { labels.contains($0.lowercased()) } ?? false
    }
}

func findPath(_ element: AXUIElement, depth: Int) -> [Int]? {
    // These subtrees hold page content and never the tab strip chrome.
    if ["AXWebArea", kAXScrollAreaRole as String].contains(role(of: element)) { return nil }
    if isToggle(element) { return [] }
    guard depth < 12 else { return nil }
    for (index, child) in children(of: element).enumerated() {
        if let sub = findPath(child, depth: depth + 1) { return [index] + sub }
    }
    return nil
}

func walk(_ root: AXUIElement, _ path: [Int]) -> AXUIElement? {
    path.reduce(root as AXUIElement?) { element, index in
        element.flatMap { children(of: $0).indices.contains(index) ? children(of: $0)[index] : nil }
    }
}

func toggle() -> String? {
    guard let chrome = NSWorkspace.shared.runningApplications
        .first(where: { $0.bundleIdentifier == "com.google.Chrome" }) else {
        return "Chrome is not running"
    }

    let app = AXUIElementCreateApplication(chrome.processIdentifier)
    AXUIElementSetMessagingTimeout(app, 2.0)

    guard let windows = attr(app, kAXWindowsAttribute as String) as? [AXUIElement] else {
        // The AppleScript route borrowed System Events' rights; the direct API is
        // checked against this bundle. Prompt so it lands in the settings pane.
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        return "no accessibility permission"
    }
    guard let window = windows.first(where: {
        (attr($0, kAXTitleAttribute as String) as? String) != "Picture in Picture"
    }) else {
        return "no usable window"
    }

    // Fast path: replay the cached child-index path, verifying it still lands
    // on the button so a Chrome update falls back to a fresh search.
    let cached = (try? String(contentsOfFile: cachePath, encoding: .utf8))?
        .split(separator: ",").compactMap { Int($0) } ?? []
    if !cached.isEmpty, let button = walk(window, cached), isToggle(button) {
        AXUIElementPerformAction(button, kAXPressAction as CFString)
        return nil
    }

    guard let path = findPath(window, depth: 0), let button = walk(window, path) else {
        return "toggle button not found"
    }
    AXUIElementPerformAction(button, kAXPressAction as CFString)
    try? path.map(String.init).joined(separator: ",").write(toFile: cachePath, atomically: true, encoding: .utf8)
    return nil
}

// Chrome frames native messages as a little-endian uint32 length followed by
// JSON. No frame means the binary was run straight from a shell for testing.
let header = FileHandle.standardInput.readData(ofLength: 4)
let framed = header.count == 4
if framed {
    let length = header.withUnsafeBytes { $0.load(as: UInt32.self) }
    if length > 0 { _ = FileHandle.standardInput.readData(ofLength: Int(length)) }
}

if let error = toggle() {
    FileHandle.standardError.write(Data("toggle-tabbar: \(error)\n".utf8))
    exit(1)
}

if framed {
    let body = Data(#"{"status":"ok"}"#.utf8)
    var length = UInt32(body.count).littleEndian
    var out = Data(bytes: &length, count: 4)
    out.append(body)
    FileHandle.standardOutput.write(out)
}
