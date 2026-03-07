---
name: community-management
description: Use when building online communities, defining moderation policies, managing community engagement, handling crises, designing ambassador programs, or measuring community health. Covers community building frameworks, engagement tactics, forum/Discord/Slack management, user-generated content, community events, feedback loops, community-led growth, and toxicity handling.
user-invocable: true
allowed-tools: ["Read", "Write", "Edit", "Grep", "Glob", "Bash"]
---

# Community Management -- Building and Nurturing Engaged Communities

## 1. Community Building Frameworks

### 1.1 Community Maturity Model

```
STAGE 1: INCEPTION (0-100 members)
├── Focus: Seed the community with founding members
├── Activities:
│   ├── Personally invite 20-50 "founding members" from existing network
│   ├── Create welcome flow and onboarding experience
│   ├── Post daily to establish content patterns
│   ├── Respond to every single post within 1 hour
│   └── Define community purpose and guidelines
├── Metrics: Member count, first-post rate, response time
├── Risk: Ghost town effect (too few members, no activity)
└── Duration: 1-3 months

STAGE 2: ESTABLISHMENT (100-1,000 members)
├── Focus: Build habits and culture
├── Activities:
│   ├── Introduce recurring events (weekly AMAs, monthly challenges)
│   ├── Identify and nurture early power users
│   ├── Create content templates members can use
│   ├── Start member spotlights and recognition
│   └── Develop moderation team (recruit from active members)
├── Metrics: Daily active users, posts per member, retention rate
├── Risk: Quality dilution as new members join
└── Duration: 3-6 months

STAGE 3: GROWTH (1,000-10,000 members)
├── Focus: Scale engagement without losing culture
├── Activities:
│   ├── Launch ambassador/champion program
│   ├── Create sub-groups or channels by interest/topic
│   ├── Automate onboarding and welcome sequences
│   ├── Host larger events (webinars, conferences)
│   └── Implement community-led content creation
├── Metrics: Member-to-member interactions, UGC volume, NPS
├── Risk: Loss of intimacy, moderation overwhelm
└── Duration: 6-18 months

STAGE 4: MATURITY (10,000+ members)
├── Focus: Sustain, deepen, and monetize
├── Activities:
│   ├── Empower member-led initiatives
│   ├── Create premium/exclusive tiers
│   ├── Integrate community into product feedback loop
│   ├── Build self-sustaining content ecosystem
│   └── Measure business impact (retention, referrals, support deflection)
├── Metrics: Community-influenced revenue, support deflection, referral rate
├── Risk: Stagnation, community fatigue, governance challenges
└── Duration: Ongoing
```

### 1.2 Community Purpose Framework

```
COMMUNITY PURPOSE CANVAS
==========================

WHO is the community for?
├── Primary persona: [Description, needs, goals]
├── Secondary persona: [Description, needs, goals]
└── Who is NOT welcome: [Exclusion criteria if any]

WHAT value does it provide?
├── For members: [Learning, networking, support, belonging]
├── For the brand: [Feedback, loyalty, advocacy, support deflection]
└── Unique value: [What makes THIS community different from alternatives]

WHY would someone join and stay?
├── Join triggers: [What motivates first visit]
├── Stay triggers: [What keeps them coming back]
├── Leave triggers: [What causes churn -- to avoid]
└── Invite triggers: [What motivates referrals]

WHERE does the community live?
├── Primary platform: [Discord, Slack, Facebook Group, Forum, etc.]
├── Supporting channels: [Social media, email, events]
└── Platform rationale: [Why this platform fits the audience]

HOW will success be measured?
├── 30-day goal: [Metric and target]
├── 90-day goal: [Metric and target]
├── 1-year goal: [Metric and target]
└── North star metric: [Single metric that captures community health]
```

### 1.3 Community Type Selection

```
COMMUNITY TYPES AND BEST FIT
==============================

PRODUCT COMMUNITY
├── Purpose: Help users succeed with your product
├── Best for: SaaS, developer tools, complex products
├── Platform: Forum (Discourse), Discord, or Slack
├── Content: How-tos, troubleshooting, feature requests, best practices
├── Example: Figma Community, Notion community
└── Key metric: Support ticket deflection rate

PRACTICE COMMUNITY
├── Purpose: Help practitioners improve at their craft
├── Best for: Professional services, education, B2B
├── Platform: Slack, Discord, or LinkedIn Group
├── Content: Knowledge sharing, career advice, industry trends
├── Example: dbt community, Product Hunt Makers
└── Key metric: Knowledge contribution rate

INTEREST COMMUNITY
├── Purpose: Connect people with shared passions
├── Best for: B2C brands, lifestyle, hobbies
├── Platform: Facebook Group, Reddit, Discord
├── Content: Discussions, sharing, meetups, challenges
├── Example: Peloton community, r/photography
└── Key metric: Member-to-member interactions

ADVOCACY COMMUNITY
├── Purpose: Mobilize superfans to spread the word
├── Best for: Consumer brands, cause-driven organizations
├── Platform: Branded app, Facebook Group, or Discord
├── Content: Exclusive content, early access, missions, rewards
├── Example: Salesforce Trailblazers, Sephora Beauty Insider
└── Key metric: Referral and advocacy actions per member
```

---

## 2. Platform-Specific Community Management

### 2.1 Discord Server Management

```
DISCORD SERVER STRUCTURE
=========================

CATEGORY: WELCOME
├── #rules-and-guidelines (read-only)
├── #introductions (new member intros)
├── #announcements (read-only, team posts only)
└── #start-here (onboarding resources, pinned links)

CATEGORY: GENERAL
├── #general-chat (open discussion)
├── #off-topic (non-work conversations)
├── #wins-and-celebrations (member achievements)
└── #feedback-and-ideas (product/community suggestions)

CATEGORY: TOPICS (customize per community)
├── #topic-channel-1 (e.g., #frontend, #marketing, #design)
├── #topic-channel-2
├── #topic-channel-3
└── #resources (curated links and tools)

CATEGORY: HELP
├── #ask-the-community (peer support)
├── #ask-the-team (team-answered questions)
└── #bugs-and-issues (technical support)

CATEGORY: EVENTS
├── #event-announcements
├── #event-chat (during live events)
└── Voice channels for AMAs, workshops, hangouts

CATEGORY: MODERATORS (private)
├── #mod-chat
├── #mod-logs
├── #escalations
└── #community-metrics

ROLE STRUCTURE:
├── @Admin: Full server control (team only)
├── @Moderator: Manage messages, mute/kick (trusted volunteers)
├── @Champion/Ambassador: Special badge, access to exclusive channel
├── @Verified: Completed onboarding steps
├── @Member: Default role on join
└── @New: Auto-assigned, limited posting until verified

BOT SETUP:
├── MEE6 or Carl-bot: Welcome messages, auto-moderation, leveling
├── Dyno: Logging, anti-spam, custom commands
├── Ticket bot: Support ticket system within Discord
└── Event bot: RSVP management for community events
```

### 2.2 Slack Community Management

```
SLACK WORKSPACE STRUCTURE
==========================

PUBLIC CHANNELS:
├── #welcome (auto-post for new members, pinned resources)
├── #introductions (new member intros)
├── #announcements (admin-only posting)
├── #general (open discussion)
├── #random (off-topic, fun)
├── #help (peer support)
├── #resources (curated links, shared weekly)
├── #jobs (job board for community members)
├── #events (upcoming events and recaps)
├── #wins (member achievements and celebrations)
├── #feedback (product and community suggestions)
└── #topic-channels (1 per major topic area)

PRIVATE CHANNELS:
├── #team-internal (staff coordination)
├── #moderation (mod team discussions)
├── #ambassadors (ambassador program coordination)
└── #vip (high-value members, exclusive content)

SLACK BEST PRACTICES:
├── Set channel purposes and topics for every channel
├── Pin important messages in each channel
├── Use threaded replies to keep channels readable
├── Set posting guidelines (no self-promotion in #general)
├── Create a weekly digest bot (summarize key discussions)
├── Archive inactive channels quarterly
├── Use Slack workflows for onboarding automation
└── Set custom emoji for reactions and engagement
```

### 2.3 Facebook Group Management

```
FACEBOOK GROUP SETUP
=====================

GROUP SETTINGS:
├── Privacy: Private (visible but must request to join)
├── Membership questions: 3 questions for screening
│   ├── "What do you do professionally?"
│   ├── "What do you hope to get from this community?"
│   └── "How did you hear about us?" (or email for list)
├── Post approval: Enable for new members (first 2 weeks)
├── Group rules: 5-7 clear rules (see moderation section)
└── Linked Page: Connect to brand Facebook Page

RECURRING CONTENT SCHEDULE:
├── Monday: Weekly discussion prompt or question
├── Tuesday: Resource or tip share
├── Wednesday: Member spotlight or success story
├── Thursday: AMA or expert Q&A thread
├── Friday: Fun thread (meme day, wins, casual chat)
├── Saturday: Weekend reading or resource roundup
└── Sunday: Rest (or plan ahead for next week)

GROWTH TACTICS:
├── Add group link to email signature
├── Promote in post-purchase email sequence
├── Cross-promote in other social channels
├── Pin a "welcome and share" post monthly
├── Run "invite a colleague" campaigns with incentives
├── Partner with complementary groups for cross-promotion
└── Go live weekly (Facebook prioritizes group Lives)
```

### 2.4 Forum Management (Discourse, Circle, Mighty Networks)

```
FORUM CATEGORY STRUCTURE
==========================

GETTING STARTED
├── Welcome & Introductions
├── Community Guidelines
├── FAQ and Help
└── Platform Tutorial

MAIN CATEGORIES (customize per community)
├── Category 1: [Core topic area]
│   ├── Sub-category A
│   └── Sub-category B
├── Category 2: [Secondary topic area]
├── Category 3: [Third topic area]
└── General Discussion

COMMUNITY
├── Events & Meetups
├── Jobs & Opportunities
├── Feedback & Suggestions
├── Wins & Celebrations
└── Off-Topic / Watercooler

RESOURCES
├── Guides & Tutorials
├── Tools & Templates
├── Curated Links
└── Book/Content Recommendations

FORUM ENGAGEMENT TACTICS:
├── Seed discussions before launching publicly (50+ threads)
├── Ask genuine questions (not rhetorical)
├── Feature the best answers with "solved" or "best answer" tags
├── Create "wiki" posts for frequently asked questions
├── Use polls to drive participation
├── Implement a trust level / reputation system
├── Send weekly digest emails of top discussions
└── Archive stale threads, merge duplicates
```

---

## 3. Engagement Tactics

### 3.1 Daily Engagement Playbook

```
MORNING ROUTINE (30-60 minutes):
├── Check overnight messages, mentions, and flags
├── Respond to unanswered questions (or tag relevant experts)
├── Welcome new members who joined overnight
├── Review and approve pending posts (if moderation queue exists)
├── Post the day's discussion prompt or content
└── Flag any potential issues to moderation team

MIDDAY CHECK (15-30 minutes):
├── Respond to comments on morning post
├── Engage with member-generated content (like, comment, amplify)
├── Check for trending discussions to participate in
├── Share relevant external content or news
└── Monitor sentiment for any emerging issues

EVENING WRAP (15-30 minutes):
├── Respond to remaining unanswered questions
├── Thank active contributors
├── Note engagement patterns for reporting
├── Plan next day's content or prompts
└── Escalate any unresolved issues
```

### 3.2 Engagement Prompt Library

```
CATEGORY: DISCUSSION STARTERS
├── "What is the biggest challenge you are facing with [topic] right now?"
├── "If you could change one thing about [industry/tool/process], what would it be?"
├── "What is the best advice you have received about [topic]?"
├── "Agree or disagree: [provocative but safe industry statement]"
├── "What is one tool/resource you cannot live without? Why?"
└── "Share your hot take on [trending topic]."

CATEGORY: KNOWLEDGE SHARING
├── "What did you learn this week that surprised you?"
├── "Share a tip that saved you hours of work."
├── "What mistake taught you the most valuable lesson?"
├── "What resource would you recommend to someone starting in [field]?"
├── "Break down your process for [common task] step by step."
└── "What is one thing most people get wrong about [topic]?"

CATEGORY: COMMUNITY BUILDING
├── "Introduce yourself! Where are you from and what do you do?"
├── "Who in this community has helped you? Tag them and say thanks."
├── "Share your biggest win from this month."
├── "What brought you to this community? What keeps you here?"
├── "Looking for accountability partners for [goal]. Who is in?"
└── "If you could have coffee with anyone in this community, who and why?"

CATEGORY: POLLS AND SURVEYS
├── "Which do you prefer: [Option A] or [Option B]?"
├── "Rate your experience with [topic] from 1-5."
├── "What topic should we cover in our next event?"
├── "How long have you been working in [field]?"
├── "What is your biggest priority for Q[X]?"
└── "Which format do you prefer for learning: video, article, or podcast?"

CATEGORY: FUN AND CASUAL
├── "It is Friday -- share something that made you laugh this week."
├── "What are you watching/reading/listening to right now?"
├── "Describe your job in the most confusing way possible."
├── "Share your workspace setup."
├── "What is your unpopular opinion about [light industry topic]?"
└── "If our community had a mascot, what would it be?"
```

### 3.3 Member Journey Mapping

```
MEMBER LIFECYCLE STAGES
========================

STAGE 1: AWARENESS (Pre-Join)
├── Touchpoints: Social media, word of mouth, search, ads
├── Goal: Communicate community value proposition
├── Action: Share community content publicly, member testimonials
└── Metric: Community page visits, join requests

STAGE 2: ONBOARDING (Day 1-7)
├── Touchpoints: Welcome message, onboarding flow, intro channel
├── Goal: First meaningful interaction within 48 hours
├── Actions:
│   ├── Auto-welcome with DM or post (personalized if possible)
│   ├── Guide to introduce themselves
│   ├── Point to 3 most valuable resources
│   ├── Tag relevant existing members for connection
│   └── Send "Getting Started" email or guide
└── Metric: Intro post rate, first interaction within 7 days

STAGE 3: ACTIVATION (Week 2-4)
├── Touchpoints: Content consumption, first reply, first question
├── Goal: Member posts or replies at least 3 times
├── Actions:
│   ├── Personally engage with their posts
│   ├── Invite to upcoming event
│   ├── Connect with similar members
│   └── Ask for feedback on their experience
└── Metric: Posts per member in first 30 days, event attendance

STAGE 4: REGULAR (Month 2-6)
├── Touchpoints: Regular participation, content creation, networking
├── Goal: Establish habitual participation (weekly+)
├── Actions:
│   ├── Recognize contributions publicly
│   ├── Invite to contribute content or lead discussions
│   ├── Offer mentorship opportunities
│   └── Solicit product/community feedback
└── Metric: Weekly active rate, contribution frequency

STAGE 5: CHAMPION (Month 6+)
├── Touchpoints: Leadership, mentoring, advocacy
├── Goal: Convert to community ambassador
├── Actions:
│   ├── Invite to ambassador program
│   ├── Give moderator or leadership role
│   ├── Feature in case studies or spotlights
│   ├── Offer exclusive perks or early access
│   └── Co-create content and events
└── Metric: Members mentored, content created, referrals driven

STAGE 6: AT-RISK (Declining activity)
├── Signals: No activity for 14+ days after being active
├── Goal: Re-engage before they leave
├── Actions:
│   ├── Personal check-in message
│   ├── Share relevant content or discussion
│   ├── Invite to an upcoming event
│   └── Ask for honest feedback on their experience
└── Metric: Win-back rate, reactivation rate
```

---

## 4. Moderation Policies

### 4.1 Community Guidelines Template

```
COMMUNITY GUIDELINES
=====================

OUR MISSION
[1-2 sentences about what the community exists to do]

RULES FOR PARTICIPATION

1. BE RESPECTFUL
   Treat others the way you want to be treated. Disagree with ideas,
   not people. No personal attacks, name-calling, or harassment.

2. STAY ON TOPIC
   Keep discussions relevant to the community's purpose. Off-topic
   content belongs in designated channels (e.g., #off-topic, #random).

3. NO SPAM OR SELF-PROMOTION
   Do not post unsolicited promotional content. Share your work only
   in designated channels and when it genuinely adds value. Affiliate
   links are not allowed unless explicitly permitted.

4. PROTECT PRIVACY
   Do not share others' personal information. Do not screenshot or
   share private conversations without consent. Respect confidentiality.

5. NO DISCRIMINATION OR HATE SPEECH
   This community does not tolerate discrimination based on race,
   gender, sexuality, religion, nationality, disability, or any
   other characteristic. Zero tolerance.

6. ADD VALUE
   Before posting, ask: "Does this help someone?" Share knowledge,
   ask thoughtful questions, and contribute meaningfully.

7. FOLLOW PLATFORM RULES
   Adhere to the platform's Terms of Service in addition to these
   guidelines.

ENFORCEMENT
├── First offense: Warning via DM with specific guideline cited
├── Second offense: 24-48 hour mute/temporary restriction
├── Third offense: 1-week suspension
├── Severe violation: Immediate ban (hate speech, threats, doxxing)
└── Appeals: Contact [moderator/admin email] within 7 days

REPORTING
To report a violation, [describe mechanism: flag button, DM mod,
email, etc.]. All reports are reviewed within 24 hours.
Reports are confidential.
```

### 4.2 Moderation Decision Framework

```
MODERATION TRIAGE MATRIX
==========================

LOW SEVERITY (Warning):
├── Off-topic post in wrong channel
├── Mild self-promotion
├── Duplicate questions already answered
├── Low-quality or low-effort posts
├── Minor tone issues (dismissive, not hostile)
└── Action: Move/redirect post, DM gentle reminder

MEDIUM SEVERITY (Mute + Warning):
├── Repeated off-topic or spam posting
├── Aggressive tone or personal criticism
├── Sharing misinformation without malice
├── Ignoring previous warnings
├── Unsolicited DM campaigns to members
└── Action: Remove post, DM formal warning, temporary mute (24-48h)

HIGH SEVERITY (Suspension):
├── Targeted harassment of a member
├── Sharing others' private information
├── Coordinated disruptive behavior
├── Commercial spam (selling without permission)
├── Deliberately inflammatory content (trolling)
└── Action: Remove content, suspend (1-7 days), document incident

CRITICAL SEVERITY (Immediate Ban):
├── Hate speech or slurs
├── Threats of violence or harm
├── Sharing illegal content
├── Doxxing (publishing private personal information)
├── Sexual harassment or predatory behavior
├── Repeated high-severity violations
└── Action: Immediate ban, remove all content, report to platform

EDGE CASES (Escalate to Lead Moderator):
├── Disagreements between active contributors
├── Criticism of the brand/product (distinguish from trolling)
├── Political or sensitive social topics
├── Requests to share content from private channels
└── Members with large followings causing disruption
```

### 4.3 Moderator Playbook

```
MODERATOR RESPONSIBILITIES
============================

DAILY TASKS:
[ ] Review flagged/reported content
[ ] Check moderation queue (if approval-based)
[ ] Review new member applications
[ ] Respond to moderator channel discussions
[ ] Log any incidents in moderation log

WEEKLY TASKS:
[ ] Review ban/mute list for expiring actions
[ ] Discuss patterns or trends in mod team channel
[ ] Update FAQ if common questions emerge
[ ] Recognize helpful community members
[ ] Review and update auto-moderation rules

MONTHLY TASKS:
[ ] Moderator team meeting (sync on issues, celebrate wins)
[ ] Review community guidelines for needed updates
[ ] Analyze moderation metrics (incidents, response times)
[ ] Provide feedback to community manager on health trends
[ ] Update moderation documentation

MODERATION LOG TEMPLATE:
┌──────────┬──────────┬──────────┬──────────┬──────────┬──────────┐
│ Date     │ Member   │ Incident │ Severity │ Action   │ Mod      │
├──────────┼──────────┼──────────┼──────────┼──────────┼──────────┤
│ [Date]   │ [Name]   │ [Desc]   │ [L/M/H/C]│ [Taken]  │ [Who]    │
└──────────┴──────────┴──────────┴──────────┴──────────┴──────────┘

COMMUNICATION TEMPLATES:

GENTLE REDIRECT:
"Hey [Name], thanks for your enthusiasm! This topic fits better in
#[channel]. Would you mind reposting there? It will get better
visibility from people interested in this area."

FORMAL WARNING:
"Hi [Name], your recent post in #[channel] was removed because it
violates our guideline on [specific rule]. Please review our community
guidelines [link]. This is a friendly reminder -- we value your
participation and want to ensure a positive experience for everyone."

SUSPENSION NOTICE:
"Hi [Name], due to [specific behavior on specific date(s)], you have
been suspended from the community for [duration]. This action was taken
because [explanation]. You may appeal by contacting [contact info]
within 7 days."
```

---

## 5. Community Health Metrics

### 5.1 Community Health Scorecard

```
COMMUNITY HEALTH SCORECARD
============================
Period: [Date range]
Platform: [Discord/Slack/Forum/FB Group]

GROWTH METRICS
├── Total members: [X] (+/-[Y]% vs prior period)
├── New members this period: [X]
├── Members lost (left/removed): [X]
├── Net growth rate: [%]
└── Growth source breakdown: [Organic X%, Invited Y%, Paid Z%]

ENGAGEMENT METRICS
├── Daily Active Users (DAU): [X] ([Y]% of total)
├── Weekly Active Users (WAU): [X] ([Y]% of total)
├── Monthly Active Users (MAU): [X] ([Y]% of total)
├── DAU/MAU ratio: [X]% (benchmark: 20-30% is healthy)
├── Posts per day: [X]
├── Replies per post (average): [X]
├── Active contributors (posted 1+ times): [X] ([Y]% of total)
├── Lurker rate: [X]% (read-only, never posted)
└── Member-to-member interactions: [X]% of all interactions

CONTENT METRICS
├── Total posts/messages: [X]
├── User-generated content: [X]% of total
├── Questions asked: [X]
├── Questions answered: [X] ([Y]% answer rate)
├── Average time to first response: [X hours]
├── Top topics/channels by activity: [List]
└── Content sentiment: [Positive X%, Neutral Y%, Negative Z%]

RETENTION METRICS
├── 7-day retention: [X]% (new members active after 7 days)
├── 30-day retention: [X]%
├── 90-day retention: [X]%
├── Churn rate (monthly): [X]%
├── Reactivation rate: [X]% (inactive members returning)
└── Average member tenure: [X months]

HEALTH INDICATORS
├── Sentiment score: [1-10]
├── Response quality: [1-10]
├── Moderation incidents: [X] (trend: up/down/stable)
├── Member satisfaction (survey): [X/10]
├── Net Promoter Score: [X]
└── Overall health: [Thriving / Healthy / At Risk / Declining]

BUSINESS IMPACT
├── Support tickets deflected: [X] (est. savings: $[Y])
├── Product feedback items collected: [X]
├── Referrals generated: [X]
├── Community-sourced content: [X] pieces
├── Event attendance driven: [X]
└── Revenue influence: $[X] (attributed to community members)
```

### 5.2 Community Health Benchmarks

```
BENCHMARK RANGES BY COMMUNITY SIZE
====================================

METRIC             │ Small (<1K)  │ Medium (1-10K) │ Large (10K+)
───────────────────┼──────────────┼────────────────┼─────────────
DAU/MAU ratio      │ 25-40%       │ 15-30%         │ 10-25%
Engagement rate    │ 15-30%       │ 8-20%          │ 3-12%
Active contributors│ 10-25%       │ 5-15%          │ 2-8%
Lurker rate        │ 60-75%       │ 70-85%         │ 80-92%
7-day retention    │ 40-60%       │ 30-50%         │ 25-45%
30-day retention   │ 25-40%       │ 20-35%         │ 15-30%
Answer rate        │ 70-90%       │ 60-80%         │ 50-75%
Monthly churn      │ 3-8%         │ 5-12%          │ 8-15%

THE 1% RULE (community participation inequality):
├── 1% of members create content
├── 9% of members interact (comment, react)
├── 90% of members lurk (read only)
└── Goal: Shift ratios to 5/15/80 or better
```

---

## 6. Ambassador and Champion Programs

### 6.1 Ambassador Program Framework

```
AMBASSADOR PROGRAM DESIGN
===========================

PROGRAM PURPOSE:
[1-2 sentences: What ambassadors do and why it matters]

AMBASSADOR TIERS:
┌──────────────┬───────────────────┬──────────────────────┐
│ Tier         │ Requirements      │ Benefits             │
├──────────────┼───────────────────┼──────────────────────┤
│ Member       │ Join community    │ Access to community  │
│ Contributor  │ 10+ valuable posts│ Contributor badge    │
│              │ 3+ months active  │ Early access to news │
│ Ambassador   │ Apply + selected  │ Exclusive channel    │
│              │ 6+ months active  │ Direct team access   │
│              │ Consistent value  │ Swag / merch         │
│ Senior Amb.  │ 1+ year, mentor   │ Conference tickets   │
│              │ others, create    │ Product input role   │
│              │ original content  │ Reference/resume     │
└──────────────┴───────────────────┴──────────────────────┘

APPLICATION PROCESS:
1. Open applications quarterly (or rolling)
2. Application form with questions:
   ├── Why do you want to be an ambassador?
   ├── What value have you contributed to the community?
   ├── How would you promote and grow the community?
   └── What unique perspective or skills do you bring?
3. Review committee scores applications (team + existing ambassadors)
4. Interview top candidates (15-minute call)
5. Onboard selected ambassadors (welcome kit, training, expectations)

AMBASSADOR RESPONSIBILITIES:
├── Create 2-4 community posts per month
├── Answer questions from other members (aim for 5+ per week)
├── Attend monthly ambassador sync meeting
├── Represent the community at events (optional)
├── Provide product feedback and beta testing
├── Recruit new members through personal networks
└── Maintain positive, helpful community presence

AMBASSADOR METRICS:
├── Content created per month
├── Questions answered per week
├── Members mentored
├── Referrals generated
├── Event participation
├── Community satisfaction with ambassadors
└── Ambassador retention rate
```

### 6.2 Recognition and Rewards System

```
RECOGNITION FRAMEWORK
======================

INSTANT RECOGNITION (daily):
├── Public shout-out in community for great posts
├── Reaction with custom emoji (e.g., community-star)
├── Pin exceptional answers or contributions
└── Personal DM thanking the member

MILESTONE RECOGNITION (automated):
├── First post: Welcome badge
├── 10 posts: Active Contributor badge
├── 50 posts: Power Contributor badge
├── 100 posts: Community Legend badge
├── 1 year anniversary: Loyalty badge
├── First answered question: Helper badge
└── Custom milestones per community goals

SPOTLIGHT RECOGNITION (weekly/monthly):
├── "Member of the Week" post with interview/profile
├── Top contributors leaderboard (monthly)
├── "Best Answer" highlight thread
├── Feature member's work/project in community newsletter
└── Invite to speak at community event

REWARD TIERS:
├── Digital: Badges, custom roles, exclusive channels, early access
├── Physical: Stickers, t-shirts, swag box, books
├── Professional: LinkedIn recommendation, reference letter, resume line
├── Access: Direct line to product team, beta features, conference passes
└── Financial: Gift cards, subscription credits, commission on referrals
```

---

## 7. User-Generated Content (UGC)

### 7.1 UGC Strategy Framework

```
UGC PROGRAM DESIGN
====================

CONTENT TYPES TO ENCOURAGE:
├── Success stories and case studies
├── Tutorials and how-to guides
├── Tips and tricks
├── Templates and resources
├── Reviews and testimonials
├── Creative uses and hacks
├── Before/after transformations
└── Community challenge submissions

UGC MOTIVATION TACTICS:
├── Make it easy: Provide templates, prompts, and examples
├── Make it visible: Feature UGC prominently (pin, share, repost)
├── Make it rewarding: Badges, prizes, recognition
├── Make it social: Tag creators, facilitate connections
├── Make it purposeful: Connect to community goals or challenges
└── Make it safe: Clear guidelines on what is encouraged

UGC QUALITY STANDARDS:
├── Minimum quality bar (not everything gets featured)
├── Editing support available (offer to help polish content)
├── Attribution always given (never share without credit)
├── Content rights clearly defined (see legal section below)
└── Feedback loop (tell creators what made their content great)
```

### 7.2 Community Challenge Framework

```
COMMUNITY CHALLENGE TEMPLATE
==============================

CHALLENGE NAME: [Catchy, descriptive name]
DURATION: [1 week / 30 days / ongoing]
THEME: [Topic or skill area]

OBJECTIVE:
[What participants will achieve by completing the challenge]

RULES:
1. [Rule 1: What to create/do]
2. [Rule 2: How to submit]
3. [Rule 3: How winners are selected]
4. [Rule 4: Any restrictions]

DAILY/WEEKLY PROMPTS:
├── Day/Week 1: [Prompt]
├── Day/Week 2: [Prompt]
├── Day/Week 3: [Prompt]
└── Day/Week 4: [Prompt]

PRIZES:
├── Grand prize: [Prize for overall winner]
├── Category prizes: [Prizes for specific categories]
├── Participation prize: [Everyone who completes gets X]
└── Community choice: [Voted by members]

PROMOTION:
├── Announce 1 week before launch
├── Daily reminders during challenge
├── Share standout submissions publicly
├── Final recap post with all winners
└── Follow-up: Impact of the challenge (what was created)
```

---

## 8. Community Events

### 8.1 Event Types and Planning

```
EVENT TYPES FOR COMMUNITIES
=============================

AMA (Ask Me Anything):
├── Frequency: Weekly or bi-weekly
├── Duration: 30-60 minutes
├── Format: Live chat, voice channel, or video call
├── Guest: Team member, industry expert, or community leader
├── Prep: Collect questions in advance + live questions
└── Output: Summary post with key takeaways

WORKSHOP / TUTORIAL:
├── Frequency: Monthly
├── Duration: 60-90 minutes
├── Format: Live demo with Q&A, screen share
├── Topic: Hands-on skill building
├── Prep: Create materials, test demos, share prerequisites
└── Output: Recording, slides, and resource links

COMMUNITY CALL / TOWN HALL:
├── Frequency: Monthly or quarterly
├── Duration: 30-45 minutes
├── Format: Video call with presentation + open floor
├── Purpose: Updates, feedback, roadmap sharing, Q&A
├── Prep: Agenda shared in advance, collect topics from members
└── Output: Notes/recap posted in community

NETWORKING / SOCIAL:
├── Frequency: Monthly
├── Duration: 30-60 minutes
├── Format: Breakout rooms, speed networking, casual hangout
├── Purpose: Member-to-member connection
├── Prep: Icebreaker questions, breakout room assignments
└── Output: Follow-up introductions thread

CHALLENGE / HACKATHON:
├── Frequency: Quarterly
├── Duration: 1 day to 1 week
├── Format: Async submissions with live kickoff/finale
├── Purpose: Create, build, or solve something together
├── Prep: Clear brief, judging criteria, prizes
└── Output: Showcase submissions, announce winners
```

### 8.2 Event Execution Checklist

```
EVENT PLANNING CHECKLIST
=========================

2 WEEKS BEFORE:
[ ] Define event topic, format, and guest/speaker
[ ] Create event page/RSVP mechanism
[ ] Announce in community with event details
[ ] Share on social media channels
[ ] Send email to community mailing list
[ ] Prepare promotional graphics

1 WEEK BEFORE:
[ ] Send reminder to RSVPs
[ ] Prepare discussion questions or agenda
[ ] Test technology (video call, screen share, recording)
[ ] Brief guest/speaker on format and expectations
[ ] Create event-specific channel or thread

DAY OF EVENT:
[ ] Post reminder 2 hours before
[ ] Open event space 5 minutes early
[ ] Record the session (with consent)
[ ] Welcome attendees, share agenda
[ ] Moderate Q&A and time management
[ ] Thank participants and preview next event

AFTER EVENT:
[ ] Post recording and key takeaways within 24 hours
[ ] Share highlights on social media
[ ] Send thank-you to guest/speaker
[ ] Collect feedback (quick poll or survey)
[ ] Update event calendar with next dates
[ ] Review attendance and engagement metrics
```

---

## 9. Feedback Loops

### 9.1 Community-to-Product Feedback Pipeline

```
FEEDBACK COLLECTION → TRIAGE → PRIORITIZE → BUILD → CLOSE THE LOOP

STEP 1: COLLECTION
├── Dedicated #feedback channel with submission template
├── Regular feedback surveys (quarterly)
├── Feature request voting board (Canny, UserVoice, or simple polls)
├── AMA and town hall Q&A themes
├── Support ticket trend analysis
└── Direct conversation with power users

FEEDBACK SUBMISSION TEMPLATE:
"Please describe your feedback:
1. What are you trying to do?
2. What is the current experience?
3. What would the ideal experience look like?
4. How important is this to you? (Nice-to-have / Important / Critical)
5. How many people in your organization are affected?"

STEP 2: TRIAGE (weekly)
├── Categorize: Bug, Feature Request, Improvement, Question
├── Tag: Module, severity, frequency
├── Deduplicate: Merge similar requests
├── Quantify: How many members requested this?
└── Assign: Route to appropriate product or engineering team

STEP 3: PRIORITIZE (monthly)
├── Score using RICE or ICE framework
├── Map to product roadmap themes
├── Communicate prioritization decisions
└── Update public roadmap if applicable

STEP 4: BUILD
├── Notify requesters when work begins
├── Invite beta testing from requesters
└── Share progress updates in community

STEP 5: CLOSE THE LOOP
├── Announce when feature ships
├── Tag original requesters
├── Share in community: "You asked, we built"
├── Collect feedback on the implementation
└── Thank contributors publicly
```

### 9.2 Community Satisfaction Survey

```
COMMUNITY SATISFACTION SURVEY (Quarterly)
==========================================

1. How satisfied are you with this community overall? (1-10)

2. How likely are you to recommend this community to a colleague? (0-10, NPS)

3. What do you value most about this community? (Select top 3)
   [ ] Learning new skills
   [ ] Networking with peers
   [ ] Getting help with problems
   [ ] Staying up to date on industry trends
   [ ] Access to exclusive content
   [ ] Feeling part of a group
   [ ] Direct access to the team
   [ ] Career advancement
   [ ] Other: ___

4. What could be improved? (Open text)

5. How often do you participate? (Daily / Weekly / Monthly / Rarely)

6. What type of content would you like to see more of? (Select all)
   [ ] Tutorials and how-tos
   [ ] Industry analysis
   [ ] Case studies
   [ ] Networking events
   [ ] AMAs with experts
   [ ] Job opportunities
   [ ] Challenges and competitions
   [ ] Other: ___

7. Do you feel welcome and included in this community? (Yes / Somewhat / No)

8. Any additional comments or suggestions? (Open text)
```

---

## 10. Crisis Communication in Communities

### 10.1 Community-Specific Crisis Playbook

```
COMMUNITY CRISIS TYPES
========================

TYPE 1: PRODUCT OUTAGE OR BUG
├── Impact: Members frustrated, flooding channels with reports
├── Response time: < 30 minutes
├── Actions:
│   ├── Post acknowledgment in #announcements
│   ├── Create dedicated #incident thread
│   ├── Provide updates every 30-60 minutes
│   ├── Share workarounds if available
│   └── Post resolution and post-mortem summary
└── Template: "We are aware of [issue]. Our team is investigating.
    We will update this thread every [30 min]. Current status: [status]."

TYPE 2: MEMBER CONFLICT
├── Impact: Heated argument visible to community
├── Response time: < 1 hour
├── Actions:
│   ├── Move discussion to private channel or DM
│   ├── Hear both sides separately
│   ├── Apply moderation policy (warn, mute, or ban as appropriate)
│   ├── Post calm, neutral message in original thread
│   └── Follow up with affected members privately
└── Template: "We appreciate passionate discussions, but let's keep
    the conversation respectful. We've reached out to those involved
    privately. Let's refocus on [topic]."

TYPE 3: COMMUNITY TRUST BREACH
├── Impact: Data leak, broken promise, controversial decision
├── Response time: < 2 hours
├── Actions:
│   ├── Internal alignment on facts and response
│   ├── Transparent acknowledgment to community
│   ├── Specific actions being taken to remedy
│   ├── Open Q&A or town hall for member questions
│   └── Follow-up report on changes made
└── Template: "We owe you transparency about [situation]. Here is
    what happened: [facts]. Here is what we are doing: [actions].
    We will host a Q&A on [date] to address your questions."

TYPE 4: TROLL INVASION OR RAID
├── Impact: Sudden influx of bad-faith actors
├── Response time: Immediate
├── Actions:
│   ├── Enable slow mode or restricted posting
│   ├── Activate all moderators
│   ├── Ban offending accounts
│   ├── Temporarily restrict new member posting
│   └── Reassure existing members
└── Template: "We are experiencing a spike in disruptive activity.
    Our mod team is handling it. Normal service will resume shortly.
    Thank you for your patience."
```

---

## 11. Toxicity Handling

### 11.1 Toxicity Detection Framework

```
TOXICITY SPECTRUM
==================

LEVEL 1: FRICTION (Normal, manageable)
├── Disagreements on opinions
├── Blunt or curt communication style
├── Minor frustration expressed
├── Passive-aggressive comments
└── Response: Monitor, nudge toward constructive tone

LEVEL 2: INCIVILITY (Requires intervention)
├── Personal insults ("you're an idiot")
├── Dismissive comments ("that's a stupid question")
├── Condescending tone ("clearly you don't understand")
├── Gatekeeping ("you shouldn't be here if you don't know X")
└── Response: DM warning, remove comment if public, redirect

LEVEL 3: HARASSMENT (Immediate action)
├── Targeted, repeated negative behavior toward a member
├── Bullying or intimidation
├── Unwanted sexual attention
├── Stalking across channels or platforms
├── Coordinated attacks on a member
└── Response: Immediate mute, investigate, likely ban

LEVEL 4: HATE / VIOLENCE (Zero tolerance)
├── Slurs, hate speech, discriminatory language
├── Threats of violence
├── Doxxing or sharing private information
├── Content promoting harm
└── Response: Immediate permanent ban, report to platform, document

PROACTIVE PREVENTION:
├── Set clear expectations in guidelines (tone matters)
├── Model the behavior you want (team members lead by example)
├── Celebrate constructive disagreement
├── Create "new member" role with limited posting initially
├── Auto-moderation filters for slurs and known toxic phrases
├── Regular community values reinforcement posts
├── Anonymous reporting mechanism
└── Moderator training on bias and de-escalation
```

### 11.2 De-escalation Techniques

```
DE-ESCALATION PLAYBOOK
========================

TECHNIQUE 1: ACKNOWLEDGE AND REDIRECT
"I can see you feel strongly about this. Let's focus on [specific
constructive aspect]. What solution would you suggest?"

TECHNIQUE 2: PRIVATE CONVERSATION
Move the discussion to DMs. People are less confrontational in private.
"Hey [Name], I'd love to hear more about your perspective. Can we
chat privately for a moment?"

TECHNIQUE 3: NAME THE BEHAVIOR, NOT THE PERSON
"That comment comes across as dismissive. In this community, we
aim to keep feedback constructive. Could you rephrase?"
(Not: "You're being rude.")

TECHNIQUE 4: COOL DOWN PERIOD
"This thread is getting heated. Let's take a breather and come back
to this in a few hours with fresh perspectives."

TECHNIQUE 5: REFRAME THE CONVERSATION
"Instead of debating who's right, let's explore what we can learn
from both viewpoints. [Name], what's the core concern behind your
position?"

TECHNIQUE 6: EMPATHIZE THEN REDIRECT
"I understand the frustration with [issue]. That's valid. Here's
what we're doing about it: [action]. In the meantime, let's keep
the discussion productive."
```

---

## 12. Community-Led Growth (CLG)

### 12.1 Community-Led Growth Framework

```
COMMUNITY-LED GROWTH FLYWHEEL
===============================

            ┌─── ATTRACT ───┐
            │  Content,      │
            │  Events, SEO   │
            ▼                │
      ┌──────────┐    ┌──────────┐
      │ ENGAGE   │───>│ ACTIVATE │
      │ Discuss, │    │ First    │
      │ Learn,   │    │ value,   │
      │ Connect  │    │ Aha      │
      └──────────┘    └──────────┘
            ▲                │
            │                ▼
      ┌──────────┐    ┌──────────┐
      │ ADVOCATE │<───│ CONVERT  │
      │ Refer,   │    │ Sign up, │
      │ Create,  │    │ Buy,     │
      │ Speak    │    │ Upgrade  │
      └──────────┘    └──────────┘

MEASURE CLG IMPACT:
├── Community-sourced leads: Members who become customers
├── Community-influenced deals: Prospects who engaged community
├── Support deflection: Questions answered by community (not support)
├── Product feedback loop: Ideas from community shipped
├── Content amplification: UGC and member shares
├── Referral pipeline: New members/customers from existing members
└── Retention lift: Community members vs non-members churn rate
```

### 12.2 Community Growth Metrics Dashboard

```
COMMUNITY-LED GROWTH DASHBOARD
================================

ACQUISITION IMPACT:
├── New members this month: [X]
├── Members who became customers: [X] (conversion rate: [%])
├── Pipeline influenced by community: $[X]
├── Referral sign-ups from members: [X]
└── Website traffic from community: [X] sessions

RETENTION IMPACT:
├── Community member churn rate: [X]% vs non-member: [Y]%
├── Community member NPS: [X] vs non-member: [Y]
├── Average contract value (community vs non): $[X] vs $[Y]
├── Expansion revenue from community members: $[X]
└── Feature adoption (community vs non): [X]% vs [Y]%

SUPPORT IMPACT:
├── Questions answered by community: [X]
├── Estimated support tickets deflected: [X]
├── Support cost savings: $[X]
├── Average resolution time (community): [X hours]
├── Knowledge base articles created from community: [X]
└── Top community-answered topics: [List]

PRODUCT IMPACT:
├── Feature requests submitted: [X]
├── Feature requests shipped: [X]
├── Beta testers recruited: [X]
├── Bug reports from community: [X]
├── Product satisfaction (community members): [X/10]
└── Ideas in current roadmap sourced from community: [X]
```

---

## 13. Community Guidelines Document Template

```
[COMMUNITY NAME] COMMUNITY GUIDELINES
========================================
Last Updated: [Date]

WELCOME
We are glad you are here. [Community Name] is a space for [purpose].
Whether you are [persona 1], [persona 2], or [persona 3], this
community is for you.

OUR VALUES
1. [Value 1]: [Brief explanation]
2. [Value 2]: [Brief explanation]
3. [Value 3]: [Brief explanation]
4. [Value 4]: [Brief explanation]

WHAT THIS COMMUNITY IS FOR
- [Encouraged behavior/content 1]
- [Encouraged behavior/content 2]
- [Encouraged behavior/content 3]
- [Encouraged behavior/content 4]

WHAT THIS COMMUNITY IS NOT FOR
- [Discouraged behavior/content 1]
- [Discouraged behavior/content 2]
- [Discouraged behavior/content 3]

THE RULES
[See Section 4.1 for detailed guidelines template]

HOW WE MODERATE
[See Section 4.2 for moderation decision framework]

HOW TO GET THE MOST OUT OF THIS COMMUNITY
1. Introduce yourself in #introductions
2. Check pinned messages in each channel
3. Ask questions -- no question is too basic
4. Share your knowledge -- someone needs what you know
5. Attend events -- they are the fastest way to connect
6. Be patient -- not everyone is in the same time zone

HOW TO GET HELP
- Community questions: Post in #ask-the-community
- Technical support: Post in #help or create a ticket
- Report an issue: DM any moderator or use the report function
- Community feedback: Post in #feedback

CONTACT
Community Manager: [Name, handle]
Moderator Team: [Handles or email]
General inquiries: [Email]
```
