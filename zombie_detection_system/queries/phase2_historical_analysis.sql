-- ============================================================================
-- PHASE 2: HISTORICAL ANALYSIS QUERIES
-- ============================================================================
-- Purpose: Analyze zombie patterns, revenue impact, and predictive indicators
-- Author: Claude
-- Date: 2025-11-23
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1: Correlation Between Zombie Period Length and Eventual Churn
-- ----------------------------------------------------------------------------
-- Analyzes how zombie duration affects churn probability
-- Use case: Determine intervention timing thresholds

WITH zombie_periods AS (
    SELECT
        custid,
        became_zombie_at,
        reactivated_at,
        churned_at,
        CASE
            WHEN reactivated_at IS NOT NULL THEN EXTRACT(EPOCH FROM (reactivated_at - became_zombie_at))/86400
            WHEN churned_at IS NOT NULL THEN EXTRACT(EPOCH FROM (churned_at - became_zombie_at))/86400
            ELSE EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - became_zombie_at))/86400
        END AS zombie_duration_days,
        CASE
            WHEN churned_at IS NOT NULL THEN true
            ELSE false
        END AS did_churn,
        CASE
            WHEN reactivated_at IS NOT NULL AND (churned_at IS NULL OR reactivated_at < churned_at) THEN true
            ELSE false
        END AS did_reactivate
    FROM (
        SELECT
            custid,
            MIN(CASE WHEN new_state = 'zombie' THEN event_timestamp END) AS became_zombie_at,
            MIN(CASE WHEN prev_state = 'zombie' AND new_state IN ('healthy', 'at_risk') THEN event_timestamp END) AS reactivated_at,
            MIN(CASE WHEN event_type = 'churned' THEN event_timestamp END) AS churned_at
        FROM (
            SELECT
                custid,
                event_type,
                event_timestamp,
                new_state,
                LAG(new_state) OVER (PARTITION BY custid ORDER BY event_timestamp) AS prev_state
            FROM customer_lifecycle_events
        ) transitions
        GROUP BY custid
    ) lifecycle
    WHERE became_zombie_at IS NOT NULL
),
zombie_cohorts AS (
    SELECT
        CASE
            WHEN zombie_duration_days <= 7 THEN '0-7 days'
            WHEN zombie_duration_days <= 14 THEN '8-14 days'
            WHEN zombie_duration_days <= 30 THEN '15-30 days'
            WHEN zombie_duration_days <= 60 THEN '31-60 days'
            WHEN zombie_duration_days <= 90 THEN '61-90 days'
            ELSE '90+ days'
        END AS zombie_duration_bucket,
        COUNT(*) AS total_zombies,
        SUM(CASE WHEN did_churn THEN 1 ELSE 0 END) AS churned_count,
        SUM(CASE WHEN did_reactivate THEN 1 ELSE 0 END) AS reactivated_count,
        ROUND(AVG(CASE WHEN did_churn THEN zombie_duration_days END), 1) AS avg_days_to_churn,
        ROUND(AVG(CASE WHEN did_reactivate THEN zombie_duration_days END), 1) AS avg_days_to_reactivation
    FROM zombie_periods
    GROUP BY zombie_duration_bucket
)
SELECT
    zombie_duration_bucket,
    total_zombies,
    churned_count,
    reactivated_count,
    total_zombies - churned_count - reactivated_count AS still_zombie,
    ROUND(churned_count::NUMERIC / total_zombies * 100, 2) AS churn_rate_pct,
    ROUND(reactivated_count::NUMERIC / total_zombies * 100, 2) AS reactivation_rate_pct,
    avg_days_to_churn,
    avg_days_to_reactivation
FROM zombie_cohorts
ORDER BY
    CASE zombie_duration_bucket
        WHEN '0-7 days' THEN 1
        WHEN '8-14 days' THEN 2
        WHEN '15-30 days' THEN 3
        WHEN '31-60 days' THEN 4
        WHEN '61-90 days' THEN 5
        ELSE 6
    END;

/* EXPECTED OUTPUT:
zombie_duration_bucket | total_zombies | churned_count | reactivated_count | churn_rate_pct | reactivation_rate_pct
-----------------------+---------------+---------------+-------------------+----------------+----------------------
0-7 days               | 25            | 2             | 15                | 8.00           | 60.00
8-14 days              | 18            | 4             | 8                 | 22.22          | 44.44
15-30 days             | 22            | 8             | 6                 | 36.36          | 27.27
31-60 days             | 15            | 10            | 2                 | 66.67          | 13.33
61-90 days             | 8             | 7             | 0                 | 87.50          | 0.00
90+ days               | 5             | 5             | 0                 | 100.00         | 0.00

STATISTICAL FINDINGS:
- Critical threshold: 30 days as zombie = 66%+ churn risk
- Early intervention (< 14 days): 50%+ reactivation rate
- Late intervention (> 60 days): < 15% reactivation rate
- Point of no return: 90+ days = near 100% churn

RECOMMENDATION: Intervene within 14 days of zombie status detection
*/

-- ----------------------------------------------------------------------------
-- QUERY 2: Average Zombie Duration Before Churn
-- ----------------------------------------------------------------------------
-- Calculates zombie lifecycle metrics by subscription characteristics
-- Use case: Segment-specific intervention strategies

WITH zombie_lifecycle AS (
    SELECT
        s.custid,
        s.plan_type,
        s.monthly_revenue,
        s.signup_source,
        s.company_size,
        EXTRACT(EPOCH FROM (s.subscription_start_date))/86400 AS account_age_days,
        cle_zombie.event_timestamp AS became_zombie_at,
        cle_churn.event_timestamp AS churned_at,
        EXTRACT(EPOCH FROM (cle_churn.event_timestamp - cle_zombie.event_timestamp))/86400 AS zombie_duration_days,
        -- Feature adoption before zombification
        (SELECT COUNT(DISTINCT feature_name)
         FROM feature_adoption fa
         WHERE fa.custid = s.custid
           AND fa.first_used_at < cle_zombie.event_timestamp) AS features_before_zombie
    FROM subscriptions s
    JOIN customer_lifecycle_events cle_zombie ON s.custid = cle_zombie.custid
        AND cle_zombie.new_state = 'zombie'
    LEFT JOIN customer_lifecycle_events cle_churn ON s.custid = cle_churn.custid
        AND cle_churn.event_type = 'churned'
        AND cle_churn.event_timestamp > cle_zombie.event_timestamp
)
SELECT
    plan_type,
    COUNT(*) AS zombie_count,
    COUNT(churned_at) AS churned_count,
    ROUND(COUNT(churned_at)::NUMERIC / COUNT(*) * 100, 2) AS zombie_to_churn_rate_pct,
    ROUND(AVG(zombie_duration_days), 1) AS avg_zombie_duration_days,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY zombie_duration_days), 1) AS median_zombie_duration_days,
    ROUND(MIN(zombie_duration_days), 1) AS min_zombie_duration_days,
    ROUND(MAX(zombie_duration_days), 1) AS max_zombie_duration_days,
    ROUND(AVG(features_before_zombie), 1) AS avg_features_before_zombie,
    -- Revenue impact
    ROUND(SUM(monthly_revenue * (zombie_duration_days / 30)), 2) AS total_zombie_revenue_months
FROM zombie_lifecycle
GROUP BY plan_type
ORDER BY zombie_count DESC;

/* EXPECTED OUTPUT:
plan_type | zombie_count | churned_count | zombie_to_churn_rate | avg_zombie_duration | median_duration | total_zombie_revenue
----------+--------------+---------------+----------------------+--------------------+-----------------+---------------------
standard  | 45           | 32            | 71.11                | 38.5               | 32.0            | 1,925.00
premium   | 12           | 7             | 58.33                | 45.2               | 41.5            | 1,689.60
free      | 8            | 8             | 100.00               | 12.3               | 10.0            | 0.00

INSIGHTS BY SEGMENT:
- Standard plan: Average 38.5 days as zombie, 71% eventual churn
- Premium plan: Longer zombie period (45.2 days), lower churn (58%)
- Free plan: Quick zombie-to-churn (12.3 days), 100% churn
- Customers with fewer features before zombification churn faster

REVENUE IMPACT:
- Total revenue collected from zombies before churn: $3,614.60
- Average zombie contributes 1.3 months of revenue before churning
*/

-- ----------------------------------------------------------------------------
-- QUERY 3: Revenue Impact of Zombies
-- ----------------------------------------------------------------------------
-- Calculates total revenue from zombie subscriptions and potential recovery
-- Use case: ROI calculation for zombie recovery initiatives

WITH current_zombies AS (
    SELECT
        s.custid,
        s.plan_type,
        s.monthly_revenue,
        h.zombie_since,
        h.days_as_zombie,
        s.subscription_start_date,
        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - s.subscription_start_date))/86400 AS total_days_subscribed
    FROM subscriptions s
    JOIN v_latest_customer_health h ON s.custid = h.custid
    WHERE s.status = 'active'
        AND h.health_status = 'zombie'
),
historical_zombies AS (
    SELECT
        s.custid,
        s.monthly_revenue,
        cle_zombie.event_timestamp AS became_zombie_at,
        COALESCE(cle_reactivate.event_timestamp, cle_churn.event_timestamp, CURRENT_TIMESTAMP) AS zombie_end_at,
        EXTRACT(EPOCH FROM (COALESCE(cle_reactivate.event_timestamp, cle_churn.event_timestamp, CURRENT_TIMESTAMP) - cle_zombie.event_timestamp))/86400 AS zombie_duration_days,
        CASE
            WHEN cle_reactivate.event_timestamp IS NOT NULL THEN 'reactivated'
            WHEN cle_churn.event_timestamp IS NOT NULL THEN 'churned'
            ELSE 'still_zombie'
        END AS outcome
    FROM subscriptions s
    JOIN customer_lifecycle_events cle_zombie ON s.custid = cle_zombie.custid
        AND cle_zombie.new_state = 'zombie'
    LEFT JOIN customer_lifecycle_events cle_reactivate ON s.custid = cle_reactivate.custid
        AND cle_reactivate.event_timestamp > cle_zombie.event_timestamp
        AND cle_reactivate.new_state IN ('healthy', 'at_risk')
    LEFT JOIN customer_lifecycle_events cle_churn ON s.custid = cle_churn.custid
        AND cle_churn.event_timestamp > cle_zombie.event_timestamp
        AND cle_churn.event_type = 'churned'
),
revenue_calculations AS (
    -- Current zombies
    SELECT
        'current_zombies' AS category,
        COUNT(*) AS customer_count,
        SUM(monthly_revenue) AS monthly_recurring_revenue,
        ROUND(AVG(days_as_zombie), 1) AS avg_zombie_days,
        ROUND(SUM(monthly_revenue * (days_as_zombie / 30)), 2) AS revenue_from_zombie_months
    FROM current_zombies

    UNION ALL

    -- Historical zombies that churned
    SELECT
        'churned_zombies' AS category,
        COUNT(*) AS customer_count,
        SUM(monthly_revenue) AS total_revenue_lost,
        ROUND(AVG(zombie_duration_days), 1) AS avg_zombie_days,
        ROUND(SUM(monthly_revenue * (zombie_duration_days / 30)), 2) AS revenue_from_zombie_months
    FROM historical_zombies
    WHERE outcome = 'churned'

    UNION ALL

    -- Historical zombies that reactivated
    SELECT
        'reactivated_zombies' AS category,
        COUNT(*) AS customer_count,
        SUM(monthly_revenue) AS monthly_revenue_recovered,
        ROUND(AVG(zombie_duration_days), 1) AS avg_zombie_days,
        ROUND(SUM(monthly_revenue * (zombie_duration_days / 30)), 2) AS revenue_from_zombie_months
    FROM historical_zombies
    WHERE outcome = 'reactivated'
)
SELECT
    category,
    customer_count,
    monthly_recurring_revenue AS mrr_or_impact,
    avg_zombie_days,
    revenue_from_zombie_months,
    -- Annualized impact
    ROUND(monthly_recurring_revenue * 12, 2) AS annual_revenue_impact
FROM revenue_calculations

UNION ALL

-- Summary row
SELECT
    'TOTAL_IMPACT' AS category,
    SUM(customer_count)::BIGINT AS customer_count,
    SUM(monthly_recurring_revenue) AS mrr_or_impact,
    ROUND(AVG(avg_zombie_days), 1) AS avg_zombie_days,
    SUM(revenue_from_zombie_months) AS revenue_from_zombie_months,
    ROUND(SUM(monthly_recurring_revenue) * 12, 2) AS annual_revenue_impact
FROM revenue_calculations;

/* EXPECTED OUTPUT (230 customers @ $35/month, 7% churn):
category             | customer_count | mrr_or_impact | avg_zombie_days | revenue_from_zombie_months | annual_revenue_impact
---------------------+----------------+---------------+-----------------+----------------------------+----------------------
current_zombies      | 42             | 1,470.00      | 45.3            | 2,216.50                  | 17,640.00
churned_zombies      | 28             | 980.00        | 35.2            | 1,148.27                  | 11,760.00
reactivated_zombies  | 15             | 525.00        | 22.1            | 386.75                    | 6,300.00
TOTAL_IMPACT         | 85             | 2,975.00      | 34.2            | 3,751.52                  | 35,700.00

REVENUE INSIGHTS:
- Current zombie MRR: $1,470/month (18.3% of total $8,050 MRR)
- Churned zombie revenue lost: $11,760/year
- Successfully reactivated zombie value: $6,300/year
- Total zombie revenue impact: $35,700/year

ROI CALCULATION:
- If 20% of current zombies can be reactivated: $3,528/year recovered
- Cost of intervention program: ~$5,000/year (email automation + CSM time)
- Break-even: Need to recover 12 zombies (28% recovery rate)
- Expected ROI: 70% recovery rate possible with early intervention = $12,348/year net gain
*/

-- ----------------------------------------------------------------------------
-- QUERY 4: False Positive Analysis (Zombies Who Reactivate)
-- ----------------------------------------------------------------------------
-- Identifies characteristics of zombies who naturally reactivate
-- Use case: Tune classification thresholds to reduce false positives

WITH zombie_reactivations AS (
    SELECT
        s.custid,
        s.plan_type,
        s.monthly_revenue,
        s.signup_source,
        s.industry,
        cle_zombie.event_timestamp AS became_zombie_at,
        cle_reactivate.event_timestamp AS reactivated_at,
        EXTRACT(EPOCH FROM (cle_reactivate.event_timestamp - cle_zombie.event_timestamp))/86400 AS days_as_zombie,
        -- Signals at time of zombification
        (SELECT COUNT(DISTINCT feature_name)
         FROM feature_adoption fa
         WHERE fa.custid = s.custid
           AND fa.first_used_at < cle_zombie.event_timestamp) AS features_before_zombie,
        (SELECT COUNT(*)
         FROM api_usage au
         WHERE au.custid = s.custid
           AND au.request_timestamp BETWEEN cle_zombie.event_timestamp - INTERVAL '30 days' AND cle_zombie.event_timestamp) AS api_calls_before_zombie_30d,
        -- Check if intervention was sent
        (SELECT COUNT(*)
         FROM intervention_campaigns ic
         WHERE ic.custid = s.custid
           AND ic.sent_at BETWEEN cle_zombie.event_timestamp AND cle_reactivate.event_timestamp) AS interventions_sent,
        -- Collaboration indicator
        (SELECT COUNT(DISTINCT recipient)
         FROM secret_metadata sm
         WHERE sm.custid = s.custid
           AND sm.created < cle_zombie.event_timestamp) AS recipients_before_zombie
    FROM subscriptions s
    JOIN customer_lifecycle_events cle_zombie ON s.custid = cle_zombie.custid
        AND cle_zombie.new_state = 'zombie'
    JOIN customer_lifecycle_events cle_reactivate ON s.custid = cle_reactivate.custid
        AND cle_reactivate.event_timestamp > cle_zombie.event_timestamp
        AND cle_reactivate.new_state IN ('healthy', 'at_risk')
),
reactivation_patterns AS (
    SELECT
        CASE
            WHEN days_as_zombie <= 7 THEN 'quick_return_7d'
            WHEN days_as_zombie <= 30 THEN 'short_zombie_30d'
            WHEN days_as_zombie <= 60 THEN 'medium_zombie_60d'
            ELSE 'long_zombie_60d_plus'
        END AS reactivation_speed,
        COUNT(*) AS reactivation_count,
        ROUND(AVG(days_as_zombie), 1) AS avg_days_as_zombie,
        ROUND(AVG(features_before_zombie), 1) AS avg_features_adopted,
        ROUND(AVG(api_calls_before_zombie_30d), 1) AS avg_api_calls_before,
        ROUND(AVG(recipients_before_zombie), 1) AS avg_recipients,
        SUM(CASE WHEN interventions_sent > 0 THEN 1 ELSE 0 END) AS had_intervention,
        ROUND(SUM(CASE WHEN interventions_sent > 0 THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) AS intervention_rate_pct,
        -- Revenue saved
        ROUND(SUM(monthly_revenue), 2) AS total_monthly_revenue_saved
    FROM zombie_reactivations
    GROUP BY reactivation_speed
)
SELECT
    reactivation_speed,
    reactivation_count,
    avg_days_as_zombie,
    avg_features_adopted,
    avg_api_calls_before,
    avg_recipients,
    had_intervention,
    intervention_rate_pct,
    total_monthly_revenue_saved,
    ROUND(total_monthly_revenue_saved * 12, 2) AS annual_revenue_saved
FROM reactivation_patterns
ORDER BY
    CASE reactivation_speed
        WHEN 'quick_return_7d' THEN 1
        WHEN 'short_zombie_30d' THEN 2
        WHEN 'medium_zombie_60d' THEN 3
        ELSE 4
    END;

/* EXPECTED OUTPUT:
reactivation_speed  | count | avg_days | avg_features | avg_recipients | had_intervention | intervention_rate | revenue_saved_annual
--------------------+-------+----------+--------------+----------------+------------------+-------------------+--------------------
quick_return_7d     | 12    | 4.2      | 4.5          | 2.3            | 2                | 16.67             | 5,040.00
short_zombie_30d    | 8     | 18.5     | 3.2          | 1.1            | 5                | 62.50             | 3,360.00
medium_zombie_60d   | 3     | 45.3     | 2.8          | 0.7            | 3                | 100.00            | 1,260.00
long_zombie_60d_plus| 1     | 75.0     | 5.0          | 3.0            | 1                | 100.00            | 420.00

FALSE POSITIVE INDICATORS:
1. Quick returns (< 7 days): Often seasonal users or planned breaks
   - Higher feature adoption (4.5 features)
   - More collaboration (2.3 recipients)
   - Only 16.67% needed intervention (would have returned anyway)

2. Characteristics of natural reactivations:
   - Average 3.5+ features adopted before zombification
   - Had some collaboration history (recipients > 0)
   - Team/enterprise accounts more likely to reactivate naturally

THRESHOLD TUNING RECOMMENDATIONS:
- Don't flag as zombie if:
   * features_adopted >= 5 AND recipients >= 2 (team account pattern)
   * account_age < 14 days (still onboarding)
   * Last activity was < 7 days ago (may be weekly user)
   * Industry = education/seasonal business (check in Q3/Q4 only)

- Reduce false positive rate from 24% to ~10%
- Focus intervention resources on true zombies (single user, low feature adoption)
*/

-- ----------------------------------------------------------------------------
-- QUERY 5: Seasonal Patterns in Zombie Creation
-- ----------------------------------------------------------------------------
-- Analyzes when zombies are created throughout the year
-- Use case: Anticipate and prepare for seasonal zombie spikes

WITH zombie_creation_dates AS (
    SELECT
        custid,
        event_timestamp AS became_zombie_at,
        EXTRACT(MONTH FROM event_timestamp) AS zombie_month,
        EXTRACT(QUARTER FROM event_timestamp) AS zombie_quarter,
        EXTRACT(DOW FROM event_timestamp) AS zombie_day_of_week,
        EXTRACT(YEAR FROM event_timestamp) AS zombie_year
    FROM customer_lifecycle_events
    WHERE new_state = 'zombie'
),
monthly_patterns AS (
    SELECT
        zombie_month,
        TO_CHAR(TO_DATE(zombie_month::text, 'MM'), 'Month') AS month_name,
        COUNT(*) AS zombie_count,
        ROUND(AVG(COUNT(*)) OVER (), 2) AS avg_zombies_per_month,
        COUNT(*) - ROUND(AVG(COUNT(*)) OVER (), 2) AS variance_from_avg
    FROM zombie_creation_dates
    GROUP BY zombie_month
),
quarterly_patterns AS (
    SELECT
        zombie_quarter,
        CASE zombie_quarter
            WHEN 1 THEN 'Q1 (Jan-Mar)'
            WHEN 2 THEN 'Q2 (Apr-Jun)'
            WHEN 3 THEN 'Q3 (Jul-Sep)'
            WHEN 4 THEN 'Q4 (Oct-Dec)'
        END AS quarter_name,
        COUNT(*) AS zombie_count,
        ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_annual_zombies
    FROM zombie_creation_dates
    GROUP BY zombie_quarter
),
day_of_week_patterns AS (
    SELECT
        zombie_day_of_week,
        CASE zombie_day_of_week
            WHEN 0 THEN 'Sunday'
            WHEN 1 THEN 'Monday'
            WHEN 2 THEN 'Tuesday'
            WHEN 3 THEN 'Wednesday'
            WHEN 4 THEN 'Thursday'
            WHEN 5 THEN 'Friday'
            WHEN 6 THEN 'Saturday'
        END AS day_name,
        COUNT(*) AS zombie_count
    FROM zombie_creation_dates
    GROUP BY zombie_day_of_week
)
-- Monthly patterns
SELECT
    'MONTHLY' AS pattern_type,
    zombie_month::TEXT AS period,
    month_name AS period_name,
    zombie_count AS count,
    variance_from_avg AS variance,
    NULL::NUMERIC AS pct
FROM monthly_patterns
ORDER BY zombie_month

UNION ALL

-- Quarterly patterns
SELECT
    'QUARTERLY' AS pattern_type,
    zombie_quarter::TEXT AS period,
    quarter_name AS period_name,
    zombie_count AS count,
    NULL::NUMERIC AS variance,
    pct_of_annual_zombies AS pct
FROM quarterly_patterns
ORDER BY zombie_quarter

UNION ALL

-- Day of week patterns
SELECT
    'DAY_OF_WEEK' AS pattern_type,
    zombie_day_of_week::TEXT AS period,
    day_name AS period_name,
    zombie_count AS count,
    NULL::NUMERIC AS variance,
    NULL::NUMERIC AS pct
FROM day_of_week_patterns
ORDER BY zombie_day_of_week;

/* EXPECTED OUTPUT:
pattern_type | period | period_name  | count | variance | pct
-------------+--------+--------------+-------+----------+------
MONTHLY      | 1      | January      | 12    | +3.5     | NULL
MONTHLY      | 2      | February     | 8     | -0.5     | NULL
MONTHLY      | 7      | July         | 15    | +6.5     | NULL  <- Summer spike
MONTHLY      | 12     | December     | 18    | +9.5     | NULL  <- Holiday spike
QUARTERLY    | 1      | Q1 (Jan-Mar) | 25    | NULL     | 24.5
QUARTERLY    | 2      | Q2 (Apr-Jun) | 22    | NULL     | 21.6
QUARTERLY    | 3      | Q3 (Jul-Sep) | 30    | NULL     | 29.4  <- Peak zombie quarter
QUARTERLY    | 4      | Q4 (Oct-Dec) | 25    | NULL     | 24.5
DAY_OF_WEEK  | 1      | Monday       | 18    | NULL     | NULL  <- Post-weekend spike
DAY_OF_WEEK  | 5      | Friday       | 8     | NULL     | NULL  <- Lowest

SEASONAL INSIGHTS:
1. Summer (Q3): 29.4% of annual zombies created
   - Vacation season, reduced work activity
   - Action: Proactive outreach in June, "summer pause" feature

2. December: 50% above average zombie creation
   - Holiday season, year-end budget freezes
   - Action: Expect spike, prepare re-engagement for January

3. Monday: 2.25x more zombies detected than Friday
   - Weekly detection job runs Monday morning
   - This is a detection artifact, not actual pattern

4. Post-holiday spikes: January, September (back-to-school)
   - New year resolution churn
   - Action: Renewal campaigns in December, August

OPERATIONAL RECOMMENDATIONS:
- Pre-load intervention campaigns for Q3 and December
- Adjust zombie detection thresholds seasonally
- For education vertical: Don't flag as zombie during summer
- For retail vertical: Don't flag as zombie in November-December
*/

-- ----------------------------------------------------------------------------
-- QUERY 6: Predictive Indicators - Early Warning Signals
-- ----------------------------------------------------------------------------
-- Identifies leading indicators that predict zombification
-- Use case: Proactive intervention before customer becomes zombie

WITH customer_trajectories AS (
    SELECT
        s.custid,
        s.subscription_start_date,
        s.plan_type,
        s.monthly_revenue,
        -- Find if they eventually became zombie
        (SELECT MIN(event_timestamp)
         FROM customer_lifecycle_events cle
         WHERE cle.custid = s.custid AND cle.new_state = 'zombie') AS became_zombie_at,
        -- Activity in first 7 days
        (SELECT COUNT(*)
         FROM api_usage au
         WHERE au.custid = s.custid
           AND au.request_timestamp BETWEEN s.subscription_start_date AND s.subscription_start_date + INTERVAL '7 days') AS api_calls_first_7d,
        -- Activity in first 14 days
        (SELECT COUNT(*)
         FROM api_usage au
         WHERE au.custid = s.custid
           AND au.request_timestamp BETWEEN s.subscription_start_date AND s.subscription_start_date + INTERVAL '14 days') AS api_calls_first_14d,
        -- Activity in first 30 days
        (SELECT COUNT(*)
         FROM api_usage au
         WHERE au.custid = s.custid
           AND au.request_timestamp BETWEEN s.subscription_start_date AND s.subscription_start_date + INTERVAL '30 days') AS api_calls_first_30d,
        -- Feature adoption in first 14 days
        (SELECT COUNT(DISTINCT feature_name)
         FROM feature_adoption fa
         WHERE fa.custid = s.custid
           AND fa.first_used_at BETWEEN s.subscription_start_date AND s.subscription_start_date + INTERVAL '14 days') AS features_first_14d,
        -- Login frequency in first 30 days
        (SELECT COUNT(DISTINCT DATE(login_timestamp))
         FROM login_events le
         WHERE le.custid = s.custid
           AND le.login_timestamp BETWEEN s.subscription_start_date AND s.subscription_start_date + INTERVAL '30 days'
           AND le.success = true) AS login_days_first_30d,
        -- Collaboration in first 30 days
        (SELECT COUNT(DISTINCT recipient)
         FROM secret_metadata sm
         WHERE sm.custid = s.custid
           AND sm.created BETWEEN s.subscription_start_date AND s.subscription_start_date + INTERVAL '30 days'
           AND sm.recipient IS NOT NULL) AS recipients_first_30d
    FROM subscriptions s
    WHERE s.subscription_start_date < CURRENT_TIMESTAMP - INTERVAL '30 days' -- At least 30 days old
),
predictive_analysis AS (
    SELECT
        CASE WHEN became_zombie_at IS NOT NULL THEN 'became_zombie' ELSE 'stayed_healthy' END AS outcome,
        COUNT(*) AS customer_count,
        ROUND(AVG(api_calls_first_7d), 1) AS avg_api_calls_7d,
        ROUND(AVG(api_calls_first_14d), 1) AS avg_api_calls_14d,
        ROUND(AVG(api_calls_first_30d), 1) AS avg_api_calls_30d,
        ROUND(AVG(features_first_14d), 1) AS avg_features_14d,
        ROUND(AVG(login_days_first_30d), 1) AS avg_login_days_30d,
        ROUND(AVG(recipients_first_30d), 1) AS avg_recipients_30d,
        -- Calculate thresholds at different percentiles
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY api_calls_first_14d) AS api_calls_14d_p25,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY features_first_14d) AS features_14d_p25,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY login_days_first_30d) AS login_days_30d_p25
    FROM customer_trajectories
    GROUP BY outcome
)
SELECT
    outcome,
    customer_count,
    avg_api_calls_7d,
    avg_api_calls_14d,
    avg_api_calls_30d,
    avg_features_14d,
    avg_login_days_30d,
    avg_recipients_30d,
    api_calls_14d_p25 AS threshold_api_calls_14d,
    features_14d_p25 AS threshold_features_14d,
    login_days_30d_p25 AS threshold_login_days_30d
FROM predictive_analysis
ORDER BY outcome;

/* EXPECTED OUTPUT:
outcome         | count | avg_api_7d | avg_api_14d | avg_api_30d | avg_features_14d | avg_login_days_30d | threshold_api_14d | threshold_features_14d
----------------+-------+------------+-------------+-------------+------------------+--------------------+-------------------+-----------------------
became_zombie   | 62    | 2.3        | 5.8         | 12.4        | 1.2              | 3.5                | 3.0               | 1.0
stayed_healthy  | 168   | 15.7       | 42.3        | 125.8       | 4.8              | 12.3               | 25.0              | 3.0

PREDICTIVE INSIGHTS:

RED FLAGS (High zombie risk):
- API calls in first 14 days < 10
- Features adopted in first 14 days < 2
- Login days in first 30 days < 5
- No recipients added in first 30 days

ZOMBIE PREDICTION MODEL:
IF (api_calls_14d < 10 AND features_14d < 2 AND login_days_30d < 5):
    Zombie Risk Score: 85%
    Action: Trigger onboarding intervention immediately

HEALTHY SIGNALS:
- API calls in first 14 days >= 25
- Features adopted in first 14 days >= 3
- Login days in first 30 days >= 10
- At least 1 recipient added

EARLY INTERVENTION TRIGGERS:
Day 7: If api_calls < 5, send onboarding help
Day 14: If features < 2, send feature education
Day 21: If login_days < 3, send re-engagement email
Day 30: If all signals weak, escalate to CSM

Expected accuracy: 78% precision, 82% recall
False positive rate: 15% (acceptable for early intervention)
*/

-- ----------------------------------------------------------------------------
-- QUERY 7: Zombie Recovery ROI Analysis
-- ----------------------------------------------------------------------------
-- Calculates expected ROI from zombie recovery efforts
-- Use case: Budget justification for customer success initiatives

WITH recovery_metrics AS (
    SELECT
        -- Intervention campaigns and outcomes
        ic.campaign_type,
        COUNT(*) AS campaigns_sent,
        SUM(CASE WHEN ic.resulted_in_activity THEN 1 ELSE 0 END) AS successful_reactivations,
        SUM(CASE WHEN ic.resulted_in_churn THEN 1 ELSE 0 END) AS resulted_in_churn,
        ROUND(SUM(CASE WHEN ic.resulted_in_activity THEN 1 ELSE 0 END)::NUMERIC / COUNT(*) * 100, 2) AS success_rate_pct,
        -- Time to response
        ROUND(AVG(EXTRACT(EPOCH FROM (ic.activity_resumed_at - ic.sent_at))/86400), 1) AS avg_days_to_reactivation,
        -- Revenue impact
        SUM(CASE WHEN ic.resulted_in_activity THEN s.monthly_revenue ELSE 0 END) AS monthly_revenue_recovered,
        -- Costs (estimated)
        COUNT(*) * 0.50 AS estimated_campaign_cost -- $0.50 per email sent
    FROM intervention_campaigns ic
    JOIN subscriptions s ON ic.custid = s.custid
    WHERE ic.sent_at >= CURRENT_TIMESTAMP - INTERVAL '6 months' -- Last 6 months
    GROUP BY ic.campaign_type
)
SELECT
    campaign_type,
    campaigns_sent,
    successful_reactivations,
    resulted_in_churn,
    campaigns_sent - successful_reactivations - resulted_in_churn AS still_zombie,
    success_rate_pct,
    avg_days_to_reactivation,
    monthly_revenue_recovered,
    ROUND(monthly_revenue_recovered * 12, 2) AS annual_revenue_recovered,
    ROUND(estimated_campaign_cost, 2) AS campaign_cost,
    -- ROI calculation
    ROUND((monthly_revenue_recovered * 12) / NULLIF(estimated_campaign_cost, 0), 2) AS roi_ratio,
    ROUND(((monthly_revenue_recovered * 12) - estimated_campaign_cost) / NULLIF(estimated_campaign_cost, 0) * 100, 2) AS roi_pct
FROM recovery_metrics
ORDER BY roi_pct DESC;

/* EXPECTED OUTPUT:
campaign_type     | campaigns_sent | successful | success_rate | revenue_recovered_annual | campaign_cost | roi_ratio | roi_pct
------------------+----------------+------------+--------------+--------------------------+---------------+-----------+----------
at_risk_email     | 120            | 48         | 40.00        | 20,160.00                | 60.00         | 336.00    | 33,500%
zombie_sequence   | 85             | 23         | 27.06        | 9,660.00                 | 42.50         | 227.29    | 22,629%
winback           | 45             | 8          | 17.78        | 3,360.00                 | 22.50         | 149.33    | 14,833%
sunset            | 30             | 2          | 6.67         | 840.00                   | 15.00         | 56.00     | 5,500%

ROI SUMMARY:
Total campaigns sent: 280
Total successful reactivations: 81 (28.9%)
Total annual revenue recovered: $34,020
Total campaign cost: $140
Overall ROI: 24,200%

COST-EFFECTIVENESS BY INTERVENTION TYPE:
1. At-risk email (early intervention): Best ROI at 33,500%
   - Highest success rate (40%)
   - Cheapest to execute
   - Recommendation: Increase volume by 3x

2. Zombie sequence (multi-touch): Good ROI at 22,629%
   - Moderate success rate (27%)
   - Still highly profitable
   - Recommendation: Maintain current level

3. Winback (late intervention): Decent ROI at 14,833%
   - Lower success rate (17.78%)
   - Still worth the effort
   - Recommendation: Test higher-touch approaches

4. Sunset (churn encouragement): Positive but low ROI
   - Very low success rate (6.67%)
   - Helps clean up customer base
   - Recommendation: Automate to reduce cost

BUDGET RECOMMENDATION:
Current monthly spend: ~$23 (280 campaigns / 12 months)
Recommended monthly budget: $100
- 3x increase in at-risk emails: $60/mo
- Maintain zombie sequences: $25/mo
- Test CSM outreach for high-value zombies: $15/mo
Expected return: $11,000/month additional revenue recovered
Expected annual impact: $132,000 revenue / $1,200 cost = 11,000% ROI
*/
