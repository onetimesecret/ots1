-- ============================================================================
-- MONITORING DASHBOARD QUERIES
-- ============================================================================
-- Purpose: Pre-built queries for customer success dashboard and monitoring
-- Author: Claude
-- Date: 2025-11-23
-- ============================================================================

-- ----------------------------------------------------------------------------
-- DASHBOARD OVERVIEW - Main KPIs
-- ----------------------------------------------------------------------------
-- Use this query to populate the main dashboard overview

WITH latest_scores AS (
    SELECT DISTINCT ON (custid)
        custid,
        health_score,
        health_status,
        churn_risk_score,
        reactivation_potential,
        zombie_since,
        days_as_zombie,
        calculated_at
    FROM customer_health_scores
    ORDER BY custid, calculated_at DESC
),
kpis AS (
    SELECT
        -- Total active customers
        COUNT(*) AS total_active_customers,

        -- By health status
        COUNT(*) FILTER (WHERE health_status = 'healthy') AS healthy_count,
        COUNT(*) FILTER (WHERE health_status = 'at_risk') AS at_risk_count,
        COUNT(*) FILTER (WHERE health_status = 'zombie') AS zombie_count,
        COUNT(*) FILTER (WHERE health_status = 'dead') AS dead_count,

        -- Percentages
        ROUND(COUNT(*) FILTER (WHERE health_status = 'healthy')::NUMERIC / COUNT(*) * 100, 2) AS healthy_pct,
        ROUND(COUNT(*) FILTER (WHERE health_status = 'at_risk')::NUMERIC / COUNT(*) * 100, 2) AS at_risk_pct,
        ROUND(COUNT(*) FILTER (WHERE health_status = 'zombie')::NUMERIC / COUNT(*) * 100, 2) AS zombie_pct,

        -- Average scores
        ROUND(AVG(health_score), 2) AS avg_health_score,
        ROUND(AVG(churn_risk_score), 2) AS avg_churn_risk,

        -- Zombie metrics
        ROUND(AVG(days_as_zombie) FILTER (WHERE health_status = 'zombie'), 1) AS avg_zombie_duration,
        MAX(days_as_zombie) AS max_zombie_duration
    FROM latest_scores ls
    JOIN subscriptions s ON ls.custid = s.custid
    WHERE s.status = 'active'
),
revenue_kpis AS (
    SELECT
        SUM(s.monthly_revenue) AS total_mrr,
        SUM(CASE WHEN ls.health_status = 'healthy' THEN s.monthly_revenue ELSE 0 END) AS healthy_mrr,
        SUM(CASE WHEN ls.health_status = 'at_risk' THEN s.monthly_revenue ELSE 0 END) AS at_risk_mrr,
        SUM(CASE WHEN ls.health_status = 'zombie' THEN s.monthly_revenue ELSE 0 END) AS zombie_mrr,
        SUM(CASE WHEN ls.health_status IN ('zombie', 'at_risk') THEN s.monthly_revenue ELSE 0 END) AS revenue_at_risk
    FROM latest_scores ls
    JOIN subscriptions s ON ls.custid = s.custid
    WHERE s.status = 'active'
),
trend_kpis AS (
    SELECT
        COUNT(*) FILTER (WHERE event_type = 'became_zombie' AND event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days') AS new_zombies_7d,
        COUNT(*) FILTER (WHERE event_type = 'became_at_risk' AND event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days') AS new_at_risk_7d,
        COUNT(*) FILTER (WHERE event_type = 'reactivated' AND event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days') AS reactivated_7d,
        COUNT(*) FILTER (WHERE event_type = 'became_zombie' AND event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '30 days') AS new_zombies_30d
    FROM customer_lifecycle_events
)
SELECT
    'OVERVIEW' AS section,
    jsonb_build_object(
        'total_active_customers', k.total_active_customers,
        'health_distribution', jsonb_build_object(
            'healthy', jsonb_build_object('count', k.healthy_count, 'percentage', k.healthy_pct),
            'at_risk', jsonb_build_object('count', k.at_risk_count, 'percentage', k.at_risk_pct),
            'zombie', jsonb_build_object('count', k.zombie_count, 'percentage', k.zombie_pct),
            'dead', jsonb_build_object('count', k.dead_count)
        ),
        'health_metrics', jsonb_build_object(
            'avg_health_score', k.avg_health_score,
            'avg_churn_risk', k.avg_churn_risk,
            'avg_zombie_duration_days', k.avg_zombie_duration
        ),
        'revenue_metrics', jsonb_build_object(
            'total_mrr', r.total_mrr,
            'healthy_mrr', r.healthy_mrr,
            'at_risk_mrr', r.at_risk_mrr,
            'zombie_mrr', r.zombie_mrr,
            'total_revenue_at_risk', r.revenue_at_risk,
            'revenue_at_risk_pct', ROUND(r.revenue_at_risk / NULLIF(r.total_mrr, 0) * 100, 2)
        ),
        'trends_7d', jsonb_build_object(
            'new_zombies', t.new_zombies_7d,
            'new_at_risk', t.new_at_risk_7d,
            'reactivated', t.reactivated_7d
        ),
        'generated_at', CURRENT_TIMESTAMP
    ) AS dashboard_data
FROM kpis k, revenue_kpis r, trend_kpis t;

-- ----------------------------------------------------------------------------
-- HIGH-PRIORITY ZOMBIE LIST
-- ----------------------------------------------------------------------------
-- Top 20 zombies ranked by revenue at risk and reactivation potential

SELECT
    s.custid,
    s.plan_type,
    s.monthly_revenue,
    s.monthly_revenue * 12 AS annual_revenue_at_risk,
    chs.health_score,
    chs.churn_risk_score,
    chs.reactivation_potential,
    chs.zombie_since,
    chs.days_as_zombie,
    chs.days_since_last_login,
    chs.api_calls_last_30d,
    -- Priority score: combination of revenue and reactivation potential
    ROUND((s.monthly_revenue / 10) + chs.reactivation_potential, 2) AS priority_score,
    -- Recommended action
    CASE
        WHEN chs.days_as_zombie < 14 THEN 'immediate_outreach'
        WHEN chs.reactivation_potential >= 60 AND s.monthly_revenue >= 50 THEN 'csm_call'
        WHEN chs.days_as_zombie >= 90 THEN 'sunset_sequence'
        ELSE 'automated_campaign'
    END AS recommended_action
FROM subscriptions s
JOIN v_latest_customer_health chs ON s.custid = chs.custid
WHERE s.status = 'active'
    AND chs.health_status = 'zombie'
ORDER BY priority_score DESC, monthly_revenue DESC
LIMIT 20;

-- ----------------------------------------------------------------------------
-- INTERVENTION CAMPAIGN PERFORMANCE
-- ----------------------------------------------------------------------------
-- Track effectiveness of re-engagement campaigns

WITH campaign_metrics AS (
    SELECT
        campaign_type,
        trigger_health_status,
        COUNT(*) AS total_sent,
        COUNT(*) FILTER (WHERE opened_at IS NOT NULL) AS opened_count,
        COUNT(*) FILTER (WHERE clicked_at IS NOT NULL) AS clicked_count,
        COUNT(*) FILTER (WHERE responded_at IS NOT NULL) AS responded_count,
        COUNT(*) FILTER (WHERE resulted_in_activity = true) AS reactivated_count,
        COUNT(*) FILTER (WHERE resulted_in_churn = true) AS churned_count,
        ROUND(AVG(EXTRACT(EPOCH FROM (activity_resumed_at - sent_at))/86400) FILTER (WHERE resulted_in_activity = true), 1) AS avg_days_to_reactivation
    FROM intervention_campaigns
    WHERE sent_at >= CURRENT_TIMESTAMP - INTERVAL '90 days'
    GROUP BY campaign_type, trigger_health_status
)
SELECT
    campaign_type,
    trigger_health_status,
    total_sent,
    opened_count,
    clicked_count,
    responded_count,
    reactivated_count,
    churned_count,
    ROUND(opened_count::NUMERIC / NULLIF(total_sent, 0) * 100, 2) AS open_rate_pct,
    ROUND(clicked_count::NUMERIC / NULLIF(total_sent, 0) * 100, 2) AS click_rate_pct,
    ROUND(responded_count::NUMERIC / NULLIF(total_sent, 0) * 100, 2) AS response_rate_pct,
    ROUND(reactivated_count::NUMERIC / NULLIF(total_sent, 0) * 100, 2) AS reactivation_rate_pct,
    ROUND(churned_count::NUMERIC / NULLIF(total_sent, 0) * 100, 2) AS churn_rate_pct,
    avg_days_to_reactivation
FROM campaign_metrics
ORDER BY reactivation_rate_pct DESC;

-- ----------------------------------------------------------------------------
-- HEALTH SCORE DISTRIBUTION
-- ----------------------------------------------------------------------------
-- Visualize distribution of health scores

WITH score_buckets AS (
    SELECT
        CASE
            WHEN health_score >= 90 THEN '90-100 (Excellent)'
            WHEN health_score >= 80 THEN '80-89 (Very Good)'
            WHEN health_score >= 70 THEN '70-79 (Good)'
            WHEN health_score >= 60 THEN '60-69 (Fair)'
            WHEN health_score >= 50 THEN '50-59 (Poor)'
            WHEN health_score >= 40 THEN '40-49 (At Risk)'
            WHEN health_score >= 30 THEN '30-39 (Zombie)'
            WHEN health_score >= 20 THEN '20-29 (Critical)'
            ELSE '0-19 (Dead)'
        END AS score_range,
        custid,
        health_score
    FROM v_latest_customer_health
)
SELECT
    score_range,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER () * 100, 2) AS percentage,
    ROUND(AVG(health_score), 2) AS avg_score_in_bucket,
    REPEAT('█', (COUNT(*)::NUMERIC / MAX(COUNT(*)) OVER () * 50)::INT) AS visual_bar
FROM score_buckets
GROUP BY score_range
ORDER BY MIN(health_score) DESC;

-- ----------------------------------------------------------------------------
-- CUSTOMER SUCCESS WORKLOAD
-- ----------------------------------------------------------------------------
-- Customers requiring CSM attention

SELECT
    CASE
        WHEN s.monthly_revenue >= 100 AND chs.health_status = 'zombie' AND chs.days_as_zombie < 30 THEN 'P0 - High-value new zombie'
        WHEN s.monthly_revenue >= 100 AND chs.health_status = 'zombie' THEN 'P1 - High-value zombie'
        WHEN s.monthly_revenue >= 100 AND chs.health_status = 'at_risk' THEN 'P2 - High-value at-risk'
        WHEN chs.health_status = 'zombie' AND chs.reactivation_potential >= 70 THEN 'P3 - High potential zombie'
        WHEN chs.health_status = 'at_risk' AND chs.churn_risk_score >= 70 THEN 'P4 - High churn risk'
        ELSE 'P5 - Monitor'
    END AS priority,
    s.custid,
    s.plan_type,
    s.monthly_revenue,
    chs.health_status,
    chs.health_score,
    chs.churn_risk_score,
    chs.reactivation_potential,
    chs.days_as_zombie,
    chs.days_since_last_login,
    -- Check if intervention already sent
    (SELECT COUNT(*) FROM intervention_campaigns ic
     WHERE ic.custid = s.custid
       AND ic.sent_at >= CURRENT_TIMESTAMP - INTERVAL '7 days') AS recent_interventions,
    -- Last contact
    (SELECT MAX(sent_at) FROM intervention_campaigns ic
     WHERE ic.custid = s.custid) AS last_contact_at
FROM subscriptions s
JOIN v_latest_customer_health chs ON s.custid = chs.custid
WHERE s.status = 'active'
    AND chs.health_status IN ('at_risk', 'zombie')
    AND (
        s.monthly_revenue >= 100  -- High-value customers
        OR chs.reactivation_potential >= 70  -- High potential
        OR (chs.health_status = 'zombie' AND chs.days_as_zombie < 14)  -- New zombies
    )
ORDER BY
    CASE priority
        WHEN 'P0 - High-value new zombie' THEN 0
        WHEN 'P1 - High-value zombie' THEN 1
        WHEN 'P2 - High-value at-risk' THEN 2
        WHEN 'P3 - High potential zombie' THEN 3
        WHEN 'P4 - High churn risk' THEN 4
        ELSE 5
    END,
    s.monthly_revenue DESC
LIMIT 50;

-- ----------------------------------------------------------------------------
-- WEEKLY HEALTH TREND
-- ----------------------------------------------------------------------------
-- Track how overall customer health is trending

WITH weekly_stats AS (
    SELECT
        DATE_TRUNC('week', calculated_at) AS week_start,
        ROUND(AVG(health_score), 2) AS avg_health_score,
        ROUND(AVG(churn_risk_score), 2) AS avg_churn_risk,
        COUNT(*) FILTER (WHERE health_status = 'zombie') AS zombie_count,
        COUNT(*) FILTER (WHERE health_status = 'at_risk') AS at_risk_count,
        COUNT(*) FILTER (WHERE health_status = 'healthy') AS healthy_count
    FROM customer_health_scores
    WHERE calculated_at >= CURRENT_TIMESTAMP - INTERVAL '12 weeks'
    GROUP BY DATE_TRUNC('week', calculated_at)
)
SELECT
    week_start,
    avg_health_score,
    avg_churn_risk,
    zombie_count,
    at_risk_count,
    healthy_count,
    -- Week-over-week change
    avg_health_score - LAG(avg_health_score) OVER (ORDER BY week_start) AS health_score_change,
    zombie_count - LAG(zombie_count) OVER (ORDER BY week_start) AS zombie_count_change,
    -- Trend indicator
    CASE
        WHEN avg_health_score > LAG(avg_health_score) OVER (ORDER BY week_start) THEN '↗ Improving'
        WHEN avg_health_score < LAG(avg_health_score) OVER (ORDER BY week_start) THEN '↘ Declining'
        ELSE '→ Stable'
    END AS trend
FROM weekly_stats
ORDER BY week_start DESC;

-- ----------------------------------------------------------------------------
-- ALERT CONDITIONS
-- ----------------------------------------------------------------------------
-- Conditions that should trigger alerts to CS team

SELECT
    'ALERT' AS type,
    CASE alert_condition
        WHEN 'spike_new_zombies' THEN 'CRITICAL'
        WHEN 'high_revenue_zombie' THEN 'HIGH'
        WHEN 'zombie_approaching_90d' THEN 'MEDIUM'
        ELSE 'LOW'
    END AS severity,
    alert_condition,
    alert_message,
    affected_count,
    revenue_impact,
    recommended_action
FROM (
    -- Alert 1: Spike in new zombies (>20% increase WoW)
    SELECT
        'spike_new_zombies' AS alert_condition,
        'New zombie count increased by ' || ROUND(((this_week - last_week)::NUMERIC / NULLIF(last_week, 0) * 100), 0)::TEXT || '% this week' AS alert_message,
        this_week AS affected_count,
        NULL::NUMERIC AS revenue_impact,
        'Investigate common patterns among new zombies' AS recommended_action
    FROM (
        SELECT
            COUNT(*) FILTER (WHERE event_timestamp >= DATE_TRUNC('week', CURRENT_TIMESTAMP)) AS this_week,
            COUNT(*) FILTER (WHERE event_timestamp >= DATE_TRUNC('week', CURRENT_TIMESTAMP) - INTERVAL '1 week'
                                AND event_timestamp < DATE_TRUNC('week', CURRENT_TIMESTAMP)) AS last_week
        FROM customer_lifecycle_events
        WHERE event_type = 'became_zombie'
    ) zombie_trend
    WHERE this_week > last_week * 1.2

    UNION ALL

    -- Alert 2: High-revenue customer became zombie
    SELECT
        'high_revenue_zombie' AS alert_condition,
        COUNT(*)::TEXT || ' high-value customer(s) became zombie in last 7 days' AS alert_message,
        COUNT(*) AS affected_count,
        SUM(s.monthly_revenue) AS revenue_impact,
        'Immediate CSM outreach required' AS recommended_action
    FROM customer_lifecycle_events cle
    JOIN subscriptions s ON cle.custid = s.custid
    WHERE cle.event_type = 'became_zombie'
        AND cle.event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
        AND s.monthly_revenue >= 100
    HAVING COUNT(*) > 0

    UNION ALL

    -- Alert 3: Zombies approaching 90-day mark
    SELECT
        'zombie_approaching_90d' AS alert_condition,
        COUNT(*)::TEXT || ' zombie customers approaching 90 days (low recovery chance)' AS alert_message,
        COUNT(*) AS affected_count,
        SUM(s.monthly_revenue) AS revenue_impact,
        'Consider sunset sequence or final winback attempt' AS recommended_action
    FROM v_latest_customer_health chs
    JOIN subscriptions s ON chs.custid = s.custid
    WHERE chs.health_status = 'zombie'
        AND chs.days_as_zombie BETWEEN 80 AND 89
        AND s.status = 'active'
    HAVING COUNT(*) > 0
) alerts
ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 0
        WHEN 'HIGH' THEN 1
        WHEN 'MEDIUM' THEN 2
        ELSE 3
    END;

-- ----------------------------------------------------------------------------
-- FEATURE ADOPTION GAPS (Zombie Prevention)
-- ----------------------------------------------------------------------------
-- Identify features that could prevent zombification if adopted

WITH zombie_features AS (
    SELECT
        fa.feature_name,
        COUNT(DISTINCT CASE WHEN chs.health_status = 'zombie' THEN fa.custid END) AS zombie_users,
        COUNT(DISTINCT CASE WHEN chs.health_status = 'healthy' THEN fa.custid END) AS healthy_users,
        COUNT(DISTINCT fa.custid) AS total_users
    FROM feature_adoption fa
    JOIN v_latest_customer_health chs ON fa.custid = chs.custid
    GROUP BY fa.feature_name
)
SELECT
    feature_name,
    healthy_users,
    zombie_users,
    total_users,
    ROUND(healthy_users::NUMERIC / NULLIF(total_users, 0) * 100, 2) AS healthy_adoption_pct,
    ROUND(zombie_users::NUMERIC / NULLIF(total_users, 0) * 100, 2) AS zombie_adoption_pct,
    ROUND((healthy_users::NUMERIC / NULLIF(total_users, 0)) / NULLIF((zombie_users::NUMERIC / NULLIF(total_users, 0)), 0), 2) AS healthy_to_zombie_ratio,
    CASE
        WHEN (healthy_users::NUMERIC / NULLIF(total_users, 0)) > (zombie_users::NUMERIC / NULLIF(total_users, 0)) * 2 THEN 'Sticky feature - promote heavily'
        WHEN (healthy_users::NUMERIC / NULLIF(total_users, 0)) > (zombie_users::NUMERIC / NULLIF(total_users, 0)) THEN 'Engagement driver - educate users'
        ELSE 'Low impact'
    END AS feature_category
FROM zombie_features
WHERE total_users >= 10  -- Minimum sample size
ORDER BY healthy_to_zombie_ratio DESC NULLS LAST;
