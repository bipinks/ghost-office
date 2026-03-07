---
name: analytics-reporting
description: Use when building KPI frameworks, designing dashboards, analyzing marketing performance, setting up attribution models, or creating automated reports. Covers Google Analytics 4, social media analytics, funnel analysis, cohort analysis, A/B test analysis, ROI calculation, competitive benchmarking, and stakeholder reporting.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Analytics & Reporting -- Performance Measurement and Data-Driven Decisions

## 1. KPI Framework Design

### 1.1 KPI Hierarchy

```
BUSINESS OBJECTIVES (Company Level)
  |
  +-- STRATEGIC KPIs (Quarterly targets)
  |     |
  |     +-- TACTICAL KPIs (Monthly metrics)
  |           |
  |           +-- OPERATIONAL METRICS (Weekly/Daily tracking)
  |                 |
  |                 +-- RAW DATA (Event-level data collection)
```

### 1.2 KPI Definition Template

```
KPI DEFINITION
==============
Name:           [Clear, specific metric name]
Owner:          [Team or individual responsible]
Definition:     [Exact calculation formula]
Data Source:     [Where the data comes from]
Frequency:      [How often it is measured]
Target:         [Specific numeric goal with timeframe]
Benchmark:      [Industry average or historical baseline]
Threshold:      [Red / Yellow / Green ranges]
Audience:       [Who sees this metric in reports]
```

### 1.3 Marketing KPI Framework

```
AWARENESS KPIs
├── Impressions (total and per platform)
├── Reach (unique accounts exposed)
├── Brand mention volume (social listening)
├── Share of voice (% of industry conversation)
├── Website sessions from organic channels
├── Video views and watch time
└── New follower growth rate

CONSIDERATION KPIs
├── Engagement rate (interactions / impressions)
├── Click-through rate (CTR)
├── Average session duration
├── Pages per session
├── Email open rate and click rate
├── Content download count
├── Webinar/event registration rate
└── Social media saves and shares

CONVERSION KPIs
├── Conversion rate (by channel and campaign)
├── Cost per acquisition (CPA)
├── Cost per lead (CPL)
├── Lead-to-customer rate
├── Return on ad spend (ROAS)
├── Marketing-sourced revenue
├── Customer acquisition cost (CAC)
└── Pipeline contribution ($)

RETENTION KPIs
├── Customer lifetime value (CLV)
├── Churn rate
├── Net Promoter Score (NPS)
├── Repeat purchase rate
├── Email subscriber retention rate
├── Community membership growth
└── Customer satisfaction score (CSAT)
```

### 1.4 North Star Metric Framework

```
NORTH STAR METRIC SELECTION
============================

Step 1: Identify the core value your product delivers to users
Step 2: Find the metric that best represents that value exchange
Step 3: Ensure the metric is:
  - Measurable (you can track it reliably)
  - Actionable (teams can influence it)
  - Leading (predicts future revenue, not just reflects past)
  - Understandable (everyone in the company gets it)

EXAMPLES BY BUSINESS TYPE:
├── SaaS: Weekly active users, or features used per session
├── E-commerce: Purchases per customer per quarter
├── Marketplace: Transactions completed per week
├── Content/Media: Daily reading time per subscriber
├── B2B Services: Monthly active projects per client
└── Community: Weekly engaged members (posted or commented)

SUPPORTING METRICS (pick 3-5 that drive the North Star):
├── Input metric 1: [e.g., sign-ups per week]
├── Input metric 2: [e.g., onboarding completion rate]
├── Input metric 3: [e.g., feature adoption in first 7 days]
├── Input metric 4: [e.g., support ticket resolution time]
└── Input metric 5: [e.g., referral invites sent per user]
```

---

## 2. Google Analytics 4 (GA4)

### 2.1 GA4 Event Architecture

```
GA4 EVENT MODEL
===============

AUTOMATICALLY COLLECTED EVENTS (no setup needed):
├── page_view
├── session_start
├── first_visit
├── user_engagement
└── scroll (at 90% depth)

ENHANCED MEASUREMENT EVENTS (toggle in GA4 settings):
├── scroll
├── outbound_click
├── site_search
├── video_engagement (YouTube embeds)
├── file_download
└── form_interaction (form_start, form_submit)

RECOMMENDED EVENTS (manually implemented, standard names):
├── sign_up           — User creates an account
├── login             — User logs in
├── purchase          — Transaction completed
├── add_to_cart       — Item added to cart
├── begin_checkout    — Checkout started
├── generate_lead     — Lead form submitted
├── view_item         — Product/service page viewed
├── share             — Content shared
├── search            — Internal search performed
└── select_content    — Content element clicked

CUSTOM EVENTS (business-specific):
├── demo_requested
├── pricing_viewed
├── feature_compared
├── whitepaper_downloaded
├── webinar_registered
└── chat_started
```

### 2.2 GA4 Implementation Checklist

```
SETUP CHECKLIST
[ ] Create GA4 property (not Universal Analytics)
[ ] Install gtag.js or Google Tag Manager container
[ ] Configure data streams (web, iOS, Android)
[ ] Enable enhanced measurement events
[ ] Set up cross-domain tracking (if multiple domains)
[ ] Configure data retention (14 months recommended)
[ ] Link Google Ads account
[ ] Link Search Console
[ ] Set up Google Signals (for cross-device tracking)
[ ] Configure user ID tracking (for logged-in users)

CONVERSION SETUP
[ ] Mark key events as conversions (max 30 per property)
[ ] Set up conversion values where applicable
[ ] Configure attribution model (data-driven recommended)
[ ] Test conversion tracking with debug mode

CUSTOM DIMENSIONS AND METRICS
[ ] User-scoped: user_type, subscription_plan, industry
[ ] Event-scoped: content_category, feature_name, experiment_variant
[ ] Item-scoped: product_category, brand, pricing_tier

AUDIENCES
[ ] All users (baseline)
[ ] Engaged users (2+ sessions in 7 days)
[ ] Converters (completed key conversion)
[ ] Cart abandoners (begin_checkout without purchase)
[ ] High-value users (top 20% by revenue)
[ ] Re-engagement targets (inactive 30+ days)
```

### 2.3 GA4 Reporting Configuration

```
CUSTOM REPORTS TO BUILD:

1. ACQUISITION OVERVIEW
   Dimensions: Session source/medium, Campaign
   Metrics: Sessions, Engaged sessions, Engagement rate,
            Conversions, Revenue
   Filter: Date range comparison (this period vs. last period)

2. CONTENT PERFORMANCE
   Dimensions: Page path, Page title, Content group
   Metrics: Views, Average engagement time, Scroll events,
            Conversions (by page)
   Filter: Exclude internal traffic

3. CONVERSION FUNNEL
   Steps:
   ├── Landing page view
   ├── Key page interaction (pricing, features, demo)
   ├── Form start or sign-up initiation
   ├── Form submit or sign-up complete
   └── Conversion confirmation
   Breakdown: By source/medium, device category

4. USER JOURNEY
   Dimensions: Landing page -> Second page -> Third page -> Exit page
   Metrics: Users, Conversion rate at each step
   Use: Path exploration report in GA4

5. CAMPAIGN PERFORMANCE
   Dimensions: Campaign name, Source, Medium
   Metrics: Sessions, Engaged sessions, Conversions, Revenue, CPA
   Filter: Paid channels only (medium = cpc, paid_social, email)
```

### 2.4 UTM Parameter Standards

```
UTM NAMING CONVENTION
=====================

utm_source:   Platform or publisher (lowercase, no spaces)
              Examples: google, facebook, linkedin, newsletter, partner-name

utm_medium:   Marketing medium (standardized terms)
              Examples: cpc, organic_social, paid_social, email, referral,
                        display, video, affiliate

utm_campaign: Campaign name (lowercase, hyphens)
              Examples: spring-launch-2026, product-demo-series,
                        black-friday-sale, webinar-ai-trends

utm_term:     Paid search keyword (optional)
              Examples: project+management+software, crm+for+startups

utm_content:  Ad/content variant for A/B testing (optional)
              Examples: cta-red-button, hero-video, testimonial-carousel

FULL URL EXAMPLE:
https://example.com/pricing?utm_source=linkedin&utm_medium=paid_social&utm_campaign=q1-brand-awareness&utm_content=carousel-v2

UTM BUILDER SPREADSHEET COLUMNS:
| Campaign | Source | Medium | Term | Content | Full URL | Short URL |
```

---

## 3. Social Media Analytics

### 3.1 Platform-Specific Metrics

```
LINKEDIN METRICS
├── Impressions and unique impressions
├── Engagement rate = (reactions + comments + shares + clicks) / impressions
├── Click-through rate (CTR) = clicks / impressions
├── Follower growth (net new per week/month)
├── Demographics: job title, industry, company size, location
├── Top-performing posts by engagement rate
├── Profile views and search appearances
└── Newsletter subscribers and open rate

X/TWITTER METRICS
├── Impressions per tweet
├── Engagement rate = (likes + replies + retweets + clicks) / impressions
├── Profile visits
├── Follower growth rate
├── Link clicks
├── Media engagement (image/video views)
├── Bookmark rate (high-quality signal)
└── Mention volume and sentiment

INSTAGRAM METRICS
├── Reach (unique accounts)
├── Impressions
├── Engagement rate = (likes + comments + saves + shares) / reach
├── Save rate = saves / reach (strongest quality signal)
├── Share rate = shares / reach
├── Stories: completion rate, tap-forward, tap-back, exit rate
├── Reels: plays, average watch time, shares
├── Profile visits and website clicks
└── Follower growth and demographics

YOUTUBE METRICS
├── Views and unique viewers
├── Watch time (hours)
├── Average view duration (AVD)
├── Average percentage viewed
├── Click-through rate (CTR) on thumbnails
├── Subscriber conversion rate (subs gained / views)
├── Audience retention curve (where viewers drop off)
├── Traffic sources (search, suggested, external, browse)
└── Revenue (if monetized): RPM, CPM

TIKTOK METRICS
├── Video views
├── Average watch time
├── Watch-through rate (% who watch to the end)
├── Profile views
├── Follower growth
├── Likes, comments, shares per video
├── Traffic source types
└── Audience demographics (age, gender, location)

FACEBOOK METRICS
├── Page reach and post reach
├── Engagement rate
├── Video views (3-second and 1-minute)
├── Page likes/follows growth
├── Click-through rate
├── Group membership and active members
├── Group engagement (posts, comments per member)
└── Referral traffic to website
```

### 3.2 Social Media Reporting Template

```
SOCIAL MEDIA PERFORMANCE REPORT
================================
Period: [Date range]
Prepared by: [Name]
Date: [Report date]

EXECUTIVE SUMMARY
[2-3 sentences: overall performance, key wins, areas for improvement]

FOLLOWER GROWTH
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│ Platform │ Start    │ End      │ Net New  │ Growth % │
├──────────┼──────────┼──────────┼──────────┼──────────┤
│ LinkedIn │ [X]      │ [Y]      │ [+Z]     │ [%]      │
│ X/Twitter│ [X]      │ [Y]      │ [+Z]     │ [%]      │
│ Instagram│ [X]      │ [Y]      │ [+Z]     │ [%]      │
│ YouTube  │ [X]      │ [Y]      │ [+Z]     │ [%]      │
│ TikTok   │ [X]      │ [Y]      │ [+Z]     │ [%]      │
└──────────┴──────────┴──────────┴──────────┴──────────┘

ENGAGEMENT SUMMARY
┌──────────┬───────────┬───────────┬──────────┬──────────┐
│ Platform │ Posts     │ Impressns │ Eng Rate │ Clicks   │
├──────────┼───────────┼───────────┼──────────┼──────────┤
│ [plat]   │ [count]   │ [count]   │ [%]      │ [count]  │
└──────────┴───────────┴───────────┴──────────┴──────────┘

TOP PERFORMING CONTENT (top 3 per platform)
1. [Platform] - [Post description] - [Engagement rate] - [Why it worked]
2. [Platform] - [Post description] - [Engagement rate] - [Why it worked]
3. [Platform] - [Post description] - [Engagement rate] - [Why it worked]

CONTENT PILLAR PERFORMANCE
┌──────────────┬──────────┬───────────┬──────────┐
│ Pillar       │ # Posts  │ Avg Eng % │ Trend    │
├──────────────┼──────────┼───────────┼──────────┤
│ Educational  │ [X]      │ [%]       │ [up/dn]  │
│ Promotional  │ [X]      │ [%]       │ [up/dn]  │
│ Engagement   │ [X]      │ [%]       │ [up/dn]  │
│ Culture      │ [X]      │ [%]       │ [up/dn]  │
└──────────────┴──────────┴───────────┴──────────┘

WEBSITE TRAFFIC FROM SOCIAL
├── Total sessions from social: [X] ([+/-]% vs prior period)
├── Top referral platform: [Platform] ([X] sessions)
├── Conversion rate from social: [%]
├── Leads generated from social: [X]
└── Revenue attributed to social: $[X]

INSIGHTS AND RECOMMENDATIONS
1. [Insight with data support] -> [Recommended action]
2. [Insight with data support] -> [Recommended action]
3. [Insight with data support] -> [Recommended action]

NEXT PERIOD PRIORITIES
1. [Priority 1]
2. [Priority 2]
3. [Priority 3]
```

---

## 4. Marketing Attribution Models

### 4.1 Attribution Model Comparison

```
LAST-CLICK ATTRIBUTION
======================
Rule: 100% credit to the last touchpoint before conversion
Pros: Simple, clear, easy to implement
Cons: Ignores awareness and consideration touchpoints
Best for: Direct response campaigns, bottom-of-funnel analysis

FIRST-CLICK ATTRIBUTION
========================
Rule: 100% credit to the first touchpoint
Pros: Values awareness and discovery channels
Cons: Ignores nurturing touchpoints that sealed the deal
Best for: Understanding which channels drive initial awareness

LINEAR ATTRIBUTION
==================
Rule: Equal credit to every touchpoint in the journey
Pros: Acknowledges all touchpoints
Cons: Overvalues low-impact touches, undervalues critical moments
Best for: Long sales cycles with many touchpoints

TIME-DECAY ATTRIBUTION
=======================
Rule: More credit to touchpoints closer to conversion
Pros: Balances awareness and conversion credit
Cons: May undervalue early awareness
Best for: B2B with long consideration periods

POSITION-BASED (U-SHAPED) ATTRIBUTION
======================================
Rule: 40% first touch, 40% last touch, 20% split among middle
Pros: Values both discovery and conversion
Cons: Arbitrary weighting
Best for: Balanced view of full funnel

DATA-DRIVEN ATTRIBUTION (GA4 Default)
======================================
Rule: Machine learning assigns credit based on actual conversion patterns
Pros: Most accurate, adapts to your data
Cons: Requires sufficient conversion volume (300+ per month)
Best for: Any business with enough data
```

### 4.2 Multi-Touch Attribution Setup

```
ATTRIBUTION IMPLEMENTATION STEPS
=================================

Step 1: Define conversion events
├── Primary: Purchase, sign-up, demo request
├── Secondary: Lead form, content download, trial start
└── Micro: Email sign-up, webinar registration, pricing page view

Step 2: Ensure consistent tracking
├── UTM parameters on ALL external links
├── Cross-domain tracking configured
├── User ID stitching for logged-in users
├── Click ID capture (gclid, fbclid, li_fat_id)
└── CRM integration for offline conversions

Step 3: Map customer journey stages
├── Awareness: First visit, brand search, social impression
├── Consideration: Return visit, content consumption, email open
├── Intent: Pricing page, demo request, trial start
├── Decision: Proposal view, contract page, checkout
└── Purchase: Transaction complete, contract signed

Step 4: Choose attribution window
├── B2C / E-commerce: 7-30 day window
├── B2B / SaaS: 30-90 day window
├── Enterprise: 90-180 day window
└── Adjust based on your average sales cycle length

Step 5: Build attribution report
├── Channel contribution by model
├── Assisted conversions per channel
├── Time lag to conversion
├── Path length analysis
└── Compare models side-by-side
```

### 4.3 Channel Attribution Report Template

```
CHANNEL ATTRIBUTION REPORT
===========================
Period: [Date range]
Model: [Attribution model used]
Conversion event: [Primary conversion]

CHANNEL PERFORMANCE
┌───────────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│ Channel       │ Last     │ First    │ Linear   │ Data     │ Assisted │
│               │ Click    │ Click    │          │ Driven   │ Conv.    │
├───────────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│ Organic Search│ 120      │ 85       │ 95       │ 102      │ 180      │
│ Paid Search   │ 95       │ 40       │ 65       │ 78       │ 110      │
│ Social (Org)  │ 25       │ 60       │ 45       │ 42       │ 95       │
│ Social (Paid) │ 45       │ 35       │ 40       │ 43       │ 65       │
│ Email         │ 80       │ 10       │ 50       │ 55       │ 120      │
│ Direct        │ 60       │ 90       │ 70       │ 68       │ 40       │
│ Referral      │ 15       │ 20       │ 15       │ 12       │ 30       │
└───────────────┴──────────┴──────────┴──────────┴──────────┴──────────┘

KEY INSIGHT: [Channel X] appears undervalued in last-click but
drives [Y] assisted conversions, indicating strong awareness
contribution. Consider increasing investment.
```

---

## 5. Funnel Analysis

### 5.1 Marketing Funnel Framework

```
TOFU (Top of Funnel) — AWARENESS
├── Metrics: Impressions, reach, brand searches, new visitors
├── Content: Blog posts, social posts, videos, podcasts
├── Channels: SEO, social media, PR, display ads
└── Goal: Get noticed by target audience

MOFU (Middle of Funnel) — CONSIDERATION
├── Metrics: Engagement, email sign-ups, content downloads, return visits
├── Content: Whitepapers, case studies, webinars, comparison guides
├── Channels: Email, retargeting, organic social, search ads
└── Goal: Educate and build trust

BOFU (Bottom of Funnel) — DECISION
├── Metrics: Demo requests, trial starts, pricing views, proposals
├── Content: Product demos, free trials, ROI calculators, testimonials
├── Channels: Sales outreach, remarketing, direct
└── Goal: Convert to customer

POST-FUNNEL — RETENTION & ADVOCACY
├── Metrics: NPS, retention rate, expansion revenue, referrals
├── Content: Onboarding, help docs, community, loyalty programs
├── Channels: Email, in-app, community, support
└── Goal: Retain, expand, and create advocates
```

### 5.2 Funnel Conversion Analysis Template

```
CONVERSION FUNNEL ANALYSIS
===========================
Period: [Date range]
Funnel: [e.g., Website Visitor to Customer]

STAGE BREAKDOWN
┌─────────────────────┬──────────┬──────────┬──────────┬──────────┐
│ Stage               │ Volume   │ Conv %   │ Drop-off │ Benchmark│
├─────────────────────┼──────────┼──────────┼──────────┼──────────┤
│ Website visitors    │ 50,000   │ ---      │ ---      │ ---      │
│ Engaged visitors    │ 15,000   │ 30.0%    │ 70.0%    │ 25-35%   │
│ Lead (form fill)    │ 1,500    │ 10.0%    │ 90.0%    │ 8-12%    │
│ MQL (qualified)     │ 450      │ 30.0%    │ 70.0%    │ 25-35%   │
│ SQL (sales-ready)   │ 135      │ 30.0%    │ 70.0%    │ 20-30%   │
│ Opportunity         │ 55       │ 40.7%    │ 59.3%    │ 35-45%   │
│ Customer            │ 22       │ 40.0%    │ 60.0%    │ 25-40%   │
└─────────────────────┴──────────┴──────────┴──────────┴──────────┘

OVERALL: 50,000 visitors -> 22 customers = 0.044% conversion rate

BOTTLENECK IDENTIFICATION:
1. Largest absolute drop-off: [Stage with most lost volume]
2. Lowest stage conversion: [Stage with lowest %]
3. Below-benchmark stages: [Stages underperforming vs. benchmark]

RECOMMENDATIONS:
1. [Stage X] drop-off is [Y]% above benchmark -- investigate [Z]
2. Improve [content/UX/targeting] at [stage] to increase conversion by [target]%
3. Expected impact: +[N] additional customers per period = $[revenue]
```

---

## 6. Cohort Analysis

### 6.1 Cohort Analysis Framework

```
COHORT ANALYSIS STRUCTURE
==========================

DEFINE COHORT: Group users by a shared characteristic
├── Acquisition cohort: Month/week user first signed up
├── Behavioral cohort: Users who completed a specific action
├── Channel cohort: Users acquired from a specific source
└── Feature cohort: Users who adopted a specific feature

DEFINE METRIC: What to measure over time
├── Retention rate: % still active after N periods
├── Revenue: Average revenue per user over time
├── Engagement: Actions per user per period
├── Conversion: % who upgrade/purchase over time
└── Churn: % who leave each period

DEFINE TIME PERIODS: Granularity of analysis
├── Daily (for high-frequency products)
├── Weekly (for most SaaS/apps)
├── Monthly (for B2B, subscription services)
└── Quarterly (for enterprise, long cycle)
```

### 6.2 Retention Cohort Table Template

```
USER RETENTION BY MONTHLY ACQUISITION COHORT
==============================================

         │ Month 0 │ Month 1 │ Month 2 │ Month 3 │ Month 4 │ Month 5 │
─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
Jan 2026 │ 100%    │ 45%     │ 32%     │ 28%     │ 25%     │ 24%     │
Feb 2026 │ 100%    │ 48%     │ 35%     │ 30%     │ 27%     │         │
Mar 2026 │ 100%    │ 52%     │ 38%     │ 33%     │         │         │
Apr 2026 │ 100%    │ 55%     │ 40%     │         │         │         │
May 2026 │ 100%    │ 50%     │         │         │         │         │
Jun 2026 │ 100%    │         │         │         │         │         │

READING THE TABLE:
- Each row = a cohort of users who joined that month
- Each column = how many are still active N months later
- Improving Month 1 retention (Jan: 45% -> Jun: TBD) indicates
  onboarding improvements are working
- If Month 3+ flattens, you have found your "sticky" user base

ACTION TRIGGERS:
- Month 1 retention < 40%: Onboarding problem
- Month 3 retention < 20%: Product-market fit concern
- Declining cohort curves over time: Product degradation
- Improving cohort curves: Product improvements are working
```

---

## 7. A/B Test Analysis

### 7.1 A/B Test Design Framework

```
A/B TEST PLAN
=============
Test Name:     [Descriptive name]
Hypothesis:    If we [change X], then [metric Y] will [increase/decrease]
               by [expected %] because [rationale].
Primary Metric: [Single metric to determine winner]
Secondary Metrics: [2-3 supporting metrics to monitor]
Guardrail Metrics: [Metrics that must NOT degrade]

VARIANTS:
├── Control (A): [Current experience — describe]
├── Treatment (B): [Changed experience — describe]
└── Treatment (C): [Optional additional variant]

SAMPLE SIZE CALCULATION:
├── Baseline conversion rate: [%]
├── Minimum detectable effect: [%]
├── Statistical significance: 95% (p < 0.05)
├── Statistical power: 80%
├── Required sample per variant: [calculated number]
└── Estimated test duration: [days/weeks]

SEGMENTATION:
├── Device: Desktop vs Mobile
├── Traffic source: Organic vs Paid
├── User type: New vs Returning
└── Geography: [if relevant]

LAUNCH CHECKLIST:
[ ] QA both variants across devices and browsers
[ ] Analytics tracking verified for both variants
[ ] Random assignment confirmed (no selection bias)
[ ] Guardrail metrics baseline recorded
[ ] Test duration committed (no peeking before sample size reached)
[ ] Stakeholders informed of test timeline
```

### 7.2 A/B Test Results Template

```
A/B TEST RESULTS
=================
Test Name:       [Name]
Duration:        [Start date] to [End date]
Total Visitors:  [N] (Control: [n1], Treatment: [n2])

PRIMARY METRIC: [Metric name]
┌──────────┬──────────┬──────────┬──────────┬──────────┐
│ Variant  │ Visitors │ Converts │ Rate     │ vs Ctrl  │
├──────────┼──────────┼──────────┼──────────┼──────────┤
│ Control  │ 5,200    │ 312      │ 6.00%    │ ---      │
│ Treat. B │ 5,150    │ 386      │ 7.50%    │ +25.0%   │
└──────────┴──────────┴──────────┴──────────┴──────────┘

Statistical significance: 97.2% (p = 0.028)
Confidence interval: +15.8% to +34.2%

SECONDARY METRICS:
├── Average order value: Control $52, Treatment $49 (-5.8%, not significant)
├── Bounce rate: Control 42%, Treatment 38% (-9.5%, significant)
└── Pages per session: Control 3.2, Treatment 3.5 (+9.4%, significant)

GUARDRAIL METRICS:
├── Page load time: No change (OK)
├── Error rate: No change (OK)
└── Support tickets: No change (OK)

DECISION: [Ship / Iterate / Kill]
RATIONALE: [Why this decision based on the data]
PROJECTED IMPACT: [Annual impact if shipped: +X conversions = $Y revenue]
```

### 7.3 Statistical Significance Quick Reference

```
SAMPLE SIZE CALCULATOR (approximate)

For a two-sided test with 95% confidence and 80% power:

Baseline Rate │ MDE 5%  │ MDE 10% │ MDE 20% │ MDE 50%
──────────────┼─────────┼─────────┼─────────┼────────
1%            │ 310K    │ 78K     │ 20K     │ 3.2K
2%            │ 153K    │ 39K     │ 10K     │ 1.6K
5%            │ 59K     │ 15K     │ 3.8K    │ 625
10%           │ 28K     │ 7.2K    │ 1.8K    │ 306
20%           │ 13K     │ 3.2K    │ 838     │ 144
50%           │ 3.1K    │ 804     │ 210     │ 40

(Per variant. Total = per variant x number of variants)
MDE = Minimum Detectable Effect (relative change)

COMMON PITFALLS:
- Peeking at results before sample size reached (inflates false positives)
- Running too many variants (requires Bonferroni correction)
- Ignoring novelty effect (users react to change, not the change itself)
- Testing during anomalous periods (holidays, outages)
- Declaring winner on secondary metric when primary was flat
```

---

## 8. ROI Calculation

### 8.1 Marketing ROI Formulas

```
BASIC MARKETING ROI
====================
ROI = (Revenue from Marketing - Marketing Cost) / Marketing Cost x 100

Example:
Revenue attributed to marketing: $150,000
Marketing spend: $50,000
ROI = ($150,000 - $50,000) / $50,000 x 100 = 200%

RETURN ON AD SPEND (ROAS)
==========================
ROAS = Revenue from Ads / Ad Spend

Example:
Revenue from ad campaigns: $30,000
Ad spend: $10,000
ROAS = $30,000 / $10,000 = 3.0x (or 300%)

Benchmark ROAS by channel:
├── Google Search Ads: 2x-8x (depends on industry)
├── Google Shopping: 3x-10x
├── Facebook/Instagram Ads: 2x-5x
├── LinkedIn Ads: 1.5x-4x (higher CPL, but higher deal value)
└── TikTok Ads: 1.5x-4x (emerging, varies widely)

CUSTOMER ACQUISITION COST (CAC)
=================================
CAC = Total Marketing & Sales Spend / New Customers Acquired

Example:
Marketing spend: $50,000
Sales team cost: $30,000
New customers: 40
CAC = $80,000 / 40 = $2,000 per customer

CUSTOMER LIFETIME VALUE (CLV)
==============================
Simple CLV = Average Revenue per Customer x Average Customer Lifespan

CLV = ARPU x Gross Margin x (1 / Churn Rate)

Example:
ARPU: $200/month
Gross Margin: 70%
Monthly Churn: 3%
CLV = $200 x 0.70 x (1 / 0.03) = $4,667

CLV:CAC RATIO
==============
Target: 3:1 or higher

CLV:CAC = $4,667 / $2,000 = 2.33:1 (below target, optimize CAC or improve retention)

PAYBACK PERIOD
===============
Payback = CAC / (ARPU x Gross Margin)
Payback = $2,000 / ($200 x 0.70) = 14.3 months
Target: Under 12 months for SaaS
```

### 8.2 Campaign ROI Tracker

```
CAMPAIGN ROI TRACKER
=====================
Campaign: [Name]
Channel: [Platform/Channel]
Duration: [Start - End]
Budget: $[Total]

COST BREAKDOWN
├── Ad spend: $[X]
├── Creative production: $[X]
├── Tools/software: $[X]
├── Agency/contractor fees: $[X]
└── Total investment: $[X]

RESULTS
├── Impressions: [X]
├── Clicks: [X] (CTR: [%])
├── Leads generated: [X] (CPL: $[X])
├── Customers acquired: [X] (CPA: $[X])
├── Revenue attributed: $[X]
├── Pipeline influenced: $[X]
└── ROAS: [X]x

ROI CALCULATION:
Revenue ($[X]) - Investment ($[X]) = Profit ($[X])
ROI = $[Profit] / $[Investment] x 100 = [X]%
```

---

## 9. Competitive Benchmarking

### 9.1 Competitive Analytics Framework

```
COMPETITIVE BENCHMARK REPORT
==============================
Period: [Date range]
Our brand: [Name]
Competitors: [List 3-5]

SOCIAL MEDIA SHARE OF VOICE
┌──────────────┬──────────┬──────────┬──────────┬──────────┐
│ Brand        │ Mentions │ Share %  │ Sent.    │ Trend    │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ Our brand    │ 1,200    │ 28%      │ +72%     │ Up       │
│ Competitor A │ 1,800    │ 42%      │ +65%     │ Stable   │
│ Competitor B │ 800      │ 19%      │ +58%     │ Down     │
│ Competitor C │ 500      │ 12%      │ +80%     │ Up       │
└──────────────┴──────────┴──────────┴──────────┴──────────┘

AUDIENCE SIZE COMPARISON
┌──────────────┬──────────┬──────────┬──────────┬──────────┐
│ Brand        │ LinkedIn │ X/Twitter│ Instagram│ YouTube  │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ Our brand    │ 12K      │ 8K       │ 15K      │ 2K       │
│ Competitor A │ 45K      │ 30K      │ 50K      │ 10K      │
│ Competitor B │ 20K      │ 12K      │ 25K      │ 5K       │
│ Competitor C │ 8K       │ 5K       │ 10K      │ 1K       │
└──────────────┴──────────┴──────────┴──────────┴──────────┘

ENGAGEMENT RATE COMPARISON
┌──────────────┬──────────┬──────────┬──────────┬──────────┐
│ Brand        │ LinkedIn │ X/Twitter│ Instagram│ YouTube  │
├──────────────┼──────────┼──────────┼──────────┼──────────┤
│ Our brand    │ 4.2%     │ 1.8%     │ 3.5%     │ 5.1%     │
│ Competitor A │ 2.1%     │ 0.9%     │ 2.8%     │ 3.2%     │
│ Competitor B │ 3.5%     │ 1.2%     │ 4.1%     │ 4.5%     │
│ Competitor C │ 5.0%     │ 2.5%     │ 5.2%     │ 6.0%     │
└──────────────┴──────────┴──────────┴──────────┴──────────┘

CONTENT STRATEGY COMPARISON
┌──────────────┬──────────────┬──────────────┬──────────────┐
│ Brand        │ Content Mix  │ Post Freq    │ Top Format   │
├──────────────┼──────────────┼──────────────┼──────────────┤
│ Our brand    │ 40/20/25/15  │ 4/wk (LI)    │ Carousels    │
│ Competitor A │ 30/30/20/20  │ 7/wk (LI)    │ Video        │
│ Competitor B │ 50/15/25/10  │ 3/wk (LI)    │ Text posts   │
│ Competitor C │ 35/10/40/15  │ 5/wk (LI)    │ Polls/engage │
└──────────────┴──────────────┴──────────────┴──────────────┘
```

### 9.2 Competitive Monitoring Tools

```
FREE TOOLS:
├── Social Blade: YouTube/TikTok/Instagram follower tracking
├── Google Alerts: Brand mention monitoring
├── SimilarWeb (free tier): Website traffic estimates
├── BuiltWith: Technology stack analysis
├── SpyFu (free tier): Competitor keyword research
└── Facebook Ad Library: View competitor ad creatives

PAID TOOLS:
├── Brandwatch / Sprout Social: Social listening and analytics
├── SEMrush / Ahrefs: SEO and content competitive analysis
├── SimilarWeb Pro: Traffic and engagement benchmarking
├── Pathmatics / AdBeat: Competitor ad spend estimates
├── Rival IQ: Social media competitive benchmarks
└── Crayon: Competitive intelligence platform
```

---

## 10. Dashboard Design

### 10.1 Dashboard Design Principles

```
PRINCIPLE 1: ONE PURPOSE PER DASHBOARD
├── Executive dashboard: High-level KPIs, trends, health
├── Campaign dashboard: Active campaign performance
├── Content dashboard: Post-level performance analysis
├── Channel dashboard: Platform-specific deep dive
└── Financial dashboard: Revenue, ROI, budget tracking

PRINCIPLE 2: VISUAL HIERARCHY
├── Top: Most critical KPIs (large numbers with trend arrows)
├── Middle: Charts showing trends over time
├── Bottom: Detailed tables and breakdowns
└── Sidebar: Filters (date range, platform, campaign)

PRINCIPLE 3: CONTEXT ALWAYS
├── Show comparison periods (this month vs last month)
├── Include targets/benchmarks as reference lines
├── Use conditional formatting (red/yellow/green)
├── Add annotations for significant events
└── Show absolute numbers AND percentages

PRINCIPLE 4: ACTIONABILITY
├── Every metric should answer "so what?"
├── Include trend direction (up/down/flat)
├── Highlight anomalies automatically
├── Link to deeper analysis where relevant
└── Include recommendations alongside data
```

### 10.2 Executive Dashboard Layout

```
EXECUTIVE MARKETING DASHBOARD
===============================
Period: [Auto-updating date range selector]

ROW 1: HEADLINE KPIs (large number cards with sparklines)
┌────────────┬────────────┬────────────┬────────────┬────────────┐
│ Revenue    │ Leads      │ CAC        │ Website    │ Social     │
│ from Mktg  │ Generated  │            │ Sessions   │ Followers  │
│ $425K      │ 1,250      │ $340       │ 125K       │ 82K        │
│ +12% MoM   │ +8% MoM    │ -5% MoM   │ +15% MoM   │ +3% MoM    │
└────────────┴────────────┴────────────┴────────────┴────────────┘

ROW 2: TREND CHARTS (line/bar charts)
┌──────────────────────────┬──────────────────────────┐
│ Revenue by Channel       │ Leads by Source           │
│ (stacked bar, monthly)   │ (stacked area, weekly)    │
└──────────────────────────┴──────────────────────────┘

ROW 3: CHANNEL PERFORMANCE (table with conditional formatting)
┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│ Channel  │ Spend    │ Revenue  │ ROAS     │ Leads    │ CPL      │
├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│ [green]  │ $X       │ $X       │ Xx       │ X        │ $X       │
│ [yellow] │ $X       │ $X       │ Xx       │ X        │ $X       │
│ [red]    │ $X       │ $X       │ Xx       │ X        │ $X       │
└──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘

ROW 4: CAMPAIGN HIGHLIGHTS
├── Top campaign: [Name] — [Key metric]
├── Needs attention: [Name] — [What's wrong]
└── New this period: [Name] — [Status]
```

---

## 11. Automated Reporting

### 11.1 Reporting Cadence

```
REPORTING SCHEDULE
===================

DAILY (automated email or Slack):
├── Key metrics snapshot (sessions, leads, spend)
├── Anomaly alerts (metrics outside 2 standard deviations)
├── Campaign pacing (spend vs budget)
└── Social media mention alerts

WEEKLY (Monday morning report):
├── Full metrics dashboard review
├── Top/bottom performing content
├── Week-over-week trend analysis
├── Campaign performance summary
├── Competitive activity summary
└── Action items for the week

MONTHLY (first week of month):
├── Full marketing performance report
├── Channel attribution analysis
├── Funnel conversion analysis
├── Budget vs actual spend
├── ROI by campaign and channel
├── Content pillar performance
├── Audience growth and demographics
└── Strategic recommendations

QUARTERLY (quarterly business review):
├── North Star metric progress
├── OKR progress tracking
├── Competitive landscape update
├── Customer insight summary
├── Strategy review and adjustments
├── Budget reallocation recommendations
└── Next quarter planning
```

### 11.2 Automated Report Configuration

```
GOOGLE LOOKER STUDIO (formerly Data Studio) SETUP:

Data Sources to Connect:
├── Google Analytics 4 (native connector)
├── Google Ads (native connector)
├── Google Search Console (native connector)
├── Facebook/Meta Ads (via Supermetrics or Funnel.io)
├── LinkedIn Ads (via Supermetrics or manual CSV)
├── CRM data (via BigQuery or Sheets connector)
└── Custom data (via Google Sheets)

Recommended Pages:
├── Page 1: Executive Summary (KPI cards + trends)
├── Page 2: Traffic & Acquisition (by channel, source/medium)
├── Page 3: Content Performance (by page, content group)
├── Page 4: Campaign Performance (by campaign, ad group)
├── Page 5: Social Media (by platform, post type)
├── Page 6: Conversion Funnel (stage-by-stage analysis)
└── Page 7: Financial (spend, revenue, ROI)

Automation:
├── Schedule email delivery (daily/weekly/monthly)
├── Set up PDF snapshot for stakeholders without access
├── Configure alerts for metric thresholds
└── Auto-refresh data on dashboard load
```

---

## 12. Data Visualization Best Practices

### 12.1 Chart Type Selection Guide

```
CHOOSING THE RIGHT CHART
==========================

COMPARISON:
├── Bar chart: Compare categories (channels, campaigns)
├── Grouped bar: Compare categories across groups
├── Bullet chart: Actual vs target for KPIs
└── Radar chart: Multi-dimension comparison (use sparingly)

TREND OVER TIME:
├── Line chart: Continuous trends (daily/weekly/monthly metrics)
├── Area chart: Trends with volume emphasis
├── Sparkline: Compact trend in a KPI card
└── Step chart: Metrics that change at discrete points

COMPOSITION:
├── Stacked bar: Parts of a whole across categories
├── Pie/donut: Parts of a whole (max 5 segments, use sparingly)
├── Treemap: Hierarchical composition (budget breakdown)
└── Waterfall: Sequential additions/subtractions (funnel impact)

DISTRIBUTION:
├── Histogram: Distribution of values
├── Box plot: Distribution with quartiles
├── Scatter plot: Relationship between two variables
└── Heatmap: Density across two dimensions (day x hour posting)

FLOW AND JOURNEY:
├── Sankey diagram: User flow between stages
├── Funnel chart: Conversion stages
└── Network graph: Relationship mapping (influencer networks)
```

### 12.2 Visualization Anti-Patterns

```
AVOID THESE MISTAKES:
[ ] 3D charts (distort data perception)
[ ] Dual y-axes (confuse readers about scale)
[ ] Pie charts with more than 5 segments
[ ] Truncated y-axis without clear indication
[ ] Rainbow color palettes (use 2-3 colors max)
[ ] Excessive grid lines and chart junk
[ ] Missing axis labels or units
[ ] Inconsistent time scales across charts
[ ] Vanity metrics without context (big number, no benchmark)
[ ] Showing averages without distribution or variance
```

---

## 13. Reporting Stakeholder Communication

### 13.1 Audience-Specific Reporting

```
C-SUITE / EXECUTIVES:
├── Format: 1-page summary with 5-7 KPIs
├── Focus: Business impact (revenue, ROI, growth)
├── Frequency: Monthly + quarterly deep dive
├── Style: High-level trends, not granular data
├── Always include: Recommendations and investment asks
└── Avoid: Technical jargon, platform-specific metrics

MARKETING LEADERSHIP:
├── Format: 5-10 page dashboard with drill-down
├── Focus: Channel performance, campaign results, strategy progress
├── Frequency: Weekly summary + monthly full report
├── Style: Data-rich with clear insights
├── Always include: What's working, what's not, and next steps
└── Avoid: Raw data without interpretation

MARKETING TEAM:
├── Format: Interactive dashboard with filters
├── Focus: Tactical metrics (engagement, CTR, conversion by ad)
├── Frequency: Daily snapshots + weekly deep dive
├── Style: Detailed, actionable, with benchmarks
├── Always include: Top/bottom performers and optimization tasks
└── Avoid: Summary-only without actionable detail

SALES TEAM:
├── Format: Lead and pipeline report
├── Focus: Lead quality, source attribution, conversion rate
├── Frequency: Weekly
├── Style: Lead-level detail with scoring
├── Always include: Top lead sources and campaign influence
└── Avoid: Awareness/engagement metrics they cannot act on
```

### 13.2 Insight Communication Framework

```
THE "SO WHAT" FRAMEWORK
=========================

For every data point, answer three questions:

1. WHAT happened?
   "LinkedIn engagement rate increased from 3.2% to 4.8% this month."

2. WHY did it happen?
   "We shifted from link posts to carousel posts (5 of our top 10
   performers were carousels), and increased posting frequency
   from 3x to 5x per week."

3. SO WHAT should we do about it?
   "Double down on carousel format. Create a carousel template
   library. Allocate $500/month to boost top-performing carousels.
   Expected result: 20% increase in leads from LinkedIn."

INSIGHT TEMPLATE:
"[Metric] [increased/decreased] by [X]% [period comparison].
This was driven by [root cause]. We recommend [action],
which we estimate will result in [projected outcome]."
```

---

## 14. Data Quality and Governance

### 14.1 Data Quality Checklist

```
DATA QUALITY AUDIT (run monthly)
=================================

TRACKING INTEGRITY:
[ ] Analytics tag fires on all pages (check coverage report)
[ ] Conversion events tracked correctly (test with debug mode)
[ ] UTM parameters consistent across all campaigns
[ ] Cross-domain tracking working (if applicable)
[ ] Bot/spam traffic filtered
[ ] Internal traffic excluded
[ ] No duplicate tracking (double-firing tags)

DATA CONSISTENCY:
[ ] Metrics definitions documented and shared
[ ] Time zones standardized across tools
[ ] Currency standardized for revenue reporting
[ ] Attribution windows consistent across platforms
[ ] Naming conventions enforced (campaigns, UTMs)

DATA FRESHNESS:
[ ] Real-time data available for critical metrics
[ ] Dashboard data refreshes on schedule
[ ] Historical data backfilled after tracking changes
[ ] Data pipeline monitoring in place (alerts on failures)

PRIVACY AND COMPLIANCE:
[ ] Cookie consent implemented (GDPR/CCPA)
[ ] Data retention policies configured
[ ] PII excluded from analytics tracking
[ ] Data Processing Agreements in place with vendors
[ ] User opt-out mechanisms working
```

### 14.2 Metric Definitions Document

```
METRIC GLOSSARY
================
Maintain a shared document with exact definitions:

METRIC: Engagement Rate
DEFINITION: (Likes + Comments + Shares + Saves) / Impressions x 100
PLATFORMS: All social platforms
NOTE: Instagram uses Reach as denominator; LinkedIn uses Impressions
SOURCE: Platform native analytics
BENCHMARK: LinkedIn 3-5%, Instagram 3-6%, X/Twitter 0.5-1.5%

METRIC: Cost Per Lead (CPL)
DEFINITION: Total Campaign Spend / Number of Qualified Leads Generated
PLATFORMS: All paid channels
NOTE: "Qualified" means lead scoring >= 50 in CRM
SOURCE: Ad platform spend + CRM lead data
BENCHMARK: B2B SaaS $50-$200, B2C $10-$50

[Add definitions for every metric used in reporting]
```
