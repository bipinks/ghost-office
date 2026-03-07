---
name: email-marketing
description: Use when planning email campaigns, building automation flows, optimizing deliverability, writing email sequences, segmenting audiences, or analyzing email performance. Covers campaign strategy, list management, automation (welcome, nurture, re-engagement, abandoned cart), A/B testing, email design, compliance (CAN-SPAM, GDPR), and analytics.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Email Marketing — Campaigns, Automation & Deliverability

## 1. Email Campaign Strategy

### Campaign Types and When to Use Them

```
EMAIL CAMPAIGN TYPES
=====================

TRANSACTIONAL (triggered by user action — highest priority)
  - Account confirmation, password reset
  - Order confirmation, receipts
  - Invoice notifications, payment confirmations
  - Delivery rate target: 99%+
  - Note: These are not marketing emails. They require separate sending
    infrastructure and are exempt from unsubscribe requirements.

AUTOMATED/LIFECYCLE (triggered by behavior or time — high priority)
  - Welcome/onboarding sequence
  - Nurture sequences
  - Re-engagement campaigns
  - Abandoned cart/process reminders
  - Milestone celebrations (1 year anniversary, usage milestones)

BROADCAST (sent to a segment at a scheduled time)
  - Newsletter (weekly/biweekly/monthly)
  - Product updates and feature announcements
  - Promotional offers
  - Event invitations
  - Seasonal campaigns

OPERATIONAL (system-driven, informational)
  - Maintenance notifications
  - Policy changes
  - Security alerts
  - Terms of service updates
```

### Campaign Planning Template

```
EMAIL CAMPAIGN BRIEF
=====================
Campaign name:      [Name]
Type:               Broadcast / Automated / Transactional
Goal:               [Specific, measurable goal]
Audience segment:   [Who receives this — see segmentation section]
Send date/trigger:  [Date or trigger event]
Sender name:        [Name <email@domain.com>]
Subject line:       [Primary] / [A/B variant]
Preview text:       [Complement the subject, not repeat it]
Primary CTA:        [Button text and destination URL]
Success metrics:    [Open rate, click rate, conversion target]
UTM parameters:     utm_source=email&utm_medium=[campaign type]&utm_campaign=[name]

CONTENT OUTLINE
- Header: [Brand header or hero image]
- Opening: [1-2 sentences — hook]
- Body: [Key message — 3-5 sentences or bullet points]
- CTA: [Primary action]
- Footer: [Unsubscribe, address, social links]
```

### Email Frequency Guidelines

```
SEND FREQUENCY BY TYPE
========================
| Campaign type     | Frequency          | Risk if too frequent        |
|-------------------|--------------------|---------------------------- |
| Newsletter        | Weekly or biweekly | Fatigue, unsubscribes       |
| Product updates   | When shipped       | Noise if minor updates      |
| Promotions        | 1-2 per month      | Brand erosion, spam flags   |
| Onboarding        | Daily for 5-7 days | Overwhelming new users      |
| Re-engagement     | 1 sequence/quarter | Annoying inactive users     |

TOTAL EMAIL VOLUME PER SUBSCRIBER
- Aim for 4-8 emails per month maximum (across all campaigns)
- Exclude transactional from this count
- Use frequency capping to prevent over-sending
- Let users set email preferences (frequency and topics)
```

## 2. List Building and Management

### List Growth Strategies

```
ETHICAL LIST BUILDING
======================

ON-SITE METHODS
- Sign-up forms: Header, footer, sidebar, and dedicated page
- Content upgrades: Gated PDF, template, or checklist within blog posts
- Exit-intent popups: Offer value before the visitor leaves
- Webinar registration: Collect email during event sign-up
- Free trial/freemium: Email collected during product sign-up
- Newsletter subscription: Dedicated page with past issue preview

OFF-SITE METHODS
- Social media CTAs: Link to landing page with sign-up form
- Guest posts: Include relevant CTA linking to gated content
- Event sponsorships: Badge scan or booth sign-up sheet
- Partner co-marketing: Joint content with email gate
- Referral program: Existing subscribers invite contacts

RULES:
- Always use confirmed opt-in (double opt-in) for marketing emails
- Never buy or rent email lists (destroys deliverability)
- Always set clear expectations about what they will receive
- Provide instant value (welcome email with promised content)
```

### List Hygiene

```
LIST MAINTENANCE SCHEDULE
===========================

WEEKLY
- Monitor bounce rates per campaign (hard bounces > 2% = problem)
- Remove hard bounces immediately

MONTHLY
- Suppress contacts who have not opened in 90 days (move to re-engagement)
- Remove role-based addresses (info@, sales@, support@) from marketing lists
- Deduplicate across lists

QUARTERLY
- Run re-engagement campaign for inactive subscribers
- Remove subscribers who do not re-engage after the sequence
- Audit sign-up sources for quality (which sources produce engaged subscribers?)
- Verify list compliance (consent records, opt-in dates)

ANNUALLY
- Full list audit: Remove all contacts inactive for 12+ months
- Re-permission campaign if consent records are unclear
- Review and update suppression lists

HEALTH METRICS
- List growth rate: > 2% per month (net of unsubscribes)
- Hard bounce rate: < 0.5% per campaign
- Unsubscribe rate: < 0.3% per campaign
- Spam complaint rate: < 0.05% (1 in 2000)
```

## 3. Segmentation

### Segmentation Framework

```
SEGMENTATION DIMENSIONS
=========================

DEMOGRAPHIC
- Role/title: Decision-maker, user, admin, developer
- Company size: SMB (1-50), mid-market (51-500), enterprise (500+)
- Industry: Manufacturing, retail, services, finance, etc.
- Geography: Region, country, time zone

BEHAVIORAL
- Product usage: Active daily, weekly, inactive
- Feature adoption: Which features they use/ignore
- Email engagement: Highly engaged, occasional opener, inactive
- Purchase history: Free tier, paid, churned, expansion candidate

LIFECYCLE STAGE
- Subscriber: Signed up but not using product
- Trial user: Active trial, exploring features
- Customer: Paying customer
- Power user: Heavy engagement, potential advocate
- At-risk: Declining usage, support tickets
- Churned: Cancelled or lapsed

INTENT/INTEREST
- Content consumed: Which topics they read about
- Pages visited: Pricing page, comparison page, documentation
- Events attended: Webinars, demos, conferences
```

### Segment-Specific Campaign Map

```
SEGMENT-TO-CAMPAIGN MAPPING
==============================

| Segment              | Campaign              | Goal                     | Frequency    |
|----------------------|-----------------------|--------------------------|-------------|
| New subscriber       | Welcome sequence      | Activate to first action | 5 emails/10 days |
| Trial user (active)  | Onboarding tips       | Convert to paid          | 3 emails/7 days  |
| Trial user (stalled) | Re-activation nudge   | Resume trial usage       | 2 emails/5 days  |
| Customer (new)       | Success onboarding    | Drive feature adoption   | 4 emails/14 days |
| Customer (power)     | Advanced features     | Expansion, advocacy      | Monthly          |
| Customer (at-risk)   | Re-engagement         | Prevent churn            | 3 emails/10 days |
| Churned              | Win-back              | Re-activate              | 3 emails/30 days |
| Pricing page visitor | Consideration nudge   | Convert to trial/demo    | 1 email/2 days   |
```

## 4. Automation Flows

### Welcome Sequence

```
WELCOME SEQUENCE (5 emails over 10 days)
==========================================

EMAIL 1 — IMMEDIATE (trigger: sign-up)
  Subject: "Welcome to [Product] — here is your first step"
  Content: Thank them. Deliver promised content (if any).
           One clear CTA: complete profile or first action.
  Goal: First product interaction.

EMAIL 2 — DAY 1
  Subject: "Create your first [entity] in under 2 minutes"
  Content: Step-by-step walkthrough of core use case.
           Screenshot or short video link.
  CTA: "Try it now"
  Goal: First value moment.

EMAIL 3 — DAY 3
  Subject: "3 features that save [persona] hours every week"
  Content: Highlight features relevant to their role/segment.
           Short benefit descriptions with links to docs.
  CTA: "Explore features"
  Goal: Feature discovery.

EMAIL 4 — DAY 7
  Subject: "How [customer] solved [problem] with [Product]"
  Content: Brief case study or testimonial.
           Specific metrics and outcomes.
  CTA: "Read the full story" or "Try this approach"
  Goal: Social proof and confidence.

EMAIL 5 — DAY 10
  Subject: "Any questions? We are here to help."
  Content: Offer support channels (chat, email, docs).
           Link to FAQ or getting started guide.
           Ask if they need anything specific.
  CTA: "Reply to this email" or "Book a call"
  Goal: Human connection and support.

BRANCHING LOGIC:
- If user completes first action before email 2: skip to email 3
- If user has not logged in by day 3: send activation-focused variant
- If user visits pricing page: add to consideration nurture
```

### Nurture Sequence

```
NURTURE SEQUENCE (for leads not ready to buy)
===============================================

PURPOSE: Educate, build trust, and stay top-of-mind until
         the prospect is ready to evaluate solutions.

CADENCE: 1 email per week for 6-8 weeks

EMAIL 1 — EDUCATIONAL CONTENT
  Subject: "[Topic] guide: everything you need to know"
  Content: Link to pillar content or comprehensive guide.
  Goal: Establish expertise.

EMAIL 2 — PROBLEM AWARENESS
  Subject: "The hidden cost of [pain point]"
  Content: Data or story about the cost of the status quo.
  Goal: Amplify problem awareness.

EMAIL 3 — HOW-TO
  Subject: "How to [solve specific aspect of the problem]"
  Content: Actionable advice they can use today (with or without your product).
  Goal: Deliver value, build trust.

EMAIL 4 — SOCIAL PROOF
  Subject: "How [company] reduced [metric] by [percentage]"
  Content: Case study with specific results.
  Goal: Prove the solution works.

EMAIL 5 — COMPARISON/EVALUATION
  Subject: "What to look for in a [product category]"
  Content: Buyer's guide or evaluation checklist.
           Position your product favorably but honestly.
  Goal: Shape evaluation criteria.

EMAIL 6 — DIRECT OFFER
  Subject: "See [Product] in action — 15-minute demo"
  Content: Offer a personalized demo or free trial.
           Restate key benefits. Address objections.
  CTA: "Book your demo"
  Goal: Convert to sales conversation.

EXIT CONDITIONS:
- If prospect books a demo: move to sales pipeline, stop nurture
- If prospect signs up for trial: move to onboarding sequence
- If prospect does not engage after 6 emails: move to long-term drip (monthly)
```

### Re-engagement Sequence

```
RE-ENGAGEMENT SEQUENCE (3 emails over 21 days)
================================================

TRIGGER: No email opens for 90 days OR no product login for 60 days

EMAIL 1 — DAY 0 (SOFT TOUCH)
  Subject: "We have been busy — here is what is new"
  Content: Highlight 3-5 notable updates since they were last active.
           Keep it brief and visual.
  CTA: "See what is new"

EMAIL 2 — DAY 7 (VALUE REMINDER)
  Subject: "Your [Product] account is waiting"
  Content: Remind them of the value they were getting.
           "Last time you were active, you [specific action/metric]."
           Offer help if they are stuck.
  CTA: "Log in now" or "Book a call with support"

EMAIL 3 — DAY 21 (FINAL NOTICE)
  Subject: "Should we keep sending you emails?"
  Content: Give them a clear choice: stay subscribed or unsubscribe.
           "If we do not hear from you, we will stop sending emails
            to keep your inbox clean."
  CTA: "Keep me subscribed" / "Unsubscribe"

POST-SEQUENCE:
- If they engage (open or click): return to regular campaigns
- If no engagement: suppress from marketing emails for 6 months
- Do NOT delete — they may return organically
```

### Abandoned Process Reminder

```
ABANDONED PROCESS SEQUENCE
=============================

TRIGGER: User starts a process (trial signup, checkout, onboarding step)
         but does not complete it within the expected timeframe.

EMAIL 1 — 1 HOUR LATER
  Subject: "Finish setting up your [account/order]"
  Content: Acknowledge they started. Tell them where they left off.
           "You are 2 steps away from [benefit]."
  CTA: "Continue setup"

EMAIL 2 — 24 HOURS LATER
  Subject: "Need help completing your [process]?"
  Content: Offer assistance. Link to help docs or support chat.
           Address the most common reason people abandon this step.
  CTA: "Get help" or "Continue where you left off"

EMAIL 3 — 72 HOURS LATER
  Subject: "Still interested in [Product/Feature]?"
  Content: Final reminder with social proof.
           "[Number] teams completed setup this week."
           Optional: small incentive (extended trial, priority support).
  CTA: "Complete your setup"

RULES:
- Do NOT send more than 3 abandonment emails per process
- If they complete the process at any point, stop the sequence
- Space emails at least 12 hours apart
- Use suppression rules to prevent overlap with other sequences
```

## 5. Deliverability

### Authentication Setup

```
EMAIL AUTHENTICATION REQUIREMENTS
====================================

SPF (Sender Policy Framework)
  - DNS TXT record listing authorized sending IPs
  - Include your ESP's SPF record
  - Example: v=spf1 include:_spf.google.com include:sendgrid.net ~all

DKIM (DomainKeys Identified Mail)
  - Cryptographic signature on every email
  - Proves the email was not altered in transit
  - Set up via DNS CNAME or TXT record (provided by ESP)

DMARC (Domain-based Message Authentication)
  - Policy telling receivers what to do with failed SPF/DKIM
  - Start with p=none (monitor), then move to p=quarantine, then p=reject
  - Example: v=DMARC1; p=quarantine; rua=mailto:dmarc@yourdomain.com; pct=100

BIMI (Brand Indicators for Message Identification)
  - Display your logo in supported email clients
  - Requires DMARC enforcement (p=quarantine or p=reject)
  - DNS TXT record pointing to logo SVG

SETUP ORDER: SPF -> DKIM -> DMARC (monitor) -> DMARC (enforce) -> BIMI
```

### Deliverability Best Practices

```
DELIVERABILITY CHECKLIST
==========================

SENDING INFRASTRUCTURE
- [ ] SPF, DKIM, and DMARC configured and passing
- [ ] Dedicated sending IP (for volume > 50K/month) or shared IP with good reputation
- [ ] Separate IPs/subdomains for transactional vs. marketing email
- [ ] Feedback loops registered with major ISPs
- [ ] Monitoring sender reputation (Google Postmaster Tools, Microsoft SNDS)

LIST QUALITY
- [ ] Double opt-in for all marketing subscribers
- [ ] Hard bounces removed immediately
- [ ] Inactive subscribers suppressed after 90 days
- [ ] Role-based addresses (info@, admin@) excluded from marketing
- [ ] Spam traps avoided (never scrape or buy lists)

CONTENT
- [ ] Text-to-image ratio at least 60:40 (text heavy)
- [ ] No link shorteners (they look spammy)
- [ ] Unsubscribe link visible and functional
- [ ] Physical mailing address included
- [ ] Subject line does not trigger spam filters (avoid ALL CAPS, $$$, FREE!!!)
- [ ] HTML is clean, well-structured, and under 100KB

SENDING BEHAVIOR
- [ ] New IP/domain warmed up gradually (start with engaged subscribers)
- [ ] Consistent sending volume (avoid spikes)
- [ ] Send during business hours in the recipient's time zone
- [ ] Honor unsubscribes within 24 hours (legal requirement in many jurisdictions)
```

### IP Warming Schedule

```
IP WARMING PLAN (new dedicated IP)
=====================================

Start by sending only to your most engaged subscribers.
Gradually increase volume over 4-6 weeks.

| Day   | Volume  | Audience                              |
|-------|---------|---------------------------------------|
| 1-3   | 500     | Opened in last 7 days                 |
| 4-7   | 1,000   | Opened in last 14 days                |
| 8-14  | 5,000   | Opened in last 30 days                |
| 15-21 | 15,000  | Opened in last 60 days                |
| 22-28 | 40,000  | Opened in last 90 days                |
| 29-35 | 80,000  | All active subscribers                |
| 36+   | Full    | Full list (with inactive suppressed)  |

MONITOR DAILY:
- Bounce rate (should stay < 2%)
- Spam complaint rate (should stay < 0.05%)
- Inbox placement rate (use seed testing)
- If metrics spike, reduce volume and investigate
```

## 6. Email Design Patterns

### HTML Email Template Structure

```html
<!-- Responsive email template — single-column layout -->
<!DOCTYPE html>
<html lang="en" xmlns:v="urn:schemas-microsoft-com:vml">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <title>Email Title</title>
  <!--[if mso]>
  <noscript>
    <xml>
      <o:OfficeDocumentSettings>
        <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
  </noscript>
  <![endif]-->
  <style>
    /* Reset styles */
    body, table, td, a { -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%; }
    table, td { mso-table-lspace: 0pt; mso-table-rspace: 0pt; }
    img { -ms-interpolation-mode: bicubic; border: 0; height: auto; line-height: 100%; outline: none; text-decoration: none; }
    body { margin: 0; padding: 0; width: 100%; height: 100%; }

    /* Responsive */
    @media screen and (max-width: 600px) {
      .container { width: 100% !important; }
      .content-padding { padding: 16px !important; }
      .mobile-full-width { width: 100% !important; display: block !important; }
    }
  </style>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f4f4;">
  <!-- Preheader text (hidden, shows in email preview) -->
  <div style="display: none; max-height: 0px; overflow: hidden;">
    Preview text goes here — complement the subject line.
    <!-- Padding to push footer text out of preview -->
    &zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;
  </div>

  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0"
         style="background-color: #f4f4f4;">
    <tr>
      <td align="center" style="padding: 20px 0;">
        <!-- Container -->
        <table role="presentation" class="container" width="600" cellspacing="0"
               cellpadding="0" border="0" style="background-color: #ffffff;">

          <!-- Header -->
          <tr>
            <td style="padding: 24px; text-align: center;">
              <img src="https://example.com/logo.png" alt="Company Name"
                   width="150" style="display: block; margin: 0 auto;">
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td class="content-padding" style="padding: 0 32px 32px;">
              <h1 style="margin: 0 0 16px; font-family: -apple-system, BlinkMacSystemFont,
                  'Segoe UI', Roboto, sans-serif; font-size: 24px; line-height: 32px;
                  color: #1a1a1a;">
                Email Heading
              </h1>
              <p style="margin: 0 0 16px; font-family: -apple-system, BlinkMacSystemFont,
                 'Segoe UI', Roboto, sans-serif; font-size: 16px; line-height: 24px;
                 color: #4a4a4a;">
                Body text goes here. Keep paragraphs short and scannable.
              </p>

              <!-- CTA Button -->
              <table role="presentation" cellspacing="0" cellpadding="0" border="0"
                     style="margin: 24px 0;">
                <tr>
                  <td style="border-radius: 6px; background-color: #2563eb;">
                    <a href="https://example.com/action?utm_source=email&utm_medium=campaign&utm_campaign=name"
                       target="_blank"
                       style="display: inline-block; padding: 14px 32px;
                              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI',
                              Roboto, sans-serif; font-size: 16px; font-weight: 600;
                              color: #ffffff; text-decoration: none; border-radius: 6px;">
                      Call to Action
                    </a>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 24px 32px; background-color: #f9fafb; border-top: 1px solid #e5e7eb;">
              <p style="margin: 0 0 8px; font-family: -apple-system, BlinkMacSystemFont,
                 'Segoe UI', Roboto, sans-serif; font-size: 12px; line-height: 18px;
                 color: #9ca3af; text-align: center;">
                Company Name, 123 Street, City, State ZIP
              </p>
              <p style="margin: 0; font-family: -apple-system, BlinkMacSystemFont,
                 'Segoe UI', Roboto, sans-serif; font-size: 12px; line-height: 18px;
                 color: #9ca3af; text-align: center;">
                <a href="{{unsubscribe_url}}" style="color: #6b7280; text-decoration: underline;">
                  Unsubscribe</a> |
                <a href="{{preferences_url}}" style="color: #6b7280; text-decoration: underline;">
                  Email preferences</a>
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

### Email Design Rules

```
EMAIL DESIGN BEST PRACTICES
==============================

LAYOUT
- Single-column layout (works everywhere, including Outlook)
- Maximum width: 600px
- Minimum font size: 14px body, 22px headings
- Line height: 1.5x font size
- Padding: 16-32px on all sides
- Mobile-responsive (stack columns, full-width buttons)

IMAGES
- Always include alt text (images are blocked by default in many clients)
- Host images on a CDN, not embedded (keeps email size small)
- Compress images (under 200KB per image)
- Total email size under 100KB (excluding images)
- Use retina-ready images (2x resolution, displayed at 1x size)

BUTTONS
- Minimum button size: 44x44px (touch target)
- Use bulletproof buttons (table-based, not image-based)
- High contrast between button and background
- Padding: 12-16px vertical, 24-32px horizontal

DARK MODE
- Use transparent PNGs for logos (avoid white backgrounds)
- Test background colors in dark mode
- Do not rely solely on background color to convey meaning
- Use meta tag: <meta name="color-scheme" content="light dark">

OUTLOOK COMPATIBILITY
- Use tables for layout (not divs)
- Inline all CSS
- Use conditional comments for Outlook-specific fixes
- Test with Outlook 2019 and Outlook on the web
```

## 7. A/B Testing

### What to Test and How

```
EMAIL A/B TEST FRAMEWORK
===========================

SUBJECT LINE TESTING (highest impact)
  Variables to test:
  - Length: Short (3-5 words) vs. medium (6-8) vs. long (9+)
  - Personalization: With name vs. without
  - Format: Question vs. statement vs. number
  - Tone: Urgent vs. curious vs. direct
  - Emoji: With vs. without (test carefully, varies by audience)

  Minimum sample: 1,000 per variant
  Test duration: 2-4 hours, then send winner to remainder

SEND TIME TESTING
  Variables to test:
  - Day of week: Tuesday-Thursday typically best for B2B
  - Time of day: Morning (9-10am) vs. lunch (12-1pm) vs. afternoon (2-3pm)
  - Time zone: Send in recipient's local time zone

  Minimum sample: Full list (test over multiple sends)
  Test duration: 4+ weeks for statistical significance

CTA TESTING
  Variables to test:
  - Button text: Action-focused vs. benefit-focused
  - Button color: Brand color vs. high-contrast
  - Button placement: Above fold vs. below content vs. both
  - Number of CTAs: Single vs. primary + secondary

  Minimum sample: 2,000 per variant
  Test duration: Full send

CONTENT TESTING
  Variables to test:
  - Length: Short (under 100 words) vs. long (200+ words)
  - Format: Paragraph vs. bullet points vs. numbered list
  - Imagery: With images vs. text-only
  - Personalization: Generic vs. segment-specific content

  Minimum sample: 2,000 per variant
  Test duration: Full send
```

### A/B Test Documentation

```
A/B TEST LOG
==============
Test ID:          [YYYY-MM-DD]-[test number]
Campaign:         [Campaign name]
Element tested:   [Subject line / Send time / CTA / Content]
Hypothesis:       [Changing X to Y will improve Z because...]
Variant A:        [Control description]
Variant B:        [Test description]
Sample size:      [N per variant]
Duration:         [Hours or days]
Primary metric:   [Open rate / Click rate / Conversion rate]
Result:           [A / B / No significant difference]
Confidence:       [Statistical significance %]
Lift:             [+/- X%]
Learning:         [What we learned and how it applies going forward]
Next test:        [Follow-up test based on this learning]
```

## 8. Compliance

### CAN-SPAM Requirements (United States)

```
CAN-SPAM COMPLIANCE CHECKLIST
================================
- [ ] Do not use deceptive subject lines
- [ ] Identify the message as an advertisement (if applicable)
- [ ] Include physical mailing address
- [ ] Include a clear and conspicuous unsubscribe mechanism
- [ ] Honor unsubscribe requests within 10 business days
- [ ] Monitor what third parties are doing on your behalf
- [ ] "From" name and address must be accurate

PENALTIES: Up to $51,744 per email violation
```

### GDPR Requirements (European Union)

```
GDPR EMAIL COMPLIANCE CHECKLIST
==================================
- [ ] Explicit, affirmative consent obtained before sending (opt-in required)
- [ ] Consent is freely given, specific, informed, and unambiguous
- [ ] Consent records stored: who, when, how, what they consented to
- [ ] Clear and easy unsubscribe mechanism in every email
- [ ] Unsubscribe processed immediately (not just within 10 days)
- [ ] Privacy policy linked and accessible
- [ ] Data subject access requests (DSARs) can be fulfilled
- [ ] Right to erasure (right to be forgotten) supported
- [ ] Data processing agreement (DPA) in place with your ESP
- [ ] Data stored in GDPR-compliant infrastructure

CONSENT RECORD TEMPLATE
=========================
Subscriber:     john@example.com
Consent type:   Marketing email opt-in
Consent date:   2026-03-07T14:32:00Z
Consent method: Website form at /newsletter with checkbox
Consent text:   "I agree to receive marketing emails from [Company].
                 I can unsubscribe at any time."
IP address:     192.168.1.1
Source URL:      https://example.com/newsletter
```

### CASL Requirements (Canada)

```
CASL COMPLIANCE CHECKLIST
============================
- [ ] Express consent obtained (implied consent has limited duration)
- [ ] Consent request includes: sender identity, purpose, contact info, opt-out mechanism
- [ ] Unsubscribe processed within 10 business days
- [ ] All commercial electronic messages include sender identification
- [ ] Implied consent tracked with expiry dates (2 years for inquiries, etc.)
- [ ] Records of consent maintained

PENALTIES: Up to $10 million CAD per violation (individual: $1 million)
```

### Global Compliance Summary

```
COMPLIANCE BY JURISDICTION
=============================
| Requirement        | CAN-SPAM (US) | GDPR (EU)    | CASL (Canada) |
|--------------------|---------------|--------------|---------------|
| Consent model      | Opt-out       | Opt-in       | Opt-in        |
| Double opt-in      | Not required  | Recommended  | Not required  |
| Unsubscribe time   | 10 days       | Immediately  | 10 days       |
| Physical address   | Required      | Not required | Required      |
| Consent records    | Not required  | Required     | Required      |
| Right to erasure   | Not required  | Required     | Not required  |

BEST PRACTICE: Follow the strictest rules globally (GDPR)
to be compliant everywhere. Use double opt-in and process
unsubscribes immediately.
```

## 9. Analytics and KPIs

### Email KPI Benchmarks

```
EMAIL MARKETING BENCHMARKS (B2B SaaS)
=========================================
| Metric                  | Good      | Great     | Investigate if below |
|-------------------------|-----------|-----------|----------------------|
| Delivery rate           | > 97%     | > 99%     | < 95%                |
| Open rate               | > 20%     | > 30%     | < 15%                |
| Click rate (CTR)        | > 2.5%    | > 5%      | < 1.5%               |
| Click-to-open rate      | > 10%     | > 15%     | < 8%                 |
| Unsubscribe rate        | < 0.3%    | < 0.1%    | > 0.5%               |
| Spam complaint rate     | < 0.05%   | < 0.01%   | > 0.1%               |
| Bounce rate (hard)      | < 0.5%    | < 0.2%    | > 2%                 |
| Conversion rate         | > 1%      | > 3%      | < 0.5%               |

NOTE: "Open rate" is increasingly unreliable due to Apple Mail
Privacy Protection. Use click rate and conversion rate as primary
engagement indicators.
```

### Revenue Attribution

```
EMAIL REVENUE TRACKING
========================

DIRECT ATTRIBUTION
- Track UTM parameters on all email links
  utm_source=email
  utm_medium=[campaign_type]  (newsletter, onboarding, nurture, etc.)
  utm_campaign=[campaign_name]
  utm_content=[cta_variant]   (for A/B tests)

- Track conversions in analytics:
  Email click -> Landing page -> Sign up / Purchase / Demo request

ASSISTED ATTRIBUTION
- Track email touchpoints in the customer journey
- "Email assisted" = User received email before converting via another channel
- Multi-touch models: Linear, time-decay, or position-based

METRICS TO REPORT
- Revenue per email sent (total revenue / total emails sent)
- Revenue per subscriber (total revenue / active subscriber count)
- Campaign ROI: (revenue - cost) / cost x 100
- Customer lifetime value by acquisition source (email vs. other)
```

### Reporting Template

```
EMAIL MARKETING MONTHLY REPORT
=================================
Period: [Month Year]

SUMMARY
- Total emails sent: [N]
- Avg. delivery rate: [X%]
- Avg. open rate: [X%] (trend: +/- vs. last month)
- Avg. click rate: [X%] (trend: +/- vs. last month)
- Total conversions from email: [N]
- Email-attributed revenue: $[N]
- List size: [N] (net change: +/-[N])

TOP PERFORMING CAMPAIGNS
| Campaign            | Sent  | Open% | Click% | Conversions | Revenue |
|---------------------|-------|-------|--------|-------------|---------|
| [Campaign 1]        | [N]   | [X%]  | [X%]   | [N]         | $[N]    |
| [Campaign 2]        | [N]   | [X%]  | [X%]   | [N]         | $[N]    |

AUTOMATION PERFORMANCE
| Flow               | Active | Completed | Open% | Click% | Conversion% |
|--------------------|--------|-----------|-------|--------|-------------|
| Welcome sequence   | [N]    | [N]       | [X%]  | [X%]   | [X%]        |
| Nurture sequence   | [N]    | [N]       | [X%]  | [X%]   | [X%]        |
| Re-engagement      | [N]    | [N]       | [X%]  | [X%]   | [X%]        |

LIST HEALTH
- New subscribers: [N]
- Unsubscribes: [N]
- Hard bounces removed: [N]
- Inactive suppressed: [N]
- Spam complaints: [N]

KEY LEARNINGS
- [Learning 1 from A/B tests or campaign results]
- [Learning 2]

NEXT MONTH PLAN
- [Campaign 1: description and goal]
- [Campaign 2: description and goal]
- [A/B test planned: what and why]
```

## 10. Email Personalization

### Personalization Tiers

```
PERSONALIZATION LEVELS
========================

TIER 1 — BASIC (merge tags)
  - First name in subject or greeting
  - Company name in body
  - Example: "Hi {{first_name}}, your weekly report is ready"

TIER 2 — SEGMENTED (audience-based content)
  - Different content blocks per segment
  - Role-specific messaging
  - Example: Show admin features to admins, user features to users

TIER 3 — BEHAVIORAL (action-based triggers)
  - Content based on product usage
  - Recommendations based on past behavior
  - Example: "You have 12 draft invoices. Ready to send them?"

TIER 4 — PREDICTIVE (data-driven)
  - Send time optimization per recipient
  - Content recommendations via ML
  - Churn prediction-triggered campaigns
  - Example: Send re-engagement before they churn, not after

START WITH TIER 1, progress to TIER 3 before investing in TIER 4.
```

### Dynamic Content Blocks

```
DYNAMIC CONTENT STRATEGY
===========================

Use conditional content blocks within a single email template
rather than maintaining separate templates per segment.

EXAMPLE: Newsletter with role-based sections

  [HEADER — same for all]

  [IF role = "admin"]
    Admin section: Platform usage stats, billing reminder
  [ELSE IF role = "manager"]
    Manager section: Team activity summary, approval queue
  [ELSE]
    User section: Feature tips, shortcuts, recent activity
  [END IF]

  [SHARED SECTION — product update, same for all]

  [IF plan = "free"]
    Upgrade CTA: "Unlock advanced features"
  [ELSE]
    Feature highlight: "Did you know about [advanced feature]?"
  [END IF]

  [FOOTER — same for all]

RULES:
- Limit dynamic blocks to 2-3 per email (avoid complexity)
- Always have a default/fallback for each condition
- Test every variant before sending
- Track performance per dynamic block variant
```
