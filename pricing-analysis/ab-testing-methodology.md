# A/B Testing Methodology for Pricing Validation

## OBJECTIVE
Design 3 A/B tests to validate critical pricing assumptions before full rollout, including sample size calculations for statistical significance and specific failure criteria.

---

## STATISTICAL FOUNDATION

### Standard Parameters
- **Significance level (α)**: 0.05 (95% confidence)
- **Statistical power (1-β)**: 0.80 (80% power to detect true effect)
- **Test type**: Two-tailed (unless otherwise specified)

### Sample Size Formula
For conversion rate tests (proportion):

```
n = (Zα/2 + Zβ)² × [p1(1-p1) + p2(1-p2)] / (p1 - p2)²

Where:
- n = required sample size per group
- Zα/2 = Z-score for significance level (1.96 for α=0.05, two-tailed)
- Zβ = Z-score for power (0.84 for power=0.80)
- p1 = baseline conversion rate
- p2 = expected conversion rate in variant
- (p1 - p2) = minimum detectable effect
```

For continuous metrics (e.g., revenue per user):

```
n = 2 × (Zα/2 + Zβ)² × σ² / δ²

Where:
- σ = pooled standard deviation
- δ = minimum detectable difference in means
```

---

## TEST #1: TEAM TIER PRICE ELASTICITY

### Hypothesis
**H0 (Null)**: Team tier conversion rate at $59/month = conversion rate at $49/month
**H1 (Alternative)**: Team tier conversion rate at $49/month > conversion rate at $59/month

### Test Design
**Objective**: Determine if lower Team tier price ($49 vs $59) significantly improves conversion without sacrificing total revenue.

**Test Setup**:
- **Control Group (A)**: Team tier priced at $59/month (Scenario 2)
- **Treatment Group (B)**: Team tier priced at $49/month (Scenario 1)
- **Population**: New signups + existing customers offered Team tier upgrade
- **Duration**: 60 days or until significance reached
- **Randomization**: 50/50 split by customer ID hash

### Primary Metric
**Conversion to Team tier**:
- Baseline (estimated): 30% (from migration distribution assumption)
- Minimum detectable effect: 10 percentage points (pp)
- Expected with lower price: 40%

### Sample Size Calculation

**Given**:
- p1 (control at $59) = 0.30
- p2 (treatment at $49) = 0.40
- Difference = 0.10 (10 pp increase)
- α = 0.05 (Zα/2 = 1.96)
- Power = 0.80 (Zβ = 0.84)

**Calculation**:
```
n = (1.96 + 0.84)² × [0.30(1-0.30) + 0.40(1-0.40)] / (0.40 - 0.30)²
n = (2.80)² × [0.30(0.70) + 0.40(0.60)] / (0.10)²
n = 7.84 × [0.21 + 0.24] / 0.01
n = 7.84 × 0.45 / 0.01
n = 3.528 / 0.01
n = 352.8

Rounded up: n = 353 per group
Total sample needed: 706 customers
```

### Secondary Metrics

**Revenue per converted customer**:
- Control: $59/month
- Treatment: $49/month
- Difference: -$10/month (-16.9%)

**Total revenue (conversion rate × price)**:
- Control: 0.30 × $59 = $17.70 per customer offered
- Treatment: 0.40 × $49 = $19.60 per customer offered
- Expected lift: +$1.90 per customer (+10.7%)

**Sample size for revenue metric**:
Assuming revenue standard deviation σ = $25 (due to 0s for non-converters):

```
n = 2 × (1.96 + 0.84)² × 25² / 1.90²
n = 2 × 7.84 × 625 / 3.61
n = 9,800 / 3.61
n = 2,714 per group
Total: 5,428 customers
```

**Recommendation**: Use conversion rate as primary metric (353/group), monitor revenue as secondary. Requires 5,428 customers for revenue significance.

### Implementation Plan

**Existing Customer Testing** (230 customers available):
- Split: 115 offered $59, 115 offered $49
- **Insufficient for statistical significance** (need 706)
- Can provide directional data only
- Extend to new customers to reach sample size

**Combined Testing** (existing + new):
- Need 706 total customers
- Have 230 existing
- Need 476 new signups
- At 10 new signups/month: 48 months ❌ TOO LONG
- At 50 new signups/month: 10 months ⚠️ MARGINAL
- At 100 new signups/month: 5 months ✓ VIABLE

**Revised approach if signup volume insufficient**:
- **Reduce power to 70%** (Zβ = 0.52):
  ```
  n = (1.96 + 0.52)² × 0.45 / 0.01 = 276 per group = 552 total
  ```
- **Increase minimum detectable effect to 12pp**:
  ```
  n = (1.96 + 0.84)² × 0.45 / (0.12)² = 245 per group = 490 total
  ```
- **Use one-tailed test** (if confident direction):
  Zα = 1.645 instead of 1.96:
  ```
  n = (1.645 + 0.84)² × 0.45 / 0.01 = 278 per group = 556 total
  ```

### Success Criteria
**Primary success** (proceed with $49 Team tier):
- Conversion rate at $49 ≥ 37% (p < 0.05)
- OR total revenue per customer at $49 ≥ revenue per customer at $59 (p < 0.10)

**Secondary success** (proceed with caution):
- Conversion rate at $49 between 33-37% (p < 0.10)
- AND 90-day retention rate ≥ 92% (inverse of 8% churn)

**Failure criteria** (use $59 Team tier):
- Conversion rate at $49 < 33% (not significantly different from $59 group)
- OR 90-day retention rate < 90%
- OR revenue per customer at $49 < 90% of revenue per customer at $59

### Duration & Early Stopping
**Minimum duration**: 30 days (account for weekly cycles)
**Maximum duration**: 90 days
**Early stopping rules**:
- Stop for success if p < 0.01 and n ≥ 200/group
- Stop for futility if after 50% of planned sample, conversion rates identical (difference < 2pp)

---

## TEST #2: SSO VALUE PROPOSITION MESSAGING

### Hypothesis
**H0**: Enterprise tier conversion rate with "SSO" messaging = conversion rate with "Security Suite" messaging
**H1**: Enterprise tier conversion rate with "Security Suite" messaging > conversion rate with "SSO" messaging

### Test Design
**Objective**: Determine if bundled positioning ("Enterprise Security Suite") converts better than feature-focused positioning ("Single Sign-On") for Enterprise tier, reducing SSO tax perception.

**Test Setup**:
- **Control Group (A)**: Enterprise tier marketed as "Adds SSO" - $89/month
- **Treatment Group (B)**: Enterprise tier marketed as "Security & Compliance Suite" (SSO + SCIM + Audit Logs + Support + SLA) - $89/month
- **Population**: Users qualifying for Enterprise (indicated need for SSO, teams >10, security requirements)
- **Duration**: 90 days
- **Randomization**: By session ID

### Primary Metric
**Conversion to Enterprise tier**:
- Baseline (estimated): 8% (from migration distribution assumption)
- Minimum detectable effect: 4 percentage points
- Expected with better messaging: 12%

### Sample Size Calculation

**Given**:
- p1 = 0.08
- p2 = 0.12
- Difference = 0.04
- α = 0.05, Power = 0.80

**Calculation**:
```
n = (1.96 + 0.84)² × [0.08(0.92) + 0.12(0.88)] / (0.04)²
n = 7.84 × [0.0736 + 0.1056] / 0.0016
n = 7.84 × 0.1792 / 0.0016
n = 1.405 / 0.0016
n = 878.125

Rounded up: n = 879 per group
Total sample needed: 1,758 qualified prospects
```

### Challenge: Qualified Prospect Volume
Enterprise prospects are rare. With 230 existing customers:
- 8% qualify = 18 customers
- **Vastly insufficient**

**Solution - Proxy Testing**:
Test on ALL customers, measuring "interest in Enterprise features":
- Primary metric: Click-through rate on Enterprise tier page
- Secondary metric: "Request info" form submissions
- Tertiary metric: Actual conversions (underpowered but directional)

**Revised sample size for CTR**:
Assuming:
- Baseline CTR: 15%
- Target CTR: 20% (+5pp)

```
n = (1.96 + 0.84)² × [0.15(0.85) + 0.20(0.80)] / (0.05)²
n = 7.84 × [0.1275 + 0.1600] / 0.0025
n = 7.84 × 0.2875 / 0.0025
n = 2.254 / 0.0025
n = 901.6

Total needed: 1,804 visitors
```

At 230 existing customers + 100 new/month:
- Month 0: 230 customers
- Month 5: 730 total (still short)
- Need ~18 months to reach sample size

**Practical approach**:
- **Qualitative testing first**: Show both messaging versions to 20 enterprise prospects (5 existing, 15 new), conduct interviews
- **Small quantitative test**: 230 existing customers, track engagement metrics (underpowered but directional)
- **Continuous monitoring**: Track Enterprise conversion over 12 months with messaging variant

### Success Criteria
**Primary success** (use "Security Suite" messaging):
- Enterprise tier CTR ≥ 18% with "Security Suite" vs ≤ 15% with "SSO" (p < 0.05)
- AND qualitative feedback shows >70% find "Security Suite" more valuable

**Secondary success**:
- CTR difference directionally positive (+2-3pp) but not significant (p < 0.10)
- AND average deal size for Enterprise ≥ $89/month (no discount pressure)

**Failure criteria** (use "SSO" messaging):
- No CTR difference (p > 0.20)
- OR qualitative feedback shows confusion with "Security Suite" messaging
- OR sales cycle lengthens >30% due to bundle complexity

### Implementation Plan

**Phase 1: Qualitative (Weeks 1-4)**
- Interview 20 target Enterprise customers
- Show both pricing pages
- Ask: "Which would you choose and why?"
- Record verbatim responses
- Identify concerns, objections, value perceptions

**Phase 2: Small Quantitative (Months 2-3)**
- A/B test on 230 existing + ~200 new customers
- Track CTR, info requests, conversion
- Accept statistical limitations
- Look for directional signal (>3pp difference)

**Phase 3: Continuous Monitoring (Months 4-12)**
- Implement winning variant (or continue test if inconclusive)
- Monitor Enterprise conversion rate
- Track customer feedback
- Measure SSO-related objections in sales calls

### Metrics Dashboard
| Metric | Control ("SSO") | Treatment ("Security Suite") | Significance |
|--------|----------------|----------------------------|--------------|
| CTR to Enterprise page | Track | Track | p-value |
| Info request submissions | Track | Track | p-value |
| Enterprise conversions | Track | Track | Directional |
| Average deal size | Track | Track | Directional |
| Sales cycle length | Track | Track | Directional |
| Customer satisfaction (NPS) | Track | Track | Ongoing |

---

## TEST #3: MIGRATION DISCOUNT STRATEGY

### Hypothesis
**H0**: 25% discount for 3 months = 30% discount for 3 months in terms of migration acceptance
**H1**: 30% discount for 3 months > 25% discount for 3 months in migration acceptance

### Test Design
**Objective**: Determine optimal migration discount to maximize migration rate while minimizing discount cost.

**Test Setup**:
- **Control Group (A)**: 25% discount for 3 months on Team/Enterprise/Dedicated tiers
- **Treatment Group (B)**: 30% discount for 3 months on Team/Enterprise/Dedicated tiers
- **Treatment Group (C)**: 20% discount for 4 months (same total value)
- **Population**: 230 existing customers migrating to new tiers
- **Duration**: 60-day migration window
- **Randomization**: Stratified by current usage to ensure balance

### Primary Metric
**Migration acceptance rate**:
- Baseline (no discount): Estimated 60%
- With 25% discount: Estimated 75%
- With 30% discount: Estimated 80%
- Minimum detectable effect: 8 percentage points

### Sample Size Calculation

**Comparing A (25%) vs B (30%)**:

**Given**:
- p1 = 0.75
- p2 = 0.83 (8pp increase)
- α = 0.05, Power = 0.80

**Calculation**:
```
n = (1.96 + 0.84)² × [0.75(0.25) + 0.83(0.17)] / (0.08)²
n = 7.84 × [0.1875 + 0.1411] / 0.0064
n = 7.84 × 0.3286 / 0.0064
n = 2.576 / 0.0064
n = 402.5

Total needed: 805 per two-group comparison
```

**Challenge**: Only 230 existing customers available

**Solution - Multi-armed test with lower power**:
With 230 customers split 3 ways:
- Group A (25% for 3mo): n = 77
- Group B (30% for 3mo): n = 77
- Group C (20% for 4mo): n = 76

Power calculation (reverse):
```
For n = 77 per group, detecting 8pp difference:
Power = Φ[√(n × (p2-p1)² / [p1(1-p1) + p2(1-p2)]) - Zα/2]
Power = Φ[√(77 × 0.08² / 0.3286) - 1.96]
Power = Φ[√(0.4928 / 0.3286) - 1.96]
Power = Φ[1.225 - 1.96]
Power = Φ[-0.735]
Power ≈ 0.23 (23%)
```

**Power is too low (need 80%)!**

**Alternative approach - Increase detectable effect**:
What difference can we detect with 80% power and n=77?

```
(p2-p1)² = (Zα/2 + Zβ)² × [p1(1-p1) + p2(1-p2)] / n
Assuming p1=0.75, solving for p2:
This requires iterative calculation, but approximately:
Detectable difference ≈ 15-18 percentage points
```

**Revised hypothesis**:
- Control (25% discount): 70% acceptance
- Treatment (30% discount): 85% acceptance (+15pp)
- This is detectable with n=77, power≈0.75

### Secondary Metrics

**Total discount cost**:
- Group A (25% × 3mo): Track total cost
- Group B (30% × 3mo): Track total cost
- Group C (20% × 4mo): Track total cost

**90-day retention rate post-discount**:
- Concern: Higher discount attracts "bargain hunters" who churn
- Track retention after discount expires
- Target: ≥90% retention

**Cost per acquired migration**:
```
Cost per migration = Total discount cost / Number of successful migrations

Example for Group A (25% for 3mo):
- 77 customers offered
- 54 accept (70%)
- Average tier price: $65
- Discount: $65 × 0.25 × 3 = $48.75 per customer
- Total cost: 54 × $48.75 = $2,632.50
- Cost per migration: $2,632.50 / 54 = $48.75

Example for Group B (30% for 3mo):
- 77 customers offered
- 65 accept (85%)
- Discount: $65 × 0.30 × 3 = $58.50 per customer
- Total cost: 65 × $58.50 = $3,802.50
- Cost per migration: $3,802.50 / 65 = $58.50

Difference: $9.75 more per migration (+20%)
But: 11 more customers migrated (20% more)
```

### Sample Size Reality Check

Given only 230 customers:
- **Cannot achieve 80% power for small differences (5-8pp)**
- **Can detect large differences (15pp+) with 70-75% power**
- **Trade-off required**

**Recommended approach**:
1. Run 3-way test with n=77 each
2. Accept lower power (70-75%)
3. Focus on practical significance, not just statistical
4. If one variant shows 15pp+ improvement, likely real
5. If differences are <10pp, consider all approaches acceptable

### Success Criteria

**Primary success** (choose winning discount):
- One variant achieves ≥85% migration rate (vs others ≤75%) with p < 0.10
- AND cost per migration within acceptable range (<$65)

**Secondary success** (choose most cost-effective):
- Migration rates similar (within 8pp)
- Choose variant with lowest cost per migration
- Ensure 90-day retention ≥90%

**Failure criteria** (increase all discounts):
- All variants achieve <70% migration rate
- Indicates discount insufficient or pricing too high
- Consider returning to pricing model

### Implementation Plan

**Pre-Migration (Weeks 1-2)**:
- Segment 230 customers into 3 balanced groups
- Ensure groups balanced by:
  - Current usage level
  - Account age
  - Payment history
  - Engagement metrics

**Migration Period (Weeks 3-10)**:
- Week 3: Send migration offer to all groups simultaneously
- Weeks 3-10: 60-day decision window
- Weekly reminders
- Track acceptance rates in real-time
- Monitor questions/objections

**Post-Migration (Weeks 11-24)**:
- Track which customers actually use new features
- Monitor retention (especially after discount expires)
- Calculate total cost and ROI
- Survey migrated customers for satisfaction

### Statistical Analysis Plan

**Primary analysis** (end of migration window):
```
Chi-square test for independence:
H0: Migration rate independent of discount level
HA: Migration rate depends on discount level

Contingency table:
                 Migrated    Declined    Total
Group A (25%)       n_A1        n_A2       77
Group B (30%)       n_B1        n_B2       77
Group C (20%/4mo)   n_C1        n_C2       76

χ² = Σ [(Observed - Expected)² / Expected]
df = (rows - 1) × (cols - 1) = 2
Critical value at α=0.05: 5.991
```

**Pairwise comparisons** (if χ² significant):
```
A vs B: Z-test for proportions
Z = (p_B - p_A) / √[p(1-p)(1/n_A + 1/n_B)]
where p = pooled proportion
```

**Cost effectiveness**:
```
Cost per migration difference:
Δ = Cost_B/Migration_B - Cost_A/Migration_A
Bootstrap confidence interval (1000 iterations)
```

### Failure & Pivot Plan

**If all groups <70% migration**:
- Week 6 (midpoint): Review interim results
- If tracking toward <70%: Extend discounts to all
  - Offer additional 10% discount for immediate acceptance
  - Extend deadline by 30 days
- Communicate: "Limited time enhanced offer"

**If differences negligible (<5pp)**:
- No statistical winner
- Choose cheapest option (likely Group C: 20% for 4mo)
- Implement for remaining non-migrated customers

**If clear winner (>15pp difference)**:
- Stop test early if one variant reaches 90%+
- Extend winning offer to other groups
- Maximize total migrations

---

## COMBINED TESTING ROADMAP

### Timeline

| Month | Test #1 (Price) | Test #2 (Messaging) | Test #3 (Discount) |
|-------|----------------|--------------------|--------------------|
| 1 | Setup & launch | Qualitative interviews | Customer segmentation |
| 2 | Data collection | Interview analysis | Setup & launch |
| 3 | Data collection | Quantitative setup | Data collection |
| 4 | Analysis | Quantitative launch | Analysis |
| 5 | Implement winner | Data collection | Implement winner |
| 6+ | Monitor | Continuous monitoring | Post-discount retention tracking |

### Resource Requirements

**Test #1 (Price Elasticity)**:
- Engineering: A/B test framework, pricing display logic
- Analytics: Conversion tracking, revenue attribution
- Sample: 706 customers (may require 6-12 months to accumulate)
- Duration: 60-90 days data collection

**Test #2 (Messaging)**:
- Design: 2 pricing page variants
- Sales: Interview 20 prospects (4 hours)
- Analytics: CTR tracking, engagement metrics
- Sample: 1,804 visitors (12-18 months)
- Duration: Ongoing qualitative + 90 days quantitative

**Test #3 (Discount Strategy)**:
- Engineering: Discount code system, email personalization
- Finance: Budget approval for discounts ($10k-15k total)
- Analytics: Migration tracking, retention monitoring
- Sample: 230 existing customers (available now)
- Duration: 60 days + 90 days retention tracking

### Budget

**Discount costs** (Test #3):
- Group A: ~$2,600
- Group B: ~$3,800
- Group C: ~$2,400
- **Total: ~$8,800**

**Opportunity cost** (Test #1):
- If $49 wins but we test $59 for 3 months on 350 customers:
- Lost revenue: 350 × 0.10 (lift) × $10 (price diff) × 3 months = $10,500
- **Mitigate**: Run test on new customers only, grandfather existing at optimal price

**Personnel time**:
- Test #1: 40 hours (setup) + 10 hours/month (monitoring)
- Test #2: 80 hours (interviews + analysis) + 20 hours (setup) + ongoing
- Test #3: 30 hours (setup) + 20 hours (analysis)
- **Total: ~200 hours**

---

## STATISTICAL POWER SUMMARY

| Test | Metric | Sample/Group | Power | Detectable Effect | Feasibility |
|------|--------|--------------|-------|-------------------|-------------|
| #1 Price | Conversion | 353 | 80% | 10pp (30%→40%) | ⚠️ Requires 6-12mo |
| #1 Price (reduced) | Conversion | 276 | 70% | 10pp | ✓ More feasible |
| #2 Messaging | CTR | 902 | 80% | 5pp (15%→20%) | ⚠️ Requires 12-18mo |
| #2 Messaging (proxy) | Qualitative | 20 | N/A | N/A | ✓ Immediately feasible |
| #3 Discount | Migration % | 77 | 75% | 15pp (70%→85%) | ✓ Feasible now |

---

## RECOMMENDATIONS

### Immediate (Month 1)
✅ **Launch Test #3 (Discount Strategy)** with existing 230 customers
- Have sample size now
- Critical for migration success
- Acceptable power for large effects
- Informs rollout strategy

✅ **Start Test #2 Qualitative Phase**
- Interview 20 enterprise prospects
- Low cost, high value insights
- Informs messaging immediately

### Short-term (Months 2-3)
⚠️ **Launch Test #1 (Price) with reduced parameters**
- Lower power to 70% (need 552 total vs 706)
- Or increase detectable effect to 12pp
- Run on new customers only to avoid alienating existing base

⚠️ **Launch Test #2 Quantitative** (if volume permits)
- Track CTR and engagement
- Accept lower power
- Use as directional signal

### Long-term (Months 4-12)
📊 **Continuous monitoring of all metrics**
- Even underpowered tests provide directional data
- Combine quantitative + qualitative insights
- Iterate based on real customer behavior

### Fallback Plan (Insufficient Sample)
If customer volume doesn't support statistical testing:

1. **Lean on competitor data**: Use median 50% SSO premium from market analysis
2. **Qualitative heavy**: Emphasize interviews, surveys, feedback
3. **Small-batch testing**: Test with 20-50 customers, iterate quickly
4. **Reversibility**: Choose pricing that can be adjusted within 90 days if wrong
5. **Gradual rollout**: Launch to 10% of customers, monitor, expand

---

## FINAL NOTE ON STATISTICAL RIGOR

**Perfect is the enemy of good.**

With 230 customers, you **cannot** achieve 80% power for small effects. You have three options:

1. **Wait months/years** to accumulate sample size → Miss market opportunity
2. **Accept lower power (60-70%)** → May miss true small effects, but detect large ones
3. **Skip statistical testing** → Rely purely on market research and intuition

**Recommended hybrid approach**:
- Run **Test #3** with full rigor (you have the sample)
- Run **Test #2** qualitatively first, quantitatively when possible
- Run **Test #1** with reduced power OR use market data as proxy
- **Monitor everything** continuously and adjust within 90 days if metrics deteriorate

Statistical significance is valuable but not always achievable for startups. **Practical significance** (e.g., "30% of customers complained about price") can be just as actionable.

**The goal is to make the best decision with available data, not to achieve perfect statistical purity.**
