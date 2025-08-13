#!/bin/bash

# Add Status headers to existing session files
# This migration adds the **Status** field to session files that don't have it

echo "📝 Adding Status Headers to Session Files"
echo "========================================="
echo ""

GLOBAL_INDEX_FILE="$HOME/.claude/sessions/.global-index"
UPDATED_COUNT=0
SKIPPED_COUNT=0

# Function to add status to a session file
add_status_to_file() {
    local file_path="$1"
    local status="$2"
    
    if [[ ! -f "$file_path" ]]; then
        return 1
    fi
    
    # Check if Status field already exists
    if grep -q "^\*\*Status\*\*:" "$file_path"; then
        echo "   ⏭️  Already has status: $(basename "$file_path")"
        ((SKIPPED_COUNT++))
        return 0
    fi
    
    # Add Status field after Branch line
    if grep -q "^\*\*Branch\*\*:" "$file_path"; then
        sed -i '' "/^\*\*Branch\*\*:/a\\
**Status**: $status" "$file_path"
        echo "   ✅ Added status '$status': $(basename "$file_path")"
        ((UPDATED_COUNT++))
    else
        echo "   ⚠️  No Branch field found: $(basename "$file_path")"
        ((SKIPPED_COUNT++))
    fi
}

# Process sessions from global index
if [[ -f "$GLOBAL_INDEX_FILE" ]]; then
    echo "🔍 Processing sessions from global index..."
    echo ""
    
    # Read each line from global index
    tail -n +3 "$GLOBAL_INDEX_FILE" | while IFS='|' read -r project session agent branch status timestamp; do
        # Determine session file location
        local_session_file="$project/.claude/sessions/$session"
        archive_session_file="$project/.claude/sessions/archive/$session"
        
        # Check if session exists in active or archive
        if [[ -f "$local_session_file" ]]; then
            echo "📂 $(basename "$project")"
            add_status_to_file "$local_session_file" "${status:-inactive}"
        elif [[ -f "$archive_session_file" ]]; then
            echo "📦 $(basename "$project") [archived]"
            add_status_to_file "$archive_session_file" "completed"
        fi
    done
fi

# Process local sessions in current directory
echo ""
echo "🔍 Processing local sessions in current directory..."
LOCAL_SESSIONS_DIR="$(pwd)/.claude/sessions"

if [[ -d "$LOCAL_SESSIONS_DIR" ]]; then
    # Process active sessions
    for session_file in "$LOCAL_SESSIONS_DIR"/*.md; do
        if [[ -f "$session_file" ]]; then
            session_name=$(basename "$session_file")
            
            # Check if it's the current session
            if [[ -f "$LOCAL_SESSIONS_DIR/.current-session" ]]; then
                current=$(cat "$LOCAL_SESSIONS_DIR/.current-session")
                if [[ "$session_name" == "$current" ]]; then
                    add_status_to_file "$session_file" "active"
                else
                    add_status_to_file "$session_file" "inactive"
                fi
            else
                add_status_to_file "$session_file" "inactive"
            fi
        fi
    done
    
    # Process archived sessions
    if [[ -d "$LOCAL_SESSIONS_DIR/archive" ]]; then
        echo ""
        echo "📦 Processing archived sessions..."
        for session_file in "$LOCAL_SESSIONS_DIR/archive"/*.md; do
            if [[ -f "$session_file" ]]; then
                add_status_to_file "$session_file" "completed"
            fi
        done
    fi
fi

echo ""
echo "📊 Migration Summary"
echo "===================="
echo "   Sessions updated: $UPDATED_COUNT"
echo "   Sessions skipped: $SKIPPED_COUNT"
echo ""

if [[ $UPDATED_COUNT -gt 0 ]]; then
    echo "✅ Status headers added successfully!"
else
    echo "ℹ️  No sessions needed updating"
fi

echo ""
echo "💡 Status meanings:"
echo "   active    - Currently being worked on"
echo "   inactive  - Not current but not completed"
echo "   completed - Finished and archived"
