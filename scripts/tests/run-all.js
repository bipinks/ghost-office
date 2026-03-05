/**
 * Test runner — executes all project validation tests.
 *
 * Usage: node scripts/tests/run-all.js
 */

const { execSync } = require('child_process');
const path = require('path');

function commandExists(cmd, cwd) {
  try {
    execSync(`command -v ${cmd}`, { cwd, stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function main() {
  const root = path.resolve(__dirname, '..', '..');
  let passed = 0;
  let failed = 0;

  console.log('🧪 Running all tests...\n');

  // Test 1: JSON validation
  console.log('Test 1: JSON file validation');
  try {
    execSync(`node -e "
      const fs = require('fs');
      const files = [
        '.claude-plugin/plugin.json',
        '.claude-plugin/marketplace.json',
        'hooks/hooks.json',
        'mcp-configs/mcp-servers.json',
        'package.json'
      ];
      files.forEach(f => JSON.parse(fs.readFileSync(f, 'utf8')));
    "`, { cwd: root, stdio: 'pipe' });
    console.log('  ✅ All JSON files are valid');
    passed++;
  } catch (e) {
    console.log('  ❌ JSON validation failed');
    failed++;
  }

  // Test 2: Structure validation
  console.log('Test 2: Project structure validation');
  try {
    execSync('node scripts/validate-structure.js', { cwd: root, stdio: 'pipe' });
    console.log('  ✅ Structure is valid');
    passed++;
  } catch {
    console.log('  ❌ Structure validation failed');
    failed++;
  }

  // Test 3: Frontmatter presence
  console.log('Test 3: YAML frontmatter in all agents/commands');
  try {
    execSync(`node -e "
      const fs = require('fs');
      const path = require('path');
      ['agents', 'commands'].forEach(dir => {
        fs.readdirSync(dir).filter(f => f.endsWith('.md')).forEach(f => {
          const content = fs.readFileSync(path.join(dir, f), 'utf8');
          if (!content.startsWith('---')) throw new Error(dir + '/' + f + ' missing frontmatter');
        });
      });
    "`, { cwd: root, stdio: 'pipe' });
    console.log('  ✅ All files have frontmatter');
    passed++;
  } catch (e) {
    console.log('  ❌ Frontmatter check failed');
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
    console.log('  ✅ All required files present');
    passed++;
  } catch (e) {
    console.log('  ❌ Missing required files');
    failed++;
  }

  // Test 5: Official plugin schema validation
  console.log('Test 5: Official Claude plugin validation');
  if (!commandExists('claude', root)) {
    console.log('  ℹ️  Skipped (claude CLI not found)');
  } else {
    try {
      execSync('claude plugin validate .claude-plugin/plugin.json', { cwd: root, stdio: 'pipe' });
      execSync('claude plugin validate .claude-plugin/marketplace.json', { cwd: root, stdio: 'pipe' });
      console.log('  ✅ Plugin and marketplace manifests are valid');
      passed++;
    } catch (e) {
      console.log('  ❌ Plugin validation failed');
      failed++;
    }
  }

  // Test 6: MCP config must not contain dummy placeholders
  console.log('Test 6: MCP config placeholder hygiene');
  try {
    execSync(`node -e "
      const fs = require('fs');
      const text = fs.readFileSync('mcp-configs/mcp-servers.json', 'utf8');
      const banned = [/<your-/i, /\\/path\\/to\\/project/i, /your-org/i];
      const found = banned.find(r => r.test(text));
      if (found) throw new Error('Found banned MCP placeholder pattern: ' + found);
    "`, { cwd: root, stdio: 'pipe' });
    console.log('  ✅ MCP config has no dummy placeholders');
    passed++;
  } catch (e) {
    console.log('  ❌ MCP placeholder check failed');
    failed++;
  }

  // Summary
  console.log(`\n${'='.repeat(40)}`);
  console.log(`Results: ${passed} passed, ${failed} failed`);
  console.log(`${'='.repeat(40)}\n`);

  process.exit(failed > 0 ? 1 : 0);
}

main();
