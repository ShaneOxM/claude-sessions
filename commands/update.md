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
# Update command - adds progress update to current session

# Join all arguments as the update message
MESSAGE="$*"

if [[ -z "$MESSAGE" ]]; then
    echo "❌ Error: Please provide an update message"
    echo ""
    echo "Usage: /update <message>"
    echo "Example: /update Implementing user authentication"
    exit 1
fi

# Call claude-sessions update
claude-sessions update "$MESSAGE"
```