# System Architecture — Platform Reference

## Overview

The platform is a multi-tenant, modular system. For ERP projects, it manages accounting, inventory, sales, HR, procurement, and manufacturing operations across multiple branches. The architecture patterns apply to any multi-tenant application.

## Architecture Style

**Modular Monolith** with API-first design, transitioning toward service-oriented architecture for high-scale modules.

```
┌─────────────────────────────────────────────────────┐
│                   Client Layer                       │
│    Web App (Vue/React)  │  Mobile App  │  API Clients│
└────────────────────────┬────────────────────────────┘
                         │ HTTPS/REST
┌────────────────────────┴────────────────────────────┐
│                   API Gateway                        │
│          (Nginx / Laravel Router)                    │
│    Rate Limiting │ Auth │ CORS │ Request Logging     │
└────────────────────────┬────────────────────────────┘
                         │
┌────────────────────────┴────────────────────────────┐
│               Application Layer                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │
│  │Accounting│ │Inventory │ │   Sales  │ │   HR   │ │
│  │ Module   │ │ Module   │ │  Module  │ │ Module │ │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └───┬────┘ │
│       │             │            │            │      │
│  ┌────┴─────────────┴────────────┴────────────┴───┐  │
│  │            Shared Services Layer                │  │
│  │  Auth │ Tenancy │ Audit │ Notifications │ Files │  │
│  └───────────────────────┬────────────────────────┘  │
└──────────────────────────┬───────────────────────────┘
                           │
┌──────────────────────────┴───────────────────────────┐
│                   Data Layer                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │PostgreSQL│  │  Redis   │  │   S3     │           │
│  │ (Primary)│  │(Cache/Q) │  │(Files)   │           │
│  └──────────┘  └──────────┘  └──────────┘           │
└──────────────────────────────────────────────────────┘
```

## Multi-Tenancy Model

**Shared database, shared schema** with `branch_id` column on every table.

```
companies (1) ──→ branches (many) ──→ users (many)
                                  ──→ invoices (many)
                                  ──→ products (many)
                                  ──→ ...all data tables
```

- Every query is automatically scoped to `branch_id` via global scope/middleware
- Users belong to one branch; admins can switch between branches
- Reports can aggregate across branches for company-level views
- Data isolation is enforced at the query level, not the database level

## Module Architecture

Each module follows this internal structure:

```
module/
├── Models/          — Eloquent models with relationships and scopes
├── Services/        — Business logic (one service per domain concept)
├── Controllers/     — Thin API controllers (delegate to services)
├── Requests/        — Form request validation
├── Resources/       — API response transformers
├── Policies/        — Authorization rules
├── Events/          — Domain events for audit and notifications
├── Listeners/       — Event handlers
├── Jobs/            — Background processing
└── Tests/           — Unit and feature tests
```

## API Design

- **Base URL**: `/api/v1/`
- **Auth**: Bearer token (Laravel Sanctum)
- **Format**: JSON
- **Response envelope**: `{ "data": {}, "meta": {}, "links": {} }`
- **Errors**: `{ "message": "", "errors": {} }` with appropriate HTTP status
- **Pagination**: Cursor-based for lists, `?per_page=25&cursor=...`

## Infrastructure

- **Compute**: Docker containers on AWS ECS or VPS with Docker Compose
- **Database**: PostgreSQL (primary), Redis (cache/queue)
- **Storage**: S3 for file uploads, local for temporary files
- **CDN**: CloudFront or Cloudflare for static assets
- **CI/CD**: GitHub Actions → Docker build → Deploy
- **Monitoring**: Prometheus + Grafana (or CloudWatch)

## Security Architecture

- **Authentication**: Laravel Sanctum (API tokens + SPA cookies)
- **Authorization**: RBAC via Laravel Policies + Spatie Permissions
- **Encryption**: AES-256 at rest, TLS 1.2+ in transit
- **Secrets**: Environment variables, AWS Secrets Manager
- **Audit**: Every data change logged with user, timestamp, before/after values
