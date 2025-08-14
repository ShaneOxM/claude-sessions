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
- ✨ **Intelligent Updates**: `/update` auto-generates summaries from git history
- 🚀 **Auto-Update on Git**: Automatic session updates after commits/pushes (optional)

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

# Start fresh (CLI)
claude-sessions start "implementing user authentication"

# Or in Claude Code (slash command)
/start implementing user authentication
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
- `/start <description>` - Start a new session with description
- `/continue` - Browse and continue sessions from any project
- `/session` - Manage current project's sessions
- `/update [message]` - Update session (auto-generates from git if no message)
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
- `~/.claude/commands/` - Symlinks to slash commands (/start, /continue, /session, /update, /complete)
- `~/.claude/sessions/` - Global index and legacy storage
- `~/.claude/settings.json` - Hook configuration
- `PROJECT/.claude/sessions/` - Local session storage (per project)

## Settings & Features

### Auto-Update Sessions (Background Tasks)
Automatically update sessions after git commits and pushes with detailed change tracking.

#### Enable Auto-Updates
```bash
enable-auto-updates
```
This will:
- ✅ Set `ENABLE_BACKGROUND_TASKS=1` in your shell config
- ✅ Install git hooks for automatic session updates
- ✅ Track commits, pushes, file changes, and code statistics
- ✅ Work with Ctrl+B in Claude Code for background operations

#### Disable Auto-Updates
```bash
disable-auto-updates
```
This will:
- ⚠️ Set `ENABLE_BACKGROUND_TASKS=0` (preserves settings)
- ⚠️ Keep your configuration for easy re-enabling
- ⚠️ Optionally remove git hooks

### Optional Features

#### Build Validation
To enable build validation before git push, ensure your project has a `build` script in package.json.

#### Custom Git Rules
Edit `~/.claude/hooks/tool-pre-bash.sh` to add custom git safety rules.

#### Session Configuration
Edit `~/.claude/session-config` to customize:
- `SESSION_AUTO_UPDATE` - Enable/disable auto-updates
- `SESSION_UPDATE_INTERVAL` - Update frequency (default: 360 seconds)
- `SESSION_SHOW_UPDATES` - Show update notifications
- `SESSION_KEEP_BACKUPS` - Enable backup creation
- `SESSION_BACKUP_COUNT` - Number of backups to keep

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

### Claude Commands (Slash Commands)
```
/start <description>                # Start new session with description
/continue [number]                  # List or continue sessions by number
/session [status|list|update]       # Manage current session
/update [message]                   # Update with auto-summary (or auto-generate if no message)
/complete [numbers]                 # Mark sessions as completed
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

## Development

### Symlink Architecture

The installation uses symlinks for instant updates during development:

```
Your Repository                    Claude's Directory
──────────────                    ─────────────────
commands/                          ~/.claude/commands/
  ├── start.md       <───────────── start.md (symlink)
  ├── continue.md    <───────────── continue.md (symlink)
  ├── complete.md    <───────────── complete.md (symlink)  
  ├── session.md     <───────────── session.md (symlink)
  └── update.md      <───────────── update.md (symlink)
```

**Benefits:**
- **Instant local updates** - Edit in your local repo, changes are live immediately
- **No sync needed** - Commands update automatically via symlinks
- **Single source** - One file to maintain, no copying
- **Git-friendly** - All changes tracked in your repository

**Important:** Symlinks point to your LOCAL repository, not GitHub. To get updates:
```bash
cd claude-session-manager  # wherever you cloned it
git pull upstream main      # pull from original repo
# Commands update instantly via symlinks
./sync-to-local.sh         # Only needed for bin/ and hooks/
```

### Development Workflow

1. **Fork and clone:**
   ```bash
   # Fork the repo on GitHub first, then:
   git clone https://github.com/YOUR_USERNAME/claude-sessions.git
   cd claude-session-manager
   
   # Set upstream to original repo for updates
   git remote add upstream https://github.com/ShaneOxM/claude-sessions.git
   
   # Install
   ./install.sh
   ```

2. **Edit commands (instant updates via symlinks):**
   ```bash
   # Edit with your preferred editor (VSCode, Cursor, vim, etc.)
   code commands/continue.md  # or cursor, vim, nano, etc.
   # Changes are immediately live - no sync needed!
   ```

3. **Edit scripts (requires sync):**
   ```bash
   # Edit with your preferred editor
   code bin/claude-sessions
   ./sync-to-local.sh  # Quick sync for non-symlinked files
   ```

### File Types

| File Type | Location | Update Method |
|-----------|----------|---------------|
| Commands (*.md) | `commands/` | Instant via symlinks |
| Scripts | `bin/` | Run `./sync-to-local.sh` |
| Hooks | `hooks/` | Run `./sync-to-local.sh` |
| Utils | `utils/` | Run `./sync-to-local.sh` |

### Quick Sync Script

For non-symlinked files, use the sync script:
```bash
./sync-to-local.sh
# Updates: claude-sessions, hooks, utilities
```

### Testing Changes

```bash
# Test commands instantly (symlinked)
/continue
/session status

# Test scripts after sync
./sync-to-local.sh
claude-sessions status
```

### Keeping Up-to-Date

The symlinks point to your **local repository**, not GitHub directly:

```
~/.claude/commands/continue.md → /path/to/your/claude-session-manager/commands/continue.md
                                  ↑
                            YOUR LOCAL REPO (not GitHub)
```

To get updates from the original repository:
```bash
# 1. Navigate to your local clone
cd claude-session-manager

# 2. Pull latest changes from upstream
git pull upstream main

# 3. Commands update instantly (symlinked)
# 4. Sync other files if needed
./sync-to-local.sh  # Updates bin/, hooks/, utils/
```

**No drift possible** because:
- Symlinks always point to your local repo
- You control when to pull updates from GitHub
- Local edits are preserved until you commit/pull

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - see [LICENSE](https://github.com/ShaneOxM/claude-sessions/blob/main/LICENSE) file for details

## Credits

Created and maintained to enhance the Claude Code development experience ❤️
