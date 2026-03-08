---
name: content-strategy
description: Use when planning content calendars, auditing existing content, defining editorial workflows, establishing brand voice guidelines, creating content governance frameworks, or measuring content performance. Covers content planning, repurposing strategies, content pillars, and audience mapping.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Content Strategy -- Planning, Governance & Performance

## 1. Content Audit

### Scoring Rubric (rate 1-5 each)
Accuracy, Relevance, Completeness, SEO, Engagement, Brand alignment. Total /30.
- 25-30: Keep, promote. 18-24: Update. 10-17: Rewrite/consolidate. 1-9: Archive (301 redirect).

### Gap Analysis
Map buyer journey stages (Awareness -> Consideration -> Decision -> Onboarding -> Retention -> Advocacy). For each: list existing content, audience questions, competitor coverage, missing topics. Prioritize gaps by search volume, business impact, effort, and competitive advantage.

## 2. Content Pillars and Clusters

```
PILLAR PAGE (3000-5000 words, comprehensive)
  +-- Cluster 1 (specific subtopic, 1200-2000 words)
  +-- Cluster 2 ... (6-10 articles per pillar)

Linking: Every cluster links to pillar. Pillar links to all clusters. Clusters cross-link.
```

### Pillar Planning
```
Topic: [Core topic]  |  Keyword: [primary, volume, difficulty]
Audience: [Who, journey stage]  |  CTA: [sign up/demo/download]
Cluster articles:
| # | Title | Keyword | Volume | Difficulty | Status |
|---|-------|---------|--------|-----------|--------|
```

## 3. Content Calendar

```
MONTHLY CALENDAR
Week | Date      | Type       | Title          | Author | Status | Channel
1    | Mon Mar 2 | Blog       | [Title]        | [Name] | Draft  | Blog, Newsletter
1    | Wed Mar 4 | Social     | [Post summary] | [Name] | Sched  | LinkedIn, Twitter
```

**Cadence**: Blog 2-4/month. Newsletter 1-2/month. Case studies 1/month. Social 3-5/week. Documentation with every release.

**Key principle**: Publish at a pace sustainable for 12+ months. Inconsistency damages trust more than low volume.

### Quarterly Plan
Goals (traffic, MQLs, case studies) -> Monthly themes -> Key content pieces (priority, type, keyword, funnel stage) -> Distribution plan.

## 4. Editorial Workflow

```
Ideation -> Brief -> Draft -> Editorial Review -> Revision -> Publish -> Distribute -> Measure
```

### Content Brief Template
```markdown
**Title**: [working]  |  **Keyword**: [vol, difficulty]  |  **Type**: Blog/Guide/Case study
**Audience**: [persona, intent, journey stage]  |  **Word count**: [range]  |  **Deadline**: [date]

## Outline
1. Introduction -- hook + problem  2-4. [H2 sections]  5. Conclusion + CTA

## SEO
Title tag (50-60 chars) | Meta description (150-160 chars) | Internal links: [pages] | External: [sources]

## CTA
Primary: [action]  |  Placement: [intro, mid, conclusion]
```

## 5. Brand Voice

### Voice Definition (3-5 attributes)
```
Attribute: [e.g., "Knowledgeable"]
  We are: Authoritative, precise, well-researched
  We are not: Academic, condescending, jargon-heavy
```

### Tone Spectrum (voice stays consistent, tone adjusts)
```
More formal -------- Neutral -------- More casual
Legal/Compliance | Product docs | Blog/guides | Social | Internal
```

### Style Rules
- Sentences: avg 15-20 words, mix lengths. Paragraphs: 2-4 sentences max.
- Active voice. Second person ("you") in blogs/guides. Define jargon on first use.
- Oxford comma always. Numbers: spell one-nine, digits for 10+. Sentence case headings.

## 6. Content Governance

**Roles**: Content Strategist (owns calendar, approves briefs/content, monitors performance). Editor (reviews quality, voice, SEO). Writers (create from briefs). SMEs (technical accuracy). Social Media Manager (distribution).

### Pre-Publish Checklist
**Accuracy**: Facts verified, SME reviewed, links valid, code tested.
**SEO**: Title tag, meta description, H1 with keyword, 2-3 internal links, alt text.
**Voice**: Tone matches type/audience, no undefined jargon, active voice.
**Formatting**: Heading hierarchy, short paragraphs, scannable lists.
**Legal**: No confidential info, customer quotes approved, disclaimers included.

### Refresh Cadence
Evergreen guides: quarterly. Blog posts: 6-month review, 12-month update/consolidate. Landing pages: monthly. Docs: every release. Case studies: annually.

## 7. Content Repurposing

```
SOURCE: Long-form blog (2000 words)
  -> Social thread (5-10 posts) + Newsletter (300 words) + Infographic
  -> Video script (2-3 min) + Slide deck + Email nurture (3-5 emails)

SOURCE: Case study
  -> Blog post + One-page PDF (sales) + Testimonial snippets + Email campaign

SOURCE: Webinar
  -> Blog (transcript + takeaways) + Social clips (30-60s) + FAQ from Q&A
```

**Workflow**: Identify top 10% content -> Select 2-3 derivative formats -> Adapt (not copy) -> Schedule -> Track each independently.

## 8. Performance Measurement

### KPIs by Type
| Type | Key Metrics |
|------|------------|
| Blog | Organic sessions, avg time, keyword rankings, CTA clicks |
| Landing page | Conversion rate, bounce rate (<40%), revenue influenced |
| Email | Open rate, click rate, conversions, unsubscribe rate |
| Case study | Views, downloads, deals influenced |

### Monthly Report Template
```
Total organic sessions: [N] ([+/-X%] vs prior)
New content published: [N]  |  Top piece: [Title] ([metric])
Content-attributed conversions: [N]

TOP 5 BY TRAFFIC | KEYWORD RANKINGS | CONTENT PUBLISHED | RECOMMENDATIONS
```

**Attribution**: Start with last-touch, add multi-touch as tracking matures. UTM params on all distributed links. CRM integration for lead-to-content mapping.

## 9. Content for Product-Led Growth

**Docs as content**: Use natural language headings. Include the problem, not just the solution. Add HowTo schema. Prioritize: getting started, integration guides, comparison pages, migration guides.

**In-app content**: Onboarding tooltips (<50 words), empty states, feature announcements, help text (<20 words), error messages. Link to full docs. Track dismissal rates.

## 10. Competitive Content Analysis

Assess per competitor: content volume, cadence, quality, topic coverage, SEO keywords, distribution, engagement.

Output: Opportunity matrix (Topic x Competitor presence = gap/opportunity).

**Differentiation**: Original research (data only you have), expert perspectives, greater depth, freshness, interactive formats, niche audiences competitors ignore.

## 11. Localization

| Tier | Scope | Approach |
|------|-------|---------|
| 1 Full | Product docs, landing pages, transactional email | Professional translation + local review + local keyword research |
| 2 Partial | Key blog posts, guides | Machine translation + human review + local examples |
| 3 English only | Niche content, internal docs | Glossary of key terms in target language |

Always: Adapt examples for local market, localize date/currency formats, review legal content locally.
