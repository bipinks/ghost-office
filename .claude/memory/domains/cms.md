# Domain Knowledge — Content Management System (CMS)

> **Domain**: Content Management System
> Auto-loaded via `domain.lock` or `/set-domain cms`

## Core Business Concepts

### Content Model
- Structured content types (articles, pages, products, events)
- Rich text editing with media embedding
- Content relationships (tags, categories, related content)
- Content versioning with draft/publish workflow
- Localization and multi-language support

### Editorial Workflow
- Draft -> Review -> Approved -> Published -> Archived
- Role-based publishing permissions
- Scheduled publishing (future date/time)
- Content expiration and auto-archive
- Editorial calendar for planning

### Multi-Site / Multi-Tenant
- Single platform serving multiple websites/brands
- Shared content library with site-specific overrides
- Per-site themes, domains, and configurations
- Cross-site content syndication

---

## Modules

### 1. Content Authoring
**Entities**: Content, ContentType, Field, Revision, MediaAsset
**Key Rules**:
- Block-based editor (Gutenberg-style or structured fields)
- Custom content types with configurable fields
- Media library with image optimization (auto-resize, WebP)
- Content templates for consistent structure
- Auto-save and revision history
- Inline editing and live preview

### 2. Taxonomy & Organization
**Entities**: Category, Tag, Collection, Menu, Navigation
**Key Rules**:
- Hierarchical categories (unlimited depth)
- Flat tags for cross-cutting topics
- Custom taxonomies per content type
- Menu builder with drag-and-drop ordering
- Breadcrumb generation from taxonomy

### 3. Page Builder
**Entities**: Page, Section, Component, Layout, Theme
**Key Rules**:
- Visual drag-and-drop page composition
- Reusable component library (hero, carousel, CTA, grid)
- Responsive preview (desktop, tablet, mobile)
- Theme system with template hierarchy
- Custom CSS/JS injection per page

### 4. Search & Discovery
**Entities**: SearchIndex, SearchQuery, Facet, Synonym
**Key Rules**:
- Full-text search with relevance ranking
- Faceted filtering (by type, date, category, author)
- Search suggestions and autocomplete
- Synonym management for improved recall
- Search analytics (popular queries, zero-result queries)

### 5. User & Access Management
**Entities**: User, Role, Permission, Workflow, AuditEntry
**Key Rules**:
- Roles: super admin, editor, author, contributor, viewer
- Content-level permissions (per type, per item)
- Workflow assignments (reviewer per content type)
- External auth (SSO, LDAP, OAuth)
- Activity log for all content changes

---

## Cross-Cutting Concerns

### SEO
- SEO-friendly URLs (customizable slugs)
- Meta title, description, Open Graph, Twitter Cards per page
- Canonical URLs and hreflang for multi-language
- XML sitemap generation (auto-updated)
- Robots.txt management
- Structured data (JSON-LD) for articles, FAQs, events
- Core Web Vitals optimization

### Performance
- Static site generation (SSG) or ISR for published content
- CDN delivery for all assets and pages
- Image optimization pipeline (resize, compress, convert to WebP)
- Lazy loading for below-fold content
- Edge caching with cache purge on publish

### API & Headless
- REST and/or GraphQL content delivery API
- Preview API for draft content (authenticated)
- Webhook triggers on content events (publish, update, delete)
- SDK/client libraries for frontend frameworks
- Rate limiting per API key/tenant

### Localization
- Content translation workflow (per-field translation)
- Language fallback chain (en-GB -> en -> default)
- RTL language support
- Date, number, currency formatting per locale
- URL strategy: subdomain, path prefix, or separate domain
