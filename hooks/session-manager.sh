#!/bin/bash

# Session Management Helper Functions
# Used by various hooks to maintain session state

SESSIONS_DIR="$HOME/.claude/sessions"
CURRENT_SESSIONS_FILE="$SESSIONS_DIR/.current-sessions"
SESSION_UPDATE_INTERVAL=300  # 5 minutes

# Get agent identifier (from environment or default)
get_agent_id() {
    echo "${CLAUDE_AGENT_ID:-claude-code-main}"
}

# Get current project path
get_project_path() {
    pwd
}

# Get current git branch
get_git_branch() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git branch --show-current 2>/dev/null || echo "no-branch"
    else
        echo "not-git"
    fi
}

# Generate session filename
generate_session_name() {
    local task_desc="$1"
    local timestamp=$(date +%Y-%m-%d-%H%M)
    local sanitized_desc=$(echo "$task_desc" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g')
    echo "${timestamp}-${sanitized_desc}.md"
}

# Update or create session entry in .current-sessions
update_current_session() {
    local agent_id=$(get_agent_id)
    local session_file="$1"
    local status="${2:-active}"
    local tasks="${3:-Working on project tasks}"
    local project_path=$(get_project_path)
    local branch=$(get_git_branch)
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Create sessions directory if it doesn't exist
    mkdir -p "$SESSIONS_DIR"
    
    # Create .current-sessions if it doesn't exist
    if [[ ! -f "$CURRENT_SESSIONS_FILE" ]]; then
        cat > "$CURRENT_SESSIONS_FILE" << 'EOF'
# Multi-Agent Session Management
# Last Updated: TIMESTAMP

## Active Sessions

## Session History
# Completed sessions are moved here with completion timestamp
EOF
        sed -i '' "s/TIMESTAMP/$timestamp/" "$CURRENT_SESSIONS_FILE"
    fi
    
    # Clean session filename - remove any "Session: " prefixes
    session_file=$(echo "$session_file" | sed 's/^Session: //' | sed 's/^Session: //' | sed 's/^Session: //')
    
    # Update the file - first remove any existing entry for this agent/project combo
    local temp_file="${CURRENT_SESSIONS_FILE}.tmp"
    > "$temp_file"  # Clear temp file
    
    # First pass: remove ALL existing entries for this agent/project combo
    awk -v agent="$agent_id" -v project="$project_path" '
        BEGIN { skip = 0 }
        /^### Agent:/ { 
            if (skip > 0) skip = 0
            if ($0 ~ agent) {
                agent_block = 1
                block_start = NR
            }
        }
        agent_block && /^- Project:/ && $0 ~ project {
            skip = 7  # Skip this entire block
            agent_block = 0
        }
        agent_block && /^$|^### Agent:|^## Session History/ {
            agent_block = 0
        }
        skip > 0 { skip--; next }
        { print }
    ' "$CURRENT_SESSIONS_FILE" > "$temp_file"
    
    # Second pass: add new entry before Session History
    local final_file="${CURRENT_SESSIONS_FILE}.final"
    local added=false
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^##\ Session\ History ]] && ! $added; then
            # Add new entry
            cat >> "$final_file" << EOF
### Agent: $agent_id
- Session: $session_file
- Project: $project_path
- Branch: $branch
- Started: $timestamp
- Last Update: $timestamp
- Status: $status
- Tasks: $tasks

EOF
            added=true
        fi
        echo "$line" >> "$final_file"
    done < "$temp_file"
    
    # If no Session History section, append at end
    if ! $added; then
        cat >> "$final_file" << EOF

### Agent: $agent_id
- Session: $session_file
- Project: $project_path
- Branch: $branch
- Started: $timestamp
- Last Update: $timestamp
- Status: $status
- Tasks: $tasks
EOF
    fi
    
    mv "$final_file" "$CURRENT_SESSIONS_FILE"
    rm -f "$temp_file"
    
    # Update timestamp at top
    sed -i '' "s/^# Last Updated:.*/# Last Updated: $timestamp/" "$CURRENT_SESSIONS_FILE"
}

# Create or update session file
update_session_file() {
    local session_file="$1"
    local content="$2"
    local append="${3:-false}"
    
    local full_path="$SESSIONS_DIR/$session_file"
    
    if [[ "$append" == "true" ]] && [[ -f "$full_path" ]]; then
        echo -e "\n## Update: $(date -u +%Y-%m-%dT%H:%M:%SZ)\n$content" >> "$full_path"
    else
        echo "$content" > "$full_path"
    fi
}

# Check if session needs update (based on time)
needs_session_update() {
    local agent_id=$(get_agent_id)
    local last_update=$(grep -A6 "### Agent: $agent_id" "$CURRENT_SESSIONS_FILE" 2>/dev/null | grep "Last Update:" | cut -d' ' -f3-)
    
    if [[ -z "$last_update" ]]; then
        return 0  # No session found, needs update
    fi
    
    local last_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_update" +%s 2>/dev/null || echo 0)
    local current_epoch=$(date +%s)
    local diff=$((current_epoch - last_epoch))
    
    if [[ $diff -gt $SESSION_UPDATE_INTERVAL ]]; then
        return 0  # Needs update
    else
        return 1  # Recent enough
    fi
}

# Initialize session on Claude start
init_session() {
    local agent_id=$(get_agent_id)
    local project_path=$(get_project_path)
    local project_name=$(basename "$project_path")
    
    # Check if we have an active session for this project
    if [[ -f "$CURRENT_SESSIONS_FILE" ]]; then
        local current_session=$(grep -A1 "### Agent: $agent_id" "$CURRENT_SESSIONS_FILE" 2>/dev/null | grep "Session:" | cut -d' ' -f2-)
        local current_project=$(grep -A2 "### Agent: $agent_id" "$CURRENT_SESSIONS_FILE" 2>/dev/null | grep "Project:" | cut -d' ' -f2-)
        
        if [[ -n "$current_session" ]] && [[ "$current_project" == "$project_path" ]]; then
            # Resume existing session
            echo "📂 Resuming session: $current_session" >&2
            return 0
        fi
    fi
    
    # Create new session
    local session_name=$(generate_session_name "$project_name-session")
    update_current_session "$session_name" "active" "Working on $project_name"
    
    # Create initial session file
    update_session_file "$session_name" "# Session: $project_name Development
**Date**: $(date +%Y-%m-%d)
**Time**: $(date +%H:%M)
**Agent**: $agent_id
**Project**: $project_path

## Summary
Development session for $project_name

## Current Work
- Starting new session"
    
    echo "🆕 Started new session: $session_name" >&2
}

# Handle command line arguments
if [[ "$1" == "init" ]]; then
    init_session
fi

# Export functions for use in other scripts
export -f get_agent_id
export -f get_project_path
export -f get_git_branch
export -f generate_session_name
export -f update_current_session
export -f update_session_file
export -f needs_session_update
export -f init_session