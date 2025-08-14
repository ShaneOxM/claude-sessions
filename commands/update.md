---
argument-hint: <message>
---

# Update Session - Add progress update to current session

Update the current active session with a progress message.

## Usage
```bash
/update Working on authentication flow    # Add update to current session
/update "Completed API integration"       # Update with quoted message
```

## Instructions

```bash
#!/bin/bash
MESSAGE="$*"

if [[ -z "$MESSAGE" ]]; then
    echo "❌ Error: Please provide an update message"
    echo ""
    echo "Usage: /update <message>"
    echo "Example: /update Implementing user authentication"
    exit 1
fi

# Auto-generate summary of recent changes
AUTO_SUMMARY=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Get recent commits
    RECENT_COMMITS=$(git log --oneline -1 2>/dev/null | cut -d' ' -f2-)
    
    # Count files changed in last commit
    FILES_CHANGED=$(git diff --name-only HEAD~1 2>/dev/null | wc -l | tr -d ' ')
    
    # Get key file names (first 3)
    KEY_FILES=$(git diff --name-only HEAD~1 2>/dev/null | head -3 | xargs -I {} basename {} | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')
    
    # Get lines changed stats
    INSERTIONS=$(git diff --stat HEAD~1 2>/dev/null | tail -1 | grep -o '[0-9]* insertion' | cut -d' ' -f1)
    DELETIONS=$(git diff --stat HEAD~1 2>/dev/null | tail -1 | grep -o '[0-9]* deletion' | cut -d' ' -f1)
    
    # Get key changes from diff (function/class additions)
    KEY_CHANGES=$(git diff HEAD~1 2>/dev/null | grep '^+[^+]' | grep -E '(function |class |def |const |let |var |^\\+#)' | head -2 | sed 's/^+//' | cut -c1-30 | tr '\n' ';' | sed 's/;$//' | sed 's/;/, /g')
    
    if [[ -n "$RECENT_COMMITS" ]] || [[ "$FILES_CHANGED" -gt 0 ]]; then
        AUTO_SUMMARY=" ✨ "
        if [[ -n "$RECENT_COMMITS" ]]; then
            AUTO_SUMMARY="${AUTO_SUMMARY}${RECENT_COMMITS}"
        fi
        if [[ "$FILES_CHANGED" -gt 0 ]]; then
            AUTO_SUMMARY="${AUTO_SUMMARY} (${FILES_CHANGED} files"
            if [[ -n "$KEY_FILES" ]] && [[ "$FILES_CHANGED" -le 3 ]]; then
                AUTO_SUMMARY="${AUTO_SUMMARY}: ${KEY_FILES}"
            fi
            if [[ -n "$INSERTIONS" ]] || [[ -n "$DELETIONS" ]]; then
                AUTO_SUMMARY="${AUTO_SUMMARY}, +"
                AUTO_SUMMARY="${AUTO_SUMMARY}${INSERTIONS:-0}/-${DELETIONS:-0} lines"
            fi
            AUTO_SUMMARY="${AUTO_SUMMARY})"
        fi
    fi
fi

# Combine user message with auto-summary
FULL_MESSAGE="${MESSAGE}${AUTO_SUMMARY}"

# Truncate if too long
if [[ ${#FULL_MESSAGE} -gt 500 ]]; then
    FULL_MESSAGE="${FULL_MESSAGE:0:497}..."
fi

OUTPUT=$("$HOME/.claude/bin/claude-sessions" update "$FULL_MESSAGE" 2>&1)
RESULT=$?
echo "$OUTPUT"
exit $RESULT
```