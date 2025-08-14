# Complete Session - Mark Sessions as Completed

Complete one or more active sessions using numbered selection.

## Usage
```bash
/complete           # Lists active sessions with numbers
/complete 1         # Complete session #1
/complete 1,3,5     # Complete multiple sessions
```

## Instructions

```bash
#!/bin/bash
# Complete command - delegates to complete-session script

# Use installed version from ~/.claude/bin
exec "$HOME/.claude/bin/complete-session" "$@"
```