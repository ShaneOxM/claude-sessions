# Claude Session Manager

A powerful session management system for Claude Code that tracks development sessions across multiple projects, branches, and Claude instances.

## Features

- **Multi-Agent Support**: Track sessions across multiple Claude chats
- **Branch-Aware**: Sessions are tracked per git branch
- **Project Isolation**: Each project maintains its own sessions
- **Git Safety**: Prevents unsafe `git add -A` operations
- **Build Validation**: Optional build checks before git push
- **Session History**: Complete history of all development sessions
- **Easy Discovery**: Find and continue previous sessions

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/claude-session-manager.git
cd claude-session-manager

# Run the installer
./install.sh
```

## Quick Start

### Starting a Session
```bash
# Start a new session
claude-session start "Working on authentication feature"

# Or use Claude's built-in command
/project:session-start Working on authentication feature
```

### Managing Sessions
```bash
# Check current session status
claude-session status

# Update session progress
claude-session update "Fixed login bug"

# List all sessions
claude-session list

# Complete current session
claude-session complete
```

### Continuing Work
```bash
# In a new Claude chat, list sessions for current project
/continue

# Continue a specific session
/continue auth-feature
```

## How It Works

The session manager tracks:
- **Agent**: Which Claude instance is working
- **Project**: Full path to the project directory
- **Branch**: Current git branch
- **Status**: active, completed, or imported
- **Tasks**: Description of work being done

Sessions are stored globally in `~/.claude/sessions/` and tracked in `.current-sessions`.

## Configuration

### Basic Setup
The installer creates:
- `~/.claude/hooks/` - Hook scripts
- `~/.claude/bin/` - CLI tools
- `~/.claude/sessions/` - Session storage
- `~/.claude/settings.json` - Hook configuration

### Optional Features

#### Build Validation
To enable build validation before git push, ensure your project has a `build` script in package.json.

#### Custom Git Rules
Edit `~/.claude/hooks/tool-pre-bash.sh` to add custom git safety rules.

## Commands Reference

### CLI Commands
```bash
claude-session start <description>    # Start new session
claude-session update <message>       # Update current session
claude-session status                 # Show current status
claude-session list                   # List all sessions
claude-session complete              # Complete current session
claude-session switch <session>      # Switch to different session
claude-session-sync                  # Sync local sessions to global
```

### Claude Commands
```
/continue [session-name]             # List or continue sessions
/project:session-start <desc>        # Start new session
/project:session-update              # Update session
/project:session-end                 # End session
```

## Architecture

```
~/.claude/
├── sessions/
│   ├── .current-sessions           # Active session tracker
│   └── YYYY-MM-DD-*.md            # Individual session files
├── hooks/
│   ├── session-manager.sh         # Core session logic
│   └── tool-pre-bash.sh          # Git safety hooks
├── bin/
│   ├── claude-session            # Main CLI tool
│   └── claude-session-sync       # Sync utility
└── settings.json                 # Hook configuration
```

## Examples

### Working on Multiple Features
```bash
# On main branch - hotfix
git checkout main
claude-session start "Critical production bugfix"

# Switch to feature branch
git checkout feature/new-dashboard
claude-session start "Implementing dashboard components"

# Each branch maintains its own session
claude-session status  # Shows only current branch session
```

### Team Collaboration
Sessions include metadata perfect for team handoffs:
- Timestamp of all updates
- Branch information
- Task descriptions
- Progress notes

## Troubleshooting

### Session Not Found
- Check current branch: `git branch --show-current`
- Verify project path: `pwd`
- List all sessions: `claude-session list`

### Hooks Not Working
- Verify installation: `ls ~/.claude/hooks/`
- Check permissions: `chmod +x ~/.claude/hooks/*.sh`
- Review settings: `cat ~/.claude/settings.json`

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - see [LICENSE](https://github.com/ShaneOxM/claude-sessions/blob/main/LICENSE) file for details

## Credits

Created by ShaneOxM to enhance the Claude Code development experience ❤️
