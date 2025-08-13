#!/bin/bash

# Archive inactive sessions to clean up working directories
# This moves inactive/completed sessions to archive folders

echo "📦 Archiving Inactive Sessions"
echo "=============================="
echo ""

GLOBAL_INDEX_FILE="$HOME/.claude/sessions/.global-index"
ARCHIVED_COUNT=0
SKIPPED_COUNT=0

if [[ ! -f "$GLOBAL_INDEX_FILE" ]]; then
    echo "❌ No global index found. Run migration first."
    exit 1
fi

echo "🔍 Processing sessions from global index..."
echo ""

# Read the global index and process each session
tail -n +3 "$GLOBAL_INDEX_FILE" | while IFS='|' read -r project session agent branch status timestamp; do
    if [[ "$status" == "inactive" ]] || [[ "$status" == "completed" ]]; then
        local_sessions_dir="$project/.claude/sessions"
        archive_dir="$local_sessions_dir/archive"
        session_file="$local_sessions_dir/$session"
        
        if [[ -f "$session_file" ]]; then
            echo "📁 Project: $(basename "$project")"
            echo "   Session: $session"
            echo "   Status: $status"
            
            # Create archive directory if needed
            mkdir -p "$archive_dir"
            
            # Move to archive
            mv "$session_file" "$archive_dir/"
            
            if [[ -f "$archive_dir/$session" ]]; then
                echo "   ✅ Archived successfully"
                ((ARCHIVED_COUNT++))
            else
                echo "   ❌ Failed to archive"
                ((SKIPPED_COUNT++))
            fi
            echo ""
        fi
    fi
done

echo "📂 Archive Summary"
echo "=================="
echo "   Sessions archived: $ARCHIVED_COUNT"
echo "   Failed/Skipped: $SKIPPED_COUNT"
echo ""

# Optional: Clean up old archives (30+ days)
echo "🧹 Checking for old archives to clean up..."
CLEANUP_COUNT=0

# Find and remove archives older than 30 days
find ~/.claude/sessions/archive -name "*.md" -type f -mtime +30 2>/dev/null | while read -r old_file; do
    rm "$old_file"
    ((CLEANUP_COUNT++))
done

if [[ $CLEANUP_COUNT -gt 0 ]]; then
    echo "   Removed $CLEANUP_COUNT old archives (30+ days)"
fi

echo ""
echo "✅ Archive operation complete!"
echo ""
echo "💡 Tip: Active sessions remain in .claude/sessions/"
echo "   Completed sessions are now in .claude/sessions/archive/"
