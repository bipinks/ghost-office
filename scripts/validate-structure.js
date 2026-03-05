/**
 * Comprehensive project validator.
 * Ensures structure, frontmatter, cross-references, and safety guardrails.
 *
 * Usage: node scripts/validate-structure.js
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { getProjectRoot, readJSON, commandExists } = require('./lib/utils');

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

function validateHooksSchema(root, errors, checks) {
  const hooksPath = path.join(root, 'hooks/hooks.json');
  checks.value += 1;
  const hooksJson = readJSON(hooksPath);
  if (!hooksJson) {
    errors.push('Invalid hooks/hooks.json');
    return;
  }

  const hooksObj = hooksJson.hooks;
  failIf(!hooksObj || typeof hooksObj !== 'object' || Array.isArray(hooksObj), 'hooks/hooks.json must contain an object in "hooks"', errors);

  ['PreToolUse', 'PostToolUse'].forEach(eventName => {
    checks.value += 1;
    const eventHooks = hooksObj && hooksObj[eventName];
    if (failIf(!Array.isArray(eventHooks), `hooks/hooks.json: "${eventName}" must be an array`, errors)) {
      return;
    }

    eventHooks.forEach((entry, index) => {
      checks.value += 1;
      failIf(!entry.matcher || typeof entry.matcher !== 'string', `hooks/hooks.json: ${eventName}[${index}] missing string matcher`, errors);
      if (failIf(!Array.isArray(entry.hooks), `hooks/hooks.json: ${eventName}[${index}].hooks must be an array`, errors)) {
        return;
      }
      entry.hooks.forEach((hook, hookIndex) => {
        checks.value += 1;
        failIf(!hook.type || typeof hook.type !== 'string', `hooks/hooks.json: ${eventName}[${index}].hooks[${hookIndex}] missing type`, errors);
        failIf(!hook.command || typeof hook.command !== 'string', `hooks/hooks.json: ${eventName}[${index}].hooks[${hookIndex}] missing command`, errors);
      });
    });
  });
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

function validateRulesPaths(root, errors, checks) {
  const requiredRuleDomains = ['terraform', 'kubernetes', 'docker', 'cicd', 'cloud', 'security'];
  requiredRuleDomains.forEach(domain => {
    const filePath = path.join(root, 'rules', domain, 'best-practices.md');
    checks.value += 1;
    if (failIf(!fs.existsSync(filePath), `Missing rule file: rules/${domain}/best-practices.md`, errors)) {
      return;
    }

    const { frontmatter } = validateFileFrontmatter(filePath, ['paths'], 'Rule', errors, checks);
    if (!frontmatter) {
      return;
    }

    checks.value += 1;
    const hasGlob = /^\s*-\s*["']?\*\*\/.+/m.test(frontmatter);
    failIf(!hasGlob, `Rule paths frontmatter has no glob entry: rules/${domain}/best-practices.md`, errors);
  });
}

function validateCommandReferences(root, commandFiles, agentNames, skillNames, errors, checks) {
  commandFiles.forEach(file => {
    const filePath = path.join(root, 'commands', file);
    const content = readText(filePath);

    checks.value += 1;
    failIf(!content.includes('$ARGUMENTS'), `Command missing $ARGUMENTS usage: commands/${file}`, errors);

    const foundAgents = Array.from(content.matchAll(/\*\*([a-z0-9-]+)\*\*\s+agent/gi)).map(match => match[1]);
    const foundSkills = Array.from(content.matchAll(/\*\*([a-z0-9-]+)\*\*\s+skill/gi)).map(match => match[1]);

    foundAgents.forEach(name => {
      checks.value += 1;
      failIf(!agentNames.has(name), `Command references unknown agent "${name}": commands/${file}`, errors);
    });
    foundSkills.forEach(name => {
      checks.value += 1;
      failIf(!skillNames.has(name), `Command references unknown skill "${name}": commands/${file}`, errors);
    });
  });
}

function validateDestructiveSkills(root, errors, checks) {
  const destructiveSkills = ['laravel-forge', 'ms365-admin'];
  destructiveSkills.forEach(skillName => {
    const skillPath = path.join(root, 'skills', skillName, 'SKILL.md');
    checks.value += 1;
    if (failIf(!fs.existsSync(skillPath), `Missing destructive skill file: skills/${skillName}/SKILL.md`, errors)) {
      return;
    }

    const content = readText(skillPath);
    const frontmatter = extractFrontmatter(content);
    checks.value += 1;
    if (failIf(!frontmatter, `Skill missing frontmatter: skills/${skillName}/SKILL.md`, errors)) {
      return;
    }

    checks.value += 1;
    failIf(parseBoolean(frontmatter, 'disable-model-invocation') !== true, `Skill must set disable-model-invocation: true -> skills/${skillName}/SKILL.md`, errors);
    checks.value += 1;
    failIf(!/^context:\s*fork\s*$/m.test(frontmatter), `Skill must set context: fork -> skills/${skillName}/SKILL.md`, errors);
    checks.value += 1;
    failIf(!hasFrontmatterKey(frontmatter, 'argument-hint'), `Skill missing argument-hint -> skills/${skillName}/SKILL.md`, errors);
    checks.value += 1;
    failIf(!hasFrontmatterKey(frontmatter, 'hooks'), `Skill missing hooks block -> skills/${skillName}/SKILL.md`, errors);
  });
}

function validatePluginManifest(root, plugin, errors, checks) {
  checks.value += 1;
  failIf(!plugin.name || typeof plugin.name !== 'string', 'plugin.json must include string "name"', errors);

  checks.value += 1;
  if (plugin.author !== undefined) {
    failIf(!plugin.author || typeof plugin.author !== 'object' || Array.isArray(plugin.author), 'plugin.json "author" must be an object', errors);
  }

  ['hooks', 'mcpServers', 'commands', 'skills', 'agents'].forEach(key => {
    checks.value += 1;
    if (plugin[key] === undefined) {
      return;
    }

    const value = plugin[key];
    const paths = Array.isArray(value) ? value : [value];

    paths.forEach((entry, index) => {
      checks.value += 1;
      if (failIf(typeof entry !== 'string', `plugin.json "${key}" entry ${index} must be a string path`, errors)) {
        return;
      }

      checks.value += 1;
      failIf(!entry.startsWith('./'), `plugin.json "${key}" path must start with "./": ${entry}`, errors);

      checks.value += 1;
      failIf(!fs.existsSync(path.join(root, entry)), `plugin.json "${key}" path does not exist: ${entry}`, errors);
    });
  });
}

function validateMarketplaceManifest(root, marketplace, errors, checks) {
  checks.value += 1;
  failIf(!marketplace.name || typeof marketplace.name !== 'string', 'marketplace.json must include string "name"', errors);

  checks.value += 1;
  failIf(!marketplace.owner || typeof marketplace.owner !== 'object' || Array.isArray(marketplace.owner), 'marketplace.json must include object "owner"', errors);

  checks.value += 1;
  if (failIf(!Array.isArray(marketplace.plugins), 'marketplace.json must include array "plugins"', errors)) {
    return;
  }

  marketplace.plugins.forEach((plugin, index) => {
    checks.value += 1;
    failIf(!plugin.name || typeof plugin.name !== 'string', `marketplace.json plugins[${index}] missing string "name"`, errors);

    checks.value += 1;
    if (failIf(!plugin.source || typeof plugin.source !== 'string', `marketplace.json plugins[${index}] missing string "source"`, errors)) {
      return;
    }

    checks.value += 1;
    failIf(!plugin.source.startsWith('./'), `marketplace.json plugins[${index}] source must start with "./": ${plugin.source}`, errors);

    checks.value += 1;
    failIf(!fs.existsSync(path.join(root, plugin.source)), `marketplace.json plugins[${index}] source does not exist: ${plugin.source}`, errors);
  });
}

function validateWithClaudeCli(root, errors, checks) {
  checks.value += 1;
  if (!commandExists('claude')) {
    console.log('ℹ️  Skipping official plugin validation (`claude` CLI not found).');
    return;
  }

  const manifests = ['.claude-plugin/plugin.json', '.claude-plugin/marketplace.json'];
  manifests.forEach(manifest => {
    checks.value += 1;
    try {
      execSync(`claude plugin validate ${manifest}`, {
        cwd: root,
        stdio: 'pipe',
      });
    } catch (error) {
      const stderr = (error.stderr || '').toString().trim();
      const stdout = (error.stdout || '').toString().trim();
      const details = stderr || stdout || error.message;
      errors.push(`Official validation failed for ${manifest}: ${details}`);
    }
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
    const filePath = path.join(root, 'commands', file);
    checks.value += 1;
    if (failIf(!fs.existsSync(filePath), `Missing sensitive command file: commands/${file}`, errors)) {
      return;
    }

    const frontmatter = extractFrontmatter(readText(filePath));
    checks.value += 1;
    if (failIf(!frontmatter, `Command missing valid frontmatter: commands/${file}`, errors)) {
      return;
    }

    checks.value += 1;
    failIf(parseBoolean(frontmatter, 'disable-model-invocation') !== true, `Sensitive command must set disable-model-invocation: true -> commands/${file}`, errors);
  });
}

function validateCodexCompatibility(root, errors, checks) {
  const codexConfigPath = path.join(root, '.codex', 'config.toml');
  checks.value += 1;
  if (failIf(!fs.existsSync(codexConfigPath), 'Missing Codex project config: .codex/config.toml', errors)) {
    return;
  }

  const configText = readText(codexConfigPath);
  ['approval_policy', 'sandbox_mode', 'project_doc_fallback_filenames', '[profiles.devops_strict]'].forEach(requiredKey => {
    checks.value += 1;
    failIf(!configText.includes(requiredKey), `Codex config missing "${requiredKey}": .codex/config.toml`, errors);
  });

  const codexSkillsPath = path.join(root, '.agents', 'skills');
  checks.value += 1;
  if (failIf(!fs.existsSync(codexSkillsPath), 'Missing Codex skills bridge: .agents/skills', errors)) {
    return;
  }

  checks.value += 1;
  const isSymlink = fs.lstatSync(codexSkillsPath).isSymbolicLink();
  if (!isSymlink) {
    const skills = fs.readdirSync(codexSkillsPath).filter(entry => fs.statSync(path.join(codexSkillsPath, entry)).isDirectory());
    checks.value += 1;
    failIf(skills.length === 0, '.agents/skills must contain at least one skill directory', errors);
  }
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
    '.claude-plugin/plugin.json',
    '.claude-plugin/marketplace.json',
    'hooks/hooks.json',
    'mcp-configs/mcp-servers.json',
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

  console.log('🔍 Validating project structure and quality...\n');

  validateJsonFiles(root, errors, checks);

  const pluginPath = path.join(root, '.claude-plugin', 'plugin.json');
  const plugin = readJSON(pluginPath);
  checks.value += 1;
  if (!plugin) {
    errors.push('Invalid or missing .claude-plugin/plugin.json');
  } else {
    validatePluginManifest(root, plugin, errors, checks);
  }

  const marketplacePath = path.join(root, '.claude-plugin', 'marketplace.json');
  const marketplace = readJSON(marketplacePath);
  checks.value += 1;
  if (!marketplace) {
    errors.push('Invalid or missing .claude-plugin/marketplace.json');
  } else {
    validateMarketplaceManifest(root, marketplace, errors, checks);
  }

  const agentsDir = path.join(root, 'agents');
  const commandsDir = path.join(root, 'commands');
  const skillsDir = path.join(root, 'skills');

  const agentFiles = listMarkdownFiles(agentsDir);
  const commandFiles = listMarkdownFiles(commandsDir);
  const skillDirs = fs.readdirSync(skillsDir).filter(name => fs.statSync(path.join(skillsDir, name)).isDirectory());

  const agentNames = collectNameMap(agentFiles, agentsDir, ['name', 'description', 'tools', 'model'], 'Agent', errors, checks);
  const commandNames = collectNameMap(commandFiles, commandsDir, ['name', 'description', 'argument-hint'], 'Command', errors, checks);
  const skillNames = new Set();

  skillDirs.forEach(skillDir => {
    const skillPath = path.join(skillsDir, skillDir, 'SKILL.md');
    checks.value += 1;
    if (failIf(!fs.existsSync(skillPath), `Skill directory missing SKILL.md: skills/${skillDir}`, errors)) {
      return;
    }

    const { frontmatter } = validateFileFrontmatter(skillPath, ['name', 'description', 'user-invocable', 'allowed-tools'], 'Skill', errors, checks);
    if (!frontmatter) {
      return;
    }

    checks.value += 1;
    const skillName = parseTopLevelName(frontmatter);
    if (failIf(!skillName, `Skill missing top-level "name": skills/${skillDir}/SKILL.md`, errors)) {
      return;
    }
    failIf(skillNames.has(skillName), `Skill has duplicate name "${skillName}"`, errors);
    skillNames.add(skillName);
  });

  checks.value += 1;
  failIf(commandNames.size !== commandFiles.length, 'Some command files have invalid or duplicate frontmatter names', errors);

  validateCommandReferences(root, commandFiles, agentNames, skillNames, errors, checks);
  validateSensitiveCommands(root, errors, checks);
  validateCodexCompatibility(root, errors, checks);
  validateRulesPaths(root, errors, checks);
  validateHooksSchema(root, errors, checks);
  validateDestructiveSkills(root, errors, checks);
  validateRequiredRootFiles(root, errors, checks);
  validateWithClaudeCli(root, errors, checks);

  console.log(`Checks run: ${checks.value}`);
  if (errors.length === 0) {
    console.log(`\n✅ All ${checks.value} checks passed!\n`);
    process.exit(0);
  }

  console.log(`\n❌ ${errors.length} error(s) found:\n`);
  errors.forEach(error => console.log(`  • ${error}`));
  console.log('');
  process.exit(1);
}

main();
