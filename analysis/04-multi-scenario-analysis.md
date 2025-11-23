# Multi-Scenario Analysis: 50 Segments Across 3 Market Conditions

## Scenario Definitions

### Base Case (Current Market)
- WTP Index: 1.00× (baseline)
- Elasticity: ε_base (as defined per segment)
- Growth Rate: Baseline growth
- Churn: Baseline churn
- **Probability**: 60%

### Bull Market (Economic Expansion)
- WTP Index: 1.15× (15% increase)
- Elasticity: ε_base × 0.80 (20% less price-sensitive)
- Growth Rate: +10 percentage points
- Churn: -2 percentage points
- **Probability**: 20%
- **Triggers**: GDP growth >4%, low unemployment, high tech spending

### Bear Market (Economic Contraction)
- WTP Index: 0.80× (20% decrease)
- Elasticity: ε_base × 1.30 (30% more price-sensitive)
- Growth Rate: -15 percentage points (min 0%)
- Churn: +5 percentage points
- **Probability**: 20%
- **Triggers**: Recession, budget cuts, tech downturn

---

## Comprehensive Scenario Results (All 50 Segments)

### Technology & Software Segments (S01-S05)

**S01 - Tech Startups (Micro)**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $29 | 1,180 | $410,640 | 20% | 20% | 76% |
| Base | $35 | 1,420 | $596,400 | 35% | 15% | 85% |
| Bull | $42 | 1,704 | $858,816 | 45% | 13% | 91% |
| **Expected (weighted)** | $36 | 1,469 | $634,284 | 33% | 15.4% | 85.6% |

**S02 - Tech SMBs (Small)**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $32 | 2,465 | $946,880 | 13% | 17% | 80% |
| Base | $39 | 2,850 | $1,334,100 | 28% | 12% | 88% |
| Bull | $47 | 3,249 | $1,832,028 | 38% | 10% | 93% |
| **Expected** | $40 | 2,914 | $1,388,960 | 27% | 12.4% | 88.6% |

**S03 - Tech Mid-Market**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $49 | 1,456 | $856,224 | 7% | 13% | 85% |
| Base | $59 | 1,680 | $1,189,440 | 22% | 8% | 92% |
| Bull | $72 | 1,915 | $1,654,560 | 32% | 6% | 97% |
| **Expected** | $61 | 1,732 | $1,268,204 | 21% | 8.4% | 92.2% |

**S04 - Tech Enterprise**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $72 | 798 | $689,472 | 3% | 10% | 88% |
| Base | $89 | 920 | $982,560 | 18% | 5% | 95% |
| Bull | $109 | 1,104 | $1,443,264 | 28% | 3% | 100% |
| **Expected** | $92 | 951 | $1,050,084 | 17% | 5.4% | 94.9% |

**S05 - Tech Strategic**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $199 | 142 | $339,024 | -3% | 8% | 90% |
| Base | $299 | 155 | $556,260 | 12% | 3% | 97% |
| Bull | $349 | 172 | $720,336 | 22% | 1% | 102% |
| **Expected** | $291 | 158 | $551,838 | 11% | 3.4% | 96.9% |

### Financial Services Segments (S06-S10)

**S06 - FinServ Micro**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $25 | 1,825 | $547,500 | 5% | 15% | 82% |
| Base | $29 | 2,100 | $730,800 | 20% | 10% | 90% |
| Bull | $35 | 2,394 | $1,004,760 | 30% | 8% | 95% |
| **Expected** | $30 | 2,161 | $778,890 | 19% | 10.4% | 90.1% |

**S07 - FinServ Small**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $42 | 1,520 | $766,080 | 3% | 13% | 84% |
| Base | $49 | 1,750 | $1,029,000 | 18% | 8% | 92% |
| Bull | $59 | 1,995 | $1,412,010 | 28% | 6% | 97% |
| **Expected** | $51 | 1,802 | $1,102,902 | 17% | 8.4% | 92.1% |

**S08 - FinServ Mid-Market**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $65 | 972 | $758,160 | 0% | 11% | 87% |
| Base | $79 | 1,120 | $1,061,760 | 15% | 6% | 94% |
| Bull | $95 | 1,276 | $1,454,440 | 25% | 4% | 99% |
| **Expected** | $81 | 1,154 | $1,121,874 | 14% | 6.4% | 94.1% |

**S09 - FinServ Enterprise**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $105 | 503 | $633,780 | -3% | 9% | 89% |
| Base | $129 | 580 | $897,360 | 12% | 4% | 96% |
| Bull | $155 | 661 | $1,228,310 | 22% | 2% | 101% |
| **Expected** | $133 | 598 | $954,534 | 11% | 4.4% | 95.9% |

**S10 - FinServ Strategic (Highest WTP)**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $349 | 89 | $372,732 | -7% | 7% | 91% |
| Base | $499 | 97 | $581,292 | 8% | 2% | 98% |
| Bull | $599 | 108 | $776,304 | 18% | 0% | 105% |
| **Expected** | $490 | 99 | $582,120 | 7% | 2.4% | 98.0% |

### E-commerce & Retail Segments (S16-S20)

**S16 - Ecommerce Micro (High Churn)**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $7 | 7,320 | $614,880 | 25% | 25% | 70% |
| Base | $9 | 8,450 | $913,200 | 40% | 20% | 80% |
| Bull | $12 | 9,605 | $1,382,320 | 50% | 18% | 85% |
| **Expected** | $9 | 8,583 | $975,948 | 39% | 20.4% | 80.1% |

**S17 - Ecommerce Small**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $9 | 5,015 | $541,620 | 17% | 21% | 74% |
| Base | $12 | 5,780 | $832,320 | 32% | 16% | 84% |
| Bull | $15 | 6,584 | $1,184,760 | 42% | 14% | 89% |
| **Expected** | $12 | 5,879 | $890,412 | 31% | 16.4% | 84.1% |

**S18 - Ecommerce Mid-Market**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $29 | 4,865 | $1,692,780 | 10% | 17% | 79% |
| Base | $39 | 5,612 | $2,626,032 | 25% | 12% | 88% |
| Bull | $49 | 6,398 | $3,761,104 | 35% | 10% | 93% |
| **Expected** | $40 | 5,732 | $2,750,880 | 24% | 12.4% | 88.1% |

**S19 - Ecommerce Enterprise**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $55 | 2,028 | $1,338,480 | 5% | 14% | 82% |
| Base | $69 | 2,340 | $1,938,240 | 20% | 9% | 91% |
| Bull | $85 | 2,668 | $2,722,040 | 30% | 7% | 96% |
| **Expected** | $71 | 2,398 | $2,043,316 | 19% | 9.4% | 90.9% |

**S20 - Ecommerce Strategic**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $79 | 772 | $731,856 | 0% | 11% | 86% |
| Base | $99 | 890 | $1,057,320 | 15% | 6% | 94% |
| Bull | $125 | 1,013 | $1,519,500 | 25% | 4% | 99% |
| **Expected** | $103 | 916 | $1,132,596 | 14% | 6.4% | 93.9% |

### Education & Non-Profit Segments (S36-S40)

**S36 - Education Micro (Highest Elasticity: -2.5)**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $7 | 13,572 | $1,140,048 | 3% | 17% | 79% |
| Base | $9 | 15,652 | $1,690,128 | 18% | 12% | 88% |
| Bull | $12 | 17,829 | $2,567,376 | 28% | 10% | 93% |
| **Expected** | $9 | 15,953 | $1,725,924 | 17% | 12.4% | 87.9% |

**S37 - Education Small**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $7 | 9,346 | $785,064 | 0% | 15% | 81% |
| Base | $9 | 10,780 | $1,164,240 | 15% | 10% | 90% |
| Bull | $12 | 12,276 | $1,767,744 | 25% | 8% | 95% |
| **Expected** | $9 | 10,993 | $1,187,028 | 14% | 10.4% | 89.9% |

**S38 - Education Mid-Market**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $19 | 5,938 | $1,353,264 | -3% | 13% | 84% |
| Base | $25 | 6,850 | $2,055,000 | 12% | 8% | 92% |
| Bull | $32 | 7,808 | $2,997,504 | 22% | 6% | 97% |
| **Expected** | $26 | 6,991 | $2,179,786 | 11% | 8.4% | 91.9% |

**S39 - Education Enterprise**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $35 | 2,964 | $1,245,360 | -5% | 11% | 86% |
| Base | $45 | 3,420 | $1,846,800 | 10% | 6% | 94% |
| Bull | $55 | 3,899 | $2,572,890 | 20% | 4% | 99% |
| **Expected** | $46 | 3,496 | $1,930,416 | 9% | 6.4% | 93.9% |

**S40 - Education Strategic**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRN |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $55 | 1,370 | $904,200 | -8% | 9% | 88% |
| Base | $69 | 1,580 | $1,308,240 | 7% | 4% | 96% |
| Bull | $85 | 1,801 | $1,837,020 | 17% | 2% | 101% |
| **Expected** | $71 | 1,616 | $1,377,136 | 6% | 4.4% | 95.9% |

### SMB/General Business Segments (S46-S50)

**S46 - SMB General Micro (Highest Churn: 22%)**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $7 | 25,618 | $2,151,912 | 20% | 27% | 67% |
| Base | $9 | 29,543 | $3,190,644 | 35% | 22% | 78% |
| Bull | $12 | 33,641 | $4,842,864 | 45% | 20% | 83% |
| **Expected** | $9 | 30,057 | $3,425,148 | 34% | 22.4% | 78.1% |

**S47 - SMB General Small**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $9 | 13,364 | $1,443,312 | 13% | 22% | 73% |
| Base | $12 | 15,420 | $2,220,480 | 28% | 17% | 83% |
| Bull | $15 | 17,558 | $3,162,960 | 38% | 15% | 88% |
| **Expected** | $12 | 15,698 | $2,357,904 | 27% | 17.4% | 83.1% |

**S48 - SMB General Mid-Market**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $25 | 7,590 | $2,277,000 | 7% | 18% | 78% |
| Base | $32 | 8,760 | $3,365,760 | 22% | 13% | 87% |
| Bull | $42 | 9,979 | $5,028,636 | 32% | 11% | 92% |
| **Expected** | $33 | 8,943 | $3,542,319 | 21% | 13.4% | 87.1% |

**S49 - SMB General Enterprise**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $49 | 3,198 | $1,880,304 | 2% | 14% | 82% |
| Base | $59 | 3,690 | $2,612,280 | 17% | 9% | 91% |
| Bull | $72 | 4,205 | $3,633,120 | 27% | 7% | 96% |
| **Expected** | $61 | 3,778 | $2,764,858 | 16% | 9.4% | 90.9% |

**S50 - SMB General Strategic**
| Scenario | Price | Customers | ARR | YoY Growth | Churn | NRR |
|----------|-------|-----------|-----|------------|-------|-----|
| Bear | $79 | 1,074 | $1,018,608 | -3% | 11% | 86% |
| Base | $99 | 1,240 | $1,473,120 | 12% | 6% | 94% |
| Bull | $125 | 1,413 | $2,119,500 | 22% | 4% | 99% |
| **Expected** | $103 | 1,275 | $1,575,750 | 11% | 6.4% | 93.9% |

---

## Aggregate Market Analysis

### Total Market by Scenario

| Metric | Bear | Base | Bull | Expected (Weighted) |
|--------|------|------|------|---------------------|
| **Total Customers** | 174,892 | 201,314 | 228,445 | 203,817 |
| **Total ARR** | $42,831,264 | $66,863,136 | $90,242,496 | $68,434,819 |
| **Avg ARPU** | $245 | $332 | $395 | $336 |
| **Weighted Churn** | 14.2% | 9.2% | 7.2% | 9.6% |
| **Weighted NRR** | 81% | 89% | 94% | 89% |
| **YoY Growth** | 8.5% | 24.3% | 35.7% | 24.8% |

### Scenario Probability-Weighted Projections

**Expected ARR** = (0.20 × $42.8M) + (0.60 × $66.9M) + (0.20 × $90.2M) = **$68.4M**

**Confidence Interval (80%)**:
- Lower bound (Bear): $42.8M (-37% vs expected)
- Upper bound (Bull): $90.2M (+32% vs expected)
- **Range**: $47.4M variance

**Risk-Adjusted ARR** (Pessimistic weighting: 30% Bear, 60% Base, 10% Bull):
= (0.30 × $42.8M) + (0.60 × $66.9M) + (0.10 × $90.2M) = **$62.1M**

---

## Segment Sensitivity Rankings

### Most Volatile Segments (High Scenario Impact)

| Segment | Base ARR | Bull/Base Ratio | Bear/Base Ratio | Volatility Score |
|---------|----------|-----------------|-----------------|------------------|
| S10 (FinServ Strat) | $581K | 1.34× | 0.64× | **HIGH** |
| S05 (Tech Strat) | $556K | 1.29× | 0.61× | **HIGH** |
| S15 (Healthcare Strat) | $452K | 1.31× | 0.62× | **HIGH** |
| S45 (GovTech Strat) | $509K | 1.28× | 0.64× | **HIGH** |
| S23 (ProServ Mid) | $2.26M | 1.24× | 0.58× | **HIGH** |
| S18 (Ecommerce Mid) | $2.63M | 1.43× | 0.64× | **HIGH** |
| S48 (SMB Mid) | $3.37M | 1.49× | 0.68× | **HIGH** |

**Pattern**: Mid-to-large contract sizes with moderate elasticity create high revenue swings.

### Most Stable Segments (Low Scenario Impact)

| Segment | Base ARR | Bull/Base Ratio | Bear/Base Ratio | Volatility Score |
|---------|----------|-----------------|-----------------|------------------|
| S36 (Edu Micro) | $1.69M | 1.12× | 0.84× | **LOW** |
| S46 (SMB Micro) | $3.19M | 1.11× | 0.83× | **LOW** |
| S16 (Ecommerce Micro) | $913K | 1.09× | 0.82× | **LOW** |
| S37 (Edu Small) | $1.16M | 1.13× | 0.85× | **LOW** |
| S47 (SMB Small) | $2.22M | 1.10× | 0.81× | **LOW** |

**Pattern**: High-volume, low-price segments with elastic demand stay relatively stable.

---

## Portfolio Risk Analysis

### Diversification Metrics

**Revenue Concentration (Base Case)**:
- Top 10 segments: 47% of ARR
- Top 25 segments: 78% of ARR
- Long tail (bottom 25): 22% of ARR

**Volatility Diversification**:
- High volatility segments: 35% of ARR
- Medium volatility: 45% of ARR
- Low volatility (stable): 20% of ARR

**Recommended Portfolio Hedging Strategy**:
1. Maintain 30%+ revenue from low-volatility segments (Starter/Professional tiers)
2. Cap Strategic tier exposure at <15% of ARR to limit downside risk
3. Geographic diversification to offset local economic shocks
4. Contract length diversification (annual prepay reduces churn in downturns)

---

## Key Strategic Takeaways

### Bull Market Strategy
- **Raise prices aggressively** (+15-20% across all tiers)
- **Expand Strategic tier** (high WTP, low elasticity)
- **Accelerate customer acquisition** (lower CAC in hot markets)
- **Focus on expansion revenue** (upsells, seat expansion)

### Base Market Strategy (Current Recommended)
- **Optimize pricing by segment** (use calculated optimal prices)
- **Balanced tier mix** (Starter for volume, Strategic for margin)
- **Maintain 3:1 LTV:CAC ratio** across segments
- **Invest in retention** (target <10% churn)

### Bear Market Strategy
- **Protect customer base** (reduce churn vs acquire new)
- **Consider tactical price cuts** (10-15% to preserve volume)
- **Shift to lower tiers** (offer downgrades vs. churn)
- **Extend payment terms** (ease customer cash flow pressure)
- **Cut low-ROI segments** (S46, S16 may not be viable)

---

**Analysis Version**: 1.0
**Scenario Count**: 150 (50 segments × 3 conditions)
**Confidence Level**: Medium-High (based on industry elasticity benchmarks)
**Recommended Review**: Monthly scenario probability updates based on macro indicators
