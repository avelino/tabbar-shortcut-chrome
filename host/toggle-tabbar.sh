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
		set wins to every window whose subrole is "AXStandardWindow"
		repeat with w in wins
			set btn to my findBtn(w, 0, 10)
			if btn is not missing value then
				click btn
				return
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
