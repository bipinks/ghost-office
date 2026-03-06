/**
 * Project structure validator for Claude Code native layout.
 * Validates .claude/ components, frontmatter, cross-references, and safety guardrails.
 *
 * Usage: node scripts/validate-structure.js
 */

const fs = require('fs');
const path = require('path');
const { getProjectRoot, readJSON } = require('./lib/utils');

function failIf(condition, message, errors) {
  if (condition) {
    errors.push(message);
    return true;
  }
  return false;
}

function readText(filePath) {
  return fs.readFileSync(filePath, 'utf8');
}

function listMarkdownFiles(dirPath) {
  if (!fs.existsSync(dirPath)) return [];
  return fs.readdirSync(dirPath).filter(name => name.endsWith('.md'));
}

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
  if (!frontmatter) {
    return false;
  }
  const pattern = new RegExp(`^${key}:`, 'm');
  return pattern.test(frontmatter);
}

function parseTopLevelName(frontmatter) {
  if (!frontmatter) {
    return null;
  }
  const match = frontmatter.match(/^name:\s*["']?([^"'\n]+)["']?\s*$/m);
  return match ? match[1].trim() : null;
}

function parseBoolean(frontmatter, key) {
  const match = frontmatter && frontmatter.match(new RegExp(`^${key}:\\s*(true|false)\\s*$`, 'm'));
  if (!match) {
    return null;
  }
  return match[1] === 'true';
}

function validateFileFrontmatter(filePath, requiredKeys, label, errors, checks) {
  checks.value += 1;
  const content = readText(filePath);
  const frontmatter = extractFrontmatter(content);
  if (failIf(!frontmatter, `${label} missing valid YAML frontmatter: ${path.relative(process.cwd(), filePath)}`, errors)) {
    return { content, frontmatter: null };
  }

  requiredKeys.forEach(key => {
    checks.value += 1;
    failIf(!hasFrontmatterKey(frontmatter, key), `${label} missing frontmatter key "${key}": ${path.relative(process.cwd(), filePath)}`, errors);
  });

  return { content, frontmatter };
}

function collectNameMap(files, baseDir, requiredKeys, label, errors, checks) {
  const names = new Set();

  files.forEach(file => {
    const filePath = path.join(baseDir, file);
    const { frontmatter } = validateFileFrontmatter(filePath, requiredKeys, label, errors, checks);
    if (!frontmatter) {
      return;
    }

    checks.value += 1;
    const name = parseTopLevelName(frontmatter);
    if (failIf(!name, `${label} missing top-level "name": ${path.relative(process.cwd(), filePath)}`, errors)) {
      return;
    }
    failIf(names.has(name), `${label} has duplicate name "${name}"`, errors);
    names.add(name);
  });

  return names;
}

function validateSettingsHooks(root, errors, checks) {
  const settingsPath = path.join(root, '.claude/settings.json');
  checks.value += 1;
  const settings = readJSON(settingsPath);
  if (!settings) {
    errors.push('Invalid .claude/settings.json');
    return;
  }

  const hooks = settings.hooks;
  failIf(!hooks || typeof hooks !== 'object' || Array.isArray(hooks), '.claude/settings.json must contain "hooks" object', errors);

  ['PreToolUse', 'PostToolUse'].forEach(eventName => {
    checks.value += 1;
    const eventHooks = hooks && hooks[eventName];
    if (failIf(!Array.isArray(eventHooks), `.claude/settings.json: "${eventName}" must be an array`, errors)) {
      return;
    }

    eventHooks.forEach((entry, index) => {
      checks.value += 1;
      failIf(!entry.matcher || typeof entry.matcher !== 'string', `.claude/settings.json: ${eventName}[${index}] missing string matcher`, errors);
      if (failIf(!Array.isArray(entry.hooks), `.claude/settings.json: ${eventName}[${index}].hooks must be an array`, errors)) {
        return;
      }
      entry.hooks.forEach((hook, hookIndex) => {
        checks.value += 1;
        failIf(!hook.type || typeof hook.type !== 'string', `.claude/settings.json: ${eventName}[${index}].hooks[${hookIndex}] missing type`, errors);
        failIf(!hook.command || typeof hook.command !== 'string', `.claude/settings.json: ${eventName}[${index}].hooks[${hookIndex}] missing command`, errors);
      });
    });
  });
}

function validateRulesPaths(root, errors, checks) {
  const requiredRuleDomains = ['terraform', 'kubernetes', 'docker', 'cicd', 'cloud', 'security'];
  requiredRuleDomains.forEach(domain => {
    const filePath = path.join(root, '.claude/rules', domain, 'best-practices.md');
    checks.value += 1;
    if (failIf(!fs.existsSync(filePath), `Missing rule file: .claude/rules/${domain}/best-practices.md`, errors)) {
      return;
    }

    const { frontmatter } = validateFileFrontmatter(filePath, ['paths'], 'Rule', errors, checks);
    if (!frontmatter) {
      return;
    }

    checks.value += 1;
    const hasGlob = /^\s*-\s*["']?\*\*\/.+/m.test(frontmatter);
    failIf(!hasGlob, `Rule paths frontmatter has no glob entry: .claude/rules/${domain}/best-practices.md`, errors);
  });
}

function validateCommandReferences(root, commandFiles, agentNames, skillNames, errors, checks) {
  commandFiles.forEach(file => {
    const filePath = path.join(root, '.claude/commands', file);
    const content = readText(filePath);

    checks.value += 1;
    failIf(!content.includes('$ARGUMENTS'), `Command missing $ARGUMENTS usage: .claude/commands/${file}`, errors);

    const foundAgents = Array.from(content.matchAll(/\*\*([a-z0-9-]+)\*\*\s+agent/gi)).map(match => match[1]);
    const foundSkills = Array.from(content.matchAll(/\*\*([a-z0-9-]+)\*\*\s+skill/gi)).map(match => match[1]);

    foundAgents.forEach(name => {
      checks.value += 1;
      failIf(!agentNames.has(name), `Command references unknown agent "${name}": .claude/commands/${file}`, errors);
    });
    foundSkills.forEach(name => {
      checks.value += 1;
      failIf(!skillNames.has(name), `Command references unknown skill "${name}": .claude/commands/${file}`, errors);
    });
  });
}

function validateSensitiveCommands(root, errors, checks) {
  const sensitiveCommands = [
    'backup.md',
    'db-migrate.md',
    'deploy.md',
    'forge-deploy.md',
    'k8s-deploy.md',
    'ms365-provision.md',
    'server-provision.md',
    'ssl-setup.md',
  ];

  sensitiveCommands.forEach(file => {
    const filePath = path.join(root, '.claude/commands', file);
    checks.value += 1;
    if (failIf(!fs.existsSync(filePath), `Missing sensitive command file: .claude/commands/${file}`, errors)) {
      return;
    }

    const frontmatter = extractFrontmatter(readText(filePath));
    checks.value += 1;
    if (failIf(!frontmatter, `Command missing valid frontmatter: .claude/commands/${file}`, errors)) {
      return;
    }

    checks.value += 1;
    failIf(parseBoolean(frontmatter, 'disable-model-invocation') !== true, `Sensitive command must set disable-model-invocation: true -> .claude/commands/${file}`, errors);
  });
}

function validateDestructiveSkills(root, errors, checks) {
  const destructiveSkills = ['laravel-forge', 'ms365-admin'];
  destructiveSkills.forEach(skillName => {
    const skillPath = path.join(root, '.claude/skills', skillName, 'SKILL.md');
    checks.value += 1;
    if (failIf(!fs.existsSync(skillPath), `Missing destructive skill file: .claude/skills/${skillName}/SKILL.md`, errors)) {
      return;
    }

    const content = readText(skillPath);
    const frontmatter = extractFrontmatter(content);
    checks.value += 1;
    if (failIf(!frontmatter, `Skill missing frontmatter: .claude/skills/${skillName}/SKILL.md`, errors)) {
      return;
    }

    checks.value += 1;
    failIf(parseBoolean(frontmatter, 'disable-model-invocation') !== true, `Skill must set disable-model-invocation: true -> .claude/skills/${skillName}/SKILL.md`, errors);
    checks.value += 1;
    failIf(!/^context:\s*fork\s*$/m.test(frontmatter), `Skill must set context: fork -> .claude/skills/${skillName}/SKILL.md`, errors);
    checks.value += 1;
    failIf(!hasFrontmatterKey(frontmatter, 'argument-hint'), `Skill missing argument-hint -> .claude/skills/${skillName}/SKILL.md`, errors);
    checks.value += 1;
    failIf(!hasFrontmatterKey(frontmatter, 'hooks'), `Skill missing hooks block -> .claude/skills/${skillName}/SKILL.md`, errors);
  });
}

function validateMcpConfig(root, errors, checks) {
  const mcpPath = path.join(root, '.mcp.json');
  checks.value += 1;
  const mcp = readJSON(mcpPath);
  if (failIf(!mcp, 'Invalid .mcp.json', errors)) {
    return;
  }

  checks.value += 1;
  failIf(!mcp.mcpServers || typeof mcp.mcpServers !== 'object', '.mcp.json must contain "mcpServers" object', errors);
}

function validateRequiredRootFiles(root, errors, checks) {
  const requiredFiles = [
    'README.md',
    'CLAUDE.md',
    'AGENTS.md',
    'LICENSE',
    'CONTRIBUTING.md',
    'BEGINNERS-GUIDE.md',
    '.gitignore',
  ];

  requiredFiles.forEach(file => {
    checks.value += 1;
    failIf(!fs.existsSync(path.join(root, file)), `Missing required root file: ${file}`, errors);
  });
}

function validateJsonFiles(root, errors, checks) {
  const jsonFiles = [
    '.claude/settings.json',
    '.mcp.json',
    'package.json',
  ];

  jsonFiles.forEach(file => {
    checks.value += 1;
    const filePath = path.join(root, file);
    if (failIf(!fs.existsSync(filePath), `JSON file not found: ${file}`, errors)) {
      return;
    }
    if (!readJSON(filePath)) {
      errors.push(`Invalid JSON in ${file}`);
    }
  });
}

function main() {
  const root = getProjectRoot();
  const errors = [];
  const checks = { value: 0 };

  console.log('Validating project structure...\n');

  validateJsonFiles(root, errors, checks);

  const agentsDir = path.join(root, '.claude/agents');
  const commandsDir = path.join(root, '.claude/commands');
  const skillsDir = path.join(root, '.claude/skills');

  const agentFiles = listMarkdownFiles(agentsDir);
  const commandFiles = listMarkdownFiles(commandsDir);
  const skillDirs = fs.existsSync(skillsDir)
    ? fs.readdirSync(skillsDir).filter(name => fs.statSync(path.join(skillsDir, name)).isDirectory())
    : [];

  const agentNames = collectNameMap(agentFiles, agentsDir, ['name', 'description', 'tools', 'model'], 'Agent', errors, checks);
  const commandNames = collectNameMap(commandFiles, commandsDir, ['name', 'description', 'argument-hint'], 'Command', errors, checks);
  const skillNames = new Set();

  skillDirs.forEach(skillDir => {
    const skillPath = path.join(skillsDir, skillDir, 'SKILL.md');
    checks.value += 1;
    if (failIf(!fs.existsSync(skillPath), `Skill directory missing SKILL.md: .claude/skills/${skillDir}`, errors)) {
      return;
    }

    const { frontmatter } = validateFileFrontmatter(skillPath, ['name', 'description', 'user-invocable', 'allowed-tools'], 'Skill', errors, checks);
    if (!frontmatter) {
      return;
    }

    checks.value += 1;
    const skillName = parseTopLevelName(frontmatter);
    if (failIf(!skillName, `Skill missing top-level "name": .claude/skills/${skillDir}/SKILL.md`, errors)) {
      return;
    }
    failIf(skillNames.has(skillName), `Skill has duplicate name "${skillName}"`, errors);
    skillNames.add(skillName);
  });

  checks.value += 1;
  failIf(commandNames.size !== commandFiles.length, 'Some command files have invalid or duplicate frontmatter names', errors);

  validateCommandReferences(root, commandFiles, agentNames, skillNames, errors, checks);
  validateSensitiveCommands(root, errors, checks);
  validateRulesPaths(root, errors, checks);
  validateSettingsHooks(root, errors, checks);
  validateDestructiveSkills(root, errors, checks);
  validateMcpConfig(root, errors, checks);
  validateRequiredRootFiles(root, errors, checks);

  console.log(`Checks run: ${checks.value}`);
  if (errors.length === 0) {
    console.log(`\nAll ${checks.value} checks passed!\n`);
    process.exit(0);
  }

  console.log(`\n${errors.length} error(s) found:\n`);
  errors.forEach(error => console.log(`  - ${error}`));
  console.log('');
  process.exit(1);
}

main();
