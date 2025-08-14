---
argument-hint: [list|status|update]
---

# Session Management

Interactive session management for the current project.

## Usage
```bash
/session         # Show session menu
/session list    # List all sessions
/session status  # Show current status
/session update  # Update current session
```

## Instructions

```bash
#!/bin/bash
# Session command - interactive session management

# Source session manager functions
source ~/.claude/hooks/session-manager.sh 2>/dev/null

# Use installed version
CLAUDE_SESSIONS="$HOME/.claude/bin/claude-sessions"

COMMAND="${1:-menu}"

case "$COMMAND" in
    "menu"|"")
        echo "📊 Session Management"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Commands:"
        echo "  /start <desc>    - Start a new session"
        echo "  /session list    - List all sessions"
        echo "  /session status  - Show current status"
        echo "  /session update  - Update current session"
        echo "  /continue        - Browse and continue sessions"
        echo "  /complete        - Mark sessions as completed"
        echo ""
        # Show current status
        "$CLAUDE_SESSIONS" status
        ;;
        
    "list")
        "$CLAUDE_SESSIONS" list
        ;;
        
    "status")
        "$CLAUDE_SESSIONS" status
        ;;
        
    "update")
        shift
        MESSAGE="$*"
        if [[ -z "$MESSAGE" ]]; then
            echo "Please provide an update message"
            echo "Usage: /session update <message>"
        else
            OUTPUT=$("$CLAUDE_SESSIONS" update "$MESSAGE" 2>&1)
            echo "$OUTPUT"
        fi
        ;;
        
    *)
        echo "Unknown command: $COMMAND"
        echo "Use /session for menu"
        ;;
esac
```