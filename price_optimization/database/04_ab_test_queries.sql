-- =============================================================================
-- PHASE 4: A/B Test SQL Queries
-- For experiment allocation, tracking, and analysis
-- =============================================================================

-- =============================================================================
-- CREATE NEW A/B TEST EXPERIMENT
-- =============================================================================

-- Insert new experiment (replace placeholders with actual values)
INSERT INTO ab_test_experiments (
    experiment_name,
    segment_id,
    tier_id,
    control_price,
    variant_prices,
    required_sample_size,
    statistical_power,
    significance_level,
    minimum_detectable_effect,
    start_date,
    planned_end_date,
    status,
    primary_metric,
    secondary_metrics,
    success_threshold,
    max_allowed_revenue_loss,
    auto_stop_enabled,
    created_by,
    hypothesis
) VALUES (
    'Starter Tier Price Test Q1 2025',
    (SELECT segment_id FROM market_segments WHERE segment_name = 'Individual Developers'),
    (SELECT tier_id FROM product_tiers WHERE tier_name = 'Starter'),
    900,  -- $9 control
    ARRAY[700, 1100],  -- $7 and $11 variants
    3840,  -- Calculated sample size
    0.80,  -- 80% power
    0.05,  -- 5% significance
    0.15,  -- 15% minimum detectable effect
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP + INTERVAL '30 days',
    'active',
    'revenue_per_visitor',
    ARRAY['conversion_rate', 'churn_rate'],
    1.10,  -- 10% improvement threshold
    50000,  -- Max $500 loss
    TRUE,
    'pricing_team',
    'Lower price ($7) will increase conversion enough to offset revenue per customer'
);

-- =============================================================================
-- ASSIGN USER TO TEST GROUP
-- =============================================================================

-- Deterministic assignment using hash (consistent across sessions)
CREATE OR REPLACE FUNCTION assign_to_test_group(
    p_experiment_id UUID,
    p_user_id_hash VARCHAR(64)
) RETURNS TABLE (
    test_group VARCHAR(50),
    assigned_price INTEGER
) AS $$
DECLARE
    v_variant_count INTEGER;
    v_hash_numeric BIGINT;
    v_group_index INTEGER;
    v_control_price INTEGER;
    v_variant_prices INTEGER[];
BEGIN
    -- Get experiment details
    SELECT
        e.control_price,
        e.variant_prices
    INTO v_control_price, v_variant_prices
    FROM ab_test_experiments e
    WHERE e.experiment_id = p_experiment_id
      AND e.status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No active experiment found';
    END IF;

    -- Convert hash to numeric (use last 16 chars)
    v_hash_numeric := ('x' || RIGHT(p_user_id_hash, 15))::BIT(60)::BIGINT;

    -- Total groups = 1 control + N variants
    v_variant_count := array_length(v_variant_prices, 1);

    -- Assign to group based on modulo (ensures uniform distribution)
    v_group_index := (v_hash_numeric % (v_variant_count + 1))::INTEGER;

    IF v_group_index = 0 THEN
        -- Control group
        RETURN QUERY SELECT 'control'::VARCHAR(50), v_control_price;
    ELSE
        -- Variant group
        RETURN QUERY SELECT
            ('variant_' || v_group_index::TEXT)::VARCHAR(50),
            v_variant_prices[v_group_index];
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Example usage:
/*
SELECT * FROM assign_to_test_group(
    'test0001-0001-0001-0001-000000000001'::UUID,
    encode(digest('user@example.com', 'sha256'), 'hex')
);
*/

-- =============================================================================
-- RECORD TEST ASSIGNMENT
-- =============================================================================

INSERT INTO ab_test_participants (
    experiment_id,
    user_id_hash,
    session_id,
    test_group,
    assigned_price,
    assignment_method,
    assignment_hash,
    assigned_at,
    user_properties
)
SELECT
    experiment_id,
    user_id_hash,
    session_id,
    test_group,
    assigned_price,
    'deterministic' AS assignment_method,
    user_id_hash AS assignment_hash,
    CURRENT_TIMESTAMP AS assigned_at,
    jsonb_build_object(
        'segment', segment_name,
        'tier', tier_name,
        'timestamp', CURRENT_TIMESTAMP
    ) AS user_properties
FROM (
    SELECT
        e.experiment_id,
        encode(digest($USER_EMAIL, 'sha256'), 'hex') AS user_id_hash,
        $SESSION_ID AS session_id,
        (assign_to_test_group(e.experiment_id, encode(digest($USER_EMAIL, 'sha256'), 'hex'))).*,
        ms.segment_name,
        pt.tier_name
    FROM ab_test_experiments e
    JOIN market_segments ms ON ms.segment_id = e.segment_id
    JOIN product_tiers pt ON pt.tier_id = e.tier_id
    WHERE e.status = 'active'
    LIMIT 1
) assignment
ON CONFLICT (experiment_id, user_id_hash)
DO NOTHING;  -- User already assigned

-- =============================================================================
-- RECORD TEST EVENTS (Conversion, Revenue, etc.)
-- =============================================================================

INSERT INTO ab_test_results (
    participant_id,
    experiment_id,
    event_type,
    event_timestamp,
    revenue_amount,
    viewed,
    clicked,
    signed_up,
    converted,
    time_on_page_seconds,
    pages_viewed,
    event_properties
) VALUES (
    $PARTICIPANT_ID,
    $EXPERIMENT_ID,
    'conversion',
    CURRENT_TIMESTAMP,
    $REVENUE_AMOUNT,  -- In cents
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    $TIME_ON_PAGE,
    $PAGES_VIEWED,
    jsonb_build_object(
        'price_shown', $PRICE_SHOWN,
        'payment_method', $PAYMENT_METHOD,
        'user_agent', $USER_AGENT
    )
);

-- =============================================================================
-- ANALYZE TEST RESULTS - Conversion Rate
-- =============================================================================

WITH test_groups AS (
    SELECT
        e.experiment_name,
        p.test_group,
        p.assigned_price,
        COUNT(DISTINCT p.participant_id) AS total_participants,
        COUNT(DISTINCT CASE WHEN r.converted = TRUE THEN p.participant_id END) AS conversions,
        SUM(r.revenue_amount) AS total_revenue,
        AVG(r.revenue_amount) AS avg_revenue_per_visitor
    FROM ab_test_experiments e
    JOIN ab_test_participants p ON p.experiment_id = e.experiment_id
    LEFT JOIN ab_test_results r ON r.participant_id = p.participant_id
        AND r.event_type = 'conversion'
    WHERE e.experiment_id = $EXPERIMENT_ID
    GROUP BY e.experiment_name, p.test_group, p.assigned_price
),
control_metrics AS (
    SELECT
        total_participants AS control_n,
        conversions AS control_conversions,
        total_revenue AS control_revenue,
        avg_revenue_per_visitor AS control_avg_revenue
    FROM test_groups
    WHERE test_group = 'control'
),
variant_metrics AS (
    SELECT
        test_group,
        assigned_price,
        total_participants AS variant_n,
        conversions AS variant_conversions,
        total_revenue AS variant_revenue,
        avg_revenue_per_visitor AS variant_avg_revenue
    FROM test_groups
    WHERE test_group != 'control'
)
SELECT
    v.test_group,
    v.assigned_price / 100.0 AS price_dollars,

    -- Sample sizes
    c.control_n,
    v.variant_n,

    -- Conversion rates
    ROUND((c.control_conversions::FLOAT / c.control_n)::NUMERIC, 4) AS control_conversion_rate,
    ROUND((v.variant_conversions::FLOAT / v.variant_n)::NUMERIC, 4) AS variant_conversion_rate,

    -- Conversion lift
    ROUND((
        (v.variant_conversions::FLOAT / v.variant_n) -
        (c.control_conversions::FLOAT / c.control_n)
    )::NUMERIC, 4) AS absolute_lift,

    ROUND((
        ((v.variant_conversions::FLOAT / v.variant_n) - (c.control_conversions::FLOAT / c.control_n)) /
        NULLIF((c.control_conversions::FLOAT / c.control_n), 0) * 100
    )::NUMERIC, 2) AS relative_lift_pct,

    -- Statistical significance (Z-test approximation)
    -- Z = (p1 - p2) / sqrt(p_pooled * (1 - p_pooled) * (1/n1 + 1/n2))
    ROUND((
        ABS(
            (v.variant_conversions::FLOAT / v.variant_n) -
            (c.control_conversions::FLOAT / c.control_n)
        ) /
        SQRT(
            ((c.control_conversions + v.variant_conversions)::FLOAT / (c.control_n + v.variant_n)) *
            (1 - ((c.control_conversions + v.variant_conversions)::FLOAT / (c.control_n + v.variant_n))) *
            (1.0 / c.control_n + 1.0 / v.variant_n)
        )
    )::NUMERIC, 4) AS z_statistic,

    -- Revenue metrics
    c.control_revenue / 100.0 AS control_revenue_dollars,
    v.variant_revenue / 100.0 AS variant_revenue_dollars,
    ROUND(c.control_avg_revenue / 100.0, 2) AS control_avg_revenue_dollars,
    ROUND(v.variant_avg_revenue / 100.0, 2) AS variant_avg_revenue_dollars,

    -- Revenue lift
    ROUND((v.variant_revenue - c.control_revenue) / 100.0, 2) AS revenue_lift_dollars,
    ROUND((
        (v.variant_revenue - c.control_revenue)::FLOAT /
        NULLIF(c.control_revenue, 0) * 100
    )::NUMERIC, 2) AS revenue_lift_pct

FROM variant_metrics v
CROSS JOIN control_metrics c
ORDER BY v.test_group;

-- =============================================================================
-- DETECT EARLY WINNER/LOSER (Sequential Testing)
-- =============================================================================

-- Check if variant is significantly worse (auto-stop condition)
WITH current_results AS (
    SELECT
        p.test_group,
        COUNT(DISTINCT p.participant_id) AS n,
        COUNT(DISTINCT CASE WHEN r.converted = TRUE THEN p.participant_id END) AS conversions,
        SUM(r.revenue_amount) AS revenue
    FROM ab_test_participants p
    LEFT JOIN ab_test_results r ON r.participant_id = p.participant_id
        AND r.event_type = 'conversion'
    WHERE p.experiment_id = $EXPERIMENT_ID
    GROUP BY p.test_group
),
control AS (
    SELECT n, conversions, revenue FROM current_results WHERE test_group = 'control'
),
variants AS (
    SELECT test_group, n, conversions, revenue FROM current_results WHERE test_group != 'control'
)
SELECT
    v.test_group,

    -- Revenue comparison
    v.revenue AS variant_revenue,
    c.revenue AS control_revenue,
    (c.revenue - v.revenue) AS revenue_loss,

    -- Should stop?
    CASE
        WHEN (c.revenue - v.revenue) > (SELECT max_allowed_revenue_loss FROM ab_test_experiments WHERE experiment_id = $EXPERIMENT_ID)
        THEN TRUE
        ELSE FALSE
    END AS should_auto_stop,

    -- Reason
    CASE
        WHEN (c.revenue - v.revenue) > (SELECT max_allowed_revenue_loss FROM ab_test_experiments WHERE experiment_id = $EXPERIMENT_ID)
        THEN 'Revenue loss exceeds threshold'
        ELSE NULL
    END AS stop_reason

FROM variants v
CROSS JOIN control c;

-- =============================================================================
-- BAYESIAN PROBABILITY OF BEING BEST
-- =============================================================================

-- Simplified Bayesian approach using Beta distribution for conversion rates
WITH test_data AS (
    SELECT
        p.test_group,
        COUNT(DISTINCT p.participant_id) AS n,
        COUNT(DISTINCT CASE WHEN r.converted = TRUE THEN p.participant_id END) AS conversions
    FROM ab_test_participants p
    LEFT JOIN ab_test_results r ON r.participant_id = p.participant_id
        AND r.event_type = 'conversion'
    WHERE p.experiment_id = $EXPERIMENT_ID
    GROUP BY p.test_group
)
SELECT
    test_group,
    n AS sample_size,
    conversions,
    ROUND((conversions::FLOAT / n)::NUMERIC, 4) AS conversion_rate,

    -- Beta distribution parameters (using Jeffrey's prior: Beta(0.5, 0.5))
    conversions + 0.5 AS alpha,
    (n - conversions) + 0.5 AS beta,

    -- Expected value (mean of Beta distribution)
    ROUND(((conversions + 0.5) / (n + 1.0))::NUMERIC, 4) AS expected_conversion_rate,

    -- 95% Credible interval
    -- Approximation: mean ± 1.96 * sqrt(alpha*beta / ((alpha+beta)^2 * (alpha+beta+1)))
    ROUND((
        ((conversions + 0.5) / (n + 1.0)) -
        1.96 * SQRT(
            ((conversions + 0.5) * (n - conversions + 0.5)) /
            (POW(n + 1.0, 2) * (n + 2.0))
        )
    )::NUMERIC, 4) AS credible_interval_lower,

    ROUND((
        ((conversions + 0.5) / (n + 1.0)) +
        1.96 * SQRT(
            ((conversions + 0.5) * (n - conversions + 0.5)) /
            (POW(n + 1.0, 2) * (n + 2.0))
        )
    )::NUMERIC, 4) AS credible_interval_upper

FROM test_data
ORDER BY expected_conversion_rate DESC;

-- =============================================================================
-- UPDATE EXPERIMENT STATUS
-- =============================================================================

-- Mark experiment as completed
UPDATE ab_test_experiments
SET
    status = 'completed',
    actual_end_date = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE experiment_id = $EXPERIMENT_ID;

-- =============================================================================
-- EXPORT RESULTS FOR REPORTING
-- =============================================================================

SELECT
    e.experiment_name,
    e.control_price / 100.0 AS control_price_dollars,
    p.test_group,
    p.assigned_price / 100.0 AS assigned_price_dollars,
    COUNT(DISTINCT p.participant_id) AS participants,
    COUNT(DISTINCT CASE WHEN r.viewed = TRUE THEN p.participant_id END) AS views,
    COUNT(DISTINCT CASE WHEN r.clicked = TRUE THEN p.participant_id END) AS clicks,
    COUNT(DISTINCT CASE WHEN r.converted = TRUE THEN p.participant_id END) AS conversions,
    ROUND(SUM(r.revenue_amount) / 100.0, 2) AS total_revenue_dollars,
    ROUND(AVG(r.revenue_amount) / 100.0, 2) AS avg_revenue_dollars,
    ROUND(AVG(r.time_on_page_seconds), 1) AS avg_time_on_page_sec
FROM ab_test_experiments e
JOIN ab_test_participants p ON p.experiment_id = e.experiment_id
LEFT JOIN ab_test_results r ON r.participant_id = p.participant_id
WHERE e.experiment_id = $EXPERIMENT_ID
GROUP BY e.experiment_name, e.control_price, p.test_group, p.assigned_price
ORDER BY p.test_group;
