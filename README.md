# Claude Session Manager

A powerful hybrid session management system for Claude Code that combines project-local storage with global visibility. Sessions stay with their projects while maintaining cross-project awareness.

## Features

- 📁 **Project-Local Sessions**: Sessions stored in `PROJECT/.claude/sessions/`
- 🌍 **Global Index**: Cross-project visibility via global index
- ⚡ **Instant Lookup**: No complex searching, just read local files
- 🔄 **Multi-Agent Support**: Track sessions across multiple Claude instances
- 🌿 **Branch-Aware**: Each git branch gets its own session
- 📊 **Session History**: Complete history with backups
- 🔍 **Easy Discovery**: Find sessions locally or globally

## Installation

```bash
# Clone the repository
git clone https://github.com/ShaneOxM/claude-sessions.git
cd claude-sessions-manager

# Run the installer
./install.sh
```

## Quick Start

#### Starting a Session
```bash
# Navigate to your project
cd my-project

# See what you were working on
claude-sessions status

# Or start fresh
claude-sessions start "implementing user authentication"
```

#### During Development
```bash
# Track your progress
claude-sessions update "Added login endpoint"
claude-sessions update "Fixed password validation bug"
claude-sessions update "Added unit tests"

# Check current status anytime
claude-sessions status
```

#### In Claude Code
Use these slash commands:
- `/continue` - Browse and continue sessions from any project
- `/session` - Manage current project's sessions
- `/update <message>` - Quick update to current session
- `/complete` - Mark sessions as completed

#### End of Session
```bash
# Complete the session
claude-sessions complete

# Or leave a note for tomorrow
claude-sessions update "stopping for today - TODO: write integration tests"
```

## How It Works

### Branch-Aware Sessions
Each git branch gets its own session automatically:
```bash
# On main branch
git status  # On branch main
claude-sessions status  # Shows: Session for main branch

# Switch branches
git checkout feature/payments
claude-sessions status  # Shows: Session for payments branch (different session!)
```

### Hybrid Architecture
- **Local Storage**: Sessions live in `PROJECT/.claude/sessions/`
- **Global Index**: `~/.claude/sessions/.global-index` tracks all projects
- **Fast Access**: Current session in `.claude/sessions/.current-session`
- **Portable**: Sessions travel with projects (can be committed if desired)

## Architecture

### Where Sessions Live
```
my-project/
  .claude/
    sessions/
      2025-08-12-1030-feature-auth.md    # Actual session content
      2025-08-12-0900-bug-fix.md         # Previous session
      .current-session                    # Points to active: "2025-08-12-1030-feature-auth.md"
      backups/                            # Auto-backups of sessions

~/.claude/
  sessions/
    .global-index                         # Index of all projects' sessions
    .current-sessions                     # Legacy global tracker (kept for compatibility)
```

### Benefits of Hybrid Approach
- ✅ **No searching**: Direct file reads, no complex AWK patterns
- ✅ **Project isolation**: Sessions stay with their code
- ✅ **Global visibility**: See all work via global index
- ✅ **Committable**: Optionally commit sessions with project
- ✅ **Fast**: Instant session lookups

## Configuration

### Basic Setup
The installer creates:
- `~/.claude/hooks/` - Hook scripts
- `~/.claude/bin/` - CLI tools
- `~/.claude/sessions/` - Global index and legacy storage
- `~/.claude/settings.json` - Hook configuration
- `PROJECT/.claude/sessions/` - Local session storage (per project)

### Optional Features

#### Build Validation
To enable build validation before git push, ensure your project has a `build` script in package.json.

#### Custom Git Rules
Edit `~/.claude/hooks/tool-pre-bash.sh` to add custom git safety rules.

## Commands Reference

### CLI Commands
```bash
claude-sessions start <description>    # Start new session
claude-sessions update <message>       # Update current session
claude-sessions status                 # Show current status
claude-sessions list                   # List all sessions
claude-sessions complete              # Complete current session
claude-sessions switch <session>      # Switch to different session
claude-sessions-sync                  # Sync local sessions to global
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
│   ├── tool-pre-bash.sh          # Git safety hooks
│   ├── auto-session.sh           # Automatic session creation
│   └── track-changes.sh          # Change tracking
├── bin/
│   ├── claude-sessions            # Main CLI tool
│   ├── claude-sessions-picker     # Interactive session picker
│   └── claude-sessions-sync       # Sync utility
└── settings.json                 # Hook configuration
```

## Real-World Examples

### Scenario 1: Bug Fix While Working on Feature
```bash
# Working on new feature
git checkout feature/user-profiles
claude-sessions update "halfway through profile component"

# Urgent bug reported!
git checkout main
claude-sessions start "fix: users can't login - session timeout bug"
# ... fix the bug ...
claude-sessions update "identified issue in session middleware"
claude-sessions update "fixed timeout calculation, added tests"
claude-sessions complete

# Back to feature work - your context is preserved!
git checkout feature/user-profiles
claude-sessions status  # Shows: "halfway through profile component"
```

### Scenario 2: Monday Morning - What Was I Doing?
```bash
cd my-project
claude-sessions list

# Output:
# 🟢 Active Sessions
#   - 2025-08-09-user-auth.md (feature/auth branch)
#   - 2025-08-08-api-refactor.md (main branch)  

# Continue where you left off
git checkout feature/auth
claude-sessions status
# Shows your last update: "TODO: Add password reset flow"
```

### Scenario 3: Handoff to Teammate
```bash
# Before vacation
claude-sessions update "HANDOFF: Database migrations ready, need API endpoints"
claude-sessions update "See /docs/api-spec.md for endpoint details"
claude-sessions update "Tests written but not passing - check auth middleware"

# Teammate can see full context
claude-sessions status  # Shows all your notes
```

## Troubleshooting

### Session Not Found
- Check current branch: `git branch --show-current`
- Verify project path: `pwd`
- List all sessions: `claude-sessions list`

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

Created and maintained to enhance the Claude Code development experience ❤️
