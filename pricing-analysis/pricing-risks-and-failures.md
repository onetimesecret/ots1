# Pricing Strategy Risks: Real-World Failures and Lessons

## OBJECTIVE
Identify 3 specific risks where this pricing strategy could fail, with documented real-world examples of companies that made similar mistakes.

---

## RISK #1: EXCESSIVE PRICE INCREASES TRIGGERING MASS EXODUS

### Description
Raising prices too aggressively (>50-100%) without sufficient value justification causes immediate customer revolt, brand damage, and long-term revenue loss even if changes are partially reversed.

### How This Applies to Your Strategy
- **Scenario 4 (Aggressive)**: Team tier increases 100% ($35→$70)
- **Scenario 5 (Premium)**: Team tier increases 114.3% ($35→$75)
- **Enterprise tiers**: All scenarios show 154-268% increases
- **Risk level**: HIGH for scenarios 3-5, MODERATE for scenario 2, LOW for scenario 1

### Real-World Example 1: Unity Runtime Fee Disaster (2023)

#### Company Background
Unity Technologies - Game engine platform with millions of developers worldwide, valued at billions

#### What They Did Wrong
**The Announcement (September 12, 2023)**:
- Introduced "Runtime Fee" - charging developers per game installation
- Applied retroactively to games already published
- Pricing structure was opaque and unpredictable
- Effective price increase: **200-500%+ for many developers**

Source: [Unity Pricing Controversy](https://www.bairesdev.com/blog/unity-pricing-controversy/)

**The Backlash**:
- Within 3 days, massive developer revolt across Reddit, Twitter, forums
- High-profile developers like Mega Crit (Slay the Spire) threatened to abandon Unity
- Brand trust destroyed overnight
- CEO John Riccitiello resigned within 2 weeks
- Stock price fell sharply

Source: [How to Lose $200M - Unity's Pricing Backlash](https://www.linkedin.com/pulse/how-lose-200m-story-unitys-pricing-backlash-alex-david-vtolc)

**The Damage**:
> "While Unity staved off an immediate crisis, its brand, its reputation, and the trust it's built with developers over the years all took a hit. Perception and unpredictability caused more damage than the actual cost... it was opaque, unstable, and threatening."

Source: [Unity Apologizes to Devs](https://www.gamedeveloper.com/business/unity-apologizes-to-devs-reveals-updated-runtime-fee-policy)

**The Reversal**:
- Unity apologized within 1 week
- Completely canceled Runtime Fee in 2024
- Returned to subscription model with seat-based pricing
- Damage already done - developers had lost trust

Source: [Unity Cancels Controversial Runtime Fee](https://www.renderhub.com/blog/unity-cancels-controversial-runtime-fee-what-it-means-for-game-developers)

#### Financial Impact
- Estimated $200M+ in market value loss
- Massive developer migration to Unreal Engine, Godot
- Brand damage lasting years
- CEO departure costs
- Engineering resources wasted on rollback

#### Key Lessons
1. **Retroactive pricing changes are toxic**
2. **Price increases >100% trigger existential fear in customers**
3. **Opaque/unpredictable pricing destroys trust**
4. **Reversing doesn't undo brand damage**
5. **Perception matters more than actual cost**

#### Direct Application to Your Pricing
⚠️ **WARNING FOR SCENARIOS 4-5**:

If you implement Scenario 4 or 5:
- Team tier doubling ($35→$70) mirrors Unity's mistake
- Enterprise 242-268% increase creates same "betrayal of trust"
- Even with discounts, perceived price shock remains
- Customers will explore competitors immediately
- Churn modeling (15-18% monthly) may be **optimistic**

**Safer approach**: Scenario 1 caps team increase at 40% ($35→$49), which is aggressive but defensible with clear value add.

---

### Real-World Example 2: Evernote Price Increase Catastrophe (2016)

#### Company Background
Evernote - Note-taking app with 200M+ users, once valued at $1B, considered future IPO candidate

#### What They Did Wrong
**The 2016 Pricing Overhaul**:
- Raised Premium price from $45/year to $69.99/year (**+55% increase**)
- Raised Plus price from $25/year to $34.99/year (**+40% increase**)
- Severely restricted free tier:
  - Limited to 2 devices (down from unlimited)
  - 60MB upload limit
  - Removed many features previously free

Source: [Why Evernote Failed to Realize Its Potential](https://nira.com/evernote-history/)

**The Context Making It Worse**:
- Competitors (Microsoft OneNote, Apple Notes) offered MORE features for FREE
- No significant new features to justify price increase
- Years of generous freemium had "spoiled users"
- Sudden shift from permissive to restrictive

Source: [Tearing Down Evernote's Pricing](https://sbigrowth.com/insights/evernote-pricing)

**Customer Reaction**:
From actual user forums:
> "Shocking increase in plan price"
> "Price increase is insane"
> "Paying users are also leaving (price increase, no real new features)"

Source: [Evernote User Forum - Price Increase Threads](https://discussion.evernote.com/forums/topic/149259-price-increase-is-insane/)

**The Outcome**:
- Mass customer exodus to competitors
- "Evernote's once loyal userbase wasted little time in criticizing them"
- Company struggled for years afterward
- Multiple layoffs and leadership changes
- Never recovered to original position
- Eventually sold to Bending Spoons (Italy) in 2023 - acquisition of distressed asset

Source: [What Happened to Evernote?](https://www.linkedin.com/pulse/what-happened-evernote-todd-allan)

#### Financial Impact
- Lost market leadership position
- Massive user base decline
- Valuation collapse from $1B+ to distressed sale
- Years of attempted recovery failed
- Brand became cautionary tale

#### Key Lessons
1. **40-55% price increases are dangerous even with value**
2. **Free tier restrictions + price increases = double jeopardy**
3. **Gradual changes > sudden shifts**
4. **Competitor pricing context matters critically**
5. **"Spoiled" users (used to generous free tier) are highest risk**

#### Direct Application to Your Pricing
⚠️ **CRITICAL RELEVANCE**:

Your current customers pay $35/month for features (custom domain + branding). They are "spoiled" by this generous offering.

**Scenario 2-5 risks**:
- Team tier increases of 68-114% ($35→$59-75) mirror Evernote's mistake
- Your customers are accustomed to feature-rich offering at $35
- Competitors may offer similar features cheaper
- Unlike Evernote, you DON'T have 200M users to cushion exodus

**Evernote's mistake you must avoid**:
> "What the company should have done was gradually introduce restriction incentives to its free version over time, rather than transitioning from a generous freemium product to a comparatively expensive paid service."

**Your equivalent mistake would be**:
- Sudden jump from $35 all-inclusive to $59-75 for Team tier
- Without gradual feature stratification over time
- Without significant new features to justify increase

**Safer approach**:
- Scenario 1 reduces Individual price to $29 (builds goodwill)
- Team tier $49 is 40% increase (matches Evernote's "Plus" tier, which was less controversial than 55% Premium increase)
- Gradual rollout with heavy communication

---

## RISK #2: THE "SSO TAX" BACKLASH - TREATING SECURITY AS LUXURY PREMIUM

### Description
Charging excessive premiums (>200%) for basic security features like SSO triggers industry backlash, regulatory scrutiny, customer resentment, and competitive vulnerability.

### How This Applies to Your Strategy
- **All scenarios**: SSO gated to Enterprise tier with 154-268% price premium
- **Competitor analysis**: Shows median 50% SSO premium, you're planning 154-268%
- **Risk level**: MODERATE to HIGH depending on implementation

### Real-World Example: HubSpot and the SSO Wall of Shame (2023-2024)

#### Industry Background
"SSO Tax" - The practice of SaaS vendors charging extreme premiums for Single Sign-On, a basic security feature

#### HubSpot's Extreme Case
**The Pricing**:
- Base tier: $46/month
- SSO tier: $3,647/month
- **Increase: 7,828%** (not a typo)

Source: [Explaining the backlash to the SSO tax](https://blog.1password.com/explaining-the-backlash-to-the-sso-tax/)

**Industry Hall of Shame**:
- **Cloudflare**: 4,900% increase
- **Breezy HR**: 777% increase
- **Airtable**: 500% increase
- **GitHub**: 425% increase ($4→$21/user/month)
- **Figma**: 275% increase ($12→$45/user/month)
- **Docker**: 167% increase ($9→$24/user/month)
- **Asana**: 140% increase
- **Slack**: 72% increase
- **Notion**: 50% increase

Source: [Wall of Shame - SSOtax.org](https://ssotax.org/)

#### The Backlash

**Security Community Revolt**:
> "The SSO tax is a security ransom, and it's time to call it out!"

Source: [The SSO tax is a security ransom](https://www.satola.tech/2025/the-sso-tax-is-a-security-ransom-and-its-time-to-call-it-out/)

**Regulatory Pressure**:
- CISA's "Secure by Design" whitepaper explicitly states: "Essential security features should be available as part of basic service offerings"
- 80% of SaaS applications employees use are NOT in SSO portals, with SSO licensing cost being the top reason (Grip Security survey of 100+ CISOs)

Source: [Avoid the SSO Tax](https://www.idsalliance.org/blog/avoid-the-sso-tax-stay-secure-without-paying-more/)

**Company Reversals**:
**Tailscale (2024)** - Completely removed SSO paywall, admitting:
> "The SSO tax felt like a mistake"

**HubSpot** - Partially relented after sustained backlash

Source: [It's time to overthrow the SSO tax](https://www.nudgesecurity.com/post/why-the-sso-tax-needs-to-go)

#### Why SSO Tax Fails

1. **Security should not be luxury**: Industry consensus emerging that security features must be baseline
2. **Competitive pressure**: Companies removing SSO paywalls gain competitive advantage
3. **Customer resentment**: CISOs forced to pay ransom for basic security feel exploited
4. **Regulatory risk**: Government agencies starting to push back
5. **Workarounds hurt vendors**: 80% of apps not in SSO because companies refuse to pay

#### Financial Impact
- Lost enterprise deals (security teams reject products with SSO tax)
- Brand damage in security community
- Competitive disadvantage vs. vendors offering free SSO
- Regulatory compliance complications
- Customer resentment reducing expansion revenue

#### Key Lessons
1. **50-75% SSO premium is tolerable; 200%+ triggers backlash**
2. **Security features are increasingly expected as baseline**
3. **Industry tide turning against SSO paywalls**
4. **Competitive dynamics favor vendors removing SSO tax**
5. **"Wall of Shame" public naming creates lasting brand damage**

#### Direct Application to Your Pricing
⚠️ **YOUR SSO PRICING RISK ANALYSIS**:

**Current plan across all scenarios**:
- SSO only in Enterprise tier
- Price premium: 154% (Scenario 1) to 268% (Scenario 5)

**Your positioning vs. industry**:

| Your Pricing | Industry Context | Risk Level |
|--------------|-----------------|------------|
| Scenario 1: $89 Enterprise (+154% from $35) | Above median 50% premium, below "Wall of Shame" threshold | ⚠️ MODERATE |
| Scenario 2: $99 Enterprise (+183%) | Approaching backlash territory | ⚠️ HIGH |
| Scenario 3: $110 Enterprise (+214%) | In "Wall of Shame" range | 🔴 HIGH |
| Scenario 4: $120 Enterprise (+243%) | Deep in backlash territory | 🔴 VERY HIGH |
| Scenario 5: $129 Enterprise (+268%) | Extreme SSO tax | 🔴 CRITICAL |

**Mitigation Strategies**:

1. **Option A: Lower SSO barrier**
   - Offer basic SSO at Team tier ($49-59)
   - Reserve advanced SSO (SCIM, multiple IdPs) for Enterprise
   - Aligns with industry trend

2. **Option B: Justify premium with bundles**
   - Don't sell "SSO alone" at Enterprise
   - Bundle: SSO + SCIM + advanced audit logs + dedicated support + SLA
   - Make it clear customer isn't just paying for SSO

3. **Option C: Tiered SSO**
   - Team tier: Basic SAML SSO (1 IdP)
   - Enterprise tier: Advanced SSO (multiple IdPs, SCIM, JIT provisioning)
   - Reduces "ransom" perception

**Industry Momentum**:
The tide is turning AGAINST SSO paywalls. Companies like Tailscale removing them entirely. If you gate SSO aggressively now, you may need to reverse in 1-2 years, creating:
- Lost revenue from failed enterprise deals
- Customer resentment from early "ransom payers"
- Competitive disadvantage vs. vendors offering free/cheap SSO
- Awkward communications when you eventually lower SSO barrier

**Recommended approach**:
- Scenario 1 ($89 Enterprise) with Option B (heavy bundle justification)
- Position as "Enterprise security suite" not "SSO fee"
- Plan to potentially add basic SSO to Team tier within 18 months based on competitive pressure

---

## RISK #3: COMPLEX TIER MIGRATION CAUSING CUSTOMER CONFUSION AND DECISION PARALYSIS

### Description
Moving from single product to 4-tier structure creates confusion, decision paralysis, downgrade/upgrade churn, and support burden if not executed with crystal-clear communication and gradual rollout.

### How This Applies to Your Strategy
- **Current state**: 1 product, $35/month, simple
- **Target state**: 4 tiers, 5x price range ($29-179), feature matrices
- **230 customers** must ALL make migration decisions simultaneously
- **Risk level**: MODERATE to HIGH depending on execution

### Real-World Example: Mailchimp Pricing Complexity Backlash (2019-2020)

#### Company Background
Mailchimp - Email marketing platform with millions of users, dominant market position

#### What They Did Wrong
**The 2019 Pivot**:
- Shifted from "email marketing platform" to "CRM platform"
- Changed pricing model fundamentally:
  - Previously: Charged based on active subscribers
  - New model: **Charged for ALL contacts including unsubscribed**
  - Tier restructuring: Pro/Grow/Free → Premium/Standard/Essentials/Free
  - Feature gates changed significantly
  - Email send limits reduced (12,000→10,000 for 2k contacts)

Source: [The details behind Mailchimp's 2019 pricing change](https://medium.com/@td_evans/the-details-behind-mailchimps-2019-pricing-change-3c1cd02bc270)

**The Complexity Problem**:
- Existing customers grandfathered on legacy plans
- New customers on new plans
- Different pricing structures running simultaneously
- Confusion about which features in which tiers
- Required customers to understand complex contact counting rules

Source: [Mailchimp Pricing Changes - Pricetimeline](https://pricetimeline.com/data/marketing/mailchimp-price-history)

**Additional Pain Points**:
- **50% price increase** for custom template users (forced upgrade to Standard plan)
- Unsubscribed contacts now counting toward billing
- Feature restrictions unclear
- Migration path complicated

Source: [Mailchimp Price Increase: What Every Business Needs to Know](https://www.brevo.com/blog/mailchimp-price-increase/)

#### Customer Reaction
**Social Media Backlash**:
> "The change was pretty badly received by customers on social media, with many users upset."

**Actual Customer Migrations**:
- Users switching to GetResponse, Omnisend, MailerLite
- $2k/month customers leaving: "I switched to GetResponse Enterprise before the pricing changes"
- Migration to EmailOctopus, Brevo, other competitors

Source: [Mailchimp pricing update 2023 - EmailOctopus Blog](https://blog.emailoctopus.com/mailchimp-pricing-update-2023-the-details-behind-it/)

**Forum Comments** (from Mailchimp's own forums):
- Confusion about new pricing model
- Anger about unsubscribed contacts counting
- Frustration with forced upgrades
- Complexity of comparing old vs. new plans

#### Why It Failed (Partially)
1. **Too many simultaneous changes**: Pricing model + tier structure + feature gates + counting rules
2. **Grandfathering complexity**: Two systems running parallel created confusion
3. **Forced upgrades**: Users couldn't stay on equivalent tier, had to pay more
4. **Poor communication**: Changes not clearly explained in advance
5. **Surprise billing**: Counting unsubscribed contacts caught users off-guard

#### Business Impact
- Customer churn to competitors
- Negative brand perception
- Increased support burden (confused customers)
- Competitive opportunity for simpler alternatives
- Required further pricing adjustments in subsequent years

#### Key Lessons
1. **Complexity is the enemy of conversion**
2. **Simultaneous changes compound confusion**
3. **Grandfathering creates two-tier support burden**
4. **Counting rule changes feel like "gotchas"**
5. **Forced upgrades generate maximum resentment**

#### Direct Application to Your Pricing
⚠️ **YOUR MIGRATION COMPLEXITY RISK**:

**Your challenge**:
- 230 customers currently on identical $35/month plan
- ALL must choose between 4 new tiers
- Feature matrices must be understood
- Pricing ranges from -17% to +640% depending on choice
- Must happen in compressed timeframe

**Potential confusion points**:

1. **"Which tier am I supposed to be on?"**
   - Current: Everyone has custom domain + branding
   - New: These features in which tier(s)?
   - If Team tier has custom domain, why would anyone pay more for Individual?
   - If Individual lacks custom domain, customer downgrades = feature loss

2. **"How do I compare old vs. new?"**
   - Old: $35 gets everything
   - New: $35 gets ??? (depends on tier choice)
   - No clear 1:1 mapping

3. **"Am I being forced to upgrade?"**
   - If current features only available in Team ($49-75), feels like forced upgrade
   - If available in Individual ($29-35), why have Team tier?

4. **"What happens if I do nothing?"**
   - Auto-migration path must be crystal clear
   - Default choice shapes perceptions

5. **Grandfathering complexity**:
   - If you grandfather existing customers at $35, you have two pricing structures forever
   - If you force migration, you risk Mailchimp-style backlash
   - If you offer transition discounts, expiration creates future churn spike

#### Mailchimp's Mistakes You Can Avoid

**Don't do**:
- ❌ Change pricing model AND tier structure simultaneously
- ❌ Create complex counting/billing rules
- ❌ Force upgrades to maintain current features
- ❌ Announce 60 days before with minimal communication
- ❌ Make migration decision complex

**Do instead**:
- ✅ Map current features to SPECIFIC new tier (1:1 clarity)
- ✅ Grandfather existing customers at "Individual Enhanced" ($35 with all current features) for 12+ months
- ✅ Make migration decision dead simple: "Stay same price, or upgrade for new features"
- ✅ Communicate 90+ days in advance with multiple touchpoints
- ✅ Provide migration calculator: "You are currently using X features, we recommend Y tier"
- ✅ Offer 1:1 migration consultations for larger customers
- ✅ Phase rollout: New customers first, existing customers 60 days later

#### Migration Execution Recommendation

**Phase 1: New Customers (Month 0-2)**
- Launch 4-tier pricing for new signups only
- Existing customers unchanged
- Test messaging, support burden, conversion rates
- Refine tier descriptions based on questions

**Phase 2: Existing Customer Communication (Month 3-4)**
- Announce changes 90 days in advance
- Provide personalized tier recommendation for each customer
- Offer "Grandfather Tier" option: keep $35 + all current features for 12 months
- Early migration discount: 30% off first 6 months if migrate before deadline

**Phase 3: Migration Window (Month 4-6)**
- 60-day migration window
- Active support: answer questions, provide guidance
- 1:1 consultations for top 20% of customers (by revenue or potential)
- Weekly reminders with clear deadline

**Phase 4: Auto-Migration (Month 6)**
- Customers who didn't choose: auto-migrate to "Individual Enhanced" ($35 grandfathered)
- No forced upgrades
- No one loses features without explicit choice
- 12-month grandfather period before required tier choice

**Phase 5: Optimization (Month 7-18)**
- Monitor grandfather tier retention
- Offer upgrade incentives (not threats)
- Gradually encourage migration to standard tiers
- Month 18: Final transition of grandfather tier to standard Individual tier ($29-35) or upgrade

This approach avoids Mailchimp's mistakes:
- ✅ No forced immediate decisions
- ✅ No feature loss without consent
- ✅ Clear migration path
- ✅ Time to understand new tiers
- ✅ Reduction in decision paralysis
- ✅ Maintains trust through transition

---

## RISK SUMMARY MATRIX

| Risk | Severity | Likelihood | Mitigation Difficulty | Example Company | Outcome if Not Mitigated |
|------|----------|------------|----------------------|----------------|-------------------------|
| **#1: Excessive Price Increases** | CRITICAL | HIGH (Scenarios 4-5) | EASY (choose Scenario 1) | Unity, Evernote | Mass exodus, brand damage, revenue collapse |
| **#2: SSO Tax Backlash** | HIGH | MODERATE | MODERATE (bundle features, justify premium) | HubSpot, Tailscale | Enterprise deal losses, competitive disadvantage, forced reversal |
| **#3: Migration Complexity** | MODERATE | HIGH | MODERATE (phased rollout, clear communication) | Mailchimp | Customer confusion, support burden, unnecessary churn |

---

## COMBINED RISK SCENARIO: THE PERFECT STORM

**What happens if all three risks occur simultaneously?**

### Month 0: Launch with Scenario 5 pricing
- Individual: $35 (unchanged)
- Team: $75 (114% increase)
- Enterprise: $129 (268% increase) with SSO
- Dedicated: $259 (640% increase)

### Month 1: Confusion + Sticker Shock
- 230 customers receive migration announcement
- Unclear which tier they "should" choose
- Team tier doubling triggers Unity-style "betrayal" feeling
- Enterprise SSO premium appears on "Wall of Shame" equivalent lists
- Social media backlash begins

### Month 2: Churn Acceleration
- Price-sensitive customers leave immediately (20-30%)
- Enterprise prospects balk at SSO tax
- Competitors offer promotions targeting your customers
- Support overwhelmed with angry tickets

### Month 3: Damage Control
- Forced to offer emergency discounts (50%+ for 6 months)
- Discounts cost $26k+ (from Scenario 5 calculation)
- Brand damage already done
- Remaining customers resentful, waiting for better alternative

### Month 6: Failed Strategy
- MRR below original $8,050 despite higher prices
- Customer base shrunk 30-40%
- Negative word-of-mouth preventing new customer acquisition
- Competitors have absorbed your churned customers
- Considering rollback, but damage irreversible

### Month 12: Postmortem
- Total customer loss: 40-50%
- Revenue below pre-transition levels
- Engineering resources wasted
- Brand reputation damaged
- Forced to restart with conservative pricing (should have done initially)
- Leadership changes likely

**This is not hypothetical. This is the Unity playbook. This is the Evernote playbook.**

---

## RECOMMENDATIONS TO AVOID ALL THREE RISKS

### ✅ CHOOSE SCENARIO 1 (Conservative Pricing)
- Individual: $29 (price DECREASE builds goodwill)
- Team: $49 (40% increase, defensible)
- Enterprise: $89 (154% increase, below backlash threshold)
- Dedicated: $179 (reasonable premium for single-tenant)

### ✅ MITIGATE SSO TAX PERCEPTION
- Position Enterprise as "Security & Compliance Suite"
- Bundle: SSO + SCIM + advanced audit logs + dedicated support + SLA + priority features
- Don't sell "SSO" - sell "Enterprise security package"
- Consider offering basic SSO at Team tier within 18 months

### ✅ EXECUTE PHASED MIGRATION
- 90-day advance notice
- Grandfather tier option (keep $35 + current features for 12 months)
- Personalized tier recommendations
- No forced upgrades
- Clear, simple communication
- 1:1 support for large customers

### ✅ MONITOR & ADJUST
- Set churn thresholds: If Individual >10%, Team >12%, Enterprise >8% → reduce prices
- Weekly metrics review during migration
- Customer feedback loops
- Competitor monitoring
- Be ready to pivot

### ✅ LEARN FROM FAILURES
- Unity: Don't retroactively change terms or shock customers
- Evernote: Don't increase prices >40% without major value add
- HubSpot: Don't charge extreme security premiums (>200%)
- Mailchimp: Don't create complex, confusing migrations
- Delicious: Don't make sustainability impossible

---

## CONFIDENCE IN RISK ASSESSMENT

### HIGH CONFIDENCE (Verified Examples)
- ✅ Unity runtime fee disaster (2023) - extensively documented
- ✅ Evernote pricing failure (2016) - user forums + analysis available
- ✅ SSO tax backlash (2023-2024) - active industry movement
- ✅ Mailchimp complexity issues (2019-2020) - documented customer reactions

### MODERATE CONFIDENCE (Pattern Recognition)
- ⚠️ Your specific market may differ from these examples
- ⚠️ Customer base size (230) smaller than examples, both advantage (easier communication) and disadvantage (less statistical smoothing)
- ⚠️ Secrets management market dynamics may tolerate different premiums than examples

### UNABLE TO VERIFY
- ❌ Specific price elasticity for YOUR customers (requires A/B testing)
- ❌ Exact competitive response to your pricing changes
- ❌ Whether your value proposition can support higher premiums than market
- ❌ Customer switching costs in your specific market

**Recommendation**: Treat these risks as MINIMUM bounds. Actual damage from aggressive pricing could be worse than documented examples, since you lack the user base scale and brand recognition of Unity, Evernote, HubSpot, or Mailchimp.

---

## FINAL WARNING

Every company in this document thought they could charge more than they ultimately could. Every one thought their customers would understand and accept the changes. Every one was wrong.

**The only difference between you and them**:
- They had more resources to absorb the damage
- They had larger customer bases to cushion churn
- They had stronger brands to recover from mistakes

**You have less margin for error. Choose conservative pricing. Execute flawless migration. Build trust. Grow gradually.**
