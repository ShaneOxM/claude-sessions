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

COMMAND="${1:-menu}"

case "$COMMAND" in
    "menu"|"")
        echo "📊 Session Management"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Commands:"
        echo "  /session list    - List all sessions"
        echo "  /session status  - Show current status"
        echo "  /session update  - Update current session"
        echo "  /continue        - Browse and continue sessions"
        echo "  /complete        - Mark sessions as completed"
        echo ""
        # Show current status
        claude-sessions status
        ;;
        
    "list")
        claude-sessions list
        ;;
        
    "status")
        claude-sessions status
        ;;
        
    "update")
        shift
        MESSAGE="$*"
        if [[ -z "$MESSAGE" ]]; then
            echo "Please provide an update message"
            echo "Usage: /session update <message>"
        else
            OUTPUT=$(claude-sessions update "$MESSAGE" 2>&1)
            echo "$OUTPUT"
        fi
        ;;
        
    *)
        echo "Unknown command: $COMMAND"
        echo "Use /session for menu"
        ;;
esac
```