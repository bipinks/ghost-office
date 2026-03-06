---
name: exchange-online-admin
description: Use when managing Exchange Online. Covers mailbox provisioning, shared/room mailboxes, mail flow rules, transport policies, anti-spam/phishing configuration, DLP policies, retention policies, and quarantine management.
user-invocable: true
disable-model-invocation: true
context: fork
allowed-tools: ["Read", "Write", "Bash"]
argument-hint: "email admin action (e.g., create shared mailbox, configure mail flow rule)"
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "#!/bin/bash\nif [ -z \"$AZURE_CLIENT_ID\" ] && [ -z \"$MS_GRAPH_TOKEN\" ]; then\n  echo '❌ [Hook] Exchange Online credentials not configured. Set AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID.' >&2\n  exit 1\nfi\nif [ -n \"$AZURE_CLIENT_ID\" ] && [ -n \"$AZURE_CLIENT_SECRET\" ] && [ -n \"$AZURE_TENANT_ID\" ]; then\n  export ACCESS_TOKEN=$(node scripts/ms365.mjs token 2>/dev/null)\n  export MS_GRAPH_TOKEN=\"$ACCESS_TOKEN\"\nfi"
---

# Exchange Online Administration

## Overview
Exchange Online mailbox management, mail flow rules, anti-spam/phishing, DLP, and retention policies using Microsoft Graph API and Exchange Online PowerShell.

## Mailbox Management

### Create Shared Mailbox
```powershell
Connect-ExchangeOnline

# Create shared mailbox
New-Mailbox -Shared -Name "Support Team" -DisplayName "Support Team" `
    -Alias "support" -PrimarySmtpAddress "support@contoso.com"

# Grant full access
Add-MailboxPermission -Identity "support@contoso.com" `
    -User "admin@contoso.com" -AccessRights FullAccess -AutoMapping $true

# Grant send-as permission
Add-RecipientPermission -Identity "support@contoso.com" `
    -Trustee "admin@contoso.com" -AccessRights SendAs -Confirm:$false
```

### Create Room Mailbox
```powershell
New-Mailbox -Room -Name "Board Room" -DisplayName "Board Room - Floor 3" `
    -Alias "boardroom" -PrimarySmtpAddress "boardroom@contoso.com"

# Configure room settings
Set-CalendarProcessing -Identity "boardroom@contoso.com" `
    -AutomateProcessing AutoAccept `
    -AddOrganizerToSubject $true `
    -DeleteComments $false `
    -DeleteSubject $false `
    -AllowConflicts $false `
    -BookingWindowInDays 180 `
    -MaximumDurationInMinutes 480
```

### Mailbox via Graph API
```bash
# Get mailbox settings
curl -s https://graph.microsoft.com/v1.0/users/user@contoso.com/mailboxSettings \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# Update automatic replies (out of office)
curl -X PATCH https://graph.microsoft.com/v1.0/users/user@contoso.com/mailboxSettings \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "automaticRepliesSetting": {
      "status": "scheduled",
      "scheduledStartDateTime": {
        "dateTime": "2026-03-10T08:00:00",
        "timeZone": "UTC"
      },
      "scheduledEndDateTime": {
        "dateTime": "2026-03-15T17:00:00",
        "timeZone": "UTC"
      },
      "internalReplyMessage": "I am currently out of office.",
      "externalReplyMessage": "I am out of office. For urgent matters, contact support@contoso.com."
    }
  }'
```

## Mail Flow Rules

### Disclaimer / Email Footer
```powershell
New-TransportRule -Name "Company Disclaimer" `
    -FromScope InOrganization `
    -ApplyHtmlDisclaimerLocation Append `
    -ApplyHtmlDisclaimerText @"
<div style="font-size:11px;color:#666;">
<p>CONFIDENTIAL: This email is intended only for the named recipient(s).
If received in error, please notify the sender and delete immediately.</p>
</div>
"@ `
    -ApplyHtmlDisclaimerFallbackAction Wrap
```

### Block External Auto-Forwarding
```powershell
New-TransportRule -Name "Block External Auto-Forward" `
    -FromScope InOrganization `
    -MessageTypeMatches AutoForward `
    -SentToScope NotInOrganization `
    -RejectMessageReasonText "External email forwarding is not permitted." `
    -Priority 0
```

### Route Emails by Subject
```powershell
New-TransportRule -Name "Route Support Emails" `
    -SubjectContainsWords @("support request", "help needed", "urgent issue") `
    -RedirectMessageTo "support@contoso.com" `
    -SetSCL -1
```

## Anti-Spam & Anti-Phishing

### Anti-Phishing Policy
```powershell
Connect-IPPSSession

# Create anti-phishing policy
New-AntiPhishPolicy -Name "Strict Anti-Phishing" `
    -EnableMailboxIntelligenceProtection $true `
    -EnableOrganizationDomainsProtection $true `
    -EnableSimilarUsersSafetyTips $true `
    -EnableSimilarDomainsSafetyTips $true `
    -EnableUnusualCharactersSafetyTips $true `
    -PhishThresholdLevel 3 `
    -TargetedUserProtectionAction Quarantine `
    -TargetedDomainProtectionAction Quarantine `
    -MailboxIntelligenceProtectionAction Quarantine

# Create anti-phishing rule
New-AntiPhishRule -Name "Strict Anti-Phishing Rule" `
    -AntiPhishPolicy "Strict Anti-Phishing" `
    -RecipientDomainIs "contoso.com" `
    -Priority 0
```

### Safe Attachments Policy
```powershell
New-SafeAttachmentPolicy -Name "Block Malicious Attachments" `
    -Action Block `
    -Enable $true `
    -ActionOnError $true `
    -Redirect $true `
    -RedirectAddress "secops@contoso.com"

New-SafeAttachmentRule -Name "Block Malicious Attachments Rule" `
    -SafeAttachmentPolicy "Block Malicious Attachments" `
    -RecipientDomainIs "contoso.com"
```

## Data Loss Prevention (DLP)

### Prevent External Sharing of Sensitive Data
```powershell
# Create DLP policy for credit card numbers
New-DlpCompliancePolicy -Name "Financial Data Protection" `
    -ExchangeLocation All `
    -SharePointLocation All `
    -OneDriveLocation All `
    -TeamsLocation All `
    -Mode Enable

New-DlpComplianceRule -Name "Block Credit Card External" `
    -Policy "Financial Data Protection" `
    -ContentContainsSensitiveInformation @(
        @{Name="Credit Card Number"; minCount="1"}
    ) `
    -BlockAccess $true `
    -BlockAccessScope NotInOrganization `
    -NotifyUser "SiteAdmin","LastModifier" `
    -GenerateAlert "SiteAdmin"
```

## Retention Policies

### Email Retention
```powershell
# Create retention policy
New-RetentionCompliancePolicy -Name "Email Retention - 7 Years" `
    -ExchangeLocation All `
    -Enabled $true

New-RetentionComplianceRule -Name "Retain 7 Years" `
    -Policy "Email Retention - 7 Years" `
    -RetentionDuration 2555 `
    -RetentionComplianceAction KeepAndDelete `
    -RetentionDurationDisplayHint Days
```

### Litigation Hold
```powershell
# Place user on litigation hold
Set-Mailbox -Identity "user@contoso.com" `
    -LitigationHoldEnabled $true `
    -LitigationHoldDuration 365 `
    -LitigationHoldOwner "legal@contoso.com" `
    -RetentionComment "Legal hold - Case #12345"
```

## Distribution Lists & Groups

### Create Distribution List
```powershell
New-DistributionGroup -Name "All Engineering" `
    -DisplayName "All Engineering" `
    -Alias "all-engineering" `
    -PrimarySmtpAddress "all-engineering@contoso.com" `
    -Type Distribution `
    -MemberDepartRestriction Closed `
    -MemberJoinRestriction ApprovalRequired

# Add members
Add-DistributionGroupMember -Identity "all-engineering" -Member "user1@contoso.com"

# Allow external senders (if needed)
Set-DistributionGroup -Identity "all-engineering" -RequireSenderAuthenticationEnabled $false
```

## Quarantine Management

### Review and Release
```powershell
# View quarantined messages
Get-QuarantineMessage -StartReceivedDate (Get-Date).AddDays(-7) |
    Select-Object Subject, SenderAddress, RecipientAddress, QuarantineTypes,
    ReleaseStatus, ReceivedTime | Format-Table -AutoSize

# Release message from quarantine
Release-QuarantineMessage -Identity $messageId -ReleaseToAll

# Preview quarantined message
Preview-QuarantineMessage -Identity $messageId
```

## Reporting

### Mailbox Statistics
```powershell
# Mailbox sizes
Get-EXOMailbox -ResultSize Unlimited | Get-EXOMailboxStatistics |
    Sort-Object TotalItemSize -Descending |
    Select-Object DisplayName, TotalItemSize, ItemCount -First 20

# Inactive mailboxes
Get-Mailbox -InactiveMailboxOnly | Select-Object DisplayName, WhenSoftDeleted

# Mail flow summary
Get-MailFlowStatusReport -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)
```

## Best Practices
1. **Shared mailboxes over distribution lists** — For teams that need to manage replies
2. **Transport rules carefully** — Test with audit mode before enforcing
3. **Anti-phishing baseline** — Enable impersonation protection for executives
4. **DLP incrementally** — Start with audit mode, review false positives, then enforce
5. **Retention first** — Define retention policies before users accumulate data
6. **Block auto-forwarding** — Prevent data exfiltration via external forwarding rules
7. **DKIM/DMARC/SPF** — Configure all three for email authentication
8. **Naming convention** — Prefix: DL=Distribution List, SM=Shared Mailbox, RM=Room Mailbox
9. **Regular audits** — Review mailbox permissions and forwarding rules monthly
10. **Quarantine review** — Assign quarantine reviewers; don't let messages pile up
