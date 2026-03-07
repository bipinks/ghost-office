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
 *  12. Agent skill-mapping validation (inline)
 *  13. Frontmatter schema validation (inline)
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

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
    const files = ['.claude/settings.json', '.mcp.json', 'package.json'];
    files.forEach(f => JSON.parse(fs.readFileSync(path.join(root, f), 'utf8')));
  });

  // Test 2: Structure validation
  inlineTest('Project structure validation', () => {
    execSync('node scripts/validate-structure.js', { cwd: root, stdio: 'pipe' });
  });

  // Test 3: Frontmatter presence
  inlineTest('YAML frontmatter in all agents/commands', () => {
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
    ['README.md', 'CLAUDE.md', 'AGENTS.md', 'LICENSE', 'CONTRIBUTING.md', 'BEGINNERS-GUIDE.md', '.gitignore'].forEach(f => {
      if (!fs.existsSync(path.join(root, f))) throw new Error(`Missing: ${f}`);
    });
  });

  // Test 5: MCP config placeholder hygiene
  inlineTest('MCP config placeholder hygiene', () => {
    const text = fs.readFileSync(path.join(root, '.mcp.json'), 'utf8');
    const banned = [/<your-/i, /\/path\/to\/project/i, /your-org/i];
    const found = banned.find(r => r.test(text));
    if (found) throw new Error(`Found banned MCP placeholder pattern: ${found}`);
  });

  // Test 6: .claude directory structure
  inlineTest('.claude directory structure', () => {
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
  // Shared: pre-read agent files for Tests 12 & 13
  // ==========================================
  const agentsDir = path.join(root, '.claude', 'agents');
  const skillsDir = path.join(root, '.claude', 'skills');
  const commandsDir = path.join(root, '.claude', 'commands');
  const agentFileCache = new Map();
  fs.readdirSync(agentsDir).filter(f => f.endsWith('.md')).forEach(file => {
    agentFileCache.set(file, fs.readFileSync(path.join(agentsDir, file), 'utf8'));
  });

  // ==========================================
  // Test 12: Agent skill-mapping validation
  // ==========================================
  inlineTest('Agent skill-mapping validation', () => {
    const agentFiles = Array.from(agentFileCache.keys());
    const skillDirs = fs.existsSync(skillsDir)
      ? fs.readdirSync(skillsDir).filter(name => fs.statSync(path.join(skillsDir, name)).isDirectory())
      : [];
    const errors = [];
    const referencedSkills = new Set();

    // Extract skills from each agent's frontmatter and verify they exist
    agentFiles.forEach(file => {
      const content = agentFileCache.get(file);
      if (!content.startsWith('---')) return;
      const lines = content.split(/\r?\n/);
      const endIdx = lines.indexOf('---', 1);
      if (endIdx === -1) return;
      const frontmatter = lines.slice(1, endIdx).join('\n');

      // Parse skills array from frontmatter (YAML format: skills: ["a", "b"] or skills:\n  - a)
      const inlineMatch = frontmatter.match(/^skills:\s*\[([^\]]*)\]/m);
      let skills = [];
      if (inlineMatch) {
        skills = inlineMatch[1]
          .split(',')
          .map(s => s.trim().replace(/^["']|["']$/g, ''))
          .filter(s => s.length > 0);
      } else {
        // Try YAML list format
        const listMatch = frontmatter.match(/^skills:\s*\n((?:\s+-\s+.+\n?)+)/m);
        if (listMatch) {
          skills = listMatch[1]
            .split('\n')
            .map(line => line.replace(/^\s+-\s+/, '').replace(/["']/g, '').trim())
            .filter(s => s.length > 0);
        }
      }

      const agentName = file.replace('.md', '');
      skills.forEach(skill => {
        referencedSkills.add(skill);
        const skillPath = path.join(skillsDir, skill, 'SKILL.md');
        if (!fs.existsSync(skillPath)) {
          errors.push(`Agent ${agentName} references skill '${skill}' which does not exist`);
        }
      });
    });

    // Check for orphaned skills (not referenced by any agent)
    const orphanedSkills = skillDirs.filter(dir => !referencedSkills.has(dir));
    if (orphanedSkills.length > 0) {
      console.log(`  WARN: ${orphanedSkills.length} orphaned skill(s) not referenced by any agent: ${orphanedSkills.join(', ')}`);
    }

    if (errors.length > 0) {
      throw new Error(errors.join('; '));
    }
  });

  // ==========================================
  // Test 13: Frontmatter schema validation
  // ==========================================
  inlineTest('Frontmatter schema validation', () => {
    const errors = [];
    const lineSplitRe = /\r?\n/;
    const quoteStripRe = /^["']|["']$/g;

    function extractFm(content) {
      if (!content.startsWith('---')) return null;
      const lines = content.split(lineSplitRe);
      const endIdx = lines.indexOf('---', 1);
      if (endIdx === -1) return null;
      return lines.slice(1, endIdx).join('\n');
    }

    // Pre-compiled regex cache for hasKey and parseArrayField
    const regexCache = {};
    function getKeyRegexes(key) {
      if (!regexCache[key]) {
        regexCache[key] = {
          has: new RegExp(`^${key}:`, 'm'),
          inline: new RegExp(`^${key}:\\s*\\[([^\\]]*)\\]`, 'm'),
          list: new RegExp(`^${key}:\\s*\\n((?:\\s+-\\s+.+\\n?)+)`, 'm'),
        };
      }
      return regexCache[key];
    }

    function hasKey(fm, key) {
      return getKeyRegexes(key).has.test(fm);
    }

    function parseArrayField(fm, key) {
      const re = getKeyRegexes(key);
      const inlineMatch = fm.match(re.inline);
      if (inlineMatch) {
        return inlineMatch[1].split(',').map(s => s.trim().replace(quoteStripRe, '')).filter(s => s.length > 0);
      }
      const listMatch = fm.match(re.list);
      if (listMatch) {
        return listMatch[1].split('\n').map(l => l.replace(/^\s+-\s+/, '').replace(/["']/g, '').trim()).filter(s => s.length > 0);
      }
      return null;
    }

    // Validate agent frontmatter: name, description, tools (array), model
    Array.from(agentFileCache.keys()).forEach(file => {
      const content = agentFileCache.get(file);
      const fm = extractFm(content);
      if (!fm) {
        errors.push(`Agent ${file}: missing frontmatter`);
        return;
      }
      ['name', 'description', 'model'].forEach(key => {
        if (!hasKey(fm, key)) errors.push(`Agent ${file}: missing required field '${key}'`);
      });
      if (!hasKey(fm, 'tools')) {
        errors.push(`Agent ${file}: missing required field 'tools'`);
      } else {
        const tools = parseArrayField(fm, 'tools');
        if (!tools || tools.length === 0) {
          errors.push(`Agent ${file}: 'tools' must be a non-empty array`);
        }
      }
    });

    // Validate skill frontmatter: name, description, user-invocable
    if (fs.existsSync(skillsDir)) {
      fs.readdirSync(skillsDir)
        .filter(name => fs.statSync(path.join(skillsDir, name)).isDirectory())
        .forEach(skillDir => {
          const skillPath = path.join(skillsDir, skillDir, 'SKILL.md');
          if (!fs.existsSync(skillPath)) return; // already caught by other tests
          const content = fs.readFileSync(skillPath, 'utf8');
          const fm = extractFm(content);
          if (!fm) {
            errors.push(`Skill ${skillDir}/SKILL.md: missing frontmatter`);
            return;
          }
          ['name', 'description', 'user-invocable'].forEach(key => {
            if (!hasKey(fm, key)) errors.push(`Skill ${skillDir}/SKILL.md: missing required field '${key}'`);
          });
        });
    }

    // Validate command frontmatter: name, description
    fs.readdirSync(commandsDir).filter(f => f.endsWith('.md')).forEach(file => {
      const content = fs.readFileSync(path.join(commandsDir, file), 'utf8');
      const fm = extractFm(content);
      if (!fm) {
        errors.push(`Command ${file}: missing frontmatter`);
        return;
      }
      ['name', 'description'].forEach(key => {
        if (!hasKey(fm, key)) errors.push(`Command ${file}: missing required field '${key}'`);
      });
    });

    if (errors.length > 0) {
      throw new Error(errors.join('; '));
    }
  });

  // ==========================================
  // Summary
  // ==========================================
  console.log(`\n${'='.repeat(50)}`);
  console.log(`Results: ${totalPassed} passed, ${totalFailed} failed (${suiteCount} suites)`);
  console.log(`${'='.repeat(50)}\n`);

  process.exit(totalFailed > 0 ? 1 : 0);
}

main();
