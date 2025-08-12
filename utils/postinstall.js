#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

// Colors for output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  red: '\x1b[31m'
};

const homeDir = os.homedir();
const claudeDir = path.join(homeDir, '.claude');
const packageDir = path.dirname(__dirname);

console.log(`${colors.blue}${colors.bright}═══════════════════════════════════════════════════════${colors.reset}`);
console.log(`${colors.blue}${colors.bright}     Claude Session Manager - Setup${colors.reset}`);
console.log(`${colors.blue}${colors.bright}═══════════════════════════════════════════════════════${colors.reset}\n`);

// SAFETY CHECK: Never touch user sessions
const sessionsDir = path.join(claudeDir, 'sessions');
if (fs.existsSync(sessionsDir)) {
  const sessionFiles = fs.readdirSync(sessionsDir).filter(f => f.endsWith('.md'));
  if (sessionFiles.length > 0) {
    console.log(`${colors.green}✓${colors.reset} Found ${sessionFiles.length} existing sessions - ${colors.bright}these will NOT be touched${colors.reset}\n`);
  }
}

// Create directories
console.log(`${colors.yellow}Creating directories...${colors.reset}`);
const dirs = [
  path.join(claudeDir, 'sessions'),
  path.join(claudeDir, 'sessions', 'backups'),
  path.join(claudeDir, 'commands'),
  path.join(claudeDir, 'hooks')
];

dirs.forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});
console.log(`${colors.green}✓${colors.reset} Directories created\n`);

// Copy hooks
console.log(`${colors.yellow}Installing hooks...${colors.reset}`);
const hooksDir = path.join(packageDir, 'hooks');
if (fs.existsSync(hooksDir)) {
  const hooks = fs.readdirSync(hooksDir);
  hooks.forEach(hook => {
    const src = path.join(hooksDir, hook);
    const dest = path.join(claudeDir, 'hooks', hook);
    fs.copyFileSync(src, dest);
    if (process.platform !== 'win32') {
      fs.chmodSync(dest, '755');
    }
    console.log(`  ${colors.green}✓${colors.reset} ${hook}`);
  });
}
console.log();

// Link slash commands
console.log(`${colors.yellow}Setting up slash commands...${colors.reset}`);
const commandsDir = path.join(packageDir, 'commands');
if (fs.existsSync(commandsDir)) {
  // Remove old commands first
  const oldCommands = ['list', 'start', 'new', 'switch', 'update', 'status', 'cleanup', 'test', 'worktree'];
  oldCommands.forEach(cmd => {
    const cmdPath = path.join(claudeDir, 'commands', `${cmd}.md`);
    if (fs.existsSync(cmdPath)) {
      fs.unlinkSync(cmdPath);
      console.log(`  ${colors.red}✗${colors.reset} Removed old: /${cmd}`);
    }
  });
  
  // Link our commands
  const commands = fs.readdirSync(commandsDir);
  commands.forEach(cmd => {
    if (cmd.endsWith('.md')) {
      const src = path.join(commandsDir, cmd);
      const dest = path.join(claudeDir, 'commands', cmd);
      
      // Create symlink or copy on Windows
      try {
        if (fs.existsSync(dest)) {
          fs.unlinkSync(dest);
        }
        if (process.platform === 'win32') {
          fs.copyFileSync(src, dest);
        } else {
          fs.symlinkSync(src, dest);
        }
        console.log(`  ${colors.green}✓${colors.reset} /${cmd.replace('.md', '')}`);
      } catch (err) {
        console.log(`  ${colors.yellow}⚠${colors.reset} /${cmd.replace('.md', '')} - ${err.message}`);
      }
    }
  });
}
console.log();

// Create session config if it doesn't exist
const sessionConfig = path.join(claudeDir, 'session-config');
if (!fs.existsSync(sessionConfig)) {
  console.log(`${colors.yellow}Creating session configuration...${colors.reset}`);
  const template = path.join(packageDir, 'config', 'session-config.template');
  if (fs.existsSync(template)) {
    fs.copyFileSync(template, sessionConfig);
    console.log(`${colors.green}✓${colors.reset} Configuration created\n`);
  }
} else {
  console.log(`${colors.blue}ℹ${colors.reset} Session config already exists\n`);
}

// Show summary
console.log(`${colors.green}${colors.bright}═══════════════════════════════════════════════════════${colors.reset}`);
console.log(`${colors.green}${colors.bright}     Installation Complete!${colors.reset}`);
console.log(`${colors.green}${colors.bright}═══════════════════════════════════════════════════════${colors.reset}\n`);

console.log(`📋 ${colors.blue}CLI Commands Available:${colors.reset}`);
console.log(`  ${colors.green}claude-sessions${colors.reset}      - Main session manager`);
console.log(`  ${colors.green}csm${colors.reset}                  - Short alias for claude-sessions`);
console.log(`  ${colors.green}continue-session${colors.reset}     - Interactive session picker`);
console.log(`  ${colors.green}complete-session${colors.reset}     - Complete sessions`);
console.log(`  ${colors.green}session-revert${colors.reset}       - Revert to previous state`);
console.log();

console.log(`🔧 ${colors.blue}Slash Commands in Claude:${colors.reset}`);
console.log(`  ${colors.green}/continue${colors.reset}     - Browse and continue sessions`);
console.log(`  ${colors.green}/complete${colors.reset}     - Mark sessions as completed`);
console.log(`  ${colors.green}/session${colors.reset}      - Session management menu`);
console.log();

console.log(`📁 ${colors.blue}Configuration:${colors.reset}`);
console.log(`  Config: ${colors.yellow}~/.claude/session-config${colors.reset}`);
console.log(`  Sessions: ${colors.yellow}~/.claude/sessions/${colors.reset}`);
console.log();

console.log(`${colors.green}✨ Ready to use!${colors.reset}`);
console.log(`Try ${colors.blue}csm status${colors.reset} or use ${colors.blue}/continue${colors.reset} in Claude Code\n`);