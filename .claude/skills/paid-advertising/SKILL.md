---
name: paid-advertising
description: Use when planning paid advertising campaigns, optimizing ad spend, setting up conversion tracking, designing audience targeting, writing ad copy, or analyzing campaign performance. Covers Google Ads, Meta Ads, LinkedIn Ads, TikTok Ads, bidding strategies, retargeting, lookalike audiences, landing page optimization, ROAS optimization, and compliance.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Paid Advertising -- Campaign Strategy, Execution, and Optimization

## 1. Campaign Structure Fundamentals

### 1.1 Universal Campaign Hierarchy

```
ACCOUNT
  |
  +-- CAMPAIGN (budget, objective, schedule)
  |     |
  |     +-- AD SET / AD GROUP (targeting, bid, placement)
  |     |     |
  |     |     +-- AD (creative, copy, CTA, destination URL)
  |     |     +-- AD (variant B for testing)
  |     |
  |     +-- AD SET / AD GROUP (different audience)
  |           |
  |           +-- AD
  |           +-- AD
  |
  +-- CAMPAIGN (different objective)
        |
        +-- ...
```

### 1.2 Campaign Objective Selection

```
AWARENESS OBJECTIVES
├── Brand awareness: Maximize impressions to target audience
├── Reach: Show ads to maximum unique people
├── Video views: Maximize video consumption
└── Best for: New brands, product launches, market entry

CONSIDERATION OBJECTIVES
├── Traffic: Drive clicks to website
├── Engagement: Maximize likes, comments, shares
├── App installs: Drive mobile app downloads
├── Lead generation: Collect leads within the platform
├── Messages: Start conversations (Messenger, WhatsApp, DMs)
└── Best for: Building interest, growing email lists, content promotion

CONVERSION OBJECTIVES
├── Conversions: Drive specific website actions (purchase, sign-up)
├── Catalog sales: Promote products from a product catalog
├── Store traffic: Drive visits to physical locations
└── Best for: Direct response, e-commerce, SaaS sign-ups

OBJECTIVE SELECTION MATRIX:
┌─────────────────────┬─────────────┬─────────────┬─────────────┐
│ Business Goal       │ Objective   │ KPI         │ Bid Strategy│
├─────────────────────┼─────────────┼─────────────┼─────────────┤
│ Build awareness     │ Reach       │ CPM, Reach  │ Lowest cost │
│ Drive website visits│ Traffic     │ CPC, CTR    │ Lowest CPC  │
│ Collect leads       │ Lead gen    │ CPL         │ Target CPA  │
│ Get purchases       │ Conversions │ ROAS, CPA   │ Target ROAS │
│ Promote content     │ Engagement  │ CPE         │ Lowest cost │
│ Install app         │ App install │ CPI         │ Target CPI  │
└─────────────────────┴─────────────┴─────────────┴─────────────┘
```

---

## 2. Google Ads

### 2.1 Google Ads Campaign Types

```
SEARCH CAMPAIGNS
├── How it works: Text ads shown on Google search results
├── Targeting: Keywords (user intent)
├── Best for: High-intent bottom-of-funnel traffic
├── Key metrics: CTR, CPC, conversion rate, quality score
├── Budget tip: Start with exact and phrase match keywords
└── Avoid: Broad match without negative keywords (waste)

PERFORMANCE MAX (PMAX)
├── How it works: AI-driven ads across all Google surfaces
├── Targeting: Audience signals + Google automation
├── Best for: E-commerce, lead gen with conversion data
├── Key metrics: ROAS, conversions, CPA
├── Budget tip: Needs 50+ conversions/month for optimization
└── Avoid: Launching without conversion tracking set up

DISPLAY CAMPAIGNS
├── How it works: Banner/image ads on Google Display Network
├── Targeting: Audiences, topics, placements
├── Best for: Retargeting, brand awareness
├── Key metrics: CPM, view-through conversions, reach
├── Budget tip: Use primarily for retargeting, not cold prospecting
└── Avoid: Broad targeting without placement exclusions

YOUTUBE VIDEO CAMPAIGNS
├── How it works: Video ads before/during/after YouTube videos
├── Types: Skippable in-stream, non-skippable, bumper, in-feed
├── Targeting: Demographics, interests, keywords, placements
├── Best for: Brand awareness, product education, retargeting
├── Key metrics: View rate, CPV, watch time, earned actions
├── Budget tip: Target specific channels/videos for efficiency
└── Avoid: Non-skippable for cold audiences (drives negative sentiment)

DEMAND GEN CAMPAIGNS
├── How it works: Visual ads on Discover, Gmail, YouTube
├── Targeting: Audiences (similar to social targeting)
├── Best for: Mid-funnel consideration, visual products
├── Key metrics: CTR, CPC, conversions
└── Budget tip: Use strong visual creatives (similar to social ads)
```

### 2.2 Google Ads Account Structure

```
RECOMMENDED ACCOUNT STRUCTURE
===============================

CAMPAIGN 1: Brand Search
├── Ad Group: Brand terms (company name + variations)
├── Match types: Exact + Phrase
├── Budget: Low (but always on -- protect brand from competitors)
└── Expected: High CTR (>10%), Low CPC, High conversion rate

CAMPAIGN 2: Non-Brand Search -- High Intent
├── Ad Group 1: [Product/service category 1]
│   ├── Keywords: "buy [product]", "[product] pricing", "[product] demo"
│   └── Ads: Feature-focused, pricing CTA
├── Ad Group 2: [Product/service category 2]
│   ├── Keywords: "[service] for [audience]", "best [service]"
│   └── Ads: Benefit-focused, social proof
└── Budget: Primary budget allocation (highest ROAS)

CAMPAIGN 3: Non-Brand Search -- Research Intent
├── Ad Group 1: Comparison/alternative searches
│   ├── Keywords: "[competitor] alternative", "[product] vs [product]"
│   └── Ads: Comparison landing pages
├── Ad Group 2: How-to/educational searches
│   ├── Keywords: "how to [solve problem]", "[problem] solution"
│   └── Ads: Content-first approach, lead magnet
└── Budget: Lower allocation (longer conversion path)

CAMPAIGN 4: Performance Max / Shopping
├── Asset groups by product category
├── Audience signals: Customer lists, website visitors, in-market
├── Creative: Product images, lifestyle images, video
└── Budget: Scale based on ROAS performance

CAMPAIGN 5: Retargeting (Display + YouTube)
├── Ad Group 1: Website visitors (7-30 days)
├── Ad Group 2: Cart/form abandoners (1-14 days)
├── Ad Group 3: Past customers (cross-sell/upsell)
└── Budget: 10-20% of total budget (high ROAS)

NEGATIVE KEYWORD STRATEGY:
├── Account-level negatives: free, cheap, jobs, salary, tutorial,
│   wikipedia, reddit, download, torrent, DIY
├── Campaign-level: Cross-campaign negatives to avoid cannibalization
└── Review search terms report weekly and add negatives
```

### 2.3 Google Ads Quality Score Optimization

```
QUALITY SCORE COMPONENTS (1-10 scale)
=======================================

EXPECTED CTR (weight: ~39%)
├── Improve by:
│   ├── Write compelling headlines with keywords
│   ├── Use ad extensions (sitelinks, callouts, structured snippets)
│   ├── Test multiple ad variations (RSAs with 15 headlines)
│   ├── Include numbers, percentages, and specific claims
│   └── Match ad copy tightly to keyword intent
└── Target: "Above average"

AD RELEVANCE (weight: ~22%)
├── Improve by:
│   ├── Group tightly themed keywords (5-15 per ad group)
│   ├── Include primary keyword in headlines
│   ├── Write ad copy that directly addresses the search intent
│   ├── Use dynamic keyword insertion where appropriate
│   └── Create separate ad groups for distinct themes
└── Target: "Above average"

LANDING PAGE EXPERIENCE (weight: ~39%)
├── Improve by:
│   ├── Match landing page content to ad promise
│   ├── Fast page load (<3 seconds)
│   ├── Mobile-optimized (responsive design)
│   ├── Clear, prominent CTA
│   ├── Original, valuable content
│   ├── Easy navigation (no dead ends)
│   └── HTTPS (SSL certificate)
└── Target: "Above average"

QUALITY SCORE IMPACT ON CPC:
├── QS 10: Pay ~50% less than average
├── QS 7-8: Pay ~10-20% less
├── QS 5-6: Pay average
├── QS 3-4: Pay ~25-50% more
└── QS 1-2: Pay ~200-400% more (or ads won't show)
```

### 2.4 Google Ads Responsive Search Ad Template

```
RESPONSIVE SEARCH AD (RSA) TEMPLATE
=====================================
(Provide 15 headlines and 4 descriptions; Google mixes and matches)

HEADLINES (max 30 characters each):

Keyword-focused (3-4):
  H1: "[Primary Keyword] Software"
  H2: "Best [Keyword] Solution"
  H3: "[Keyword] for [Audience]"
  H4: "Top-Rated [Keyword] Platform"

Benefit-focused (3-4):
  H5: "Save 10 Hours Per Week"
  H6: "Increase Revenue by 30%"
  H7: "Reduce Costs by 40%"
  H8: "Get Results in 14 Days"

CTA-focused (2-3):
  H9:  "Start Your Free Trial"
  H10: "Book a Demo Today"
  H11: "Get Started for Free"

Social proof (2-3):
  H12: "Trusted by 5,000+ Teams"
  H13: "4.8/5 Stars on G2"
  H14: "Award-Winning Platform"

Urgency/offer (1-2):
  H15: "Limited Time: 20% Off"

DESCRIPTIONS (max 90 characters each):
  D1: "Streamline your [process] with our all-in-one platform. Start your free trial today."
  D2: "Join 5,000+ businesses using [Product] to [key benefit]. No credit card required."
  D3: "See why [industry] teams choose [Product]. Book a personalized demo in minutes."
  D4: "[Product] helps you [outcome 1], [outcome 2], and [outcome 3]. Try it free."

PIN STRATEGY:
├── Pin brand name headline to Position 1 (always shows)
├── Pin CTA headline to Position 2 or 3
├── Leave remaining headlines unpinned (let Google optimize)
└── Pin at most 2-3 headlines; over-pinning limits optimization
```

---

## 3. Meta Ads (Facebook and Instagram)

### 3.1 Meta Ads Campaign Structure

```
RECOMMENDED CAMPAIGN STRUCTURE
================================

CAMPAIGN 1: PROSPECTING (Cold audiences)
├── Ad Set 1: Lookalike -- Customers (1%)
│   ├── Ad 1: Video testimonial
│   ├── Ad 2: Carousel -- product features
│   └── Ad 3: Static image -- bold claim
├── Ad Set 2: Lookalike -- Website visitors (1-3%)
│   ├── Ad 1: UGC-style video
│   ├── Ad 2: Infographic
│   └── Ad 3: Before/after
├── Ad Set 3: Interest-based targeting
│   ├── Ad 1: Problem-solution format
│   ├── Ad 2: Social proof focused
│   └── Ad 3: Offer/discount focused
└── Budget: 60-70% of total Meta budget

CAMPAIGN 2: RETARGETING (Warm audiences)
├── Ad Set 1: Website visitors (1-7 days)
│   ├── Ad 1: Product demo video
│   ├── Ad 2: Testimonial carousel
│   └── Ad 3: Limited-time offer
├── Ad Set 2: Website visitors (8-30 days)
│   ├── Ad 1: Case study
│   ├── Ad 2: FAQ-style ad
│   └── Ad 3: Comparison ad
├── Ad Set 3: Engaged with social (IG/FB, 30 days)
│   ├── Ad 1: Lead magnet offer
│   ├── Ad 2: Webinar/event invite
│   └── Ad 3: Free trial CTA
└── Budget: 20-30% of total Meta budget

CAMPAIGN 3: RETENTION / UPSELL (Existing customers)
├── Ad Set 1: Customer list (purchased but not upgraded)
│   ├── Ad 1: New feature announcement
│   └── Ad 2: Upgrade incentive
├── Ad Set 2: Customer list (at risk of churn)
│   ├── Ad 1: Re-engagement offer
│   └── Ad 2: Success story from similar customer
└── Budget: 10% of total Meta budget

EXCLUSION STRATEGY:
├── Prospecting campaigns: Exclude website visitors (30 days)
│   and existing customers
├── Retargeting campaigns: Exclude existing customers
├── Always exclude: Employees, existing converters (7-day window)
└── Purpose: Prevent audience overlap and wasted spend
```

### 3.2 Meta Ads Creative Best Practices

```
VIDEO AD FRAMEWORK (15-60 seconds)
====================================

STRUCTURE:
Second 0-3:   HOOK — Stop the scroll
              ├── Bold text overlay with surprising claim
              ├── Quick movement or visual disruption
              ├── "Stop scrolling if you [pain point]"
              └── Before/after flash preview

Second 3-15:  PROBLEM — Relate to the audience
              ├── "You know that feeling when..."
              ├── Show the frustration visually
              └── Build empathy

Second 15-40: SOLUTION — Show your product in action
              ├── Demo the key feature
              ├── Show real results or testimonials
              ├── Use screen recordings for SaaS
              └── Show transformation

Second 40-60: CTA — Tell them what to do
              ├── Clear verbal CTA
              ├── Text overlay with offer details
              ├── Urgency element (limited time, spots, etc.)
              └── End card with logo and link

TECHNICAL SPECS:
├── Aspect ratio: 9:16 (Stories/Reels), 1:1 (Feed), 4:5 (Feed optimal)
├── Resolution: 1080x1920 (vertical), 1080x1080 (square)
├── File size: Under 4GB (under 1GB recommended)
├── Captions: Always add (85% watch without sound)
├── Length: 15-30 seconds for cold audiences, 30-60 for retargeting
└── Thumbnail: Custom, not auto-generated

STATIC IMAGE AD FRAMEWORK:
├── Rule of thirds: Product/face top-right or center
├── Text overlay: Max 20% of image area (for best delivery)
├── Contrast: High contrast between text and background
├── Brand colors: Consistent but stand out in feed
├── CTA button: Visible in the image itself (not just the ad CTA)
├── Test: Photo vs illustration vs UGC-style
└── Size: 1080x1080 (square) or 1080x1350 (4:5 portrait)

CAROUSEL AD FRAMEWORK:
├── Slide 1: Hook/headline that compels swiping
├── Slides 2-4: Features, benefits, or steps
├── Slide 5: Social proof (testimonial, stats)
├── Slide 6: CTA slide with offer
├── Each slide: Self-contained but connected
├── Consistent visual style across all slides
└── 3-10 slides (5-6 is the sweet spot)
```

### 3.3 Meta Ads Audience Targeting

```
AUDIENCE TYPES
===============

CORE AUDIENCES (Interest/Demographic Targeting):
├── Demographics: Age, gender, location, language
├── Interests: Based on pages liked, content engaged with
├── Behaviors: Purchase behavior, device usage, travel
├── Connections: Page fans, app users, event attendees
└── Tip: Start broad (2-10M audience size), let Meta optimize

CUSTOM AUDIENCES (Your data):
├── Website visitors (pixel-based)
│   ├── All visitors (180 days max)
│   ├── Specific page visitors (e.g., pricing page)
│   ├── Time on site (top 25%)
│   └── Event-based (added to cart, initiated checkout)
├── Customer list (email/phone upload)
│   ├── All customers
│   ├── High-value customers (top 20% by LTV)
│   ├── Recent customers (last 90 days)
│   └── Churned customers
├── Engagement audiences
│   ├── Video viewers (25%, 50%, 75%, 95% watched)
│   ├── Lead form openers/submitters
│   ├── Instagram/Facebook profile engagers
│   └── Event attendees
└── App activity audiences

LOOKALIKE AUDIENCES (Meta finds similar people):
├── Source: Custom audience (best: high-value customers)
├── Size: 1% (most similar, smallest) to 10% (broader)
├── Country: Select target country
├── Best sources:
│   ├── Purchasers / converters (highest quality)
│   ├── High-LTV customers
│   ├── Email subscribers (engaged)
│   └── Video viewers (75%+ watch time)
├── Strategy:
│   ├── Test 1% first (highest quality)
│   ├── Expand to 1-3% if 1% is performing
│   ├── Use 3-5% for scale
│   └── 5-10% for broad awareness
└── Minimum source size: 100 people (1,000+ recommended)

ADVANTAGE+ AUDIENCE (Meta AI):
├── How it works: You provide suggestions, Meta finds the audience
├── Best for: Campaigns with 50+ weekly conversions
├── Input: Age, location, interests (as suggestions, not restrictions)
├── Advantage: Can find audiences you wouldn't have targeted
└── Caution: Monitor placement and audience reports for quality
```

---

## 4. LinkedIn Ads

### 4.1 LinkedIn Ads Campaign Structure

```
LINKEDIN CAMPAIGN STRUCTURE
=============================

CAMPAIGN 1: AWARENESS (Thought Leadership)
├── Objective: Brand awareness
├── Format: Single image or video ad
├── Targeting: Industry + seniority + company size
├── Content: Educational content, industry insights
├── CTA: Learn More
├── Budget: $20-50/day
└── KPI: CPM, engagement rate

CAMPAIGN 2: CONSIDERATION (Content Promotion)
├── Objective: Website visits or engagement
├── Format: Single image, carousel, or document ad
├── Targeting: Job function + skills + groups
├── Content: Blog posts, reports, webinars
├── CTA: Download, Register, Read More
├── Budget: $30-100/day
└── KPI: CPC, CTR, content downloads

CAMPAIGN 3: LEAD GENERATION
├── Objective: Lead generation (Lead Gen Forms)
├── Format: Single image or video + Lead Gen Form
├── Targeting: Decision-makers by title + industry
├── Content: Whitepapers, demos, consultations
├── CTA: Download Now, Book Demo, Get Quote
├── Budget: $50-200/day
└── KPI: CPL, lead quality, conversion to opportunity

CAMPAIGN 4: RETARGETING
├── Objective: Website conversions
├── Format: Single image or message ad (InMail)
├── Targeting: Website visitors, video viewers, engagement
├── Content: Case studies, testimonials, special offers
├── CTA: Start Trial, Schedule Call, Get Pricing
├── Budget: $20-50/day
└── KPI: CPA, conversion rate
```

### 4.2 LinkedIn Ads Targeting Options

```
LINKEDIN TARGETING DIMENSIONS
===============================

COMPANY ATTRIBUTES:
├── Company name (target specific accounts -- ABM)
├── Company industry (17 categories, 148 sub-categories)
├── Company size (1-10, 11-50, 51-200, 201-500, 501-1000, 1000+)
├── Company revenue ($1M-$10M, $10M-$100M, $100M+, etc.)
├── Company connections (1st-degree connections of employees)
├── Company followers (followers of specific LinkedIn pages)
└── Company growth rate (fast-growing companies)

MEMBER ATTRIBUTES:
├── Job title (specific titles)
├── Job function (25 functions: Marketing, Sales, IT, Finance, etc.)
├── Job seniority (Entry, Senior, Manager, Director, VP, CXO, Owner)
├── Skills (member-listed skills)
├── Groups (LinkedIn group membership)
├── Years of experience (1-2, 3-5, 6-10, 10+)
├── Education (degrees, fields of study, specific schools)
└── Member interests (inferred from activity)

MATCHED AUDIENCES:
├── Website retargeting (LinkedIn Insight Tag)
├── Contact list targeting (email upload)
├── Company list targeting (ABM account lists)
├── Lookalike audiences (from any matched audience)
├── Event audiences (LinkedIn Event attendees)
└── Lead Gen Form audiences (opened/submitted forms)

ABM (Account-Based Marketing) STRATEGY:
├── Upload target account list (company names/domains)
├── Layer with: Job function + seniority
├── Create account-specific ad copy when possible
├── Use Message Ads (InMail) for high-value accounts
├── Minimum audience size: 300 members (1,000+ recommended)
└── Budget: Higher CPC ($5-15) but higher deal values
```

### 4.3 LinkedIn Ad Copy Templates

```
SPONSORED CONTENT (Single Image):

PATTERN 1: Problem-Agitate-Solve
"[Audience role]s lose [X hours/dollars] every [time period] on [problem].

The worst part? [Agitate the pain point with specific scenario].

[Product] solves this by [key mechanism]. Here's how:
[Benefit 1]
[Benefit 2]
[Benefit 3]

[CTA]: [Action] → [Link with UTM]"

PATTERN 2: Data-Driven
"We analyzed [X] [data points] and found that [surprising insight].

The top [X]% of [audience] are doing [specific thing differently].

Our latest report breaks down:
- [Finding 1]
- [Finding 2]
- [Finding 3]

Download the full report → [Link]"

PATTERN 3: Social Proof
"[Customer name/company] [achieved specific result] in [timeframe]
using [Product].

Before: [Old situation with specific metric]
After: [New situation with specific metric]

'[Direct quote from customer]' — [Name, Title, Company]

See how they did it → [Link]"

MESSAGE AD (InMail) TEMPLATE:
Subject: "[First Name], [personalized question or statement]"

Body:
"Hi [First Name],

I noticed [relevant observation about their company/role].

[1-2 sentences about why you're reaching out, tied to their context].

We recently helped [similar company] achieve [specific result].

Would you be open to a [15-minute call / free assessment / demo]
to explore how [Product] could help [their company]?

[CTA button: Schedule a Call]

Best,
[Your name]
[Title, Company]"
```

---

## 5. Bidding Strategies

### 5.1 Bidding Strategy Selection

```
BIDDING STRATEGY MATRIX
=========================

AWARENESS / REACH:
├── Google: Target impression share, CPM bidding
├── Meta: Lowest cost (reach), or cost cap
├── LinkedIn: Maximum delivery
└── When to use: Brand campaigns, new market entry

TRAFFIC / CLICKS:
├── Google: Maximize clicks, manual CPC (with cap)
├── Meta: Lowest cost (link clicks)
├── LinkedIn: Maximum delivery, or manual CPC
└── When to use: Content promotion, website traffic campaigns

LEADS / CONVERSIONS:
├── Google: Target CPA, maximize conversions
├── Meta: Cost cap, or bid cap for volume control
├── LinkedIn: Maximum delivery with conversion tracking
└── When to use: Lead gen, sign-ups, demo requests

REVENUE / ROAS:
├── Google: Target ROAS, maximize conversion value
├── Meta: Minimum ROAS (bid strategy)
├── LinkedIn: Not available (use CPA proxy)
└── When to use: E-commerce, revenue-focused campaigns

BIDDING PROGRESSION:
Phase 1 (Learning): Start with lowest cost / maximize conversions
  ├── Goal: Collect 50+ conversions for algorithm learning
  ├── Duration: 1-2 weeks typically
  └── Budget: Generous enough to exit learning phase quickly

Phase 2 (Optimization): Switch to target CPA or target ROAS
  ├── Goal: Control costs while maintaining volume
  ├── Set targets based on Phase 1 actuals (start 10-20% above)
  └── Gradually tighten targets as performance stabilizes

Phase 3 (Scaling): Increase budget 20-30% per week
  ├── Goal: Grow volume without sacrificing efficiency
  ├── Monitor for diminishing returns
  └── If CPA rises >20%, pause scaling and optimize
```

### 5.2 Budget Allocation Framework

```
BUDGET ALLOCATION MODEL
=========================

TOTAL MONTHLY BUDGET: $[X]

CHANNEL ALLOCATION (starting point, adjust based on data):
┌──────────────┬─────────┬──────────┬─────────────────────────┐
│ Channel      │ % of    │ Monthly  │ Rationale               │
│              │ Budget  │ Spend    │                         │
├──────────────┼─────────┼──────────┼─────────────────────────┤
│ Google Search│ 35-45%  │ $[X]     │ High intent, proven ROI │
│ Meta (FB/IG) │ 25-35%  │ $[X]     │ Scale, prospecting      │
│ LinkedIn     │ 10-20%  │ $[X]     │ B2B targeting precision  │
│ Retargeting  │ 10-15%  │ $[X]     │ Highest ROAS channel    │
│ Experimental │ 5-10%   │ $[X]     │ TikTok, YouTube, etc.   │
└──────────────┴─────────┴──────────┴─────────────────────────┘

FUNNEL ALLOCATION:
├── Top of funnel (awareness): 20-30% of budget
├── Middle of funnel (consideration): 30-40% of budget
├── Bottom of funnel (conversion): 30-40% of budget
└── Retargeting: 10-15% of budget (cross-funnel)

70/20/10 RULE:
├── 70% — Proven campaigns (scale what works)
├── 20% — Optimization experiments (improve what exists)
└── 10% — New experiments (test new ideas, channels, audiences)

BUDGET PACING:
├── Daily: Total monthly / days in month
├── Monitor: Check pacing every 2-3 days
├── Adjust: Front-load if seasonal, even-pace for evergreen
├── Reserve: Hold 10% for end-of-month opportunities
└── Overspend: OK up to 10% daily, Google adjusts monthly
```

---

## 6. Conversion Tracking

### 6.1 Conversion Tracking Setup Checklist

```
GOOGLE ADS CONVERSION TRACKING:
[ ] Google Ads conversion tag installed (via GTM recommended)
[ ] Primary conversions marked (purchase, lead, sign-up)
[ ] Secondary conversions set (page view, engagement)
[ ] Google Analytics 4 linked to Google Ads
[ ] Import GA4 conversions to Google Ads
[ ] Enhanced conversions enabled (first-party data matching)
[ ] Offline conversion import configured (CRM data)
[ ] Conversion value set (static or dynamic)
[ ] Conversion window configured (7/14/30/90 days)
[ ] Phone call tracking set up (if relevant)
[ ] Test conversions firing correctly (Tag Assistant)

META ADS CONVERSION TRACKING:
[ ] Meta Pixel installed on all pages
[ ] Conversions API (CAPI) implemented (server-side)
[ ] Standard events configured:
│   ├── PageView, ViewContent, AddToCart
│   ├── InitiateCheckout, Purchase
│   ├── Lead, CompleteRegistration
│   └── Search, Contact, Subscribe
[ ] Custom conversions created for non-standard events
[ ] Event Match Quality score > 6.0 (check in Events Manager)
[ ] Aggregated Event Measurement configured (iOS 14+)
[ ] Domain verified in Business Manager
[ ] Test events with Meta Pixel Helper extension
[ ] Value optimization enabled for purchase events

LINKEDIN CONVERSION TRACKING:
[ ] LinkedIn Insight Tag installed
[ ] Conversion actions created:
│   ├── URL-based (thank-you page visits)
│   ├── Event-specific (custom events)
│   └── Offline conversions (CSV upload)
[ ] Attribution window set (1/7/30/90 days)
[ ] Revenue tracking configured
[ ] Test with LinkedIn Tag Validator

CROSS-PLATFORM:
[ ] UTM parameters on all ad destination URLs
[ ] Google Tag Manager (GTM) centrally managing all tags
[ ] Cookie consent implemented (GDPR/CCPA compliant)
[ ] Cross-domain tracking configured if needed
[ ] Deduplication logic for multi-platform attribution
[ ] Regular audit cadence (monthly tag health check)
```

### 6.2 Conversion Value Framework

```
ASSIGNING CONVERSION VALUES
=============================

DIRECT VALUE (known):
├── E-commerce purchase: Actual transaction value
├── Subscription: Monthly/annual subscription price
├── Service booking: Service price
└── Implementation: Pass dynamic value via data layer

ESTIMATED VALUE (calculated):
├── Lead form: Average deal value x close rate
│   Example: $10,000 avg deal x 10% close rate = $1,000 per lead
├── Demo request: Average deal value x demo-to-close rate
│   Example: $10,000 x 25% = $2,500 per demo
├── Free trial: Average conversion value x trial-to-paid rate
│   Example: $1,200 annual x 15% = $180 per trial
├── Email sign-up: LTV x email-to-customer rate
│   Example: $5,000 LTV x 2% = $100 per email sign-up
└── Content download: Pipeline value x content-to-lead rate
    Example: $1,000 lead value x 5% = $50 per download

MICRO-CONVERSION VALUES:
├── Pricing page view: $5-20 (high intent signal)
├── Case study view: $2-10 (consideration signal)
├── Blog engagement (3+ min): $1-5 (awareness signal)
├── Video view (50%+): $0.50-2 (awareness signal)
└── Purpose: Feed data to smart bidding algorithms
```

---

## 7. Landing Page Optimization

### 7.1 Landing Page Framework

```
HIGH-CONVERTING LANDING PAGE STRUCTURE
========================================

ABOVE THE FOLD (visible without scrolling):
├── Headline: Clear value proposition (matches ad promise)
├── Subheadline: Supporting detail or clarification
├── Hero image/video: Product in action or outcome visual
├── CTA button: Contrasting color, action-oriented text
├── Trust signals: Logos, ratings, certifications
└── No navigation menu (reduce exit points)

BELOW THE FOLD:
├── Section 1: Problem statement (empathize with pain)
├── Section 2: Solution overview (how you solve it)
├── Section 3: Key features/benefits (3-5, with icons)
├── Section 4: Social proof (testimonials, case studies, numbers)
├── Section 5: How it works (3-step process)
├── Section 6: FAQ (overcome common objections)
├── Section 7: Final CTA (repeat primary offer)
└── Footer: Minimal -- privacy policy, terms, contact

LANDING PAGE CHECKLIST:
[ ] Headline matches ad copy (message match)
[ ] Single, clear CTA (one action per page)
[ ] Page loads in < 3 seconds (mobile and desktop)
[ ] Mobile-responsive design
[ ] Form fields minimized (ask only what you need)
[ ] Trust signals visible (logos, reviews, security badges)
[ ] No competing navigation or links
[ ] Social proof near CTA (testimonial or stat)
[ ] Clear benefit statements (not just features)
[ ] Privacy policy linked near form
[ ] Thank-you page with next steps (not just "thanks")
[ ] Retargeting pixel fires on visit and conversion
[ ] A/B test running (always be testing)
```

### 7.2 Landing Page A/B Test Priority

```
WHAT TO TEST (in order of impact):

1. HEADLINE (highest impact)
   ├── Benefit-focused vs feature-focused
   ├── Question vs statement
   ├── Specific number vs general claim
   └── Short vs long

2. CTA (high impact)
   ├── Button text ("Start Free Trial" vs "Get Started" vs "See Demo")
   ├── Button color (test 2-3 contrasting colors)
   ├── Button placement (above fold, floating, multiple)
   └── Single CTA vs two options

3. SOCIAL PROOF (high impact)
   ├── Testimonials with photos vs without
   ├── Customer logos vs review stars
   ├── Case study numbers vs quotes
   └── Video testimonial vs text

4. FORM LENGTH (medium impact)
   ├── 3 fields vs 5 fields vs 7 fields
   ├── Single page vs multi-step form
   ├── With vs without phone number field
   └── Inline validation vs submit validation

5. PAGE LAYOUT (medium impact)
   ├── Long-form vs short-form
   ├── Video hero vs image hero
   ├── Left-aligned form vs centered
   └── With pricing vs without pricing

6. OFFER (highest impact when different)
   ├── Free trial vs free demo
   ├── Discount percentage vs dollar amount
   ├── Limited time vs always available
   └── Lead magnet type (guide vs template vs checklist)
```

---

## 8. Retargeting Strategies

### 8.1 Retargeting Audience Segments

```
RETARGETING FUNNEL
====================

SEGMENT 1: ALL WEBSITE VISITORS (Broad)
├── Window: 30-180 days
├── Exclude: Converters
├── Message: Brand reinforcement, value proposition
├── Frequency cap: 3-5 impressions per week
├── Budget allocation: 30% of retargeting budget
└── Creative: Educational content, brand video

SEGMENT 2: HIGH-INTENT PAGE VISITORS
├── Pages: Pricing, features, comparison, demo request
├── Window: 7-30 days
├── Message: Address objections, show social proof
├── Frequency cap: 5-7 impressions per week
├── Budget allocation: 30% of retargeting budget
└── Creative: Testimonials, case studies, limited-time offer

SEGMENT 3: CART/FORM ABANDONERS
├── Trigger: Started checkout/form but did not complete
├── Window: 1-14 days
├── Message: Reminder + incentive (discount, free shipping)
├── Frequency cap: 7-10 impressions per week
├── Budget allocation: 25% of retargeting budget
└── Creative: Product image, urgency messaging, offer

SEGMENT 4: PAST CUSTOMERS (Cross-sell/Upsell)
├── Source: Customer list upload
├── Window: 30-365 days since purchase
├── Message: Complementary products, upgrade offers
├── Frequency cap: 3-5 impressions per week
├── Budget allocation: 15% of retargeting budget
└── Creative: New features, loyalty offers, referral program

RETARGETING SEQUENCING:
Day 1-3:   "Hey, you visited [Product]. Here's what makes it special."
Day 4-7:   "See how [Customer] achieved [result] with [Product]."
Day 8-14:  "Still thinking about it? Here's a special offer for you."
Day 15-30: "Last chance: [Offer] expires soon."
Day 30+:   Move to broad awareness or remove from retargeting
```

### 8.2 Dynamic Retargeting Setup

```
DYNAMIC RETARGETING (E-commerce / Catalog)
=============================================

REQUIREMENTS:
├── Product catalog/feed uploaded to ad platform
├── Pixel/tracking configured for product views
├── Dynamic creative templates designed
├── Product IDs passed via pixel events
└── Catalog synced with inventory (avoid promoting out-of-stock)

PRODUCT FEED FORMAT:
├── Required fields: ID, title, description, link, image_link, price
├── Recommended: sale_price, brand, category, availability
├── Optimization: High-quality images, keyword-rich titles
├── Sync: Daily or real-time feed updates
└── Size: 1080x1080 minimum image resolution

DYNAMIC AD TEMPLATES:
├── Single product: Show the exact product viewed
├── Multi-product: Show viewed product + similar items
├── Collection: Group by category or style
├── Carousel: Multiple viewed products in sequence
└── Personalization: Include user's name if available (Meta)
```

---

## 9. Ad Copy Frameworks

### 9.1 Proven Ad Copy Formulas

```
PAS (Problem-Agitate-Solve):
"Tired of [problem]? Every [time period], [specific pain with numbers].
[Product] eliminates [problem] by [mechanism]. [CTA]."

Example:
"Tired of manual expense reports? Teams waste 5+ hours per month
chasing receipts. [Product] auto-captures expenses from any receipt
in seconds. Start your free trial."

AIDA (Attention-Interest-Desire-Action):
Attention: [Bold claim or statistic]
Interest: [How/why this matters to the reader]
Desire: [Paint the picture of the outcome]
Action: [Clear CTA]

Example:
"Companies using [Product] close deals 40% faster.
Our AI analyzes your pipeline and prioritizes the hottest leads.
Imagine knowing exactly which prospect to call next.
Book a demo today."

BAB (Before-After-Bridge):
Before: [Current painful state]
After: [Desired future state]
Bridge: [How your product gets them there]

Example:
"Before: Spending hours building reports in spreadsheets.
After: Real-time dashboards that update automatically.
Bridge: [Product] connects to your data and creates reports in minutes.
Try it free."

4U FORMULA (Useful, Urgent, Unique, Ultra-specific):
"[Specific benefit] in [specific timeframe] with [unique method].
[Urgency element]. [CTA]."

Example:
"Reduce your cloud costs by 30% in 14 days with our AI optimizer.
Offer ends Friday. Start your free audit."

SOCIAL PROOF FORMULA:
"[X] [audience type] use [Product] to [outcome].
'[Direct quote from customer]' — [Name, Title]
[CTA]: Join them today."

Example:
"5,000+ marketing teams use [Product] to double their content output.
'It cut our production time in half.' -- Sarah Chen, VP Marketing
Start your free trial today."
```

### 9.2 Ad Copy Checklist

```
AD COPY REVIEW CHECKLIST
==========================

RELEVANCE:
[ ] Matches the search intent or audience interest
[ ] Headline directly addresses the audience's need
[ ] Landing page delivers on the ad's promise
[ ] Keywords included naturally (for search ads)

CLARITY:
[ ] Benefit is clear within 3 seconds
[ ] No jargon or ambiguous language
[ ] Specific numbers/claims over vague statements
[ ] Single focus (one message per ad)

PERSUASION:
[ ] Includes social proof (numbers, names, ratings)
[ ] Addresses a specific pain point
[ ] Creates urgency or scarcity (when genuine)
[ ] Differentiates from competitors

CTA:
[ ] Clear action verb (Start, Get, Book, Download, Try)
[ ] Specific outcome ("Get Your Free Report" vs "Learn More")
[ ] Low friction (free, no credit card, instant access)
[ ] Matches the landing page action

COMPLIANCE:
[ ] No misleading claims or exaggerations
[ ] Disclaimers included where required
[ ] Follows platform-specific ad policies
[ ] Competitive claims substantiated
[ ] Financial/health claims have proper disclaimers
```

---

## 10. ROAS Optimization

### 10.1 ROAS Optimization Framework

```
ROAS DIAGNOSTIC FRAMEWORK
===========================

IF ROAS IS TOO LOW:

CHECK 1: Targeting (are you reaching the right people?)
├── Review audience demographics report
├── Check search terms for irrelevant queries
├── Narrow targeting (remove broad interests)
├── Exclude low-performing demographics/placements
└── Test lookalike audiences from best customers

CHECK 2: Creative (are ads compelling?)
├── Review CTR -- low CTR means ads aren't resonating
├── Test new ad formats (video, carousel, UGC)
├── Refresh creative every 2-4 weeks (ad fatigue)
├── A/B test headlines and images
└── Ensure message matches landing page

CHECK 3: Landing page (are visitors converting?)
├── Review landing page conversion rate
├── Check page load speed (<3 seconds)
├── Simplify form (fewer fields = more conversions)
├── Add trust signals (testimonials, logos, guarantees)
├── Test different offers (free trial vs demo vs discount)
└── Ensure mobile optimization

CHECK 4: Bidding (are you paying the right price?)
├── Compare CPC/CPM to benchmarks
├── Adjust bid strategy (manual vs automated)
├── Set bid caps if costs are escalating
├── Test dayparting (show ads only during peak hours)
└── Review quality score (Google) or relevance score (Meta)

CHECK 5: Funnel (are leads converting to revenue?)
├── Check lead quality with sales team
├── Review lead-to-opportunity conversion rate
├── Analyze time-to-conversion
├── Implement lead scoring
└── Align sales follow-up process with lead intent

ROAS OPTIMIZATION LEVERS (ranked by impact):
1. Improve conversion rate (landing page CRO)
2. Increase average order value (upsells, bundles)
3. Reduce CPC (better quality score, targeting)
4. Improve lead quality (better targeting, qualification)
5. Optimize bid strategy (smart bidding with enough data)
6. Reduce wasted spend (negative keywords, exclusions)
```

### 10.2 Campaign Scaling Playbook

```
SCALING CAMPAIGNS THAT WORK
==============================

RULE 1: Validate before scaling
├── Minimum data: 50+ conversions at target CPA/ROAS
├── Stable performance for 7+ days
├── Consistent across weekdays and weekends
└── Profitable after all costs (not just ad spend)

RULE 2: Scale gradually
├── Increase budget by 20-30% per week (not 2x overnight)
├── Google: Can handle larger increases (50%+ sometimes)
├── Meta: Sensitive to budget changes (resets learning phase)
├── LinkedIn: Less sensitive but still gradual
└── Monitor CPA/ROAS for 3-5 days after each increase

RULE 3: Horizontal scaling (new audiences, not just more budget)
├── Test new lookalike audiences (from different seed lists)
├── Expand geographic targeting
├── Test new interest/demographic segments
├── Launch on new platforms
├── Create new ad formats (video if only using static)
└── Test new landing pages for different segments

RULE 4: Know when to stop
├── CPA increases >30% despite optimization: plateau reached
├── Frequency >3 (Meta) or impression share >80% (Google): saturated
├── Diminishing marginal returns: track incremental ROAS
├── Audience overlap >30% between ad sets: consolidate
└── Creative fatigue: CTR declining week-over-week

SCALING BUDGET TRACKER:
┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│ Week     │ Budget   │ Spend    │ Conv.    │ CPA      │ ROAS     │
├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│ Week 1   │ $500     │ $480     │ 24       │ $20      │ 4.2x     │
│ Week 2   │ $650     │ $630     │ 30       │ $21      │ 4.0x     │
│ Week 3   │ $850     │ $820     │ 37       │ $22      │ 3.8x     │
│ Week 4   │ $1,100   │ $1,050   │ 44       │ $24      │ 3.5x     │
│ Week 5   │ $1,100   │ $1,080   │ 42       │ $26      │ 3.2x     │
│          │ (held)   │          │          │ (rising) │ (falling)│
│ Action:  │ Optimize before scaling further                      │
└──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘
```

---

## 11. Platform-Specific Compliance

### 11.1 Ad Policy Quick Reference

```
GOOGLE ADS POLICIES:
├── Prohibited: Counterfeit goods, dangerous products, hate content
├── Restricted: Alcohol, gambling, healthcare, financial services
├── Editorial: No excessive capitalization, punctuation, or symbols
├── Destination: Landing page must work, match ad content, no malware
├── Personalization: No targeting by sensitive categories (health, race)
├── Trademark: Can use competitor names in ad text (varies by region)
└── Housing/employment/credit: Special restrictions (US)

META ADS POLICIES:
├── Prohibited: Illegal products, tobacco, weapons, MLM, payday loans
├── Restricted: Alcohol, dating, gambling, pharmacy, supplements
├── Text in images: No limit but <20% text recommended for delivery
├── Before/after: Not allowed in health/fitness ads
├── Personal attributes: Cannot assert personal characteristics
│   (e.g., "Are you overweight?" is not allowed)
├── Discrimination: No targeting by race, religion, sexual orientation
│   for housing, employment, or credit ads
├── Political ads: Requires authorization and disclaimers
└── Crypto/financial: Requires prior written permission

LINKEDIN ADS POLICIES:
├── Professional tone required (no sensationalism)
├── Accuracy: Claims must be substantiated
├── Prohibited: Tobacco, weapons, adult content, payday loans
├── Restricted: Alcohol, gambling, healthcare
├── B2B focus: Consumer-oriented ads may be rejected
├── Targeting: Cannot discriminate in employment ads
├── InMail: Must be relevant to professional context
└── Landing page: Must match ad content, no auto-downloads

COMPLIANCE CHECKLIST:
[ ] Ad claims are accurate and substantiated
[ ] Required disclaimers included (financial, health, etc.)
[ ] Landing page matches ad content
[ ] Privacy policy accessible on landing page
[ ] Age/geo restrictions applied for regulated products
[ ] Trademark usage approved (if using competitor names)
[ ] No discriminatory targeting (especially housing/employment/credit)
[ ] Ad creative follows platform editorial guidelines
[ ] Industry-specific licenses/approvals obtained if required
```

---

## 12. Campaign Performance Report Template

```
PAID ADVERTISING PERFORMANCE REPORT
=====================================
Period: [Date range]
Total spend: $[X]
Prepared by: [Name]

EXECUTIVE SUMMARY:
[2-3 sentences: Overall performance, key wins, concerns]

CHANNEL PERFORMANCE OVERVIEW:
┌──────────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│ Channel      │ Spend    │ Impress. │ Clicks   │ Conv.    │ ROAS     │
├──────────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│ Google Search│ $[X]     │ [X]      │ [X]      │ [X]      │ [X]x     │
│ Google PMax  │ $[X]     │ [X]      │ [X]      │ [X]      │ [X]x     │
│ Meta (FB/IG) │ $[X]     │ [X]      │ [X]      │ [X]      │ [X]x     │
│ LinkedIn     │ $[X]     │ [X]      │ [X]      │ [X]      │ [X]x     │
│ Retargeting  │ $[X]     │ [X]      │ [X]      │ [X]      │ [X]x     │
├──────────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│ TOTAL        │ $[X]     │ [X]      │ [X]      │ [X]      │ [X]x     │
└──────────────┴──────────┴──────────┴──────────┴──────────┴──────────┘

BUDGET PACING:
├── Planned spend: $[X]
├── Actual spend: $[X] ([X]% of plan)
├── Remaining budget: $[X]
└── Projected month-end spend: $[X]

TOP PERFORMING CAMPAIGNS:
1. [Campaign name] — ROAS [X]x, [X] conversions at $[X] CPA
2. [Campaign name] — ROAS [X]x, [X] conversions at $[X] CPA
3. [Campaign name] — ROAS [X]x, [X] conversions at $[X] CPA

UNDERPERFORMING CAMPAIGNS:
1. [Campaign name] — ROAS [X]x, Issue: [diagnosis], Action: [plan]
2. [Campaign name] — ROAS [X]x, Issue: [diagnosis], Action: [plan]

CREATIVE PERFORMANCE:
├── Top creative: [Description] — CTR [X]%, Conv rate [X]%
├── Worst creative: [Description] — CTR [X]%, Conv rate [X]%
├── Creative refresh needed: [Yes/No, which campaigns]
└── New creatives tested this period: [X]

AUDIENCE INSIGHTS:
├── Best performing audience: [Description, metrics]
├── Worst performing audience: [Description, metrics]
├── New audience tests: [Results]
└── Audience overlap check: [Any issues]

RECOMMENDATIONS:
1. [Recommendation with expected impact]
2. [Recommendation with expected impact]
3. [Recommendation with expected impact]

NEXT PERIOD PLAN:
├── Budget: $[X] (change from this period: [+/-$X])
├── Key tests: [List 2-3 tests planned]
├── New campaigns: [Any new launches]
└── Optimization focus: [Top priorities]
```

---

## 13. TikTok and Emerging Platform Ads

### 13.1 TikTok Ads Structure

```
TIKTOK ADS CAMPAIGN STRUCTURE
===============================

CAMPAIGN 1: SPARK ADS (Boosted Organic)
├── Objective: Traffic or conversions
├── Format: Boost top-performing organic TikToks
├── Targeting: Broad (let algorithm optimize)
├── Budget: $20-50/day
├── Why: Native feel, higher engagement than standard ads
└── Best for: Content that already proved itself organically

CAMPAIGN 2: IN-FEED ADS (Cold Prospecting)
├── Objective: Conversions or traffic
├── Format: UGC-style video ads (look native)
├── Targeting: Interest + behavior based
├── Budget: $50-100/day
├── Creative tips:
│   ├── Film on phone (polished ads underperform)
│   ├── Use trending sounds
│   ├── Hook in first 1-2 seconds
│   ├── Include text overlay (watch without sound)
│   └── 15-30 seconds optimal length
└── Best for: Scaling beyond organic reach

CAMPAIGN 3: RETARGETING
├── Objective: Conversions
├── Format: Product-focused or testimonial video
├── Targeting: Website visitors, video viewers (50%+)
├── Budget: $15-30/day
└── Best for: Converting warm audiences

TIKTOK CREATIVE BEST PRACTICES:
├── Do NOT make ads that look like ads
├── Use creators/UGC style (outperforms brand-produced 2:1)
├── Test 3-5 creatives per ad group (high creative turnover)
├── Refresh creatives every 7-14 days (fatigue is fast)
├── Use TikTok Creative Center for inspiration
├── Leverage trending sounds and formats
└── Vertical video only (9:16, 1080x1920)
```

### 13.2 Emerging Platform Considerations

```
REDDIT ADS:
├── Targeting: Subreddit targeting (interest communities)
├── Formats: Promoted posts, video, carousel
├── Tone: Must feel authentic -- Redditors reject overt ads
├── Best for: Niche B2B, developer tools, gaming, tech
├── CPMs: Low ($2-5), but conversion requires native content
└── Tip: Participate in subreddits before advertising

PINTEREST ADS:
├── Targeting: Keywords + interests + demographics
├── Formats: Standard pin, video pin, carousel, shopping
├── Audience: 80% female, high purchase intent
├── Best for: E-commerce, home, food, fashion, wedding
├── CPCs: Competitive ($0.50-1.50)
└── Tip: Vertical images (2:3 ratio), text overlay, lifestyle imagery

SPOTIFY ADS:
├── Targeting: Demographics, interests, playlists, genres
├── Formats: Audio ads (15-30 sec), video, display
├── Best for: Brand awareness, local businesses, events
├── CPMs: $15-25 (audio), $20-30 (video)
└── Tip: Conversational tone, clear CTA, companion display banner

CONNECTED TV (CTV) / OTT:
├── Platforms: Hulu, Roku, Amazon Fire TV, YouTube TV
├── Targeting: Demographics, interests, purchase data
├── Formats: 15-30 second non-skippable video
├── Best for: Brand awareness at scale, local targeting
├── CPMs: $20-40
└── Tip: Repurpose YouTube video ads, add QR codes for response
```
