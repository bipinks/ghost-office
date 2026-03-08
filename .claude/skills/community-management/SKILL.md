---
name: community-management
description: Use when building online communities, defining moderation policies, managing community engagement, handling crises, designing ambassador programs, or measuring community health. Covers community building frameworks, engagement tactics, forum/Discord/Slack management, user-generated content, community events, feedback loops, community-led growth, and toxicity handling.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Community Management -- Building and Nurturing Engaged Communities

## 1. Community Maturity Model

| Stage | Size | Focus | Key Activities | Duration |
|-------|------|-------|---------------|----------|
| Inception | 0-100 | Seed founding members | Personal invites, daily posts, respond to every post within 1hr | 1-3 mo |
| Establishment | 100-1K | Build habits and culture | Recurring events, nurture power users, member spotlights | 3-6 mo |
| Growth | 1K-10K | Scale without losing quality | Moderation team, self-serve resources, sub-communities | 6-12 mo |
| Maturity | 10K+ | Sustain and evolve | Member-led initiatives, governance model, strategic partnerships | Ongoing |

**Risk at each stage**: Inception = ghost town. Establishment = quality dilution. Growth = moderation overwhelm. Maturity = stagnation.

## 2. Platform Selection

| Platform | Best For | Strengths | Weaknesses |
|----------|----------|-----------|------------|
| Discord | Developer/gaming/tech communities | Real-time chat, bots, roles, channels | Overwhelming for non-tech users |
| Slack | Professional/B2B communities | Threaded discussions, integrations | Expensive at scale, message limits (free) |
| Circle/Discourse | Brand/course communities | Structured forums, SEO-friendly | Less real-time engagement |
| Reddit | Public discussion, broad reach | Organic discovery, voting | Less brand control, toxicity risk |
| Facebook Groups | Broad consumer audiences | Familiar UX, large user base | Algorithm-controlled visibility |

**Decision framework**: Choose Discord/Slack for real-time, high-engagement technical communities. Choose Circle/Discourse for async, structured knowledge-sharing. Choose Reddit for organic growth and public discourse.

## 3. Community Structure (Discord/Slack Example)

```
WELCOME & INFO
  #rules-and-guidelines
  #introductions
  #announcements

DISCUSSION
  #general
  #topic-specific-1 (e.g., #frontend, #backend, #devops)
  #topic-specific-2
  #off-topic

SUPPORT
  #help-and-questions
  #bugs-and-issues
  #feature-requests

ENGAGEMENT
  #showcase (member projects)
  #events
  #jobs-and-opportunities

MODERATION (staff-only)
  #mod-log
  #mod-discussion
  #reports
```

**Channel hygiene**: Archive inactive channels quarterly. Pin important resources. Use slow mode (1 msg/30s) on high-traffic channels during events.

## 4. Moderation Framework

### Tiered Response System

| Level | Behavior | Response | Example |
|-------|----------|----------|---------|
| 1 - Minor | Off-topic, mild spam | Gentle redirect, move post | "This fits better in #off-topic" |
| 2 - Warning | Disrespect, repeated minor | Written warning (DM) | First formal notice |
| 3 - Temp ban | Harassment, NSFW, doxxing | 24h-7d ban, log incident | Cooling-off period |
| 4 - Perm ban | Hate speech, threats, illegal | Immediate permanent ban | Zero tolerance |

### Moderation Team Scaling

| Community Size | Mod Ratio | Structure |
|---------------|-----------|-----------|
| < 500 | Founder + 1-2 volunteers | Informal |
| 500-5K | 1 mod per 500 members | Lead mod + team, weekly sync |
| 5K-50K | 1 mod per 1K + automod | Tiered roles, mod queue, documented policies |
| 50K+ | Paid community managers + volunteer mods | Formal program, training, SLAs |

**Automod essentials**: Keyword filters (slurs, spam patterns), link restrictions for new members, rate limiting, duplicate content detection, new account quarantine (e.g., 10-min wait before posting).

## 5. Engagement Tactics

### Recurring Programs

| Program | Frequency | Purpose | Format |
|---------|-----------|---------|--------|
| Welcome thread | Daily/weekly | Onboard new members | Intro template, ice-breaker question |
| AMA (Ask Me Anything) | Monthly | Bring in experts | Scheduled Q&A with guest |
| Challenge/hackathon | Monthly/quarterly | Drive creation | Theme + deadline + prizes |
| Member spotlight | Weekly | Recognize contributors | Interview or showcase post |
| Feedback Friday | Weekly | Collect input | Structured feedback thread |

### The 1-9-90 Rule

- 1% create content (nurture these heavily -- they are your community engine)
- 9% engage (comments, reactions -- encourage them to create)
- 90% lurk (make it easy to consume, periodically nudge toward participation)

**Activating lurkers**: Low-barrier polls and reactions. "React with your answer" posts. Welcome DMs with a specific ask ("Share one thing you're working on").

## 6. Ambassador / Champion Program

**Selection criteria**: Active 3+ months, helpful to others, aligned with values, diverse representation.

**Tiers**:
1. **Contributor**: Recognized active member. Badge/role, early access to announcements.
2. **Ambassador**: Leads discussions, mentors newcomers. Swag, exclusive channel, quarterly call with leadership.
3. **Champion**: Co-creates content, represents community externally. Compensation/stipend, conference invites, advisory role.

**Management**: Monthly check-ins, quarterly reviews, clear expectations document, graceful off-ramp for inactive ambassadors.

## 7. Crisis Management

### Severity Levels

| Severity | Example | Response Time | Actions |
|----------|---------|--------------|---------|
| P1 Critical | Data breach, legal threat, member safety | < 1 hour | Lock channels, leadership involved, legal review |
| P2 High | Raid/brigading, viral negative content | < 4 hours | Temp lockdown, mod all-hands, public statement |
| P3 Medium | Heated debate, misinformation spreading | < 24 hours | Mod intervention, pin clarification, cool-down |
| P4 Low | Complaint thread, minor policy violation | < 48 hours | Normal moderation process |

### Response Template

```
CRISIS COMMUNICATION:
1. Acknowledge: "We're aware of [situation] and are investigating."
2. Action: "Here's what we're doing: [specific steps]."
3. Timeline: "We'll provide an update by [time]."
4. Follow-up: "Here's what happened, what we learned, and what changes we're making."
```

**Post-crisis**: Debrief within 48 hours. Document lessons learned. Update policies if gaps identified. Communicate changes to community.

## 8. Community-Led Growth (CLG)

**Flywheel**: Great community -> members create content/referrals -> attracts new users -> some become community members -> repeat.

**Tactics**:
- User-generated content programs (templates, tutorials, showcases)
- Referral program (invite codes with community perks)
- Community-sourced testimonials and case studies
- Member-led workshops and study groups
- Public community metrics as social proof ("Join 5,000+ developers")

**Measuring CLG impact**: Track signups with community referral attribution. Measure time-to-value for community members vs non-members. Compare retention rates: community participants vs general users.

## 9. Community Health Metrics

| Metric | Formula | Healthy Range | Frequency |
|--------|---------|--------------|-----------|
| DAU/MAU ratio | Daily active / Monthly active | 15-30% | Weekly |
| Post-to-member ratio | Posts per week / Total members | 5-15% | Weekly |
| Response time | Avg time to first reply | < 4 hours | Daily |
| Resolution rate | Questions answered / Questions asked | > 80% | Weekly |
| New member activation | New members who post in first 7 days | > 30% | Weekly |
| Churn rate | Members inactive 30+ days / Total | < 20%/month | Monthly |
| Sentiment score | Positive posts / Total posts | > 70% positive | Monthly |
| Escalation rate | Mod actions / Total posts | < 2% | Weekly |

### Health Dashboard

```
COMMUNITY HEALTH SCORECARD
Period: [Date range]

Engagement:  [DAU/MAU] [trend]    |  Growth:  [Net new members] [trend]
Activity:    [Posts/week] [trend]  |  Quality: [Resolution rate] [trend]
Sentiment:   [Score] [trend]      |  Churn:   [Rate] [trend]

Red flags: [Any metric trending in wrong direction for 2+ periods]
Actions:   [Specific interventions for underperforming metrics]
```

## 10. Feedback Loops

**Collection methods**: In-community polls, quarterly surveys (NPS + open-ended), feature request voting boards, exit interviews for churned members, sentiment analysis on posts.

**Processing**: Categorize feedback (product, community, content, support). Prioritize by frequency and impact. Close the loop publicly ("You asked for X, we built X").

**Cadence**: Weekly feedback review (community team). Monthly feedback report to product/leadership. Quarterly community survey with published results.

## 11. Legal and Compliance

- **Terms of Service**: Define acceptable use, content ownership, dispute resolution
- **Privacy**: Disclose data collection, comply with GDPR/CCPA, provide data export/deletion
- **Content liability**: Establish that user-generated content does not represent the company
- **Minors**: If community may include minors, implement COPPA compliance (age gates, parental consent, content restrictions)
- **Moderation documentation**: Log all mod actions with timestamps and reasons (needed for legal disputes)
