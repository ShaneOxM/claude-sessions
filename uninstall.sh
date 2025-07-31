#!/bin/bash

# Claude Session Manager Uninstaller
# Safely removes session manager while preserving sessions

echo "🗑️  Claude Session Manager Uninstaller"
echo "====================================="
echo ""

read -p "Keep session history? [Y/n] " -n 1 -r
echo
KEEP_SESSIONS=${REPLY:-Y}

read -p "Keep git safety hooks? [y/N] " -n 1 -r
echo
KEEP_GIT_HOOKS=${REPLY:-N}

CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/backups/uninstall-$(date +%Y%m%d-%H%M%S)"

# Create backup
echo "💾 Creating backup..."
mkdir -p "$BACKUP_DIR"

# Backup sessions if keeping
if [[ $KEEP_SESSIONS =~ ^[Yy]$ ]]; then
    if [ -d "$CLAUDE_DIR/sessions" ]; then
        cp -r "$CLAUDE_DIR/sessions" "$BACKUP_DIR/"
        echo "   ✓ Sessions backed up"
    fi
fi

# Remove CLI tools
echo "🧹 Removing CLI tools..."
rm -f "$CLAUDE_DIR/bin/claude-session"
rm -f "$CLAUDE_DIR/bin/claude-session-sync"
echo "   ✓ CLI tools removed"

# Remove or keep hooks based on preference
echo "🔧 Processing hooks..."
if [[ $KEEP_GIT_HOOKS =~ ^[Yy]$ ]]; then
    echo "   ✓ Keeping git safety hooks"
    # Remove only session-related hooks
    rm -f "$CLAUDE_DIR/hooks/session-manager.sh"
else
    rm -f "$CLAUDE_DIR/hooks/session-manager.sh"
    rm -f "$CLAUDE_DIR/hooks/tool-pre-bash.sh"
    echo "   ✓ All hooks removed"
fi

# Clean up settings.json
echo "⚙️  Cleaning settings..."
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$BACKUP_DIR/"
    
    # Remove hook entries using Python
    cat > /tmp/clean_settings.py << 'EOF'
import json
import sys

try:
    with open(sys.argv[1], 'r') as f:
        settings = json.load(f)
    
    # Remove session-related hooks
    if 'hooks' in settings:
        if not sys.argv[2] == "keep-git":
            # Remove all our hooks
            if 'PreToolUse' in settings['hooks']:
                settings['hooks']['PreToolUse'] = [
                    h for h in settings['hooks']['PreToolUse'] 
                    if not (h.get('matcher') == 'Bash' and 
                           'tool-pre-bash.sh' in h.get('hooks', [{}])[0].get('command', ''))
                ]
        
        # Clean up empty sections
        settings['hooks'] = {k: v for k, v in settings['hooks'].items() if v}
        if not settings['hooks']:
            del settings['hooks']
    
    print(json.dumps(settings, indent=2))
except:
    # If anything goes wrong, output original
    with open(sys.argv[1], 'r') as f:
        print(f.read())
EOF
    
    KEEP_FLAG=""
    if [[ $KEEP_GIT_HOOKS =~ ^[Yy]$ ]]; then
        KEEP_FLAG="keep-git"
    fi
    
    python3 /tmp/clean_settings.py "$CLAUDE_DIR/settings.json" "$KEEP_FLAG" > "$CLAUDE_DIR/settings.json.new"
    mv "$CLAUDE_DIR/settings.json.new" "$CLAUDE_DIR/settings.json"
    rm /tmp/clean_settings.py
    echo "   ✓ Settings cleaned"
fi

# Remove from PATH
echo "🔗 Cleaning PATH..."
for RC_FILE in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$RC_FILE" ]; then
        sed -i.bak '/# Claude Session Manager/,+1d' "$RC_FILE" 2>/dev/null || \
        sed -i '' '/# Claude Session Manager/,+1d' "$RC_FILE" 2>/dev/null || true
        rm -f "$RC_FILE.bak"
    fi
done
echo "   ✓ PATH cleaned"

# Clean up sessions if not keeping
if [[ ! $KEEP_SESSIONS =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing sessions..."
    rm -rf "$CLAUDE_DIR/sessions"
    echo "   ✓ Sessions removed"
fi

# Final cleanup
echo "🧹 Final cleanup..."
# Remove commands
rm -f "$CLAUDE_DIR/commands/continue.md"
# Remove empty directories
find "$CLAUDE_DIR" -type d -empty -delete 2>/dev/null || true

echo ""
echo "✅ Uninstall complete!"
echo ""

if [[ $KEEP_SESSIONS =~ ^[Yy]$ ]]; then
    echo "📁 Sessions preserved in: $CLAUDE_DIR/sessions/"
fi

if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR")" ]; then
    echo "💾 Backup saved to: $BACKUP_DIR"
fi

echo ""
echo "To reinstall later:"
echo "   git clone https://github.com/yourusername/claude-session-manager"
echo "   cd claude-session-manager && ./install.sh"