/**
 * Infrastructure Safety Check Hook
 * Validates infrastructure operations before execution.
 */

const { getTimestamp } = require('../lib/utils');

function checkInfraSafety(command) {
  const warnings = [];

  // Check for destructive Terraform operations
  if (/terraform\s+(destroy|apply\s+-auto-approve)/.test(command)) {
    warnings.push('🔴 DESTRUCTIVE: Terraform destroy or auto-approve detected');
  }

  // Check for kubectl delete without namespace
  if (/kubectl\s+delete\s+(?!.*-n\s)/.test(command)) {
    warnings.push('⚠️  kubectl delete without explicit namespace');
  }

  // Check for force operations
  if (/--force|--force-with-lease/.test(command)) {
    warnings.push('⚠️  Force operation detected - verify this is intentional');
  }

  // Check for production references
  if (/prod(uction)?/i.test(command)) {
    warnings.push('🔴 PRODUCTION environment detected - extra caution required');
  }

  return warnings;
}

function main() {
  const command = process.argv[2] || '';
  const warnings = checkInfraSafety(command);

  if (warnings.length > 0) {
    console.error(`[${getTimestamp()}] Infrastructure Safety Check:`);
    warnings.forEach(w => console.error(`  ${w}`));
    console.error('');
    console.error('  Please verify this operation before proceeding.');
  }
}

if (require.main === module) {
  main();
}

module.exports = { checkInfraSafety };
