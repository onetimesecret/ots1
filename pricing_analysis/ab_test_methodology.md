# A/B Testing Methodology for Pricing Validation

## Overview

This document outlines three A/B tests designed to validate critical pricing assumptions before full migration. Each test includes statistical power calculations, sample size requirements, specific metrics, and failure criteria.

---

## Test 1: Individual Tier Price Sensitivity Test

### Hypothesis

**H0 (Null Hypothesis)**: Individual tier pricing between $19-$35/month has no significant impact on conversion rate or retention.

**H1 (Alternative Hypothesis)**: Lower Individual tier pricing ($19-25) will increase conversion rate by ≥15% compared to current $35 pricing.

### Test Design

**Test Type**: Multi-variant A/B test (4 variants)

**Variants**:
- **Control (A)**: $35.00/month (current pricing)
- **Variant B**: $29.00/month (-17.14% from control)
- **Variant C**: $25.00/month (-28.57% from control)
- **Variant D**: $19.00/month (-45.71% from control)

**Traffic Allocation**: 25% to each variant (equal split)

**Test Duration**: 60 days (two full billing cycles)

### Primary Metrics

**1. Conversion Rate**:
- Definition: % of free trial users who convert to paid Individual tier
- Current baseline: Assume 8.5% (industry standard for SaaS)
- Target improvement: ≥15% relative increase (8.5% → 9.8%)

**2. 60-Day Retention Rate**:
- Definition: % of new customers who remain active after 60 days
- Current baseline: Assume 93% (inverse of 7% monthly churn)
- Target: Maintain ≥93% across all variants

**3. Revenue Per Customer (RPC)**:
- Definition: Average revenue per customer over 60 days
- Control RPC: $35 × 2 months × 0.93 retention = $65.10
- Variant D RPC: $19 × 2 months × 0.93 retention = $35.34

### Sample Size Calculation

**Method**: Two-proportion z-test for conversion rates

**Parameters**:
- **Baseline conversion rate (p₁)**: 8.5%
- **Minimum detectable effect (MDE)**: 15% relative lift = 1.275% absolute increase
- **Target conversion rate (p₂)**: 9.775%
- **Significance level (α)**: 0.05 (5% Type I error rate)
- **Statistical power (1-β)**: 0.80 (80% power, 20% Type II error rate)
- **Test type**: Two-tailed

**Formula**:
```
n = (Z_α/2 + Z_β)² × [p₁(1-p₁) + p₂(1-p₂)] / (p₂-p₁)²

Where:
- Z_α/2 = 1.96 (for α = 0.05, two-tailed)
- Z_β = 0.84 (for power = 0.80)
- p₁ = 0.085 (baseline conversion)
- p₂ = 0.09775 (target conversion)
```

**Calculation**:
```
p₁(1-p₁) = 0.085 × 0.915 = 0.077775
p₂(1-p₂) = 0.09775 × 0.90225 = 0.088195
(p₂-p₁)² = (0.09775-0.085)² = 0.000162

n = (1.96 + 0.84)² × (0.077775 + 0.088195) / 0.000162
n = 7.84 × 0.16597 / 0.000162
n = 1.301 / 0.000162
n = 8,031.36 ≈ 8,032 per variant
```

**Total Sample Size Required**: 8,032 × 4 variants = **32,128 free trial starts**

**With Current Traffic**:
- Current customer base: 230 customers
- Estimated new trial starts per month: 230 × (7% churn + 5% growth) = 28 per month
- Trials needed: 32,128
- **Required duration**: 32,128 / 28 = 1,148 months = 95.6 years ⚠️

**ISSUE**: Sample size infeasible with current traffic.

### Revised Test Design (Feasible)

**Option 1: Reduce Variants**
- Test only Control ($35) vs. Best Candidate ($22)
- Sample size per variant: 8,032
- Total sample size: 16,064
- Required duration: Still infeasible

**Option 2: Increase MDE to 30%**
```
Target conversion: 8.5% → 11.05% (30% relative lift)
(p₂-p₁)² = (0.1105-0.085)² = 0.000651

n = 7.84 × 0.16597 / 0.000651
n = 1,998 per variant
Total = 1,998 × 2 = 3,996 trials
Duration = 3,996 / 28 = 143 months ⚠️
```

**Option 3: Bayesian Adaptive Test (RECOMMENDED)**
- Start with 100 customers per variant (400 total)
- Use Bayesian inference to update priors continuously
- Stop test when 95% credible interval excludes null hypothesis
- Or when futility threshold reached (no chance of significance)

**Bayesian Sample Size**:
- Initial cohort: 100 customers × 4 variants = 400 customers
- Duration: 400 / 28 = 14.3 months (feasible)
- Early stopping possible if strong signal

### Success Criteria

**Primary Success Criterion**:
- At least one variant achieves ≥15% conversion rate increase with p < 0.05

**Secondary Success Criteria**:
1. Retention rate ≥93% for winning variant (no degradation)
2. Net Revenue Impact positive: (Conversion Lift × Price) > 0
   - Example: Variant D ($19) must increase conversion by ≥84.2% to match control revenue
   - Calculation: $19 × (1 + X) ≥ $35 → X ≥ 0.842

**Formula for Revenue Neutrality**:
```
Revenue_Variant = Price_Variant × Conversion_Variant × Retention_Variant
Revenue_Control = Price_Control × Conversion_Control × Retention_Control

For revenue neutrality:
Price_Variant × (Conversion_Control × (1 + Lift)) = Price_Control × Conversion_Control

Required Lift = (Price_Control / Price_Variant) - 1

Variant D ($19): Required lift = ($35 / $19) - 1 = 84.2%
Variant C ($25): Required lift = ($35 / $25) - 1 = 40%
Variant B ($29): Required lift = ($35 / $29) - 1 = 20.7%
```

### Failure Criteria

**Test should be stopped if**:
1. Any variant shows retention drop >10% (below 83.7%)
2. After 200 customers per variant, no variant shows >5% conversion improvement
3. Negative revenue trend confirmed with 90% confidence
4. Implementation issues (tracking failures, customer complaints)

### Implementation Plan

**Phase 1: Setup (Week 1-2)**
- Create landing pages for each variant
- Set up A/B testing infrastructure (randomization, tracking)
- Configure analytics (conversion events, retention tracking)

**Phase 2: Pilot (Week 3-6)**
- Run test with 50 customers per variant (200 total)
- Monitor daily for implementation issues
- Conduct interim analysis at 50 customers per variant

**Phase 3: Full Test (Week 7-62)**
- Continue test until statistical significance or futility
- Weekly analysis of key metrics
- Monthly review with stakeholders

**Phase 4: Analysis (Week 63-64)**
- Final statistical analysis
- Calculate confidence intervals
- Prepare recommendation

### Reporting Template

```
Individual Tier Price Sensitivity Test Results

Test Period: [Start Date] - [End Date]
Total Participants: [N]

| Variant | Price | Participants | Conversions | Conv. Rate | Lift vs Control | p-value | Retention | Revenue/Customer |
|---------|-------|--------------|-------------|------------|-----------------|---------|-----------|-------------------|
| Control | $35   | [n]          | [c]         | [%]        | -               | -       | [%]       | $[X]              |
| B       | $29   | [n]          | [c]         | [%]        | [%]             | [p]     | [%]       | $[X]              |
| C       | $25   | [n]          | [c]         | [%]        | [%]             | [p]     | [%]       | $[X]              |
| D       | $19   | [n]          | [c]         | [%]        | [%]             | [p]     | [%]       | $[X]              |

Winning Variant: [Variant]
Recommendation: [Adopt/Reject with rationale]
```

---

## Test 2: Tier Distribution Prediction Test

### Hypothesis

**H0 (Null Hypothesis)**: Customer self-selection into tiers will follow assumed distribution (60/30/8/2).

**H1 (Alternative Hypothesis)**: Actual tier selection will differ significantly from assumed distribution.

### Test Design

**Test Type**: Chi-square goodness-of-fit test

**Approach**: Present new customers with all four tiers and measure actual selection rate.

**Variants**:
- **Control Group**: Current single-tier offering ($35)
- **Test Group**: Four-tier offering (Individual/Team/Enterprise/Dedicated)

**Traffic Allocation**: 20% to test group (80% to control to minimize revenue risk)

**Test Duration**: 90 days (to allow for enterprise sales cycles)

### Primary Metrics

**1. Tier Selection Rate**:
- Expected: 60% Individual, 30% Team, 8% Enterprise, 2% Dedicated
- Actual: Measured from test group

**2. Average Revenue Per Customer (ARPC)**:
- Control ARPC: $35.00
- Test Group ARPC: Weighted average of tier selections
- Target: Test Group ARPC ≥ Control ARPC × 1.15 (15% increase)

**3. Conversion Rate by Tier**:
- Measure if certain tiers have higher/lower conversion from trial

### Sample Size Calculation

**Method**: Chi-square test for goodness-of-fit

**Parameters**:
- **Significance level (α)**: 0.05
- **Statistical power (1-β)**: 0.80
- **Degrees of freedom**: 3 (4 tiers - 1)
- **Effect size (w)**: 0.3 (medium effect)

**Formula using Cohen's w**:
```
n = (Z_α + Z_β)² / w²

For chi-square with df=3:
Critical χ² value at α=0.05: 7.815

For effect size w=0.3 (medium):
n = [(1.96 + 0.84)² / 0.3²] × (df / 4)
n = (7.84 / 0.09) × (3 / 4)
n = 87.11 × 0.75
n = 65.33 per category
```

**Total Sample Size**: 65 × 4 tiers = **260 customers minimum**

**Alternative Calculation using Power Analysis**:
```
Expected frequencies:
- Individual: 156 (60%)
- Team: 78 (30%)
- Enterprise: 21 (8%)
- Dedicated: 5 (2%)

Minimum sample to detect 10 percentage point shift in any tier:
n = 260 customers
```

**With Current Traffic**:
- New customers per month (20% of traffic): 28 × 0.20 = 5.6 customers/month
- Required duration: 260 / 5.6 = **46.4 months** ⚠️

### Revised Test Design (Feasible)

**Option 1: Increase allocation to test group**
- Allocate 80% to test group, 20% to control
- Faster accumulation: 28 × 0.80 = 22.4 customers/month
- Duration: 260 / 22.4 = **11.6 months** (feasible but long)

**Option 2: Survey-based prediction**
- Survey existing 230 customers about tier preference
- Response rate: 40% = 92 responses
- Faster: Can complete in 1 month
- Less accurate: Stated vs. revealed preference gap

**Option 3: Soft launch to all new customers (RECOMMENDED)**
- Launch four-tier pricing to 100% of new customers
- Track for 90 days (minimum 84 new customers)
- Lower statistical power but real-world data

### Success Criteria

**Primary Success Criterion**:
- Chi-square test p-value > 0.05 (fail to reject H0 = distribution matches expectations)
- OR: If distribution differs, ARPC still increases by ≥15%

**Secondary Success Criteria**:
1. No tier has <5 selections (minimum viable sample per tier)
2. Total MRR from test group ≥ MRR from equivalent control group
3. Conversion rate doesn't drop >10% with multi-tier offering

**Tier Distribution Acceptance Ranges**:
```
Individual: 50-70% (expected 60% ± 10pp)
Team: 20-40% (expected 30% ± 10pp)
Enterprise: 3-13% (expected 8% ± 5pp)
Dedicated: 0-7% (expected 2% ± 5pp)
```

### Calculation Examples

**Scenario: Actual distribution = 70% Individual, 25% Team, 4% Enterprise, 1% Dedicated**

**Chi-square calculation**:
```
n = 260 customers

Expected:
- Individual: 156 (60%)
- Team: 78 (30%)
- Enterprise: 21 (8%)
- Dedicated: 5 (2%)

Observed:
- Individual: 182 (70%)
- Team: 65 (25%)
- Enterprise: 10 (4%)
- Dedicated: 3 (1%)

χ² = Σ[(O-E)²/E]
χ² = (182-156)²/156 + (65-78)²/78 + (10-21)²/21 + (3-5)²/5
χ² = 676/156 + 169/78 + 121/21 + 4/5
χ² = 4.33 + 2.17 + 5.76 + 0.80
χ² = 13.06

Critical value at df=3, α=0.05: 7.815
13.06 > 7.815 → Reject H0 (distribution differs significantly)
```

**Revenue Impact**:
```
Using Scenario 5 (Hybrid) pricing:
Individual: $22, Team: $95, Enterprise: $249, Dedicated: $699

Expected ARPC:
(156 × $22 + 78 × $95 + 21 × $249 + 5 × $699) / 260
= ($3,432 + $7,410 + $5,229 + $3,495) / 260
= $19,566 / 260
= $75.25

Observed ARPC (70/25/4/1 distribution):
(182 × $22 + 65 × $95 + 10 × $249 + 3 × $699) / 260
= ($4,004 + $6,175 + $2,490 + $2,097) / 260
= $14,766 / 260
= $56.79

Difference: $56.79 - $75.25 = -$18.46 (-24.5%)
```

**Interpretation**: Distribution shift toward Individual tier reduces ARPC by 24.5%. This scenario would FAIL success criteria.

### Failure Criteria

**Test should be stopped if**:
1. After 150 customers, <3 selections in Enterprise or Dedicated tier (insufficient sample)
2. ARPC drops >20% below control
3. Conversion rate drops >15%
4. Over 80% of customers select Individual tier (suggests pricing misalignment)

### Implementation Plan

**Phase 1: Preparation (Week 1-4)**
- Design pricing page with clear tier differentiation
- Create comparison table of features
- Set up tracking for tier selections
- Prepare sales materials for higher tiers

**Phase 2: Soft Launch (Week 5-8)**
- Launch to 20% of new customers (survey intent)
- Gather qualitative feedback via post-selection survey
- Identify confusion points or objections

**Phase 3: Full Test (Week 9-48)**
- Launch to 80-100% of new customers
- Monthly analysis of distribution trends
- Adjust messaging if necessary (not pricing)

**Phase 4: Analysis (Week 49-52)**
- Final statistical analysis
- Compare predicted vs. actual distribution
- Update financial model with actual data

### Reporting Template

```
Tier Distribution Prediction Test Results

Test Period: [Start Date] - [End Date]
Total Participants: [N]

| Tier | Expected % | Expected Count | Actual % | Actual Count | Difference |
|------|-----------|----------------|----------|--------------|------------|
| Individual | 60% | [n] | [%] | [n] | [pp] |
| Team | 30% | [n] | [%] | [n] | [pp] |
| Enterprise | 8% | [n] | [%] | [n] | [pp] |
| Dedicated | 2% | [n] | [%] | [n] | [pp] |

Chi-square: [χ²]
p-value: [p]
Result: [Distribution matches expectations / Distribution differs significantly]

Expected ARPC: $[X]
Actual ARPC: $[X]
Difference: [%]

Recommendation: [Update model / Proceed with assumptions]
```

---

## Test 3: Migration Discount Impact Test

### Hypothesis

**H0 (Null Hypothesis)**: Offering migration discount (20% for 3 months) does not significantly impact upgrade rate or retention.

**H1 (Alternative Hypothesis)**: Migration discount increases upgrade rate by ≥25% and improves 6-month retention by ≥5%.

### Test Design

**Test Type**: A/B test with existing customer migration

**Cohorts**:
- **Control (A)**: No discount, immediate migration to new tiers
- **Variant B**: 20% discount for first 3 months
- **Variant C**: 30% discount for first 3 months
- **Variant D**: 15% discount for first 6 months

**Traffic Allocation**: 25% to each cohort (equal split among 230 existing customers)

**Test Duration**: 180 days (6 months to measure retention)

### Primary Metrics

**1. Tier Upgrade Rate**:
- Definition: % of Individual-priced customers ($35) who upgrade to Team/Enterprise tiers
- Baseline: Assume 5% organic upgrade rate (no discount)
- Target: ≥25% relative increase → 6.25% upgrade rate

**2. Churn Rate (6-month)**:
- Definition: % of customers who cancel within 6 months of migration
- Current baseline: (1 - 0.93^6) = 35.3% churn over 6 months
- Target: ≤30% churn (5pp improvement)

**3. Net Revenue Impact (6-month)**:
- Definition: Total revenue from cohort over 6 months minus discount cost
- Formula: `(MRR_M0 + MRR_M1 + ... + MRR_M5) - Discount_Cost`
- Target: Net revenue ≥ Control group revenue

### Sample Size Calculation

**Method**: Two-proportion z-test for upgrade rate

**Parameters**:
- **Baseline upgrade rate (p₁)**: 5%
- **Target upgrade rate (p₂)**: 6.25% (25% relative lift)
- **Significance level (α)**: 0.05
- **Statistical power (1-β)**: 0.80

**Calculation**:
```
p₁ = 0.05
p₂ = 0.0625
(p₂-p₁)² = (0.0625-0.05)² = 0.00015625

p₁(1-p₁) = 0.05 × 0.95 = 0.0475
p₂(1-p₂) = 0.0625 × 0.9375 = 0.05859

n = (1.96 + 0.84)² × (0.0475 + 0.05859) / 0.00015625
n = 7.84 × 0.10609 / 0.00015625
n = 5,323 per cohort
```

**Total Sample Size Required**: 5,323 × 4 cohorts = **21,292 customers** ⚠️

**Current Customer Base**: 230 customers

**ISSUE**: Massively underpowered with current base.

### Revised Test Design (Feasible)

**Option 1: All existing customers with sequential rollout**
- Week 1-2: Control (no discount) to 25% = 58 customers
- Week 3-4: Variant B (20% discount) to 25% = 58 customers
- Week 5-6: Variant C (30% discount) to 25% = 58 customers
- Week 7-8: Variant D (15% for 6mo) to 25% = 58 customers

**Option 2: Binary test (discount vs. no discount)**
- Control: No discount (115 customers)
- Variant: 20% discount for 3 months (115 customers)
- Increased MDE to 50% relative lift (5% → 7.5%)

**Calculation for Binary Test**:
```
p₁ = 0.05
p₂ = 0.075
(p₂-p₁)² = 0.000625

n = 7.84 × 0.10609 / 0.000625
n = 1,330 per cohort
```

Still requires 2,660 customers total ⚠️

**Option 3: Observational study (RECOMMENDED)**
- Offer discount to all 230 existing customers
- Measure upgrade rate and churn
- Compare to historical baseline (pre-migration)
- No control group (less rigorous but feasible)

**Sample Size for Single-Sample Proportion Test**:
```
Baseline upgrade rate: 5%
Target: 7.5% (50% increase)
α = 0.05, power = 0.80

n = [(Z_α + Z_β) × √(p(1-p))]² / (p-p₀)²
n = [(1.96 + 0.84) × √(0.075 × 0.925)]² / (0.075-0.05)²
n = [2.80 × 0.263]² / 0.000625
n = 0.536 / 0.000625
n = 858 customers
```

Still too large. **Current base insufficient for rigorous test.**

### Alternative Approach: Effect Size Estimation

**With 230 customers, what effect can we detect?**

```
n = 115 per group (binary split)
α = 0.05, power = 0.80

MDE = (Z_α + Z_β) × √[(p₁(1-p₁) + p₂(1-p₂)) / n]

Assuming p₁ = 0.05, solving for p₂:
MDE = 2.80 × √[(0.0475 + p₂(1-p₂)) / 115]

For reasonable detection:
p₂ ≈ 0.15 (3x baseline = 200% relative lift)
```

**Conclusion**: With 230 customers, can only detect massive effect sizes (200%+ lift). Not suitable for subtle discount effects.

### Recommended Test Design (Practical)

**Approach**: **Discount for All + Historical Comparison**

**Implementation**:
1. Offer 20% discount for 3 months to all 230 existing customers
2. Track upgrade rate and churn
3. Compare to historical upgrade rate (if available)
4. Conduct customer surveys to understand discount impact

**Metrics**:
- **Upgrade Rate**: Target ≥7.5% (vs. 5% historical baseline)
- **Churn Rate (6-month)**: Target ≤30% (vs. 35.3% baseline)
- **Net Revenue**: Target revenue neutral or positive vs. non-discount scenario

**Statistical Approach**:
- Single-sample proportion test (upgrade rate vs. historical baseline)
- Survival analysis (Kaplan-Meier) for churn over time
- Qualitative feedback from customer surveys

### Success Criteria

**Primary Success Criterion**:
- Upgrade rate ≥7.5% (50% increase from 5% baseline) with 90% confidence

**Secondary Success Criteria**:
1. 6-month churn rate ≤30% (5pp improvement)
2. Net revenue after discounts ≥ projected revenue without discounts
3. Customer satisfaction score (survey) ≥7/10 regarding migration

**Revenue Neutrality Calculation**:
```
Scenario: 230 customers, Hybrid pricing (Scenario 5)

Without discount (Month 0-5):
- Distribution: 138 Individual ($22), 69 Team ($95), 18 Enterprise ($249), 5 Dedicated ($699)
- MRR M0: $17,568
- 6-month total with churn: $17,568 + $16,624 + $15,797 + $14,992 + $14,205 + $13,437 = $92,623

With 20% discount (Month 0-2):
- MRR M0: $14,054 (discounted)
- MRR M1: $13,299 (discounted)
- MRR M2: $12,638 (discounted)
- MRR M3: $14,992 (full price)
- MRR M4: $14,205 (full price)
- MRR M5: $13,437 (full price)
- 6-month total: $82,625

Discount cost: $92,623 - $82,625 = $9,998
Break-even: Requires $9,998 in additional revenue from upgrades or reduced churn
```

**Upgrade Impact**:
```
If 10 customers upgrade from Individual ($22) to Team ($95):
- Additional MRR: 10 × ($95 - $22) = $730/month
- 6-month value: $730 × 6 × 0.93^3 = $3,444 (with churn)

Need: $9,998 / $3,444 = 2.9 months to break even
OR: Need 29 upgrades over 6 months (12.6% of Individual tier customers)
```

### Failure Criteria

**Test should be stopped or reconsidered if**:
1. Month 3 churn rate >15% (projected to 6-month churn >40%)
2. Upgrade rate <3% after 90 days (unlikely to reach 7.5% target)
3. Negative customer feedback score <5/10
4. Net revenue on track to be <-10% vs. non-discount scenario

### Implementation Plan

**Phase 1: Communication (Week 1-2)**
- Email campaign explaining new tiers to existing customers
- Highlight discount offer (limited time: 3 months)
- Provide tier comparison tool and upgrade path

**Phase 2: Migration Window (Week 3-6)**
- Open 30-day migration window for existing customers
- Personal outreach to potential Team/Enterprise customers
- Support team available for questions

**Phase 3: Monitoring (Week 7-28)**
- Weekly tracking of upgrade rate, churn, support tickets
- Monthly customer surveys (NPS, satisfaction)
- Financial tracking of net revenue impact

**Phase 4: Analysis (Week 29-32)**
- Final calculation of upgrade rate, churn rate, net revenue
- Customer survey analysis
- Recommendation: permanent discount for future migrations?

### Reporting Template

```
Migration Discount Impact Test Results

Test Period: [Start Date] - [End Date]
Total Participants: 230 existing customers

Cohort: 20% Discount for 3 Months

Metric | Historical Baseline | Target | Actual | Status |
|------|---------------------|--------|--------|--------|
| Upgrade Rate | 5% | 7.5% | [%] | [Pass/Fail] |
| 6-Month Churn | 35.3% | ≤30% | [%] | [Pass/Fail] |
| Net Revenue (6mo) | $92,623 | ≥$92,623 | $[X] | [Pass/Fail] |
| Customer Satisfaction | N/A | ≥7/10 | [X]/10 | [Pass/Fail] |

Upgrade Breakdown:
- Individual → Team: [n] customers
- Individual → Enterprise: [n] customers
- Individual → Dedicated: [n] customers

Churn Analysis:
- Month 1 churn: [%]
- Month 3 churn (cumulative): [%]
- Month 6 churn (cumulative): [%]

Qualitative Feedback:
[Summary of customer survey responses]

Recommendation: [Offer discount / Don't offer discount] for future migrations
Rationale: [Evidence-based reasoning]
```

---

## Summary: Statistical Power vs. Practical Constraints

### Power Analysis Summary

| Test | Ideal Sample Size | Available Sample | Feasibility | Recommended Approach |
|------|------------------|------------------|-------------|----------------------|
| Test 1: Individual Tier Pricing | 32,128 | ~28/month | Infeasible | Bayesian adaptive with 400 customers (14 months) |
| Test 2: Tier Distribution | 260 | ~28/month | Marginal | Soft launch to 100% new customers (90 days) |
| Test 3: Migration Discount | 21,292 | 230 total | Infeasible | Observational study with historical comparison |

### Key Statistical Concepts

**1. Statistical Power (1-β)**:
- Definition: Probability of detecting a true effect when it exists
- Standard: 80% (0.80)
- Trade-off: Higher power requires larger sample size

**2. Significance Level (α)**:
- Definition: Probability of false positive (Type I error)
- Standard: 5% (0.05)
- Trade-off: Lower α requires larger sample size

**3. Minimum Detectable Effect (MDE)**:
- Definition: Smallest effect size the test can reliably detect
- Trade-off: Smaller MDE requires exponentially larger sample
- OTS Constraint: Small customer base means can only detect large effects (30-50%+ lifts)

**4. Sample Size Formula (Two-Proportion Test)**:
```
n = (Z_α/2 + Z_β)² × [p₁(1-p₁) + p₂(1-p₂)] / (p₂-p₁)²

Where:
- Z_α/2: Critical value for significance level (1.96 for α=0.05)
- Z_β: Critical value for power (0.84 for 80% power)
- p₁: Control proportion
- p₂: Treatment proportion
- (p₂-p₁): Effect size
```

### Practical Recommendations

**Given OTS's constraints (230 current customers, ~28 new/month), recommend**:

1. **Test 1 (Pricing)**: Use Bayesian adaptive testing with lower sample size (400 customers over 14 months) and accept wider confidence intervals.

2. **Test 2 (Distribution)**: Launch four-tier pricing to 100% of new customers for 90 days. Accept lower statistical power in exchange for real-world data.

3. **Test 3 (Discount)**: Offer discount to all existing customers, measure upgrade rate, compare to historical baseline. Supplement with customer surveys for qualitative validation.

**Alternative**: Conduct all tests simultaneously:
- New customers → Test 1 (pricing) + Test 2 (distribution)
- Existing customers → Test 3 (discount migration)
- Combined duration: 6 months
- Total customers needed: ~168 new + 230 existing = 398 total

This approach maximizes learning while working within resource constraints.

---

## Confidence Intervals for Small Samples

### When Statistical Significance is Unattainable

**Reality**: With 230 existing customers and 28 new/month, achieving p<0.05 for modest effect sizes (15-30% lifts) is impossible in reasonable timeframes.

**Alternative Framework**: **Estimation with Confidence Intervals**

Instead of testing "Is the effect significant?" ask "What is our best estimate of the effect, and how uncertain are we?"

### Example: Individual Tier Pricing

**Scenario**: Test $22 vs. $35 with 100 customers each

**Observed Results**:
- $22 tier: 12 conversions (12% conversion rate)
- $35 tier: 9 conversions (9% conversion rate)
- Difference: 3 percentage points (33% relative lift)

**Statistical Test**:
```
p-value ≈ 0.45 (not significant at α=0.05)
```

**Confidence Interval Approach**:
```
95% CI for difference: [-4.2%, +10.2%]

Interpretation: We're 95% confident the true lift is between -4.2pp and +10.2pp.
While not "significant," the point estimate (3pp lift) and upper bound (+10.2pp)
suggest potential benefit worth considering alongside other factors (revenue,
qualitative feedback, strategic positioning).
```

### Decision Framework for Small Samples

**Use this criteria**:
1. **Point estimate direction**: Does the effect go in the expected direction?
2. **Confidence interval**: Does the lower bound exclude catastrophic outcomes?
3. **Practical significance**: Is the point estimate large enough to matter economically?
4. **Qualitative alignment**: Do customer surveys support the quantitative findings?

**Example Decision**:
- Point estimate: +3pp conversion lift for $22 tier
- 95% CI: [-4.2%, +10.2%]
- Practical significance: Even at lower bound (-4.2%), revenue may be neutral due to other factors
- Qualitative: Customer surveys show "excellent value" for $22 tier

**Decision**: Adopt $22 tier despite statistical insignificance, because:
- Direction is positive
- Risk is bounded
- Economic model supports it
- Customer feedback is strong

---

## Conclusion

Given OTS's small customer base, traditional A/B testing with p<0.05 significance is **not feasible** for most pricing questions.

**Recommended hybrid approach**:
1. **Quantitative**: Run tests with available samples, report confidence intervals
2. **Qualitative**: Heavy reliance on customer surveys, interviews, feedback
3. **Competitive**: Benchmark against market pricing (already done)
4. **Financial**: Model revenue impact with sensitivity analysis
5. **Iterative**: Launch, measure, adjust quickly rather than waiting for significance

**Final recommendation**: Proceed with Scenario 5 (Hybrid) pricing based on:
- Competitive analysis (✓ complete)
- Financial modeling (✓ complete)
- Customer surveys (→ to be conducted)
- Small-scale test (→ 100 customers over 90 days for validation)

This combines available evidence with practical business needs, accepting higher uncertainty in exchange for faster decision-making.
