#!/bin/bash
# Git Safety Hook for Claude Code
# Prevents unsafe git operations and enforces best practices

# Read JSON input from Claude
INPUT=$(cat)

# Extract command from JSON
COMMAND=$(echo "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

# Default response
RESPONSE='{"action": "allow"}'

# Git safety checks
if [[ "$COMMAND" =~ ^git[[:space:]] ]]; then
    # Block dangerous git add patterns
    if [[ "$COMMAND" =~ git[[:space:]]add[[:space:]](-A|--all|\.) ]] || [[ "$COMMAND" == "git add" ]]; then
        # Show current status
        echo "🚫 Blocked: '$COMMAND'" >&2
        echo "" >&2
        echo "Use specific file patterns instead:" >&2
        echo "  git add <file-path>" >&2
        echo "  git add *.js" >&2
        echo "  git add src/" >&2
        echo "" >&2
        echo "Current git status:" >&2
        git status --short >&2
        
        RESPONSE='{"action": "block", "message": "Use specific file patterns with git add"}'
    fi
    
    # Build validation before push (optional feature)
    if [[ "$COMMAND" =~ git[[:space:]]push ]] && [[ -f "package.json" ]]; then
        if command -v npm >/dev/null 2>&1; then
            echo "🔨 Running build validation before push..." >&2
            
            # Check if build script exists
            if grep -q '"build"' package.json; then
                echo "📦 Building project..." >&2
                if ! npm run build >&2; then
                    echo "❌ Build failed! Fix errors before pushing." >&2
                    RESPONSE='{"action": "block", "message": "Build failed - fix errors before pushing"}'
                else
                    echo "✅ Build successful!" >&2
                fi
            fi
        fi
    fi
fi

# Output JSON response
echo "$RESPONSE"