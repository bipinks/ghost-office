#!/usr/bin/env node
// Acodax Office ERP administration CLI via REST API.
// Usage: node scripts/acodax.mjs <command> [args...]
//
// Required env vars:
//   ACODAX_OFFICE_LINK       — Base URL (e.g., http://localhost:8008)
//   ACODAX_OFFICE_USERNAME   — Admin username
//   ACODAX_OFFICE_PASSWORD   — Admin password
//
// Optional env vars:
//   ACODAX_OFFICE_TENANT_ID  — Tenant UUID (default: 6c8a0c62-2a22-41fb-8121-333999137558)
//   ACODAX_OFFICE_BRANCH_ID  — Default branch UUID
//   ACODAX_OFFICE_APP        — App identifier (default: ERP)

import { randomUUID } from "node:crypto";

// ─── Config ────────────────────────────────────────────────────────────────────

const {
  ACODAX_OFFICE_LINK,
  ACODAX_OFFICE_USERNAME,
  ACODAX_OFFICE_PASSWORD,
  ACODAX_OFFICE_TENANT_ID = "6c8a0c62-2a22-41fb-8121-333999137558",
  ACODAX_OFFICE_BRANCH_ID = "",
  ACODAX_OFFICE_APP = "ERP",
} = process.env;

const USAGE = `Usage: node scripts/acodax.mjs <command> [args...]

Commands:
  User Management:
    list-users [search]                              List users (optional search)
    user-info <user-id>                              Get user details
    create-user <username> <email> <password> <first_name> [last_name] [role_id] [branch_id]
    update-user <user-id> <field> <value>            Update a user field
    change-password <user-id> <new-password>         Change user password
    change-status <user-id> <1|0>                    Enable (1) or disable (0) user
    delete-user <user-id>                            Delete a user

  System:
    token                                            Print auth token
    roles                                            List available roles
    branches                                         List available branches
    companies                                        List available companies

Environment variables:
  ACODAX_OFFICE_LINK, ACODAX_OFFICE_USERNAME, ACODAX_OFFICE_PASSWORD (required)
  ACODAX_OFFICE_TENANT_ID, ACODAX_OFFICE_BRANCH_ID, ACODAX_OFFICE_APP (optional)`;

// ─── Helpers ───────────────────────────────────────────────────────────────────

function die(msg) {
  console.error(`Error: ${msg}`);
  process.exit(1);
}

function pad(str, len) {
  return (str || "-").substring(0, len).padEnd(len);
}

function validateEnv() {
  if (!ACODAX_OFFICE_LINK) die("ACODAX_OFFICE_LINK is not set.");
  if (!ACODAX_OFFICE_USERNAME) die("ACODAX_OFFICE_USERNAME is not set.");
  if (!ACODAX_OFFICE_PASSWORD) die("ACODAX_OFFICE_PASSWORD is not set.");
}

/** Extract array from API response, handling nested paginated structures like {data:{data:[...]}} */
function extractList(data, ...altKeys) {
  // Direct array
  if (Array.isArray(data)) return data;
  // Check alt keys first (e.g. data.users, data.roles)
  for (const key of altKeys) {
    if (Array.isArray(data[key])) return data[key];
  }
  // Nested paginated: {data: {data: [...]}} or {data: [...]}
  if (data.data) {
    if (Array.isArray(data.data)) return data.data;
    if (Array.isArray(data.data.data)) return data.data.data;
  }
  return [];
}

// ─── Auth ──────────────────────────────────────────────────────────────────────

let TOKEN = null;

async function login() {
  const res = await fetch(`${ACODAX_OFFICE_LINK}/api/auth/login`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-Acodax-Tenant-Id": ACODAX_OFFICE_TENANT_ID,
      "X-Acodax-App": ACODAX_OFFICE_APP,
    },
    body: JSON.stringify({
      username: ACODAX_OFFICE_USERNAME,
      password: ACODAX_OFFICE_PASSWORD,
    }),
  });

  const data = await res.json();

  if (!res.ok) {
    die(`Login failed (HTTP ${res.status}): ${data.message || JSON.stringify(data)}`);
  }

  // Extract token — handle common response shapes
  const token = data.token || data.access_token || data.data?.token || data.data?.access_token;
  if (!token) die(`Login succeeded but no token found in response: ${JSON.stringify(data)}`);

  return token;
}

// ─── API Client ────────────────────────────────────────────────────────────────

function baseHeaders() {
  return {
    Accept: "application/json",
    Authorization: `Bearer ${TOKEN}`,
    "X-Acodax-App": ACODAX_OFFICE_APP,
    "X-Acodax-Tenant-Id": ACODAX_OFFICE_TENANT_ID,
    "X-Acodax-Request-Id": randomUUID(),
    "Idempotency-Key": randomUUID(),
    Timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    ...(ACODAX_OFFICE_BRANCH_ID && {
      "X-Acodax-Trans-Branch-Id": ACODAX_OFFICE_BRANCH_ID,
    }),
  };
}

async function api(path, { method = "GET", body, form, qs, rawResponse = false } = {}) {
  let url = `${ACODAX_OFFICE_LINK}${path}`;
  if (qs) {
    const params = new URLSearchParams(qs);
    url += `?${params}`;
  }

  const headers = baseHeaders();
  const opts = { method, headers };

  if (form) {
    // Multipart form data — let fetch set Content-Type with boundary
    const formData = new FormData();
    for (const [key, value] of Object.entries(form)) {
      if (Array.isArray(value)) {
        value.forEach((v, i) => formData.append(`${key}[${i}]`, v));
      } else if (value !== undefined && value !== null) {
        formData.append(key, String(value));
      }
    }
    opts.body = formData;
    // Remove Content-Type so fetch auto-sets multipart boundary
    delete headers["Content-Type"];
  } else if (body) {
    headers["Content-Type"] = "application/json";
    opts.body = JSON.stringify(body);
  }

  const res = await fetch(url, opts);
  if (rawResponse) return res;

  // Handle empty responses
  const text = await res.text();
  if (!text) {
    if (res.ok) return null;
    die(`API error (HTTP ${res.status}): Empty response`);
  }

  let data;
  try {
    data = JSON.parse(text);
  } catch {
    if (res.ok) return { raw: text };
    die(`API error (HTTP ${res.status}): ${text.substring(0, 200)}`);
  }

  if (!res.ok) {
    const msg = data.message || data.error || JSON.stringify(data);
    die(`API error (HTTP ${res.status}): ${msg}`);
  }

  return data;
}

// ─── Commands: User Management ─────────────────────────────────────────────────

async function cmdListUsers(search) {
  const qs = {};
  if (search) qs.search = search;
  const data = await api("/api/user", { qs });

  const users = extractList(data, "users");
  if (!users.length) {
    console.log("No users found.");
    return;
  }

  console.log(`${pad("NAME", 30)} ${pad("USERNAME", 20)} ${pad("EMAIL", 35)} ${pad("STATUS", 8)} ID`);
  console.log(`${pad("----", 30)} ${pad("--------", 20)} ${pad("-----", 35)} ${pad("------", 8)} --`);
  for (const u of users) {
    const name = [u.first_name, u.last_name].filter(Boolean).join(" ") || u.name || "-";
    const status = u.is_active === 1 || u.is_active === true ? "Active" : "Inactive";
    console.log(`${pad(name, 30)} ${pad(u.username, 20)} ${pad(u.email, 35)} ${pad(status, 8)} ${u.id}`);
  }
  console.log(`\nTotal: ${users.length} users`);
}

async function cmdUserInfo(userId) {
  if (!userId) die("Usage: user-info <user-id>");
  const data = await api(`/api/user/${userId}`);
  const u = data.data?.data || data.data || data.user || data;

  const name = [u.first_name, u.last_name].filter(Boolean).join(" ") || u.name || "-";
  console.log(`=== ${name} ===`);
  console.log(`  ID:         ${u.id}`);
  console.log(`  Username:   ${u.username || "-"}`);
  console.log(`  Email:      ${u.email || "-"}`);
  console.log(`  Phone:      ${u.phone || "-"}`);
  console.log(`  Role:       ${u.role?.name || u.role_id || "-"}`);
  console.log(`  Branch:     ${u.branch?.name || u.branch_id || "-"}`);
  console.log(`  Language:   ${u.language || "-"}`);
  console.log(`  Timezone:   ${u.time_zone || "-"}`);
  console.log(`  Status:     ${u.is_active === 1 || u.is_active === true ? "Active" : "Inactive"}`);
  console.log(`  Created:    ${u.created_at || "-"}`);
}

async function cmdCreateUser(username, email, password, firstName, lastName, roleId, branchId) {
  if (!username || !email || !password || !firstName) {
    die("Usage: create-user <username> <email> <password> <first_name> [last_name] [role_id] [branch_id]");
  }

  const form = {
    first_name: firstName,
    username,
    email,
    password,
    c_password: password,
    language: "EN",
  };
  if (lastName) form.last_name = lastName;
  if (roleId) form.role_id = roleId;
  if (branchId) form.branch_id = branchId;
  else if (ACODAX_OFFICE_BRANCH_ID) form.branch_id = ACODAX_OFFICE_BRANCH_ID;

  console.log(`Creating user '${username}' (${email})...`);
  const data = await api("/api/user/register", { method: "POST", form });

  const u = data.data?.data || data.data || data.user || data;
  console.log("User created successfully.");
  if (u.id) console.log(`  ID: ${u.id}`);
}

async function cmdUpdateUser(userId, field, value) {
  if (!userId || !field || value === undefined) {
    die("Usage: update-user <user-id> <field> <value>\nFields: first_name, last_name, email, username, phone, role_id, branch_id, language, time_zone, ph_country_code");
  }

  const ALLOWED_FIELDS = [
    "first_name", "last_name", "email", "username", "phone",
    "role_id", "branch_id", "language", "time_zone", "ph_country_code",
    "default_cash_collection_account", "default_bank_transfer_collection_account",
    "default_card_payment_collection_account",
  ];

  if (!ALLOWED_FIELDS.includes(field)) {
    die(`Field '${field}' not supported.\nSupported: ${ALLOWED_FIELDS.join(", ")}`);
  }

  const form = { [field]: value, _method: "PUT" };

  console.log(`Updating ${field} for user ${userId}...`);
  await api(`/api/user/update/${userId}`, { method: "POST", form });
  console.log("Updated successfully.");
}

async function cmdChangePassword(userId, password) {
  if (!userId || !password) die("Usage: change-password <user-id> <new-password>");

  console.log(`Changing password for user ${userId}...`);
  await api("/api/user/change-user-password", {
    method: "POST",
    body: { user_id: userId, password, c_password: password },
  });
  console.log("Password changed successfully.");
}

async function cmdChangeStatus(userId, status) {
  if (!userId || status === undefined) die("Usage: change-status <user-id> <1|0> (1=active, 0=inactive)");
  const isActive = parseInt(status, 10);
  if (isActive !== 0 && isActive !== 1) die("Status must be 1 (active) or 0 (inactive).");

  const label = isActive ? "Activating" : "Deactivating";
  console.log(`${label} user ${userId}...`);
  await api("/api/user/change-user-status", {
    method: "POST",
    body: { user_id: userId, is_active: isActive },
  });
  console.log(`User ${isActive ? "activated" : "deactivated"} successfully.`);
}

async function cmdDeleteUser(userId) {
  if (!userId) die("Usage: delete-user <user-id>");

  console.log(`Deleting user ${userId}...`);
  const res = await api(`/api/user/${userId}`, { method: "DELETE", rawResponse: true });

  if (res.ok) {
    console.log("User deleted successfully.");
  } else {
    const data = await res.json().catch(() => ({}));
    die(data.message || `Failed (HTTP ${res.status})`);
  }
}

// ─── Commands: System ──────────────────────────────────────────────────────────

async function cmdRoles() {
  const data = await api("/api/roles");
  const roles = extractList(data, "roles");
  if (!roles.length) { console.log("No roles found."); return; }

  console.log(`${pad("ROLE NAME", 35)} ID`);
  console.log(`${pad("---------", 35)} --`);
  for (const r of roles) {
    console.log(`${pad(r.name || r.display_name || "-", 35)} ${r.id}`);
  }
  console.log(`\nTotal: ${roles.length} roles`);
}

async function cmdBranches() {
  const data = await api("/api/branches");
  const branches = extractList(data, "branches");
  if (!branches.length) { console.log("No branches found."); return; }

  console.log(`${pad("BRANCH NAME", 45)} ID`);
  console.log(`${pad("-----------", 45)} --`);
  for (const b of branches) {
    console.log(`${pad(b.name || b.display_name || "-", 45)} ${b.id}`);
  }
  console.log(`\nTotal: ${branches.length} branches`);
}

async function cmdCompanies() {
  const data = await api("/api/companies");
  const companies = extractList(data, "companies");
  if (!companies.length) { console.log("No companies found."); return; }

  console.log(`${pad("COMPANY NAME", 45)} ID`);
  console.log(`${pad("------------", 45)} --`);
  for (const c of companies) {
    console.log(`${pad(c.name || c.display_name || "-", 45)} ${c.id}`);
  }
  console.log(`\nTotal: ${companies.length} companies`);
}

// ─── Dispatch ──────────────────────────────────────────────────────────────────

const [command, ...args] = process.argv.slice(2);

if (!command) {
  console.error(USAGE);
  process.exit(1);
}

const COMMANDS = {
  // User management
  "list-users":       ([s]) => cmdListUsers(s),
  "user-info":        ([id]) => cmdUserInfo(id),
  "create-user":      ([u, e, p, fn, ln, r, b]) => cmdCreateUser(u, e, p, fn, ln, r, b),
  "update-user":      ([id, f, v]) => cmdUpdateUser(id, f, v),
  "change-password":  ([id, p]) => cmdChangePassword(id, p),
  "change-status":    ([id, s]) => cmdChangeStatus(id, s),
  "delete-user":      ([id]) => cmdDeleteUser(id),
  // System
  token:              () => { process.stdout.write(TOKEN); },
  roles:              () => cmdRoles(),
  branches:           () => cmdBranches(),
  companies:          () => cmdCompanies(),
};

if (!COMMANDS[command]) {
  console.error(`Unknown command: ${command}\n`);
  console.error(USAGE);
  process.exit(1);
}

try {
  validateEnv();
  TOKEN = await login();
  await COMMANDS[command](args);
} catch (err) {
  die(err.message);
}
