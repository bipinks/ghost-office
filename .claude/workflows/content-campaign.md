# Content Campaign Workflow

## Overview
End-to-end workflow for planning and executing a content or marketing campaign, from strategy definition through performance analysis.

## Trigger
- Business goal requires content-driven growth (lead generation, brand awareness, product launch)
- New product feature needs marketing support
- Quarterly content planning cycle
- Command: `/launch-content-campaign`

## Workflow Diagram
```
[Strategy]──→[Design + Content Creation]──→[SEO Optimization]──→[Distribution]──→[Analytics]
     │           ┌────────┴────────┐              │                    │               │
  Content     UI/UX         Content            Content           Social Media     Social Media
  Strategist  Designer      Strategist +       Strategist        Manager          Manager
                            Prompt Engineer
```

## Phases

### Phase 1: Strategy (Sequential)
**Agent**: content-strategist
**Actions**:
1. Define campaign goals with measurable KPIs (traffic, leads, signups, revenue)
2. Identify target audience personas and their content needs
3. Conduct content audit of existing assets relevant to the campaign
4. Define content pillars and topic clusters aligned with business objectives
5. Perform competitive content analysis to find gaps and opportunities
6. Map content to the buyer journey (awareness, consideration, decision)
7. Create a content calendar with topics, formats, channels, and deadlines
8. Define brand voice and tone guidelines for the campaign
**Output**: Campaign strategy document with goals, audience personas, content calendar, and KPI targets
**Gate**: Strategy approval required before design and content creation begin

### Phase 2: Design (Parallel with Phase 3)
**Agent**: ui-ux-designer
**Actions**:
1. Create visual identity for the campaign (color palette, typography, imagery style)
2. Design social media graphic templates (LinkedIn, Twitter, Instagram formats)
3. Build HTML email templates (mobile-responsive, single-column layout)
4. Design blog post featured images and inline graphics
5. Create landing page mockups for campaign CTAs
6. Prepare ad creative assets (display, social, retargeting)
7. Export all assets in required formats and sizes per platform
**Output**: Complete visual asset library with templates for all campaign channels

### Phase 3: Content Creation (Parallel with Phase 2)
**Agents**: content-strategist, prompt-engineer (run in parallel by content type)

#### Blog and Long-Form Track (content-strategist)
1. Write SEO content briefs for each blog post (keyword, intent, outline, CTA)
2. Draft blog posts following brand voice guidelines
3. Write pillar page content and supporting cluster articles
4. Create case studies with customer success metrics
5. Write landing page copy using conversion frameworks (AIDA, PAS, BAB)
**Output**: Draft blog posts, pillar pages, case studies, and landing page copy

#### Email and Short-Form Track (content-strategist + prompt-engineer)
1. Write email sequences (welcome, nurture, re-engagement, product update)
2. Craft email subject lines and preview text (A/B variants)
3. Write social media posts tailored to each platform
4. Draft ad copy for paid campaigns (headlines, descriptions, CTAs)
5. Write microcopy for in-app announcements and notifications
**Output**: Draft email sequences, social posts, ad copy, and microcopy

**Gate**: All content reviewed for accuracy, brand voice, and CTA alignment before SEO optimization

### Phase 4: SEO Optimization (Sequential after Phases 2 and 3)
**Agent**: content-strategist
**Actions**:
1. Perform keyword research for each content piece (volume, difficulty, intent)
2. Optimize title tags (50-60 characters, primary keyword near front)
3. Write meta descriptions (150-160 characters, clear value proposition and CTA)
4. Structure heading hierarchy (H1 with primary keyword, H2s with secondary keywords)
5. Add internal links (minimum 2-3 per page, descriptive anchor text)
6. Optimize images (alt text with keywords, WebP format, compression)
7. Implement schema markup (Article, FAQ, HowTo, BreadcrumbList as applicable)
8. Validate technical SEO (canonical tags, robots directives, sitemap inclusion)
9. Create or update the keyword map to avoid cannibalization
**Output**: SEO-optimized content ready for publishing, keyword map updated, schema markup implemented
**Gate**: On-page SEO checklist passed for every content piece before distribution

### Phase 5: Distribution (Sequential after Phase 4)
**Agent**: social-media-manager
**Actions**:
1. Publish blog posts and landing pages with correct meta tags and UTM parameters
2. Schedule social media posts across platforms (LinkedIn, Twitter, Instagram, etc.)
3. Set up and send email campaigns with proper segmentation and personalization
4. Launch paid ad campaigns with targeting and budget allocation
5. Syndicate content to relevant third-party platforms
6. Coordinate internal distribution (Slack, team newsletters, sales enablement)
7. Execute link-building outreach for pillar content
**Output**: All content published and distributed across channels with UTM tracking in place

### Phase 6: Analytics (Sequential, ongoing after distribution)
**Agent**: social-media-manager
**Actions**:
1. Track campaign KPIs against targets (organic traffic, rankings, conversions, email metrics)
2. Monitor content performance at 7, 30, and 90 days post-publish
3. Analyze email campaign metrics (open rate, click rate, unsubscribe rate)
4. Review social media engagement (reach, impressions, clicks, shares)
5. Measure paid campaign ROI (CPC, CPA, ROAS)
6. Identify top-performing and underperforming content
7. Generate performance report with recommendations for iteration
8. Feed insights back to content-strategist for strategy refinement
**Output**: Campaign performance report with actionable recommendations

## Parallel Execution Summary

```
Phase 1 (Strategy)
     |
     | [Gate: Strategy approved]
     |
     +--→ Phase 2 (Design)            ← runs in parallel
     +--→ Phase 3 (Content Creation)   ← runs in parallel
     |
     | [Gate: Content reviewed and approved]
     |
Phase 4 (SEO Optimization)
     |
     | [Gate: SEO checklist passed]
     |
Phase 5 (Distribution)
     |
Phase 6 (Analytics)  ← ongoing, reports at 7/30/90 days
```

## Error Handling

| Error | Recovery |
|-------|----------|
| Strategy goals are unclear or unmeasurable | Return to Phase 1, redefine KPIs with stakeholders |
| Design assets do not match brand guidelines | Return to Phase 2, revise with brand feedback |
| Content fails editorial review | Return to Phase 3, revise based on feedback |
| Keyword cannibalization detected | Return to Phase 4, reassign keywords across pages |
| Email deliverability issues | Pause distribution, check SPF/DKIM/DMARC, warm IP if needed |
| Campaign underperforms at 30-day review | Analyze data, iterate on content or distribution strategy |

## Success Criteria

| Metric | Target | Measurement |
|--------|--------|-------------|
| Organic traffic increase | +20% within 90 days | Google Analytics |
| Target keyword rankings | Top 10 within 90 days | Search Console |
| Email open rate | > 20% | Email platform |
| Email click rate | > 2.5% | Email platform |
| Content conversion rate | > 1% | Analytics + CRM |
| Social engagement rate | > 2% | Social analytics |
| Campaign ROI | Positive within 6 months | Revenue attribution |

## Logging
Every phase logs:
- Agent name and action
- Start and end time
- Content pieces created or modified
- Assets delivered (files, URLs)
- KPI snapshots at each milestone
- Review feedback and revisions
- Distribution channels and UTM parameters used
