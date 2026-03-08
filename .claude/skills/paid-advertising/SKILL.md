---
name: paid-advertising
description: Use when planning paid advertising campaigns, optimizing ad spend, setting up conversion tracking, designing audience targeting, writing ad copy, or analyzing campaign performance. Covers Google Ads, Meta Ads, LinkedIn Ads, TikTok Ads, bidding strategies, retargeting, lookalike audiences, landing page optimization, ROAS optimization, and compliance.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Paid Advertising -- Campaign Strategy, Execution, and Optimization

## 1. Campaign Structure

```
Account -> Campaign (budget, objective, schedule)
           -> Ad Set / Ad Group (targeting, bid, placement)
              -> Ad (creative, copy, CTA, destination URL)
```

### Objective Selection

| Goal | Objective | Platforms | Key Metric |
|------|----------|-----------|------------|
| Brand awareness | Awareness/Reach | All | CPM, reach |
| Website traffic | Traffic | All | CPC, CTR |
| Lead generation | Lead gen / Conversions | All | CPL, conversion rate |
| App installs | App installs | Meta, Google, TikTok | CPI, install rate |
| Sales/revenue | Conversions / Shopping | Google, Meta | ROAS, CPA |
| B2B leads | Lead gen | LinkedIn, Google | CPL, lead quality score |

**Rule**: One objective per campaign. Never mix awareness and conversion objectives.

## 2. Platform Selection Guide

| Platform | Best For | Avg CPC | Targeting Strength |
|----------|----------|---------|-------------------|
| Google Search | High-intent keywords, bottom-funnel | $1-5 | Intent-based (keyword) |
| Google Shopping | E-commerce, product catalog | $0.50-2 | Product-based |
| Google Display | Retargeting, awareness | $0.10-1 | Contextual, audience |
| Meta (FB/IG) | B2C, lookalikes, visual products | $0.50-3 | Demographic, interest, behavioral |
| LinkedIn | B2B, job title targeting | $5-15 | Professional (title, company, industry) |
| TikTok | Gen Z/Millennial, viral creative | $0.20-2 | Interest, behavioral |
| YouTube | Video ads, awareness, tutorials | $0.10-0.30/view | Intent + demographic |

**Decision framework**: Start with the platform where your audience shows purchase intent. For B2B with deal sizes > $5K, LinkedIn's high CPC is justified by lead quality. For D2C/e-commerce, Meta + Google Shopping is the standard stack.

## 3. Audience Targeting

### Targeting Layers

| Layer | Description | Example |
|-------|-------------|---------|
| Core/demographic | Age, gender, location, language | 25-45, US, English |
| Interest/behavioral | Interests, purchase behavior | "SaaS", "Project management" |
| Custom audiences | Your data (email lists, pixel data) | Customers, leads, website visitors |
| Lookalike/similar | Platform-generated from seed list | 1% lookalike of purchasers |
| Retargeting | Re-engage past visitors/engagers | Visited pricing page, didn't convert |

### Retargeting Windows

| Audience | Window | Bid Adjustment |
|----------|--------|---------------|
| Cart abandoners | 1-3 days | Highest (3-5x) |
| Pricing page visitors | 7 days | High (2-3x) |
| Key page visitors | 14 days | Medium (1.5-2x) |
| All website visitors | 30 days | Standard |
| Past purchasers (upsell) | 60-90 days | Medium |
| Engaged social followers | 90 days | Low-medium |

**Lookalike best practices**: Seed with highest-value customers (not all customers). Start with 1% lookalike (most similar), test wider. Exclude existing customers. Refresh seed lists quarterly.

## 4. Bidding Strategies

| Strategy | When to Use | Risk Level |
|----------|-------------|------------|
| Manual CPC | Learning phase, tight control | Low |
| Target CPA | Stable conversion data (50+ conv/month) | Medium |
| Target ROAS | Revenue tracking in place, 100+ conv/month | Medium |
| Maximize conversions | Limited budget, want volume | High (CPA may spike) |
| Maximize clicks | Traffic campaigns, awareness | Low |

**Budget allocation framework**: 70% to proven campaigns/audiences, 20% to testing new audiences/creatives, 10% to experimental (new platforms, formats).

**Learning phase**: Most platforms need 50 conversions per ad set per week to optimize. During learning (first 3-7 days), avoid major changes. If not hitting 50/week, broaden targeting or combine ad sets.

## 5. Ad Creative and Copy

### Ad Copy Formula

```
HEADLINE (max 30 chars Google, 40 chars Meta):
  [Benefit] + [Specificity] + [Urgency/CTA]
  Examples: "Cut Deployment Time 80% -- Free Trial"
            "AI-Powered CRM -- 14 Days Free"

DESCRIPTION (max 90 chars Google, 125 chars Meta):
  [Problem] + [Solution] + [Proof] + [CTA]
  Example: "Tired of manual deployments? Automate CI/CD in minutes.
            Trusted by 5,000 teams. Start free."

CREATIVE BEST PRACTICES:
- Video outperforms static on Meta/TikTok (2-3x engagement)
- UGC-style content outperforms polished ads on TikTok
- Carousel ads drive highest CTR on Meta for e-commerce
- Text-heavy images penalized on Meta (keep text < 20% of image)
```

### Testing Framework

Test one variable at a time: Creative -> Copy -> Audience -> Placement -> Bid.

| Test Type | What to Test | Min Budget | Duration |
|-----------|-------------|------------|----------|
| Creative | Image vs video, styles | $500/variant | 7-14 days |
| Copy | Headlines, CTAs, angles | $300/variant | 7-14 days |
| Audience | Targeting segments | $500/segment | 14 days |
| Landing page | Page variants | $500/variant | 14-21 days |

**Winner criteria**: Statistical significance (95% confidence), minimum 100 conversions per variant, or 1,000 clicks for CTR tests.

## 6. Conversion Tracking

### Implementation Checklist

```
[ ] Base pixel/tag installed on all pages (Meta Pixel, Google Tag, LinkedIn Insight)
[ ] Conversion events defined and firing correctly
[ ] Server-side tracking as backup (Meta CAPI, Google Server-side GTM)
[ ] Enhanced conversions enabled (hashed email/phone for matching)
[ ] UTM parameters on all ad destination URLs
[ ] Cross-domain tracking configured (if applicable)
[ ] Test mode verified (Meta Events Manager, Google Tag Assistant)
[ ] Offline conversion import set up (CRM -> ad platform)
```

### Attribution Windows

| Platform | Default Click | Default View | Recommended |
|----------|--------------|-------------|-------------|
| Google Ads | 30 days | 1 day | 30-day click |
| Meta Ads | 7 days | 1 day | 7-day click, 1-day view |
| LinkedIn | 30 days | 7 days | 30-day click |
| TikTok | 7 days | 1 day | 7-day click |

## 7. Campaign Optimization

### Optimization Cadence

| Timeframe | Actions |
|-----------|---------|
| Daily | Check spend pacing, pause underperformers, adjust budgets |
| Weekly | Review CPL/CPA/ROAS by ad set, refresh creative if fatigued |
| Bi-weekly | Audience analysis, add negative keywords (Search), test new creative |
| Monthly | Full performance review, budget reallocation, strategy adjustments |

### Key Optimization Levers

| Problem | Diagnosis | Fix |
|---------|-----------|-----|
| Low CTR | Ad not resonating | Test new creative/copy, refine targeting |
| High CPC | Competitive auction | Improve quality score, adjust bidding, try different keywords |
| Low conversion rate | Landing page or audience mismatch | A/B test landing page, tighten targeting |
| High CPA | Multiple issues possible | Check full funnel: CTR -> landing page -> conversion flow |
| Ad fatigue | Frequency > 3 (Meta) | Refresh creative, expand audience |
| Low ROAS | Wrong audience or offer | Segment by audience, test pricing/offer changes |

### Google Search Specific

**Negative keywords**: Review search terms report weekly. Add irrelevant terms as negatives. Use negative keyword lists shared across campaigns.

**Quality Score optimization**: Align ad copy with keyword intent. Ensure landing page matches ad promise. Improve page load speed. Target CTR > 3% for non-brand keywords.

## 8. Landing Page Optimization

**Must-haves**: Headline matches ad copy (message match). Single clear CTA above the fold. Social proof (logos, testimonials, numbers). Mobile-optimized (60%+ of ad traffic is mobile). Load time < 3 seconds.

**Conversion rate benchmarks**: SaaS landing pages 3-5%. E-commerce product pages 2-4%. Lead gen pages 5-15%. Free trial pages 8-15%.

## 9. Reporting and ROAS

### Campaign Performance Template

```
Campaign: [Name]  |  Period: [Dates]  |  Budget: $[X]

Metrics:
  Impressions: [X]     |  Clicks: [X]        |  CTR: [%]
  CPC: $[X]            |  Conversions: [X]    |  CVR: [%]
  CPA: $[X]            |  Revenue: $[X]       |  ROAS: [X]x
  Spend: $[X]          |  Profit: $[X]        |  ROI: [%]

By Ad Set: [Top 3 and bottom 3 with metrics]
By Creative: [Top 3 and bottom 3 with metrics]

Actions: [What to pause, scale, or test next]
```

### ROAS Targets by Industry

| Industry | Break-even ROAS | Good ROAS | Excellent ROAS |
|----------|----------------|-----------|----------------|
| E-commerce (physical) | 2x | 4x | 6x+ |
| SaaS (monthly sub) | 1.5x (first month) | CLV-based: 3x+ | 5x+ |
| B2B services | 3x | 5x | 8x+ |
| D2C brands | 2.5x | 4x | 7x+ |

## 10. Compliance and Privacy

**Platform policies**: No misleading claims or fake urgency. No before/after images without disclaimers (Meta). No discriminatory targeting for housing/employment/credit (US law). Proper disclaimers for regulated industries (finance, health).

**Privacy requirements**: Cookie consent before pixel fires (GDPR/ePrivacy). Honor opt-outs (CCPA). Use Conversions API / server-side tracking to reduce reliance on cookies. First-party data strategy: email lists, CRM data, logged-in user matching.

**Ad library transparency**: Major platforms require political/issue ad disclosures. All Meta ads are publicly visible in the Ad Library. Plan creative accordingly.

## 11. Budget Planning

### Monthly Budget Template

| Line Item | Budget | % of Total |
|-----------|--------|-----------|
| Google Search (brand) | $X | 10% |
| Google Search (non-brand) | $X | 25% |
| Google Shopping | $X | 15% |
| Meta (prospecting) | $X | 20% |
| Meta (retargeting) | $X | 10% |
| LinkedIn | $X | 10% |
| Testing/experimental | $X | 10% |
| **Total** | **$X** | **100%** |

**Scaling rules**: Increase budget by max 20% per week (platform algorithms destabilize with larger jumps). Scale winning ad sets, not campaigns. When CPA exceeds target by 30%+, pause and diagnose before spending more.
