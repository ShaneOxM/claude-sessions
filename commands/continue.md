---
argument-hint: [session-number]
---

# Continue Session - Interactive Selection

Continue a previous session using numbered selection.

## Usage
```bash
/continue       # Lists active sessions with numbers
/continue 1     # Continue session #1
/continue new   # Start a new session
```

## Instructions

```bash
#!/bin/bash
# Continue command - shows sessions and handles selection

# Call the continue-session script from installed location
OUTPUT=$(~/.claude/bin/continue-session "$@" 2>&1)

# Display the output
echo "$OUTPUT"

# If no arguments were provided and sessions were listed, prompt Claude
if [[ -z "$1" ]] && echo "$OUTPUT" | grep -q "Active Sessions"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 To continue a session, use: /continue <number>"
    echo "💡 For example: /continue 1"
    echo "💡 Or start new: /continue new \"description\""
fi
```