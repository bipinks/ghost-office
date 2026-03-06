---
name: ms365-provision
description: Provision and configure Microsoft 365 users, licenses, and services
argument-hint: "[user email or bulk CSV path]"
disable-model-invocation: true
---

# /ms365-provision — Microsoft 365 Provisioning

Provision Microsoft 365 for $ARGUMENTS using the **ms365-admin** skill:

1. Create user accounts (single or bulk from CSV)
2. Assign licenses (E3, E5, Business Basic, etc.)
3. Configure Teams and channels
4. Set up SharePoint sites
5. Send emails (via MCP `send-shared-mailbox-mail`)
6. Apply security policies (Conditional Access, MFA)
7. Generate onboarding documentation

## Usage
```
/ms365-provision "new user john@company.com with E3 license"
/ms365-provision "bulk import from users.csv"
/ms365-provision "create Engineering team with channels"
/ms365-provision "set up conditional access for MFA"
/ms365-provision "send test email to user@example.com"
```
