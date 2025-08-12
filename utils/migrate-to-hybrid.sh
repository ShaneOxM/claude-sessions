#!/bin/bash

# Migration script to convert to hybrid local+global session architecture
# This moves sessions from global storage to project-local storage

echo "🔄 Migrating to Hybrid Session Architecture"
echo "==========================================="
echo ""
echo "This will:"
echo "  1. Move global sessions to their project directories"
echo "  2. Create local .claude/sessions/ in each project"
echo "  3. Build a global index for cross-project visibility"
echo "  4. Preserve all session content and history"
echo ""

GLOBAL_SESSIONS_DIR="$HOME/.claude/sessions"
GLOBAL_INDEX_FILE="$GLOBAL_SESSIONS_DIR/.global-index"
CURRENT_SESSIONS_FILE="$GLOBAL_SESSIONS_DIR/.current-sessions"

# Backup everything first
BACKUP_DIR="$GLOBAL_SESSIONS_DIR/backup-$(date +%Y%m%d-%H%M%S)"
echo "📦 Creating backup in $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
cp -r "$GLOBAL_SESSIONS_DIR"/*.md "$BACKUP_DIR/" 2>/dev/null || true
cp "$CURRENT_SESSIONS_FILE" "$BACKUP_DIR/" 2>/dev/null || true
echo "   ✅ Backup complete"
echo ""

# Initialize global index
echo "📝 Creating global index..."
cat > "$GLOBAL_INDEX_FILE" << EOF
# Global Session Index
# Format: PROJECT|SESSION|AGENT|BRANCH|STATUS|TIMESTAMP
EOF

MIGRATED=0
FAILED=0
PROJECTS_PROCESSED=()

echo "🔍 Processing sessions..."
echo ""

# Process each active session from .current-sessions
if [[ -f "$CURRENT_SESSIONS_FILE" ]]; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^###\ Agent: ]]; then
            AGENT=""
            SESSION=""
            PROJECT=""
            BRANCH=""
            STATUS=""
            
            # Extract agent
            AGENT=$(echo "$line" | sed 's/^### Agent: //')
            
            # Read the session block
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
            
            # Process this session
            if [[ -n "$SESSION" ]] && [[ -n "$PROJECT" ]]; then
                echo "📁 Processing: $SESSION"
                echo "   Project: $PROJECT"
                
                # Check if project directory exists
                if [[ -d "$PROJECT" ]]; then
                    # Create local sessions directory
                    LOCAL_SESSIONS_DIR="$PROJECT/.claude/sessions"
                    mkdir -p "$LOCAL_SESSIONS_DIR"
                    
                    # Check if session file exists in global
                    if [[ -f "$GLOBAL_SESSIONS_DIR/$SESSION" ]]; then
                        # Copy session to local directory
                        cp "$GLOBAL_SESSIONS_DIR/$SESSION" "$LOCAL_SESSIONS_DIR/"
                        
                        if [[ -f "$LOCAL_SESSIONS_DIR/$SESSION" ]]; then
                            echo "   ✅ Moved to local directory"
                            
                            # Set as current if active
                            if [[ "$STATUS" == "active" ]]; then
                                echo "$SESSION" > "$LOCAL_SESSIONS_DIR/.current-session"
                                echo "   ✅ Set as current session"
                            fi
                            
                            # Add to global index
                            echo "${PROJECT}|${SESSION}|${AGENT}|${BRANCH}|${STATUS:-active}|$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$GLOBAL_INDEX_FILE"
                            
                            ((MIGRATED++))
                            
                            # Track processed projects
                            if [[ ! " ${PROJECTS_PROCESSED[@]} " =~ " ${PROJECT} " ]]; then
                                PROJECTS_PROCESSED+=("$PROJECT")
                            fi
                        else
                            echo "   ❌ Failed to copy session"
                            ((FAILED++))
                        fi
                    else
                        echo "   ⚠️  Session file not found in global storage"
                        ((FAILED++))
                    fi
                else
                    echo "   ⚠️  Project directory not found"
                    ((FAILED++))
                fi
                echo ""
            fi
        fi
    done < "$CURRENT_SESSIONS_FILE"
fi

# Handle orphaned sessions (in global but not in .current-sessions)
echo "🔍 Checking for orphaned sessions..."
for session_file in "$GLOBAL_SESSIONS_DIR"/*.md; do
    if [[ -f "$session_file" ]]; then
        SESSION_NAME=$(basename "$session_file")
        
        # Skip if already processed
        if grep -q "$SESSION_NAME" "$GLOBAL_INDEX_FILE" 2>/dev/null; then
            continue
        fi
        
        # Try to extract project from session file
        PROJECT_PATH=$(grep "^\*\*Project\*\*:" "$session_file" | sed 's/^\*\*Project\*\*: //')
        
        if [[ -n "$PROJECT_PATH" ]] && [[ -d "$PROJECT_PATH" ]]; then
            echo "   Found orphaned session: $SESSION_NAME"
            echo "   Moving to: $PROJECT_PATH"
            
            LOCAL_SESSIONS_DIR="$PROJECT_PATH/.claude/sessions"
            mkdir -p "$LOCAL_SESSIONS_DIR"
            cp "$session_file" "$LOCAL_SESSIONS_DIR/"
            
            # Add to global index as inactive
            BRANCH=$(grep "^\*\*Branch\*\*:" "$session_file" | sed 's/^\*\*Branch\*\*: //')
            AGENT=$(grep "^\*\*Agent\*\*:" "$session_file" | sed 's/^\*\*Agent\*\*: //')
            echo "${PROJECT_PATH}|${SESSION_NAME}|${AGENT:-unknown}|${BRANCH:-main}|inactive|$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$GLOBAL_INDEX_FILE"
            
            ((MIGRATED++))
        fi
    fi
done

echo ""
echo "📊 Migration Summary"
echo "===================="
echo "   Sessions migrated: $MIGRATED"
echo "   Failed/Skipped: $FAILED"
echo "   Projects updated: ${#PROJECTS_PROCESSED[@]}"
echo ""

if [[ $MIGRATED -gt 0 ]]; then
    echo "✅ Migration complete!"
    echo ""
    echo "Your sessions are now:"
    echo "  📁 Stored locally in each project's .claude/sessions/"
    echo "  🌍 Indexed globally for cross-project visibility"
    echo "  ⚡ Faster with no AWK searching needed"
    echo ""
    echo "💡 Next steps:"
    echo "  1. Test with: claude-sessions status"
    echo "  2. Update with: claude-sessions update 'Testing new architecture'"
    echo "  3. List all with: claude-sessions list"
else
    echo "ℹ️  No sessions needed migration"
fi

echo ""
echo "📦 Backup saved to: $BACKUP_DIR"
echo "   You can safely delete this after verifying everything works"