/**
 * Unit tests for scripts/lib/utils.js
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const {
  getProjectRoot,
  readJSON,
  writeJSON,
  getTimestamp,
  commandExists,
  getSystemInfo,
  findFiles,
} = require('../lib/utils');

let passed = 0;
let failed = 0;

function assert(condition, message) {
  if (condition) {
    passed++;
  } else {
    console.log(`    FAIL: ${message}`);
    failed++;
  }
}

function test(name, fn) {
  try {
    fn();
  } catch (e) {
    console.log(`    FAIL: ${name} — ${e.message}`);
    failed++;
  }
}

function run() {
  console.log('  utils.js tests');

  // --- getProjectRoot ---
  test('getProjectRoot returns a directory', () => {
    const root = getProjectRoot();
    assert(typeof root === 'string' && root.length > 0, 'getProjectRoot returns empty');
    assert(fs.existsSync(root), 'getProjectRoot returns non-existent path');
  });

  // --- readJSON ---
  test('readJSON parses valid JSON', () => {
    const pkgPath = path.join(getProjectRoot(), 'package.json');
    const result = readJSON(pkgPath);
    assert(result !== null, 'readJSON returned null for valid file');
    assert(result.name === 'devops-agent-hub', 'readJSON: unexpected package name');
  });

  test('readJSON returns null for invalid file', () => {
    // Suppress expected error output
    const origError = console.error;
    console.error = () => {};
    const result = readJSON('/nonexistent/file.json');
    console.error = origError;
    assert(result === null, 'readJSON should return null for missing file');
  });

  test('readJSON returns null for non-JSON', () => {
    const tmpFile = path.join(os.tmpdir(), 'test-invalid.json');
    fs.writeFileSync(tmpFile, 'not json {{{');
    const origError = console.error;
    console.error = () => {};
    const result = readJSON(tmpFile);
    console.error = origError;
    assert(result === null, 'readJSON should return null for invalid JSON');
    fs.unlinkSync(tmpFile);
  });

  // --- writeJSON ---
  test('writeJSON creates file with formatted content', () => {
    const tmpFile = path.join(os.tmpdir(), 'test-write.json');
    const data = { hello: 'world', count: 42 };
    writeJSON(tmpFile, data);
    assert(fs.existsSync(tmpFile), 'writeJSON did not create file');
    const content = fs.readFileSync(tmpFile, 'utf8');
    assert(content.endsWith('\n'), 'writeJSON should end with newline');
    const parsed = JSON.parse(content);
    assert(parsed.hello === 'world', 'writeJSON data mismatch');
    assert(parsed.count === 42, 'writeJSON numeric data mismatch');
    fs.unlinkSync(tmpFile);
  });

  test('writeJSON creates parent directories', () => {
    const tmpDir = path.join(os.tmpdir(), `test-writejson-${Date.now()}`);
    const tmpFile = path.join(tmpDir, 'nested', 'deep', 'file.json');
    writeJSON(tmpFile, { nested: true });
    assert(fs.existsSync(tmpFile), 'writeJSON should create nested dirs');
    // Cleanup
    fs.rmSync(tmpDir, { recursive: true });
  });

  // --- getTimestamp ---
  test('getTimestamp returns ISO format', () => {
    const ts = getTimestamp();
    assert(typeof ts === 'string', 'getTimestamp should return string');
    assert(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(ts), 'getTimestamp should match ISO format');
    // Should parse without error
    const d = new Date(ts);
    assert(!isNaN(d.getTime()), 'getTimestamp should produce valid date');
  });

  // --- commandExists ---
  test('commandExists returns true for node', () => {
    assert(commandExists('node') === true, 'node should exist');
  });

  test('commandExists returns false for nonexistent command', () => {
    assert(commandExists('definitely_not_a_real_command_xyz123') === false, 'fake command should not exist');
  });

  // --- getSystemInfo ---
  test('getSystemInfo returns expected fields', () => {
    const info = getSystemInfo();
    assert(typeof info.platform === 'string', 'missing platform');
    assert(typeof info.arch === 'string', 'missing arch');
    assert(typeof info.nodeVersion === 'string', 'missing nodeVersion');
    assert(info.nodeVersion.startsWith('v'), 'nodeVersion should start with v');
    assert(typeof info.hostname === 'string', 'missing hostname');
    assert(typeof info.user === 'string', 'missing user');
  });

  // --- findFiles ---
  test('findFiles finds markdown files', () => {
    const root = getProjectRoot();
    const results = findFiles(path.join(root, '.claude', 'agents'), '\\.md$');
    assert(Array.isArray(results), 'findFiles should return array');
    assert(results.length > 0, 'findFiles should find agent .md files');
    assert(results.every(f => f.endsWith('.md')), 'all results should be .md');
  });

  test('findFiles returns empty for no matches', () => {
    const root = getProjectRoot();
    const results = findFiles(root, '\\.xyz_nonexistent$');
    assert(Array.isArray(results), 'findFiles should return array');
    assert(results.length === 0, 'findFiles should return empty for no matches');
  });

  test('findFiles skips node_modules and dot directories', () => {
    const root = getProjectRoot();
    const results = findFiles(root, '\\.json$');
    const hasNodeModules = results.some(f => f.includes('node_modules'));
    assert(!hasNodeModules, 'findFiles should skip node_modules');
  });

  return { passed, failed };
}

module.exports = { run };
