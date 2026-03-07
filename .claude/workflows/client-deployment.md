# Client Deployment Workflow

## Overview
Workflow for deploying the platform to a new client tenant or updating an existing client's deployment.

## Trigger
- New client onboarding
- Existing client requesting update
- Multi-branch setup for a client
- Command: `/deploy-staging` or `/deploy-production`

## Workflow Diagram
```
[Request]──→[Setup Tenant]──→[Configure]──→[Data Import]──→[Deploy]──→[Verify]──→[Handoff]
     │            │               │              │             │          │           │
   User       Support          Backend        Support       DevOps    Monitoring   Support
              Agent            Engineer        Agent        Engineer    Agent       Agent
```

## Phases

### Phase 1: Client Requirements
**Agent**: support-agent + product-manager
**Actions**:
1. Gather client requirements:
   - Company name and branches
   - Required modules
   - User count and roles
   - Data migration needs (from existing system)
   - Integration requirements
   - Customization needs
2. Create deployment checklist
**Output**: Client deployment specification

### Phase 2: Tenant Setup
**Agent**: backend-engineer + database-engineer
**Actions**:
1. Create new branch/tenant in the system
2. Configure database schema (if separate DB per tenant)
3. Set up tenant-specific configuration:
   - Company details (name, address, logo, tax IDs)
   - Currency and locale settings
   - Financial year configuration
   - Invoice/document numbering sequences
4. Enable required modules
**Output**: Tenant created and configured

### Phase 3: User & Role Setup
**Agent**: support-agent
**Actions**:
1. Create admin user for the client
2. Configure roles based on client's organizational structure:
   - Admin, Manager, Accountant, Sales, HR, Warehouse, etc.
3. Set up role permissions per module
4. Generate temporary passwords
5. Configure MFA requirements
**Output**: Users and roles configured

### Phase 4: Data Import
**Agent**: support-agent + database-engineer
**Actions**:
1. Import master data:
   - Chart of accounts
   - Product/service catalog
   - Customer and vendor lists
   - Employee records
   - Opening balances
2. Validate imported data:
   - Check referential integrity
   - Verify totals match source
   - Confirm no duplicate records
3. Generate import report
**Output**: Data imported and validated

### Phase 5: Deployment
**Agent**: devops-engineer
**Actions**:
1. Deploy application to client's environment
2. Configure domain and SSL
3. Set up email integration (SMTP, notifications)
4. Configure backup schedule
5. Set up monitoring for the tenant
**Output**: Application deployed and accessible

### Phase 6: Verification
**Agent**: qa-agent + monitoring-agent
**Actions**:
1. Run smoke tests on the deployed instance
2. Verify all enabled modules are accessible
3. Test key workflows:
   - Login and authentication
   - Create and approve an invoice
   - Generate a financial report
   - Process a stock movement
4. Verify email notifications working
5. Confirm backup is running
**Output**: Deployment verified and healthy

### Phase 7: Client Handoff
**Agent**: support-agent + documentation-agent
**Actions**:
1. Prepare client documentation:
   - Login credentials (secure delivery)
   - Getting started guide
   - Module-specific user guides
   - Support contact information
2. Schedule onboarding session
3. Create support ticket for follow-up
**Output**: Client onboarded with documentation

## Multi-Branch Deployment

For clients with multiple branches:
1. Create the parent company/tenant
2. For each branch:
   - Create branch entity
   - Configure branch-specific settings (address, tax, currency)
   - Assign branch managers
   - Import branch-specific data
3. Verify inter-branch isolation
4. Test consolidated reporting across branches

## Rollback

If deployment fails or client requests rollback:
1. Deactivate the tenant (don't delete)
2. Preserve all data for potential re-activation
3. Document the reason for rollback
4. Create action items for resolution
