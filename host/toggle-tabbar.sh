#!/bin/bash
# Native messaging host — clicks Chrome's "Collapse Tabs" / "Expand Tabs" button via macOS accessibility

# Consume the incoming message (length-prefixed JSON from Chrome)
read -r -n 4 _length

# Run the AppleScript as its own app so it holds its own Accessibility grant.
# macOS 27 checks osascript itself, not Chrome, so an inline osascript call is denied.
open -g -W "$(dirname "$0")/TabbarToggle.app" 2>/dev/null

# Send response back to Chrome (length-prefixed JSON)
MESSAGE='{"status":"ok"}'
LENGTH=${#MESSAGE}
printf "$(printf '\\x%02x' $((LENGTH & 0xFF)) $((LENGTH >> 8 & 0xFF)) $((LENGTH >> 16 & 0xFF)) $((LENGTH >> 24 & 0xFF)))"
printf '%s' "$MESSAGE"
