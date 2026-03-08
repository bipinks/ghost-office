---
name: seo-optimization
description: Use when performing keyword research, optimizing on-page SEO, implementing technical SEO (schema markup, crawling, indexing, site speed), building internal linking strategies, conducting SEO audits, improving Core Web Vitals, analyzing Search Console data, or planning link building campaigns. Covers on-page, off-page, technical, and local SEO.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# SEO Optimization -- Technical, On-Page & Off-Page

## 1. Keyword Research

**Process**: Seed keywords -> Expand with volume/difficulty/intent -> Prioritize -> Map to content.

**Priority formula**: `(Search Volume x Business Relevance) / (Difficulty + 1)`

Business relevance: 5 = core product, 4 = key use case, 3 = industry, 2 = tangential, 1 = broad.

**Intent classification**:
- **Informational**: "how to", "guide" -> Blog posts, docs
- **Navigational**: Brand/product names, "login" -> Homepage, product pages
- **Commercial**: "best", "vs", "review" -> Comparison pages, case studies
- **Transactional**: "buy", "pricing", "demo" -> Pricing, signup, product pages

**Rules**: One primary keyword per page (avoid cannibalization). 2-5 secondary keywords. Map each to existing or new page, content type, and funnel stage.

---

## 2. On-Page SEO

**Title tags**: 50-60 chars. Primary keyword near front. Structure: `Primary Keyword -- Context | Brand`.

**Meta descriptions**: 150-160 chars. Summarize value + keyword + soft CTA. Unique per page.

**Heading hierarchy**: One H1 per page with primary keyword. H2s for major sections with secondary keywords. Never skip levels. Use for semantics, not styling.

**Internal linking**: 2-3+ links per page. Descriptive anchor text (never "click here"). Hub-and-spoke for pillar/cluster. Update existing content to link to new pages. Audit quarterly for orphans and broken links.

**Content checklist**:
- [ ] Primary keyword in title, H1, first 100 words, URL, meta description
- [ ] Answers search intent completely; more comprehensive than competitors
- [ ] Images: descriptive alt text, WebP format, compressed, descriptive filenames
- [ ] Scannable: headings, bullets, short paragraphs, ToC for 2000+ words
- [ ] Fast load (< 2.5s LCP), no intrusive interstitials

---

## 3. Technical SEO

### Crawling & Indexing

**robots.txt**: Block admin, API, internal tools, duplicate-creating params. Never block CSS/JS. Reference sitemap.

**XML sitemap**: All indexable pages, exclude noindex/redirects/404s. Accurate lastmod. Max 50K URLs per file. Submit to Search Console.

**Indexing directives** (meta robots or X-Robots-Tag):
- `noindex, follow`: Thank-you pages, internal search, tag/filter duplicates, staging, login pages
- Self-referencing canonical on every page. Canonical must be absolute URL returning 200.

### Core Web Vitals

| Metric | Good | Fix Strategy |
|--------|------|-------------|
| LCP | < 2.5s | Preload LCP resource, CDN, remove render-blocking, TTFB < 200ms |
| INP | < 200ms | Break long tasks (> 50ms), defer JS, use web workers, debounce handlers |
| CLS | < 0.1 | Explicit image/video dimensions, reserve ad space, font-display: swap |

### Site Speed Checklist

- HTTP/2+, CDN, Gzip/Brotli, cache headers, TTFB < 200ms
- Minify CSS/JS, remove unused code, defer non-critical JS, code-split by route
- WebP/AVIF images, responsive srcset, lazy-load below fold
- Self-host fonts, font-display: swap, preload critical fonts, limit weights

### Schema Markup (JSON-LD)

Key types: Organization, Article, FAQPage, HowTo, BreadcrumbList, SoftwareApplication, LocalBusiness.

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Guide Title",
  "author": { "@type": "Person", "name": "Author" },
  "publisher": { "@type": "Organization", "name": "Brand", "logo": { "@type": "ImageObject", "url": "https://example.com/logo.png" } },
  "datePublished": "2026-01-15",
  "dateModified": "2026-03-01"
}
```

Validate with Google Rich Results Test and Schema Markup Validator.

---

## 4. Off-Page SEO

### Link Building (ethical, sustainable)

| Strategy | Approach |
|----------|----------|
| Content-driven | Original research, comprehensive guides, free tools, infographics |
| Relationship | Guest posts, podcast appearances, expert roundups, partner co-marketing |
| Digital PR | Press releases, HARO responses, industry awards, expert commentary |
| Community | Forum answers, open-source contributions, event sponsorship |

**Never**: Buy links, use PBNs, spam comments, link exchange schemes, automated tools.

**Prospect evaluation**: DA > 30 (prefer > 50), topically relevant, real traffic, editorial standards. Personalize outreach, reference specific content, offer genuine value. Follow up once after 5-7 days.

---

## 5. Local SEO

**Google Business Profile**: Accurate NAP, correct categories, description with keywords, photos, weekly posts, respond to all reviews.

**Local citations**: Consistent NAP across all directories (Yelp, BBB, Apple Maps, Bing Places).

**Local content**: Location-specific landing pages with LocalBusiness schema. Local case studies, events, partnerships.

---

## 6. SEO Audit Checklist

**Technical**: robots.txt not blocking important pages, valid sitemap submitted, no orphan pages, no crawl traps, no 404s on important pages, 301 redirects for moved content, no redirect chains/loops, HTTPS everywhere with HSTS, no mixed content, canonical tags on all pages, consistent www/trailing slash, mobile-friendly, CWV passing, TTFB < 200ms.

**Content** (per page): Primary keyword mapped (no cannibalization), present in title/H1/URL/first paragraph, intent matched, more comprehensive than top-3 competitors, current info, heading hierarchy correct, 2-3+ internal links, images optimized, schema where applicable.

**Scoring**: 8-10 maintain, 5-7 update/optimize, 1-4 rewrite/consolidate/redirect.

---

## 7. Search Console Analysis

**Weekly**: Performance (impressions, clicks, CTR, position), coverage errors, CWV regressions, manual actions.

**Monthly**: Top queries (new rankings, drops), top pages performance, low-CTR pages (improve title/meta), significant position changes.

**Quarterly**: Keyword gaps (top 10 misses), cannibalization, high-impression/low-click opportunities, full technical crawl.

**Low-CTR optimization**: Position 1-3 with CTR < 5% -> title not compelling, meta needs work, missing rich snippets. Position 4-10 with CTR < 2% -> improve ranking first, differentiate title.

---

## 8. SEO Content Brief Template

```markdown
## Target keyword
- **Primary**: [keyword] (volume, difficulty)
- **Secondary**: [2-3 keywords]
- **Search intent**: Informational / Commercial / Transactional
- **User goal**: [What searcher wants]

## SERP analysis
- Featured snippet: [Yes/No, format]
- People Also Ask: [Top 4-5 questions]
- Top 3 results: [Title, word count, strengths, gaps]

## Content requirements
- Title tag (50-60 chars), meta description (150-160 chars), H1 with keyword
- Word count range, format (guide/list/comparison/how-to)
- Internal links TO and FROM existing pages
- Schema type: Article / HowTo / FAQ / None

## Success criteria
- Top 10 within 90 days, [N] organic sessions/month within 6 months
```

---

## 9. Maintenance Schedule

**Weekly**: Search Console errors, CWV monitoring, keyword ranking changes, publish per calendar.
**Monthly**: Full GSC analysis, refresh 2-3 underperforming pages, internal link audit, competitor comparison, backlink review.
**Quarterly**: Full technical audit, content gap analysis, keyword map update, schema validation, site architecture review.
**Annually**: Comprehensive strategy review, fresh keyword research, full content audit, competitive landscape analysis.
