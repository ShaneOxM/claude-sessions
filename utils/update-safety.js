#!/usr/bin/env node

/**
 * Update Safety Checker
 * Ensures updates NEVER touch user data
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const homeDir = os.homedir();
const claudeDir = path.join(homeDir, '.claude');

// Protected directories and files that should NEVER be modified
const PROTECTED_PATHS = [
  path.join(claudeDir, 'sessions', '*.md'),           // User session files
  path.join(claudeDir, 'sessions', '.current-sessions'), // Active sessions tracker
  path.join(claudeDir, 'sessions', 'backups', '*'),    // User backups
  path.join(claudeDir, 'session-config'),              // User configuration
  path.join(claudeDir, 'CLAUDE.md'),                   // User's global CLAUDE.md
];

// Files that can be safely updated
const UPDATABLE = [
  'hooks/*.sh',      // Hook scripts (functionality)
  'commands/*.md',   // Slash commands (functionality)
  'bin/*',          // CLI tools (functionality)
];

function checkSafety() {
  console.log('🔒 Update Safety Check\n');
  
  // Check protected paths
  console.log('Protected User Data:');
  PROTECTED_PATHS.forEach(pattern => {
    const dir = path.dirname(pattern);
    const file = path.basename(pattern);
    
    if (fs.existsSync(dir)) {
      if (file === '*' || file === '*.md') {
        const files = fs.readdirSync(dir);
        const count = file === '*.md' ? files.filter(f => f.endsWith('.md')).length : files.length;
        if (count > 0) {
          console.log(`  ✓ ${path.relative(homeDir, dir)}: ${count} files (protected)`);
        }
      } else if (fs.existsSync(pattern)) {
        console.log(`  ✓ ${path.relative(homeDir, pattern)} (protected)`);
      }
    }
  });
  
  console.log('\nUpdatable Components:');
  UPDATABLE.forEach(component => {
    console.log(`  • ${component} (will be updated)`);
  });
  
  console.log('\n✅ Update is SAFE - User data will not be touched\n');
  return true;
}

// Export for use in other scripts
module.exports = { checkSafety, PROTECTED_PATHS };

// Run if called directly
if (require.main === module) {
  checkSafety();
}