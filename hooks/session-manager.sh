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
    
    # Use awk to process the file and update/add the session
    local temp_file="${CURRENT_SESSIONS_FILE}.tmp"
    
    awk -v agent="$agent_id" -v session="$session_file" -v project="$project_path" \
        -v branch="$branch" -v status="$status" -v tasks="$tasks" -v ts="$timestamp" '
    BEGIN {
        found = 0
        in_block = 0
        skip_block = 0
    }
    /^### Agent:/ {
        if (skip_block) {
            skip_block--
            next
        }
        if ($0 ~ "### Agent: " agent) {
            # This is our agent, check if it matches project/branch
            in_block = 1
            agent_line = $0
            block_project = ""
            block_branch = ""
            block_started = ""
            block_lines[0] = $0
            line_count = 1
        } else {
            in_block = 0
            print
        }
        next
    }
    in_block {
        block_lines[line_count++] = $0
        
        if (/^- Project:/) {
            gsub(/^- Project: /, "")
            block_project = $0
        } else if (/^- Branch:/) {
            gsub(/^- Branch: /, "")
            block_branch = $0
        } else if (/^- Started:/) {
            gsub(/^- Started: /, "")
            block_started = $0
        } else if (/^$/ || /^### Agent:/ || /^## Session History/) {
            # End of block - decide what to do
            if (block_project == project && block_branch == branch) {
                # This is our block - replace it
                if (!found) {
                    print "### Agent: " agent
                    print "- Session: " session
                    print "- Project: " project
                    print "- Branch: " branch
                    # Preserve original start time if it exists
                    if (block_started != "") {
                        print "- Started: " block_started
                    } else {
                        print "- Started: " ts
                    }
                    print "- Last Update: " ts
                    print "- Status: " status
                    print "- Tasks: " tasks
                    print ""
                    found = 1
                }
                # Skip the original block
            } else {
                # Not our block - print it as-is
                for (i = 0; i < line_count; i++) {
                    print block_lines[i]
                }
            }
            in_block = 0
            
            # Handle the current line if its a section header
            if (/^### Agent:/ || /^## Session History/) {
                skip_block = 0
                if (/^## Session History/ && !found) {
                    # Add new session before history
                    print "### Agent: " agent
                    print "- Session: " session  
                    print "- Project: " project
                    print "- Branch: " branch
                    print "- Started: " ts
                    print "- Last Update: " ts
                    print "- Status: " status
                    print "- Tasks: " tasks
                    print ""
                    found = 1
                }
                print
            }
        }
        next
    }
    /^## Session History/ {
        if (!found) {
            # Add new session before history
            print "### Agent: " agent
            print "- Session: " session
            print "- Project: " project
            print "- Branch: " branch
            print "- Started: " ts
            print "- Last Update: " ts
            print "- Status: " status
            print "- Tasks: " tasks
            print ""
            found = 1
        }
        print
        next
    }
    { print }
    END {
        if (!found) {
            # Add at end if no history section
            print ""
            print "### Agent: " agent
            print "- Session: " session
            print "- Project: " project
            print "- Branch: " branch
            print "- Started: " ts
            print "- Last Update: " ts
            print "- Status: " status
            print "- Tasks: " tasks
        }
    }
    ' "$CURRENT_SESSIONS_FILE" > "$temp_file"
    
    mv "$temp_file" "$CURRENT_SESSIONS_FILE"
    
    # Update timestamp at top
    sed -i '' "s/^# Last Updated:.*/# Last Updated: $timestamp/" "$CURRENT_SESSIONS_FILE"
}

# Create or update session file
update_session_file() {
    local session_file="$1"
    local content="$2"
    local append="${3:-false}"
    
    local full_path="$SESSIONS_DIR/$session_file"
    
    # Load config for backup settings
    local config_file="$HOME/.claude/session-config"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
    
    # Defaults
    local keep_backups="${SESSION_KEEP_BACKUPS:-true}"
    local backup_dir="${SESSION_BACKUP_DIR:-$SESSIONS_DIR/backups}"
    local backup_count="${SESSION_BACKUP_COUNT:-10}"
    
    # Create backup if file exists and backups are enabled
    if [[ "$keep_backups" == "true" ]] && [[ -f "$full_path" ]]; then
        mkdir -p "$backup_dir"
        local session_base=$(basename "$session_file" .md)
        local timestamp=$(date +%Y%m%d-%H%M%S)
        local backup_file="$backup_dir/${session_base}-${timestamp}.md"
        cp "$full_path" "$backup_file"
        
        # Clean old backups (keep only last N)
        local backups=($(ls -t "$backup_dir/${session_base}"*.md 2>/dev/null))
        if [[ ${#backups[@]} -gt $backup_count ]]; then
            for ((i=$backup_count; i<${#backups[@]}; i++)); do
                rm "${backups[$i]}"
            done
        fi
    fi
    
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
    
    # Check if we have an active session for this project and branch
    if [[ -f "$CURRENT_SESSIONS_FILE" ]]; then
        local branch=$(get_git_branch)
        local active_session=$(awk -v agent="$agent_id" -v project="$project_path" -v branch="$branch" '
            BEGIN { found = 0 }
            /^### Agent:/ { 
                if ($0 ~ agent) {
                    in_block = 1
                    has_project = 0
                    has_branch = 0
                    session = ""
                } else {
                    in_block = 0
                }
            }
            in_block && /^- Session:/ { session = $3 }
            in_block && /^- Project:/ { if ($0 ~ project) has_project = 1 }
            in_block && /^- Branch:/ { if ($0 ~ branch) has_branch = 1 }
            in_block && /^- Status:/ { 
                if ($3 == "active" && has_project && has_branch && session != "") {
                    print session
                    exit
                }
            }
            in_block && /^$|^### Agent:|^## Session History/ {
                in_block = 0
                has_project = 0
                has_branch = 0
                session = ""
            }
        ' "$CURRENT_SESSIONS_FILE")
        
        if [[ -n "$active_session" ]]; then
            # Resume existing session
            echo "📂 Resuming session: $active_session" >&2
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