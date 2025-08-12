#!/usr/bin/env python3
"""
Fix duplicate sessions in .current-sessions file.
Keeps only the most recent active session for each unique agent/project/branch combination.
"""

import os
import re
from datetime import datetime
from collections import defaultdict
import shutil

def parse_sessions_file(filepath):
    """Parse the sessions file and return active and completed sessions."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Split into blocks separated by double newlines
    blocks = re.split(r'\n\n+', content.strip())
    
    active_sessions = []
    completed_sessions = []
    
    for block in blocks:
        if not block.strip():
            continue
        
        # Parse the block
        lines = block.strip().split('\n')
        session_data = {'raw_block': block}
        
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
                    session_data['started'] = datetime.now()
            elif line.startswith('- Completed:'):
                session_data['is_completed'] = True
        
        # Categorize the session
        if session_data.get('agent'):
            if session_data.get('is_completed'):
                completed_sessions.append(block)
            else:
                active_sessions.append(session_data)
    
    return active_sessions, completed_sessions

def deduplicate_active_sessions(active_sessions):
    """Keep only the most recent session for each agent/project/branch combo."""
    # Group by unique key
    session_groups = defaultdict(list)
    
    for session in active_sessions:
        key = (
            session.get('agent', ''),
            session.get('project', ''),
            session.get('branch', '')
        )
        if all(key):  # Only if all components are present
            session_groups[key].append(session)
    
    # Keep only most recent for each group
    kept_sessions = []
    
    for key, sessions in session_groups.items():
        # Sort by started time, most recent first
        sorted_sessions = sorted(
            sessions,
            key=lambda x: x.get('started', datetime.min),
            reverse=True
        )
        # Keep the most recent
        kept_sessions.append(sorted_sessions[0])
    
    return kept_sessions

def format_session_block(session):
    """Format a session data dict back into a block."""
    block = f"### Agent: {session['agent']}\n"
    block += f"- Session: {session['session']}\n"
    block += f"- Project: {session['project']}\n"
    block += f"- Branch: {session['branch']}\n"
    
    if 'started' in session:
        started_str = session['started'].isoformat().replace('+00:00', 'Z')
        block += f"- Started: {started_str}"
    else:
        block += f"- Started: {datetime.now().isoformat().replace('+00:00', 'Z')}"
    
    return block

def main():
    sessions_file = os.path.expanduser('~/.claude/sessions/.current-sessions')
    
    if not os.path.exists(sessions_file):
        print(f"Sessions file not found: {sessions_file}")
        return
    
    # Create backup
    backup_file = f"{sessions_file}.backup.{datetime.now().strftime('%Y%m%d%H%M%S')}"
    shutil.copy2(sessions_file, backup_file)
    print(f"Created backup: {backup_file}")
    
    # Parse the file
    active_sessions, completed_sessions = parse_sessions_file(sessions_file)
    
    print(f"Found {len(active_sessions)} active sessions")
    print(f"Found {len(completed_sessions)} completed sessions")
    
    # Deduplicate active sessions
    kept_sessions = deduplicate_active_sessions(active_sessions)
    
    print(f"After deduplication: {len(kept_sessions)} active sessions")
    
    # Write back to file
    with open(sessions_file, 'w') as f:
        # Write active sessions first
        for i, session in enumerate(kept_sessions):
            if i > 0:
                f.write('\n\n')
            f.write(format_session_block(session))
        
        # Write completed sessions
        for block in completed_sessions:
            f.write('\n\n')
            f.write(block)
        
        # End with newline
        f.write('\n')
    
    print("\nDeduplication complete!")
    print(f"Kept {len(kept_sessions)} unique active sessions")
    
    # Show what we kept
    print("\nActive sessions kept:")
    for session in kept_sessions:
        project_name = os.path.basename(session['project'])
        print(f"  - {session['session'][:50]} ({project_name}/{session['branch']})")

if __name__ == '__main__':
    main()
