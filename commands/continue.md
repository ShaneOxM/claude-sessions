---
argument-hint: [session-name-or-id]
---

# Continue Session with Project Context

Continue a previous session or list available sessions for the current project.

## Usage
```bash
/continue                    # List sessions for current project
/continue auth-refactor      # Continue specific session
/continue 2025-07-25-2340   # Continue by partial ID
```

## Instructions

1. Check if session name provided:
   ```bash
   if [ -z "$SESSION_NAME" ]; then
       SHOW_LIST=true
   fi
   ```

2. Get current project path:
   ```bash
   PROJECT_PATH=$(pwd)
   PROJECT_NAME=$(basename "$PROJECT_PATH")
   ```

3. If listing sessions:
   ```bash
   echo "📚 Available Sessions for $PROJECT_NAME"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo ""
   
   # Check global sessions for this project
   SESSIONS_FOUND=0
   
   # From global tracker
   grep -B1 -A5 "Project: $PROJECT_PATH" ~/.claude/sessions/.current-sessions 2>/dev/null | \
   grep "Session:" | sed 's/.*Session: //' | while read -r session; do
       if [ -f "$HOME/.claude/sessions/$session" ]; then
           # Extract summary from session file
           SUMMARY=$(grep -m1 "^##" "$HOME/.claude/sessions/$session" | sed 's/^## //')
           DATE=$(echo "$session" | grep -o '^[0-9-]*')
           echo "📄 $session"
           echo "   Date: $DATE"
           echo "   Summary: $SUMMARY"
           echo ""
           ((SESSIONS_FOUND++))
       fi
   done
   
   # From local project sessions
   if [ -d ".claude/sessions" ]; then
       for session in .claude/sessions/*.md; do
           if [ -f "$session" ]; then
               SESSION_NAME=$(basename "$session")
               SUMMARY=$(grep -m1 "^##" "$session" | sed 's/^## //')
               DATE=$(echo "$SESSION_NAME" | grep -o '^[0-9-]*')
               echo "📄 $SESSION_NAME (local)"
               echo "   Date: $DATE"
               echo "   Summary: $SUMMARY"
               echo ""
               ((SESSIONS_FOUND++))
           fi
       done
   fi
   
   if [ $SESSIONS_FOUND -eq 0 ]; then
       echo "No sessions found for this project."
       echo ""
       echo "💡 Tips:"
       echo "   • Run 'claude-session-sync' to import local sessions"
       echo "   • Use 'claude-session start' to begin a new session"
   else
       echo "💡 To continue a session:"
       echo "   /continue <session-name>"
   fi
   ```

4. If continuing specific session:
   ```bash
   # Try to find the session
   SESSION_FILE=""
   
   # Check global sessions
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
   
   # Check local sessions
   if [ -z "$SESSION_FILE" ] && [ -d ".claude/sessions" ]; then
       if [ -f ".claude/sessions/$SESSION_NAME" ]; then
           SESSION_FILE=".claude/sessions/$SESSION_NAME"
       elif [ -f ".claude/sessions/${SESSION_NAME}.md" ]; then
           SESSION_FILE=".claude/sessions/${SESSION_NAME}.md"
       else
           # Try partial match
           MATCHES=$(ls -1 .claude/sessions/ | grep -i "$SESSION_NAME" | head -1)
           if [ -n "$MATCHES" ]; then
               SESSION_FILE=".claude/sessions/$MATCHES"
           fi
       fi
   fi
   
   if [ -n "$SESSION_FILE" ]; then
       echo "📂 Loading session: $(basename "$SESSION_FILE")"
       echo ""
       cat "$SESSION_FILE"
       echo ""
       echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
       echo "✅ Session loaded. Continue where you left off!"
       
       # Update global tracker
       claude-session switch "$(basename "$SESSION_FILE")"
   else
       echo "❌ Session not found: $SESSION_NAME"
       echo ""
       echo "Use '/continue' without arguments to see available sessions."
   fi
   ```