---
name: content-strategy
description: Use when planning content calendars, auditing existing content, defining editorial workflows, establishing brand voice guidelines, creating content governance frameworks, or measuring content performance. Covers content planning, repurposing strategies, content pillars, and audience mapping.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Content Strategy — Planning, Governance & Performance

## 1. Content Audit

### Inventory Template

Before creating new content, audit what already exists:

```
CONTENT AUDIT SPREADSHEET
==========================
URL                  | Title              | Type       | Word Count | Publish Date | Last Updated
---------------------|--------------------|------------|------------|--------------|-------------
/blog/feature-x      | Introducing X      | Blog post  | 1200       | 2025-06-15   | 2025-06-15
/docs/api-reference  | API Reference v2   | Docs       | 3400       | 2025-03-01   | 2025-09-20
/landing/pricing     | Pricing Plans      | Landing    | 800        | 2025-01-10   | 2025-08-05

Additional columns to track:
- Organic sessions (last 90 days)
- Bounce rate
- Avg. time on page
- Conversion rate (if applicable)
- Target keyword
- Current ranking position
- Content quality score (1-5)
- Action: Keep / Update / Consolidate / Remove
```

### Content Scoring Rubric

Rate each piece of content on a 1-5 scale across these dimensions:

```
CONTENT QUALITY SCORE
======================
Accuracy:       Is the information current and correct?          (1-5)
Relevance:      Does it serve a defined audience need?           (1-5)
Completeness:   Does it cover the topic thoroughly?              (1-5)
SEO:            Is it optimized for target keywords?             (1-5)
Engagement:     Does it drive measurable user actions?           (1-5)
Brand alignment: Does it follow voice and tone guidelines?       (1-5)

Total score: __/30
- 25-30: Keep as-is, promote actively
- 18-24: Update with fresh data, improve SEO
- 10-17: Rewrite or consolidate with related content
-  1-9:  Archive or remove (add 301 redirect if indexed)
```

### Gap Analysis

```
GAP ANALYSIS FRAMEWORK
=======================
1. Map every stage of the buyer journey:
   Awareness -> Consideration -> Decision -> Onboarding -> Retention -> Advocacy

2. For each stage, list:
   - Existing content pieces
   - Audience questions at this stage
   - Competitor content covering the same questions
   - Missing topics (gaps)

3. Prioritize gaps by:
   - Search volume for related keywords
   - Business impact (does filling this gap drive revenue?)
   - Effort to create (can we repurpose existing content?)
   - Competitive advantage (are competitors covering this well?)
```

## 2. Content Pillars and Clusters

### Pillar-Cluster Model

Organize content around core topics to build topical authority:

```
PILLAR PAGE (comprehensive, 3000-5000 words)
  |
  +-- Cluster Article 1 (specific subtopic, 1200-2000 words)
  +-- Cluster Article 2 (specific subtopic, 1200-2000 words)
  +-- Cluster Article 3 (specific subtopic, 1200-2000 words)
  +-- Cluster Article 4 (specific subtopic, 1200-2000 words)
  +-- Cluster Article 5 (specific subtopic, 1200-2000 words)

Internal linking:
- Every cluster article links back to the pillar page
- The pillar page links out to every cluster article
- Cluster articles cross-link where relevant
```

### Example Pillar Map

```
PILLAR: "Complete Guide to Inventory Management"
  |
  +-- "FIFO vs LIFO: Choosing the Right Costing Method"
  +-- "How to Set Reorder Points and Safety Stock Levels"
  +-- "Warehouse Organization Best Practices"
  +-- "Inventory Forecasting with Historical Data"
  +-- "Batch and Serial Number Tracking Explained"
  +-- "Multi-Warehouse Inventory Synchronization"
  +-- "Inventory Audit: Step-by-Step Process"
  +-- "Reducing Shrinkage and Stock Discrepancies"
```

### Pillar Planning Template

```
PILLAR DEFINITION
==================
Topic:              [Core topic]
Target keyword:     [Primary keyword, search volume, difficulty]
Audience:           [Who reads this and at what journey stage]
Pillar URL:         /guides/[topic-slug]
Word count target:  3000-5000 words
Cluster count:      6-10 supporting articles
Content format:     Long-form guide with TOC, visuals, CTAs
CTA:                [Primary action: sign up, demo, download]

CLUSTER ARTICLES
=================
| # | Title                     | Target keyword         | Vol  | Diff | Status  |
|---|---------------------------|------------------------|------|------|---------|
| 1 | [Subtopic article title]  | [keyword]              | 1200 | 25   | Draft   |
| 2 | [Subtopic article title]  | [keyword]              | 800  | 18   | Planned |
| 3 | [Subtopic article title]  | [keyword]              | 2400 | 40   | Live    |
```

## 3. Content Calendar

### Monthly Calendar Template

```
CONTENT CALENDAR — [MONTH YEAR]
=================================
Week | Publish Date | Type      | Title                        | Author   | Status   | Channel
-----|-------------|-----------|------------------------------|----------|----------|--------
1    | Mon Mar 2   | Blog      | [Title]                      | [Name]   | Draft    | Blog, Newsletter
1    | Wed Mar 4   | Social    | [Post summary]               | [Name]   | Scheduled| LinkedIn, Twitter
1    | Fri Mar 6   | Email     | [Campaign name]              | [Name]   | Approved | Email list
2    | Mon Mar 9   | Blog      | [Title]                      | [Name]   | Planned  | Blog, Newsletter
2    | Thu Mar 12  | Case study| [Customer name]              | [Name]   | In review| Blog, Sales
3    | Mon Mar 16  | Blog      | [Title]                      | [Name]   | Planned  | Blog
3    | Wed Mar 18  | Webinar   | [Topic]                      | [Name]   | Confirmed| Email, Social
4    | Mon Mar 23  | Blog      | [Title]                      | [Name]   | Planned  | Blog, Newsletter
4    | Fri Mar 27  | Newsletter| Monthly roundup              | [Name]   | Planned  | Email list
```

### Publishing Cadence Guidelines

```
RECOMMENDED CADENCE BY CONTENT TYPE
=====================================
Blog posts:          2-4 per month (consistency > volume)
Newsletter:          1-2 per month (avoid fatigue)
Case studies:        1 per month or quarter
Landing pages:       As needed for campaigns/features
Documentation:       Updated with every feature release
Social media:        3-5 posts per week (coordinate with social-media-manager)
Email campaigns:     Varies by segment (see email-marketing skill)

KEY PRINCIPLE: Publish at a pace you can sustain for 12+ months.
Inconsistent publishing damages audience trust more than low volume.
```

### Quarterly Planning Template

```
QUARTERLY CONTENT PLAN — Q[N] [YEAR]
======================================

GOALS
- Goal 1: Increase organic traffic by 20%
- Goal 2: Generate 50 MQLs from content
- Goal 3: Publish 3 case studies

THEMES
- Month 1: [Theme — e.g., "Inventory Optimization"]
- Month 2: [Theme — e.g., "Financial Year-End Preparation"]
- Month 3: [Theme — e.g., "Multi-Branch Scaling"]

KEY CONTENT PIECES
| Priority | Type        | Title/Topic                  | Target Keyword     | Funnel Stage   | Owner  |
|----------|-------------|------------------------------|--------------------|----------------|--------|
| P1       | Pillar      | Complete Guide to [Topic]    | [keyword]          | Awareness      | [Name] |
| P1       | Case study  | How [Customer] achieved X    | [keyword]          | Decision       | [Name] |
| P2       | Blog        | [Title]                      | [keyword]          | Consideration  | [Name] |
| P2       | Landing     | [Feature] page               | [keyword]          | Decision       | [Name] |
| P3       | Blog        | [Title]                      | [keyword]          | Awareness      | [Name] |

DISTRIBUTION PLAN
- Each blog post: Newsletter feature + 3 social posts + internal Slack share
- Case studies: Sales enablement deck + dedicated email + LinkedIn article
- Pillar pages: Paid promotion for 2 weeks + backlink outreach
```

## 4. Editorial Workflow

### Content Lifecycle Stages

```
STAGE 1: IDEATION
  - Source: Keyword research, customer questions, sales feedback, competitor gaps
  - Output: Content brief
  - Approver: Content strategist

STAGE 2: BRIEF
  - Define: Target keyword, audience, intent, outline, CTA, word count, deadline
  - Output: Approved content brief
  - Approver: Content strategist

STAGE 3: DRAFT
  - Writer creates first draft following the brief
  - Output: Draft in review
  - Approver: Author self-review

STAGE 4: EDITORIAL REVIEW
  - Review for accuracy, clarity, brand voice, SEO optimization
  - Output: Reviewed draft with feedback
  - Approver: Editor or content strategist

STAGE 5: REVISION
  - Author addresses feedback
  - Output: Final draft
  - Approver: Editor sign-off

STAGE 6: PUBLISH
  - Format, add images, set meta tags, schedule
  - Output: Published content
  - Approver: Content strategist

STAGE 7: DISTRIBUTE
  - Share via email, social, syndication
  - Output: Distribution report
  - Owner: Social media manager + content strategist

STAGE 8: MEASURE
  - Track performance after 7, 30, 90 days
  - Output: Performance report
  - Owner: Content strategist
```

### Content Brief Template

```markdown
# Content Brief

## Overview
- **Title (working)**: [Title]
- **Target keyword**: [keyword] (volume: X, difficulty: Y)
- **Secondary keywords**: [list]
- **Content type**: Blog post / Guide / Case study / Landing page
- **Word count target**: [range]
- **Deadline**: [YYYY-MM-DD]
- **Author**: [Name]

## Audience
- **Primary persona**: [Role, experience level, goals]
- **Search intent**: Informational / Navigational / Commercial / Transactional
- **Buyer journey stage**: Awareness / Consideration / Decision

## Outline
1. Introduction — Hook and problem statement
2. Section 1 — [H2 heading and key points]
3. Section 2 — [H2 heading and key points]
4. Section 3 — [H2 heading and key points]
5. Conclusion — Summary and CTA

## SEO Requirements
- Title tag: [50-60 characters including keyword]
- Meta description: [150-160 characters with keyword and CTA]
- H1: [Include primary keyword naturally]
- Internal links: Link to [list of related pages]
- External links: Cite [authoritative sources]

## CTA
- Primary CTA: [What action should the reader take?]
- CTA placement: [After introduction, mid-article, conclusion]

## Competitor References
- [URL 1]: [What they cover well / what they miss]
- [URL 2]: [What they cover well / what they miss]

## Notes
- [Style notes, things to avoid, required examples]
```

## 5. Brand Voice Guidelines

### Voice Definition Framework

```
BRAND VOICE ATTRIBUTES
=======================
Define 3-5 attributes that describe how the brand communicates:

Attribute 1: [e.g., "Knowledgeable"]
  - We are: Authoritative, well-researched, precise
  - We are not: Academic, condescending, jargon-heavy

Attribute 2: [e.g., "Approachable"]
  - We are: Friendly, clear, conversational
  - We are not: Casual, sloppy, overly informal

Attribute 3: [e.g., "Action-oriented"]
  - We are: Practical, solution-focused, direct
  - We are not: Preachy, vague, theoretical

Attribute 4: [e.g., "Trustworthy"]
  - We are: Transparent, honest, evidence-backed
  - We are not: Evasive, salesy, hyperbolic
```

### Tone Spectrum

```
TONE ADJUSTS BY CONTEXT (voice stays consistent)
==================================================

More formal                                      More casual
|------------|------------|------------|------------|
Legal/       Product     Blog posts   Social      Internal
Compliance   docs        & guides     media       comms

Examples:
- Error message (formal): "Your session has expired. Please sign in again."
- Blog intro (neutral): "Managing inventory across multiple warehouses is tricky. Here is how to get it right."
- Social post (casual): "Warehouse chaos? We have all been there. Here are 5 fixes that actually work."
```

### Writing Style Rules

```
STYLE GUIDE ESSENTIALS
=======================
Sentence length:     Average 15-20 words. Mix short and long.
Paragraph length:    2-4 sentences maximum.
Active voice:        Prefer "The system calculates tax" over "Tax is calculated by the system."
Second person:       Address the reader as "you" in blogs and guides.
Jargon:              Define technical terms on first use. Avoid unnecessary jargon.
Contractions:        Use them in blogs and social. Avoid in legal and formal docs.
Oxford comma:        Always use it.
Numbers:             Spell out one through nine. Use digits for 10 and above.
Headings:            Use sentence case ("How to set up inventory"), not title case.
Lists:               Use bullets for unordered items, numbers for sequential steps.
```

## 6. Content Governance

### Roles and Responsibilities

```
CONTENT GOVERNANCE MODEL
=========================
Content Strategist (owner)
  - Defines content calendar and priorities
  - Approves briefs and final content
  - Monitors performance and iterates strategy
  - Maintains brand voice guidelines

Editor
  - Reviews drafts for quality, accuracy, and voice
  - Ensures SEO best practices are followed
  - Manages editorial calendar execution

Writers (internal or external)
  - Create content from approved briefs
  - Follow style guide and SEO requirements
  - Submit drafts by deadline

Subject Matter Experts
  - Provide technical accuracy review
  - Supply data, quotes, and case study input
  - Review content for domain correctness

Social Media Manager
  - Distributes content across social channels
  - Creates platform-specific derivative content
  - Reports on social engagement metrics
```

### Content Review Checklist

```
PRE-PUBLISH REVIEW CHECKLIST
==============================
Accuracy:
- [ ] All facts, statistics, and claims are verified
- [ ] Technical content reviewed by SME
- [ ] Links are valid and point to correct destinations
- [ ] Code examples tested and working

SEO:
- [ ] Title tag set (50-60 characters, includes keyword)
- [ ] Meta description set (150-160 characters)
- [ ] H1 includes primary keyword
- [ ] Internal links added (minimum 2-3)
- [ ] Images have descriptive alt text
- [ ] URL slug is clean and keyword-rich

Brand voice:
- [ ] Tone matches content type and audience
- [ ] No jargon without definition
- [ ] Active voice used predominantly
- [ ] Consistent with style guide

Formatting:
- [ ] Headings follow logical hierarchy (H1 > H2 > H3)
- [ ] Paragraphs are 2-4 sentences
- [ ] Lists used for scannable content
- [ ] Images and diagrams add value (not decorative filler)

Legal/compliance:
- [ ] No confidential or proprietary information exposed
- [ ] Customer quotes and logos approved for use
- [ ] Appropriate disclaimers included where needed
- [ ] Copyright and attribution handled correctly

CTA:
- [ ] Clear primary CTA present
- [ ] CTA aligned with content goal and funnel stage
- [ ] UTM parameters set for trackable links
```

### Content Maintenance Schedule

```
CONTENT REFRESH CADENCE
========================
Evergreen guides:     Review quarterly, update as needed
Blog posts:           Review at 6 months, update or consolidate at 12 months
Landing pages:        Review monthly (tied to conversion data)
Documentation:        Update with every product release
Case studies:         Review annually, refresh metrics
API docs:             Update with every API change (automated where possible)
```

## 7. Content Repurposing

### Repurposing Matrix

Transform one piece of content into multiple formats:

```
SOURCE: Long-form blog post (2000 words)
  |
  +-- Social media thread (5-10 posts)
  +-- Newsletter feature (300 words + link)
  +-- Infographic (key data points visualized)
  +-- Short video script (2-3 minutes)
  +-- Slide deck (10-15 slides)
  +-- Podcast talking points
  +-- Email nurture sequence (3-5 emails)
  +-- FAQ entries for knowledge base
  +-- Pull quotes for social images

SOURCE: Customer case study
  |
  +-- Blog post (full story)
  +-- One-page PDF (sales enablement)
  +-- Video testimonial script
  +-- Social proof snippets for landing pages
  +-- Email campaign featuring the customer
  +-- Conference presentation slide

SOURCE: Webinar recording
  |
  +-- Blog post (transcript + key takeaways)
  +-- Short clips for social (30-60 seconds each)
  +-- Slide deck download
  +-- Follow-up email sequence
  +-- FAQ document from Q&A session
```

### Repurposing Workflow

```
1. IDENTIFY high-performing content (top 10% by traffic or engagement)
2. SELECT 2-3 derivative formats that serve different channels/audiences
3. ADAPT the content for each format (do not just copy-paste)
4. SCHEDULE distribution across channels with appropriate spacing
5. TRACK performance of each derivative independently
6. ITERATE based on which formats perform best for which source types
```

## 8. Content Performance Measurement

### KPI Framework by Content Type

```
BLOG POSTS
===========
Traffic:        Organic sessions, page views, unique visitors
Engagement:     Avg. time on page, scroll depth, bounce rate
SEO:            Keyword rankings, impressions, click-through rate
Conversion:     CTA clicks, form submissions, sign-ups attributed

LANDING PAGES
==============
Traffic:        Page views by source
Conversion:     Conversion rate (primary CTA)
Revenue:        Pipeline or revenue influenced
Bounce:         Bounce rate (target < 40%)

EMAIL CAMPAIGNS
================
Delivery:       Delivery rate, bounce rate
Engagement:     Open rate, click rate, click-to-open rate
Conversion:     Conversions attributed, revenue per email
Health:         Unsubscribe rate, spam complaints

CASE STUDIES
=============
Usage:          Views, downloads, shares
Sales impact:   Deals influenced, sales team usage frequency
SEO:            Rankings for customer/industry keywords
```

### Reporting Template

```
MONTHLY CONTENT PERFORMANCE REPORT
====================================
Period: [Month Year]

SUMMARY
- Total organic sessions: [N] (vs. [N-1] previous month, [+/-X%])
- New content published: [N] pieces
- Top performing piece: [Title] ([metric])
- Content-attributed conversions: [N]

TOP 5 CONTENT BY ORGANIC TRAFFIC
| # | Title                    | Sessions | Avg. Time | Bounce | Conversions |
|---|--------------------------|----------|-----------|--------|-------------|
| 1 | [Title]                  | [N]      | [Xm Ys]  | [X%]   | [N]         |
| 2 | [Title]                  | [N]      | [Xm Ys]  | [X%]   | [N]         |

KEYWORD RANKINGS (Target keywords)
| Keyword                  | Current | Previous | Change | URL              |
|--------------------------|---------|----------|--------|------------------|
| [keyword]                | [pos]   | [pos]    | [+/-]  | [url]            |

CONTENT PUBLISHED THIS MONTH
| Title               | Type    | Publish Date | Sessions (7d) | Conversions |
|---------------------|---------|--------------|---------------|-------------|
| [Title]             | Blog    | [Date]       | [N]           | [N]         |

RECOMMENDATIONS
- [Action 1: e.g., Update article X with fresh data — rankings dropped 5 positions]
- [Action 2: e.g., Create cluster article for pillar Y — gap identified]
- [Action 3: e.g., Repurpose case study Z into social campaign — high engagement]
```

### Attribution Model

```
CONTENT ATTRIBUTION
====================
First-touch:    Which content first brought the user to the site?
Last-touch:     Which content was consumed before conversion?
Multi-touch:    Which content pieces were consumed across the journey?

For most content teams, start with last-touch attribution,
then add multi-touch as tracking matures.

Tools for tracking:
- Google Analytics 4 (content grouping, conversion paths)
- UTM parameters on all distributed links
- CRM integration for lead-to-content mapping
- Heatmaps for on-page engagement (scroll depth, click maps)
```

## 9. Content for Product-Led Growth

### Documentation as Content

```
DOCUMENTATION CONTENT STRATEGY
================================
User-facing docs serve dual purposes:
1. Help existing users succeed (retention)
2. Attract new users via search (acquisition)

Optimize docs for search:
- Use natural language headings ("How to create an invoice" not "Invoice creation")
- Include the problem statement, not just the solution
- Add structured data (HowTo schema) for rich snippets
- Cross-link to related feature pages and blog posts

Docs to prioritize for SEO:
- Getting started guides (high search volume for "[product] tutorial")
- Integration guides (capture "[product] + [integration]" searches)
- Comparison pages (capture "[product] vs [competitor]" searches)
- Migration guides (capture "[competitor] to [product]" searches)
```

### In-App Content

```
IN-APP CONTENT TYPES
======================
Onboarding tooltips:   Guide new users through key features
Empty states:          Educate and motivate when no data exists yet
Feature announcements: Highlight new capabilities on first visit
Help text:             Contextual explanations near complex fields
Error messages:        Clear problem + solution (see copywriting-patterns skill)

Rules for in-app content:
- Keep it concise (under 50 words for tooltips, under 20 for help text)
- Link to full documentation for deep dives
- Test with real users for clarity
- Track dismissal rates and help link clicks
```

## 10. Competitive Content Analysis

### Competitor Content Audit

```
COMPETITOR CONTENT ANALYSIS
=============================
For each key competitor, assess:

1. Content volume:     How many blog posts, guides, case studies?
2. Publishing cadence: How often do they publish?
3. Content quality:    Depth, accuracy, production value
4. Topic coverage:     Which topics do they own? Where are their gaps?
5. SEO performance:    Which keywords do they rank for that we do not?
6. Distribution:       Which channels do they use? How large is their audience?
7. Engagement:         Social shares, comments, backlinks

OUTPUT: Opportunity matrix
| Topic              | Us  | Competitor A | Competitor B | Opportunity |
|--------------------|-----|--------------|--------------|-------------|
| [Topic 1]          | Gap | Strong       | Weak         | High        |
| [Topic 2]          | OK  | Gap          | Strong       | Medium      |
| [Topic 3]          | Strong | Gap       | Gap          | Defend      |
```

### Content Differentiation

```
HOW TO DIFFERENTIATE CONTENT
==============================
1. Original research:    Publish data only you have (product usage, survey results)
2. Expert perspectives:  Feature internal experts or customer interviews
3. Depth:                Go deeper than competitors (more examples, more edge cases)
4. Freshness:            Be first to cover new trends or updates
5. Format:               Use interactive tools, calculators, or templates
6. Specificity:          Target niche audiences competitors ignore
```

## 11. Content Operations Tooling

### Recommended Tool Stack

```
CONTENT OPS TOOLS
==================
Planning:           Content calendar (Notion, Airtable, or spreadsheet)
Writing:            Markdown editor or Google Docs with commenting
SEO research:       Ahrefs, SEMrush, or Google Search Console
Editing:            Grammarly, Hemingway, or manual editorial review
Publishing:         CMS (WordPress, Ghost, or static site generator)
Distribution:       Email platform, social scheduler, syndication feeds
Analytics:          Google Analytics 4, Search Console, CRM
Collaboration:      Shared drive, project management tool, Slack channel
```

### Content Workflow Automation

```
AUTOMATION OPPORTUNITIES
=========================
1. Auto-generate social posts from blog post metadata (title, excerpt, tags)
2. Schedule newsletter compilation from recently published content
3. Trigger SEO alerts when rankings drop for target keywords
4. Auto-notify SMEs when content referencing their domain needs review
5. Generate monthly performance reports from analytics data
6. Flag stale content based on last-updated date (> 6 months)
```

## 12. Localization and Global Content

### Localization Strategy

```
CONTENT LOCALIZATION TIERS
============================
Tier 1 (Full localization):
  - All product docs, landing pages, transactional emails
  - Professional translation + local review
  - Keyword research in target language

Tier 2 (Partial localization):
  - Key blog posts and guides
  - Machine translation + human review
  - Adapt examples for local market

Tier 3 (English only with support):
  - Niche content, internal docs
  - Provide glossary of key terms in target language

LOCALIZATION CHECKLIST
- [ ] Content adapted for local market (examples, currency, regulations)
- [ ] SEO keyword research done in target language (not just translated)
- [ ] Date, number, and currency formats localized
- [ ] Images and screenshots localized or made language-neutral
- [ ] Legal and compliance content reviewed by local counsel
```
