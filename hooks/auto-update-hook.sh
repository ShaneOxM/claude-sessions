#!/bin/bash
# Auto-update hook for Claude Code sessions
# This hook runs session updates in the background periodically

# Configuration
SESSION_UPDATE_SCRIPT="$HOME/code/os-repos/claude-session-manager/bin/session-auto-update"
UPDATE_INTERVAL="${SESSION_UPDATE_INTERVAL:-360}"  # Default 6 minutes
LAST_UPDATE_FILE="/tmp/.claude-session-last-update"

# Function to check if update is needed
should_update() {
    if [[ ! -f "$LAST_UPDATE_FILE" ]]; then
        return 0  # First run, should update
    fi
    
    last_update=$(cat "$LAST_UPDATE_FILE" 2>/dev/null || echo 0)
    current_time=$(date +%s)
    diff=$((current_time - last_update))
    
    if [[ $diff -ge $UPDATE_INTERVAL ]]; then
        return 0  # Time to update
    else
        return 1  # Too soon
    fi
}

# Function to run background update
run_background_update() {
    # Check if the script exists
    if [[ ! -x "$SESSION_UPDATE_SCRIPT" ]]; then
        return
    fi
    
    # Check if update is needed
    if ! should_update; then
        return
    fi
    
    # Run update in background
    (
        "$SESSION_UPDATE_SCRIPT" 2>/dev/null
        date +%s > "$LAST_UPDATE_FILE"
    ) &
    
    # Store background job ID for tracking
    echo $! > /tmp/.claude-session-update-pid
}

# Export function for use in hooks
export -f run_background_update

# If called directly, run the update
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_background_update
fi