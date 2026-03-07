---
name: documentation-standards
description: Use when writing or updating technical documentation for the platform. Covers API docs, Architecture Decision Records, user guides, changelogs, README patterns, and knowledge base maintenance.
user-invocable: false
allowed-tools: ["Read", "Write", "Grep", "Glob"]
---

# Documentation Standards — ERP Platform

## API Documentation Pattern

Document every endpoint with this structure:

```markdown
### Create Invoice

`POST /api/v1/invoices`

**Description**: Create a new sales invoice with line items.

**Authentication**: Bearer token required

**Request Body**:
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| customer_id | integer | Yes | Customer ID |
| date | string (YYYY-MM-DD) | Yes | Invoice date |
| due_date | string (YYYY-MM-DD) | Yes | Payment due date |
| notes | string | No | Additional notes |
| items | array | Yes | Line items (min 1) |
| items[].product_id | integer | Yes | Product ID |
| items[].quantity | number | Yes | Quantity (> 0) |
| items[].price | number | Yes | Unit price (>= 0) |

**Response** (201 Created):
```json
{
  "data": {
    "id": 42,
    "invoice_number": "INV-DXB-2026-00042",
    "customer_id": 15,
    "date": "2026-03-06",
    "due_date": "2026-04-05",
    "status": "draft",
    "subtotal": 1500.00,
    "tax": 75.00,
    "total": 1575.00,
    "items": [...]
  }
}
```

**Error Responses**:
- `422 Unprocessable Entity` — Validation errors
- `403 Forbidden` — Insufficient permissions
- `404 Not Found` — Customer not found
```

## Architecture Decision Record (ADR)

```markdown
# ADR-{NNN}: {Title}

**Date**: YYYY-MM-DD
**Status**: Proposed | Accepted | Deprecated | Superseded by ADR-XXX
**Deciders**: {agent or team}

## Context
{What is the issue? Why do we need to decide?}

## Decision
{What is the change we are making?}

## Consequences

### Positive
- {Benefit 1}
- {Benefit 2}

### Negative
- {Trade-off 1}
- {Risk 1}

### Neutral
- {Observation}

## Alternatives Considered
1. **{Alternative A}** — Rejected because {reason}
2. **{Alternative B}** — Rejected because {reason}
```

## Changelog Format

Follow [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

## [Unreleased]

### Added
- Invoice PDF generation with company letterhead (#123)
- Bulk payment processing for multiple invoices (#145)

### Changed
- Improved inventory search performance with composite index (#156)

### Fixed
- Tax calculation for exempt items now correctly returns 0 (#167)
- Stock level display rounding error on dashboard (#172)

### Security
- Upgraded Laravel to 11.5 to patch CVE-2026-XXXX (#180)

## [2.4.0] - 2026-03-01

### Added
- Multi-currency support for sales invoices (#110)
```

## Module Documentation

Every ERP module should have a README:

```markdown
# {Module Name} Module

## Overview
{1-2 sentence description of the module's purpose}

## Entities
| Entity | Table | Description |
|--------|-------|-------------|
| Invoice | invoices | Sales invoices with line items |
| Payment | payments | Payments linked to invoices |

## API Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/v1/invoices | List invoices (paginated) |
| POST | /api/v1/invoices | Create invoice |
| GET | /api/v1/invoices/{id} | Get invoice details |
| PUT | /api/v1/invoices/{id} | Update invoice |
| DELETE | /api/v1/invoices/{id} | Soft-delete invoice |

## Business Rules
1. Invoices require at least one line item
2. Due date must be after invoice date
3. Only draft invoices can be edited
4. Cancellation creates a credit note

## Events
| Event | Trigger | Listeners |
|-------|---------|-----------|
| InvoiceCreated | New invoice saved | UpdateLedger, SendNotification |
| InvoiceApproved | Status → approved | ReserveStock, NotifyCustomer |
| PaymentReceived | Payment recorded | UpdateInvoiceStatus, UpdateLedger |

## Permissions
| Permission | Roles |
|------------|-------|
| invoices.view | All authenticated |
| invoices.create | Sales, Manager, Admin |
| invoices.approve | Manager, Admin |
| invoices.delete | Admin |
```

## User Guide Pattern

```markdown
# How to Create an Invoice

## Prerequisites
- You must have the **Sales** or **Manager** role
- At least one customer must exist in the system
- Products must be set up in the Inventory module

## Steps

1. Navigate to **Sales → Invoices**
2. Click **+ New Invoice**
3. Select the **Customer** from the dropdown
4. Set the **Invoice Date** and **Due Date**
5. Add line items:
   - Search for a product
   - Enter the quantity
   - Verify the unit price (auto-filled from product)
   - Click **Add Item**
6. Review the totals (subtotal, tax, total)
7. Click **Save as Draft** or **Save & Approve**

## Notes
- Draft invoices can be edited freely
- Approved invoices lock stock reservations
- Use **Credit Notes** for post-approval adjustments
```

## Knowledge Base Maintenance

### Rules for `.claude/memory/` Files

1. **Single source of truth** — Each topic has one authoritative file
2. **Keep current** — Update after every architectural change
3. **Concise** — Max 300 lines per file; link to detailed docs
4. **Structured** — Use headings, tables, and code blocks
5. **Cross-reference** — Use `@.claude/memory/file.md` imports

### When to Update Memory Files

| Event | Update |
|-------|--------|
| New module added | `architecture.md`, `domain-knowledge.md` |
| API change | `architecture.md` |
| New coding pattern | `coding-standards.md` |
| Deployment change | `deployment-standards.md` |
| New runbook procedure | `devops-runbook.md` |
| Performance target change | `performance-guidelines.md` |

## Writing Style

- **Active voice**: "The system creates a journal entry" not "A journal entry is created"
- **Present tense**: "This endpoint returns" not "This endpoint will return"
- **Specific**: "Returns 422 with validation errors" not "Returns an error"
- **Consistent terms**: Use the same word for the same concept throughout
- **No jargon without definition**: Define terms on first use
- **Code examples**: Include working examples for every API endpoint and pattern
