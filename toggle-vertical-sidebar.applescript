#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle vertical sidebar
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

try
    tell application "System Events"
        tell process "Google Chrome"
            repeat with w in (every window)
                set wName to name of w
                -- Skip PiP windows
                if wName is not "Picture in Picture" and wName does not contain "Video playing in picture-in-picture mode" then
                    try
                        -- Standard vertical tab bar toggle path
                        click button 1 of group 1 of UI element 3 of group 1 of group 1 of group 1 of group 1 of w
                        return -- Success, exit the script
                    end try
                end if
            end repeat
        end tell
    end tell
on error
    return
end try
return