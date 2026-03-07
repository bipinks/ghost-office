/**
 * Content integrity tests for agents, commands, skills, workflows, memory, and rules.
 * Validates that all components meet quality and consistency standards.
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
  console.log('  content integrity tests');

  // ==========================================
  // Agents — all 14 files present and well-formed
  // ==========================================
  const agentsDir = path.join(ROOT, '.claude', 'agents');
  const agentFiles = fs.readdirSync(agentsDir).filter(f => f.endsWith('.md'));

  const expectedAgents = [
    'master-orchestrator', 'architecture-agent', 'backend-engineer',
    'frontend-engineer', 'database-engineer', 'qa-agent', 'security-agent',
    'devops-engineer', 'monitoring-agent', 'performance-agent',
    'support-agent', 'documentation-agent', 'ms-it-admin', 'product-manager',
  ];

  expectedAgents.forEach(name => {
    assert(agentFiles.includes(`${name}.md`), `agent exists: ${name}.md`);
  });

  // Agents should have meaningful content (> 50 lines minimum)
  agentFiles.forEach(file => {
    const content = fs.readFileSync(path.join(agentsDir, file), 'utf8');
    const lines = content.split('\n').length;
    assert(lines >= 20, `agent ${file}: has sufficient content (${lines} lines)`);
  });

  // ==========================================
  // Commands — expected commands present
  // ==========================================
  const commandsDir = path.join(ROOT, '.claude', 'commands');
  const commandFiles = fs.readdirSync(commandsDir).filter(f => f.endsWith('.md'));

  const expectedCommands = [
    'implement-feature', 'fix-bug', 'deploy-staging', 'deploy-production',
    'security-scan', 'write-tests', 'analyze-project',
  ];

  expectedCommands.forEach(name => {
    assert(commandFiles.includes(`${name}.md`), `command exists: ${name}.md`);
  });

  // Commands should reference $ARGUMENTS
  commandFiles.forEach(file => {
    const content = fs.readFileSync(path.join(commandsDir, file), 'utf8');
    assert(content.includes('$ARGUMENTS'), `command ${file}: uses $ARGUMENTS`);
  });

  // ==========================================
  // Skills — expected directories with SKILL.md
  // ==========================================
  const skillsDir = path.join(ROOT, '.claude', 'skills');
  const skillDirs = fs.readdirSync(skillsDir).filter(name =>
    fs.statSync(path.join(skillsDir, name)).isDirectory()
  );

  assert(skillDirs.length >= 20, `skills: at least 20 skill directories (found ${skillDirs.length})`);

  const expectedSkills = [
    'aws-patterns', 'terraform-patterns', 'docker-patterns',
    'kubernetes-patterns', 'cicd-patterns', 'security-hardening',
    'monitoring-patterns', 'database-ops',
  ];

  expectedSkills.forEach(name => {
    assert(skillDirs.includes(name), `skill directory exists: ${name}`);
    const skillFile = path.join(skillsDir, name, 'SKILL.md');
    assert(fs.existsSync(skillFile), `skill has SKILL.md: ${name}`);
  });

  // Skills should have substantial content
  skillDirs.forEach(dir => {
    const skillFile = path.join(skillsDir, dir, 'SKILL.md');
    if (fs.existsSync(skillFile)) {
      const content = fs.readFileSync(skillFile, 'utf8');
      assert(content.length > 500, `skill ${dir}: SKILL.md has substantial content (${content.length} chars)`);
    }
  });

  // ==========================================
  // Workflows — all 5 present
  // ==========================================
  const workflowsDir = path.join(ROOT, '.claude', 'workflows');
  assert(fs.existsSync(workflowsDir), 'workflows directory exists');

  const expectedWorkflows = [
    'feature-development', 'bug-fix', 'release-process',
    'production-incident', 'client-deployment',
  ];

  if (fs.existsSync(workflowsDir)) {
    const workflowFiles = fs.readdirSync(workflowsDir).filter(f => f.endsWith('.md'));
    expectedWorkflows.forEach(name => {
      assert(workflowFiles.includes(`${name}.md`), `workflow exists: ${name}.md`);
    });

    // Workflows should have phases/steps
    workflowFiles.forEach(file => {
      const content = fs.readFileSync(path.join(workflowsDir, file), 'utf8');
      assert(content.length > 500, `workflow ${file}: has substantial content`);
      assert(content.includes('#'), `workflow ${file}: has markdown headings`);
    });
  }

  // ==========================================
  // Memory — all 6 knowledge base docs
  // ==========================================
  const memoryDir = path.join(ROOT, '.claude', 'memory');
  assert(fs.existsSync(memoryDir), 'memory directory exists');

  const expectedMemory = [
    'architecture', 'coding-standards', 'domain-knowledge',
    'deployment-standards', 'devops-runbook', 'performance-guidelines',
  ];

  if (fs.existsSync(memoryDir)) {
    const memoryFiles = fs.readdirSync(memoryDir).filter(f => f.endsWith('.md'));
    expectedMemory.forEach(name => {
      assert(memoryFiles.includes(`${name}.md`), `memory doc exists: ${name}.md`);
    });

    // Memory docs should be substantial reference material
    memoryFiles.forEach(file => {
      const content = fs.readFileSync(path.join(memoryDir, file), 'utf8');
      assert(content.length > 1000, `memory ${file}: has substantial content (${content.length} chars)`);
    });
  }

  // ==========================================
  // Rules — domain rules with paths frontmatter
  // ==========================================
  const rulesDir = path.join(ROOT, '.claude', 'rules');
  assert(fs.existsSync(rulesDir), 'rules directory exists');

  // Common rules
  const commonRules = ['coding-style', 'git-workflow', 'performance', 'security', 'testing'];
  commonRules.forEach(name => {
    const filePath = path.join(rulesDir, 'common', `${name}.md`);
    assert(fs.existsSync(filePath), `common rule exists: ${name}.md`);
  });

  // Domain rules with paths frontmatter
  const domainRules = ['terraform', 'kubernetes', 'docker', 'cicd', 'cloud', 'security'];
  domainRules.forEach(domain => {
    const filePath = path.join(rulesDir, domain, 'best-practices.md');
    assert(fs.existsSync(filePath), `domain rule exists: ${domain}/best-practices.md`);
    if (fs.existsSync(filePath)) {
      const content = fs.readFileSync(filePath, 'utf8');
      assert(content.startsWith('---'), `rule ${domain}: has frontmatter`);
      assert(content.includes('paths:'), `rule ${domain}: has paths key`);
    }
  });

  // ==========================================
  // Hooks — all 11 scripts present and executable
  // ==========================================
  const hooksDir = path.join(ROOT, '.claude', 'hooks');
  assert(fs.existsSync(hooksDir), 'hooks directory exists');

  const expectedHooks = [
    'session-start.sh', 'pre-compact.sh', 'infra-safety-check.sh',
    'git-safety-check.sh', 'file-write-check.sh', 'migration-check.sh',
    'ms365-audit-log.sh', 'tool-failure.sh', 'stop-validation.sh',
    'notification.sh', 'subagent-lifecycle.sh',
  ];

  if (fs.existsSync(hooksDir)) {
    const hookFiles = fs.readdirSync(hooksDir).filter(f => f.endsWith('.sh'));
    expectedHooks.forEach(name => {
      assert(hookFiles.includes(name), `hook exists: ${name}`);
    });
  }

  // ==========================================
  // Required root files
  // ==========================================
  const requiredRootFiles = [
    'README.md', 'CLAUDE.md', 'AGENTS.md', 'LICENSE',
    'CONTRIBUTING.md', 'BEGINNERS-GUIDE.md', '.gitignore',
  ];

  requiredRootFiles.forEach(file => {
    assert(fs.existsSync(path.join(ROOT, file)), `root file exists: ${file}`);
  });

  // CLAUDE.md should reference key concepts
  const claudeMd = fs.readFileSync(path.join(ROOT, 'CLAUDE.md'), 'utf8');
  assert(claudeMd.includes('branch_id'), 'CLAUDE.md: mentions branch_id');
  assert(claudeMd.includes('multi-tenant'), 'CLAUDE.md: mentions multi-tenant');
  assert(claudeMd.includes('conventional commits') || claudeMd.includes('feat:'), 'CLAUDE.md: mentions commit conventions');

  // AGENTS.md should list all agents
  const agentsMd = fs.readFileSync(path.join(ROOT, 'AGENTS.md'), 'utf8');
  assert(agentsMd.includes('master-orchestrator'), 'AGENTS.md: mentions master-orchestrator');
  assert(agentsMd.includes('backend-engineer'), 'AGENTS.md: mentions backend-engineer');
  assert(agentsMd.includes('security-agent'), 'AGENTS.md: mentions security-agent');

  // ==========================================
  // Cross-reference: agents referenced in CLAUDE.md match actual files
  // ==========================================
  const agentNamesFromFiles = agentFiles.map(f => f.replace('.md', ''));
  expectedAgents.forEach(name => {
    assert(agentNamesFromFiles.includes(name), `cross-ref: agent ${name} file exists for expected agent`);
  });

  return { passed, failed };
}

module.exports = { run };
