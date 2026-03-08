---
name: analytics-reporting
description: Use when building KPI frameworks, designing dashboards, analyzing marketing performance, setting up attribution models, or creating automated reports. Covers Google Analytics 4, social media analytics, funnel analysis, cohort analysis, A/B test analysis, ROI calculation, competitive benchmarking, and stakeholder reporting.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Analytics & Reporting -- Performance Measurement and Data-Driven Decisions

## 1. KPI Framework

### KPI Hierarchy

Business Objectives -> Strategic KPIs (quarterly) -> Tactical KPIs (monthly) -> Operational Metrics (weekly/daily) -> Raw Data (events)

### Marketing KPI Categories

| Stage | Key Metrics |
|-------|------------|
| Awareness | Impressions, reach, brand mentions, share of voice, new sessions |
| Consideration | Engagement rate, CTR, avg session duration, email open/click rate |
| Conversion | Conversion rate, CPA, CPL, ROAS, marketing-sourced revenue, CAC |
| Retention | CLV, churn rate, NPS, repeat purchase rate, CSAT |

### North Star Metric Selection

Must be: measurable, actionable, leading (predicts future revenue), and understandable company-wide.

| Business Type | North Star Example |
|--------------|-------------------|
| SaaS | Weekly active users |
| E-commerce | Purchases per customer per quarter |
| Marketplace | Transactions completed per week |
| Content/Media | Daily reading time per subscriber |
| B2B Services | Monthly active projects per client |

Pick 3-5 supporting input metrics that drive the North Star (e.g., sign-ups/week, onboarding completion, feature adoption in first 7 days).

## 2. Google Analytics 4

### Event Tiers

| Tier | Examples | Setup |
|------|----------|-------|
| Auto-collected | page_view, session_start, first_visit | None |
| Enhanced measurement | scroll, outbound_click, site_search, file_download | Toggle in GA4 settings |
| Recommended events | sign_up, purchase, add_to_cart, generate_lead | Manual implementation, standard names |
| Custom events | demo_requested, pricing_viewed, feature_compared | Manual, business-specific |

### Setup Checklist

- [ ] GA4 property created, gtag.js or GTM installed
- [ ] Data streams configured (web, iOS, Android)
- [ ] Enhanced measurement enabled
- [ ] Cross-domain tracking (if multiple domains)
- [ ] Key events marked as conversions (max 30)
- [ ] Google Ads and Search Console linked
- [ ] Custom dimensions: user_type, subscription_plan (user-scoped); content_category (event-scoped)
- [ ] Audiences defined: converters, cart abandoners, high-value users, re-engagement targets
- [ ] Data retention set to 14 months
- [ ] Internal traffic excluded

### UTM Convention

```
utm_source:   Platform (lowercase): google, facebook, linkedin, newsletter
utm_medium:   Channel type: cpc, organic_social, paid_social, email, referral
utm_campaign: Campaign name (lowercase, hyphens): spring-launch-2026
utm_content:  Variant for A/B testing: cta-red-button, hero-video
```

## 3. Attribution Models

| Model | Rule | Best For |
|-------|------|----------|
| Last-click | 100% to last touchpoint | Direct response, bottom-funnel |
| First-click | 100% to first touchpoint | Understanding awareness channels |
| Linear | Equal credit to all touchpoints | Long sales cycles |
| Time-decay | More credit closer to conversion | B2B with long consideration |
| Position-based (U-shaped) | 40% first, 40% last, 20% middle | Balanced full-funnel view |
| Data-driven (GA4 default) | ML-assigned based on patterns | Any business with 300+ conversions/month |

### Implementation Steps

1. **Define conversions**: Primary (purchase, sign-up), secondary (lead form, trial), micro (email sign-up, pricing view)
2. **Ensure tracking**: UTMs on all links, cross-domain tracking, user ID stitching, click ID capture (gclid, fbclid)
3. **Set attribution window**: B2C 7-30 days, B2B 30-90 days, Enterprise 90-180 days
4. **Build report**: Channel contribution by model, assisted conversions, time lag, path length

## 4. Funnel Analysis

### Marketing Funnel

| Stage | Metrics | Content Types | Goal |
|-------|---------|--------------|------|
| TOFU (Awareness) | Impressions, reach, new visitors | Blog, social, video, PR | Get noticed |
| MOFU (Consideration) | Engagement, email sign-ups, downloads | Whitepapers, webinars, case studies | Build trust |
| BOFU (Decision) | Demo requests, trials, pricing views | Demos, trials, ROI calculators | Convert |
| Post-funnel | NPS, retention, referrals | Onboarding, community, loyalty | Retain and expand |

### Funnel Analysis Template

```
Stage               | Volume  | Conv %  | Drop-off | Benchmark
Website visitors    | 50,000  | ---     | ---      | ---
Engaged visitors    | 15,000  | 30.0%   | 70.0%    | 25-35%
Lead (form fill)    | 1,500   | 10.0%   | 90.0%    | 8-12%
MQL                 | 450     | 30.0%   | 70.0%    | 25-35%
SQL                 | 135     | 30.0%   | 70.0%    | 20-30%
Opportunity         | 55      | 40.7%   | 59.3%    | 35-45%
Customer            | 22      | 40.0%   | 60.0%    | 25-40%

Bottleneck: [Stage with lowest % or largest absolute drop]
Action: Improve [content/UX/targeting] at bottleneck stage
```

## 5. Cohort Analysis

**Cohort types**: Acquisition (sign-up month), behavioral (completed action X), channel (source), feature (adopted feature Y).

**Retention cohort table**: Rows = cohort month, columns = months since join, cells = % still active.

**Action triggers**:
- Month 1 retention < 40% -> Onboarding problem
- Month 3 retention < 20% -> Product-market fit concern
- Declining curves across newer cohorts -> Product degradation
- Improving curves -> Product improvements working

## 6. A/B Test Analysis

### Test Design

```
Hypothesis: If we [change X], then [metric Y] will [increase/decrease]
            by [expected %] because [rationale].
Primary metric:    [Single winner-determining metric]
Guardrail metrics: [Must NOT degrade: page load, error rate, support tickets]
Sample size:       [Calculate based on baseline rate and MDE]
Duration:          [Until sample size reached -- no peeking]
```

### Sample Size Quick Reference (95% confidence, 80% power)

| Baseline Rate | MDE 10% | MDE 20% | MDE 50% |
|--------------|---------|---------|---------|
| 2% | 39K/variant | 10K | 1.6K |
| 5% | 15K | 3.8K | 625 |
| 10% | 7.2K | 1.8K | 306 |
| 20% | 3.2K | 838 | 144 |

### Common Pitfalls

- Peeking before sample size reached (inflates false positives)
- Running too many variants without correction (Bonferroni)
- Ignoring novelty effect
- Testing during anomalous periods (holidays, outages)
- Declaring winner on secondary metric when primary was flat

## 7. ROI Calculation

### Core Formulas

```
Marketing ROI = (Revenue from Marketing - Marketing Cost) / Marketing Cost x 100
ROAS          = Revenue from Ads / Ad Spend
CAC           = Total Marketing & Sales Spend / New Customers
CLV           = ARPU x Gross Margin x (1 / Churn Rate)
CLV:CAC       = Target 3:1 or higher
Payback       = CAC / (ARPU x Gross Margin)  -- Target < 12 months for SaaS
```

### ROAS Benchmarks by Channel

| Channel | Typical ROAS |
|---------|-------------|
| Google Search | 2x-8x |
| Google Shopping | 3x-10x |
| Meta Ads | 2x-5x |
| LinkedIn Ads | 1.5x-4x (higher CPL, higher deal value) |
| TikTok Ads | 1.5x-4x |

## 8. Social Media Analytics

### Platform Key Metrics

| Platform | Engagement Rate Formula | Quality Signal | Benchmark |
|----------|------------------------|---------------|-----------|
| LinkedIn | (reactions + comments + shares + clicks) / impressions | Comments | 3-5% |
| Instagram | (likes + comments + saves + shares) / reach | Saves | 3-6% |
| X/Twitter | (likes + replies + retweets + clicks) / impressions | Bookmarks | 0.5-1.5% |
| YouTube | Watch time, avg view duration | Avg % viewed | CTR 4-10% |
| TikTok | Likes + comments + shares / views | Watch-through rate | 3-9% |

## 9. Dashboard Design

### Principles

1. **One purpose per dashboard**: Executive (KPIs), Campaign (performance), Content (post-level), Financial (ROI/budget)
2. **Visual hierarchy**: Top = critical KPIs with trend arrows. Middle = trend charts. Bottom = detail tables.
3. **Always show context**: Comparison periods, targets as reference lines, conditional formatting (red/yellow/green)
4. **Actionability**: Every metric answers "so what?" -- include trend direction and anomaly highlights

### Chart Type Selection

| Purpose | Chart Type |
|---------|-----------|
| Compare categories | Bar chart |
| Trend over time | Line chart |
| Parts of whole | Stacked bar (avoid pie with > 5 segments) |
| Distribution | Histogram, box plot |
| Funnel stages | Funnel chart |
| Two-variable relationship | Scatter plot |

**Anti-patterns**: 3D charts, dual y-axes, truncated axes without indication, rainbow palettes, averages without variance.

## 10. Reporting Cadence

| Frequency | Content | Audience |
|-----------|---------|----------|
| Daily | Key metrics snapshot, anomaly alerts, spend pacing | Marketing team |
| Weekly | Full dashboard review, top/bottom content, WoW trends | Marketing team + leadership |
| Monthly | Channel attribution, funnel analysis, ROI by campaign, budget vs actual | Leadership + stakeholders |
| Quarterly | North Star progress, competitive landscape, strategy review, budget reallocation | Executive team |

### Stakeholder-Specific Reporting

| Audience | Format | Focus |
|----------|--------|-------|
| C-Suite | 1-page summary, 5-7 KPIs | Business impact: revenue, ROI, growth |
| Marketing leadership | 5-10 page dashboard | Channel performance, strategy progress |
| Marketing team | Interactive dashboard with filters | Tactical: engagement, CTR, conversion by ad |
| Sales team | Lead/pipeline report | Lead quality, source attribution, conversion rate |

### The "So What" Framework

For every data point: (1) WHAT happened? (2) WHY did it happen? (3) SO WHAT should we do?

Template: "[Metric] [changed] by [X]% [period]. Driven by [cause]. Recommend [action], expected result [outcome]."

## 11. Data Quality

### Monthly Audit Checklist

- [ ] Analytics tag fires on all pages (check coverage)
- [ ] Conversion events fire correctly (test with debug mode)
- [ ] UTM parameters consistent across campaigns
- [ ] Bot/spam traffic filtered, internal traffic excluded
- [ ] Metric definitions documented and shared (engagement rate formula varies by platform)
- [ ] Time zones and currency standardized
- [ ] Cookie consent implemented (GDPR/CCPA)
- [ ] PII excluded from analytics tracking
