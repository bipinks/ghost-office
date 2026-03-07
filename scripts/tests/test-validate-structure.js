/**
 * Unit tests for scripts/validate-structure.js — frontmatter parsing and validation functions.
 * Tests the exported-via-require internal functions by re-implementing the pure logic.
 */

const fs = require('fs');
const path = require('path');

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

// --- Re-implement pure functions from validate-structure.js for unit testing ---
// (The original file only exports main(), so we test the logic directly)

function extractFrontmatter(content) {
  if (!content.startsWith('---\n') && !content.startsWith('---\r\n')) {
    return null;
  }
  const lines = content.split(/\r?\n/);
  const end = lines.indexOf('---', 1);
  if (end === -1) {
    return null;
  }
  return lines.slice(1, end).join('\n');
}

function hasFrontmatterKey(frontmatter, key) {
  if (!frontmatter) return false;
  const pattern = new RegExp(`^${key}:`, 'm');
  return pattern.test(frontmatter);
}

function parseTopLevelName(frontmatter) {
  if (!frontmatter) return null;
  const match = frontmatter.match(/^name:\s*["']?([^"'\n]+)["']?\s*$/m);
  return match ? match[1].trim() : null;
}

function parseBoolean(frontmatter, key) {
  const match = frontmatter && frontmatter.match(new RegExp(`^${key}:\\s*(true|false)\\s*$`, 'm'));
  if (!match) return null;
  return match[1] === 'true';
}

function run() {
  console.log('  validate-structure.js tests');

  // --- extractFrontmatter ---
  assert(
    extractFrontmatter('---\nname: test\n---\nbody') === 'name: test',
    'extractFrontmatter: basic case'
  );

  assert(
    extractFrontmatter('---\nname: test\ndescription: desc\n---\nbody') === 'name: test\ndescription: desc',
    'extractFrontmatter: multi-key'
  );

  assert(
    extractFrontmatter('no frontmatter here') === null,
    'extractFrontmatter: no frontmatter returns null'
  );

  assert(
    extractFrontmatter('---\nname: test\nno closing') === null,
    'extractFrontmatter: unclosed frontmatter returns null'
  );

  assert(
    extractFrontmatter('') === null,
    'extractFrontmatter: empty string returns null'
  );

  assert(
    extractFrontmatter('---\r\nname: test\r\n---\r\nbody') === 'name: test',
    'extractFrontmatter: Windows line endings'
  );

  assert(
    extractFrontmatter('---\n---\nbody') === '',
    'extractFrontmatter: empty frontmatter returns empty string'
  );

  // --- hasFrontmatterKey ---
  assert(
    hasFrontmatterKey('name: test\ndescription: desc', 'name') === true,
    'hasFrontmatterKey: finds existing key'
  );

  assert(
    hasFrontmatterKey('name: test\ndescription: desc', 'description') === true,
    'hasFrontmatterKey: finds second key'
  );

  assert(
    hasFrontmatterKey('name: test', 'tools') === false,
    'hasFrontmatterKey: missing key returns false'
  );

  assert(
    hasFrontmatterKey(null, 'name') === false,
    'hasFrontmatterKey: null frontmatter returns false'
  );

  assert(
    hasFrontmatterKey('model: opus\nname: test', 'name') === true,
    'hasFrontmatterKey: key not at start of content'
  );

  assert(
    hasFrontmatterKey('username: test', 'name') === false,
    'hasFrontmatterKey: should not match partial key (username vs name)'
  );

  // --- parseTopLevelName ---
  assert(
    parseTopLevelName('name: my-agent') === 'my-agent',
    'parseTopLevelName: simple name'
  );

  assert(
    parseTopLevelName('name: "quoted-name"') === 'quoted-name',
    'parseTopLevelName: double-quoted name'
  );

  assert(
    parseTopLevelName("name: 'single-quoted'") === 'single-quoted',
    'parseTopLevelName: single-quoted name'
  );

  assert(
    parseTopLevelName('description: foo\nname: bar\nmodel: opus') === 'bar',
    'parseTopLevelName: name in middle of frontmatter'
  );

  assert(
    parseTopLevelName(null) === null,
    'parseTopLevelName: null frontmatter returns null'
  );

  assert(
    parseTopLevelName('description: no name here') === null,
    'parseTopLevelName: missing name returns null'
  );

  assert(
    parseTopLevelName('name:   spaced-name   ') === 'spaced-name',
    'parseTopLevelName: trims whitespace'
  );

  // --- parseBoolean ---
  assert(
    parseBoolean('disable-model-invocation: true', 'disable-model-invocation') === true,
    'parseBoolean: true value'
  );

  assert(
    parseBoolean('disable-model-invocation: false', 'disable-model-invocation') === false,
    'parseBoolean: false value'
  );

  assert(
    parseBoolean('name: test', 'disable-model-invocation') === null,
    'parseBoolean: missing key returns null'
  );

  assert(
    parseBoolean(null, 'key') === null,
    'parseBoolean: null frontmatter returns null'
  );

  assert(
    parseBoolean('user-invocable: true\nname: test', 'user-invocable') === true,
    'parseBoolean: hyphenated key with true'
  );

  // --- Test actual agent files have valid frontmatter ---
  const root = path.resolve(__dirname, '..', '..');
  const agentsDir = path.join(root, '.claude', 'agents');
  const agentFiles = fs.readdirSync(agentsDir).filter(f => f.endsWith('.md'));

  agentFiles.forEach(file => {
    const content = fs.readFileSync(path.join(agentsDir, file), 'utf8');
    const fm = extractFrontmatter(content);
    assert(fm !== null, `Agent ${file}: has frontmatter`);
    assert(hasFrontmatterKey(fm, 'name'), `Agent ${file}: has name`);
    assert(hasFrontmatterKey(fm, 'description'), `Agent ${file}: has description`);
    assert(hasFrontmatterKey(fm, 'tools'), `Agent ${file}: has tools`);
    assert(hasFrontmatterKey(fm, 'model'), `Agent ${file}: has model`);
    const name = parseTopLevelName(fm);
    assert(name !== null && name.length > 0, `Agent ${file}: name is non-empty`);
  });

  // --- Test actual command files have valid frontmatter ---
  const commandsDir = path.join(root, '.claude', 'commands');
  const commandFiles = fs.readdirSync(commandsDir).filter(f => f.endsWith('.md'));

  commandFiles.forEach(file => {
    const content = fs.readFileSync(path.join(commandsDir, file), 'utf8');
    const fm = extractFrontmatter(content);
    assert(fm !== null, `Command ${file}: has frontmatter`);
    assert(hasFrontmatterKey(fm, 'name'), `Command ${file}: has name`);
    assert(hasFrontmatterKey(fm, 'description'), `Command ${file}: has description`);
    assert(hasFrontmatterKey(fm, 'argument-hint'), `Command ${file}: has argument-hint`);
  });

  // --- Test command bodies include $ARGUMENTS ---
  commandFiles.forEach(file => {
    const content = fs.readFileSync(path.join(commandsDir, file), 'utf8');
    assert(content.includes('$ARGUMENTS'), `Command ${file}: uses $ARGUMENTS`);
  });

  // --- Test skill directories have SKILL.md ---
  const skillsDir = path.join(root, '.claude', 'skills');
  const skillDirs = fs.readdirSync(skillsDir).filter(name =>
    fs.statSync(path.join(skillsDir, name)).isDirectory()
  );

  skillDirs.forEach(dir => {
    const skillFile = path.join(skillsDir, dir, 'SKILL.md');
    assert(fs.existsSync(skillFile), `Skill ${dir}: has SKILL.md`);
    if (fs.existsSync(skillFile)) {
      const content = fs.readFileSync(skillFile, 'utf8');
      const fm = extractFrontmatter(content);
      assert(fm !== null, `Skill ${dir}: SKILL.md has frontmatter`);
      assert(hasFrontmatterKey(fm, 'name'), `Skill ${dir}: has name`);
      assert(hasFrontmatterKey(fm, 'description'), `Skill ${dir}: has description`);
    }
  });

  // --- Test name uniqueness across agents ---
  const agentNames = new Set();
  let duplicateAgents = false;
  agentFiles.forEach(file => {
    const content = fs.readFileSync(path.join(agentsDir, file), 'utf8');
    const fm = extractFrontmatter(content);
    const name = parseTopLevelName(fm);
    if (name && agentNames.has(name)) duplicateAgents = true;
    if (name) agentNames.add(name);
  });
  assert(!duplicateAgents, 'Agent names should be unique');

  // --- Test name uniqueness across commands ---
  const commandNames = new Set();
  let duplicateCommands = false;
  commandFiles.forEach(file => {
    const content = fs.readFileSync(path.join(commandsDir, file), 'utf8');
    const fm = extractFrontmatter(content);
    const name = parseTopLevelName(fm);
    if (name && commandNames.has(name)) duplicateCommands = true;
    if (name) commandNames.add(name);
  });
  assert(!duplicateCommands, 'Command names should be unique');

  return { passed, failed };
}

module.exports = { run };
