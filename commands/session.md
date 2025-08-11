---
argument-hint: [options]
---

# Session Management

Manage Claude sessions for the current project.

## Usage
```bash
/session                # List sessions for current project
/session list          # List all sessions (same as above)
/session switch NAME   # Switch to specific session
```

## Instructions

1. First check if we have an argument:
   ```bash
   if [ -z "$1" ]; then
       COMMAND="list"
   else
       COMMAND="$1"
   fi
   ```

2. Handle each command:
   ```bash
   case "$COMMAND" in
       "list")
           # List sessions in current project
           PROJECT_PATH=$(pwd)
           echo "📂 Sessions for $(basename "$PROJECT_PATH")"
           echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
           echo
           
           grep -B1 -A5 "Project: $PROJECT_PATH" ~/.claude/sessions/.current-sessions | \
               grep -E "^### Agent:|^- Session:|^- Branch:|^- Status:" | \
               sed 's/^### Agent:/\n👤 Agent:/' | \
               sed 's/^- /  /'
           ;;
           
           
       "switch")
           # Switch to specific session
           SESSION_NAME="$2"
           if [ -z "$SESSION_NAME" ]; then
               echo "❌ Please provide a session name"
               echo "Usage: /session switch <session-name>"
               exit 1
           fi
           
           if [ -f "$HOME/.claude/sessions/$SESSION_NAME" ]; then
               echo "📂 Switching to session: $SESSION_NAME"
               claude-sessions switch "$SESSION_NAME"
           else
               echo "❌ Session not found: $SESSION_NAME"
               echo "Use /session list to see available sessions"
           fi
           ;;
           
       *)
           echo "❌ Unknown command: $COMMAND"
           echo "Usage: /session [list|switch NAME]"
           exit 1
           ;;
   esac
   ```

3. Display picked session content:
   ```bash
   if [ -n "$session" ]; then
       echo
       echo "📄 Session Content"
       echo "━━━━━━━━━━━━━━━"
       echo
       cat "$HOME/.claude/sessions/$session"
   fi
   ```
