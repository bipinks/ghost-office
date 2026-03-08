/**
 * Tests for .claude/settings.json and .mcp.json structure and integrity.
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

const ROOT = path.resolve(__dirname, '..', '..');

function run() {
  console.log('  settings & config tests');

  // ==========================================
  // .claude/settings.json
  // ==========================================

  const settingsPath = path.join(ROOT, '.claude', 'settings.json');
  const settingsRaw = fs.readFileSync(settingsPath, 'utf8');
  let settings;

  try {
    settings = JSON.parse(settingsRaw);
    passed++;
  } catch {
    console.log('    FAIL: settings.json is not valid JSON');
    failed++;
    return { passed, failed };
  }

  // Top-level keys
  assert(settings.project_type === 'ai_software_company', 'settings: project_type');
  assert(settings.autonomy_enabled === true, 'settings: autonomy_enabled');
  assert(settings.logging_enabled === true, 'settings: logging_enabled');

  // Permissions structure
  assert(typeof settings.permissions === 'object', 'settings: permissions is object');
  assert(Array.isArray(settings.permissions.allow), 'settings: permissions.allow is array');
  assert(Array.isArray(settings.permissions.deny), 'settings: permissions.deny is array');

  // Required allowed tools
  const requiredAllowed = ['Read', 'Glob', 'Grep', 'TodoWrite', 'Agent', 'WebSearch'];
  requiredAllowed.forEach(tool => {
    assert(settings.permissions.allow.includes(tool), `settings: allow includes ${tool}`);
  });

  // Required deny patterns
  assert(settings.permissions.deny.some(d => d.includes('rm -rf')), 'settings: deny includes rm -rf');
  assert(settings.permissions.deny.some(d => d.includes('terraform destroy')), 'settings: deny includes terraform destroy');
  assert(settings.permissions.deny.some(d => d.includes('DROP DATABASE')), 'settings: deny includes DROP DATABASE');
  assert(settings.permissions.deny.some(d => d.includes('force') && d.includes('main')), 'settings: deny includes force-push to main');

  // Hooks structure
  assert(typeof settings.hooks === 'object', 'settings: hooks is object');

  const expectedEvents = ['SessionStart', 'PreToolUse', 'PostToolUse', 'PostToolUseFailure', 'Stop', 'PreCompact'];
  expectedEvents.forEach(event => {
    assert(Array.isArray(settings.hooks[event]), `settings: hooks.${event} is array`);
  });

  // PreToolUse should have Bash and MS365 matchers
  const preToolUse = settings.hooks.PreToolUse;
  assert(preToolUse.some(h => h.matcher === 'Bash'), 'settings: PreToolUse has Bash matcher');
  assert(preToolUse.some(h => h.matcher && h.matcher.includes('ms365')), 'settings: PreToolUse has MS365 matcher');

  // PostToolUse should have Write|Edit matcher
  const postToolUse = settings.hooks.PostToolUse;
  assert(postToolUse.some(h => h.matcher && h.matcher.includes('Write')), 'settings: PostToolUse has Write matcher');

  // Every hook entry should have type and command
  Object.entries(settings.hooks).forEach(([event, entries]) => {
    if (!Array.isArray(entries)) return;
    entries.forEach((entry, i) => {
      assert(typeof entry.matcher === 'string', `settings: hooks.${event}[${i}] has matcher`);
      assert(Array.isArray(entry.hooks), `settings: hooks.${event}[${i}].hooks is array`);
      entry.hooks.forEach((hook, j) => {
        assert(hook.type === 'command', `settings: hooks.${event}[${i}].hooks[${j}] type is command`);
        assert(typeof hook.command === 'string', `settings: hooks.${event}[${i}].hooks[${j}] has command`);
        // Verify the hook script file exists
        const hookFile = path.join(ROOT, hook.command);
        assert(fs.existsSync(hookFile), `settings: hook file exists: ${hook.command}`);
      });
    });
  });

  // ==========================================
  // .mcp.json
  // ==========================================

  const mcpPath = path.join(ROOT, '.mcp.json');
  let mcp;

  try {
    mcp = JSON.parse(fs.readFileSync(mcpPath, 'utf8'));
    passed++;
  } catch {
    console.log('    FAIL: .mcp.json is not valid JSON');
    failed++;
    return { passed, failed };
  }

  assert(typeof mcp.mcpServers === 'object', 'mcp: has mcpServers object');

  const expectedServers = ['github', 'aws', 'ms365', 'filesystem', 'docker', 'kubernetes'];
  expectedServers.forEach(server => {
    assert(mcp.mcpServers[server] !== undefined, `mcp: has ${server} server`);
    if (mcp.mcpServers[server]) {
      assert(typeof mcp.mcpServers[server].command === 'string', `mcp: ${server} has command`);
      assert(Array.isArray(mcp.mcpServers[server].args), `mcp: ${server} has args array`);
    }
  });

  // MCP should not have dummy placeholder values
  const mcpStr = JSON.stringify(mcp);
  assert(!/<your-/.test(mcpStr), 'mcp: no <your- placeholders');
  assert(!/\/path\/to\/project/.test(mcpStr), 'mcp: no /path/to/project placeholders');
  assert(!/your-org/.test(mcpStr), 'mcp: no your-org placeholders');

  // ==========================================
  // package.json
  // ==========================================

  const pkgPath = path.join(ROOT, 'package.json');
  let pkg;

  try {
    pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    passed++;
  } catch {
    console.log('    FAIL: package.json is not valid JSON');
    failed++;
    return { passed, failed };
  }

  assert(pkg.name === 'ghost-office', 'pkg: correct name');
  assert(typeof pkg.version === 'string', 'pkg: has version');
  assert(typeof pkg.scripts === 'object', 'pkg: has scripts');
  assert(typeof pkg.scripts.test === 'string', 'pkg: has test script');
  assert(typeof pkg.scripts.validate === 'string', 'pkg: has validate script');
  assert(pkg.engines && pkg.engines.node, 'pkg: has engines.node');

  return { passed, failed };
}

module.exports = { run };
