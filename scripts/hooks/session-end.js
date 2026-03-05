/**
 * Session End Hook
 * Saves session state and context when the agent session ends.
 */

const fs = require('fs');
const path = require('path');
const { getProjectRoot, writeJSON, getTimestamp } = require('../lib/utils');

function main() {
  const projectRoot = getProjectRoot();
  const stateDir = path.join(projectRoot, '.devops-state');

  if (!fs.existsSync(stateDir)) {
    fs.mkdirSync(stateDir, { recursive: true });
  }

  const stateFile = path.join(stateDir, 'session-state.json');
  const state = {
    lastSessionEnd: getTimestamp(),
    activeEnvironment: process.env.DEVOPS_ENV || 'development',
    pendingActions: [],
  };

  writeJSON(stateFile, state);
  console.log(`[${getTimestamp()}] Session state saved.`);
}

if (require.main === module) {
  main();
}

module.exports = { main };
