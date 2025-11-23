# Risk Assessment & Mitigation Framework

## Risk Scoring Methodology

### Risk Score Formula

```
Risk Score = (Probability × Impact × Exposure) / Mitigation Effectiveness

Where:
- Probability: 1-5 (1=rare, 5=almost certain)
- Impact: 1-5 (1=negligible, 5=catastrophic)
- Exposure: % of ARR affected
- Mitigation: 0.1-1.0 (0.1=90% mitigated, 1.0=no mitigation)

Risk Level:
- CRITICAL: Score >15
- HIGH: Score 10-15
- MEDIUM: Score 5-10
- LOW: Score <5
```

---

## Strategic Risks

### RISK-001: Revenue Concentration in Strategic Tier

**Category**: Revenue Risk
**Probability**: 3/5 (Moderate—inherent to SaaS model)
**Impact**: 5/5 (Catastrophic—Strategic tier= 2.6% of ARR but highest ARPU)
**Exposure**: 2.6% of customer base, concentrated revenue
**Current Mitigation**: Limited (no dedicated strategy)
**Risk Score**: 3 × 5 × 0.026 / 0.3 = **1.3** (LOW but needs monitoring)

**Description**:
Over-reliance on small number of Strategic tier customers creates revenue volatility. Loss of 1-2 accounts has outsized impact.

**Impact if Realized**:
- Loss of 1 Strategic customer (S05): -$17,940 ARR (-0.027% total)
- Loss of top 10 Strategic customers: -$1.7M ARR (-2.6% total)
- Churn spike in Strategic tier: Material impact on growth trajectory

**Mitigation Strategies**:

1. **Diversification** (Priority: HIGH)
   - **Action**: Increase Enterprise tier acquisition (target: 15% of ARR by Year 2)
   - **Timeline**: 12 months
   - **Owner**: VP Sales
   - **Budget**: $500K (sales hiring, enterprise marketing)
   - **KPI**: Enterprise tier ARR >$10M

2. **Customer Success Program** (Priority: CRITICAL)
   - **Action**: Dedicated CSM for all Strategic accounts
   - **Timeline**: Immediate (30 days)
   - **Owner**: Head of Customer Success
   - **Budget**: $300K/year (2 CSMs @ $150K each)
   - **KPI**: Strategic tier churn <2%, NRR >110%

3. **Annual Contracts** (Priority: MEDIUM)
   - **Action**: Require 12-month minimum for Strategic tier
   - **Timeline**: 60 days (contract template updates)
   - **Owner**: Legal + Sales
   - **Budget**: $20K (legal review)
   - **KPI**: 100% of Strategic on annual+ contracts

**Residual Risk**: 3 × 5 × 0.026 / 0.7 = **0.56** (LOW)

---

### RISK-002: Economic Downturn (Bear Market Scenario)

**Category**: Market Risk
**Probability**: 2/5 (Unlikely in next 12 months, possible in 24)
**Impact**: 5/5 (Catastrophic—36% ARR decline modeled)
**Exposure**: 100% of ARR
**Current Mitigation**: Moderate (diversified segments, but WTP-sensitive)
**Risk Score**: 2 × 5 × 1.0 / 0.5 = **20** (CRITICAL)

**Description**:
Macroeconomic recession triggers -20% WTP decrease, +30% elasticity, +5pp churn across all segments. Model shows -$24M ARR impact ($66.9M → $42.8M).

**Impact if Realized**:
- Total ARR: -36% ($24M decline)
- Customer count: -13% (26,422 customers lost)
- Weighted churn: +5pp (9.2% → 14.2%)
- High-value segments hit hardest (S05: -39%, S10: -40%)

**Mitigation Strategies**:

1. **Portfolio Rebalancing** (Priority: CRITICAL)
   - **Action**: Increase low-volatility segment mix (Starter/Pro tiers)
   - **Timeline**: 6-12 months
   - **Owner**: CMO
   - **Budget**: $1M (shift marketing spend)
   - **KPI**: Starter+Pro = 60% of customers (vs 51% today)

2. **Annual Prepay Incentives** (Priority: HIGH)
   - **Action**: Offer 20% discount for 12-month prepay (vs 15% today)
   - **Timeline**: Immediate
   - **Owner**: CFO + Sales
   - **Budget**: Revenue trade-off ($2M discount for $10M cash)
   - **KPI**: 50% of ARR on annual prepay (vs 30% today)

3. **Downgrade Paths** (Priority: HIGH)
   - **Action**: Build tier downgrade flows (prevent churn)
   - **Timeline**: 90 days (product development)
   - **Owner**: Product
   - **Budget**: $100K (engineering)
   - **KPI**: Churn reduction of 2pp = $1.3M ARR saved

4. **Cost Structure Flex** (Priority: MEDIUM)
   - **Action**: Variable cost contracts (cloud, support)
   - **Timeline**: 6 months (renegotiate contracts)
   - **Owner**: COO
   - **Budget**: Neutral (better terms)
   - **KPI**: 60% of costs variable (vs 40% today)

**Residual Risk**: 2 × 5 × 1.0 / 0.7 = **14.3** (HIGH but manageable)

---

### RISK-003: Competitive Price War

**Category**: Competitive Risk
**Probability**: 3/5 (Moderate—Comp A could drop prices further)
**Impact**: 4/5 (Major—forces matching price cuts or lose volume)
**Exposure**: 51% of customer base (Starter/Pro tiers competing with Comp A)
**Current Mitigation**: Moderate (feature differentiation, but price-sensitive segments)
**Risk Score**: 3 × 4 × 0.51 / 0.5 = **12.2** (HIGH)

**Description**:
Competitor A (budget provider) drops prices 30-40% to gain market share, forcing us to match or lose price-sensitive segments (S16, S21, S36, S46, S47).

**Impact if Realized**:
- Price cuts of 20-30% on Starter/Pro tiers = -$4M ARR
- Customer churn to Comp A in elastic segments = -$2M ARR
- Total exposure: -$6M ARR (-9% of total)

**Mitigation Strategies**:

1. **Feature Differentiation** (Priority: CRITICAL)
   - **Action**: Widen gap vs Comp A (custom domains, better support, compliance)
   - **Timeline**: 3-6 months (product roadmap)
   - **Owner**: Product + Engineering
   - **Budget**: $500K (R&D investment)
   - **KPI**: 3× feature advantage in customer surveys

2. **Value-Based Pricing** (Priority: HIGH)
   - **Action**: Justify premium with ROI calculators, case studies
   - **Timeline**: 60 days (marketing collateral)
   - **Owner**: Marketing
   - **Budget**: $100K (content production)
   - **KPI**: 80% of lost deals cite "features" not "price"

3. **Selective Price Matching** (Priority: MEDIUM)
   - **Action**: Match Comp A only for high-volume, high-churn segments (S46, S47)
   - **Timeline**: Immediate (promotional pricing)
   - **Owner**: Pricing Committee
   - **Budget**: -$500K ARR (revenue give-up)
   - **KPI**: Churn reduction >2pp in targeted segments

4. **Annual Lock-In** (Priority: HIGH)
   - **Action**: 15-20% discounts for annual prepay (prevents mid-year churn to Comp A)
   - **Timeline**: Immediate
   - **Owner**: Sales + Finance
   - **Budget**: Revenue acceleration trade-off
   - **KPI**: 40% of at-risk segments on annual contracts

**Residual Risk**: 3 × 4 × 0.51 / 0.7 = **8.7** (MEDIUM)

---

## Operational Risks

### RISK-004: Pricing Execution Errors

**Category**: Operational Risk
**Probability**: 4/5 (Likely—50 segments × 5 tiers = 250 price points)
**Impact**: 3/5 (Moderate—incorrect pricing causes revenue leak or lost deals)
**Exposure**: Varies by segment
**Current Mitigation**: Low (manual pricing, no automation)
**Risk Score**: 4 × 3 × 0.15 / 0.2 = **9.0** (MEDIUM)

**Description**:
Complex pricing matrix (50 segments, 5 tiers, dynamic adjustments) creates risk of:
- Sales quoting wrong prices
- Website displaying outdated pricing
- Discount stacking errors
- Regional pricing mistakes

**Impact if Realized**:
- Revenue leakage: $500K-$1M annually (1.5% of ARR)
- Customer dissatisfaction (billing disputes)
- Competitive disadvantage (too high or too low)

**Mitigation Strategies**:

1. **CPQ Implementation** (Priority: CRITICAL)
   - **Action**: Deploy Configure-Price-Quote system (e.g., Salesforce CPQ)
   - **Timeline**: 6 months
   - **Owner**: Sales Ops + IT
   - **Budget**: $200K (software + implementation)
   - **KPI**: 0 manual pricing errors

2. **Pricing Approval Workflows** (Priority: HIGH)
   - **Action**: Require manager approval for >10% discounts
   - **Timeline**: 30 days (process documentation)
   - **Owner**: Sales Leadership
   - **Budget**: $0 (policy change)
   - **KPI**: 100% discount justification documented

3. **Automated Price Testing** (Priority: MEDIUM)
   - **Action**: Weekly audits of website vs CRM pricing
   - **Timeline**: 60 days (QA automation)
   - **Owner**: Engineering
   - **Budget**: $50K (test automation)
   - **KPI**: Pricing discrepancies detected within 24 hours

**Residual Risk**: 4 × 3 × 0.15 / 0.8 = **2.25** (LOW)

---

### RISK-005: Segment Misclassification

**Category**: Data/Analytics Risk
**Probability**: 3/5 (Moderate—customer self-reports industry/size)
**Impact**: 3/5 (Moderate—wrong pricing leaves money on table)
**Exposure**: 20% of customers (estimated mis-segment)
**Current Mitigation**: Low (no validation of customer segment)
**Risk Score**: 3 × 3 × 0.20 / 0.2 = **9.0** (MEDIUM)

**Description**:
Customers misclassify themselves (or game the system) to access lower-priced tiers. Example: Enterprise customer selects "Small Business" segment to pay $49/user vs $119/user.

**Impact if Realized**:
- Revenue loss: $1-2M annually (customers in wrong tier)
- Pricing integrity erosion (word spreads about loophole)

**Mitigation Strategies**:

1. **Data Enrichment** (Priority: HIGH)
   - **Action**: Use Clearbit/ZoomInfo to verify company size/industry
   - **Timeline**: 90 days (integration)
   - **Owner**: Data/Analytics
   - **Budget**: $50K/year (data subscriptions)
   - **KPI**: 95% segment accuracy

2. **Usage-Based Tier Enforcement** (Priority: CRITICAL)
   - **Action**: Auto-upgrade if usage exceeds tier limits (e.g., 51+ users = Enterprise)
   - **Timeline**: 6 months (product feature)
   - **Owner**: Engineering
   - **Budget**: $100K (development)
   - **KPI**: 0 tier abuse cases

3. **Audit & Compliance** (Priority: MEDIUM)
   - **Action**: Quarterly review of top 100 customers for tier appropriateness
   - **Timeline**: Immediate (manual process)
   - **Owner**: Finance
   - **Budget**: $20K/year (analyst time)
   - **KPI**: Recover $200K+ ARR annually from tier corrections

**Residual Risk**: 3 × 3 × 0.20 / 0.7 = **3.86** (LOW)

---

## Product/Market Risks

### RISK-006: Feature Parity Collapse (Competitors Catch Up)

**Category**: Product Risk
**Probability**: 3/5 (Moderate—typical SaaS feature convergence)
**Impact**: 4/5 (Major—undermines premium pricing justification)
**Exposure**: 30% of ARR (mid-tier customers most at risk)
**Current Mitigation**: Moderate (product roadmap, but not competitor-focused)
**Risk Score**: 3 × 4 × 0.30 / 0.5 = **7.2** (MEDIUM)

**Description**:
Comp A adds enterprise features (SSO, audit logs) OR Comp C improves managed cloud offering, eroding our differentiation.

**Impact if Realized**:
- Churn to lower-cost alternatives: -$3-5M ARR
- Forced price cuts to remain competitive: -10-15% pricing power
- Win rate decline in competitive deals: 60% → 40%

**Mitigation Strategies**:

1. **Accelerated Roadmap** (Priority: CRITICAL)
   - **Action**: Ship 2-3 "moat" features per quarter (competitors can't easily copy)
   - **Examples**: AI-powered security insights, blockchain immutability, quantum-safe encryption
   - **Timeline**: Ongoing (continuous)
   - **Owner**: CTO
   - **Budget**: $2M/year (R&D)
   - **KPI**: 12-month feature lead vs competitors

2. **Platform Lock-In** (Priority: HIGH)
   - **Action**: Deep integrations with Salesforce, Slack, AWS (switching cost)
   - **Timeline**: 12 months
   - **Owner**: Product + Partnerships
   - **Budget**: $500K (integration development)
   - **KPI**: 50% of customers use 3+ integrations (high stickiness)

3. **Customer Advisory Board** (Priority: MEDIUM)
   - **Action**: 20 customers co-develop roadmap (aligned to their needs, not Comp's)
   - **Timeline**: 90 days (first meeting)
   - **Owner**: Product
   - **Budget**: $100K/year (travel, events)
   - **KPI**: 90% of CAB members renew annually

**Residual Risk**: 3 × 4 × 0.30 / 0.75 = **4.8** (LOW-MEDIUM)

---

## Financial Risks

### RISK-007: Payment Failures & Involuntary Churn

**Category**: Financial Risk
**Probability**: 4/5 (Likely—typical 2-5% of SaaS customers)
**Impact**: 2/5 (Minor—recoverable with dunning)
**Exposure**: 3% of ARR (estimated payment failures)
**Current Mitigation**: Moderate (basic dunning emails)
**Risk Score**: 4 × 2 × 0.03 / 0.5 = **0.48** (LOW)

**Description**:
Credit card expirations, insufficient funds, fraud blocks cause involuntary churn. Estimated 3% of ARR at risk annually.

**Impact if Realized**:
- Involuntary churn: $2M ARR lost unnecessarily
- Customer dissatisfaction (service interruption)

**Mitigation Strategies**:

1. **Advanced Dunning** (Priority: HIGH)
   - **Action**: 7-email sequence, SMS alerts, auto-retry with backoff
   - **Timeline**: 60 days (Stripe/payment provider integration)
   - **Owner**: Engineering + Finance
   - **Budget**: $30K (implementation)
   - **KPI**: Recover 70% of failed payments (vs 40% today)

2. **Payment Method Diversity** (Priority: MEDIUM)
   - **Action**: Accept ACH, wire transfer, PayPal (not just credit cards)
   - **Timeline**: 90 days
   - **Owner**: Finance
   - **Budget**: $20K (integration)
   - **KPI**: 20% of Enterprise+ on non-card payment (lower failure rate)

**Residual Risk**: 4 × 2 × 0.03 / 0.8 = **0.30** (LOW)

---

### RISK-008: Foreign Exchange Volatility

**Category**: Financial Risk
**Probability**: 4/5 (Likely—currency fluctuations are constant)
**Impact**: 3/5 (Moderate—10-20% FX swings possible)
**Exposure**: 30% of ARR (estimated international revenue)
**Current Mitigation**: Low (no hedging, bill in USD only)
**Risk Score**: 4 × 3 × 0.30 / 0.2 = **18.0** (CRITICAL for global expansion)

**Description**:
USD strengthening vs EUR/GBP makes pricing uncompetitive in international markets. Customers face 10-20% effective price increases.

**Impact if Realized**:
- International customer churn: -$3-5M ARR
- Price competitiveness erosion in EU/APAC
- Win rate decline in non-USD markets

**Mitigation Strategies**:

1. **Multi-Currency Pricing** (Priority: CRITICAL)
   - **Action**: Bill in EUR, GBP, AUD, SGD for local customers
   - **Timeline**: 6 months (Stripe multi-currency setup)
   - **Owner**: Finance + Engineering
   - **Budget**: $100K (implementation + FX fees)
   - **KPI**: 80% of international customers on local currency

2. **FX Hedging** (Priority: HIGH for >$10M international ARR)
   - **Action**: Forward contracts to lock in rates 12 months out
   - **Timeline**: When international ARR >$10M
   - **Owner**: CFO
   - **Budget**: 1-2% of hedged amount (hedging costs)
   - **KPI**: FX volatility <5% impact on annual revenue

3. **Localized Pricing** (Priority: MEDIUM)
   - **Action**: Adjust prices by PPP (purchasing power parity) for developing markets
   - **Timeline**: 12 months (pricing analysis required)
   - **Owner**: Pricing Committee
   - **Budget**: $50K (consulting)
   - **KPI**: Competitive parity in top 10 international markets

**Residual Risk**: 4 × 3 × 0.30 / 0.7 = **5.14** (MEDIUM)

---

## Compliance & Regulatory Risks

### RISK-009: Pricing Discrimination / Antitrust

**Category**: Legal/Regulatory Risk
**Probability**: 1/5 (Rare—requires intentional discriminatory pricing)
**Impact**: 5/5 (Catastrophic—fines, lawsuits, reputation damage)
**Exposure**: 100% of pricing strategy
**Current Mitigation**: Moderate (segment-based pricing is legal, but needs documentation)
**Risk Score**: 1 × 5 × 1.0 / 0.5 = **10.0** (HIGH due to severity)

**Description**:
Segment-based pricing could be challenged as discriminatory if:
- Pricing differences aren't justified by cost/value
- Customers in same situation get different prices
- Appears to target protected classes

**Impact if Realized**:
- Regulatory investigation (FTC, EU Commission)
- Class-action lawsuit (overcharged customers)
- Forced pricing standardization (eliminates segmentation value)
- Reputation damage

**Mitigation Strategies**:

1. **Legal Review** (Priority: CRITICAL)
   - **Action**: Antitrust counsel review of pricing strategy
   - **Timeline**: Immediate (before launch)
   - **Owner**: General Counsel
   - **Budget**: $50K (external counsel)
   - **KPI**: Written legal opinion confirming compliance

2. **Cost-Based Justification** (Priority: HIGH)
   - **Action**: Document COGS/CAC differences by segment (justify price gaps)
   - **Timeline**: 60 days
   - **Owner**: Finance
   - **Budget**: $20K (internal analysis)
   - **KPI**: Price variance explained by ≥50% cost variance

3. **Transparent Pricing Logic** (Priority: MEDIUM)
   - **Action**: Publish pricing methodology (segment criteria public)
   - **Timeline**: 90 days
   - **Owner**: Legal + Marketing
   - **Budget**: $10K (content)
   - **KPI**: 0 discrimination complaints

**Residual Risk**: 1 × 5 × 1.0 / 0.9 = **5.56** (MEDIUM)

---

## Risk Portfolio Summary

### Risk Heat Map

```
IMPACT
  5 │   [R-009]        [R-002]
    │
  4 │   [R-003]        [R-006]
    │
  3 │   [R-004]        [R-008]
    │   [R-005]
  2 │                  [R-007]
    │
  1 │   [R-001]
    └─────────────────────────── PROBABILITY
      1    2    3    4    5

R-001: Revenue Concentration
R-002: Economic Downturn (Bear Market)
R-003: Competitive Price War
R-004: Pricing Execution Errors
R-005: Segment Misclassification
R-006: Feature Parity Collapse
R-007: Payment Failures
R-008: FX Volatility
R-009: Pricing Discrimination
```

### Risk Priority Ranking (by Risk Score)

| Rank | Risk ID | Description | Score | Priority | Budget |
|------|---------|-------------|-------|----------|--------|
| 1 | R-002 | Economic Downturn | 20.0 | CRITICAL | $1.1M |
| 2 | R-008 | FX Volatility | 18.0 | CRITICAL | $150K |
| 3 | R-003 | Price War | 12.2 | HIGH | $1.1M |
| 4 | R-009 | Antitrust | 10.0 | HIGH | $80K |
| 5 | R-004 | Execution Errors | 9.0 | MEDIUM | $250K |
| 5 | R-005 | Mis-segment | 9.0 | MEDIUM | $170K |
| 7 | R-006 | Feature Parity | 7.2 | MEDIUM | $2.6M |
| 8 | R-001 | Concentration | 1.3 | LOW | $820K |
| 9 | R-007 | Payment Fail | 0.48 | LOW | $50K |

**Total Mitigation Budget**: $6.32M over 12 months

### Mitigation ROI Analysis

| Risk ID | Mitigation Cost | Expected ARR Protected | ROI |
|---------|-----------------|------------------------|-----|
| R-002 | $1.1M | $24M (bear scenario) | 21.8× |
| R-003 | $1.1M | $6M (price war) | 5.5× |
| R-006 | $2.6M | $5M (churn prevention) | 1.9× |
| R-008 | $150K | $4M (FX losses) | 26.7× |
| R-004 | $250K | $1M (revenue leakage) | 4.0× |
| R-001 | $820K | $1.7M (strategic churn) | 2.1× |

**Portfolio Mitigation ROI**: 8.5× ($54M ARR protected / $6.32M invested)

---

## Risk Monitoring Dashboard

### Key Risk Indicators (KRIs)

| KRI | Threshold | Alert Level | Review Frequency |
|-----|-----------|-------------|------------------|
| Strategic tier churn | >3% | RED | Monthly |
| Economic indicators (GDP, unemployment) | Bear signals | YELLOW | Weekly |
| Competitive pricing changes | >10% | YELLOW | Weekly |
| Pricing error rate | >1% of quotes | RED | Weekly |
| Segment classification accuracy | <90% | YELLOW | Monthly |
| Feature parity gap | <6 months lead | RED | Quarterly |
| Payment failure recovery rate | <60% | YELLOW | Monthly |
| FX impact on revenue | >5% | YELLOW | Monthly |

### Quarterly Risk Review Agenda

1. **Risk Score Recalculation** (update probabilities based on actual events)
2. **Mitigation Effectiveness Review** (did strategies work?)
3. **Emerging Risk Identification** (new threats?)
4. **Budget Reallocation** (shift $ from over-mitigated to under-mitigated)
5. **Executive Summary** (top 3 risks + actions)

---

**Risk Framework Version**: 1.0
**Total Risks Identified**: 9 (strategic, operational, product, financial, compliance)
**Critical Risks**: 2 (R-002 Economic Downturn, R-008 FX Volatility)
**Total ARR at Risk**: $54M (81% of base case ARR)
**Mitigation Budget**: $6.32M (9.5% of ARR)
**Residual Risk**: $12M (18% of ARR after mitigation)
**Recommended Review**: Quarterly risk committee + monthly KRI dashboard
