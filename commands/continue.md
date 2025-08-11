---
argument-hint: [session-name-or-id]
---

# Continue Session with Project Context

Continue a previous session using the interactive session picker.

## Usage
```bash
/continue                    # Open interactive session picker
/continue auth-refactor      # Continue specific session
/continue 2025-07-25-2340   # Continue by partial ID
```

## Instructions

1. Get current project path:
   ```bash
   PROJECT_PATH=$(pwd)
   PROJECT_NAME=$(basename "$PROJECT_PATH")
   ```

2. If no session name provided, list available sessions:
   ```bash
   if [ -z "$SESSION_NAME" ]; then
       echo "📂 Available Sessions"
       echo "━━━━━━━━━━━━━━━━━━"
       echo
       
       # List active sessions with numbers
       SESSION_COUNT=0
       declare -a SESSION_FILES
       
       # Active sessions for current project
       echo "🟢 Active Sessions in Current Project"
       grep -B1 -A5 "Project: $PROJECT_PATH" ~/.claude/sessions/.current-sessions 2>/dev/null | \
       grep "Session:" | sed 's/.*Session: //' | while read -r session; do
           if [ -f "$HOME/.claude/sessions/$session" ]; then
               SESSION_COUNT=$((SESSION_COUNT + 1))
               SESSION_FILES[$SESSION_COUNT]="$session"
               
               # Get session details
               BRANCH=$(grep "^\*\*Branch\*\*:" "$HOME/.claude/sessions/$session" | cut -d':' -f2- | xargs)
               SUMMARY=$(grep -m1 "^## Summary" -A1 "$HOME/.claude/sessions/$session" | tail -1)
               DATE=$(echo "$session" | grep -o '^[0-9-]*')
               
               echo "  [$SESSION_COUNT] $session"
               echo "      📅 Date: $DATE"
               echo "      🌿 Branch: $BRANCH"
               echo "      📝 Summary: $SUMMARY"
               echo
           fi
       done
       
       # All other active sessions
       echo "📁 Other Active Sessions"
       grep -A1 "### Agent:" ~/.claude/sessions/.current-sessions | \
       grep "Session:" | sed 's/.*Session: //' | while read -r session; do
           if [ -f "$HOME/.claude/sessions/$session" ] && \
              ! grep -q "$session" <<< "${SESSION_FILES[@]}"; then
               SESSION_COUNT=$((SESSION_COUNT + 1))
               SESSION_FILES[$SESSION_COUNT]="$session"
               
               PROJECT=$(grep "^\*\*Project\*\*:" "$HOME/.claude/sessions/$session" | cut -d':' -f2- | xargs)
               DATE=$(echo "$session" | grep -o '^[0-9-]*')
               
               echo "  [$SESSION_COUNT] $session"
               echo "      📅 Date: $DATE"
               echo "      📁 Project: $(basename "$PROJECT")"
               echo
           fi
       done
       
       if [ $SESSION_COUNT -eq 0 ]; then
           echo "No sessions found."
           echo
           echo "💡 Start a new session with:"
           echo "   claude-sessions start \"description\""
       else
           echo "━━━━━━━━━━━━━━━━━━━━━━━━"
           echo "💡 To continue a session:"
           echo "   /continue <session-name>"
           echo "   /continue <number>"
           echo
           echo "Example: /continue 1"
       fi
       exit 0
   fi
   ```

3. Otherwise, try to find specific session:
   ```bash
   # Check if it's a number (session index)
   if [[ "$SESSION_NAME" =~ ^[0-9]+$ ]]; then
       # Get session by index
       SESSION_INDEX="$SESSION_NAME"
       SESSION_FILE=""
       COUNT=0
       
       # Find the nth session
       for session in $(grep -A1 "### Agent:" ~/.claude/sessions/.current-sessions | \
                       grep "Session:" | sed 's/.*Session: //'); do
           if [ -f "$HOME/.claude/sessions/$session" ]; then
               COUNT=$((COUNT + 1))
               if [ $COUNT -eq $SESSION_INDEX ]; then
                   SESSION_FILE="$HOME/.claude/sessions/$session"
                   break
               fi
           fi
       done
   else
       # Try exact match first
       if [ -f "$HOME/.claude/sessions/$SESSION_NAME" ]; then
           SESSION_FILE="$HOME/.claude/sessions/$SESSION_NAME"
       elif [ -f "$HOME/.claude/sessions/${SESSION_NAME}.md" ]; then
           SESSION_FILE="$HOME/.claude/sessions/${SESSION_NAME}.md"
       else
           # Try partial match
           MATCHES=$(ls -1 "$HOME/.claude/sessions/" | grep -i "$SESSION_NAME" | head -1)
           if [ -n "$MATCHES" ]; then
               SESSION_FILE="$HOME/.claude/sessions/$MATCHES"
           fi
       fi
   fi
   
   if [ -n "$SESSION_FILE" ] && [ -f "$SESSION_FILE" ]; then
       SESSION_NAME=$(basename "$SESSION_FILE")
       echo "📂 Loading session: $SESSION_NAME"
       echo
       
       # Switch to session
       claude-sessions switch "$SESSION_NAME"
       
       # Show session metadata
       echo "📋 Session Details"
       echo "━━━━━━━━━━━━━━━"
       grep -E "^\*\*(Date|Time|Project|Branch)\*\*:" "$SESSION_FILE" | \
           sed 's/\*\*\(.*\)\*\*:/  \1:/' 
       echo
       
       # Show summary and recent work
       echo "📝 Summary"
       echo "━━━━━━━━"
       sed -n '/^## Summary/,/^##/p' "$SESSION_FILE" | sed '/^##/d' | head -5
       echo
       
       echo "🔄 Recent Updates"
       echo "━━━━━━━━━━━━━"
       grep "^## Update:" "$SESSION_FILE" | tail -3 | sed 's/^## Update:/  📍/'
       echo
       
       echo "✅ Session loaded! Continue where you left off."
       echo
       echo "💡 Use 'claude-sessions update \"message\"' to add updates"
   else
       echo "❌ Session not found: $SESSION_NAME"
       echo
       echo "Use '/continue' without arguments to see available sessions."
   fi
   ```
