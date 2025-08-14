#!/bin/bash

# Claude Session Manager Installer
# Safe installation that preserves existing configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/$(date +%Y%m%d-%H%M%S)"

echo "🚀 Claude Session Manager Installer"
echo "===================================="
echo ""

# Check for Claude Code
if ! command -v claude >/dev/null 2>&1; then
    echo "⚠️  Warning: Claude Code CLI not found in PATH"
    echo "   Session management will still work when using Claude Code"
    echo ""
fi

# Create directories
echo "📁 Creating directories..."
mkdir -p "$CLAUDE_DIR"/{hooks,bin,sessions,commands}
mkdir -p "$BACKUP_DIR"

# Backup existing files
echo "💾 Backing up existing configurations..."
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$BACKUP_DIR/"
    echo "   ✓ Backed up settings.json"
fi

# Install hooks
echo "🔧 Installing hooks..."
cp "$SCRIPT_DIR/hooks/session-manager.sh" "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/session-manager.sh"
echo "   ✓ session-manager.sh"

cp "$SCRIPT_DIR/hooks/tool-pre-bash.sh" "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/tool-pre-bash.sh"
echo "   ✓ tool-pre-bash.sh"

# Install CLI tools
echo "🛠️  Installing CLI tools..."
for tool in claude-sessions start-session continue-session complete-session session-auto-update session-revert claude-sessions-sync; do
    if [ -f "$SCRIPT_DIR/bin/$tool" ]; then
        cp "$SCRIPT_DIR/bin/$tool" "$CLAUDE_DIR/bin/"
        chmod +x "$CLAUDE_DIR/bin/$tool"
        echo "   ✓ $tool"
    fi
done

# Install commands (using symlinks for auto-updates)
echo "📝 Installing Claude commands..."
if [ -d "$SCRIPT_DIR/commands" ]; then
    for cmd_file in "$SCRIPT_DIR/commands"/*.md; do
        if [[ -f "$cmd_file" ]]; then
            cmd_name=$(basename "$cmd_file")
            # Remove existing file if it's not a symlink
            if [ -f "$CLAUDE_DIR/commands/$cmd_name" ] && [ ! -L "$CLAUDE_DIR/commands/$cmd_name" ]; then
                rm -f "$CLAUDE_DIR/commands/$cmd_name"
            fi
            # Create symlink
            ln -sf "$cmd_file" "$CLAUDE_DIR/commands/$cmd_name"
            echo "   ✓ /$(basename "$cmd_name" .md) linked"
        fi
    done
fi

# Install migration utility for cleaning up existing sessions
echo "🔄 Installing migration utilities..."
if [ -f "$SCRIPT_DIR/utils/migrate-to-hybrid.sh" ]; then
    cp "$SCRIPT_DIR/utils/migrate-to-hybrid.sh" "$CLAUDE_DIR/bin/claude-migrate-sessions"
    chmod +x "$CLAUDE_DIR/bin/claude-migrate-sessions"
    echo "   ✓ Session migration utility installed"
fi

# Update or create settings.json
echo "⚙️  Configuring Claude settings..."
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    # Merge with existing settings
    echo "   📋 Merging with existing settings..."
    cp "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.bak"
    
    # Create temporary Python script for JSON merging
    cat > /tmp/merge_settings.py << 'EOF'
import json
import sys

with open(sys.argv[1], 'r') as f:
    existing = json.load(f)

new_hooks = {
    "PreToolUse": [
        {
            "matcher": "Bash",
            "hooks": [
                {
                    "type": "command",
                    "command": "~/.claude/hooks/tool-pre-bash.sh"
                }
            ]
        }
    ]
}

# Merge hooks
if 'hooks' not in existing:
    existing['hooks'] = {}

for hook_type, hooks in new_hooks.items():
    if hook_type not in existing['hooks']:
        existing['hooks'][hook_type] = hooks
    else:
        # Check if already exists
        exists = False
        for hook in existing['hooks'][hook_type]:
            if hook.get('matcher') == 'Bash':
                exists = True
                break
        if not exists:
            existing['hooks'][hook_type].extend(hooks)

print(json.dumps(existing, indent=2))
EOF
    
    python3 /tmp/merge_settings.py "$CLAUDE_DIR/settings.json" > "$CLAUDE_DIR/settings.json.new"
    mv "$CLAUDE_DIR/settings.json.new" "$CLAUDE_DIR/settings.json"
    rm /tmp/merge_settings.py
else
    # Create new settings.json
    cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/tool-pre-bash.sh"
          }
        ]
      }
    ]
  }
}
EOF
fi
echo "   ✓ Settings configured"

# Add to PATH if not already there
echo "🔗 Configuring PATH..."
SHELL_RC=""
if [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
fi

if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
    if ! grep -q "claude/bin" "$SHELL_RC"; then
        echo "" >> "$SHELL_RC"
        echo "# Claude Session Manager" >> "$SHELL_RC"
        echo "export PATH=\"\$HOME/.claude/bin:\$PATH\"" >> "$SHELL_RC"
        echo "   ✓ Added to PATH in $SHELL_RC"
        echo "   ⚠️  Run 'source $SHELL_RC' or restart your terminal"
    else
        echo "   ✓ PATH already configured"
    fi
fi

# Initialize session tracking
echo "📊 Initializing session tracking..."
if [ ! -f "$CLAUDE_DIR/sessions/.current-sessions" ]; then
    cat > "$CLAUDE_DIR/sessions/.current-sessions" << 'EOF'
# Multi-Agent Session Management
# Last Updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Active Sessions

## Session History
# Completed sessions are moved here with completion timestamp
EOF
    echo "   ✓ Session tracker initialized"
fi

# Import existing local sessions
if command -v claude-sessions-sync >/dev/null 2>&1; then
    echo "🔄 Importing existing sessions..."
    claude-sessions-sync
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "💡 Recommended: Clean up existing sessions"
echo "   If you have existing sessions, run this command to migrate them:"
echo "   claude-migrate-sessions"
echo ""
echo "🎯 Quick Start:"
echo "   1. Restart your terminal or run: source $SHELL_RC"
echo "   2. Start a session: claude-sessions start \"Working on new feature\""
echo "   3. Check status: claude-sessions status"
echo "   4. In Claude: /continue"
echo ""
echo "📚 Full documentation: https://github.com/yourusername/claude-session-manager"
echo ""

# Prompt to view backup location
if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR")" ]; then
    echo "💾 Backups saved to: $BACKUP_DIR"
fi