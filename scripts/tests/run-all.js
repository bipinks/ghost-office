/**
 * Test runner — executes all project validation tests.
 *
 * Usage: node scripts/tests/run-all.js
 */

const { execSync } = require('child_process');
const path = require('path');

function main() {
  const root = path.resolve(__dirname, '..', '..');
  let passed = 0;
  let failed = 0;

  console.log('Running all tests...\n');

  // Test 1: JSON validation
  console.log('Test 1: JSON file validation');
  try {
    execSync(`node -e "
      const fs = require('fs');
      const files = [
        '.claude/settings.json',
        '.mcp.json',
        'package.json'
      ];
      files.forEach(f => JSON.parse(fs.readFileSync(f, 'utf8')));
    "`, { cwd: root, stdio: 'pipe' });
    console.log('  PASS - All JSON files are valid');
    passed++;
  } catch (e) {
    console.log('  FAIL - JSON validation failed');
    failed++;
  }

  // Test 2: Structure validation
  console.log('Test 2: Project structure validation');
  try {
    execSync('node scripts/validate-structure.js', { cwd: root, stdio: 'pipe' });
    console.log('  PASS - Structure is valid');
    passed++;
  } catch {
    console.log('  FAIL - Structure validation failed');
    failed++;
  }

  // Test 3: Frontmatter presence
  console.log('Test 3: YAML frontmatter in all agents/commands');
  try {
    execSync(`node -e "
      const fs = require('fs');
      const path = require('path');
      ['.claude/agents', '.claude/commands'].forEach(dir => {
        fs.readdirSync(dir).filter(f => f.endsWith('.md')).forEach(f => {
          const content = fs.readFileSync(path.join(dir, f), 'utf8');
          if (!content.startsWith('---')) throw new Error(dir + '/' + f + ' missing frontmatter');
        });
      });
    "`, { cwd: root, stdio: 'pipe' });
    console.log('  PASS - All files have frontmatter');
    passed++;
  } catch (e) {
    console.log('  FAIL - Frontmatter check failed');
    failed++;
  }

  // Test 4: Required files
  console.log('Test 4: Required root files');
  try {
    execSync(`node -e "
      const fs = require('fs');
      ['README.md','CLAUDE.md','AGENTS.md','LICENSE','CONTRIBUTING.md','.gitignore','BEGINNERS-GUIDE.md'].forEach(f => {
        if (!fs.existsSync(f)) throw new Error('Missing: ' + f);
      });
    "`, { cwd: root, stdio: 'pipe' });
    console.log('  PASS - All required files present');
    passed++;
  } catch (e) {
    console.log('  FAIL - Missing required files');
    failed++;
  }

  // Test 5: MCP config placeholder hygiene
  console.log('Test 5: MCP config placeholder hygiene');
  try {
    execSync(`node -e "
      const fs = require('fs');
      const text = fs.readFileSync('.mcp.json', 'utf8');
      const banned = [/<your-/i, /\\/path\\/to\\/project/i, /your-org/i];
      const found = banned.find(r => r.test(text));
      if (found) throw new Error('Found banned MCP placeholder pattern: ' + found);
    "`, { cwd: root, stdio: 'pipe' });
    console.log('  PASS - MCP config has no dummy placeholders');
    passed++;
  } catch (e) {
    console.log('  FAIL - MCP placeholder check failed');
    failed++;
  }

  // Test 6: .claude directory structure
  console.log('Test 6: .claude directory structure');
  try {
    execSync(`node -e "
      const fs = require('fs');
      const dirs = ['.claude/agents', '.claude/commands', '.claude/skills', '.claude/rules'];
      dirs.forEach(d => {
        if (!fs.existsSync(d)) throw new Error('Missing directory: ' + d);
        const entries = fs.readdirSync(d);
        if (entries.length === 0) throw new Error('Empty directory: ' + d);
      });
    "`, { cwd: root, stdio: 'pipe' });
    console.log('  PASS - .claude directories are populated');
    passed++;
  } catch (e) {
    console.log('  FAIL - .claude directory check failed');
    failed++;
  }

  // Summary
  console.log(`\n${'='.repeat(40)}`);
  console.log(`Results: ${passed} passed, ${failed} failed`);
  console.log(`${'='.repeat(40)}\n`);

  process.exit(failed > 0 ? 1 : 0);
}

main();
