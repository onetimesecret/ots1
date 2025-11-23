# Customer Lifecycle State Machine
## Zombie Detection System

**Author:** Claude
**Date:** 2025-11-23
**Version:** 1.0

---

## State Machine Diagram

```
                                    ┌──────────────┐
                                    │              │
                    signup ────────>│   NEW USER   │
                                    │              │
                                    └──────┬───────┘
                                           │
                                           │ first_activity
                                           │ (api_call OR login)
                                           │
                                           v
                                    ┌──────────────┐
                          ┌─────────┤              │<─────────┐
                          │         │   HEALTHY    │          │
                          │         │ (score≥70)   │          │
                          │         └──────┬───────┘          │
                          │                │                   │
                          │   engagement   │ declining_usage   │ improving_usage
                          │   increases    │ (score drops)     │
                          │                │                   │
                          │                v                   │
                          │         ┌──────────────┐           │
                          │         │              │           │
                          │         │   AT-RISK    │           │
                          │         │ (40≤score<70)│───────────┘
                          │         │              │
                          │         └──────┬───────┘
                          │                │
                          │                │ 2+ zombie signals
                          │                │ score continues drop
                          │                │
                          │                v
                          │         ┌──────────────┐
                          │         │              │
                reactivate│         │   ZOMBIE     │
                (campaign │         │ (15≤score<40)│
                success)  │         │  3+ signals  │
                          │         │              │
                          │         └──────┬───────┘
                          │                │
                          │                │ no activity 90+ days
                          │                │ never_onboarded
                          │                │
                          │                v
                          │         ┌──────────────┐
                          │         │              │
                          └────────>│     DEAD     │────┐
                                    │  (score<15)  │    │
                                    │              │    │
                                    └──────────────┘    │
                                                        │
                                                        │ churn OR
                                                        │ sunset
                                                        v
                                                 ┌──────────────┐
                                                 │              │
                                                 │   CHURNED    │
                                                 │  (canceled)  │
                                                 │              │
                                                 └──────────────┘
```

---

## States

### 1. NEW USER
**Definition:** Recently signed up, no meaningful activity yet

**Criteria:**
- Account age < 14 days
- Total API calls < 5
- Features used < 2

**Characteristics:**
- Still in onboarding phase
- High potential for activation
- Not yet billable in some cases

**Transitions:**
- → **HEALTHY**: First successful usage (API call, secret created)
- → **DEAD**: 14+ days with no activity (failed onboarding)

**Intervention:**
- Onboarding emails (day 1, 3, 7, 14)
- In-app tutorials
- Welcome calls (high-value plans)

**Metrics:**
- Target activation rate: 70%
- Acceptable time to first value: 3 days

---

### 2. HEALTHY
**Definition:** Active, engaged customer with good product usage

**Criteria:**
- Health score ≥ 70
- Login days in last 30d ≥ 10
- API calls in last 30d ≥ 50
- Stable or growing usage trend

**Characteristics:**
- Low churn risk (< 5%)
- High product satisfaction
- Good feature adoption

**Transitions:**
- → **AT-RISK**: Declining usage, score drops below 70
- → **ZOMBIE**: Sudden inactivity (rare, usually goes through at-risk first)

**Intervention:**
- Upsell campaigns
- Feature announcements
- Customer success check-ins (quarterly)

**Metrics:**
- Expected percentage: 55-60% of customers
- Average health score: 82
- Average retention: 95%+

---

### 3. AT-RISK
**Definition:** Usage declining, early warning of potential churn

**Criteria:**
- Health score 40-69
- 2+ warning signals:
  - Days since last login > 30
  - API calls < 10 in last 30d
  - Usage trend = "declining"

**Characteristics:**
- Medium churn risk (15-25%)
- Still somewhat engaged
- Intervention can prevent zombification

**Transitions:**
- → **HEALTHY**: Re-engagement successful, usage improves
- → **ZOMBIE**: Continued decline, 3+ zombie signals detected
- → **DEAD**: Rapid disengagement (rare)

**Intervention:**
- Proactive outreach emails (day 0, 7, 21)
- Feature education
- CSM check-in (high-value customers)
- In-app engagement prompts

**Metrics:**
- Expected percentage: 25-30% of customers
- Target prevention rate: 60% (at-risk → healthy)
- Time to recovery: 14 days average

---

### 4. ZOMBIE
**Definition:** Paying customer with no meaningful usage

**Criteria:**
- Health score 15-39
- 3+ confirmation signals:
  - No login in 60+ days
  - API calls < 5 in last 30d
  - Features used ≤ 2
  - No data activity
  - No collaboration

**Characteristics:**
- High churn risk (50-70%)
- Still paying subscription
- Revenue at risk
- May not realize they're paying

**Subcategories:**
1. **Recent Zombie** (< 30 days): High reactivation potential (40%)
2. **Established Zombie** (30-90 days): Medium potential (15-25%)
3. **Long-term Zombie** (90+ days): Low potential (5-10%)

**Transitions:**
- → **HEALTHY**: Reactivation campaign successful, full recovery
- → **AT-RISK**: Partial reactivation, some usage resumed
- → **DEAD**: Extended inactivity (90+ days as zombie)
- → **CHURNED**: Customer cancels subscription

**Intervention:**
- Aggressive re-engagement sequence
- Winback offers (credits, VIP setup)
- Personal outreach (founder/exec for high-value)
- Sunset sequence (long-term zombies)

**Metrics:**
- Expected percentage: 12-18% of customers
- Target reactivation rate: 25%
- Average zombie duration before churn: 38 days

---

### 5. DEAD
**Definition:** Never successfully onboarded OR extended zombie

**Criteria:**
**Path A - Never Onboarded:**
- Account age > 14 days
- API calls in 90d = 0
- Features used = 0
- No login in 90+ days

**Path B - Extended Zombie:**
- Zombie duration > 90 days
- Health score < 15
- No response to interventions

**Characteristics:**
- Critical churn risk (90%+)
- Likely doesn't remember product exists
- Low recovery potential (< 10%)

**Transitions:**
- → **AT-RISK**: Rare successful recovery (< 5% chance)
- → **CHURNED**: Subscription canceled (most common)

**Intervention:**
- Final winback attempt (one-time)
- Sunset sequence (encourage cancellation)
- Data export reminder
- Graceful offboarding

**Metrics:**
- Expected percentage: 2-5% of customers
- Target recovery rate: 10%
- Acceptable time to churn: 30 days

---

### 6. CHURNED
**Definition:** Subscription canceled, no longer a customer

**Criteria:**
- Subscription status = 'canceled'
- Billing stopped

**Characteristics:**
- Ex-customer
- May return in future (winback)
- Data retention for 30-90 days

**Transitions:**
- → **NEW USER**: Re-subscription (treated as new signup)

**Post-Churn Activities:**
- Cancellation survey
- Exit interview (high-value customers)
- Data export provided
- Winback campaigns (60, 120, 180 days post-churn)

**Metrics:**
- Expected monthly churn rate: 7%
- Winback success rate: 5-8%
- Average time to winback: 120 days

---

## Transition Rules

### Automatic Transitions

| From State | To State | Trigger | Auto/Manual |
|------------|----------|---------|-------------|
| NEW USER | HEALTHY | first_activity | Automatic |
| NEW USER | DEAD | 14 days no activity | Automatic |
| HEALTHY | AT-RISK | score drops < 70 | Automatic |
| AT-RISK | HEALTHY | score rises ≥ 70 | Automatic |
| AT-RISK | ZOMBIE | 3+ zombie signals | Automatic |
| ZOMBIE | AT-RISK | partial reactivation | Automatic |
| ZOMBIE | HEALTHY | full reactivation | Automatic |
| ZOMBIE | DEAD | 90+ days inactive | Automatic |
| DEAD | CHURNED | subscription cancel | Automatic |
| ANY | CHURNED | manual cancel | Manual |

---

## Intervention Timing

### Critical Timing Windows

**Window 1: First 14 Days (NEW USER → HEALTHY)**
- **Goal:** Successful onboarding
- **Success Rate:** 70%
- **Key Metric:** Time to first secret
- **Intervention:** Automated onboarding emails, tutorials

**Window 2: First 30 Days Post-Decline (HEALTHY → AT-RISK → HEALTHY)**
- **Goal:** Prevent zombification
- **Success Rate:** 60%
- **Key Metric:** Usage resumption within 21 days
- **Intervention:** Proactive outreach, feature education

**Window 3: First 30 Days as Zombie (AT-RISK → ZOMBIE → HEALTHY)**
- **Goal:** Quick reactivation
- **Success Rate:** 40%
- **Key Metric:** Login within 14 days
- **Intervention:** We miss you emails, incentives

**Window 4: 30-90 Days as Zombie**
- **Goal:** Last-chance recovery
- **Success Rate:** 15-25%
- **Key Metric:** Response to winback offer
- **Intervention:** Aggressive winback, personal outreach

**Window 5: 90+ Days (ZOMBIE → DEAD → CHURNED)**
- **Goal:** Graceful sunset
- **Success Rate:** 5-10%
- **Key Metric:** Clean cancellation process
- **Intervention:** Sunset sequence, data export

---

## State Dwell Times

### Healthy Dwell Time Targets
- **Median:** Indefinite (goal)
- **Mean:** 365+ days

### At-Risk Dwell Time
- **Healthy outcome:** < 21 days
- **Zombie outcome:** 30-45 days
- **Target:** Resolve within 30 days

### Zombie Dwell Time
- **Reactivated:** 10-30 days
- **Churned:** 40-60 days
- **Maximum acceptable:** 90 days

### Dead Dwell Time
- **Target:** < 30 days (sunset quickly)

---

## False Positive Handling

### Seasonal Users
**Issue:** Flagged as zombie during off-season

**Solution:**
- Check industry field (education, retail, tax)
- Apply seasonal thresholds
- Don't intervene during known low-usage periods

### Annual Plan Customers
**Issue:** Low monthly usage but already paid upfront

**Solution:**
- Separate tracking from monthly customers
- Focus on renewal risk, not immediate churn
- Lower zombie threshold

### API-Only Users
**Issue:** Never login to web UI

**Solution:**
- Detect usage pattern (API >> logins)
- Adjust component weights (API 50%, logins 20%)
- Use different healthy threshold

### Weekly Users
**Issue:** Flagged as zombie after 7 days inactive

**Solution:**
- Don't flag < 30 days since last activity
- Look at pattern (active every 7 days)
- Adjust login frequency expectations

---

## Monitoring and Alerts

### Daily Alerts

1. **New zombies detected:** Count > baseline + 20%
2. **High-value zombie:** Revenue > $100/mo
3. **Zombie → Dead transition:** 90-day mark approaching

### Weekly Reviews

1. Distribution of customers across states
2. Transition rates (week-over-week)
3. Intervention campaign performance

### Monthly Analysis

1. Churn correlation with state transitions
2. False positive rate calculation
3. Model performance tuning

---

## Success Metrics by State

| State | Target % | Churn Risk | Avg Score | Intervention Cost |
|-------|----------|------------|-----------|-------------------|
| HEALTHY | 55-60% | < 5% | 82 | Low ($0.50/mo) |
| AT-RISK | 25-30% | 15-25% | 52 | Medium ($2/mo) |
| ZOMBIE | 12-18% | 50-70% | 28 | High ($5-10/mo) |
| DEAD | 2-5% | 90%+ | 8 | Very High ($20/mo) |

---

## Conclusion

This state machine provides a structured framework for:
1. Classifying customer health status
2. Triggering appropriate interventions at the right time
3. Measuring effectiveness of retention efforts
4. Optimizing resource allocation across customer segments

The key to success is early intervention (at-risk stage) and aggressive recovery attempts for recent zombies, while gracefully sunsetting long-term inactive customers.
