---
name: acodax-erp-office-admin
description: Use when managing Acodax Office ERP. Covers user provisioning, role management, branch operations, password resets, and system administration via REST API.
user-invocable: true
disable-model-invocation: true
context: fork
allowed-tools: ["Read", "Write", "Bash"]
argument-hint: "user action (e.g., list users, create user, reset password)"
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "#!/bin/bash\nif [ -z \"$ACODAX_OFFICE_LINK\" ] || [ -z \"$ACODAX_OFFICE_USERNAME\" ] || [ -z \"$ACODAX_OFFICE_PASSWORD\" ]; then\n  echo '❌ [Hook] Acodax Office credentials not configured. Set ACODAX_OFFICE_LINK, ACODAX_OFFICE_USERNAME, ACODAX_OFFICE_PASSWORD.' >&2\n  exit 1\nfi"
---

# Acodax Office ERP Administration

## Overview
Acodax Office ERP administration via REST API. Manage users, roles, branches, and system configuration using the CLI tool at `scripts/acodax.mjs`.

## CLI Reference

### User Management
```bash
# List all users or search
node scripts/acodax.mjs list-users
node scripts/acodax.mjs list-users "search-term"

# Get user details
node scripts/acodax.mjs user-info <user-id>

# Create user
node scripts/acodax.mjs create-user <username> <email> <password> <first_name> [last_name] [role_id] [branch_id]

# Update user field
node scripts/acodax.mjs update-user <user-id> <field> <value>
# Editable fields: first_name, last_name, email, username, phone, role_id,
#                  branch_id, language, time_zone, ph_country_code

# Change password
node scripts/acodax.mjs change-password <user-id> <new-password>

# Enable / disable user
node scripts/acodax.mjs change-status <user-id> 1   # activate
node scripts/acodax.mjs change-status <user-id> 0   # deactivate

# Delete user
node scripts/acodax.mjs delete-user <user-id>
```

### System Lookups
```bash
# List roles (to get role_id for user creation)
node scripts/acodax.mjs roles

# List branches (to get branch_id for user creation)
node scripts/acodax.mjs branches

# List companies
node scripts/acodax.mjs companies

# Get auth token for custom API calls
TOKEN=$(node scripts/acodax.mjs token)
```

## API Details

### Authentication
- Login: `POST /api/auth/login` with `username` and `password` in JSON body
- Required headers: `X-Acodax-Tenant-Id`, `X-Acodax-App`
- Returns Bearer token used for all subsequent requests

### Common Headers
All authenticated requests require:
- `Authorization: Bearer <token>`
- `X-Acodax-App: ERP`
- `X-Acodax-Tenant-Id: <tenant-uuid>`
- `X-Acodax-Request-Id: <unique-uuid>` (idempotency)
- `X-Acodax-Trans-Branch-Id: <branch-uuid>` (for transactional operations)

### Response Structure
List endpoints return nested paginated responses:
```json
{"success": true, "data": {"data": [...], "current_page": 1, ...}}
```
The actual array is at `response.data.data`, not `response.data`. The CLI handles this automatically via `extractList()`.

### User Endpoints
| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/user` | List users |
| GET | `/api/user/{id}` | Get user details |
| POST | `/api/user/register` | Create user (multipart form) |
| POST | `/api/user/update/{id}` | Update user (multipart form, `_method=PUT`) |
| POST | `/api/user/change-user-password` | Change password (JSON) |
| POST | `/api/user/change-user-status` | Enable/disable user (JSON) |
| DELETE | `/api/user/{id}` | Delete user |

### System Endpoints
| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/roles` | List roles |
| GET | `/api/branches` | List branches |
| GET | `/api/companies` | List companies |

## Best Practices
1. Always look up `role_id` and `branch_id` before creating users
2. Deactivate users before deleting (soft-delete first)
3. Use strong passwords for user creation
4. Verify user exists before updates or password changes
5. The CLI handles token refresh automatically on each invocation
