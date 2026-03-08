/**
 * Setup script — interactive setup for new installations.
 *
 * Usage: node scripts/setup.js
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { getProjectRoot } = require('./lib/utils');

function main() {
  const root = getProjectRoot();
  const rulesDir = path.join(process.env.HOME || '~', '.claude', 'rules');

  console.log('🚀 Ghost Office — Setup\n');

  // Step 1: Install rules
  console.log('📋 Installing rules...');
  const ruleDirs = ['common', 'terraform', 'kubernetes', 'docker', 'cicd', 'cloud', 'security'];

  ruleDirs.forEach(domain => {
    const src = path.join(root, 'rules', domain);
    const dest = path.join(rulesDir, domain);

    if (fs.existsSync(src)) {
      if (!fs.existsSync(dest)) {
        fs.mkdirSync(dest, { recursive: true });
      }
      const files = fs.readdirSync(src).filter(f => f.endsWith('.md'));
      files.forEach(f => {
        fs.copyFileSync(path.join(src, f), path.join(dest, f));
      });
      console.log(`  ✅ Installed ${domain} rules`);
    }
  });

  // Step 2: Validate JSON files
  console.log('\n🔍 Validating project files...');
  const jsonFiles = [
    '.claude-plugin/plugin.json',
    '.claude-plugin/marketplace.json',
    'hooks/hooks.json',
    'mcp-configs/mcp-servers.json',
    'package.json',
  ];

  let allValid = true;
  jsonFiles.forEach(f => {
    try {
      JSON.parse(fs.readFileSync(path.join(root, f), 'utf8'));
      console.log(`  ✅ ${f}`);
    } catch (e) {
      console.log(`  ❌ ${f}: ${e.message}`);
      allValid = false;
    }
  });

  // Step 3: Try plugin registration
  console.log('\n🔌 Attempting plugin registration...');
  try {
    execSync(`claude plugin marketplace add "${root}"`, { stdio: 'ignore' });
    execSync('claude plugin install "ghost-office@ghost-office"', { stdio: 'ignore' });
    console.log('  ✅ Plugin registered successfully');
  } catch {
    console.log('  ℹ️  Plugin registration skipped (Claude Code CLI not found or not supported)');
  }

  console.log('\n✅ Setup complete!\n');
  console.log('📚 Next steps:');
  console.log('  1. Read BEGINNERS-GUIDE.md for usage instructions');
  console.log('  2. Try /infra-plan "Design a VPC" to get started');
  console.log('  3. Run: node scripts/validate-structure.js to verify installation');
  console.log('  4. Codex users: run `codex -C .` (or `codex -C . -p devops_strict`)\n');
}

main();
