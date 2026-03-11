#!/usr/bin/env node
/**
 * Capture screenshots of all dashboard tabs using Chrome DevTools Protocol.
 * Requires: ws (npm install --no-save ws)
 *
 * Usage: node scripts/capture-screenshots.mjs
 */

import { execSync, spawn } from 'child_process';
import { writeFileSync, mkdirSync } from 'fs';
import http from 'http';
import WebSocket from 'ws';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const BASE_URL = 'http://localhost:8686';
const OUT_DIR = 'assets/screenshots';
const CDP_PORT = 9222;
const WIDTH = 1440;

mkdirSync(OUT_DIR, { recursive: true });

try { execSync(`lsof -ti:${CDP_PORT} | xargs kill -9 2>/dev/null`); } catch {}

const sleep = ms => new Promise(r => setTimeout(r, ms));

function httpGetJson(url) {
  return new Promise((resolve, reject) => {
    http.get(url, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => resolve(JSON.parse(d)));
    }).on('error', reject);
  });
}

// Launch Chrome with a clean user data dir to avoid stale tabs
const chrome = spawn(CHROME, [
  `--remote-debugging-port=${CDP_PORT}`,
  '--headless=new',
  '--disable-gpu',
  '--no-first-run',
  '--no-default-browser-check',
  '--disable-extensions',
  `--user-data-dir=/tmp/chrome-screenshots-${Date.now()}`,
  `--window-size=${WIDTH},1000`,
  `${BASE_URL}/dashboard.html`
], { stdio: 'ignore' });

await sleep(3000);

function connectCDP(wsUrl) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(wsUrl);
    let id = 0;
    const pending = new Map();

    ws.on('open', () => resolve({
      async send(method, params = {}) {
        return new Promise((res, rej) => {
          const msgId = ++id;
          pending.set(msgId, { resolve: res, reject: rej });
          ws.send(JSON.stringify({ id: msgId, method, params }));
        });
      },
      close() { ws.close(); }
    }));

    ws.on('message', raw => {
      const msg = JSON.parse(raw.toString());
      if (msg.id && pending.has(msg.id)) {
        const p = pending.get(msg.id);
        pending.delete(msg.id);
        if (msg.error) p.reject(new Error(msg.error.message));
        else p.resolve(msg.result);
      }
    });

    ws.on('error', reject);
    setTimeout(() => reject(new Error('WebSocket connect timeout')), 5000);
  });
}

async function capture(cdp, filename, height = 1000) {
  await cdp.send('Emulation.setDeviceMetricsOverride', {
    width: WIDTH, height, deviceScaleFactor: 2, mobile: false
  });
  await sleep(300);

  const { data } = await cdp.send('Page.captureScreenshot', {
    format: 'png',
    clip: { x: 0, y: 0, width: WIDTH, height, scale: 1 }
  });

  const buf = Buffer.from(data, 'base64');
  writeFileSync(`${OUT_DIR}/${filename}`, buf);
  console.log(`  ✓ ${filename} (${Math.round(buf.length / 1024)}KB)`);
}

async function clickTab(cdp, selector) {
  await cdp.send('Runtime.evaluate', {
    expression: `document.querySelector('${selector}')?.click()`
  });
  await sleep(2000);
}

async function navigateTo(cdp, url) {
  await cdp.send('Page.navigate', { url });
  // Wait for load event
  await sleep(4000);
}

try {
  // Get page WS URL
  const tabs = await httpGetJson(`http://127.0.0.1:${CDP_PORT}/json/list`);
  const page = tabs.find(t => t.type === 'page');
  if (!page) throw new Error('No page found');

  console.log(`Connecting to: ${page.url}`);
  const cdp = await connectCDP(page.webSocketDebuggerUrl);
  await cdp.send('Page.enable');
  await cdp.send('Runtime.enable');

  // Wait for initial page to fully load
  await sleep(3000);

  console.log('\nCapturing screenshots...\n');

  // 1. Dashboard overview (already loaded)
  await capture(cdp, 'dashboard-overview.png', 1100);

  // 2-6. Other dashboard tabs
  const dashTabs = [
    { sel: '.nav-item[data-tab="agents"]', file: 'dashboard-agents.png', h: 1100 },
    { sel: '.nav-item[data-tab="workflow"]', file: 'dashboard-workflow.png', h: 1000 },
    { sel: '.nav-item[data-tab="errors"]', file: 'dashboard-errors.png', h: 1000 },
    { sel: '.nav-item[data-tab="messages"]', file: 'dashboard-messages.png', h: 1000 },
    { sel: '.nav-item[data-tab="org"]', file: 'dashboard-organization.png', h: 1300 },
  ];

  for (const tab of dashTabs) {
    await clickTab(cdp, tab.sel);
    await capture(cdp, tab.file, tab.h);
  }

  // 7. Analytics page
  await navigateTo(cdp, `${BASE_URL}/analytics.html`);
  await capture(cdp, 'analytics-overview.png', 1500);

  // 8. Landing page
  await navigateTo(cdp, `${BASE_URL}/`);
  await capture(cdp, 'landing-page.png', 1000);

  cdp.close();
  console.log(`\nDone! 8 screenshots saved to ${OUT_DIR}/`);
} catch (err) {
  console.error('Error:', err.message);
  process.exit(1);
} finally {
  chrome.kill();
  // Clean up temp dir
  try { execSync('rm -rf /tmp/chrome-screenshots-*'); } catch {}
}
