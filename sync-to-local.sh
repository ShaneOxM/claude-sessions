#!/bin/bash

# Quick sync script to update local ~/.claude with latest changes

echo "🔄 Syncing to ~/.claude..."

# Copy updated scripts
cp bin/claude-sessions ~/.claude/bin/
cp bin/claude-sessions-archive ~/.claude/bin/
cp bin/start-session ~/.claude/bin/ 2>/dev/null
cp bin/continue-session ~/.claude/bin/ 2>/dev/null
cp bin/complete-session ~/.claude/bin/ 2>/dev/null
cp hooks/session-manager.sh ~/.claude/hooks/

# Copy utilities
cp utils/migrate-to-hybrid.sh ~/.claude/bin/claude-migrate-sessions 2>/dev/null
cp utils/archive-inactive-sessions.sh ~/.claude/bin/claude-archive-inactive 2>/dev/null
cp utils/add-status-headers.sh ~/.claude/bin/claude-add-status 2>/dev/null

# Make sure everything is executable
chmod +x ~/.claude/bin/claude-*
chmod +x ~/.claude/hooks/*.sh

echo "✅ Sync complete!"
echo ""
echo "Updated:"
echo "  - claude-sessions (with Status field support)"
echo "  - claude-sessions-archive"
echo "  - start-session (new /start command)"
echo "  - continue-session"
echo "  - complete-session"
echo "  - session-manager.sh (with update_session_status)"
echo "  - Migration utilities"