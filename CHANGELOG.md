# Changelog

All notable changes to the Claude Session Manager project will be documented in this file.

## [2.1.0] - 2025-08-10

### Added
- `/session` command for quick access in Claude Code
- Better visual feedback with formatted output & emojis
- Enhanced multi-session and agent management support

### Changed
- Renamed all references to `claude-sessions` (plural) for consistency
- Improved branch-aware filtering – each git branch now properly maintains its own session
- Enhanced output formatting for all session operations (start, update, switch, complete)

### Fixed
- Fixed bug in updating wrong sessions and creating duplicate records
- Corrected session filtering logic for multi-branch workflows
- Fixed newline formatting issues in command output
- Improved session initialization to properly check branch context

## [2.0.0] - 2025-07-31

### Added
- Branch-aware session tracking
- Multi-agent support for different Claude instances
- Session picker tool for interactive selection
- Git hooks for automatic session management
- Build validation before git push

### Changed
- Sessions now tracked per project and branch
- Improved session file naming convention
- Enhanced metadata tracking

## [1.0.0] - 2025-07-01

### Added
- Initial release
- Basic session management commands
- Session creation and tracking
- Git integration
- Project isolation
- Session history tracking

## Features Roadmap

### Planned for 2.2.0
- [ ] Session templates for common workflows
- [ ] Export sessions to markdown reports
- [ ] Session analytics and insights
- [ ] Team collaboration features

### Planned for 3.0.0
- [ ] Web interface for session browsing
- [ ] Integration with popular IDEs
- [ ] Cloud sync for sessions
- [ ] Advanced search and filtering
