/**
 * Ghost Office — Utility Library
 * Cross-platform utilities for file, path, and system operations.
 */

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

/**
 * Get the project root directory.
 */
function getProjectRoot() {
  let dir = __dirname;
  while (dir !== path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, '.claude-plugin'))) {
      return dir;
    }
    dir = path.dirname(dir);
  }
  return process.cwd();
}

/**
 * Read a JSON file safely.
 */
function readJSON(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(content);
  } catch (error) {
    console.error(`Failed to read JSON: ${filePath}`, error.message);
    return null;
  }
}

/**
 * Write a JSON file with formatting.
 */
function writeJSON(filePath, data) {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2) + '\n');
}

/**
 * Get the current timestamp in ISO format.
 */
function getTimestamp() {
  return new Date().toISOString();
}

/**
 * Check if a command exists in PATH.
 */
function commandExists(cmd) {
  try {
    execSync(`which ${cmd}`, { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

/**
 * Get system information.
 */
function getSystemInfo() {
  return {
    platform: os.platform(),
    arch: os.arch(),
    nodeVersion: process.version,
    hostname: os.hostname(),
    user: os.userInfo().username,
  };
}

/**
 * Find files matching a pattern recursively.
 */
function findFiles(dir, pattern) {
  const results = [];
  const regex = new RegExp(pattern);

  function walk(currentDir) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(currentDir, entry.name);
      if (entry.isDirectory() && !entry.name.startsWith('.') && entry.name !== 'node_modules') {
        walk(fullPath);
      } else if (entry.isFile() && regex.test(entry.name)) {
        results.push(fullPath);
      }
    }
  }

  walk(dir);
  return results;
}

module.exports = {
  getProjectRoot,
  readJSON,
  writeJSON,
  getTimestamp,
  commandExists,
  getSystemInfo,
  findFiles,
};
