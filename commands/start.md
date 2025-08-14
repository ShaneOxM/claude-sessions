---
argument-hint: <description>
---

# Start Session

Start a new session with a description for your current work.

## Usage
```bash
/start <description>   # Start new session with description
```

## Examples
```bash
/start implementing user authentication
/start fixing payment processing bug
/start refactoring database layer
```

## Instructions

```bash
#!/bin/bash
# Start command - start a new session with description

# Use installed version from ~/.claude/bin
START_SESSION="$HOME/.claude/bin/start-session"

if [[ -z "$*" ]]; then
    "$START_SESSION"
else
    "$START_SESSION" "$@"
fi
```