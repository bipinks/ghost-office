---
name: ms365-admin
description: Use when managing Microsoft 365 tenants via Graph API. Covers user provisioning, license assignment, group management, Exchange Online, SharePoint, Teams admin, MFA setup, and compliance policies.
user-invocable: true
disable-model-invocation: true
context: fork
allowed-tools: ["Read", "Write", "Bash"]
argument-hint: "user email or admin action"
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "#!/bin/bash\nif [ -z \"$AZURE_CLIENT_ID\" ] && [ -z \"$MS_GRAPH_TOKEN\" ]; then\n  echo '❌ [Hook] MS Graph credentials not configured. Set AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID.' >&2\n  exit 1\nfi\nif [ -n \"$AZURE_CLIENT_ID\" ] && [ -n \"$AZURE_CLIENT_SECRET\" ] && [ -n \"$AZURE_TENANT_ID\" ]; then\n  export ACCESS_TOKEN=$(scripts/ms-graph-token.sh 2>/dev/null)\n  export MS_GRAPH_TOKEN=\"$ACCESS_TOKEN\"\nfi"
---

# Microsoft 365 Administration

## Overview
Comprehensive Microsoft 365 administration patterns using Microsoft Graph API and PowerShell for user management, licensing, Teams, SharePoint, and Exchange.

## User Provisioning

### Create User via Graph API
```bash
# Create new user
curl -X POST https://graph.microsoft.com/v1.0/users \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "accountEnabled": true,
    "displayName": "John Smith",
    "mailNickname": "jsmith",
    "userPrincipalName": "jsmith@contoso.com",
    "passwordProfile": {
      "forceChangePasswordNextSignIn": true,
      "password": "TempP@ssw0rd!"
    },
    "usageLocation": "US",
    "department": "Engineering",
    "jobTitle": "Software Engineer",
    "officeLocation": "Building A"
  }'
```

### PowerShell User Management
```powershell
# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

# Create user
$PasswordProfile = @{
    Password = "TempP@ssw0rd!"
    ForceChangePasswordNextSignIn = $true
}

New-MgUser -DisplayName "John Smith" `
    -MailNickname "jsmith" `
    -UserPrincipalName "jsmith@contoso.com" `
    -PasswordProfile $PasswordProfile `
    -AccountEnabled `
    -UsageLocation "US" `
    -Department "Engineering"

# Bulk user creation from CSV
$users = Import-Csv -Path "new-users.csv"
foreach ($user in $users) {
    $params = @{
        DisplayName = $user.DisplayName
        UserPrincipalName = $user.UPN
        MailNickname = $user.MailNickname
        PasswordProfile = @{
            Password = $user.TempPassword
            ForceChangePasswordNextSignIn = $true
        }
        AccountEnabled = $true
        UsageLocation = $user.Location
        Department = $user.Department
        JobTitle = $user.JobTitle
    }
    New-MgUser @params
    Write-Host "Created: $($user.DisplayName)"
}
```

## License Management

### Assign Licenses
```powershell
# Get available licenses
Get-MgSubscribedSku | Select-Object SkuPartNumber, ConsumedUnits, PrepaidUnits

# Assign E3 license to user
$E3Sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq "ENTERPRISEPACK" }

Set-MgUserLicense -UserId "jsmith@contoso.com" `
    -AddLicenses @(@{SkuId = $E3Sku.SkuId}) `
    -RemoveLicenses @()

# Assign license with disabled plans
Set-MgUserLicense -UserId "jsmith@contoso.com" `
    -AddLicenses @(@{
        SkuId = $E3Sku.SkuId
        DisabledPlans = @("YAMMER_ENTERPRISE", "SWAY")
    }) `
    -RemoveLicenses @()

# Bulk license assignment
$users = Get-MgUser -Filter "department eq 'Engineering'" -All
foreach ($user in $users) {
    Set-MgUserLicense -UserId $user.Id `
        -AddLicenses @(@{SkuId = $E3Sku.SkuId}) `
        -RemoveLicenses @()
}
```

## Teams Management

### Create Team
```bash
# Create team from group
curl -X POST "https://graph.microsoft.com/v1.0/teams" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template@odata.bind": "https://graph.microsoft.com/v1.0/teamsTemplates('\''standard'\'')",
    "displayName": "Engineering Team",
    "description": "Engineering department team",
    "members": [
      {
        "@odata.type": "#microsoft.graph.aadUserConversationMember",
        "roles": ["owner"],
        "user@odata.bind": "https://graph.microsoft.com/v1.0/users('\''user-id'\'')"
      }
    ],
    "channels": [
      { "displayName": "Announcements", "isFavoriteByDefault": true },
      { "displayName": "Development", "isFavoriteByDefault": true },
      { "displayName": "DevOps", "isFavoriteByDefault": true }
    ]
  }'
```

## SharePoint Administration
```powershell
# Connect to SharePoint
Connect-PnPOnline -Url "https://contoso.sharepoint.com" -Interactive

# Create new site
New-PnPSite -Type TeamSite -Title "Engineering Docs" -Alias "engineering-docs"

# Set permissions
Set-PnPGroupPermissions -Identity "Engineering Docs Members" -AddRole "Edit"

# Create document library
New-PnPList -Title "Technical Documentation" -Template DocumentLibrary
```

## Security & Compliance

### Conditional Access
```powershell
# Require MFA for all users
$params = @{
    DisplayName = "Require MFA for all users"
    State = "enabled"
    Conditions = @{
        Users = @{ IncludeUsers = @("All") }
        Applications = @{ IncludeApplications = @("All") }
    }
    GrantControls = @{
        BuiltInControls = @("mfa")
        Operator = "OR"
    }
}
New-MgIdentityConditionalAccessPolicy @params
```

## Best Practices
1. **Automated provisioning** — Use Graph API for consistent user onboarding
2. **Group-based licensing** — Assign licenses via groups, not individuals
3. **Least privilege** — Assign minimal admin roles, use PIM for elevation
4. **MFA enforcement** — Require MFA for all users via Conditional Access
5. **Naming conventions** — Standardize group, team, and site naming
6. **Guest access** — Configure policy for external collaboration
7. **Data governance** — Configure retention policies and sensitivity labels
8. **Monitoring** — Review sign-in logs and audit logs regularly
9. **Backup** — Third-party backup for Exchange, SharePoint, OneDrive, Teams
10. **Documentation** — Maintain runbooks for common admin tasks
