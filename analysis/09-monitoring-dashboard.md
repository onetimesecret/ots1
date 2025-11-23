# Monitoring Dashboard & Alert System Specifications

## Dashboard Architecture

### Technology Stack

**Visualization Layer**: Looker / Tableau / Power BI
**Data Warehouse**: Snowflake / BigQuery
**Real-Time Streaming**: Kafka / Kinesis
**Alert Engine**: PagerDuty / Opsgenie
**Data Pipelines**: Airbyte / Fivetran
**Business Intelligence**: dbt (data transformations)

---

## Executive Dashboard (C-Suite View)

### Layout: Single-Page Overview

#### Top Row: North Star Metrics

| Metric | Current | vs Target | vs Last Quarter | Trend (12mo) |
|--------|---------|-----------|-----------------|--------------|
| **ARR** | $68.4M | ↑ 2.3% | ↑ 24% | ████████░░ |
| **Customer Count** | 203,817 | ↑ 1.2% | ↑ 18% | ███████░░░ |
| **ARPU** | $336 | ↑ 1.0% | ↑ 5% | ████░░░░░░ |
| **Net Revenue Retention** | 89% | ↓ 1pp below | ↑ 4pp | ██████░░░░ |
| **LTV:CAC** | 5.8× | ↑ on track | ↑ 0.3× | ████████░░ |

#### Middle Row: Revenue Breakdown

**Revenue by Tier** (Pie Chart):
- Strategic: 2.6% ($1.7M) [Red]
- Enterprise: 10.6% ($7.1M) [Orange]
- Team: 36.2% ($24.2M) [Blue]
- Professional: 29.9% ($20.0M) [Green]
- Starter: 20.7% ($13.8M) [Gray]

**Revenue by Segment Category** (Stacked Bar):
- Technology: $18.5M (27%)
- Financial Services: $12.3M (18%)
- Professional Services: $10.2M (15%)
- E-commerce: $9.8M (14%)
- SMB General: $8.9M (13%)
- Healthcare: $4.8M (7%)
- Other: $3.9M (6%)

#### Bottom Row: Health Indicators

**Churn by Tier** (Line Chart, 12-month trend):
```
Churn %
15% │                   Starter
    │              ╱────────────
12% │         ╱───╯
    │    ╱───╯         Professional
9%  │╱──╯         ╱────────────
    │         ╱───╯
6%  │    ╱───╯         Team
    │╱──╯         ╱────────────
3%  │         ╱───╯   Enterprise
    │    ╱───╯    Strategic ───
0%  └─────────────────────────────
    Jan  Mar  May  Jul  Sep  Nov
```

**Win Rate by Competitor** (Horizontal Bar):
- vs Comp A: ████████░░ 80% (↑5pp)
- vs Comp B: ██████░░░░ 60% (↑2pp)
- vs Comp C: █████░░░░░ 50% (↓3pp)

**Magic Number** (Gauge):
```
    ╭────────────╮
    │     3.2    │  [GREEN]
    │   ↑ 0.5    │
    ╰────────────╯
   0  1  2  3  4  5
  Bad    Good   Great
```

### Alerts (Executive Level)

| Alert | Threshold | Notification | Recipients |
|-------|-----------|--------------|------------|
| ARR decline QoQ | <0% growth | Slack + Email | CEO, CFO, Board |
| NRR drops | <95% | Email | CEO, CRO, CS Lead |
| Churn spike | +3pp vs avg | Email + Slack | CEO, CS Lead |
| LTV:CAC deterioration | <4× | Email | CFO, CMO, CRO |
| Win rate drop | <50% vs any competitor | Slack | CEO, CRO |

---

## Pricing Operations Dashboard

### Layout: Multi-Tab Interface

#### Tab 1: Segment Performance

**Table View: All 50 Segments**

| Segment | Tier | Customers | ARR | ARPU | Churn | NRR | vs Model | Actions |
|---------|------|-----------|-----|------|-------|-----|----------|---------|
| S05 | Strategic | 155 | $556K | $3,588 | 3% | 97% | ✓ On track | Monitor |
| S10 | Strategic | 97 | $581K | $5,988 | 2% | 98% | ✓ On track | Monitor |
| S23 | Team | 3,847 | $2.26M | $588 | 10% | 87% | ⚠ -2pp NRR | Price test |
| S36 | Starter | 15,652 | $1.69M | $108 | 12% | 88% | ✓ On track | Monitor |
| S46 | Starter | 29,543 | $3.19M | $108 | 22% | 78% | 🔴 High churn | Review ROI |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |

**Filters**: Tier, Industry, Size, Performance (on/off track)
**Sort**: By ARR, Churn, NRR, Variance from Model
**Export**: CSV, PDF

#### Tab 2: Price Optimization Opportunities

**Ranked List: Segments with Headroom**

| Segment | Current Price | Optimal Price | Revenue Gain | Confidence | Status |
|---------|---------------|---------------|--------------|------------|--------|
| S05 | $299 | $329 | +$34K ARR | 85% | ✓ Approved |
| S23 | $49 | $44 | +$109K ARR | 78% | 🟡 Testing |
| S10 | $499 | $549 | +$58K ARR | 72% | 📋 Proposed |
| S18 | $39 | $42 | +$168K ARR | 65% | 📋 Proposed |

**Actions**: Approve test, Launch immediately, Reject, Request more data

#### Tab 3: Competitive Pricing Monitor

**Table: Competitor Price Changes (Last 90 Days)**

| Date | Competitor | Tier | Old Price | New Price | Change | Our Response |
|------|------------|------|-----------|-----------|--------|--------------|
| 2025-11-15 | Comp A | Pro | $25 | $22 | -12% | ✓ Hold (feature gap) |
| 2025-11-01 | Comp B | Enterprise | $300 | $275 | -8% | 🟡 Under review |
| 2025-10-20 | Comp C | Cloud Team | $80 | $75 | -6% | ✓ Hold (managed premium) |

**Alert Rule**: Email when competitor changes price >10%

#### Tab 4: Elasticity Tracking

**Chart: Conversion Rate by Price Point (A/B Tests)**

Segment S23 - Team Tier:
```
Conversion %
8% │         $44
   │        ╱ ╲
7% │       ╱   ╲
   │      ╱     ╲
6% │   $39       $49 (current)
   │   ╱           ╲
5% │  ╱             ╲
   │ ╱               ╲
4% │                  $54
   └────────────────────────
   $35  $40  $45  $50  $55

Optimal: $44 (7.8% conversion, 4,490 customers, $2.37M ARR)
Current: $49 (6.5% conversion, 3,847 customers, $2.26M ARR)
Opportunity: +$109K ARR
```

**Actions**: Launch $44 pricing, Run additional test, Hold at $49

### Alerts (Pricing Team)

| Alert | Threshold | Notification | Recipients |
|-------|-----------|--------------|------------|
| Conversion rate drop | >15% vs baseline | Slack | Pricing Committee |
| Price elasticity shift | ±0.3 change | Email | Head of Pricing |
| Segment underperformance | >10% below model | Email | Segment Owner |
| Competitor price change | >10% | Slack + Email | Pricing Committee |
| ARR variance | ±5% vs forecast | Email | CFO, Pricing Lead |

---

## Customer Success Dashboard

### Layout: Three-Column View

#### Left Column: Health Scores

**Customer Health Distribution**

```
Healthy (80-100):    ██████████████░░░░░░ 70% (42,100 customers)
At Risk (50-79):     █████░░░░░░░░░░░░░░░ 22% (13,230 customers)
Critical (<50):      ██░░░░░░░░░░░░░░░░░░  8% (4,810 customers)

Health Score Factors:
- Product usage (40% weight)
- Feature adoption (20%)
- Support ticket volume (15%)
- Payment history (15%)
- Engagement (NPS, QBR attendance) (10%)
```

**At-Risk Customer List** (Top 50):

| Customer | Segment | Tier | ARR | Health | Primary Risk | Owner | Action |
|----------|---------|------|-----|--------|--------------|-------|--------|
| Acme Corp | S09 | Enterprise | $140K | 45 | Low usage | Jane D. | Call scheduled |
| TechStart | S02 | Team | $12K | 38 | Support issues | Mike R. | Escalated |
| ... | ... | ... | ... | ... | ... | ... | ... |

#### Middle Column: Churn Analysis

**Churn Reasons** (Last Quarter):

```
Price too high:           ████████░░ 35% (820 customers)
Switched to competitor:   ██████░░░░ 28% (656 customers)
Product fit:              ████░░░░░░ 18% (422 customers)
Went out of business:     ███░░░░░░░ 12% (281 customers)
Other/Unknown:            ██░░░░░░░░  7% (164 customers)
```

**Churn by Cohort**:

| Cohort | Customers at Start | Churned | Churn Rate | Target | Status |
|--------|-------------------|---------|------------|--------|--------|
| Q1 2024 | 12,450 | 1,120 | 9.0% | <10% | ✓ Green |
| Q2 2024 | 15,680 | 1,882 | 12.0% | <10% | 🔴 Red |
| Q3 2024 | 18,920 | 1,703 | 9.0% | <10% | ✓ Green |
| Q4 2024 | 22,150 | 2,215 | 10.0% | <10% | 🟡 Yellow |

#### Right Column: Expansion Opportunities

**Upsell Pipeline**:

| Customer | Current Tier | Target Tier | ARR Expansion | Probability | Owner |
|----------|--------------|-------------|---------------|-------------|-------|
| Widget Co | Team ($8.4K) | Enterprise | +$50K | 75% | Sarah L. |
| DataCorp | Pro ($468) | Team | +$12K | 60% | Tom K. |
| ... | ... | ... | ... | ... | ... |

**Total Pipeline**: $2.4M expansion ARR (weighted: $1.6M)

**Seat Expansion Tracking**:

```
Customers by % of Licenses Used:
100%+ (over limit):      ████░░ 15% → Auto-upgrade trigger
90-99%:                  ████░░ 18% → Proactive outreach
75-89%:                  █████░ 22% → Monitor
50-74%:                  █████░ 25% → Healthy
<50%:                    █████░ 20% → Underutilized (churn risk)
```

### Alerts (Customer Success Team)

| Alert | Threshold | Notification | Recipients |
|-------|-----------|--------------|------------|
| Enterprise customer at risk | Health <60 | PagerDuty | Dedicated CSM + VP CS |
| Churn spike | >2pp above target | Slack | Head of CS |
| Seat expansion opportunity | Usage >90% | Email | Account owner |
| Payment failure | 3 failed attempts | Email | CSM + Finance |
| Low NPS score | <6/10 | Slack | CSM + Product |

---

## Sales Dashboard

### Layout: Two-Panel View

#### Left Panel: Pipeline Management

**Pipeline by Stage**:

| Stage | Deals | ARR | Conversion Rate | Avg Days in Stage |
|-------|-------|-----|-----------------|-------------------|
| Qualified Lead | 450 | $12.5M | 60% → | 7 days |
| Demo Scheduled | 270 | $7.5M | 70% → | 14 days |
| Proposal Sent | 189 | $5.25M | 50% → | 21 days |
| Negotiation | 95 | $2.63M | 80% → | 10 days |
| Closed Won | 76 | $2.1M | — | — |

**Weighted Pipeline**: $6.8M (actual × probability)
**Forecast (This Quarter)**: $2.1M closed + $1.5M high-probability = $3.6M

#### Right Panel: Sales Efficiency

**Rep Performance**:

| Rep | Quota | Closed | Attainment | Avg Deal Size | Win Rate | Cycle Time |
|-----|-------|--------|------------|---------------|----------|------------|
| Alice J. | $500K | $520K | 104% | $45K | 65% | 32 days |
| Bob K. | $500K | $380K | 76% | $38K | 55% | 45 days |
| Carol M. | $500K | $610K | 122% | $52K | 72% | 28 days |
| ... | ... | ... | ... | ... | ... | ... |

**Deal Velocity**:

```
Avg Time to Close (by Tier):
Starter:      ██ 2 days (self-serve)
Professional: ████ 7 days (self-serve + sales-assist)
Team:         ████████ 15 days (sales-led)
Enterprise:   ████████████████ 35 days (complex sale)
Strategic:    ████████████████████████ 60 days (executive sale)
```

**Competitive Win/Loss**:

```
Q4 2024 Win Rate:
Overall:        ████████████░░░░░░░░  62%

By Competitor:
vs Comp A:      ████████████████░░░░  78% (feature superiority)
vs Comp B:      ████████████░░░░░░░░  58% (price advantage)
vs Comp C:      ██████████░░░░░░░░░░  48% (convenience vs free)
vs Status Quo:  ████████████████████  95% (net new market)
```

### Alerts (Sales Team)

| Alert | Threshold | Notification | Recipients |
|-------|-----------|--------------|------------|
| Deal stalled | >45 days in stage | Email | Rep + Manager |
| Large deal at risk | >$100K, prob <40% | Slack | AE + VP Sales |
| Win rate drop | <55% (30-day rolling) | Email | Sales Leadership |
| Forecast miss | <85% of target | PagerDuty | CRO + CFO |

---

## Marketing Dashboard

### Layout: Four-Quadrant View

#### Q1: Traffic & Conversion

**Website Funnel**:

```
Visitors:        100,000 │████████████████████
↓ (2%)                   │
Signups:          2,000  │████
↓ (25%)                  │
Trials:             500  │█
↓ (30%)                  │
Paid:               150  │░  (0.15% overall conversion)

Target: 0.20% → Need +50 conversions
```

**Conversion Rate by Source**:

| Source | Visitors | Signups | CVR | Cost per Signup |
|--------|----------|---------|-----|-----------------|
| Organic Search | 45,000 | 1,125 | 2.5% | $0 (SEO) |
| Paid Search | 20,000 | 500 | 2.5% | $120 |
| Direct | 15,000 | 225 | 1.5% | $0 |
| Referral | 10,000 | 100 | 1.0% | $50 |
| Social | 10,000 | 50 | 0.5% | $80 |

#### Q2: CAC by Segment

**Customer Acquisition Cost Trends**:

```
CAC by Tier (12-month trend):
$2,000 │                         Enterprise ───
       │                    ╱────
$1,500 │               ╱───╯
       │          ╱───╯         Team ────
$1,000 │     ╱───╯         ╱────
       │╱───╯         ╱───╯
  $500 │         ╱───╯   Professional ───
       │    ╱───╯
  $100 │───╯    Starter ────────────────
       └─────────────────────────────────
       Jan  Mar  May  Jul  Sep  Nov
```

**CAC Payback Period by Segment**:

| Segment | CAC | ARPU | Payback (months) | Target | Status |
|---------|-----|------|------------------|--------|--------|
| S05 (Tech Strat) | $5,980 | $3,588 | 20 mo | <24 mo | ✓ Green |
| S23 (ProServ Mid) | $735 | $588 | 15 mo | <18 mo | ✓ Green |
| S36 (Edu Micro) | $108 | $108 | 12 mo | <12 mo | 🟡 Yellow |
| S46 (SMB Micro) | $108 | $108 | 12 mo | <12 mo | 🟡 Yellow |

#### Q3: Campaign Performance

**Active Campaigns** (Last 30 Days):

| Campaign | Segment Target | Spend | Leads | CAC | Closed ARR | ROI |
|----------|----------------|-------|-------|-----|------------|-----|
| Enterprise Security | S04, S09, S14 | $50K | 120 | $2,500 | $180K | 3.6× |
| SMB Value Play | S46, S47, S48 | $30K | 850 | $106 | $92K | 3.1× |
| Tech Startup | S01, S02 | $25K | 420 | $179 | $65K | 2.6× |

#### Q4: Content Performance

**Top Content by Conversion**:

| Content | Views | Signups | CVR | Segment Affinity |
|---------|-------|---------|-----|------------------|
| SOC 2 Compliance Guide | 12,500 | 375 | 3.0% | S08, S09, S13, S14 |
| Pricing Calculator | 8,200 | 246 | 3.0% | S23, S24, S25 |
| vs Competitor A Comparison | 6,800 | 170 | 2.5% | S16, S21, S36, S46 |

### Alerts (Marketing Team)

| Alert | Threshold | Notification | Recipients |
|-------|-----------|--------------|------------|
| CAC spike | >20% increase | Email | CMO + CFO |
| Conversion rate drop | <1.5% | Slack | Demand Gen Lead |
| Campaign underperformance | ROI <2× | Email | Campaign Manager |
| SEO traffic decline | >15% drop | Email | SEO Lead |

---

## Financial Dashboard

### Layout: Multi-Tab Interface

#### Tab 1: Revenue Recognition

**ARR Waterfall** (Quarterly):

```
Starting ARR (Q3):     $58.2M
+ New Business:        +$12.4M
+ Expansion:           +$3.8M
- Contraction:         -$1.2M
- Churn:               -$4.8M
──────────────────────────────
Ending ARR (Q4):       $68.4M (+17.5%)
```

**Cohort Analysis**:

| Cohort | Initial ARR | Current ARR | NRR | Age (months) |
|--------|-------------|-------------|-----|--------------|
| Q1 2023 | $2.5M | $3.2M | 128% | 21 |
| Q2 2023 | $3.8M | $4.6M | 121% | 18 |
| Q3 2023 | $5.2M | $5.9M | 113% | 15 |
| Q4 2023 | $7.1M | $7.8M | 110% | 12 |
| Q1 2024 | $9.5M | $9.9M | 104% | 9 |
| Q2 2024 | $12.3M | $12.1M | 98% | 6 |

**NRR Target**: >105% company-wide

#### Tab 2: Unit Economics

**LTV:CAC by Segment** (Heatmap):

```
                Micro    Small    Mid     Enterprise  Strategic
Technology      3.0×     4.2×     5.8×    8.5×       12.0×
Financial       3.5×     4.8×     6.5×    9.2×       15.0×
Healthcare      3.2×     4.5×     6.2×    8.8×       13.5×
E-commerce      2.1×     2.8×     4.2×    6.5×       10.0×
ProServ         2.5×     3.5×     5.0×    7.5×       11.0×

Color Key:
🔴 <3× (unprofitable)
🟡 3-5× (acceptable)
🟢 >5× (strong)
```

**Gross Margin by Tier**:

| Tier | Revenue | COGS | Gross Margin | GM % | Target | Status |
|------|---------|------|--------------|------|--------|--------|
| Starter | $13.8M | $2.2M | $11.6M | 84% | >80% | ✓ Green |
| Professional | $20.0M | $2.8M | $17.2M | 86% | >85% | ✓ Green |
| Team | $24.2M | $3.9M | $20.3M | 84% | >80% | ✓ Green |
| Enterprise | $7.1M | $2.1M | $5.0M | 70% | >75% | 🟡 Yellow |
| Strategic | $1.7M | $0.6M | $1.1M | 65% | >65% | ✓ Green |
| **TOTAL** | **$66.8M** | **$11.6M** | **$55.2M** | **83%** | **>80%** | **✓ Green** |

#### Tab 3: Cash Flow

**Cash Conversion Cycle**:

```
Days Sales Outstanding (DSO):    32 days (Target: <45)
Payment Terms:
- Starter/Pro: Monthly in advance        (DSO: 0)
- Team: Monthly in advance               (DSO: 0)
- Enterprise: Annual prepay (80%)        (DSO: -270)
- Strategic: Annual prepay (100%)        (DSO: -365)

Weighted avg DSO: 32 days (↓ 8 days vs last quarter)
```

**Burn Rate & Runway**:

| Metric | Amount |
|--------|--------|
| Monthly Revenue | $5.7M |
| Monthly Expenses | $4.2M |
| Net Burn | -$1.5M (profitable!) |
| Cash on Hand | $18.5M |
| Runway | 12+ months (infinite at profitability) |

### Alerts (Finance Team)

| Alert | Threshold | Notification | Recipients |
|-------|-----------|--------------|------------|
| Revenue miss | >5% below forecast | PagerDuty | CFO + CEO |
| DSO increase | >45 days | Email | CFO + AR team |
| Gross margin decline | <78% | Email | CFO + COO |
| Burn rate spike | >$2M/month | Slack | CFO + CEO + Board |

---

## Automated Alert System

### Alert Levels

**P0 - CRITICAL** (PagerDuty + SMS + Email):
- Revenue down >10% QoQ
- System outage affecting billing
- Strategic customer churned (ARR >$100K)
- Data breach / security incident

**P1 - HIGH** (Slack + Email):
- Revenue down 5-10% QoQ
- NRR <95%
- Churn spike (+3pp)
- Competitor price war detected

**P2 - MEDIUM** (Email):
- Segment underperformance (>10% below model)
- CAC increase >15%
- Win rate drop <55%

**P3 - LOW** (Weekly digest email):
- Minor forecast variances (<5%)
- Feature requests trends
- Market research updates

### Alert Routing

| Alert Type | P0 Recipients | P1 Recipients | P2 Recipients | P3 Recipients |
|------------|---------------|---------------|---------------|---------------|
| Revenue | CEO, CFO, Board | CFO, CRO | Pricing Team | Finance Analysts |
| Pricing | CEO, CFO, Pricing | Pricing Committee | Segment Owners | Marketing |
| Churn | CEO, CRO, CS Lead | CS Team Leads | CSMs | CS Ops |
| Competitive | CEO, CRO | Pricing, Sales, Marketing | Sales Enablement | Strategy Team |
| Product | CEO, CTO | Product, Engineering | PM Team | Eng Leads |

### Escalation Paths

**If P0 alert not acknowledged within 15 minutes**:
1. Re-notify original recipients (PagerDuty)
2. Escalate to CEO + on-call executive
3. Alert Board (if revenue/security)

**If P1 alert not acknowledged within 2 hours**:
1. Re-notify + escalate to manager
2. Create incident ticket
3. Schedule emergency meeting

---

## Quarterly Optimization Framework

### Timeline

**Week 1 (First week of quarter)**:
- Review previous quarter actuals vs forecast
- Identify top 5 underperforming segments
- Prioritize pricing tests for quarter

**Week 4-8 (Mid-quarter)**:
- Launch pricing experiments (3-5 segments)
- Competitive pricing review
- Customer feedback analysis (NPS, win/loss)

**Week 10-12 (End of quarter)**:
- Analyze test results
- Update pricing model with actual data
- Propose pricing changes for next quarter
- Board review preparation

**Week 13 (Start of new quarter)**:
- Implement approved price changes
- Update all systems (website, CPQ, CRM)
- Train sales team on new pricing

### Optimization Inputs

**Data Sources**:
1. **Internal**: CRM (Salesforce), Billing (Stripe), Product Analytics (Amplitude), Support (Zendesk)
2. **External**: Clearbit (firmographics), G2/TrustRadius (reviews), Klue (competitive intel)
3. **Surveys**: NPS, Van Westendorp PSM, Win/Loss interviews
4. **Economic**: GDP growth, unemployment, tech spending (Gartner/IDC)

**Analysis Outputs**:
- Updated elasticity coefficients (by segment)
- Revised WTP indices (market conditions)
- Optimal price points (algorithm output)
- Segment attractiveness scores (prioritization)
- Competitive gap analysis

### Decision Framework

**Pricing Change Criteria** (ALL must be true):
1. ✅ Statistically significant test result (p<0.05, n>100 customers)
2. ✅ Expected ARR lift >3% OR churn reduction >2pp
3. ✅ Legal review passed (no discrimination/antitrust risk)
4. ✅ Implementation cost <10% of expected gain
5. ✅ Customer communication plan ready
6. ✅ Pricing Committee approval (majority vote)

---

**Dashboard Version**: 1.0
**Technology**: Looker (visualization) + Snowflake (data warehouse) + dbt (transformations)
**Refresh Frequency**: Real-time (streaming metrics), Hourly (aggregated), Daily (full rebuild)
**Data Retention**: 7 years (compliance), 90 days (real-time cache)
**Access Control**: Role-based (Executive, Manager, IC, Read-only)
**Mobile**: Responsive web app + native iOS/Android (C-suite only)
**SLA**: 99.9% uptime, <30s query latency for 95th percentile
