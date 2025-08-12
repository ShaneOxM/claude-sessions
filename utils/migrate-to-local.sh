#!/bin/bash

# Migration script to add project-local session caching
# This fixes existing sessions to work with the new dual-tracking system

SESSIONS_DIR="$HOME/.claude/sessions"
CURRENT_SESSIONS_FILE="$SESSIONS_DIR/.current-sessions"

echo "🔄 Migrating Sessions to Local Cache System"
echo "==========================================="
echo ""

if [[ ! -f "$CURRENT_SESSIONS_FILE" ]]; then
    echo "No sessions to migrate"
    exit 0
fi

# Process each active session
MIGRATED=0
FAILED=0

echo "Finding active sessions..."
echo ""

# Parse the current sessions file
while IFS= read -r line; do
    if [[ "$line" =~ ^###\ Agent: ]]; then
        # Start of a session block
        AGENT=""
        SESSION=""
        PROJECT=""
        BRANCH=""
        STATUS=""
        
        # Extract agent
        AGENT=$(echo "$line" | sed 's/^### Agent: //')
        
        # Read the next lines to get session details
        for i in {1..10}; do
            IFS= read -r subline
            if [[ "$subline" =~ ^-\ Session:\ (.+)$ ]]; then
                SESSION="${BASH_REMATCH[1]}"
            elif [[ "$subline" =~ ^-\ Project:\ (.+)$ ]]; then
                PROJECT="${BASH_REMATCH[1]}"
            elif [[ "$subline" =~ ^-\ Branch:\ (.+)$ ]]; then
                BRANCH="${BASH_REMATCH[1]}"
            elif [[ "$subline" =~ ^-\ Status:\ (.+)$ ]]; then
                STATUS="${BASH_REMATCH[1]}"
            elif [[ -z "$subline" ]] || [[ "$subline" =~ ^###\ Agent: ]] || [[ "$subline" =~ ^##\ Session\ History ]]; then
                break
            fi
        done
        
        # If we have an active session with all required fields
        if [[ -n "$SESSION" ]] && [[ -n "$PROJECT" ]] && [[ "$STATUS" == "active" ]]; then
            echo "📁 Processing: $SESSION"
            echo "   Project: $PROJECT"
            
            # Check if project directory exists
            if [[ -d "$PROJECT" ]]; then
                # Create .claude directory if needed
                mkdir -p "$PROJECT/.claude" 2>/dev/null || {
                    echo "   ⚠️  Cannot create .claude directory (permissions?)"
                    ((FAILED++))
                    continue
                }
                
                # Create the local cache file
                echo "$SESSION" > "$PROJECT/.claude/.current-session"
                
                if [[ -f "$PROJECT/.claude/.current-session" ]]; then
                    echo "   ✅ Created local cache"
                    ((MIGRATED++))
                else
                    echo "   ❌ Failed to create cache"
                    ((FAILED++))
                fi
            else
                echo "   ⚠️  Project directory not found (may be on different machine)"
                ((FAILED++))
            fi
            echo ""
        fi
    fi
done < "$CURRENT_SESSIONS_FILE"

echo "📊 Migration Summary"
echo "===================="
echo "   Sessions migrated: $MIGRATED"
echo "   Failed/Skipped: $FAILED"
echo ""

if [[ $MIGRATED -gt 0 ]]; then
    echo "✅ Migration complete!"
    echo ""
    echo "Your sessions now use fast local caching:"
    echo "  - Updates will be instant (no more searching)"
    echo "  - No more duplicate sessions"
    echo "  - Full backwards compatibility maintained"
else
    echo "ℹ️  No sessions needed migration"
fi

echo ""
echo "💡 Test the fix with: claude-sessions update 'Testing migration'"