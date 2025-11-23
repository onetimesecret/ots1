# A/B Testing Framework for OneTimeSecret Pricing Optimization

## Executive Summary

This framework provides a rigorous statistical approach to validate intermediate pricing tiers before full rollout. Each test includes sample size calculations, success criteria, rollback triggers, and monitoring dashboards to ensure data-driven decisions.

---

## TESTING PHILOSOPHY

### Core Principles
1. **Statistical Rigor**: All tests must reach 95% confidence level before conclusions
2. **Risk Mitigation**: Grandfather existing customers; test with new signups first
3. **Iterative Validation**: Test one tier at a time to isolate variables
4. **Revenue Protection**: Immediate rollback if MRR drops >5% vs. control

### Test Sequence
1. **Phase 1**: Professional Tier ($45-49) - Lowest risk, highest volume
2. **Phase 2**: Business Tier ($125) - Mid-risk, mid-volume
3. **Phase 3**: Premium Tier ($275-300) - Highest risk, lowest volume

---

## TEST 1: PROFESSIONAL TIER ($45-49/MONTH)

### Hypothesis
**H0 (Null)**: Adding a $45-49 Professional tier will NOT increase MRR
**H1 (Alternative)**: Adding a $45-49 Professional tier will increase MRR by ≥15%

### Test Design

**Type**: Between-subjects A/B test
**Duration**: 60 days minimum (2 billing cycles)
**Allocation**: 50/50 split for new signups

**Control Group (A)**:
- Sees current pricing: $25 (Individual), $75 (Team), $150 (Enterprise), $500 (Dedicated)
- n = 115 new signups expected

**Treatment Group (B)**:
- Sees new pricing: $25 (Individual), **$49 (Professional)**, $75 (Team), $150 (Enterprise), $500 (Dedicated)
- n = 115 new signups expected

**Existing Customers**: NOT included in test (grandfather pricing)

### Sample Size Calculation

**Primary Metric**: Revenue per new signup (conversion rate × ARPU)

**Assumptions**:
- Baseline conversion rate: 15% (from free trial to paid)
- Baseline ARPU: $45/month (weighted average)
- Minimum Detectable Effect (MDE): 15% increase in revenue per signup
- Statistical Power: 80%
- Significance Level (α): 0.05 (5%)

**Formula**:
```
n = 2 * (z_α/2 + z_β)² * σ² / δ²

Where:
- z_α/2 = 1.96 (95% confidence)
- z_β = 0.84 (80% power)
- σ = standard deviation of revenue per signup ≈ $35
- δ = minimum detectable difference = $6.75 (15% of $45)

n = 2 * (1.96 + 0.84)² * 35² / 6.75²
n = 2 * 7.84 * 1225 / 45.56
n = 421.3

Required sample size per group: 422 signups
Total sample size: 844 signups
```

**Estimated Timeline**: 60-90 days
- Current signup rate: ~7-10 new signups/day
- Expected test duration: 844 / 14 = 60 days minimum

### Success Criteria

**Primary Success Metrics**:
1. **Revenue per Signup**: ≥15% increase (p < 0.05)
   - Control: $6.75 revenue/signup
   - Treatment target: ≥$7.76 revenue/signup

2. **Professional Tier Adoption**: ≥18% of paid conversions
   - Expected: 41-46 customers choose $49 tier (out of ~230)

**Secondary Success Metrics**:
3. **Conversion Rate**: No significant decrease (<2%)
4. **Time to Convert**: ≤7 days median
5. **Churn Rate**: ≤10% in first 30 days

**Minimum Viable Success**: Hit primary metric #1 OR (#2 AND #3)

### Rollback Criteria (Automatic Triggers)

**Immediate Rollback if ANY**:
1. MRR decreases >5% vs. control (p < 0.05)
2. Conversion rate drops >10% vs. control (p < 0.05)
3. Churn rate exceeds 25% in first 30 days
4. Customer support tickets increase >50% (pricing confusion)
5. Critical bug in billing system

**Review Rollback if**:
6. After 30 days, revenue per signup <0% change (not meeting 15% target)
7. Professional tier adoption <10% (below model predictions)

### Monitoring Dashboard Requirements

**Real-Time Metrics** (Updated hourly):
- New signups (Control vs. Treatment)
- Conversion rate by cohort
- Revenue per signup
- Tier selection distribution
- Churn events

**Daily Metrics**:
- MRR by cohort
- ARPU by cohort
- Professional tier adoption rate
- Support ticket volume & sentiment
- Payment failure rates

**Weekly Metrics**:
- Cohort retention curves
- LTV projections
- Statistical significance tests
- Cannibalization analysis (which tiers are affected)

### Statistical Analysis Plan

**Primary Analysis**: Welch's t-test (two-sample, unequal variance)
- Compare mean revenue per signup between Control and Treatment
- Report: mean difference, 95% CI, p-value, effect size (Cohen's d)

**Secondary Analyses**:
1. **Chi-square test**: Tier distribution differences
2. **Survival analysis**: Time to churn comparison (Kaplan-Meier curves)
3. **Regression analysis**: Control for covariates (company size, industry, geography)

**Interim Analysis**: After 50% of sample (422 signups)
- Use O'Brien-Fleming spending function (α = 0.005 for interim)
- If p < 0.005, can declare early success
- If clear failure trend, recommend early termination

### Expected Outcomes

**Predicted Results** (from Monte Carlo simulation):
- **Most Likely**: +18% revenue per signup
- **95% CI**: [+12%, +24%]
- **Professional Tier Adoption**: 20-23% of paid users
- **Cannibalization**: 12% from Individual, 3% from Team
- **Net New Revenue**: +$2,200-$2,800 MRR

---

## TEST 2: BUSINESS TIER ($125/MONTH)

### Hypothesis
**H0**: Adding a $125 Business tier will NOT increase MRR
**H1**: Adding a $125 Business tier will increase MRR by ≥18%

### Test Design

**Type**: Sequential rollout (test after Professional tier proven successful)
**Duration**: 90 days minimum (3 billing cycles for B2B)
**Allocation**: 50/50 split for new signups + upgrade offers to existing Team customers

**Control Group (A)**:
- Current pricing ladder (including validated Professional tier)
- $25, $49, $75, $150, $500

**Treatment Group (B)**:
- New pricing ladder: $25, $49, $75, **$125**, $150, $500

**Special Consideration**: Offer upgrade path to existing Team ($75) customers
- Email campaign to 50% of Team customers (randomly selected)
- Highlight SSO, compliance, SLA features

### Sample Size Calculation

**Primary Metric**: Revenue per new enterprise signup + Team upgrades

**Assumptions**:
- Baseline enterprise conversion: 5% (lower than SMB)
- Baseline enterprise ARPU: $150/month
- MDE: 18% increase
- Statistical Power: 80%
- α: 0.05

**Calculation**:
```
n = 2 * (1.96 + 0.84)² * 50² / 27²
n = 2 * 7.84 * 2500 / 729
n = 53.7

Required sample size per group: 54 enterprise signups
Total sample size: 108 enterprise signups
```

**Additional**: 50 Team customer upgrade attempts per cohort

**Estimated Timeline**: 90-120 days
- Enterprise signup rate: ~1-2/day
- Expected test duration: 108 / 2 = 54-108 days

### Success Criteria

**Primary Success Metrics**:
1. **Revenue per Enterprise Signup**: ≥18% increase
   - Control: $7.50 revenue/signup (5% × $150)
   - Treatment target: ≥$8.85 revenue/signup

2. **Business Tier Adoption**: ≥10% of enterprise customers
   - Expected: 18-23 customers at $125

3. **Team Upgrade Rate**: ≥8% of Team customers upgrade to Business
   - Expected: 6-9 upgrades from ~75 Team customers

**Secondary Success Metrics**:
4. **Enterprise Retention**: ≥92% at 90 days
5. **SSO Activation**: ≥60% of Business tier customers enable SSO within 14 days

### Rollback Criteria

**Immediate Rollback if**:
1. Enterprise MRR decreases >7% vs. control
2. Team tier churn increases >15% (due to upgrade pressure)
3. Business tier adoption <5% after 60 days

**Review Rollback if**:
4. After 60 days, no significant revenue increase (p > 0.10)
5. SSO activation rate <30% (indicates poor feature-market fit)

### Expected Outcomes

**Predicted Results**:
- **Revenue Increase**: +22% per enterprise signup
- **95% CI**: [+14%, +30%]
- **Business Tier Adoption**: 10-12% of enterprise segment
- **Team Upgrades**: 8-10% upgrade rate
- **Net New Revenue**: +$2,500-$3,200 MRR

---

## TEST 3: PREMIUM TIER ($275-300/MONTH)

### Hypothesis
**H0**: Adding a $275-300 Premium tier will NOT increase high-end revenue
**H1**: Adding a $275-300 Premium tier will increase revenue from $150+ segment by ≥12%

### Test Design

**Type**: Invitational rollout (hand-selected enterprise accounts)
**Duration**: 120 days (4 billing cycles)
**Allocation**: Targeted outreach, not random

**Control Group (A)**:
- Top 50 Enterprise customers (by usage/revenue potential)
- Offered: Standard upgrade path to Dedicated ($500)

**Treatment Group (B)**:
- Top 50 Enterprise customers (matched by usage/revenue)
- Offered: New Premium tier ($300) with dedicated resources

**Methodology**: Account-based testing, not random allocation
- Match accounts by: API usage, team size, industry, revenue history
- Personal outreach from account managers

### Sample Size Calculation

**Note**: Traditional power calculations don't apply for small, matched samples
**Alternative**: Wilcoxon signed-rank test (non-parametric, paired data)

**Minimum Detectable Effect**:
- Control upgrade rate to Dedicated: 5% (2-3 upgrades out of 50)
- Treatment upgrade rate to Premium: 15% (7-8 upgrades out of 50)
- Difference: 10 percentage points

**Sample Size** (McNemar's test for paired proportions):
```
n = (z_α/2 + z_β)² * (p₁ + p₂) / (p₁ - p₂)²

Where:
- p₁ = 0.15 (treatment upgrade rate)
- p₂ = 0.05 (control upgrade rate)
- α = 0.05, β = 0.20

n = (1.96 + 0.84)² * (0.15 + 0.05) / (0.15 - 0.05)²
n = 7.84 * 0.20 / 0.01
n = 156.8

Required: 157 matched pairs
```

**Adjusted Strategy**: Given limited enterprise pool, use **Bayesian approach**
- Start with prior: P(Premium better) = 50%
- Update posterior after each conversion/rejection
- Decision rule: If P(Premium better) > 85%, declare success

### Success Criteria

**Primary Success Metrics**:
1. **Premium Tier Adoption**: ≥7 customers (14% of outreach)
2. **Revenue from Top Accounts**: +12% vs. control group

**Secondary Success Metrics**:
3. **Account Manager Feedback**: ≥70% positive (solves customer pain points)
4. **Resource Utilization**: Dedicated resources used >60% capacity
5. **Expansion Revenue**: Premium customers increase usage >20% within 90 days

### Rollback Criteria

**Review Rollback if**:
1. After 90 days, <3 Premium customers (6% adoption)
2. Premium customers churn >20%
3. Account managers report consistent pricing objections
4. Resource isolation costs exceed revenue by >40%

**No immediate rollback** - Due to low volume and high touch, allow full 120-day evaluation

### Expected Outcomes

**Predicted Results**:
- **Premium Tier Adoption**: 10-14 customers (20-28% of outreach)
- **Revenue per Account**: +15-20% increase
- **95% Credible Interval (Bayesian)**: [+8%, +25%]
- **Net New Revenue**: +$2,800-$3,600 MRR from high-end expansion

---

## CROSS-TIER CANNIBALIZATION MONITORING

### Cannibalization Metrics

Track weekly for all tests:

**Downgrade Cannibalization**:
- Individual → Free (churn)
- Team → Professional
- Enterprise → Business
- Dedicated → Premium

**Expected vs. Actual**:
| Transition | Expected Rate | Alert Threshold |
|------------|---------------|-----------------|
| Individual → Free | 5% | >10% |
| Team → Professional | 3-5% | >8% |
| Enterprise → Business | 2-3% | >6% |
| Dedicated → Premium | 1-2% | >5% |

**Response Actions**:
1. If alert threshold exceeded: Analyze feature gap
2. Consider feature enhancements to higher tier
3. Grandfather pricing for loyal customers
4. Adjust marketing messaging

---

## MONITORING DASHBOARD SPECIFICATION

### Real-Time Dashboard (Hourly Updates)

**Section 1: Test Status**
- Current test name & days remaining
- Sample size progress: n/target (%)
- Statistical power achieved so far
- P-value (current estimate)

**Section 2: Primary Metrics**
- Revenue per signup (Control vs. Treatment)
- Conversion rate by cohort
- MRR by cohort
- Tier distribution (pie chart)

**Section 3: Alerts**
- Rollback triggers (red if breached)
- Sample ratio mismatch (50/50 check)
- Novelty effect detection (Week 1 vs. Week 2+ behavior)

### Daily Dashboard

**Section 4: Cohort Analysis**
- Signup funnel by cohort
- Time to convert distribution
- Payment method breakdown
- Geographic distribution

**Section 5: Financial Metrics**
- Daily MRR change
- Cumulative revenue difference
- LTV projections (cohort-based)
- Churn rate by tier

**Section 6: Qualitative Signals**
- Support ticket themes (AI sentiment analysis)
- Sales call feedback
- Upgrade request trends
- Pricing page exit rates

### Weekly Dashboard

**Section 7: Statistical Analysis**
- Formal hypothesis test results
- Effect size calculations (Cohen's d)
- Confidence intervals (forest plot)
- Heterogeneous treatment effects (by segment)

**Section 8: Long-Term Trends**
- Retention curves (Kaplan-Meier)
- LTV/CAC ratios by cohort
- Expansion revenue rates
- Net Revenue Retention (NRR)

---

## DECISION FRAMEWORK

### After Test Completion

**If Statistically Significant Success (p < 0.05 AND meets success criteria)**:
1. ✅ Prepare full rollout plan
2. ✅ Update pricing page, documentation, sales materials
3. ✅ Train customer success team
4. ✅ Announce new tier to existing customers
5. ✅ Monitor for 30 days post-rollout

**If Trending Positive But Not Significant (p < 0.15)**:
1. ⏸ Extend test duration by 50%
2. ⏸ Analyze subgroup effects (maybe works for specific segments)
3. ⏸ Consider adjusting price point (e.g., $45 vs. $49)
4. ⏸ Gather qualitative feedback

**If No Effect Or Negative (p > 0.15 OR negative revenue)**:
1. ❌ Rollback test group to control pricing
2. ❌ Conduct post-mortem analysis
3. ❌ Survey treatment group for objections
4. ❌ Revisit feature packaging and value proposition
5. ❌ Consider alternative price points or tier structures

---

## SAMPLE SIZE SUMMARY TABLE

| Test | Metric | Per Group | Total | Duration | Power |
|------|--------|-----------|-------|----------|-------|
| **Professional Tier** | New signups | 422 | 844 | 60-90 days | 80% |
| **Business Tier** | Enterprise signups | 54 | 108 | 90-120 days | 80% |
| **Business Tier** | Team upgrades | 50 | 100 | 90 days | 75% |
| **Premium Tier** | Enterprise accounts | 50 | 100 (matched) | 120 days | Bayesian |

**Total Test Timeline**: 12-18 months for all three tiers (sequential)
- **Months 1-3**: Professional tier test
- **Months 4-7**: Business tier test
- **Months 8-12**: Premium tier test
- **Months 13-18**: Post-rollout monitoring

---

## RISK MITIGATION STRATEGIES

### Customer Communication

**Before Test Launch**:
- Email to existing customers: "No price changes for you" guarantee
- FAQ page: "Why are prices different for new signups?"
- Support team training: Handle "unfair pricing" complaints

**During Test**:
- Transparent blog post: "We're testing new pricing to better serve you"
- Grandfather promise: "Your price locked for 12 months minimum"
- Monitor social media / review sites for backlash

**After Test**:
- Announce results: "Based on customer feedback, we're adding X tier"
- Migration offers: Give existing customers early access with discounts

### Technical Risk Mitigation

**Billing System**:
- Dry-run test with $0 charges (validate flows)
- Stripe webhook monitoring (catch failures)
- Manual billing audit (first 20 customers/cohort)

**Feature Flags**:
- Implement via LaunchDarkly or similar
- Kill switch for instant rollback
- Gradual rollout within treatment group (10% → 50% → 100%)

**Data Quality**:
- A/A test first (both groups see same pricing, validate randomization)
- Sample ratio mismatch detection (should be 50/50 ± 5%)
- Bot detection (filter non-human signups)

---

## APPENDIX: STATISTICAL FORMULAS

### Power Calculation (Two-Sample T-Test)

```python
from scipy import stats
import numpy as np

def calculate_sample_size(baseline_mean, mde_pct, std_dev, alpha=0.05, power=0.80):
    """
    Calculate required sample size for A/B test

    Args:
        baseline_mean: Current metric average
        mde_pct: Minimum detectable effect (percentage)
        std_dev: Standard deviation of metric
        alpha: Significance level (default 0.05)
        power: Statistical power (default 0.80)

    Returns:
        Required sample size per group
    """
    mde = baseline_mean * mde_pct
    z_alpha = stats.norm.ppf(1 - alpha/2)
    z_beta = stats.norm.ppf(power)

    n = 2 * ((z_alpha + z_beta) ** 2) * (std_dev ** 2) / (mde ** 2)
    return int(np.ceil(n))

# Example: Professional Tier Test
n = calculate_sample_size(
    baseline_mean=45,  # ARPU
    mde_pct=0.15,      # 15% increase
    std_dev=35,        # revenue variability
    alpha=0.05,
    power=0.80
)
print(f"Required sample size: {n} per group")
```

### Bayesian A/B Test (Premium Tier)

```python
import pymc3 as pm

def bayesian_ab_test(control_conversions, control_total,
                     treatment_conversions, treatment_total):
    """
    Bayesian A/B test for conversion rate

    Returns probability that treatment is better than control
    """
    with pm.Model() as model:
        # Priors (Beta distribution for conversion rate)
        p_control = pm.Beta('p_control', alpha=1, beta=1)
        p_treatment = pm.Beta('p_treatment', alpha=1, beta=1)

        # Likelihoods
        obs_control = pm.Binomial('obs_control', n=control_total,
                                   p=p_control, observed=control_conversions)
        obs_treatment = pm.Binomial('obs_treatment', n=treatment_total,
                                     p=p_treatment, observed=treatment_conversions)

        # Difference
        delta = pm.Deterministic('delta', p_treatment - p_control)

        # Sample
        trace = pm.sample(2000, return_inferencedata=False)

    # Probability treatment is better
    prob_better = (trace['delta'] > 0).mean()
    return prob_better, trace

# Example: Premium Tier Test after 30 days
prob, trace = bayesian_ab_test(
    control_conversions=2,  # 2 upgrades to Dedicated
    control_total=50,
    treatment_conversions=7,  # 7 upgrades to Premium
    treatment_total=50
)
print(f"Probability Premium tier is better: {prob:.1%}")
```

---

**Document Version**: 1.0
**Date**: November 23, 2025
**Review Cycle**: Monthly during active testing
**Owner**: Product & Data Science Teams
