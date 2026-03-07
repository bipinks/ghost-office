# Domain Knowledge — SaaS (Software as a Service)

> **Domain**: SaaS Platform
> Auto-loaded via `domain.lock` or `/set-domain saas`

## Core Business Concepts

### Subscription Model
- Free tier, trial periods, paid plans
- Monthly and annual billing cycles (annual = discount)
- Per-seat, per-usage, or flat-rate pricing
- Plan upgrades/downgrades with prorated billing
- Dunning management (failed payment retry)

### Multi-Tenancy
- Tenant isolation at the application layer
- Shared database with `tenant_id` / `organization_id` scoping
- Tenant-specific configuration and branding
- Data export for tenant portability
- Tenant lifecycle: trial -> active -> suspended -> churned -> deleted

### User Management
- Organization-level accounts with team members
- Role-based access: owner, admin, member, viewer
- SSO integration (SAML, OIDC)
- Invitation flow with email verification
- API key management per organization

---

## Modules

### 1. Authentication & Identity
**Entities**: User, Organization, Team, Invitation, Session, ApiKey
**Key Rules**:
- Email + password with MFA (TOTP, SMS)
- Social login (Google, GitHub, Microsoft)
- SSO/SAML for enterprise plans
- Session management with device tracking
- Password policies (min length, complexity, rotation)
- Account lockout after failed attempts

### 2. Billing & Subscriptions
**Entities**: Plan, Subscription, Invoice, PaymentMethod, Usage
**Key Rules**:
- Stripe/Paddle integration for subscription management
- Metered billing: track usage, bill at period end
- Plan limits enforced in middleware (API calls, storage, seats)
- Trial expiration with grace period
- Revenue recognition (MRR, ARR calculations)
- Tax handling via Stripe Tax or tax provider

### 3. Feature Flags & Entitlements
**Entities**: Feature, Entitlement, PlanFeature, Override
**Key Rules**:
- Features gated by plan tier
- Gradual rollout with percentage-based flags
- Per-tenant overrides for custom deals
- Usage limits per feature (e.g., 1000 API calls/month)
- Graceful degradation when limits exceeded

### 4. Notifications & Communication
**Entities**: Notification, EmailTemplate, Webhook, EventLog
**Key Rules**:
- In-app notifications (bell icon, real-time via WebSocket)
- Email notifications (transactional + marketing)
- Webhook delivery with retry and dead-letter queue
- Notification preferences per user (opt-in/opt-out)
- Activity feed per organization

### 5. Admin & Operations
**Entities**: AdminUser, AuditLog, SystemConfig, FeatureFlag
**Key Rules**:
- Internal admin dashboard (separate from tenant UI)
- Tenant impersonation for support debugging
- System-wide feature flags for rollouts
- Health monitoring and usage dashboards
- Data export and deletion for compliance

---

## Cross-Cutting Concerns

### Onboarding
- Guided setup wizard (progressive disclosure)
- Sample data / templates for quick start
- In-app tours and contextual help
- Activation metrics: time-to-value, setup completion rate

### Analytics & Metrics
- **Business**: MRR, ARR, churn rate, LTV, CAC
- **Product**: DAU/MAU, feature adoption, retention cohorts
- **Technical**: API latency, error rates, uptime SLA

### Security & Compliance
- SOC 2 Type II compliance
- GDPR: data processing agreements, right to erasure, data export
- Encryption at rest and in transit
- Audit logging for all admin and data access
- Penetration testing (annual)
- Vulnerability disclosure program

### Scalability Patterns
- Horizontal scaling behind load balancer
- Database read replicas for analytics queries
- Background job queues for async operations
- CDN for static assets and API caching
- Rate limiting per tenant (prevent noisy neighbor)
