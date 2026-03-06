#!/usr/bin/env node
// Microsoft 365 user management CLI via Graph API.
// Usage: node scripts/ms365.mjs <command> [args...]
//
// Requires env: AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID

const GRAPH = "https://graph.microsoft.com/v1.0";

const SKU_NAMES = {
  O365_BUSINESS_ESSENTIALS: "Microsoft 365 Business Basic",
  SMB_BUSINESS_ESSENTIALS: "Microsoft 365 Business Basic",
  O365_BUSINESS_PREMIUM: "Microsoft 365 Business Standard",
  SPB: "Microsoft 365 Business Premium",
  SMB_BUSINESS: "Microsoft 365 Apps for business",
  OFFICESUBSCRIPTION: "Microsoft 365 Apps for enterprise",
  STANDARDPACK: "Office 365 E1",
  ENTERPRISEPACK: "Office 365 E3",
  ENTERPRISEPREMIUM: "Office 365 E5",
  DEVELOPERPACK: "Office 365 E3 Developer",
  DESKLESSPACK: "Office 365 F3",
  SPE_E3: "Microsoft 365 E3",
  SPE_E5: "Microsoft 365 E5",
  SPE_F1: "Microsoft 365 F3",
  FLOW_FREE: "Power Automate Free",
  POWER_AUTOMATE_FREE: "Power Automate Free",
  POWER_BI_STANDARD: "Power BI / Fabric Free",
  PBI_FABRIC_FREE: "Power BI / Fabric Free",
  POWER_BI_PRO: "Power BI Pro",
  POWERAPPS_VIRAL: "Power Apps Plan 2 Trial",
  POWERAPPS_DEV: "Power Apps for Developer",
  TEAMS_EXPLORATORY: "Teams Exploratory",
  TEAMS_FREE: "Microsoft Teams Free",
  EXCHANGESTANDARD: "Exchange Online Plan 1",
  EXCHANGEENTERPRISE: "Exchange Online Plan 2",
  ATP_ENTERPRISE: "Defender for Office 365 P1",
  THREAT_INTELLIGENCE: "Defender for Office 365 P2",
  EMSPREMIUM: "Enterprise Mobility + Security E5",
  EMS: "Enterprise Mobility + Security E3",
  INTUNE_A: "Microsoft Intune Plan 1",
  AAD_PREMIUM: "Entra ID P1",
  AAD_PREMIUM_P2: "Entra ID P2",
  PROJECTPREMIUM: "Project Plan 5",
  VISIOCLIENT: "Visio Plan 2",
  MICROSOFT_COPILOT: "Microsoft 365 Copilot",
  STREAM: "Microsoft Stream Trial",
};

const EDITABLE_PROPS = [
  "displayName", "givenName", "surname", "department", "jobTitle",
  "officeLocation", "mobilePhone", "city", "state", "country",
  "postalCode", "streetAddress", "usageLocation", "companyName", "employeeId",
];

const USAGE = `Usage: node scripts/ms365.mjs <command> [args...]

Commands:
  info <name-or-upn>                                 User details + licenses
  list [name-filter]                                 List users
  licenses                                           Tenant license inventory
  assign-license <upn> <skuPartNumber>               Assign license
  remove-license <upn> <skuPartNumber>               Remove license
  create <upn> <displayName> <password> [dept] [title]  Create user
  edit <upn> <property> <value>                      Edit user property
  delete <upn>                                       Soft-delete user
  groups <upn>                                       User's group memberships
  list-groups [name-filter]                          List tenant groups
  add-to-group <upn> <groupName>                     Add user to group
  remove-from-group <upn> <groupName>                Remove user from group
  token                                              Print Graph API access token`;

// ─── Auth ──────────────────────────────────────────────────────────────────────

async function getToken() {
  const { AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID } = process.env;
  if (!AZURE_CLIENT_ID || !AZURE_CLIENT_SECRET || !AZURE_TENANT_ID) {
    die("AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, and AZURE_TENANT_ID must be set.");
  }
  const res = await fetch(
    `https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/v2.0/token`,
    {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: AZURE_CLIENT_ID,
        client_secret: AZURE_CLIENT_SECRET,
        scope: "https://graph.microsoft.com/.default",
        grant_type: "client_credentials",
      }),
    }
  );
  const data = await res.json();
  if (data.error) die(`Token error: ${data.error_description}`);
  return data.access_token;
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

let TOKEN;

function die(msg) {
  console.error(`Error: ${msg}`);
  process.exit(1);
}

function friendly(sku) {
  return SKU_NAMES[sku] || sku;
}

function pad(str, len) {
  return (str || "").substring(0, len).padEnd(len);
}

function groupType(g) {
  const unified = g.groupTypes?.includes("Unified");
  if (unified) return "M365";
  if (g.securityEnabled && !g.mailEnabled) return "Security";
  if (g.securityEnabled && g.mailEnabled) return "Mail+Sec";
  if (g.mailEnabled) return "Distribution";
  return "Other";
}

async function graph(path, { method = "GET", body, qs, rawResponse = false } = {}) {
  let url = path.startsWith("http") ? path : `${GRAPH}${path}`;
  if (qs) {
    const params = new URLSearchParams(qs);
    url += `?${params}`;
  }
  const opts = {
    method,
    headers: { Authorization: `Bearer ${TOKEN}`, "Content-Type": "application/json" },
  };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(url, opts);
  if (rawResponse) return res;
  if (res.status === 204) return null;
  const data = await res.json();
  if (data.error) die(data.error.message);
  return data;
}

async function resolveUserId(upn) {
  const data = await graph(`/users/${upn}`, { qs: { $select: "id" } });
  return data.id;
}

async function findGroup(name) {
  const data = await graph("/groups", {
    qs: { $filter: `displayName eq '${name}'`, $select: "id,displayName", $top: 1 },
  });
  if (!data.value?.length) die(`Group '${name}' not found. Run: node scripts/ms365.mjs list-groups`);
  return data.value[0];
}

// ─── Commands ──────────────────────────────────────────────────────────────────

async function cmdInfo(search) {
  if (!search) die("Usage: info <name-or-upn>");
  const select = "id,displayName,userPrincipalName,mail,department,jobTitle,accountEnabled";
  let data;
  if (search.includes("@")) {
    data = await graph(`/users/${search}`, { qs: { $select: select } });
    data = { value: [data] };
  } else {
    data = await graph("/users", {
      qs: {
        $filter: `startswith(displayName,'${search}') or startswith(userPrincipalName,'${search}')`,
        $select: select,
        $top: 5,
      },
    });
  }

  if (!data.value?.length) { console.log(`No users found matching '${search}'`); return; }

  for (const u of data.value) {
    const lic = await graph(`/users/${u.id}/licenseDetails`, { qs: { $select: "skuPartNumber" } });
    console.log(`=== ${u.displayName} ===`);
    console.log(`  UPN:        ${u.userPrincipalName}`);
    console.log(`  Department: ${u.department || "-"}`);
    console.log(`  Job Title:  ${u.jobTitle || "-"}`);
    console.log(`  Enabled:    ${u.accountEnabled}`);
    if (lic.value?.length) {
      console.log("  Licenses:");
      for (const l of lic.value) console.log(`    - ${friendly(l.skuPartNumber)} (${l.skuPartNumber})`);
    } else {
      console.log("  Licenses:   (none)");
    }
    console.log();
  }
}

async function cmdList(filter) {
  const select = "displayName,userPrincipalName,department,accountEnabled";
  const qs = { $select: select, $top: 50 };
  if (filter) {
    qs.$filter = `startswith(displayName,'${filter}') or startswith(userPrincipalName,'${filter}')`;
  } else {
    qs.$orderby = "displayName";
  }
  const data = await graph("/users", { qs });
  if (!data.value?.length) { console.log("No users found."); return; }

  console.log(`${pad("NAME", 30)} ${pad("UPN", 40)} ${pad("DEPARTMENT", 15)} ENABLED`);
  console.log(`${pad("----", 30)} ${pad("---", 40)} ${pad("----------", 15)} -------`);
  for (const u of data.value) {
    console.log(`${pad(u.displayName, 30)} ${pad(u.userPrincipalName, 40)} ${pad(u.department || "-", 15)} ${u.accountEnabled}`);
  }
  console.log(`\nTotal: ${data.value.length} users`);
}

async function cmdLicenses() {
  const data = await graph("/subscribedSkus");
  console.log(`${pad("LICENSE", 40)} ${pad("USED", 8)} ${pad("TOTAL", 8)} SKU`);
  console.log(`${pad("-------", 40)} ${pad("----", 8)} ${pad("-----", 8)} ---`);
  for (const s of data.value.filter(s => s.capabilityStatus === "Enabled")) {
    console.log(`${pad(friendly(s.skuPartNumber), 40)} ${pad(String(s.consumedUnits), 8)} ${pad(String(s.prepaidUnits.enabled), 8)} ${s.skuPartNumber}`);
  }
}

async function cmdAssignLicense(upn, skuPart) {
  if (!upn || !skuPart) die("Usage: assign-license <upn> <skuPartNumber>\nRun 'licenses' to see available SKUs.");
  const skus = await graph("/subscribedSkus");
  const sku = skus.value.find(s => s.skuPartNumber === skuPart);
  if (!sku) die(`SKU '${skuPart}' not found. Run: node scripts/ms365.mjs licenses`);

  console.log(`Assigning ${friendly(skuPart)} (${skuPart}) to ${upn}...`);
  await graph(`/users/${upn}/assignLicense`, {
    method: "POST",
    body: { addLicenses: [{ skuId: sku.skuId }], removeLicenses: [] },
  });
  console.log("License assigned successfully.");
}

async function cmdRemoveLicense(upn, skuPart) {
  if (!upn || !skuPart) die("Usage: remove-license <upn> <skuPartNumber>");
  const skus = await graph("/subscribedSkus");
  const sku = skus.value.find(s => s.skuPartNumber === skuPart);
  if (!sku) die(`SKU '${skuPart}' not found.`);

  console.log(`Removing ${friendly(skuPart)} (${skuPart}) from ${upn}...`);
  await graph(`/users/${upn}/assignLicense`, {
    method: "POST",
    body: { addLicenses: [], removeLicenses: [sku.skuId] },
  });
  console.log("License removed successfully.");
}

async function cmdCreate(upn, displayName, password, dept, title) {
  if (!upn || !displayName || !password) die("Usage: create <upn> <displayName> <password> [dept] [title]");
  const body = {
    accountEnabled: true,
    displayName,
    mailNickname: upn.split("@")[0],
    userPrincipalName: upn,
    passwordProfile: { forceChangePasswordNextSignIn: true, password },
    usageLocation: "IN",
  };
  if (dept) body.department = dept;
  if (title) body.jobTitle = title;

  console.log(`Creating user ${upn} (${displayName})...`);
  const data = await graph("/users", { method: "POST", body });
  console.log("User created successfully.");
  console.log(`  ID:  ${data.id}`);
  console.log(`  UPN: ${upn}`);
  console.log("  Password change required on first login.");
}

async function cmdEdit(upn, prop, value) {
  if (!upn || !prop || value === undefined) {
    die(`Usage: edit <upn> <property> <value>\nProperties: ${EDITABLE_PROPS.join(", ")}`);
  }
  if (!EDITABLE_PROPS.includes(prop)) {
    die(`Property '${prop}' not supported.\nSupported: ${EDITABLE_PROPS.join(", ")}`);
  }

  console.log(`Updating ${prop} for ${upn} to '${value}'...`);
  await graph(`/users/${upn}`, { method: "PATCH", body: { [prop]: value } });
  console.log("Updated successfully.");
}

async function cmdDelete(upn) {
  if (!upn) die("Usage: delete <upn>");
  console.log(`Deleting user ${upn} (soft-delete, recoverable for 30 days)...`);
  const res = await graph(`/users/${upn}`, { method: "DELETE", rawResponse: true });
  if (res.status === 204) {
    console.log(`User ${upn} deleted successfully.`);
    console.log("  Recoverable from Entra ID > Deleted users for 30 days.");
  } else {
    const data = await res.json();
    die(data.error?.message || `Unexpected response (HTTP ${res.status})`);
  }
}

async function cmdGroups(upn) {
  if (!upn) die("Usage: groups <upn>");
  const data = await graph(`/users/${upn}/memberOf`, {
    qs: { $select: "displayName,id,groupTypes,mailEnabled,securityEnabled", $top: 100 },
  });
  const groups = data.value.filter(v => v["@odata.type"] === "#microsoft.graph.group");
  if (!groups.length) { console.log(`User ${upn} is not a member of any groups.`); return; }

  console.log(`Groups for ${upn}:\n`);
  console.log(`${pad("GROUP NAME", 40)} ${pad("TYPE", 12)} ID`);
  console.log(`${pad("----------", 40)} ${pad("----", 12)} --`);
  for (const g of groups) {
    console.log(`${pad(g.displayName, 40)} ${pad(groupType(g), 12)} ${g.id}`);
  }
  console.log(`\nTotal: ${groups.length} groups`);
}

async function cmdListGroups(filter) {
  const qs = {
    $select: "id,displayName,groupTypes,mailEnabled,securityEnabled,mail",
    $top: 50,
    $orderby: "displayName",
  };
  if (filter) qs.$filter = `startswith(displayName,'${filter}')`;
  const data = await graph("/groups", { qs });
  if (!data.value?.length) { console.log("No groups found."); return; }

  console.log(`${pad("GROUP NAME", 40)} ${pad("TYPE", 12)} ${pad("EMAIL", 35)} ID`);
  console.log(`${pad("----------", 40)} ${pad("----", 12)} ${pad("-----", 35)} --`);
  for (const g of data.value) {
    console.log(`${pad(g.displayName, 40)} ${pad(groupType(g), 12)} ${pad(g.mail || "-", 35)} ${g.id}`);
  }
  console.log(`\nTotal: ${data.value.length} groups`);
}

async function cmdAddToGroup(upn, groupName) {
  if (!upn || !groupName) die("Usage: add-to-group <upn> <groupName>");
  const userId = await resolveUserId(upn);
  const group = await findGroup(groupName);

  console.log(`Adding ${upn} to group '${group.displayName}'...`);
  const res = await graph(`/groups/${group.id}/members/$ref`, {
    method: "POST",
    body: { "@odata.id": `${GRAPH}/directoryObjects/${userId}` },
    rawResponse: true,
  });

  if (res.status === 204) {
    console.log("Added successfully.");
  } else {
    const data = await res.json();
    if (data.error?.message?.toLowerCase().includes("already exist")) {
      console.log("User is already a member of this group.");
    } else {
      die(data.error?.message || `Unexpected response (HTTP ${res.status})`);
    }
  }
}

async function cmdRemoveFromGroup(upn, groupName) {
  if (!upn || !groupName) die("Usage: remove-from-group <upn> <groupName>");
  const userId = await resolveUserId(upn);
  const group = await findGroup(groupName);

  console.log(`Removing ${upn} from group '${group.displayName}'...`);
  const res = await graph(`/groups/${group.id}/members/${userId}/$ref`, {
    method: "DELETE",
    rawResponse: true,
  });

  if (res.status === 204) {
    console.log("Removed successfully.");
  } else {
    const data = await res.json();
    die(data.error?.message || `Unexpected response (HTTP ${res.status})`);
  }
}

// ─── Main ──────────────────────────────────────────────────────────────────────

const [command, ...args] = process.argv.slice(2);

if (!command) {
  console.error(USAGE);
  process.exit(1);
}

const COMMANDS = {
  info:               ([s]) => cmdInfo(s),
  list:               ([f]) => cmdList(f),
  licenses:           () => cmdLicenses(),
  "assign-license":   ([u, s]) => cmdAssignLicense(u, s),
  "remove-license":   ([u, s]) => cmdRemoveLicense(u, s),
  create:             ([u, d, p, dept, t]) => cmdCreate(u, d, p, dept, t),
  edit:               ([u, p, v]) => cmdEdit(u, p, v),
  delete:             ([u]) => cmdDelete(u),
  groups:             ([u]) => cmdGroups(u),
  "list-groups":      ([f]) => cmdListGroups(f),
  "add-to-group":     ([u, g]) => cmdAddToGroup(u, g),
  "remove-from-group":([u, g]) => cmdRemoveFromGroup(u, g),
  token:              () => { process.stdout.write(TOKEN); },
};

if (!COMMANDS[command]) {
  console.error(`Unknown command: ${command}\n`);
  console.error(USAGE);
  process.exit(1);
}

try {
  TOKEN = await getToken();
  await COMMANDS[command](args);
} catch (err) {
  die(err.message);
}
