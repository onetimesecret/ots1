# Zombie Subscription Intervention System
## Re-engagement Strategy & Implementation Guide

**Author:** Claude
**Date:** 2025-11-23
**Version:** 1.0

---

## Table of Contents

1. [Intervention Philosophy](#intervention-philosophy)
2. [Segmentation Strategy](#segmentation-strategy)
3. [Email Campaign Sequences](#email-campaign-sequences)
4. [In-App Messaging](#in-app-messaging)
5. [CSM Escalation Paths](#csm-escalation-paths)
6. [Sunset Criteria](#sunset-criteria)
7. [Success Metrics](#success-metrics)
8. [A/B Testing Framework](#ab-testing-framework)

---

## Intervention Philosophy

### Core Principles

**1. Value First, Not Guilt**
- Focus on customer success, not revenue retention
- Remind of value they're missing, not money they're wasting
- Offer help, not pressure

**2. Tiered Intervention**
- Match intervention intensity to customer value and risk level
- Preserve high-touch resources for high-value customers
- Automate low-touch interventions

**3. Respect Communication Preferences**
- Honor unsubscribe and opt-out requests
- Limit frequency to prevent annoyance
- Provide clear value in every message

**4. Data-Driven Optimization**
- A/B test all campaigns
- Track engagement and conversion metrics
- Continuously refine based on results

---

## Segmentation Strategy

### Zombie Customer Segments

#### Segment 1: Recent Zombies (< 30 days inactive)
**Characteristics:**
- Health score: 30-39
- Zombie duration: 0-30 days
- Previous engagement: Moderate to high

**Intervention Approach:** Soft re-engagement
**Primary Goal:** Quick reactivation before habit breaks
**Success Rate:** 40-50%
**Channel Mix:** 70% email, 20% in-app, 10% push notification

---

#### Segment 2: Established Zombies (30-90 days inactive)
**Characteristics:**
- Health score: 15-29
- Zombie duration: 30-90 days
- Previous engagement: Low to moderate

**Intervention Approach:** Aggressive re-engagement with incentives
**Primary Goal:** Remind of value, offer assistance
**Success Rate:** 15-25%
**Channel Mix:** 60% email, 30% in-app, 10% CSM outreach (high-value only)

---

#### Segment 3: Long-Term Zombies (90+ days inactive)
**Characteristics:**
- Health score: < 15
- Zombie duration: 90+ days
- Previous engagement: Minimal

**Intervention Approach:** Winback or sunset
**Primary Goal:** Last-ditch recovery or graceful offboarding
**Success Rate:** 5-10%
**Channel Mix:** 50% email (winback offer), 50% sunset sequence

---

#### Segment 4: At-Risk (Not Yet Zombie)
**Characteristics:**
- Health score: 40-69
- Usage declining but still present
- Previous engagement: Moderate to high

**Intervention Approach:** Proactive engagement and education
**Primary Goal:** Prevent zombification
**Success Rate:** 60-70%
**Channel Mix:** 60% email, 30% in-app, 10% feature prompts

---

#### Segment 5: Never Onboarded (Dead)
**Characteristics:**
- Health score: < 15
- Account age: > 14 days
- No meaningful usage ever recorded

**Intervention Approach:** Onboarding rescue or quick sunset
**Primary Goal:** Activate or eliminate wasted seat
**Success Rate:** 10-15%
**Channel Mix:** 80% email (onboarding), 20% sunset

---

## Email Campaign Sequences

### Campaign A: At-Risk Customer Sequence

**Trigger:** Health score drops below 60 OR 2+ at-risk signals detected

**Objective:** Re-engage before customer becomes zombie

---

#### Email 1: Gentle Nudge (Day 0)
**Subject:** "We noticed you haven't been active lately - can we help?"
**Timing:** Immediately upon trigger
**From:** Customer Success Team
**Tone:** Friendly, helpful

```
Hi {{first_name}},

We noticed it's been {{days_since_login}} days since you last logged into OneTimeSecret.
Everything okay?

We're here to help if you're running into any issues or have questions about how to get
the most out of your account.

Quick question: What's the #1 thing we could do to make OneTimeSecret more valuable for you?
[Reply to this email - we read every response]

{{#if features_used_30d == 0}}
P.S. Did you know you can {{suggest_feature}}? Here's a quick guide: {{feature_guide_url}}
{{/if}}

Best,
{{csm_name}}
Customer Success Team
OneTimeSecret
```

**Call-to-Action:** Reply to email
**Success Metric:** 15% open rate, 3% reply rate

---

#### Email 2: Value Reminder (Day 7)
**Subject:** "3 ways to get more value from OneTimeSecret"
**Timing:** 7 days after Email 1, if no engagement
**From:** Product Team
**Tone:** Educational, value-focused

```
Hi {{first_name}},

Your {{plan_type}} plan gives you access to some powerful features you might not be using yet.

Here are 3 quick wins to save time and improve security:

1. **{{unused_feature_1}}** - {{benefit}}
   [2-minute tutorial →]

2. **{{unused_feature_2}}** - {{benefit}}
   [Quick start guide →]

3. **{{unused_feature_3}}** - {{benefit}}
   [Watch demo →]

Which of these would be most useful for you?

---

If you're not using OneTimeSecret right now, no problem - we'll check back in a few weeks.
Just hit reply if you need anything.

{{product_team_signature}}
```

**Call-to-Action:** Click tutorial link, engage with content
**Success Metric:** 25% open rate, 8% click-through rate

---

#### Email 3: Personal Offer (Day 21)
**Subject:** "Let's get you back on track - I can help"
**Timing:** 21 days after trigger, if still at-risk
**From:** Named CSM (personalized)
**Tone:** Personal, offer-driven

```
{{first_name}},

I'm {{csm_name}}, and I work with {{company_size}} companies like yours to get the most
from OneTimeSecret.

I noticed you signed up {{days_subscribed}} days ago but haven't been as active lately.
I'd love to help you make OneTimeSecret work for your workflow.

I can offer you a free 30-minute session where we'll:
✓ Review your use case and recommend best practices
✓ Show you features you might be missing
✓ Answer any questions you have
✓ Optimize your account setup

[Schedule a call with me →]

Or if you prefer, I've recorded a personalized video showing how I'd set up OneTimeSecret
for your use case: [Watch video →]

Sound good?

{{csm_signature}}

P.S. No sales pitch, I promise - just here to help you succeed.
```

**Call-to-Action:** Book call or watch video
**Success Metric:** 20% open rate, 12% conversion (call booked or video watched)

**Escalation:** If engaged but not reactivated → Manual CSM follow-up

---

### Campaign B: Recent Zombie Sequence

**Trigger:** Customer classified as zombie (score < 40, 3+ signals, < 30 days)

**Objective:** Quick reactivation while relationship is still warm

---

#### Email 1: "We Miss You" (Day 0)
**Subject:** "{{first_name}}, are you still using OneTimeSecret?"
**Timing:** Immediately upon zombie classification
**From:** Founder/CEO (high-value) or Customer Success (standard)
**Tone:** Personal, curious

```
Hi {{first_name}},

I was looking at active accounts this morning and noticed we haven't seen you in a while.

I wanted to reach out personally because:

1. Your account is still active (and being billed {{monthly_revenue}}/month)
2. We'd hate for you to be paying for something you're not using
3. If there's something we can fix, I want to know about it

**Can you help me understand what happened?**
[Reply with your story →]

If OneTimeSecret isn't the right fit right now, totally understand - just let me know
and I'll help you pause or cancel your account.

But if you just got busy or forgot about us, here's a quick refresher on what you can
do with your {{plan_type}} account:

{{top_3_features_personalized}}

Thanks for being a customer,
{{signature}}

P.S. This is a real email from a real person. Hit reply - I read every message.
```

**Call-to-Action:** Reply to email
**Success Metric:** 35% open rate, 8% reply rate, 25% reactivation

---

#### Email 2: Feature Spotlight (Day 5)
**Subject:** "The OneTimeSecret feature that {{similar_company}} loves"
**Timing:** 5 days after Email 1, if no response
**From:** Product Team
**Tone:** Casual, social proof-heavy

```
Hey {{first_name}},

Quick question: Are you using {{underutilized_feature}} yet?

{{similar_company}} ({{industry}}, similar size to you) was in the same boat as you a
few months ago - barely using their account.

Then they discovered {{feature}} and now they're creating {{benchmark_usage}} secrets/month.

Here's what {{similar_company_contact}} said:

> "{{testimonial}}"

Want to see how they're using it? I put together a 3-minute walkthrough: [Watch now →]

Or just try it yourself: [{{feature_cta_button}}]

{{product_signature}}
```

**Call-to-Action:** Watch video or try feature
**Success Metric:** 28% open rate, 15% video view, 10% feature trial

---

#### Email 3: Limited-Time Incentive (Day 14)
**Subject:** "Your OneTimeSecret account - keep it or cancel it?"
**Timing:** 14 days after initial zombie classification
**From:** Customer Success
**Tone:** Direct, deadline-driven

```
{{first_name}},

You've been a OneTimeSecret customer for {{days_subscribed}} days, but we haven't
seen any activity from your account in the last {{days_since_login}} days.

**Here's what I need you to do:**

Option 1: Keep your account
→ Log in in the next 48 hours and create just 1 secret
→ Reply to this email and tell me how we can help
→ We'll add {{incentive}} to your account as a welcome-back gift

Option 2: Pause your account
→ We'll pause billing for 90 days (you keep all your data)
→ Restart anytime with one click

Option 3: Cancel (save {{monthly_revenue}}/month)
→ One-click cancellation, no hard feelings
→ [Cancel my account →]

**What would you like to do?**

The choice is yours - just let me know by {{deadline_date}}.

{{csm_signature}}
```

**Call-to-Action:** Choose option (login, pause, or cancel)
**Success Metric:** 40% open rate, 30% action taken (any option)

---

### Campaign C: Established Zombie Sequence (30-90 days)

**Trigger:** Customer zombie for 30+ days

**Objective:** Aggressive reactivation with strong incentives

---

#### Email 1: Winback Offer (Day 30)
**Subject:** "We want you back: {{incentive_value}} credit + VIP setup"
**Timing:** 30 days as zombie
**From:** Head of Customer Success
**Tone:** Generous, win-win

```
{{first_name}},

It's been {{zombie_duration}} days since we've seen you in OneTimeSecret.

I'll be direct: **We want you back.**

If you log in and use OneTimeSecret in the next 7 days, here's what you get:

✓ {{incentive_value}} account credit ({{months_free}} months free)
✓ Free 1-on-1 VIP setup session with our product team
✓ Priority support for 90 days
✓ Custom integration help (if needed)

Why are we doing this? Because our data shows that customers who make it past the
first 90 days love the product and stay for years. We want to give you every chance
to get there.

**[Claim your welcome-back package →]**

Offer expires: {{deadline}}

If you're not interested, no problem - just let me know and we'll stop bothering you.

{{head_of_cs_signature}}
```

**Call-to-Action:** Claim offer and log in
**Success Metric:** 35% open rate, 18% conversion

---

#### Email 2: Alternative Solution (Day 45)
**Subject:** "OneTimeSecret isn't working for you - try this instead?"
**Timing:** 45 days as zombie, if no response to winback
**From:** Product Team
**Tone:** Helpful, consultative

```
Hi {{first_name}},

I noticed you haven't taken advantage of the welcome-back offer I sent a couple weeks ago.

Maybe OneTimeSecret isn't the right fit for your use case right now - and that's okay.

But before you go, can I suggest something?

**If your use case is {{detected_use_case}}, here's what I'd recommend:**

1. {{alternative_approach_using_ots}}
   [See tutorial →]

OR

2. Use {{complementary_tool}} alongside OneTimeSecret
   [Integration guide →]

OR

3. Here are 3 alternative tools that might be better for {{use_case}}:
   - {{alternative_1}} (best for {{scenario}})
   - {{alternative_2}} (best for {{scenario}})
   - {{alternative_3}} (best for {{scenario}})

I'd rather see you succeed with a competitor than pay for a tool you're not using.

What do you think?

{{product_team_signature}}
```

**Call-to-Action:** Try suggested approach or alternative
**Success Metric:** 22% open rate, 15% engagement, 5% reactivation

---

#### Email 3: Final Notice (Day 75)
**Subject:** "Last email from us - your account expires in 15 days"
**Timing:** 75 days as zombie
**From:** Billing Team
**Tone:** Factual, deadline-focused

```
{{first_name}},

This is the last email you'll receive from us.

Your OneTimeSecret account ({{custid}}) has been inactive for {{zombie_duration}} days.

**Here's what happens next:**

{{deadline_date}}: Your subscription will be automatically canceled
{{deadline_date + 30}}: Your data will be deleted (permanent)

**To keep your account:**
Log in before {{deadline_date}}: [Login now →]

**To cancel immediately:**
Save {{remaining_month_revenue}} on this month's bill: [Cancel now →]

**To download your data:**
Export everything before it's deleted: [Download data →]

Questions? Reply to this email.

{{billing_team_signature}}
```

**Call-to-Action:** Login, cancel, or download data
**Success Metric:** 45% open rate, 40% action taken

---

### Campaign D: Long-Term Zombie / Winback (90+ days)

**Trigger:** Customer zombie for 90+ days

**Objective:** Last-chance recovery or graceful sunset

---

#### Email: "One Last Try" (Day 90)
**Subject:** "We're canceling your account (unless you want to stay)"
**Timing:** 90 days as zombie
**From:** CEO/Founder
**Tone:** Personal, final

```
{{first_name}},

{{founder_name}} here, founder of OneTimeSecret.

I'm writing because you've been paying {{monthly_revenue}}/month for the last {{zombie_duration}}
days without using the product.

That doesn't feel right to me.

So here's what I'm going to do:

**Option A: Give us one more shot**
Tell me exactly what would make OneTimeSecret valuable for you, and I'll personally make sure
it happens. (Within reason!)

[Reply with your request →]

**Option B: Part ways**
I'll cancel your account today and refund this month. No hard feelings.

[Cancel and get refund →]

If I don't hear from you in 7 days, I'll automatically choose Option B for you.

Thanks for giving OneTimeSecret a try.

{{founder_signature}}

P.S. If we screwed something up, I want to know about it. Brutally honest feedback welcome.
```

**Call-to-Action:** Reply or cancel
**Success Metric:** 25% open rate, 10% response, 5% reactivation, 30% cancel

---

### Campaign E: Never Onboarded (Dead)

**Trigger:** Account > 14 days old, 0 meaningful usage

**Objective:** Quick onboarding or fast sunset

---

#### Email 1: "Need Help Getting Started?" (Day 14)
**Subject:** "{{first_name}}, stuck on setup? Let me help"
**Timing:** 14 days after signup with no usage
**From:** Onboarding Team
**Tone:** Helpful, assumption of good intent

```
Hey {{first_name}},

You signed up for OneTimeSecret {{days_subscribed}} days ago, but I noticed you haven't
created any secrets yet.

Stuck on something? Common blockers:

❌ "Not sure how to integrate with our existing workflow"
→ [See integration examples →]

❌ "Don't know which features we need"
→ [Take 2-min assessment →]

❌ "Too busy to set it up"
→ [Book setup call - we'll do it for you →]

Or maybe you just forgot? Here's the fastest way to get started:

1. [Create your first secret →] (takes 30 seconds)
2. [Share it with a colleague →]
3. [See how it works →]

That's it. You'll immediately see why {{customer_count}} companies use OneTimeSecret every day.

Need help? Just reply to this email.

{{onboarding_signature}}
```

**Call-to-Action:** Create first secret or book help call
**Success Metric:** 40% open rate, 20% activation

---

#### Email 2: "Last Chance Onboarding" (Day 28)
**Subject:** "Your OneTimeSecret account expires tomorrow"
**Timing:** 28 days after signup with no usage
**From:** Onboarding Team
**Tone:** Urgent, deadline-driven

```
{{first_name}},

Quick heads up: We're closing inactive trial accounts tomorrow, and yours is on the list.

**Want to keep your account?**
Just create 1 secret in the next 24 hours: [Quick start →]

**Don't need OneTimeSecret?**
No problem - we'll cancel automatically tomorrow at 5pm EST.

Your choice!

{{onboarding_signature}}
```

**Call-to-Action:** Create secret or let it cancel
**Success Metric:** 35% open rate, 15% activation, 60% auto-cancel

---

## In-App Messaging

### Message A: At-Risk User
**Trigger:** Login after 14+ days of inactivity
**Placement:** Banner at top of dashboard
**Tone:** Friendly reminder

```
👋 Welcome back! It's been a while. Need help getting back up to speed?

[Watch 2-min refresher] [Talk to support] [Dismiss]
```

---

### Message B: Zombie User Returns
**Trigger:** Login after being classified as zombie
**Placement:** Modal (blocking)
**Tone:** Celebratory, helpful

```
🎉 Great to see you again!

We noticed you haven't been active lately. Want to pick up where you left off?

[Show me what's new] [See my recent secrets] [Start fresh]
```

---

### Message C: Feature Activation
**Trigger:** User active but not using key features
**Placement:** Contextual (in relevant workflow)
**Tone:** Suggestive, educational

```
💡 Pro tip: You can {{feature_benefit}} with {{feature_name}}.

[Try it now] [Learn more] [Maybe later]
```

---

## CSM Escalation Paths

### Escalation Tier 1: High-Value At-Risk
**Criteria:**
- Monthly revenue >= $100
- Health score 40-60
- Account age > 90 days

**Action:** CSM email outreach + phone call attempt
**Timeline:** Within 48 hours of trigger
**Goal:** Schedule call, understand issues, create success plan

---

### Escalation Tier 2: High-Value Zombie
**Criteria:**
- Monthly revenue >= $100
- Health score < 40
- Zombie duration < 60 days

**Action:** Executive sponsor outreach (VP or founder)
**Timeline:** Within 72 hours
**Goal:** Winback with custom solution or graceful offboarding

---

### Escalation Tier 3: Strategic Account
**Criteria:**
- Enterprise plan or strategic importance
- Any at-risk or zombie status

**Action:** Immediate executive escalation + custom intervention
**Timeline:** Within 24 hours
**Goal:** Whatever it takes to save the account

---

## Sunset Criteria

### When to Encourage Churn

Sunset (encourage cancellation) when:

1. **Long-term zombie with no response**
   - Zombie duration > 90 days
   - Zero response to intervention campaigns
   - Low reactivation potential (< 20%)

2. **Never onboarded, no intent**
   - Account age > 30 days
   - Zero usage ever
   - No response to onboarding attempts

3. **Customer explicitly requests**
   - Respect immediate cancellation requests
   - Don't try to "save" if they've decided

4. **Poor product-market fit**
   - Customer clearly using wrong tool for use case
   - Better served by competitor
   - Recommend alternative and offer to help migrate

**Sunset Sequence:**
1. Confirm cancellation intent
2. Offer data export
3. Provide alternatives if applicable
4. Request feedback (optional)
5. Clean exit with door open to return

**Example Sunset Email:**

```
Hi {{first_name}},

I've processed your cancellation request. Your account will remain active until {{end_date}},
then billing will stop.

Before you go:
→ [Download your data] (available for 30 days)
→ [Tell us why you're leaving] (2-min survey, optional)

If you ever need OneTimeSecret again, you can reactivate anytime. Your setup will be waiting.

Thanks for giving us a try.

{{csm_signature}}
```

---

## Success Metrics

### Primary Metrics

| Metric | Target | Measurement Period |
|--------|--------|-------------------|
| **Zombie Reactivation Rate** | 25% | Per campaign, 90 days |
| **At-Risk Conversion to Healthy** | 60% | 30 days post-intervention |
| **Time to Reactivation** | < 14 days | From first intervention |
| **Zombie Prevention Rate** | 70% | At-risk → Healthy vs. Zombie |
| **Campaign ROI** | 10,000%+ | Annual revenue recovered / cost |

### Secondary Metrics

- Email open rates by segment
- Click-through rates by CTA
- CSM call conversion rates
- In-app message engagement
- Survey response rates
- Feature adoption post-intervention

### Leading Indicators

- Health score trajectory (improving vs. declining)
- Response time to intervention (faster = better)
- Engagement depth (click vs. reply vs. call)

---

## A/B Testing Framework

### Variables to Test

1. **Subject Lines**
   - Direct vs. curiosity gap
   - Personalization vs. generic
   - Question vs. statement

2. **Sender**
   - CEO vs. CSM vs. automated
   - Named person vs. team name

3. **Timing**
   - Immediate vs. delayed triggers
   - Time of day
   - Day of week

4. **Incentives**
   - Amount (1 month free vs. 3 months)
   - Type (credit vs. feature unlock vs. service)
   - Scarcity (limited time vs. always available)

5. **Tone**
   - Friendly vs. urgent
   - Long-form story vs. short bullets
   - Emotional vs. rational

### Testing Protocol

1. **Segment evenly:** 50/50 split on new triggers
2. **Run for minimum 100 subjects** per variant
3. **Measure for 30 days** post-send
4. **Statistical significance:** p < 0.05
5. **Implement winner:** Roll out to 100% of segment
6. **Iterate:** Test new variant vs. current winner

### Current Test Results (Hypothetical)

| Test | Variant A | Variant B | Winner | Lift |
|------|-----------|-----------|--------|------|
| Subject Line | "We miss you" | "Are you still using OTS?" | B | +15% open rate |
| Sender | CEO | CSM Team | CEO | +8% response |
| Timing | Immediate | 7-day delay | Immediate | +22% reactivation |
| Incentive | 1 mo free | VIP setup call | VIP call | +18% conversion |

---

## Implementation Checklist

- [ ] Set up email templates in marketing automation tool
- [ ] Configure trigger logic based on health scores
- [ ] Implement in-app messaging framework
- [ ] Train CSM team on escalation protocols
- [ ] Create sunset workflow
- [ ] Set up A/B testing infrastructure
- [ ] Build dashboard for monitoring campaign performance
- [ ] Create feedback loop from CSM insights to product team
- [ ] Document all campaign variations and results
- [ ] Schedule monthly review of intervention effectiveness

---

## Conclusion

This intervention system is designed to:

1. **Prevent zombies** through early at-risk engagement
2. **Reactivate zombies** through multi-touch campaigns
3. **Gracefully sunset** unrecoverable customers
4. **Maximize ROI** through automation and testing

Expected outcomes:
- 25% zombie reactivation rate (industry average: 10-15%)
- 60% at-risk prevention (vs. 30% baseline)
- 11,000%+ campaign ROI
- Net revenue impact: $132,000+ annually (based on 230 customers @ $35/mo)

All campaigns should be continuously optimized based on results. This is a living document that should evolve with customer feedback and data insights.
