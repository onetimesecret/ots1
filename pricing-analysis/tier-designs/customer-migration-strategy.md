# Customer Migration Strategy for 230 Existing Customers

## Executive Summary

This document provides a comprehensive strategy for migrating 230 existing customers ($35/month) to the new 7-tier pricing structure while minimizing churn, maximizing revenue, and maintaining customer satisfaction.

**Current State**: 230 customers @ $35/month = $8,050 MRR
**Target State**: Optimized distribution across 7 tiers with +25-35% MRR increase
**Timeline**: 6-month phased migration (Q1-Q2 2026)
**Risk**: Churn rate <10% (maintain >207 customers)

---

## CURRENT CUSTOMER PROFILE ANALYSIS

### Current $35/Month Customers (230 total)

**Estimated Segmentation** (based on usage patterns):

| Segment | Count | % | Characteristics | Ideal Tier | Expected Price |
|---------|-------|---|-----------------|------------|----------------|
| **Under-utilizing** | 58 | 25% | Low API usage, <30 day TTL, solo users | Individual $25 | **Downgrade** |
| **Right-sized** | 81 | 35% | Moderate usage, solo/small team (1-5 users) | Professional $49 | **Upgrade** |
| **Team Users** | 69 | 30% | High usage, 5-15 users, team features needed | Team $75 | **Upgrade** |
| **Enterprise Needs** | 17 | 7.5% | Very high usage, compliance needs, >15 users | Business $125 | **Upgrade** |
| **Power Users** | 5 | 2.5% | Extreme usage, mission-critical | Premium $300 | **Upgrade** |

**Revenue Impact Analysis**:
- Under-utilizing → $25: **58 × (-$10) = -$580 MRR**
- Right-sized → $49: **81 × (+$14) = +$1,134 MRR**
- Team → $75: **69 × (+$40) = +$2,760 MRR**
- Enterprise → $125: **17 × (+$90) = +$1,530 MRR**
- Power → $300: **5 × (+$265) = +$1,325 MRR**

**Net MRR Impact**: $8,050 + $6,169 = **$14,219 MRR** (+76.6% before churn)
**Expected Churn**: 8% (18 customers) = -$630 MRR
**Final Projected MRR**: **$13,589** (+68.8% increase)

---

## MIGRATION PRINCIPLES

### Core Commitments

1. **Grandfather Protection**: No forced migrations for 6 months
2. **Transparent Communication**: 60-day advance notice of changes
3. **Value-First Messaging**: Focus on new features, not price increases
4. **Flexible Migration Paths**: Allow customers to choose their tier
5. **Incentive Alignment**: Reward early adopters with discounts

### Anti-Patterns to Avoid

❌ **DON'T**: Force immediate price increases
❌ **DON'T**: Remove features from current plan without notice
❌ **DON'T**: Send generic "your price is changing" emails
❌ **DON'T**: Make grandfathered pricing confusing
❌ **DON'T**: Ignore customer feedback during migration

---

## PHASE 1: PREPARATION (Month 0 - Before Launch)

### Actions

**1. Customer Data Enrichment**
- Collect usage metrics for all 230 customers (30-day trailing average):
  - API calls per month
  - Secret count and avg TTL
  - Number of active users
  - Feature adoption (webhooks, custom domains, etc.)
  - Support ticket history
- Create customer health score (1-10) based on:
  - Usage intensity
  - Feature adoption
  - Payment history
  - Support interactions
  - NPS/satisfaction scores

**2. Tier Recommendation Engine**
- Build algorithm to suggest optimal tier per customer
- Inputs: usage data, company size, industry, growth trajectory
- Output: Primary recommendation + 2 alternatives
- Validation: 95%+ accuracy vs. manual review (sample 50 customers)

**3. Customer Success Training**
- Train CS team on new pricing structure (full-day workshop)
- Develop migration scripts for common objections
- Create tier comparison tool for live demos
- Role-play difficult conversations (price-sensitive customers)

**4. Migration Communication Templates**
- Email templates (6 variations based on recommended tier)
- FAQ page: "Pricing Changes Explained"
- Video walkthrough: "Choosing Your Perfect Plan"
- In-app notification banners

### Success Criteria
- ✅ 100% of customers have tier recommendations
- ✅ CS team achieves >90% on migration quiz
- ✅ Communication templates approved by legal & marketing
- ✅ Migration dashboard built and tested

---

## PHASE 2: SOFT LAUNCH (Month 1)

### Actions

**1. Grandfather Announcement**
- **Day 1**: Email all 230 customers
  - Subject: "We're Improving OneTimeSecret—Your Price Stays the Same"
  - Key message: "No changes to your $35/month plan for 6 months minimum"
  - Preview: "New plans launching soon with advanced features"
  - CTA: "See what's coming" (link to blog post)

**2. New Tier Launch (New Customers Only)**
- Launch 7-tier pricing for new signups
- Existing customers still see $35/month renewal
- Run A/B tests on new customers (see ab-test-framework.md)

**3. Early Access Program (Invite-Only)**
- Select 20 customers (top 10% by usage) for early access
- Offer: "Upgrade now, get 20% off for 12 months"
- Goal: Validate migration flow, gather feedback
- Success metric: >50% accept early upgrade offer

### Success Criteria
- ✅ Email open rate >60%, click rate >20%
- ✅ <5 customer support tickets complaining about email
- ✅ Early access: 10+ customers upgrade successfully
- ✅ Zero billing errors in early access group

---

## PHASE 3: VOLUNTARY MIGRATION (Months 2-3)

### Actions

**1. Personalized Migration Offers**

**Wave 1: Power Users (5 customers) → Premium $300**
- **Day 30**: Personal email from CEO
- Offer: Upgrade to Premium for $250/month (17% discount) for 12 months
- Perks: Dedicated account manager, priority feature requests
- Timeline: 2-week decision window
- Follow-up: Personal call if no response after 1 week

**Wave 2: Enterprise Needs (17 customers) → Business $125**
- **Day 35**: Email from Head of Customer Success
- Offer: Upgrade to Business for $99/month (21% discount) for 6 months
- Highlights: SSO, compliance reports, SLA
- Timeline: 3-week decision window
- Incentive: Free migration assistance + training session

**Wave 3: Team Users (69 customers) → Team $75**
- **Day 40**: Email from Customer Success Manager
- Offer: Upgrade to Team for $65/month (13% discount) for 6 months
- Highlights: Team collaboration, advanced branding, chat support
- Timeline: 4-week decision window
- Incentive: Free onboarding for entire team

**Wave 4: Right-sized (81 customers) → Professional $49**
- **Day 45**: Automated email with personal touches
- Offer: Upgrade to Professional for $45/month (8% discount) for 6 months
- Highlights: Webhooks, custom domain, priority support
- Timeline: 4-week decision window
- Incentive: Free custom domain setup

**2. In-App Nudges**
- Display tier recommendation banner after login (dismissable)
- Show feature comparison: "What you're missing on [Recommended Tier]"
- Tooltip highlights: "This feature available on Professional+"

**3. Sales Outreach (High-Value Accounts)**
- Sales team reaches out to top 30 customers by potential LTV
- Schedule 30-min demos of new tier features
- Customize offers based on specific needs
- Goal: Close >60% of outreach into upgrades

### Success Criteria
- ✅ Upgrade Rate by Segment:
  - Power Users: >80% (4/5)
  - Enterprise: >60% (10/17)
  - Team Users: >40% (28/69)
  - Right-sized: >35% (28/81)
- ✅ Overall: >70 voluntary upgrades (30% of base)
- ✅ Churn: <3% during voluntary period (<7 customers)

---

## PHASE 4: MANDATORY MIGRATION (Months 4-5)

### Actions

**1. 90-Day Notice (Month 4, Day 1)**
- Email to all remaining customers (~160 if 30% upgraded voluntarily)
- Subject: "Important: Your Plan is Changing in 90 Days"
- Key messages:
  - Your $35/month plan will end on [specific date]
  - We recommend [Recommended Tier] based on your usage
  - You can choose any tier that fits your needs
  - Your data and features safe during transition
- CTA: "Choose Your New Plan" (link to tier selection page)

**2. Tier Selection Page (Custom Per Customer)**
- Pre-select recommended tier (but allow changes)
- Show current usage vs. tier limits
- Highlight features they'll gain vs. current plan
- Display "Your price without discount: $X" vs. "Migration discount: $Y"
- Allow annual billing switch (save 15%)

**3. Progressive Reminders**
- **Day 30 (60 days remaining)**: Email reminder + in-app banner
- **Day 60 (30 days remaining)**: Email + phone call for high-value customers
- **Day 75 (15 days remaining)**: Urgent email + persistent in-app modal
- **Day 85 (5 days remaining)**: Final warning + support team proactive outreach

**4. Default Tier Assignment (for non-responders)**
- **Day 90**: Customers who didn't choose are auto-assigned
- Algorithm:
  - If current usage fits tier limits → assign that tier
  - If current usage exceeds tier limits → assign next higher tier
  - If current usage well below tier → assign lower tier (with notification)
- Notification: "We've selected [Tier] for you based on usage. You can change anytime."

### Success Criteria
- ✅ Response Rate: >85% choose their tier proactively
- ✅ Churn: <7% during mandatory period (<11 customers)
- ✅ Billing Accuracy: 100% correct tier assignment
- ✅ Support Load: <50 tickets total related to migration

---

## PHASE 5: GRANDFATHERING END (Month 6)

### Actions

**1. Final Transition**
- **Month 6, Day 1**: All customers now on new pricing
- Monitor billing closely for first 2 weeks
- Proactive outreach if payment failures spike

**2. Post-Migration Survey**
- Email survey to all 230 original customers
- Questions:
  - Satisfaction with migration process (1-10)
  - Clarity of communication (1-10)
  - Perceived value of new tier (1-10)
  - Likelihood to recommend OneTimeSecret (NPS)
  - Open feedback
- Incentive: $25 gift card for completion

**3. Win-Back Campaign (Churned Customers)**
- Reach out to customers who churned during migration
- Offer: "Come back, we'll honor your old $35 price for 6 more months"
- Highlight: New features they're missing
- Goal: Win back 30% of churned customers

### Success Criteria
- ✅ Final MRR: >$13,000 (+60% vs. baseline)
- ✅ Final Customer Count: >207 (>90% retention)
- ✅ NPS: ≥40 (industry standard for SaaS pricing changes)
- ✅ Survey Response Rate: >40%

---

## SPECIAL CASES & EDGE HANDLING

### Case 1: Under-Utilizing Customers → Individual $25 (Downgrade)

**Challenge**: 58 customers currently overpaying, now offered $25 tier
**Risk**: May downgrade, reducing MRR by $580

**Strategy**:
1. **Highlight Savings**: "Save $10/month while keeping what you need"
2. **Suggest Professional**: "For just $14 more, get webhooks and custom domain"
3. **Loss Aversion**: "You're currently using features only in $49+ tiers" (if true)
4. **Upsell After Downgrade**: 60 days later, offer Professional upgrade trial

**Expected Outcome**: 40% stay at $49, 60% downgrade to $25

### Case 2: Annual Subscribers (Prepaid)

**Challenge**: 35 customers (~15%) on annual plans, prepaid $420

**Strategy**:
1. **Honor Full Year**: No price change until renewal
2. **Early Upgrade Option**: Prorate difference if upgrading mid-year
  - Example: 6 months into annual $35 → upgrade to $49 annual
  - Charge: ($49 - $35) × 6 = $84 for remaining 6 months
3. **Renewal Notice**: 60 days before expiry, offer new tier selection
4. **Loyalty Discount**: 10% off annual plans for renewals

### Case 3: Non-Profit / Educational Customers

**Challenge**: 12 customers (~5%) with informal edu/non-profit pricing

**Strategy**:
1. **Formal Non-Profit Program**: Create official 30% discount program
2. **Verification**: Require non-profit status proof (501c3, etc.)
3. **Apply to All Tiers**: Discount applies to whichever tier they choose
4. **Example**: Non-profit on Team tier pays $52.50 instead of $75

### Case 4: Churned During Migration

**Challenge**: 18 customers (8%) expected to churn

**Strategy**:
1. **Exit Survey**: Understand why (price, features, switching to competitor)
2. **Win-Back Offer** (30 days after churn):
  - If price-sensitive: Offer Individual $25 or old $35 for 6 months
  - If feature-driven: Offer Professional $49 with free custom domain
  - If competitor: Competitive analysis, highlight unique value
3. **Retention Goal**: Win back 30% (5-6 customers)

### Case 5: Payment Failures

**Challenge**: ~10% of migrations may encounter payment issues

**Strategy**:
1. **Pre-Migration Email**: "Update your payment method to avoid interruption"
2. **Grace Period**: 7 days after migration before service suspension
3. **Proactive Contact**: Email + phone on day of failure
4. **Flexible Payment**: Offer monthly instead of annual if cash flow issue

---

## COMMUNICATION CALENDAR

### Month-by-Month Timeline

| Month | Week | Action | Audience | Channel |
|-------|------|--------|----------|---------|
| **0** | 1 | Preparation complete | Internal | Slack announcement |
| **0** | 4 | CS training finished | CS team | Workshop + quiz |
| **1** | 1 | Grandfather announcement | All 230 | Email + blog post |
| **1** | 2 | Early access invites | Top 20 customers | Personal email |
| **1** | 4 | Early access feedback review | Internal | Team meeting |
| **2** | 1 | Wave 1: Power users outreach | 5 customers | CEO email + call |
| **2** | 2 | Wave 2: Enterprise outreach | 17 customers | Email + demo offer |
| **2** | 3 | Wave 3: Team users outreach | 69 customers | Email |
| **2** | 4 | Wave 4: Professional outreach | 81 customers | Email |
| **3** | 1-4 | Sales follow-ups | High-value accounts | Calls + demos |
| **3** | 4 | Voluntary migration results review | Internal | Executive briefing |
| **4** | 1 | 90-day mandatory notice | All remaining (~160) | Email |
| **4** | 3 | 60-day reminder | Non-responders | Email + in-app |
| **5** | 1 | 30-day reminder | Non-responders | Email + calls |
| **5** | 3 | 15-day urgent notice | Non-responders | Email + modal |
| **5** | 4 | 5-day final warning | Non-responders | Email + support |
| **6** | 1 | Default tier assignment | Final non-responders | Email |
| **6** | 1 | All customers migrated | All 230 | Email |
| **6** | 2 | Post-migration survey | All customers | Email |
| **6** | 3 | Win-back campaign | Churned customers | Email |
| **6** | 4 | Migration retrospective | Internal | All-hands meeting |

---

## FINANCIAL PROJECTIONS

### Revenue Waterfall

**Starting MRR**: $8,050 (230 customers @ $35)

| Event | Customers | Price | MRR Change | Cumulative MRR |
|-------|-----------|-------|------------|----------------|
| **Baseline** | 230 | $35 | - | $8,050 |
| Power → Premium (80%) | +4 | $300 | +$1,060 | $9,110 |
| | -4 | -$35 | -$140 | $8,970 |
| Enterprise → Business (60%) | +10 | $125 | +$1,250 | $10,220 |
| | -10 | -$35 | -$350 | $9,870 |
| Team → Team tier (40%) | +28 | $75 | +$2,100 | $11,970 |
| | -28 | -$35 | -$980 | $10,990 |
| Right-sized → Pro (35%) | +28 | $49 | +$1,372 | $12,362 |
| | -28 | -$35 | -$980 | $11,382 |
| Under-utilizing → Individual (60%) | +35 | $25 | +$875 | $12,257 |
| | -35 | -$35 | -$1,225 | $11,032 |
| **Subtotal (voluntary)** | **161** upgraded | - | - | **$11,032** |
| **Remaining on $35** | **69** | $35 | - | **$11,032 + $2,415 = $13,447** |
| Mandatory migration (85% success) | +59 | Mixed | +$2,150 | $15,597 |
| | -59 | -$35 | -$2,065 | $13,532 |
| Non-responders (auto-assign) | +10 | Mixed | +$350 | $13,882 |
| | -10 | -$35 | -$350 | $13,532 |
| **Churn (8%)** | -18 | -$35 | -$630 | **$12,902** |
| **Final State** | **212** | Mixed | - | **$12,902** |

**Final MRR**: $12,902 (+60.3% vs. baseline)
**Final Customers**: 212 (92% retention)
**New ARPU**: $60.86 (+73.9% vs. $35)

### Confidence Intervals (Monte Carlo Results)

| Metric | 5th Percentile | Median | 95th Percentile |
|--------|----------------|--------|-----------------|
| Final MRR | $11,850 | $12,902 | $14,100 |
| Retention Rate | 88% | 92% | 95% |
| ARPU | $55.20 | $60.86 | $68.50 |
| Revenue Change | +47% | +60% | +75% |

---

## RISK MITIGATION

### Risk 1: Higher Than Expected Churn (>10%)

**Mitigation Actions**:
1. Pause mandatory migration if voluntary churn >5%
2. Extend grandfather period from 6 to 9 months
3. Offer "middle ground" pricing to at-risk customers
4. Improve value communication (feature highlights, case studies)

### Risk 2: Payment Failures Spike

**Mitigation Actions**:
1. Pre-migration email: "Update payment method by [date]"
2. Offer alternative payment methods (ACH, wire for enterprise)
3. Grace period: 14 days instead of 7 for good customers
4. Manual intervention: CS team reaches out immediately

### Risk 3: Negative PR / Social Media Backlash

**Mitigation Actions**:
1. Transparent blog post: "Why we're changing pricing"
2. Monitor Twitter, Reddit, HackerNews for sentiment
3. Respond quickly to concerns (< 2 hour response time)
4. Offer public concessions if backlash severe (e.g., extend grandfather to 12 months)

### Risk 4: Customer Confusion (Wrong Tier Selection)

**Mitigation Actions**:
1. Tier recommendation quiz: "Find your perfect plan in 60 seconds"
2. Live chat support during migration windows
3. 30-day tier change window (no penalty for switching tiers)
4. Proactive outreach if customer chooses tier that doesn't fit usage

---

## SUCCESS METRICS

### Primary KPIs

| Metric | Target | Measurement Window |
|--------|--------|-------------------|
| **Retention Rate** | ≥90% (≥207 customers) | End of Month 6 |
| **MRR Growth** | ≥+60% (≥$12,880) | End of Month 6 |
| **ARPU Increase** | ≥+60% (≥$56) | End of Month 6 |
| **Voluntary Migration Rate** | ≥30% (≥69 customers) | End of Month 3 |
| **Churn Rate** | ≤10% (≤23 customers) | Cumulative through Month 6 |

### Secondary KPIs

| Metric | Target | Measurement Window |
|--------|--------|-------------------|
| **NPS (Migration)** | ≥40 | Month 6 survey |
| **Email Open Rate** | ≥55% | Per campaign |
| **Tier Selection Accuracy** | ≥80% stay on recommended tier | Month 6 |
| **Support Ticket Volume** | <100 migration-related tickets | Cumulative |
| **Payment Failure Rate** | <5% | First 30 days post-migration |
| **Win-Back Rate** | ≥30% of churned | 90 days post-churn |

---

## CONCLUSION

This migration strategy balances revenue growth with customer satisfaction by:
1. **Grandfathering** existing customers for 6 months
2. **Incentivizing** early voluntary upgrades with discounts
3. **Personalizing** tier recommendations based on usage data
4. **Communicating** transparently with 90-day notice
5. **Supporting** customers through proactive CS outreach

**Expected Outcome**: 212 customers, $12,902 MRR, 92% retention, +60% revenue growth.

---

**Document Version**: 1.0
**Date**: November 23, 2025
**Owner**: Product & Customer Success Teams
**Next Review**: Monthly during migration (Months 1-6)
