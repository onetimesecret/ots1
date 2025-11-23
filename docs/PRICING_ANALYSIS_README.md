# OneTimeSecret Pricing Analysis Tools

This directory contains comprehensive pricing strategy analysis and simulation tools for migrating OneTimeSecret from a single $35/month plan to a 4-tier pricing structure.

## Contents

### 1. Analysis Documents

- **`pricing_analysis.md`** - Complete pricing strategy report (50+ pages)
  - Market intelligence and competitive analysis
  - Customer segmentation modeling
  - Price elasticity analysis
  - Monte Carlo revenue projections (24 months)
  - Recommended tier structure and pricing
  - Migration strategy and risk analysis

### 2. Simulation Tools

- **`monte_carlo_simulation.py`** - Revenue projection simulator
  - Runs 10,000+ Monte Carlo iterations
  - Models 3 scenarios: conservative, aggressive, pessimistic
  - Projects 24-month cashflow and MRR growth
  - Exports statistical summaries (P10/P50/P90 percentiles)

- **`customer_segmentation_analysis.py`** - Customer migration analyzer
  - Analyzes usage patterns to recommend optimal tier
  - Calculates churn risk for each customer
  - Generates migration recommendations
  - Visualizes tier distribution and revenue impact

## Quick Start

### Prerequisites

```bash
pip install pandas numpy matplotlib seaborn
```

### Run Monte Carlo Simulation

```bash
# Conservative scenario (recommended starting point)
python docs/monte_carlo_simulation.py --scenario conservative --iterations 10000

# Run all scenarios
python docs/monte_carlo_simulation.py --scenario all --iterations 10000

# Quick test (fewer iterations)
python docs/monte_carlo_simulation.py --scenario conservative --iterations 1000
```

**Outputs:**
- `pricing_simulation_conservative_summary.csv` - Statistical summary
- `pricing_simulation_conservative_detailed.csv` - Month-by-month projections

### Analyze Customer Segmentation

```bash
# Generate sample data for testing
python docs/customer_segmentation_analysis.py --generate-sample --visualize

# Analyze real customer data
python docs/customer_segmentation_analysis.py --input customers.csv --output recommendations.csv --visualize
```

**Expected CSV Format:**
```csv
customer_id,active_users,secrets_per_month,api_calls_per_day,needs_sso,needs_compliance,company_size
cust_001,5,150,75,false,false,20
cust_002,1,30,15,false,false,1
```

**Outputs:**
- `migration_recommendations.csv` - Tier recommendations per customer
- `migration_analysis.png` - Visualization charts

## Key Findings Summary

### Recommended Pricing

| Tier | Price | Target Customer | Est. Margin |
|------|-------|----------------|-------------|
| Individual | **$19/month** | Solo developers, hobbyists | 53% |
| Team | **$79/month** | Teams of 2-10 | 77% |
| Enterprise | **$149/month** | Mid-size companies (SSO, compliance) | 76% |
| Single Tenant | **$799/month** | Large enterprises, dedicated infra | 64% |

### Revenue Projections (Conservative Scenario)

**Current State:**
- MRR: $8,050
- Customers: 230
- EBITDA: -$1,430/month (-18% margin)

**Projected Month 12:**
- MRR: $48,161 (6x growth)
- Customers: 339
- EBITDA: $35,677/month (74% margin)

**Projected Month 24:**
- MRR: $66,976 (8.3x growth)
- Customers: 444
- Cumulative cashflow: $843,000

### Expected Customer Migration

| Current Segment | Count | Target Tier | Churn Risk |
|----------------|-------|-------------|------------|
| Solo Developers | 58 (25%) | Individual | Low (5-8%) |
| Small Teams | 104 (45%) | Team | Medium (10-15%) |
| Mid-size Teams | 46 (20%) | Enterprise | Low-Med (6-10%) |
| Enterprise | 23 (10%) | Single Tenant | Very Low (2-5%) |

## Simulation Scenarios Explained

### Conservative (Recommended Baseline)
- 60% overall retention during migration
- 20% upgrade to higher tiers
- 20% downgrade/churn
- Moderate new customer growth (7%/month)
- **Use this for**: Budget planning, investor presentations

### Aggressive (Optimistic Case)
- 75% retention
- 35% upgrade rates
- 10% downgrade/churn
- Higher new customer growth (10%/month)
- **Use this for**: Best-case scenario planning

### Pessimistic (Risk Analysis)
- 45% retention (high churn shock)
- 10% upgrade rates
- 40% downgrade/churn
- Slower growth (5%/month)
- **Use this for**: Contingency planning, stress testing

## Migration Strategy

### Recommended Timeline

**Phase 0: Pre-announcement (4 weeks)**
- Validate customer usage data
- Build migration portal
- Train support team

**Phase 1: Announcement (2 weeks)**
- Email all customers with new tier options
- Launch pricing page
- Begin 3-month grandfathering period

**Phase 2: Grandfathering (3 months)**
- Customers stay at $35/month
- Incentivize early opt-in (1 month free)
- White-glove outreach to Enterprise segment

**Phase 3: Forced Migration (Month 4)**
- Auto-migrate to recommended tier
- 2-week grace period for adjustments

**Phase 4: Post-Migration (Months 4-6)**
- Monitor churn weekly
- Adjust pricing if churn >12%

### Success Metrics (6-Month Targets)

**Must-Achieve:**
- ✅ Total MRR >$32,000 (+300%)
- ✅ Overall churn <6%/month
- ✅ Migration completion >80%

**Fail State (Re-evaluate):**
- 🔴 Total MRR <$20,000
- 🔴 Churn >9%/month
- 🔴 >40% downgrade to Individual tier

## Data Requirements for Production Use

To run accurate analysis on real customer data, export the following from your backend:

### Required Fields
- `customer_id` - Unique identifier
- `active_users` - Number of users per account
- `secrets_per_month` - Total secrets created/shared (last 90 days average)
- `api_calls_per_day` - Average daily API calls
- `needs_sso` - Boolean (true if customer has requested SSO)
- `needs_compliance` - Boolean (true if customer mentioned compliance/audit requirements)
- `company_size` - Approximate number of employees

### Optional Fields (Improve Accuracy)
- `signup_date` - Customer lifetime (longer = lower churn)
- `support_tickets_per_month` - High support needs may indicate Enterprise tier
- `ttl_usage` - Custom TTL usage suggests power user
- `peak_usage_day` - Helps identify seasonal vs consistent usage

### Export Format

```sql
-- Example SQL query to export customer data
SELECT
    customer_id,
    COUNT(DISTINCT user_email) as active_users,
    AVG(monthly_secrets) as secrets_per_month,
    AVG(daily_api_calls) as api_calls_per_day,
    MAX(sso_requested) as needs_sso,
    MAX(compliance_mentioned) as needs_compliance,
    company_size
FROM customers
LEFT JOIN usage_stats USING (customer_id)
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY customer_id;
```

## Interpreting Simulation Results

### Reading P10/P50/P90 Percentiles

**P10 (10th Percentile)** - Pessimistic outcome
- There's a 90% chance results will be BETTER than this
- Use for conservative budgeting

**P50 (Median)** - Most likely outcome
- 50% chance results will be better, 50% worse
- Use for planning targets

**P90 (90th Percentile)** - Optimistic outcome
- Only 10% chance results will be this good
- Use for stretch goals

### Example Interpretation

```
Month 12 MRR:
  P10: $41,100
  P50: $52,300
  P90: $68,900
```

**Translation**:
- You can be 90% confident MRR will exceed $41,000
- Median expectation is $52,000
- Best-case scenario (10% probability) reaches $69,000

## Customizing the Analysis

### Adjust Tier Prices

Edit `monte_carlo_simulation.py`:

```python
self.tiers = {
    'individual': TierConfig(
        price=19.0,  # ← Change this
        price_variance=2.0,  # ± variance for sensitivity
        # ... other params
    ),
    # ... other tiers
}
```

### Modify Customer Segmentation

Edit `customer_segmentation_analysis.py`:

```python
self.tier_criteria = {
    'individual': {
        'max_secrets_per_month': 100,  # ← Adjust limits
        # ... other criteria
    },
    # ... other tiers
}
```

### Change Churn Assumptions

Edit `monte_carlo_simulation.py`:

```python
TierConfig(
    churn_rate_mean=0.08,  # ← Base churn rate (8%)
    churn_rate_std=0.02,   # ← Variance (±2%)
)
```

## Validating Assumptions

### Critical Assumptions to Verify

1. **Customer Segmentation (25/45/20/10 split)** 🔴 HIGH RISK
   - Run: `python customer_segmentation_analysis.py --input real_customers.csv`
   - Compare with actual usage data

2. **Price Elasticity** 🟡 MEDIUM RISK
   - Survey subset of customers
   - A/B test pricing page with different price points

3. **Infrastructure Costs ($200/single-tenant)** 🟢 LOW RISK
   - Get quotes from AWS/GCP
   - Add 20% buffer to cost estimates

## Troubleshooting

### Import Errors

```bash
# If you get "ModuleNotFoundError: No module named 'pandas'"
pip install pandas numpy matplotlib seaborn
```

### Simulation Taking Too Long

```bash
# Reduce iterations for faster results
python docs/monte_carlo_simulation.py --iterations 1000  # Instead of 10000
```

### Visualization Not Generating

```bash
# Install matplotlib with GUI backend
pip install matplotlib --upgrade

# Or run without visualization
python docs/customer_segmentation_analysis.py --generate-sample  # Remove --visualize
```

## Next Steps

1. **Week 1-2**: Validate assumptions
   - Export actual customer usage data
   - Run segmentation analysis
   - Survey customer needs (SSO, compliance)

2. **Week 3-4**: Build migration infrastructure
   - Implement tier-based billing
   - Create migration portal
   - Design pricing page

3. **Week 5-6**: Test & launch
   - Beta test with 10-20 friendly customers
   - Announce to full customer base
   - Begin grandfathering period

## Questions?

For questions about the analysis methodology, see Appendix A in `pricing_analysis.md`.

For questions about implementation, contact the product/engineering team.

---

**Document Version**: 1.0
**Last Updated**: 2025-11-23
**Maintained By**: OneTimeSecret Team
