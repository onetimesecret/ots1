# Executive Summary: SaaS Pricing Strategy

**Date**: January 23, 2025 | **Objective**: 4-tier SaaS pricing transition

---

## RECOMMENDED PRICING

| Tier | Price/Month | Target % | Key Differentiator |
|------|-------------|----------|-------------------|
| **Individual** | **$22** | 60% | Custom domain + branding |
| **Team** | **$75** | 30% | 3-5 accounts, team management |
| **Enterprise** | **$179** | 8% | Unlimited users, SSO, SCIM |
| **Dedicated** | **$649** | 2% | Single-tenant infrastructure |

---

## FINANCIAL PROJECTIONS (95% CI)

| Metric | Month 0 | Month 6 | Month 12 |
|--------|---------|---------|----------|
| **MRR** | $14,678 | $10,290-12,705 | $6,732-9,741 |
| **vs. Current** | +82.4% | +36.7% | -1.4% |
| **vs. No-Change** | +82.4% | +100.3% | +98.9% |
| **Customers** | 230 | 158-161 | 99-122 |

**Break-Even**: 52 days with 20% migration discount

---

## KEY FINDINGS

**1. Competitive Analysis (10 verified competitors)**
- SSO premium: Median $2/user/month (40% increase)
- Individual tier market: $1-4/user/month
- OTS Individual ($22) is 5.5-22x higher, justified by custom domain feature
- Enterprise pricing 3-23x above competitors → **reduced from $249 to $179**

**2. MRR Growth Constraint Issue**
- **Target**: 15-40% increase
- **Reality**: All market-competitive scenarios exceed 40% (82-185% increase)
- **Root cause**: SSO commands 40-300% premium; tiering requires price differentiation
- **Recommendation**: Revise constraint to 60-100% OR phase over 6-12 months

**3. Pricing Failure Risks (Risk Score: 7/10 - High)**
- Netflix (2011): 60% increase → 800K subscribers lost
- Unity (2023): Retroactive fees → CEO resigned, developer exodus
- Adobe (2013): Forced subscription → succeeded due to moat; **OTS lacks this moat**

**4. Validation Challenges**
- Statistical testing requires 8,000-32,000 customers (OTS has 230)
- Recommend: Customer survey + 90-day soft launch + qualitative feedback
- Accept wider confidence intervals due to small sample size

---

## CRITICAL RISKS & MITIGATIONS

| Risk | Impact | Mitigation |
|------|--------|------------|
| Individual tier seen as "forced downgrade" | 25-40% churn | Price below $35, grandfather 12 months |
| Team/Enterprise overpriced vs. market | <15% adoption | Reduced to $75/$179 from $95/$249 |
| Lack of competitive moat | Easy switching | Migration discount, emphasize custom domain |
| "SSO tax" perception | Brand damage | Bundle with compliance features |

---

## IMPLEMENTATION (12-WEEK ROADMAP)

**Weeks 1-4**: Survey 230 customers (validate tier distribution assumption)
**Weeks 5-8**: Pricing page development, pilot with 25 customers
**Weeks 9-12**: Soft launch to 100% new customers, gather data
**Week 13+**: Full migration with 20% discount (3-month limited offer)

**Success Metrics (Month 3)**:
- Migration rate ≥80%
- MRR ≥$13,000
- Churn ≤7.5%
- Tier distribution: Individual 50-70%, Team 20-40%, Enterprise 3-13%

---

## CONTINGENCY PRICING

**If Month 3 MRR <$10K OR Enterprise adoption <3%**:

| Tier | Fallback Price | Change |
|------|---------------|--------|
| Individual | $19 | -14% |
| Team | $59 | -21% |
| Enterprise | $129 | -28% |
| Dedicated | $499 | -23% |

Contingency brings MRR to +43% (closer to 40% target) while maintaining competitiveness.

---

## FINAL RECOMMENDATION

**Adopt Modified Scenario 5** with quarterly reviews. Expected outcomes:
- 82% MRR increase at launch (exceeds 40% constraint)
- 99% improvement vs. no-change trajectory at 12 months
- Lowest churn risk (5/10) of all scenarios
- Break-even in <2 months

**Prerequisites**:
1. ✅ Revise 15-40% constraint to 60-100%
2. ✅ Survey customers to validate assumptions
3. ✅ Prepare contingency pricing if adoption <target

**Documents**: competitor_pricing_matrix.csv | detailed_calculations.md | pricing_failure_case_studies.md | ab_test_methodology.md | migration_scenarios_complete.csv
