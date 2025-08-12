#!/usr/bin/env node

/**
 * Backup Sessions Script
 * Creates a safety backup of all user sessions
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const homeDir = os.homedir();
const claudeDir = path.join(homeDir, '.claude');
const sessionsDir = path.join(claudeDir, 'sessions');
const backupBaseDir = path.join(claudeDir, 'session-backups');

function createBackup() {
  // Check if sessions exist
  if (!fs.existsSync(sessionsDir)) {
    console.log('No sessions directory found.');
    return;
  }
  
  const sessionFiles = fs.readdirSync(sessionsDir).filter(f => f.endsWith('.md'));
  
  if (sessionFiles.length === 0) {
    console.log('No sessions to backup.');
    return;
  }
  
  // Create timestamped backup directory
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
  const backupDir = path.join(backupBaseDir, `backup-${timestamp}`);
  
  console.log(`📦 Creating backup of ${sessionFiles.length} sessions...`);
  
  // Create backup directory
  fs.mkdirSync(backupDir, { recursive: true });
  
  // Copy all session files
  sessionFiles.forEach(file => {
    const src = path.join(sessionsDir, file);
    const dest = path.join(backupDir, file);
    fs.copyFileSync(src, dest);
  });
  
  // Copy .current-sessions if exists
  const currentSessions = path.join(sessionsDir, '.current-sessions');
  if (fs.existsSync(currentSessions)) {
    fs.copyFileSync(currentSessions, path.join(backupDir, '.current-sessions'));
  }
  
  // Copy config if exists
  const config = path.join(claudeDir, 'session-config');
  if (fs.existsSync(config)) {
    fs.copyFileSync(config, path.join(backupDir, 'session-config'));
  }
  
  console.log(`✅ Backup created: ${path.relative(homeDir, backupDir)}`);
  console.log(`   ${sessionFiles.length} sessions backed up`);
  
  // Clean old backups (keep last 5)
  const backups = fs.readdirSync(backupBaseDir)
    .filter(d => d.startsWith('backup-'))
    .sort()
    .reverse();
    
  if (backups.length > 5) {
    backups.slice(5).forEach(oldBackup => {
      const oldPath = path.join(backupBaseDir, oldBackup);
      fs.rmSync(oldPath, { recursive: true, force: true });
      console.log(`   Removed old backup: ${oldBackup}`);
    });
  }
  
  return backupDir;
}

// Export for use in other scripts
module.exports = { createBackup };

// Run if called directly
if (require.main === module) {
  createBackup();
}