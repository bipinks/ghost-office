/**
 * Test runner — executes all project validation tests.
 *
 * Usage: node scripts/tests/run-all.js
 *
 * Test suites:
 *   1. JSON file validation (inline)
 *   2. Project structure validation (validate-structure.js)
 *   3. YAML frontmatter presence (inline)
 *   4. Required root files (inline)
 *   5. MCP config placeholder hygiene (inline)
 *   6. .claude directory structure (inline)
 *   7. Utility library (test-utils.js)
 *   8. Frontmatter & validation logic (test-validate-structure.js)
 *   9. Hook scripts (test-hooks.js)
 *  10. Settings & config (test-settings.js)
 *  11. Content integrity (test-content-integrity.js)
 */

const { execSync } = require('child_process');
const path = require('path');

function main() {
  const root = path.resolve(__dirname, '..', '..');
  let totalPassed = 0;
  let totalFailed = 0;
  let suiteCount = 0;

  console.log('Running all tests...\n');

  // --- Helper: run inline test ---
  function inlineTest(name, fn) {
    suiteCount++;
    console.log(`Test ${suiteCount}: ${name}`);
    try {
      fn();
      console.log('  PASS');
      totalPassed++;
    } catch (e) {
      console.log(`  FAIL — ${e.message || e}`);
      totalFailed++;
    }
  }

  // --- Helper: run module test suite ---
  function moduleTest(name, modulePath) {
    suiteCount++;
    console.log(`Test ${suiteCount}: ${name}`);
    try {
      const suite = require(modulePath);
      const result = suite.run();
      if (result.failed > 0) {
        console.log(`  PARTIAL — ${result.passed} passed, ${result.failed} failed`);
        totalPassed += result.passed;
        totalFailed += result.failed;
      } else {
        console.log(`  PASS — ${result.passed} checks`);
        totalPassed += result.passed;
      }
    } catch (e) {
      console.log(`  FAIL — ${e.message || e}`);
      totalFailed++;
    }
  }

  // ==========================================
  // Inline tests (original 6)
  // ==========================================

  // Test 1: JSON validation
  inlineTest('JSON file validation', () => {
    const fs = require('fs');
    const files = ['.claude/settings.json', '.mcp.json', 'package.json'];
    files.forEach(f => JSON.parse(fs.readFileSync(path.join(root, f), 'utf8')));
  });

  // Test 2: Structure validation
  inlineTest('Project structure validation', () => {
    execSync('node scripts/validate-structure.js', { cwd: root, stdio: 'pipe' });
  });

  // Test 3: Frontmatter presence
  inlineTest('YAML frontmatter in all agents/commands', () => {
    const fs = require('fs');
    ['.claude/agents', '.claude/commands'].forEach(dir => {
      const fullDir = path.join(root, dir);
      fs.readdirSync(fullDir).filter(f => f.endsWith('.md')).forEach(f => {
        const content = fs.readFileSync(path.join(fullDir, f), 'utf8');
        if (!content.startsWith('---')) throw new Error(`${dir}/${f} missing frontmatter`);
      });
    });
  });

  // Test 4: Required files
  inlineTest('Required root files', () => {
    const fs = require('fs');
    ['README.md', 'CLAUDE.md', 'AGENTS.md', 'LICENSE', 'CONTRIBUTING.md', 'BEGINNERS-GUIDE.md', '.gitignore'].forEach(f => {
      if (!fs.existsSync(path.join(root, f))) throw new Error(`Missing: ${f}`);
    });
  });

  // Test 5: MCP config placeholder hygiene
  inlineTest('MCP config placeholder hygiene', () => {
    const fs = require('fs');
    const text = fs.readFileSync(path.join(root, '.mcp.json'), 'utf8');
    const banned = [/<your-/i, /\/path\/to\/project/i, /your-org/i];
    const found = banned.find(r => r.test(text));
    if (found) throw new Error(`Found banned MCP placeholder pattern: ${found}`);
  });

  // Test 6: .claude directory structure
  inlineTest('.claude directory structure', () => {
    const fs = require('fs');
    const dirs = ['.claude/agents', '.claude/commands', '.claude/skills', '.claude/rules'];
    dirs.forEach(d => {
      const fullDir = path.join(root, d);
      if (!fs.existsSync(fullDir)) throw new Error(`Missing directory: ${d}`);
      const entries = fs.readdirSync(fullDir);
      if (entries.length === 0) throw new Error(`Empty directory: ${d}`);
    });
  });

  // ==========================================
  // Module test suites (new)
  // ==========================================

  moduleTest('Utility library (utils.js)', './test-utils');
  moduleTest('Frontmatter & validation logic', './test-validate-structure');
  moduleTest('Hook scripts', './test-hooks');
  moduleTest('Settings & MCP config', './test-settings');
  moduleTest('Content integrity', './test-content-integrity');

  // ==========================================
  // Summary
  // ==========================================
  console.log(`\n${'='.repeat(50)}`);
  console.log(`Results: ${totalPassed} passed, ${totalFailed} failed (${suiteCount} suites)`);
  console.log(`${'='.repeat(50)}\n`);

  process.exit(totalFailed > 0 ? 1 : 0);
}

main();
