---
name: seo-optimization
description: Use when performing keyword research, optimizing on-page SEO, implementing technical SEO (schema markup, crawling, indexing, site speed), building internal linking strategies, conducting SEO audits, improving Core Web Vitals, analyzing Search Console data, or planning link building campaigns. Covers on-page, off-page, technical, and local SEO.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# SEO Optimization — Technical, On-Page & Off-Page

## 1. Keyword Research

### Keyword Research Process

```
KEYWORD RESEARCH WORKFLOW
===========================

STEP 1: SEED KEYWORDS
  - List core topics your product/business covers
  - Pull questions from customer support tickets and sales calls
  - Extract terms from competitor content
  - Use Google autocomplete and "People also ask" for variations

STEP 2: EXPAND AND CLASSIFY
  For each seed keyword, gather:
  - Search volume (monthly average)
  - Keyword difficulty (0-100 scale)
  - Search intent (informational, navigational, commercial, transactional)
  - CPC (indicates commercial value)
  - SERP features present (featured snippet, video, local pack, etc.)

STEP 3: PRIORITIZE
  Score keywords using this formula:
  Priority = (Search Volume x Business Relevance) / (Difficulty + 1)

  Business relevance scale (1-5):
    5 = Directly describes our product or core feature
    4 = Closely related to a key use case
    3 = Related to our industry/domain
    2 = Tangentially relevant
    1 = Broad/informational with weak product connection

STEP 4: MAP TO CONTENT
  Assign each keyword to:
  - An existing page (optimize) or a new page (create)
  - A content type (blog, landing page, docs, pillar)
  - A funnel stage (awareness, consideration, decision)
```

### Keyword Intent Classification

```
SEARCH INTENT MAPPING
=======================

INFORMATIONAL (user wants to learn)
  Signals: "what is," "how to," "guide," "tutorial," "why"
  Content: Blog posts, guides, documentation, videos
  Examples:
    "what is inventory management"
    "how to do bank reconciliation"
    "payroll processing steps"

NAVIGATIONAL (user wants to find a specific thing)
  Signals: Brand names, product names, "login," "docs"
  Content: Homepage, product pages, documentation, login
  Examples:
    "[product name] login"
    "[product name] pricing"
    "[product name] API docs"

COMMERCIAL INVESTIGATION (user is comparing options)
  Signals: "best," "vs," "review," "comparison," "alternative"
  Content: Comparison pages, reviews, feature pages, case studies
  Examples:
    "best ERP software for small business"
    "[product] vs [competitor]"
    "inventory management software reviews"

TRANSACTIONAL (user wants to take action)
  Signals: "buy," "pricing," "free trial," "demo," "sign up"
  Content: Pricing page, sign-up page, demo booking, product page
  Examples:
    "ERP software pricing"
    "inventory management free trial"
    "accounting software demo"
```

### Keyword Mapping Template

```
KEYWORD MAP
=============
| Target keyword              | Volume | Diff | Intent       | URL                    | Status    |
|------------------------------|--------|------|-------------|------------------------|-----------|
| inventory management software| 8,100  | 65   | Commercial  | /solutions/inventory   | Live      |
| how to track inventory       | 3,600  | 32   | Informational| /blog/inventory-tracking| Draft    |
| ERP for manufacturing        | 1,900  | 48   | Commercial  | /solutions/manufacturing| Planned  |
| bank reconciliation process  | 2,400  | 28   | Informational| /blog/bank-reconciliation| Live    |
| [product] vs [competitor]    | 720    | 22   | Commercial  | /compare/[competitor]  | Planned   |

RULES:
- One primary keyword per page (avoid keyword cannibalization)
- 2-5 secondary/related keywords per page
- Do not target the same keyword on multiple pages
- Group related keywords into clusters (see content-strategy skill)
```

## 2. On-Page SEO

### Title Tags

```
TITLE TAG BEST PRACTICES
===========================
Length:          50-60 characters (Google truncates at ~580px width)
Structure:      Primary Keyword — Secondary Context | Brand Name
Placement:      Primary keyword as close to the front as possible
Uniqueness:     Every page must have a unique title tag

FORMULAS:
  Blog post:     "How to [Action] [Object] in [Year] | [Brand]"
  Landing page:  "[Product/Feature] — [Key Benefit] | [Brand]"
  Category page: "[Category] — [Descriptor] | [Brand]"
  Comparison:    "[Product] vs [Competitor]: [Differentiator] | [Brand]"

EXAMPLES:
  Good:   "Inventory Management Software for Multi-Branch Businesses | Acme"
  Good:   "How to Reconcile Bank Statements in 5 Steps | Acme Blog"
  Bad:    "Home" (not descriptive)
  Bad:    "Acme | The Best ERP Software for Every Business Everywhere" (too long, keyword-stuffed)
```

### Meta Descriptions

```
META DESCRIPTION BEST PRACTICES
==================================
Length:          150-160 characters
Content:        Summarize the page value, include target keyword naturally
CTA:            End with a soft call to action
Uniqueness:     Every page must have a unique meta description

FORMULA:
  "[What this page covers]. [Key benefit or differentiator]. [CTA]."

EXAMPLES:
  "Learn how to track inventory across multiple warehouses in real time.
   Reduce stockouts and overstock with automated alerts. Read the guide."

  "Compare Acme ERP vs CompetitorX on features, pricing, and ease of use.
   See which platform fits your business. View the comparison."

COMMON MISTAKES:
  - Duplicating title tag as meta description
  - Keyword stuffing the description
  - Leaving it blank (Google auto-generates, often poorly)
  - Making it too short (under 100 characters wastes space)
```

### Heading Structure

```
HEADING HIERARCHY
===================
H1: One per page. Includes primary keyword. Describes the page topic.
H2: Major sections. Include secondary keywords naturally.
H3: Subsections under H2. Support the parent topic.
H4-H6: Use sparingly for deep nesting.

RULES:
- Never skip heading levels (H1 -> H3 without H2)
- Do not use headings for visual styling (use CSS instead)
- Each heading should be descriptive and scannable
- Include keywords naturally (do not force them)

EXAMPLE STRUCTURE:
  H1: Complete Guide to Inventory Management
    H2: What Is Inventory Management?
    H2: Types of Inventory Management Systems
      H3: Perpetual Inventory System
      H3: Periodic Inventory System
    H2: How to Choose the Right Inventory Method
      H3: FIFO vs LIFO Comparison
      H3: Weighted Average Cost Method
    H2: Best Practices for Multi-Warehouse Tracking
    H2: Common Inventory Mistakes to Avoid
```

### Internal Linking

```
INTERNAL LINKING STRATEGY
============================

RULES:
- Every page should have at least 2-3 internal links
- Use descriptive anchor text (not "click here" or "read more")
- Link to relevant pages (topical relevance > random linking)
- Pillar pages should receive the most internal links
- New content should link to existing high-performing pages
- Existing content should be updated to link to new content

ANCHOR TEXT GUIDELINES:
  Good:   "Learn more about bank reconciliation best practices"
  Good:   "our inventory management guide"
  Bad:    "click here"
  Bad:    "this article"
  Bad:    "inventory management inventory tracking inventory software" (keyword-stuffed)

LINKING PATTERNS:
  Hub-and-spoke: Pillar page links to cluster articles, each links back
  Sequential:    Step-by-step guides link to next/previous steps
  Contextual:    Inline links within paragraph text to related topics
  Navigation:    Sidebar or footer links to related content
  Breadcrumbs:   Hierarchical path (Home > Category > Article)

AUDIT INTERNAL LINKS QUARTERLY:
- Find orphan pages (pages with no internal links pointing to them)
- Find broken internal links (404s)
- Identify pages with too few links (< 2 inbound internal links)
- Check that high-priority pages have the most internal links
```

### Content Optimization Checklist

```
ON-PAGE SEO CHECKLIST
========================
Keyword placement:
- [ ] Primary keyword in title tag
- [ ] Primary keyword in H1
- [ ] Primary keyword in first 100 words
- [ ] Primary keyword in URL slug
- [ ] Primary keyword in meta description
- [ ] Secondary keywords in H2s (naturally)
- [ ] Related terms used throughout (semantic relevance)

Content quality:
- [ ] Answers the search intent completely
- [ ] More comprehensive than top-ranking competitors
- [ ] Includes original data, examples, or insights
- [ ] Updated with current information
- [ ] No thin content (aim for 1500+ words for competitive keywords)

Media:
- [ ] Images have descriptive alt text (include keyword if natural)
- [ ] Images are compressed (WebP format preferred)
- [ ] Images have descriptive file names (inventory-dashboard.webp, not IMG_3847.jpg)
- [ ] Videos embedded where they add value

User experience:
- [ ] Content is scannable (headings, bullets, short paragraphs)
- [ ] Table of contents for long-form content (2000+ words)
- [ ] Mobile-friendly formatting
- [ ] Fast page load (< 2.5s LCP)
- [ ] No intrusive interstitials blocking content
```

## 3. Technical SEO

### Crawling and Indexing

```
CRAWLING BEST PRACTICES
==========================

ROBOTS.TXT
  Location: https://yourdomain.com/robots.txt

  Example:
    User-agent: *
    Allow: /
    Disallow: /admin/
    Disallow: /api/
    Disallow: /tmp/
    Disallow: /*?sort=
    Disallow: /*?filter=

    Sitemap: https://yourdomain.com/sitemap.xml

  RULES:
  - Block admin, API, and internal tool paths
  - Block URL parameters that create duplicate content
  - Do NOT block CSS/JS files (crawlers need them to render pages)
  - Do NOT block pages you want indexed
  - Always reference your sitemap

XML SITEMAP
  Location: https://yourdomain.com/sitemap.xml

  Requirements:
  - Include all indexable pages
  - Exclude noindex pages, redirects, and 404s
  - Include lastmod dates (accurate, not auto-generated)
  - Maximum 50,000 URLs per sitemap (use sitemap index for large sites)
  - File size under 50MB uncompressed
  - Submit in Google Search Console and Bing Webmaster Tools

  Example:
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
      <url>
        <loc>https://example.com/blog/inventory-guide</loc>
        <lastmod>2026-03-01</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.8</priority>
      </url>
    </urlset>

INDEXING DIRECTIVES
  Use meta robots tag or X-Robots-Tag header:
  - index, follow (default — page is indexable, links are followed)
  - noindex, follow (page not indexed, but links are followed)
  - noindex, nofollow (page not indexed, links not followed)
  - noarchive (prevent cached version in search results)

  When to use noindex:
  - Thank-you pages after form submission
  - Search results pages (internal site search)
  - Tag/filter pages that duplicate content
  - Staging and preview environments
  - Login and account pages
```

### Canonical Tags

```
CANONICAL TAG USAGE
=====================
Purpose: Tell search engines which version of a page is the "original"
         when duplicate or very similar content exists.

RULES:
- Every page should have a self-referencing canonical tag
- If content is duplicated across URLs, all versions should point
  to the canonical (preferred) URL
- Canonical URL must be the absolute URL (https://example.com/page)
- Canonical must return 200 status (not a redirect or 404)

EXAMPLE:
  <link rel="canonical" href="https://example.com/blog/inventory-guide" />

COMMON SCENARIOS:
  HTTP/HTTPS variants:    Canonical to HTTPS version
  www/non-www:            Canonical to preferred version
  Trailing slash:         Pick one style and be consistent
  URL parameters:         Canonical to parameter-free version
  Paginated content:      Each page canonicals to itself (not page 1)
  Syndicated content:     Canonical points back to your original
```

### Site Speed Optimization

```
SITE SPEED CHECKLIST
======================

SERVER
- [ ] Enable HTTP/2 or HTTP/3
- [ ] Use a CDN for static assets (CloudFront, Cloudflare)
- [ ] Enable Gzip or Brotli compression
- [ ] Set appropriate cache headers (Cache-Control, ETag)
- [ ] Server response time (TTFB) under 200ms

HTML
- [ ] Minimize DOM size (under 1,500 DOM elements)
- [ ] Inline critical CSS in the <head>
- [ ] Defer non-critical CSS with media="print" and onload
- [ ] Preload key resources (fonts, hero image, critical JS)

CSS
- [ ] Minify CSS files
- [ ] Remove unused CSS (PurgeCSS or similar)
- [ ] Avoid @import (use <link> tags instead)
- [ ] Use system fonts or limit custom font files

JAVASCRIPT
- [ ] Minify and bundle JS files
- [ ] Defer non-critical JS (defer or async attribute)
- [ ] Code-split by route (lazy load non-visible routes)
- [ ] Remove unused JavaScript (tree shaking)
- [ ] Avoid render-blocking JS in the <head>

IMAGES
- [ ] Use WebP or AVIF format
- [ ] Serve responsive images (srcset with multiple sizes)
- [ ] Lazy-load images below the fold (loading="lazy")
- [ ] Set explicit width and height to prevent layout shifts
- [ ] Compress images (aim for under 100KB per image)

FONTS
- [ ] Use font-display: swap to prevent invisible text
- [ ] Preload critical font files
- [ ] Limit font weights and styles loaded
- [ ] Self-host fonts (avoid Google Fonts render-blocking)
  Example preload:
    <link rel="preload" href="/fonts/inter-400.woff2" as="font"
          type="font/woff2" crossorigin>
```

### Core Web Vitals

```
CORE WEB VITALS TARGETS
==========================

LCP (Largest Contentful Paint) — Loading performance
  Good:    < 2.5 seconds
  Needs improvement: 2.5 - 4.0 seconds
  Poor:    > 4.0 seconds

  FIX LCP ISSUES:
  - Optimize the largest visible element (hero image, heading, video)
  - Preload the LCP resource: <link rel="preload" href="hero.webp" as="image">
  - Use a CDN to reduce server latency
  - Remove render-blocking resources
  - Ensure server TTFB < 200ms

FID / INP (Interaction to Next Paint) — Interactivity
  Good:    < 200ms
  Needs improvement: 200 - 500ms
  Poor:    > 500ms

  FIX INP ISSUES:
  - Break up long JavaScript tasks (> 50ms) into smaller chunks
  - Defer non-critical JS
  - Use web workers for heavy computation
  - Optimize event handlers (debounce, throttle)
  - Reduce main thread work

CLS (Cumulative Layout Shift) — Visual stability
  Good:    < 0.1
  Needs improvement: 0.1 - 0.25
  Poor:    > 0.25

  FIX CLS ISSUES:
  - Set explicit width/height on images and videos
  - Reserve space for ads and embeds
  - Avoid inserting content above existing content
  - Use font-display: swap with size-adjusted fallback fonts
  - Preload fonts to prevent layout shift on font swap

MEASUREMENT TOOLS:
  Lab data:  Lighthouse, PageSpeed Insights, WebPageTest
  Field data: Chrome UX Report (CrUX), Google Search Console
  Monitoring: Web Vitals JS library in production
```

### Schema Markup (Structured Data)

```
SCHEMA MARKUP IMPLEMENTATION
===============================

PURPOSE: Help search engines understand your content structure.
         Can enable rich results (stars, FAQ, breadcrumbs, etc.).

FORMAT: JSON-LD (recommended — embedded in <script> tag)

ORGANIZATION SCHEMA
```

```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Acme Software",
  "url": "https://www.acme.com",
  "logo": "https://www.acme.com/logo.png",
  "sameAs": [
    "https://www.linkedin.com/company/acme",
    "https://twitter.com/acme"
  ],
  "contactPoint": {
    "@type": "ContactPoint",
    "telephone": "+1-555-555-5555",
    "contactType": "customer service",
    "availableLanguage": ["English"]
  }
}
```

```
ARTICLE SCHEMA (blog posts)
```

```json
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Complete Guide to Inventory Management",
  "description": "Learn how to manage inventory across multiple warehouses.",
  "author": {
    "@type": "Person",
    "name": "Jane Smith"
  },
  "publisher": {
    "@type": "Organization",
    "name": "Acme Software",
    "logo": {
      "@type": "ImageObject",
      "url": "https://www.acme.com/logo.png"
    }
  },
  "datePublished": "2026-01-15",
  "dateModified": "2026-03-01",
  "image": "https://www.acme.com/blog/inventory-guide/hero.webp"
}
```

```
FAQ SCHEMA (FAQ sections)
```

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is multi-branch inventory management?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Multi-branch inventory management is the process of tracking stock levels, movements, and orders across multiple warehouse or store locations from a single system."
      }
    },
    {
      "@type": "Question",
      "name": "How do I choose between FIFO and LIFO?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "FIFO (First In, First Out) is best for perishable goods and most industries. LIFO (Last In, First Out) can offer tax advantages in inflationary environments but is not allowed under IFRS."
      }
    }
  ]
}
```

```
HOWTO SCHEMA (tutorials and guides)
```

```json
{
  "@context": "https://schema.org",
  "@type": "HowTo",
  "name": "How to Reconcile Bank Statements",
  "description": "Step-by-step guide to reconciling bank statements with your accounting records.",
  "totalTime": "PT30M",
  "step": [
    {
      "@type": "HowToStep",
      "name": "Gather statements",
      "text": "Download your bank statement for the reconciliation period."
    },
    {
      "@type": "HowToStep",
      "name": "Match transactions",
      "text": "Compare each bank transaction with the corresponding entry in your ledger."
    },
    {
      "@type": "HowToStep",
      "name": "Identify discrepancies",
      "text": "Flag any transactions that do not match and investigate the cause."
    }
  ]
}
```

```
BREADCRUMB SCHEMA
```

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Home",
      "item": "https://www.acme.com/"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "Blog",
      "item": "https://www.acme.com/blog/"
    },
    {
      "@type": "ListItem",
      "position": 3,
      "name": "Inventory Management Guide",
      "item": "https://www.acme.com/blog/inventory-management-guide/"
    }
  ]
}
```

```
SOFTWARE APPLICATION SCHEMA (product/pricing pages)
```

```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Acme ERP",
  "applicationCategory": "BusinessApplication",
  "operatingSystem": "Web",
  "offers": {
    "@type": "Offer",
    "price": "49.00",
    "priceCurrency": "USD",
    "priceValidUntil": "2026-12-31"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.6",
    "reviewCount": "248"
  }
}
```

```
VALIDATION:
- Test with Google Rich Results Test: https://search.google.com/test/rich-results
- Test with Schema Markup Validator: https://validator.schema.org/
- Monitor in Search Console under "Enhancements"
```

## 4. Off-Page SEO

### Link Building Strategies

```
LINK BUILDING APPROACHES (ethical, sustainable)
=================================================

CONTENT-DRIVEN (best long-term strategy)
  - Original research and data studies (unique data gets cited)
  - Comprehensive guides that become reference material
  - Free tools and calculators (link magnets)
  - Infographics with embed code
  - Industry reports and benchmarks

RELATIONSHIP-DRIVEN
  - Guest posting on relevant industry blogs
  - Podcast appearances (show notes link back to you)
  - Expert roundups (contribute quotes with bio link)
  - Partner co-marketing (joint content, mutual linking)
  - Conference speaking (speaker page links)

DIGITAL PR
  - Press releases for significant product launches
  - HARO (Help a Reporter Out) responses
  - Industry award submissions
  - Expert commentary on industry news
  - Original research pitched to journalists

COMMUNITY
  - Answering questions on forums (with genuinely helpful content)
  - Open-source contributions (README links)
  - Sponsoring community events
  - Creating free educational resources

NEVER DO:
  - Buy links (Google penalizes this)
  - Use private blog networks (PBNs)
  - Spam comments with links
  - Use automated link building tools
  - Participate in link exchange schemes
  - Create low-quality guest posts solely for links
```

### Link Prospecting

```
LINK PROSPECT EVALUATION
===========================
Rate each prospect before outreach:

Domain Authority (DA/DR):   > 30 minimum, > 50 preferred
Relevance:                  Must be topically related to your content
Traffic:                    Site should have real organic traffic
Link quality:               Page should have dofollow editorial links
Editorial standards:        Site should have real editorial process

OUTREACH TEMPLATE:
  Subject: [Resource] for your article on [topic]

  Hi [Name],

  I read your article on [topic] — specifically the section about
  [specific section]. It is one of the better explanations I have seen.

  I recently published [content description] that covers [specific
  angle they do not cover]. It might be a useful addition for your
  readers.

  Here is the link: [URL]

  Either way, keep up the great work.

  [Your name]

RULES:
  - Personalize every outreach email (no mass templates)
  - Reference specific content they published
  - Offer genuine value, not just a link request
  - Follow up once after 5-7 days, then stop
  - Track outreach in a spreadsheet (prospect, status, date, response)
```

## 5. Local SEO

```
LOCAL SEO CHECKLIST
=====================

GOOGLE BUSINESS PROFILE
- [ ] Claimed and verified for each location
- [ ] Business name, address, phone (NAP) accurate and consistent
- [ ] Primary and secondary categories set correctly
- [ ] Business description with target keywords (750 chars)
- [ ] Business hours set (including holiday hours)
- [ ] Photos uploaded (exterior, interior, team, products)
- [ ] Products/services listed with descriptions
- [ ] Posts published regularly (weekly)
- [ ] Reviews monitored and responded to (all reviews, positive and negative)

LOCAL CITATIONS
- [ ] NAP consistent across all directories
- [ ] Listed on major directories (Yelp, Yellow Pages, BBB, industry-specific)
- [ ] Listed on Apple Maps and Bing Places
- [ ] Inconsistencies corrected (old addresses, phone numbers)

LOCAL CONTENT
- [ ] Location-specific landing pages (one per location)
- [ ] Local schema markup (LocalBusiness) on location pages
- [ ] City/region mentioned naturally in content
- [ ] Local case studies and testimonials
- [ ] Content about local events, news, or partnerships

LOCAL LINK BUILDING
- [ ] Links from local business organizations
- [ ] Chamber of commerce membership
- [ ] Local news coverage and press mentions
- [ ] Sponsorship of local events
- [ ] Partnerships with complementary local businesses

LOCAL SCHEMA EXAMPLE:
```

```json
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "Acme Software — Dubai Office",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Business Bay",
    "addressLocality": "Dubai",
    "addressRegion": "Dubai",
    "postalCode": "00000",
    "addressCountry": "AE"
  },
  "telephone": "+971-4-555-5555",
  "openingHoursSpecification": [
    {
      "@type": "OpeningHoursSpecification",
      "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      "opens": "09:00",
      "closes": "18:00"
    }
  ],
  "geo": {
    "@type": "GeoCoordinates",
    "latitude": 25.1972,
    "longitude": 55.2744
  }
}
```

## 6. SEO Audit

### Technical SEO Audit Checklist

```
TECHNICAL SEO AUDIT
======================

CRAWLING AND INDEXING
- [ ] Robots.txt is accessible and not blocking important pages
- [ ] XML sitemap exists, is valid, and submitted to Search Console
- [ ] No important pages with noindex tag
- [ ] No orphan pages (pages not linked from anywhere)
- [ ] Crawl budget not wasted on low-value pages (parameters, duplicates)
- [ ] No infinite crawl traps (calendar pages, filter combinations)

HTTP STATUS CODES
- [ ] No 404 errors on important pages
- [ ] 301 redirects in place for moved/deleted pages
- [ ] No redirect chains (A -> B -> C, should be A -> C)
- [ ] No redirect loops
- [ ] 5xx errors investigated and resolved

HTTPS
- [ ] All pages served over HTTPS
- [ ] HTTP to HTTPS redirect in place
- [ ] No mixed content warnings (HTTP resources on HTTPS pages)
- [ ] SSL certificate valid and not expiring soon
- [ ] HSTS header enabled

DUPLICATE CONTENT
- [ ] Canonical tags on all pages (self-referencing or cross-domain)
- [ ] www and non-www resolve to the same version
- [ ] Trailing slash handled consistently
- [ ] URL parameters do not create duplicate pages
- [ ] Pagination handled correctly (rel=prev/next or single-page)

MOBILE
- [ ] Mobile-friendly test passes
- [ ] No horizontal scrolling on mobile
- [ ] Touch targets large enough (48x48px minimum)
- [ ] Viewport meta tag present
- [ ] No mobile-specific crawl errors in Search Console

PERFORMANCE
- [ ] Core Web Vitals passing (LCP < 2.5s, INP < 200ms, CLS < 0.1)
- [ ] Page speed score > 80 on mobile
- [ ] TTFB < 200ms
- [ ] Total page weight < 3MB
```

### Content SEO Audit

```
CONTENT SEO AUDIT
====================

FOR EACH PAGE, EVALUATE:

KEYWORD TARGETING
- [ ] Primary keyword defined and mapped
- [ ] No keyword cannibalization (multiple pages targeting same keyword)
- [ ] Keyword present in title, H1, first paragraph, and URL
- [ ] Search intent matched (content type aligns with SERP results)

CONTENT QUALITY
- [ ] Content is more comprehensive than top-3 ranking competitors
- [ ] Information is current and accurate
- [ ] Unique value provided (not a rehash of existing content)
- [ ] Word count appropriate for the topic and competition
- [ ] Content answers the user's question completely

ON-PAGE ELEMENTS
- [ ] Title tag optimized (50-60 chars, keyword included)
- [ ] Meta description optimized (150-160 chars, compelling)
- [ ] Heading hierarchy correct (H1 > H2 > H3)
- [ ] Internal links present (2-3 minimum per page)
- [ ] Images optimized (alt text, compression, proper format)
- [ ] Schema markup implemented where applicable

ACTION:
  Score 8-10: Keep as-is, maintain freshness
  Score 5-7:  Update and optimize (content refresh)
  Score 1-4:  Rewrite, consolidate, or remove with redirect
```

## 7. Search Console Analysis

### Key Reports to Monitor

```
GOOGLE SEARCH CONSOLE MONITORING
===================================

WEEKLY CHECKS
- Performance report: Impressions, clicks, CTR, position trends
- Coverage report: New errors, warnings, excluded pages
- Core Web Vitals report: Pages failing CWV thresholds
- Manual actions: Check for penalties (should always be clean)

MONTHLY ANALYSIS
- Top queries: Identify new ranking keywords and drops
- Top pages: Track performance of key landing pages
- Click-through rate: Find low-CTR pages (improve title/meta)
- Position changes: Identify pages that moved significantly

QUARTERLY ANALYSIS
- Keyword gaps: Queries where you appear but do not rank top 10
- Cannibalization: Multiple pages ranking for the same query
- Content opportunities: High-impression, low-click queries
- Technical issues: Crawl errors, mobile usability, structured data errors

LOW-CTR OPTIMIZATION (high impressions, low clicks)
=====================================================
Avg. position 1-3 but CTR < 5%:
  - Title tag is not compelling enough
  - Meta description needs improvement
  - Rich snippet missing (add structured data)
  - SERP features (featured snippet, knowledge panel) are taking clicks

Avg. position 4-10 but CTR < 2%:
  - Improve ranking first (content quality, links, optimization)
  - Title tag should differentiate from higher-ranking results
  - Consider matching the search intent more precisely
```

### Search Console Data Export Template

```
SEARCH CONSOLE ANALYSIS TEMPLATE
===================================

TOP QUERIES (sorted by impressions)
| Query              | Clicks | Impressions | CTR   | Avg. Position | Action           |
|--------------------|--------|-------------|-------|---------------|------------------|
| [keyword]          | [N]    | [N]         | [X%]  | [X.X]         | Optimize / Create|

PAGES NEEDING ATTENTION
| Page                | Issue                    | Action                    |
|---------------------|--------------------------|---------------------------|
| /blog/old-article   | Position dropped 5+ spots| Update content, add links |
| /products/feature   | Low CTR (< 2%)           | Rewrite title and meta    |
| /docs/setup         | High impressions, no page | Create targeting this query|

TECHNICAL ISSUES
| Issue                 | Count | Priority | Fix                        |
|-----------------------|-------|----------|----------------------------|
| 404 errors            | [N]   | High     | Add redirects              |
| Redirect chains       | [N]   | Medium   | Flatten to direct redirects|
| Mobile usability      | [N]   | High     | Fix responsive issues      |
| CWV failures          | [N]   | High     | Optimize page speed        |
```

## 8. SEO Content Brief Template

```markdown
# SEO Content Brief

## Target keyword
- **Primary**: [keyword] (volume: [N], difficulty: [N])
- **Secondary**: [keyword 1], [keyword 2], [keyword 3]
- **Related/LSI**: [term 1], [term 2], [term 3]

## Search intent
- **Type**: Informational / Commercial / Transactional
- **User goal**: [What the searcher wants to accomplish]
- **Content format**: [What the SERP shows — guides, lists, videos, tools]

## SERP analysis
- **Featured snippet**: [Yes/No — format: paragraph/list/table]
- **People Also Ask**: [List top 4-5 PAA questions]
- **Top 3 results**:
  1. [Title] — [word count], [key strengths], [gaps]
  2. [Title] — [word count], [key strengths], [gaps]
  3. [Title] — [word count], [key strengths], [gaps]

## Content requirements
- **Title tag**: [50-60 chars with keyword]
- **Meta description**: [150-160 chars with keyword and CTA]
- **H1**: [Include primary keyword]
- **Word count**: [Range based on competitor analysis]
- **Format**: [Guide / List / Comparison / How-to]

## Outline
[Detailed heading outline based on SERP analysis and keyword research]

## Internal links
- Link TO: [List of existing pages to link to]
- Link FROM: [List of existing pages that should link to this new page]

## Schema markup
- **Type**: [Article / HowTo / FAQ / None]

## Success criteria
- **Ranking target**: Top 10 within 90 days
- **Traffic target**: [N] organic sessions per month within 6 months
- **Conversion target**: [N] CTA clicks per month
```

## 9. SEO Monitoring and Maintenance

```
ONGOING SEO MAINTENANCE SCHEDULE
====================================

WEEKLY
- Check Search Console for new errors
- Monitor Core Web Vitals for regressions
- Review ranking changes for target keywords
- Publish new content per editorial calendar

MONTHLY
- Full Search Console performance analysis
- Content refresh for 2-3 underperforming pages
- Internal link audit for new content
- Competitor ranking comparison
- Backlink profile review (new links, lost links, toxic links)

QUARTERLY
- Full technical SEO audit (crawl, index, speed, mobile)
- Content audit and gap analysis
- Keyword map review and update
- Schema markup validation
- Site architecture review (are new pages discoverable?)

ANNUALLY
- Comprehensive SEO strategy review
- Update keyword research with fresh data
- Full content audit (keep, update, consolidate, remove)
- Competitive landscape analysis
- Technical infrastructure review (hosting, CDN, architecture)
```
