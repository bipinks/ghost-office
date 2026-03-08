---
name: email-marketing
description: Use when planning email campaigns, building automation flows, optimizing deliverability, writing email sequences, segmenting audiences, or analyzing email performance. Covers campaign strategy, list management, automation (welcome, nurture, re-engagement, abandoned cart), A/B testing, email design, compliance (CAN-SPAM, GDPR), and analytics.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Email Marketing -- Campaigns, Automation & Deliverability

## 1. Campaign Types

| Type | Examples | Delivery Target |
|------|----------|----------------|
| **Transactional** (user-triggered) | Confirmations, receipts, password reset | 99%+ -- separate infra, no unsubscribe needed |
| **Automated/Lifecycle** (behavior-triggered) | Welcome, nurture, re-engagement, abandoned cart | High |
| **Broadcast** (scheduled) | Newsletter, product updates, promotions | Standard |
| **Operational** (system-driven) | Maintenance, policy changes, security alerts | High |

Frequency: 4-8 emails/month max per subscriber (excluding transactional). Use frequency capping.

## 2. List Management

**Growth**: Double opt-in always. Never buy lists.

**Hygiene**: Weekly remove hard bounces (<0.5%). Monthly suppress 90-day inactive. Quarterly re-engagement campaign. Annually purge 12+ month inactive.

**Health targets**: Growth >2%/month, unsubscribe <0.3%, spam complaints <0.05%.

## 3. Segmentation & Campaign Map

| Dimension | Examples |
|-----------|---------|
| Behavioral | Product usage, email engagement, purchase history |
| Lifecycle | Subscriber, trial, customer, at-risk, churned |
| Demographic | Role, company size, industry, geography |
| Intent | Content consumed, pricing page visits |

| Segment | Campaign | Cadence |
|---------|----------|---------|
| New subscriber | Welcome sequence | 5 emails / 10 days |
| Active trial | Onboarding tips | 3 / 7 days |
| Stalled trial | Re-activation nudge | 2 / 5 days |
| New customer | Success onboarding | 4 / 14 days |
| At-risk customer | Re-engagement | 3 / 10 days |
| Churned | Win-back | 3 / 30 days |

## 4. Automation Flows

### Welcome Sequence (5 emails / 10 days)
```
Email 1 (immediate): Thank, deliver promised content, CTA: first action
Email 2 (day 1):     Core use case walkthrough
Email 3 (day 3):     3 features relevant to their segment
Email 4 (day 7):     Case study with specific metrics
Email 5 (day 10):    Offer support, ask for needs

Branching: Skip ahead if first action done. Activation variant if no login by day 3.
```

### Nurture Sequence (6 emails / 6 weeks)
```
1. Educational pillar content  2. Problem awareness (cost of status quo)
3. Actionable how-to           4. Case study with results
5. Buyer's evaluation guide    6. Direct offer (demo/trial)

Exit: Demo booked -> sales. Trial signup -> onboarding. No engagement -> monthly drip.
```

### Re-engagement (3 emails / 21 days)
```
Trigger: 90 days no opens OR 60 days no login
Day 0:  "Here is what is new" (3-5 updates)
Day 7:  "Your account is waiting" + offer help
Day 21: "Should we stop emailing?" explicit stay/leave choice

Post: Engaged -> return to campaigns. No response -> suppress 6 months.
```

### Abandoned Process (3 emails max)
```
+1 hour:  "You are 2 steps away from [benefit]"
+24 hours: Offer help, address common abandonment reason
+72 hours: Final reminder with social proof. Optional incentive.
Stop immediately if process is completed.
```

## 5. Deliverability

### Authentication (setup in order)
1. **SPF**: DNS TXT listing authorized sending IPs
2. **DKIM**: Cryptographic signature per email
3. **DMARC**: Start `p=none` -> `p=quarantine` -> `p=reject`
4. **BIMI**: Logo in email clients (requires DMARC enforcement)

### Checklist
- SPF/DKIM/DMARC passing; separate IPs for transactional vs marketing
- Double opt-in; hard bounces removed immediately; inactive suppressed
- Text:image ratio 60:40+; no link shorteners; clean HTML under 100KB
- Consistent volume; business hours in recipient timezone; unsubscribes honored <24h

### IP Warming (new dedicated IP)
Ramp over 5 weeks with most engaged subscribers: 500 -> 1K -> 5K -> 15K -> 40K -> 80K -> full. Monitor bounces <2% and complaints <0.05% daily.

## 6. Email Design

```html
<!-- Single-column, 600px max, table-based layout -->
<body style="margin:0; padding:0; background:#f4f4f4;">
  <div style="display:none; max-height:0; overflow:hidden;">Preview text here</div>
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
    <tr><td align="center" style="padding:20px 0;">
      <table class="container" width="600" style="background:#fff;">
        <!-- Header: logo -->
        <!-- Body: heading + short copy + CTA button -->
        <!-- CTA: table-based bulletproof button, 44x44px min touch target -->
        <!-- Footer: address + unsubscribe + preferences -->
      </table>
    </td></tr>
  </table>
</body>
```

Rules: Min 14px body font. Inline all CSS. Retina images with alt text. Test Outlook + dark mode. Use `<meta name="color-scheme" content="light dark">`.

## 7. A/B Testing

| Element | Min Sample | What to Test |
|---------|-----------|-------------|
| Subject line (highest impact) | 1K/variant | Length, personalization, format, tone, emoji |
| Send time | Full list over 4+ weeks | Day of week, time of day, timezone |
| CTA | 2K/variant | Button text, color, placement, count |
| Content | 2K/variant | Length, format, imagery, personalization |

Test one variable at a time. Send winner to remainder after 2-4 hours for subject lines.

## 8. Compliance

| Requirement | CAN-SPAM (US) | GDPR (EU) | CASL (Canada) |
|-------------|--------------|-----------|---------------|
| Consent model | Opt-out | Opt-in | Opt-in |
| Double opt-in | Not required | Recommended | Not required |
| Unsubscribe time | 10 days | Immediately | 10 days |
| Physical address | Required | Not required | Required |
| Consent records | Not required | Required | Required |
| Right to erasure | Not required | Required | Not required |

**Best practice**: Follow GDPR globally. Double opt-in + immediate unsubscribe + consent records.

## 9. Analytics & KPIs

| Metric | Good | Great | Investigate |
|--------|------|-------|-------------|
| Delivery rate | >97% | >99% | <95% |
| Open rate* | >20% | >30% | <15% |
| Click rate (CTR) | >2.5% | >5% | <1.5% |
| Unsubscribe rate | <0.3% | <0.1% | >0.5% |
| Spam complaints | <0.05% | <0.01% | >0.1% |

*Open rate unreliable due to Apple Mail Privacy Protection. Use click rate and conversion as primary indicators.

**Attribution**: UTM params on all links (`utm_source=email&utm_medium=[type]&utm_campaign=[name]`). Track email click -> landing -> conversion. Report revenue per email sent.

## 10. Personalization Tiers

| Tier | Approach | Example |
|------|----------|---------|
| 1 Basic | Merge tags | "Hi {{first_name}}" |
| 2 Segmented | Content blocks per audience | Admin features vs user features |
| 3 Behavioral | Action-based triggers | "You have 12 draft invoices" |
| 4 Predictive | ML-driven timing/content | Send before churn, not after |

Start at Tier 1, progress to Tier 3 before investing in Tier 4. Use conditional content blocks (2-3 max per email) with fallbacks.
