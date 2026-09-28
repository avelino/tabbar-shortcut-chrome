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
        -- Check if window 1 got hijacked by PiP, and fallback to window 2 if it did
        if name of window 1 is "Picture in Picture" then
            set targetWindow to window 2
        else
            set targetWindow to window 1
        end if
        
        set base to group 1 of group 1 of group 1 of group 1 of targetWindow
        click button 1 of group 1 of UI element 3 of base
    end tell
end tell
