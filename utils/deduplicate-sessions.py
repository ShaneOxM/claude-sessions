#!/usr/bin/env python3
"""
Deduplicate active sessions in .current-sessions file.
Keeps only the most recent active session for each unique agent/project/branch combination.
Marks older duplicates as completed.
"""

import os
import re
from datetime import datetime
from collections import defaultdict
import shutil

def parse_session_block(block):
    """Parse a session block into a dictionary."""
    lines = block.strip().split('\n')
    session_data = {}
    
    for line in lines:
        if line.startswith('### Agent:'):
            session_data['agent'] = line.replace('### Agent:', '').strip()
        elif line.startswith('- Session:'):
            session_data['session'] = line.replace('- Session:', '').strip()
        elif line.startswith('- Project:'):
            session_data['project'] = line.replace('- Project:', '').strip()
        elif line.startswith('- Branch:'):
            session_data['branch'] = line.replace('- Branch:', '').strip()
        elif line.startswith('- Started:'):
            started_str = line.replace('- Started:', '').strip()
            try:
                session_data['started'] = datetime.fromisoformat(started_str.replace('Z', '+00:00'))
            except:
                # Fallback for different timestamp formats
                session_data['started'] = datetime.now()
    
    return session_data if 'agent' in session_data else None

def format_session_block(session_data, completed=False):
    """Format session data back into a block."""
    if completed:
        # Format as completed session
        completed_time = datetime.now().isoformat().replace('+00:00', 'Z')
        return f"""### Agent: {session_data['agent']}
- Session: {session_data['session']}
- Project: {session_data['project']}
- Branch: {session_data['branch']}
- Started: {session_data['started'].isoformat().replace('+00:00', 'Z')}
- Completed: {completed_time}"""
    else:
        # Format as active session
        return f"""### Agent: {session_data['agent']}
- Session: {session_data['session']}
- Project: {session_data['project']}
- Branch: {session_data['branch']}
- Started: {session_data['started'].isoformat().replace('+00:00', 'Z')}"""

def main():
    sessions_file = os.path.expanduser('~/.claude/sessions/.current-sessions')
    
    if not os.path.exists(sessions_file):
        print(f"Sessions file not found: {sessions_file}")
        return
    
    # Create backup
    backup_file = f"{sessions_file}.backup.{datetime.now().strftime('%Y%m%d%H%M%S')}"
    shutil.copy2(sessions_file, backup_file)
    print(f"Created backup: {backup_file}")
    
    # Read the file
    with open(sessions_file, 'r') as f:
        content = f.read()
    
    # Split into blocks (sessions are separated by double newlines)
    blocks = content.strip().split('\n\n')
    
    # Parse all session blocks
    active_sessions = []
    completed_sessions = []
    
    for block in blocks:
        if not block.strip():
            continue
            
        session_data = parse_session_block(block)
        if not session_data:
            # Keep non-session blocks as-is (shouldn't happen but be safe)
            completed_sessions.append(block)
            continue
        
        if 'Completed' in block:
            # Already completed session
            completed_sessions.append(block)
        else:
            # Active session
            active_sessions.append(session_data)
    
    # Group active sessions by agent/project/branch
    session_groups = defaultdict(list)
    for session in active_sessions:
        key = (session.get('agent'), session.get('project'), session.get('branch'))
        if all(key):  # Only if all components are present
            session_groups[key].append(session)
    
    # Keep only the most recent session for each group
    kept_sessions = []
    newly_completed = []
    
    for key, sessions in session_groups.items():
        # Sort by started time, most recent first
        sorted_sessions = sorted(sessions, key=lambda x: x.get('started', datetime.min), reverse=True)
        
        # Keep the most recent
        kept_sessions.append(sorted_sessions[0])
        
        # Mark the rest as completed
        for session in sorted_sessions[1:]:
            newly_completed.append(session)
    
    # Write back to file
    with open(sessions_file, 'w') as f:
        # Write active sessions first
        for session in kept_sessions:
            f.write(format_session_block(session, completed=False))
            f.write('\n\n')
        
        # Write newly completed sessions
        for session in newly_completed:
            f.write(format_session_block(session, completed=True))
            f.write('\n\n')
        
        # Write already completed sessions
        for block in completed_sessions:
            f.write(block)
            f.write('\n\n')
    
    # Report results
    print(f"\nDeduplification complete:")
    print(f"  Active sessions before: {len(active_sessions)}")
    print(f"  Active sessions after: {len(kept_sessions)}")
    print(f"  Sessions marked as completed: {len(newly_completed)}")
    print(f"  Total completed sessions: {len(completed_sessions) + len(newly_completed)}")
    
    if newly_completed:
        print(f"\nSessions marked as completed:")
        for session in newly_completed:
            print(f"  - {session['session']} ({session['project']})")

if __name__ == '__main__':
    main()
