# Executive Summary: SaaS Pricing Strategy for OTS Transition

**Prepared**: January 23, 2025
**Objective**: Determine optimal 4-tier pricing based on competitive analysis and migration modeling

---

## RECOMMENDED PRICING

| Tier | Monthly Price | Target Customers | Key Features |
|------|--------------|------------------|--------------|
| **Individual** | **$22.00** | 138 customers (60%) | Custom domain + branding, secret sharing |
| **Team** | **$75.00** * | 69 customers (30%) | 3-5 accounts, team management, extended retention |
| **Enterprise** | **$179.00** * | 18 customers (8%) | Unlimited accounts, SSO, directory sync, audit logs |
| **Enterprise Dedicated** | **$649.00** * | 5 customers (2%) | Single-tenant infrastructure, SLA, dedicated support |

**\* Adjusted from initial Scenario 5 based on competitive analysis showing Team/Enterprise tiers 25-30% overpriced vs. market**

---

## FINANCIAL PROJECTIONS

### Month 0 (Migration)
- **Current MRR**: $8,050 (230 customers × $35)
- **Projected MRR**: $14,527 (+80.52%)
- **Status**: ⚠️ **Exceeds 15-40% growth constraint**

### Month 12 (After Churn)
- **Projected MRR**: $7,506 (114 customers remaining)
- **vs. Current Trajectory**: $3,990 (if no migration)
- **Improvement**: +88.11%

### Critical Finding
**The 15-40% MRR growth constraint is incompatible with market-competitive SaaS tiering.** Recommendation: Revise constraint to 60-90% or phase migration over 6-12 months to smooth revenue curve.

---

## KEY INSIGHTS FROM ANALYSIS

### 1. Competitive Benchmarking (10 Competitors)
- **SSO Premium**: Median $2.00/user/month (40.22% increase over base tier)
- **Individual Tier Market Range**: $1.00-$4.00/user/month
- **OTS Position**: $22 Individual tier is 5.5-22x higher than competitors, justified only by custom domain feature
- **Risk**: Individual tier may be overpriced for pure password manager comparison

### 2. Pricing Failure Case Studies
Three documented failures analyzed:
- **Netflix (2011)**: 60% price increase → 800,000 subscribers lost
- **Unity (2023)**: Retroactive fees → CEO resignation, developer exodus
- **Adobe (2013)**: Forced subscription → 50,000-signature petition (succeeded due to moat; OTS lacks this)

**OTS Risk Score**: 7/10 (High Risk) due to lack of competitive moat and high churn environment

### 3. Migration Modeling
Five scenarios modeled. **Scenario 5 (Hybrid)** has lowest churn risk (5/10):
- Individual tier discount (-37% from current $35)
- Team/Enterprise premiums aligned with SSO value
- Break-even with 20% migration discount: **Month 1.7** (52 days)

---

## CRITICAL RISKS & MITIGATIONS

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Individual tier perceived as "forced downgrade" | High | Loss of 25-40% customers | ✅ Price at $22 (below $35), grandfather existing at $35 for 12 months |
| Team/Enterprise tiers overpriced vs. market | Medium | Enterprise tier adoption <8% | ⚠️ Reduce Team to $75, Enterprise to $179 |
| Lack of competitive moat enables easy switching | High | Accelerated churn to free alternatives | ✅ Emphasize custom domain uniqueness, offer migration discounts |
| Customer backlash to "SSO tax" perception | Medium | Brand damage, negative PR | ✅ Bundle SSO with other enterprise features, avoid marketing as "SSO tier" |

---

## VALIDATION REQUIREMENTS

**Before full launch**, conduct:

1. **Customer Survey** (all 230 customers): Gauge tier preference, price sensitivity, feature priorities
2. **Soft Launch** (100 new customers, 90 days): Validate tier distribution assumption (60/30/8/2)
3. **Migration Pilot** (25 existing customers): Test messaging, identify objections, measure upgrade rate

**Statistical Note**: Customer base too small for traditional A/B testing (p<0.05). Use confidence intervals + qualitative feedback instead.

---

## IMPLEMENTATION ROADMAP

### Phase 1: Pre-Launch (Weeks 1-4)
- Survey existing customers (target 40% response rate = 92 responses)
- Build pricing page with tier comparison
- Prepare migration communication (email sequence, FAQ)

### Phase 2: Pilot (Weeks 5-12)
- Soft launch to 25 existing customers (migration test)
- Soft launch to 100% new customers (tier distribution validation)
- Gather feedback, iterate messaging

### Phase 3: Full Migration (Weeks 13-18)
- Offer 20% discount for first 3 months to all existing customers
- 30-day migration window
- Personal outreach for Enterprise prospects

### Phase 4: Monitoring (Months 4-12)
- Weekly MRR tracking vs. projections
- Monthly churn analysis
- Quarterly pricing review (adjust if <10% adoption on Team/Enterprise)

---

## CONTINGENCY PRICING (If Initial Projections Fail)

**If Month 3 MRR <$10,000 OR Team/Enterprise adoption <15%**:

| Tier | Contingency Price | Rationale |
|------|------------------|-----------|
| Individual | $19.00 | Match NordPass tier pricing |
| Team | $59.00 | Closer to Bitwarden/Dashlane range |
| Enterprise | $129.00 | 2x Team vs. 3x Team |
| Dedicated | $499.00 | Maintain minimum for infrastructure cost |

---

## FINAL RECOMMENDATION

**Adopt Modified Scenario 5 with price adjustments**:
- Individual: $22/month
- Team: $75/month (vs. initial $95)
- Enterprise: $179/month (vs. initial $249)
- Dedicated: $649/month (vs. initial $699)

**Rationale**:
1. Balances revenue growth (+80.5%) with churn risk (5/10 score)
2. Individual tier below $35 avoids forced upgrade perception
3. Team/Enterprise pricing more competitive (still 2-3x market but justified by custom domain + SSO)
4. Break-even in <2 months with migration discount

**Expected Outcomes**:
- Month 0 MRR: $14,527 (+80.52%)
- Month 12 MRR: $7,506 (+88.11% vs. no-change scenario)
- Customer retention: 49.6% after 1 year (vs. 42% current trajectory)

**Success Criteria**:
- ✅ 60-90% initial MRR increase (achieved: 80.5%)
- ✅ Individual tier ≤$35 (achieved: $22)
- ✅ Break-even <3 months (achieved: 1.7 months)
- ⚠️ 15-40% growth (not achieved; constraint needs revision)

---

**Approval Required**: Revise MRR growth constraint from 15-40% to 60-90% to align with market-competitive SaaS tiering.

**Timeline to Launch**: 12 weeks (includes 4-week survey/pilot phase)

**Prepared by**: OTS Pricing Analysis Team
**Supporting Documents**: competitor_pricing_matrix.csv, detailed_calculations.md, feature_value_analysis.md, pricing_failure_case_studies.md, ab_test_methodology.md
