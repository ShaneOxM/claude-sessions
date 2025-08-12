#!/bin/bash

# Merge duplicate sessions for claude-session-manager
SESSIONS_DIR="$HOME/.claude/sessions"
CURRENT_SESSION="2025-08-12-0924-claude-session-manager-session.md"
PROJECT="claude-session-manager"

echo "Merging duplicate sessions for $PROJECT..."
echo ""

# Create backup
cp "$SESSIONS_DIR/$CURRENT_SESSION" "$SESSIONS_DIR/$CURRENT_SESSION.backup"

# Collect all updates from all sessions
TEMP_FILE="/tmp/merged-updates.md"
> "$TEMP_FILE"

# Find all sessions for today with this project name
for session in "$SESSIONS_DIR"/2025-08-12-*${PROJECT}*.md; do
    if [[ -f "$session" ]] && [[ "$(basename "$session")" != "$CURRENT_SESSION" ]]; then
        echo "Processing: $(basename "$session")"
        
        # Extract updates (everything after "## Update:")
        awk '/^## Update:/{p=1} p' "$session" >> "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
    fi
done

# Now append the collected updates to the current session
# But first, remove any duplicate timestamps
echo "" >> "$SESSIONS_DIR/$CURRENT_SESSION"
cat "$TEMP_FILE" | awk '!seen[$0]++' | while IFS= read -r line; do
    if [[ "$line" =~ ^##\ Update: ]]; then
        # Check if this timestamp already exists in current session
        if ! grep -q "$line" "$SESSIONS_DIR/$CURRENT_SESSION"; then
            echo "$line" >> "$SESSIONS_DIR/$CURRENT_SESSION"
        fi
    elif [[ -n "$line" ]]; then
        echo "$line" >> "$SESSIONS_DIR/$CURRENT_SESSION"
    fi
done

echo ""
echo "Merged updates into: $CURRENT_SESSION"
echo ""
echo "Orphaned sessions to remove:"
for session in "$SESSIONS_DIR"/2025-08-12-*${PROJECT}*.md; do
    if [[ "$(basename "$session")" != "$CURRENT_SESSION" ]]; then
        echo "  - $(basename "$session")"
    fi
done

echo ""
echo "To remove orphaned sessions, run:"
echo "  rm ~/.claude/sessions/2025-08-12-{0507,0508,0826,0827,0828,0923}-claude-session-manager-session.md"