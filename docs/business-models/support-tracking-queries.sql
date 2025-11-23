-- ============================================================================
-- SUPPORT COST MODEL: SQL TRACKING QUERIES
-- ============================================================================
-- Purpose: Track actual vs modeled support costs across pricing tiers
-- Version: 1.0
-- Date: 2025-11-23
-- ============================================================================

-- Required Tables Schema (adjust to your actual schema):
-- - customers (id, tier, created_at, churned_at, mrr)
-- - support_tickets (id, customer_id, created_at, resolved_at, channel, tier_resolved)
-- - support_agents (id, name, tier, salary, start_date, end_date, geography)
-- - support_time_logs (id, ticket_id, agent_id, minutes_spent)

-- ============================================================================
-- 1. ACTUAL COST PER TICKET TRACKING
-- ============================================================================

-- 1.1 Calculate Actual Cost Per Ticket by Tier (Current Month)
WITH agent_costs AS (
    SELECT
        tier,
        COUNT(*) as agent_count,
        SUM(salary * 1.5) as total_annual_cost, -- 1.5x for benefits + overhead
        SUM(salary * 1.5) / 12 as monthly_cost,
        -- Assume 1,560 productive hours/year per agent
        (SUM(salary * 1.5) / 12) / (COUNT(*) * 130) as hourly_cost -- 130 hours/month per agent
    FROM support_agents
    WHERE end_date IS NULL OR end_date > CURRENT_DATE
    GROUP BY tier
),
ticket_time AS (
    SELECT
        st.id as ticket_id,
        st.tier_resolved,
        SUM(stl.minutes_spent) / 60.0 as hours_spent
    FROM support_tickets st
    JOIN support_time_logs stl ON st.id = stl.ticket_id
    WHERE DATE_TRUNC('month', st.created_at) = DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY st.id, st.tier_resolved
)
SELECT
    tt.tier_resolved as support_tier,
    COUNT(tt.ticket_id) as ticket_count,
    ROUND(AVG(tt.hours_spent), 2) as avg_hours_per_ticket,
    ROUND(ac.hourly_cost, 2) as hourly_cost,
    ROUND(AVG(tt.hours_spent) * ac.hourly_cost, 2) as actual_cost_per_ticket,
    -- Model expectations
    CASE tt.tier_resolved
        WHEN 'L1' THEN 15.29
        WHEN 'L2' THEN 33.80
        WHEN 'L3' THEN 68.60
    END as modeled_cost_per_ticket,
    -- Variance
    ROUND(
        (AVG(tt.hours_spent) * ac.hourly_cost -
         CASE tt.tier_resolved
            WHEN 'L1' THEN 15.29
            WHEN 'L2' THEN 33.80
            WHEN 'L3' THEN 68.60
         END) /
        CASE tt.tier_resolved
            WHEN 'L1' THEN 15.29
            WHEN 'L2' THEN 33.80
            WHEN 'L3' THEN 68.60
        END * 100,
    1) as variance_pct
FROM ticket_time tt
JOIN agent_costs ac ON tt.tier_resolved = ac.tier
GROUP BY tt.tier_resolved, ac.hourly_cost
ORDER BY tt.tier_resolved;

-- ============================================================================
-- 2. TICKETS PER CUSTOMER BY TIER
-- ============================================================================

-- 2.1 Actual Tickets per Customer (Monthly Average, Last 90 Days)
WITH active_customers AS (
    SELECT
        id,
        tier,
        created_at
    FROM customers
    WHERE churned_at IS NULL
        AND created_at < CURRENT_DATE - INTERVAL '90 days'
),
customer_tickets AS (
    SELECT
        c.id as customer_id,
        c.tier,
        COUNT(st.id) / 3.0 as avg_monthly_tickets -- 3 months of data
    FROM active_customers c
    LEFT JOIN support_tickets st
        ON c.id = st.customer_id
        AND st.created_at >= CURRENT_DATE - INTERVAL '90 days'
    GROUP BY c.id, c.tier
)
SELECT
    tier,
    COUNT(customer_id) as customer_count,
    ROUND(AVG(avg_monthly_tickets), 2) as actual_avg_tickets_per_month,
    -- Model expectations
    CASE tier
        WHEN 'individual' THEN 0.5
        WHEN 'team' THEN 1.5
        WHEN 'enterprise_multi' THEN 3.0
        WHEN 'enterprise_single' THEN 5.0
    END as modeled_tickets_per_month,
    -- Variance
    ROUND(
        (AVG(avg_monthly_tickets) -
         CASE tier
            WHEN 'individual' THEN 0.5
            WHEN 'team' THEN 1.5
            WHEN 'enterprise_multi' THEN 3.0
            WHEN 'enterprise_single' THEN 5.0
         END) /
        CASE tier
            WHEN 'individual' THEN 0.5
            WHEN 'team' THEN 1.5
            WHEN 'enterprise_multi' THEN 3.0
            WHEN 'enterprise_single' THEN 5.0
        END * 100,
    1) as variance_pct,
    -- Percentile distribution
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY avg_monthly_tickets), 2) as p25_tickets,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY avg_monthly_tickets), 2) as p50_tickets,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY avg_monthly_tickets), 2) as p75_tickets,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY avg_monthly_tickets), 2) as p90_tickets
FROM customer_tickets
GROUP BY tier
ORDER BY
    CASE tier
        WHEN 'individual' THEN 1
        WHEN 'team' THEN 2
        WHEN 'enterprise_multi' THEN 3
        WHEN 'enterprise_single' THEN 4
    END;

-- ============================================================================
-- 3. SUPPORT COST AS % OF REVENUE BY TIER
-- ============================================================================

-- 3.1 Monthly Support Economics Dashboard
WITH monthly_revenue AS (
    SELECT
        tier,
        COUNT(*) as customer_count,
        SUM(mrr) as total_mrr
    FROM customers
    WHERE churned_at IS NULL
    GROUP BY tier
),
monthly_ticket_cost AS (
    SELECT
        c.tier,
        COUNT(st.id) as ticket_count,
        -- Simplified cost calculation (adjust with actual labor costs)
        SUM(
            CASE st.tier_resolved
                WHEN 'L1' THEN 15.29
                WHEN 'L2' THEN 33.80
                WHEN 'L3' THEN 68.60
                ELSE 20.00
            END
        ) as total_ticket_cost
    FROM support_tickets st
    JOIN customers c ON st.customer_id = c.id
    WHERE DATE_TRUNC('month', st.created_at) = DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY c.tier
)
SELECT
    mr.tier,
    mr.customer_count,
    mr.total_mrr as monthly_revenue,
    COALESCE(mtc.ticket_count, 0) as tickets_this_month,
    COALESCE(mtc.total_ticket_cost, 0) as monthly_support_cost,
    ROUND(
        COALESCE(mtc.total_ticket_cost, 0) / NULLIF(mr.total_mrr, 0) * 100,
    1) as support_cost_pct_of_revenue,
    -- Model expectations
    CASE mr.tier
        WHEN 'individual' THEN 15.9
        WHEN 'team' THEN 32.9
        WHEN 'enterprise_multi' THEN 62.0
        WHEN 'enterprise_single' THEN 46.4
    END as modeled_support_cost_pct,
    -- Variance
    ROUND(
        COALESCE(mtc.total_ticket_cost, 0) / NULLIF(mr.total_mrr, 0) * 100 -
        CASE mr.tier
            WHEN 'individual' THEN 15.9
            WHEN 'team' THEN 32.9
            WHEN 'enterprise_multi' THEN 62.0
            WHEN 'enterprise_single' THEN 46.4
        END,
    1) as variance_pct_points,
    -- Status flag
    CASE
        WHEN COALESCE(mtc.total_ticket_cost, 0) / NULLIF(mr.total_mrr, 0) * 100 >
             CASE mr.tier
                WHEN 'individual' THEN 20
                WHEN 'team' THEN 40
                WHEN 'enterprise_multi' THEN 75
                WHEN 'enterprise_single' THEN 55
             END
        THEN '🚨 DANGER ZONE'
        WHEN COALESCE(mtc.total_ticket_cost, 0) / NULLIF(mr.total_mrr, 0) * 100 >
             CASE mr.tier
                WHEN 'individual' THEN 18
                WHEN 'team' THEN 38
                WHEN 'enterprise_multi' THEN 70
                WHEN 'enterprise_single' THEN 52
             END
        THEN '⚠️ WARNING'
        ELSE '✅ HEALTHY'
    END as status
FROM monthly_revenue mr
LEFT JOIN monthly_ticket_cost mtc ON mr.tier = mtc.tier
ORDER BY
    CASE mr.tier
        WHEN 'individual' THEN 1
        WHEN 'team' THEN 2
        WHEN 'enterprise_multi' THEN 3
        WHEN 'enterprise_single' THEN 4
    END;

-- ============================================================================
-- 4. SELF-SERVICE DEFLECTION TRACKING
-- ============================================================================

-- 4.1 Deflection Rate by Tier (requires knowledge base view tracking)
-- Assumes you track KB article views in a kb_views table
WITH kb_sessions AS (
    SELECT
        c.tier,
        COUNT(DISTINCT kv.session_id) as kb_sessions,
        DATE_TRUNC('month', kv.viewed_at) as month
    FROM kb_views kv
    JOIN customers c ON kv.customer_id = c.id
    WHERE kv.viewed_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY c.tier, DATE_TRUNC('month', kv.viewed_at)
),
ticket_sessions AS (
    SELECT
        c.tier,
        COUNT(DISTINCT st.id) as ticket_count,
        DATE_TRUNC('month', st.created_at) as month
    FROM support_tickets st
    JOIN customers c ON st.customer_id = c.id
    WHERE st.created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY c.tier, DATE_TRUNC('month', st.created_at)
)
SELECT
    COALESCE(kb.tier, t.tier) as tier,
    COALESCE(kb.kb_sessions, 0) as kb_views,
    COALESCE(t.ticket_count, 0) as tickets_created,
    COALESCE(kb.kb_sessions, 0) + COALESCE(t.ticket_count, 0) as total_support_interactions,
    ROUND(
        COALESCE(kb.kb_sessions, 0)::NUMERIC /
        NULLIF(COALESCE(kb.kb_sessions, 0) + COALESCE(t.ticket_count, 0), 0) * 100,
    1) as actual_deflection_rate,
    -- Model expectations
    CASE COALESCE(kb.tier, t.tier)
        WHEN 'individual' THEN 60.0
        WHEN 'team' THEN 45.0
        WHEN 'enterprise_multi' THEN 35.0
        WHEN 'enterprise_single' THEN 20.0
    END as modeled_deflection_rate,
    -- Variance
    ROUND(
        COALESCE(kb.kb_sessions, 0)::NUMERIC /
        NULLIF(COALESCE(kb.kb_sessions, 0) + COALESCE(t.ticket_count, 0), 0) * 100 -
        CASE COALESCE(kb.tier, t.tier)
            WHEN 'individual' THEN 60.0
            WHEN 'team' THEN 45.0
            WHEN 'enterprise_multi' THEN 35.0
            WHEN 'enterprise_single' THEN 20.0
        END,
    1) as variance_pct_points
FROM kb_sessions kb
FULL OUTER JOIN ticket_sessions t ON kb.tier = t.tier AND kb.month = t.month
ORDER BY
    CASE COALESCE(kb.tier, t.tier)
        WHEN 'individual' THEN 1
        WHEN 'team' THEN 2
        WHEN 'enterprise_multi' THEN 3
        WHEN 'enterprise_single' THEN 4
    END;

-- ============================================================================
-- 5. ESCALATION RATE TRACKING
-- ============================================================================

-- 5.1 L1 → L2 → L3 Escalation Funnel
WITH ticket_escalations AS (
    SELECT
        st.id as ticket_id,
        MIN(CASE WHEN stl.agent_id IN (SELECT id FROM support_agents WHERE tier = 'L1') THEN 1 ELSE 0 END) as touched_l1,
        MIN(CASE WHEN stl.agent_id IN (SELECT id FROM support_agents WHERE tier = 'L2') THEN 1 ELSE 0 END) as touched_l2,
        MIN(CASE WHEN stl.agent_id IN (SELECT id FROM support_agents WHERE tier = 'L3') THEN 1 ELSE 0 END) as touched_l3
    FROM support_tickets st
    JOIN support_time_logs stl ON st.id = stl.ticket_id
    WHERE st.created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY st.id
)
SELECT
    COUNT(*) as total_tickets,
    SUM(touched_l1) as l1_tickets,
    SUM(touched_l2) as l2_tickets,
    SUM(touched_l3) as l3_tickets,
    -- Escalation rates
    ROUND(SUM(touched_l2)::NUMERIC / NULLIF(SUM(touched_l1), 0) * 100, 1) as actual_l1_to_l2_rate,
    15.0 as modeled_l1_to_l2_rate,
    ROUND(SUM(touched_l3)::NUMERIC / NULLIF(SUM(touched_l2), 0) * 100, 1) as actual_l2_to_l3_rate,
    10.0 as modeled_l2_to_l3_rate,
    -- Variance
    ROUND(
        (SUM(touched_l2)::NUMERIC / NULLIF(SUM(touched_l1), 0) * 100) - 15.0,
    1) as l1_to_l2_variance_ppt,
    ROUND(
        (SUM(touched_l3)::NUMERIC / NULLIF(SUM(touched_l2), 0) * 100) - 10.0,
    1) as l2_to_l3_variance_ppt
FROM ticket_escalations;

-- ============================================================================
-- 6. CHANNEL MIX TRACKING
-- ============================================================================

-- 6.1 Channel Distribution by Tier vs Model
WITH channel_distribution AS (
    SELECT
        c.tier,
        st.channel,
        COUNT(*) as ticket_count,
        ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER (PARTITION BY c.tier) * 100, 1) as actual_pct
    FROM support_tickets st
    JOIN customers c ON st.customer_id = c.id
    WHERE st.created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY c.tier, st.channel
),
expected_mix AS (
    SELECT tier, channel, expected_pct FROM (VALUES
        ('individual', 'email', 80.0),
        ('individual', 'chat', 15.0),
        ('individual', 'phone', 5.0),
        ('team', 'email', 60.0),
        ('team', 'chat', 30.0),
        ('team', 'phone', 10.0),
        ('enterprise_multi', 'email', 40.0),
        ('enterprise_multi', 'chat', 35.0),
        ('enterprise_multi', 'phone', 20.0),
        ('enterprise_multi', 'slack', 5.0),
        ('enterprise_single', 'slack', 40.0),
        ('enterprise_single', 'phone', 30.0),
        ('enterprise_single', 'email', 20.0),
        ('enterprise_single', 'video', 10.0)
    ) AS t(tier, channel, expected_pct)
)
SELECT
    cd.tier,
    cd.channel,
    cd.ticket_count,
    cd.actual_pct,
    em.expected_pct as modeled_pct,
    ROUND(cd.actual_pct - em.expected_pct, 1) as variance_ppt,
    CASE
        WHEN ABS(cd.actual_pct - em.expected_pct) > 15 THEN '🚨 HIGH VARIANCE'
        WHEN ABS(cd.actual_pct - em.expected_pct) > 10 THEN '⚠️ MEDIUM VARIANCE'
        ELSE '✅ ON TARGET'
    END as status
FROM channel_distribution cd
LEFT JOIN expected_mix em ON cd.tier = em.tier AND cd.channel = em.channel
ORDER BY cd.tier, cd.actual_pct DESC;

-- ============================================================================
-- 7. AGENT PRODUCTIVITY TRACKING
-- ============================================================================

-- 7.1 Tickets per Agent per Day
WITH agent_daily_tickets AS (
    SELECT
        sa.id as agent_id,
        sa.name as agent_name,
        sa.tier as agent_tier,
        DATE(st.created_at) as ticket_date,
        COUNT(DISTINCT st.id) as tickets_handled
    FROM support_agents sa
    JOIN support_time_logs stl ON sa.id = stl.agent_id
    JOIN support_tickets st ON stl.ticket_id = st.id
    WHERE st.created_at >= CURRENT_DATE - INTERVAL '30 days'
        AND (sa.end_date IS NULL OR sa.end_date > CURRENT_DATE)
    GROUP BY sa.id, sa.name, sa.tier, DATE(st.created_at)
)
SELECT
    agent_tier,
    COUNT(DISTINCT agent_id) as agent_count,
    ROUND(AVG(tickets_handled), 1) as avg_tickets_per_day,
    21.0 as modeled_tickets_per_day,
    ROUND(AVG(tickets_handled) - 21.0, 1) as variance,
    ROUND((AVG(tickets_handled) - 21.0) / 21.0 * 100, 1) as variance_pct,
    -- Distribution
    ROUND(MIN(tickets_handled), 1) as min_tickets,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY tickets_handled), 1) as p25_tickets,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY tickets_handled), 1) as median_tickets,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY tickets_handled), 1) as p75_tickets,
    ROUND(MAX(tickets_handled), 1) as max_tickets
FROM agent_daily_tickets
GROUP BY agent_tier
ORDER BY agent_tier;

-- ============================================================================
-- 8. HIRING TRIGGER ALERTS
-- ============================================================================

-- 8.1 Current Customer Count vs Hiring Milestones
WITH customer_counts AS (
    SELECT
        tier,
        COUNT(*) as customer_count
    FROM customers
    WHERE churned_at IS NULL
    GROUP BY tier
),
hiring_triggers AS (
    SELECT trigger_name, customer_threshold, action_needed FROM (VALUES
        ('First Agent', 400, 'Hire L1 Support Agent #1'),
        ('Second Agent', 800, 'Hire L1 Support Agent #2'),
        ('Team Lead', 1500, 'Hire or promote L2/L3 Team Lead'),
        ('Build Team', 2000, 'Hire Agents #3-4'),
        ('First Manager', 3500, 'Hire Support Manager'),
        ('Scale Department', 7500, 'Hire Director of Support')
    ) AS t(trigger_name, customer_threshold, action_needed)
)
SELECT
    ht.trigger_name,
    ht.customer_threshold,
    ht.action_needed,
    (SELECT SUM(customer_count) FROM customer_counts) as current_total_customers,
    CASE
        WHEN (SELECT SUM(customer_count) FROM customer_counts) >= ht.customer_threshold
        THEN '🚨 ACTION REQUIRED'
        WHEN (SELECT SUM(customer_count) FROM customer_counts) >= ht.customer_threshold * 0.8
        THEN '⚠️ APPROACHING THRESHOLD'
        ELSE '✅ NOT YET'
    END as status,
    ht.customer_threshold - (SELECT SUM(customer_count) FROM customer_counts) as customers_until_trigger
FROM hiring_triggers ht
ORDER BY ht.customer_threshold;

-- ============================================================================
-- 9. DANGER ZONE MONITORING
-- ============================================================================

-- 9.1 Comprehensive Danger Zone Alert System
WITH metrics AS (
    SELECT
        c.tier,
        COUNT(DISTINCT c.id) as customer_count,
        SUM(c.mrr) as total_mrr,
        COUNT(st.id) as ticket_count_30d,
        COALESCE(
            SUM(
                CASE st.tier_resolved
                    WHEN 'L1' THEN 15.29
                    WHEN 'L2' THEN 33.80
                    WHEN 'L3' THEN 68.60
                    ELSE 20.00
                END
            ),
        0) as support_cost_30d
    FROM customers c
    LEFT JOIN support_tickets st ON c.id = st.customer_id
        AND st.created_at >= CURRENT_DATE - INTERVAL '30 days'
    WHERE c.churned_at IS NULL
    GROUP BY c.tier
)
SELECT
    tier,
    customer_count,
    total_mrr,
    support_cost_30d,
    ROUND(support_cost_30d / NULLIF(total_mrr, 0) * 100, 1) as support_cost_pct,
    -- Danger zone thresholds
    CASE
        -- Enterprise Multi at $150/mo pricing
        WHEN tier = 'enterprise_multi' AND support_cost_30d / NULLIF(total_mrr, 0) > 0.75
        THEN '🚨 DANGER ZONE 2: Enterprise Multi pricing unsustainable'

        -- Overall support cost >25%
        WHEN support_cost_30d / NULLIF(total_mrr, 0) > 0.25
        THEN '🚨 DANGER ZONE 5: Support cost >25% of revenue'

        -- Warning levels
        WHEN tier = 'enterprise_multi' AND support_cost_30d / NULLIF(total_mrr, 0) > 0.65
        THEN '⚠️ WARNING: Enterprise Multi approaching danger zone'

        WHEN support_cost_30d / NULLIF(total_mrr, 0) > 0.20
        THEN '⚠️ WARNING: Support costs elevated'

        ELSE '✅ HEALTHY'
    END as danger_zone_status,
    -- Recommended actions
    CASE
        WHEN tier = 'enterprise_multi' AND support_cost_30d / NULLIF(total_mrr, 0) > 0.65
        THEN 'RECOMMENDATION: Increase Enterprise Multi pricing to $250/mo or invest in automation'

        WHEN support_cost_30d / NULLIF(total_mrr, 0) > 0.25
        THEN 'RECOMMENDATION: Immediate cost reduction or pricing increase required'

        WHEN support_cost_30d / NULLIF(total_mrr, 0) > 0.20
        THEN 'RECOMMENDATION: Review customer mix and implement AI chatbot'

        ELSE 'No action needed'
    END as recommendation
FROM metrics
ORDER BY support_cost_pct DESC;

-- ============================================================================
-- 10. EXECUTIVE DASHBOARD - WEEKLY SUMMARY
-- ============================================================================

-- 10.1 Weekly Executive Summary
WITH weekly_metrics AS (
    SELECT
        DATE_TRUNC('week', st.created_at) as week,
        COUNT(*) as tickets,
        COUNT(DISTINCT st.customer_id) as customers_with_tickets,
        AVG(EXTRACT(EPOCH FROM (st.resolved_at - st.created_at)) / 3600) as avg_resolution_hours,
        SUM(
            CASE st.tier_resolved
                WHEN 'L1' THEN 15.29
                WHEN 'L2' THEN 33.80
                WHEN 'L3' THEN 68.60
                ELSE 20.00
            END
        ) as total_cost
    FROM support_tickets st
    WHERE st.created_at >= CURRENT_DATE - INTERVAL '12 weeks'
    GROUP BY DATE_TRUNC('week', st.created_at)
),
customer_metrics AS (
    SELECT
        DATE_TRUNC('week', CURRENT_DATE) as week,
        COUNT(*) as total_customers,
        SUM(mrr) as total_mrr
    FROM customers
    WHERE churned_at IS NULL
)
SELECT
    wm.week,
    wm.tickets,
    wm.customers_with_tickets,
    cm.total_customers,
    ROUND(wm.customers_with_tickets::NUMERIC / cm.total_customers * 100, 1) as pct_customers_with_tickets,
    ROUND(wm.avg_resolution_hours, 1) as avg_resolution_hours,
    wm.total_cost as weekly_support_cost,
    cm.total_mrr * (7.0/30.0) as weekly_revenue_estimate,
    ROUND(wm.total_cost / (cm.total_mrr * (7.0/30.0)) * 100, 1) as support_cost_pct_of_revenue,
    -- Week-over-week changes
    ROUND(
        (wm.tickets - LAG(wm.tickets) OVER (ORDER BY wm.week))::NUMERIC /
        NULLIF(LAG(wm.tickets) OVER (ORDER BY wm.week), 0) * 100,
    1) as ticket_growth_pct,
    ROUND(
        (wm.total_cost - LAG(wm.total_cost) OVER (ORDER BY wm.week))::NUMERIC /
        NULLIF(LAG(wm.total_cost) OVER (ORDER BY wm.week), 0) * 100,
    1) as cost_growth_pct
FROM weekly_metrics wm
CROSS JOIN customer_metrics cm
ORDER BY wm.week DESC
LIMIT 12;

-- ============================================================================
-- 11. COHORT ANALYSIS - SUPPORT COSTS BY CUSTOMER AGE
-- ============================================================================

-- 11.1 Support Costs by Customer Tenure Cohort
WITH customer_cohorts AS (
    SELECT
        c.id,
        c.tier,
        c.mrr,
        CASE
            WHEN CURRENT_DATE - c.created_at < INTERVAL '30 days' THEN '0-30 days'
            WHEN CURRENT_DATE - c.created_at < INTERVAL '90 days' THEN '31-90 days'
            WHEN CURRENT_DATE - c.created_at < INTERVAL '180 days' THEN '91-180 days'
            WHEN CURRENT_DATE - c.created_at < INTERVAL '365 days' THEN '181-365 days'
            ELSE '365+ days'
        END as tenure_cohort
    FROM customers c
    WHERE c.churned_at IS NULL
),
cohort_tickets AS (
    SELECT
        cc.tenure_cohort,
        cc.tier,
        COUNT(DISTINCT cc.id) as customers,
        COUNT(st.id) as tickets,
        SUM(
            CASE st.tier_resolved
                WHEN 'L1' THEN 15.29
                WHEN 'L2' THEN 33.80
                WHEN 'L3' THEN 68.60
                ELSE 20.00
            END
        ) as support_cost
    FROM customer_cohorts cc
    LEFT JOIN support_tickets st ON cc.id = st.customer_id
        AND st.created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY cc.tenure_cohort, cc.tier
)
SELECT
    tenure_cohort,
    tier,
    customers,
    tickets,
    ROUND(tickets::NUMERIC / customers, 2) as tickets_per_customer,
    ROUND(support_cost / customers, 2) as support_cost_per_customer,
    -- Insight: New customers typically have higher support needs
    CASE
        WHEN tenure_cohort = '0-30 days' AND tickets::NUMERIC / customers > 2.0
        THEN '⚠️ High onboarding support load'
        WHEN tenure_cohort IN ('365+ days') AND tickets::NUMERIC / customers > 1.5
        THEN '⚠️ Power users or struggling customers - investigate'
        ELSE '✅ Normal'
    END as status
FROM cohort_tickets
ORDER BY
    CASE tenure_cohort
        WHEN '0-30 days' THEN 1
        WHEN '31-90 days' THEN 2
        WHEN '91-180 days' THEN 3
        WHEN '181-365 days' THEN 4
        WHEN '365+ days' THEN 5
    END,
    tier;

-- ============================================================================
-- 12. TOP CUSTOMERS BY SUPPORT COST (OUTLIER DETECTION)
-- ============================================================================

-- 12.1 Identify Top 10% Costliest Customers
WITH customer_support_costs AS (
    SELECT
        c.id,
        c.tier,
        c.mrr,
        COUNT(st.id) as ticket_count_90d,
        SUM(
            CASE st.tier_resolved
                WHEN 'L1' THEN 15.29
                WHEN 'L2' THEN 33.80
                WHEN 'L3' THEN 68.60
                ELSE 20.00
            END
        ) as support_cost_90d,
        ROUND(
            SUM(
                CASE st.tier_resolved
                    WHEN 'L1' THEN 15.29
                    WHEN 'L2' THEN 33.80
                    WHEN 'L3' THEN 68.60
                    ELSE 20.00
                END
            ) / (c.mrr * 3) * 100,
        1) as support_cost_pct_of_revenue
    FROM customers c
    LEFT JOIN support_tickets st ON c.id = st.customer_id
        AND st.created_at >= CURRENT_DATE - INTERVAL '90 days'
    WHERE c.churned_at IS NULL
    GROUP BY c.id, c.tier, c.mrr
)
SELECT
    id as customer_id,
    tier,
    mrr as monthly_revenue,
    ticket_count_90d,
    ROUND(support_cost_90d, 2) as support_cost_90d,
    support_cost_pct_of_revenue,
    CASE
        WHEN support_cost_pct_of_revenue > 100 THEN '🚨 UNPROFITABLE - Support cost exceeds revenue'
        WHEN support_cost_pct_of_revenue > 75 THEN '⚠️ HIGH RISK - Consider intervention'
        WHEN support_cost_pct_of_revenue > 50 THEN '⚠️ ELEVATED - Monitor closely'
        ELSE '✅ Normal'
    END as status,
    CASE
        WHEN support_cost_pct_of_revenue > 100
        THEN 'ACTION: Schedule call to address issues or consider offboarding'
        WHEN support_cost_pct_of_revenue > 75
        THEN 'ACTION: Proactive CSM outreach, training, or price increase'
        ELSE 'No action needed'
    END as recommended_action
FROM customer_support_costs
WHERE support_cost_pct_of_revenue > 50  -- Only show high-cost customers
ORDER BY support_cost_pct_of_revenue DESC
LIMIT 20;

-- ============================================================================
-- END OF SUPPORT TRACKING QUERIES
-- ============================================================================

-- USAGE NOTES:
-- 1. Schedule queries #3, #9, #10 to run weekly for executive dashboard
-- 2. Schedule queries #1, #2, #5, #6 to run daily for operational monitoring
-- 3. Run query #8 (hiring triggers) monthly during planning
-- 4. Run query #12 (outlier detection) bi-weekly to identify problem customers
-- 5. Adjust tier names and cost assumptions to match your actual implementation
-- 6. Create views for frequently-used queries to simplify dashboard creation

-- ALERTING RECOMMENDATIONS:
-- - Alert if support_cost_pct_of_revenue > 30% (blended) for 2+ consecutive weeks
-- - Alert if Enterprise Multi support_cost_pct > 70% for any month
-- - Alert if deflection rate drops >10 percentage points month-over-month
-- - Alert if L1→L2 escalation rate exceeds 20% for 2+ weeks
-- - Alert when approaching hiring trigger thresholds (80% of threshold)
