#!/usr/bin/env python3
"""
Set the exact active sessions as specified.
Keep only:
1. The theravana.io session
2. The current claude-session-manager session
"""

import os
import shutil
from datetime import datetime

def main():
    sessions_file = os.path.expanduser('~/.claude/sessions/.current-sessions')
    
    # Create backup
    backup_file = f"{sessions_file}.backup.{datetime.now().strftime('%Y%m%d%H%M%S')}"
    shutil.copy2(sessions_file, backup_file)
    print(f"Created backup: {backup_file}")
    
    # Define the two active sessions
    active_sessions = [
        """### Agent: claude-code-main
- Session: 2025-08-10-1438-meta-app-review-feedback-round-1.md
- Project: /Users/shane/Desktop/code/startups/therapy-marketing-app/theravana.io
- Branch: main
- Started: 2025-08-10T20:08:15Z""",
        """### Agent: claude-code-main
- Session: 2025-08-11-1430-claude-session-manager-session.md
- Project: /Users/shane/code/os-repos/claude-session-manager
- Branch: main
- Started: 2025-08-11T18:30:27Z"""
    ]
    
    # Write the clean sessions file
    with open(sessions_file, 'w') as f:
        f.write('\n\n'.join(active_sessions))
        f.write('\n')
    
    print("Sessions file updated successfully!")
    print("\nActive sessions:")
    print("  1. theravana.io - meta-app-review-feedback-round-1")
    print("  2. claude-session-manager - current fixing session")

if __name__ == '__main__':
    main()
