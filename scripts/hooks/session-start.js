/**
 * Session Start Hook
 * Loads saved context and state when a new agent session begins.
 */

const fs = require('fs');
const path = require('path');
const { getProjectRoot, readJSON, getTimestamp } = require('../lib/utils');

function main() {
  const projectRoot = getProjectRoot();
  const stateDir = path.join(projectRoot, '.devops-state');
  const stateFile = path.join(stateDir, 'session-state.json');

  console.log(`[${getTimestamp()}] Session starting...`);

  // Load previous session state
  if (fs.existsSync(stateFile)) {
    const state = readJSON(stateFile);
    if (state) {
      console.log(`Previous session: ${state.lastSessionEnd || 'unknown'}`);
      console.log(`Active environment: ${state.activeEnvironment || 'not set'}`);
      if (state.pendingActions && state.pendingActions.length > 0) {
        console.log(`Pending actions: ${state.pendingActions.length}`);
        state.pendingActions.forEach((action, i) => {
          console.log(`  ${i + 1}. ${action}`);
        });
      }
    }
  } else {
    console.log('No previous session state found. Fresh start.');
  }

  // Check for active deployments
  const deploymentsFile = path.join(stateDir, 'active-deployments.json');
  if (fs.existsSync(deploymentsFile)) {
    const deployments = readJSON(deploymentsFile);
    if (deployments && deployments.length > 0) {
      console.log(`⚠️  Active deployments: ${deployments.length}`);
      deployments.forEach(d => {
        console.log(`  - ${d.service} → ${d.environment} (started: ${d.startedAt})`);
      });
    }
  }

  console.log(`[${getTimestamp()}] Session ready.`);
}

if (require.main === module) {
  main();
}

module.exports = { main };
