/**
 * Integration tests for .claude/hooks/ shell scripts.
 * Tests hook scripts by piping JSON input via stdin and checking exit codes + stderr output.
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');

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
const HOOKS_DIR = path.join(ROOT, '.claude', 'hooks');

/**
 * Run a hook script with JSON input, return { exitCode, stdout, stderr }.
 * Captures stderr by redirecting it to a temp file (execSync doesn't expose stderr on success).
 */
function runHook(hookName, inputObj, env = {}) {
  const hookPath = path.join(HOOKS_DIR, hookName);
  const input = JSON.stringify(inputObj);
  const mergedEnv = { ...process.env, CLAUDE_PROJECT_DIR: ROOT, ...env };
  const stderrFile = path.join(os.tmpdir(), `hook-stderr-${Date.now()}-${Math.random().toString(36).slice(2)}`);

  try {
    const result = execSync(
      `echo '${input.replace(/'/g, "'\\''")}' | bash "${hookPath}" 2>"${stderrFile}"`,
      {
        cwd: ROOT,
        env: mergedEnv,
        stdio: ['pipe', 'pipe', 'pipe'],
        timeout: 10000,
      }
    );
    const stderr = fs.existsSync(stderrFile) ? fs.readFileSync(stderrFile, 'utf8') : '';
    try { fs.unlinkSync(stderrFile); } catch {}
    return { exitCode: 0, stdout: result.toString(), stderr };
  } catch (e) {
    const stderr = fs.existsSync(stderrFile) ? fs.readFileSync(stderrFile, 'utf8') : (e.stderr ? e.stderr.toString() : '');
    try { fs.unlinkSync(stderrFile); } catch {}
    return {
      exitCode: e.status || 1,
      stdout: e.stdout ? e.stdout.toString() : '',
      stderr,
    };
  }
}

function run() {
  console.log('  hook script tests');

  // Check jq is available (hooks degrade gracefully without it)
  let hasJq = false;
  try {
    execSync('which jq', { stdio: 'ignore' });
    hasJq = true;
  } catch {
    console.log('    SKIP: jq not installed — hook tests require jq');
    return { passed, failed };
  }

  // ==========================================
  // git-safety-check.sh
  // ==========================================

  // Should BLOCK force-push to main
  (() => {
    const result = runHook('git-safety-check.sh', {
      tool_input: { command: 'git push --force origin main' },
    });
    assert(result.exitCode === 2, 'git-safety: should block force-push to main (exit 2)');
    assert(result.stderr.includes('BLOCKED'), 'git-safety: stderr should say BLOCKED');
  })();

  // Should BLOCK force-push to production
  (() => {
    const result = runHook('git-safety-check.sh', {
      tool_input: { command: 'git push --force origin production' },
    });
    assert(result.exitCode === 2, 'git-safety: should block force-push to production');
  })();

  // Should BLOCK force-push to develop
  (() => {
    const result = runHook('git-safety-check.sh', {
      tool_input: { command: 'git push -f origin develop' },
    });
    assert(result.exitCode === 2, 'git-safety: should block -f push to develop');
  })();

  // Should ALLOW force-push to feature branch (with warning)
  (() => {
    const result = runHook('git-safety-check.sh', {
      tool_input: { command: 'git push --force origin feat/my-feature' },
    });
    assert(result.exitCode === 0, 'git-safety: should allow force-push to feature branch');
    assert(result.stderr.includes('Force push detected'), 'git-safety: should warn on force-push');
  })();

  // Should ALLOW normal push
  (() => {
    const result = runHook('git-safety-check.sh', {
      tool_input: { command: 'git push origin feat/my-feature' },
    });
    assert(result.exitCode === 0, 'git-safety: should allow normal push');
  })();

  // Should WARN on branch deletion
  (() => {
    const result = runHook('git-safety-check.sh', {
      tool_input: { command: 'git branch -D old-branch' },
    });
    assert(result.exitCode === 0, 'git-safety: should allow branch deletion');
    assert(result.stderr.includes('deletion'), 'git-safety: should warn on branch deletion');
  })();

  // Should ALLOW empty command gracefully
  (() => {
    const result = runHook('git-safety-check.sh', {
      tool_input: { command: '' },
    });
    assert(result.exitCode === 0, 'git-safety: empty command should pass');
  })();

  // Should ALLOW non-git commands
  (() => {
    const result = runHook('git-safety-check.sh', {
      tool_input: { command: 'ls -la' },
    });
    assert(result.exitCode === 0, 'git-safety: non-git command should pass');
  })();

  // ==========================================
  // infra-safety-check.sh
  // ==========================================

  // Should WARN on terraform apply
  (() => {
    const result = runHook('infra-safety-check.sh', {
      tool_input: { command: 'terraform apply' },
    });
    assert(result.exitCode === 0, 'infra-safety: terraform apply should be allowed');
    assert(result.stderr.includes('Destructive infrastructure'), 'infra-safety: should warn on terraform apply');
  })();

  // Should WARN on terraform destroy
  (() => {
    const result = runHook('infra-safety-check.sh', {
      tool_input: { command: 'terraform destroy' },
    });
    assert(result.exitCode === 0, 'infra-safety: terraform destroy should be allowed (with warning)');
    assert(result.stderr.includes('Destructive'), 'infra-safety: should warn on terraform destroy');
  })();

  // Should WARN on terraform apply -auto-approve
  (() => {
    const result = runHook('infra-safety-check.sh', {
      tool_input: { command: 'terraform apply -auto-approve' },
    });
    assert(result.exitCode === 0, 'infra-safety: auto-approve should be allowed');
    assert(result.stderr.includes('auto-approve'), 'infra-safety: should warn on auto-approve');
  })();

  // Should WARN on kubectl delete
  (() => {
    const result = runHook('infra-safety-check.sh', {
      tool_input: { command: 'kubectl delete pod my-pod' },
    });
    assert(result.exitCode === 0, 'infra-safety: kubectl delete should be allowed');
    assert(result.stderr.includes('Destructive'), 'infra-safety: should warn on kubectl delete');
  })();

  // Should WARN on rm -rf
  (() => {
    const result = runHook('infra-safety-check.sh', {
      tool_input: { command: 'rm -rf /var/data' },
    });
    assert(result.exitCode === 0, 'infra-safety: rm -rf should be allowed (with warning)');
    assert(result.stderr.includes('destructive'), 'infra-safety: should warn on rm -rf');
  })();

  // Should ALLOW safe commands
  (() => {
    const result = runHook('infra-safety-check.sh', {
      tool_input: { command: 'terraform plan' },
    });
    assert(result.exitCode === 0, 'infra-safety: terraform plan should pass');
    assert(!result.stderr.includes('Destructive'), 'infra-safety: terraform plan should not warn');
  })();

  // ==========================================
  // file-write-check.sh
  // ==========================================

  // Should WARN on secrets in files
  (() => {
    const tmpFile = path.join(ROOT, '.claude', 'logs', 'test-secret-file.tmp');
    fs.mkdirSync(path.dirname(tmpFile), { recursive: true });
    fs.writeFileSync(tmpFile, 'password = SuperSecret123!\nother_data = hello');
    const result = runHook('file-write-check.sh', {
      tool_input: { file_path: tmpFile },
    });
    assert(result.exitCode === 0, 'file-write: should allow (warnings only)');
    assert(result.stderr.includes('secret') || result.stderr.includes('Secret'), 'file-write: should warn on secrets');
    fs.unlinkSync(tmpFile);
  })();

  // Should be silent for clean files
  (() => {
    const tmpFile = path.join(ROOT, '.claude', 'logs', 'test-clean-file.tmp');
    fs.writeFileSync(tmpFile, 'const x = 42;\nconsole.log(x);');
    const result = runHook('file-write-check.sh', {
      tool_input: { file_path: tmpFile },
    });
    assert(result.exitCode === 0, 'file-write: clean file should pass');
    assert(!result.stderr.includes('secret'), 'file-write: clean file should not warn about secrets');
    fs.unlinkSync(tmpFile);
  })();

  // Should handle missing file gracefully
  (() => {
    const result = runHook('file-write-check.sh', {
      tool_input: { file_path: '/nonexistent/path/file.txt' },
    });
    assert(result.exitCode === 0, 'file-write: missing file should exit 0');
  })();

  // ==========================================
  // migration-check.sh
  // ==========================================

  // Should WARN on Laravel migration missing branch_id
  (() => {
    const tmpFile = path.join(ROOT, '.claude', 'logs', 'database', 'migrations', '2026_01_01_test.php');
    fs.mkdirSync(path.dirname(tmpFile), { recursive: true });
    fs.writeFileSync(tmpFile, `<?php
Schema::create('orders', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->timestamps();
});
function up() {}
`);
    const result = runHook('migration-check.sh', {
      tool_input: { file_path: tmpFile },
    });
    assert(result.exitCode === 0, 'migration: should allow (warnings only)');
    assert(result.stderr.includes('branch_id'), 'migration: should warn about missing branch_id');
    // Cleanup
    fs.rmSync(path.join(ROOT, '.claude', 'logs', 'database'), { recursive: true });
  })();

  // Should WARN on migration missing down() method
  (() => {
    const tmpFile = path.join(ROOT, '.claude', 'logs', 'database', 'migrations', '2026_01_02_test.php');
    fs.mkdirSync(path.dirname(tmpFile), { recursive: true });
    fs.writeFileSync(tmpFile, `<?php
function up() {
    Schema::create('orders', function (Blueprint $table) {
        $table->id();
        $table->foreignId('branch_id')->constrained();
    });
}
`);
    const result = runHook('migration-check.sh', {
      tool_input: { file_path: tmpFile },
    });
    assert(result.exitCode === 0, 'migration: should allow');
    assert(result.stderr.includes('down()'), 'migration: should warn about missing down()');
    fs.rmSync(path.join(ROOT, '.claude', 'logs', 'database'), { recursive: true });
  })();

  // Should NOT warn for non-migration files
  (() => {
    const tmpFile = path.join(ROOT, '.claude', 'logs', 'test-not-migration.js');
    fs.writeFileSync(tmpFile, 'const x = 42;');
    const result = runHook('migration-check.sh', {
      tool_input: { file_path: tmpFile },
    });
    assert(result.exitCode === 0, 'migration: non-migration should pass');
    assert(!result.stderr.includes('branch_id'), 'migration: non-migration should not warn');
    fs.unlinkSync(tmpFile);
  })();

  // ==========================================
  // ms365-audit-log.sh
  // ==========================================

  // Should log MS365 operations and exit 0
  (() => {
    const result = runHook('ms365-audit-log.sh', {
      tool_name: 'mcp__ms365__list-users',
      session_id: 'test-session-123',
      tool_input: { top: 10 },
    });
    assert(result.exitCode === 0, 'ms365-audit: should always exit 0');
    // Check log file was created
    const logFile = path.join(ROOT, '.claude', 'logs', 'ms365-audit.log');
    if (fs.existsSync(logFile)) {
      const logContent = fs.readFileSync(logFile, 'utf8');
      assert(logContent.includes('mcp__ms365__list-users'), 'ms365-audit: should log tool name');
      assert(logContent.includes('test-session-123'), 'ms365-audit: should log session id');
    }
  })();

  // Should warn on send operations
  (() => {
    const result = runHook('ms365-audit-log.sh', {
      tool_name: 'mcp__ms365__send-shared-mailbox-mail',
      session_id: 'test-session-456',
      tool_input: {},
    });
    assert(result.exitCode === 0, 'ms365-audit: send should exit 0');
    assert(result.stderr.includes('logged for audit'), 'ms365-audit: should note audit logging for sends');
  })();

  // ==========================================
  // tool-failure.sh
  // ==========================================

  // Should log failures and provide hints
  (() => {
    const result = runHook('tool-failure.sh', {
      tool_name: 'Bash',
      tool_response: { stderr: 'permission denied: /etc/shadow' },
    });
    assert(result.exitCode === 0, 'tool-failure: should always exit 0');
    assert(result.stderr.includes('Permission denied') || result.stderr.includes('permission'), 'tool-failure: should hint on permission errors');
  })();

  (() => {
    const result = runHook('tool-failure.sh', {
      tool_name: 'Bash',
      tool_response: { stderr: 'command not found: terraform' },
    });
    assert(result.exitCode === 0, 'tool-failure: should always exit 0');
    assert(result.stderr.includes('not found') || result.stderr.includes('not installed'), 'tool-failure: should hint on missing command');
  })();

  (() => {
    const result = runHook('tool-failure.sh', {
      tool_name: 'mcp__ms365__list-users',
      tool_response: { stderr: 'HTTP 401 Unauthorized' },
    });
    assert(result.exitCode === 0, 'tool-failure: ms365 auth should exit 0');
    assert(result.stderr.includes('login') || result.stderr.includes('auth'), 'tool-failure: should hint on ms365 auth error');
  })();

  // ==========================================
  // subagent-lifecycle.sh
  // ==========================================

  // Should log subagent start
  (() => {
    const result = runHook('subagent-lifecycle.sh', {
      agent_name: 'backend-engineer',
      session_id: 'test-session-789',
    }, { HOOK_EVENT: 'SubagentStart' });
    assert(result.exitCode === 0, 'subagent: should exit 0');
    assert(result.stderr.includes('started') || result.stderr.includes('Subagent'), 'subagent: should note start');
  })();

  // Should log subagent stop
  (() => {
    const result = runHook('subagent-lifecycle.sh', {
      agent_name: 'qa-agent',
      session_id: 'test-session-789',
    }, { HOOK_EVENT: 'SubagentStop' });
    assert(result.exitCode === 0, 'subagent: stop should exit 0');
    assert(result.stderr.includes('completed') || result.stderr.includes('Subagent'), 'subagent: should note stop');
  })();

  // ==========================================
  // stop-validation.sh
  // ==========================================

  // Should exit 0 with no staged sensitive files
  (() => {
    const result = runHook('stop-validation.sh', {
      session_id: 'test-stop-session',
    });
    assert(result.exitCode === 0, 'stop-validation: should exit 0');
  })();

  // ==========================================
  // All hooks should be executable
  // ==========================================
  const hookFiles = fs.readdirSync(HOOKS_DIR).filter(f => f.endsWith('.sh'));
  hookFiles.forEach(file => {
    const hookPath = path.join(HOOKS_DIR, file);
    try {
      fs.accessSync(hookPath, fs.constants.X_OK);
      passed++;
    } catch {
      console.log(`    FAIL: ${file} is not executable`);
      failed++;
    }
  });

  // All hooks should start with shebang
  hookFiles.forEach(file => {
    const content = fs.readFileSync(path.join(HOOKS_DIR, file), 'utf8');
    assert(content.startsWith('#!/bin/bash'), `${file}: should start with #!/bin/bash`);
  });

  return { passed, failed };
}

module.exports = { run };
