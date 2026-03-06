---
name: entra-id-admin
description: Use when managing Microsoft Entra ID (Azure AD). Covers user/group lifecycle, Conditional Access policies, MFA setup, SSO configuration, Privileged Identity Management, app registrations, B2B guest access, and directory sync.
user-invocable: true
disable-model-invocation: true
context: fork
allowed-tools: ["Read", "Write", "Bash"]
argument-hint: "identity action (e.g., create conditional access policy, configure SSO)"
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "#!/bin/bash\nif [ -z \"$AZURE_CLIENT_ID\" ] && [ -z \"$MS_GRAPH_TOKEN\" ]; then\n  echo '❌ [Hook] Entra ID credentials not configured. Set AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID.' >&2\n  exit 1\nfi\nif [ -n \"$AZURE_CLIENT_ID\" ] && [ -n \"$AZURE_CLIENT_SECRET\" ] && [ -n \"$AZURE_TENANT_ID\" ]; then\n  export ACCESS_TOKEN=$(node scripts/ms365.mjs token 2>/dev/null)\n  export MS_GRAPH_TOKEN=\"$ACCESS_TOKEN\"\nfi"
---

# Microsoft Entra ID Administration

## Overview
Identity and access management using Microsoft Entra ID (formerly Azure AD) via Microsoft Graph API and PowerShell. Covers user lifecycle, Conditional Access, SSO, MFA, PIM, and directory synchronization.

## User & Group Management

### Create Security Group
```bash
curl -X POST https://graph.microsoft.com/v1.0/groups \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "SG-Engineering-Developers",
    "description": "Security group for engineering developers",
    "mailEnabled": false,
    "mailNickname": "sg-eng-devs",
    "securityEnabled": true,
    "groupTypes": []
  }'
```

### PowerShell Group Management
```powershell
Connect-MgGraph -Scopes "Group.ReadWrite.All","GroupMember.ReadWrite.All"

# Create dynamic group (auto-membership by department)
$params = @{
    DisplayName = "DG-Engineering-All"
    Description = "Dynamic group for all Engineering staff"
    MailEnabled = $false
    MailNickname = "dg-eng-all"
    SecurityEnabled = $true
    GroupTypes = @("DynamicMembership")
    MembershipRule = '(user.department -eq "Engineering")'
    MembershipRuleProcessingState = "On"
}
New-MgGroup @params

# Add member to static group
New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userId

# List group members
Get-MgGroupMember -GroupId $groupId | ForEach-Object {
    Get-MgUser -UserId $_.Id | Select-Object DisplayName, UserPrincipalName
}
```

## Conditional Access Policies

### Require MFA for Admins
```powershell
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

$params = @{
    DisplayName = "CA001 - Require MFA for Admins"
    State = "enabledForReportingButNotEnforced"  # Test first!
    Conditions = @{
        Users = @{
            IncludeRoles = @(
                "62e90394-69f5-4237-9190-012177145e10"  # Global Administrator
                "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"  # SharePoint Administrator
                "fe930be7-5e62-47db-91af-98c3a49a38b1"  # User Administrator
            )
        }
        Applications = @{ IncludeApplications = @("All") }
    }
    GrantControls = @{
        BuiltInControls = @("mfa")
        Operator = "OR"
    }
}
New-MgIdentityConditionalAccessPolicy @params
```

### Block Legacy Authentication
```powershell
$params = @{
    DisplayName = "CA002 - Block Legacy Authentication"
    State = "enabledForReportingButNotEnforced"
    Conditions = @{
        Users = @{ IncludeUsers = @("All") }
        Applications = @{ IncludeApplications = @("All") }
        ClientAppTypes = @("exchangeActiveSync", "other")
    }
    GrantControls = @{
        BuiltInControls = @("block")
        Operator = "OR"
    }
}
New-MgIdentityConditionalAccessPolicy @params
```

### Require Compliant Device
```powershell
$params = @{
    DisplayName = "CA003 - Require Compliant Device for Office 365"
    State = "enabledForReportingButNotEnforced"
    Conditions = @{
        Users = @{ IncludeUsers = @("All") }
        Applications = @{
            IncludeApplications = @("Office365")
        }
        Platforms = @{
            IncludePlatforms = @("all")
        }
    }
    GrantControls = @{
        BuiltInControls = @("compliantDevice")
        Operator = "OR"
    }
}
New-MgIdentityConditionalAccessPolicy @params
```

## Privileged Identity Management (PIM)

### Activate Eligible Role
```powershell
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"

# List eligible role assignments
Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -Filter "principalId eq '$userId'"

# Activate role (just-in-time)
$params = @{
    Action = "selfActivate"
    PrincipalId = $userId
    RoleDefinitionId = $roleId
    DirectoryScopeId = "/"
    Justification = "Need Global Admin to update Conditional Access policy"
    ScheduleInfo = @{
        StartDateTime = (Get-Date).ToUniversalTime().ToString("o")
        Expiration = @{
            Type = "AfterDuration"
            Duration = "PT4H"  # 4 hours
        }
    }
}
New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest @params
```

## App Registrations & SSO

### Register Application
```bash
curl -X POST https://graph.microsoft.com/v1.0/applications \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "Internal Portal",
    "signInAudience": "AzureADMyOrg",
    "web": {
      "redirectUris": ["https://portal.company.com/auth/callback"],
      "implicitGrantSettings": {
        "enableIdTokenIssuance": true
      }
    },
    "requiredResourceAccess": [{
      "resourceAppId": "00000003-0000-0000-c000-000000000000",
      "resourceAccess": [
        { "id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d", "type": "Scope" }
      ]
    }]
  }'
```

### Configure SAML SSO
```powershell
# Create enterprise app for SAML SSO
$params = @{
    DisplayName = "Jira SAML SSO"
    Tags = @("WindowsAzureActiveDirectoryIntegratedApp")
}
$servicePrincipal = New-MgServicePrincipal @params

# Configure SAML settings
$samlParams = @{
    PreferredSingleSignOnMode = "saml"
}
Update-MgServicePrincipal -ServicePrincipalId $servicePrincipal.Id @samlParams
```

## B2B Guest Access

### Invite External User
```powershell
$invitation = @{
    InvitedUserEmailAddress = "partner@external.com"
    InviteRedirectUrl = "https://myapps.microsoft.com"
    SendInvitationMessage = $true
    InvitedUserDisplayName = "External Partner"
    InvitedUserMessageInfo = @{
        CustomizedMessageBody = "Welcome to our collaboration workspace."
    }
}
New-MgInvitation @invitation
```

## Audit & Monitoring

### Review Sign-in Logs
```powershell
# Failed sign-ins in last 24 hours
$since = (Get-Date).AddDays(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
Get-MgAuditLogSignIn -Filter "status/errorCode ne 0 and createdDateTime ge $since" `
    -Top 50 | Select-Object UserDisplayName, AppDisplayName, Status, IpAddress,
    ConditionalAccessStatus

# Risky sign-ins
Get-MgRiskyUser -Filter "riskLevel eq 'high'" |
    Select-Object UserDisplayName, UserPrincipalName, RiskLevel, RiskDetail
```

## Best Practices
1. **Report-only first** — Always deploy Conditional Access in report-only before enforcing
2. **Break-glass accounts** — Maintain 2+ emergency access accounts excluded from CA policies
3. **Named locations** — Define trusted networks to reduce MFA friction
4. **PIM over permanent** — Use eligible roles instead of permanent admin assignments
5. **Dynamic groups** — Use dynamic membership rules to automate group management
6. **App consent** — Restrict user app consent; require admin approval
7. **Access reviews** — Schedule quarterly reviews for privileged roles and guest access
8. **Naming convention** — Prefix: CA=Conditional Access, SG=Security Group, DG=Dynamic Group
9. **Sign-in monitoring** — Review risky sign-ins and failed MFA attempts daily
10. **Least privilege** — Use administrative units to scope admin roles
