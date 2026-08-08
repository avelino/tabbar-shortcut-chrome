#!/bin/bash
# Native messaging host — clicks Chrome's "Collapse Tabs" / "Expand Tabs" button via macOS accessibility

# Consume the incoming message (length-prefixed JSON from Chrome)
read -r -n 4 _length

osascript <<'APPLESCRIPT' 2>/dev/null
on findBtn(el, depth, maxDepth)
	if depth > maxDepth then return missing value
	tell application "System Events"
		set roleVal to ""
		try
			set roleVal to role of el
		end try
		-- Prune large/irrelevant subtrees
		if roleVal is "AXWebArea" then return missing value
		if roleVal is "AXToolbar" then return missing value
		if roleVal is "AXScrollArea" then return missing value
		if roleVal is "AXButton" then
			try
				set d to description of el
				if d is "Expand tabs" or d is "Collapse tabs" then return el
			end try
		end if
		try
			set kids to every UI element of el
			repeat with k in kids
				set found to my findBtn(k, depth + 1, maxDepth)
				if found is not missing value then return found
			end repeat
		end try
	end tell
	return missing value
end findBtn

tell application "System Events"
    tell process "Google Chrome"
        repeat with w in (every window)
            set wName to name of w
            -- Skip PiP windows
            if wName is not "Picture in Picture" and wName does not contain "Video playing in picture-in-picture mode" then
                try
                    -- Attempt to click the toggle button in the known hierarchy.
                    -- This will only succeed on windows that actually have the vertical tab bar.
                    click button 1 of group 1 of UI element 3 of group 1 of group 1 of group 1 of group 1 of w
                    return -- Success, exit the script
                end try
            end if
        end repeat
    end tell
end tell
APPLESCRIPT

# Send response back to Chrome (length-prefixed JSON)
MESSAGE='{"status":"ok"}'
LENGTH=${#MESSAGE}
printf "$(printf '\\x%02x' $((LENGTH & 0xFF)) $((LENGTH >> 8 & 0xFF)) $((LENGTH >> 16 & 0xFF)) $((LENGTH >> 24 & 0xFF)))"
printf '%s' "$MESSAGE"
