-- ================================================================
-- A/B TEST ALLOCATION AND ANALYSIS QUERIES
-- Production-ready SQL for A/B testing framework
-- ================================================================

-- ================================================================
-- 1. TEST ALLOCATION QUERIES
-- ================================================================

-- Create new A/B test experiment
-- Usage: Fill in parameters and execute
INSERT INTO ab_test_experiments (
    experiment_name,
    experiment_type,
    product_tier,
    control_price,
    treatment_price,
    allocation_ratio,
    minimum_sample_size,
    target_statistical_power,
    significance_level,
    minimum_detectable_effect,
    status,
    start_date,
    end_date,
    primary_metric,
    success_threshold,
    created_by
) VALUES (
    'professional_tier_q1_2026',  -- Unique experiment name
    'price_point',                 -- Experiment type
    'professional',                -- Product tier
    299.00,                        -- Control price
    349.00,                        -- Treatment price
    0.5,                          -- 50/50 split
    2000,                         -- Minimum 2000 users per variant
    0.80,                         -- 80% statistical power
    0.05,                         -- 5% significance level
    0.05,                         -- Detect 5% change
    'draft',                      -- Initial status
    NULL,                         -- Start date (set when activating)
    NULL,                         -- End date (set when activating)
    'revenue',                    -- Primary metric
    0.10,                         -- Success threshold (10% revenue increase)
    'pricing_team'                -- Creator
);

-- Allocate user to experiment variant (deterministic based on session)
CREATE OR REPLACE FUNCTION assign_to_ab_test(
    p_experiment_id UUID,
    p_user_id VARCHAR(255),
    p_session_id VARCHAR(255),
    p_market_segment VARCHAR(100),
    p_geographic_region VARCHAR(50),
    p_device_type VARCHAR(20)
) RETURNS TABLE (
    variant VARCHAR(20),
    assigned_price DECIMAL(10,2)
) AS $$
DECLARE
    v_allocation_ratio DECIMAL(3,2);
    v_control_price DECIMAL(10,2);
    v_treatment_price DECIMAL(10,2);
    v_hash_value BIGINT;
    v_variant VARCHAR(20);
    v_assigned_price DECIMAL(10,2);
    v_existing_assignment UUID;
BEGIN
    -- Check if already assigned
    SELECT id INTO v_existing_assignment
    FROM ab_test_assignments
    WHERE experiment_id = p_experiment_id
      AND session_id = p_session_id;

    IF v_existing_assignment IS NOT NULL THEN
        -- Return existing assignment
        RETURN QUERY
        SELECT
            ab_test_assignments.variant,
            ab_test_assignments.assigned_price
        FROM ab_test_assignments
        WHERE id = v_existing_assignment;
        RETURN;
    END IF;

    -- Get experiment configuration
    SELECT allocation_ratio, control_price, treatment_price
    INTO v_allocation_ratio, v_control_price, v_treatment_price
    FROM ab_test_experiments
    WHERE id = p_experiment_id
      AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Experiment % not found or not active', p_experiment_id;
    END IF;

    -- Hash session ID for deterministic assignment
    v_hash_value := abs(hashtext(p_session_id));

    -- Assign variant based on hash modulo
    IF (v_hash_value % 100) < (v_allocation_ratio * 100) THEN
        v_variant := 'control';
        v_assigned_price := v_control_price;
    ELSE
        v_variant := 'treatment';
        v_assigned_price := v_treatment_price;
    END IF;

    -- Insert assignment
    INSERT INTO ab_test_assignments (
        experiment_id,
        user_id,
        session_id,
        variant,
        assigned_price,
        market_segment,
        geographic_region,
        device_type
    ) VALUES (
        p_experiment_id,
        p_user_id,
        p_session_id,
        v_variant,
        v_assigned_price,
        p_market_segment,
        p_geographic_region,
        p_device_type
    );

    -- Return assignment
    RETURN QUERY SELECT v_variant, v_assigned_price;
END;
$$ LANGUAGE plpgsql;

-- Record A/B test result (conversion or abandonment)
CREATE OR REPLACE FUNCTION record_ab_test_result(
    p_assignment_id UUID,
    p_converted BOOLEAN,
    p_revenue DECIMAL(10,2) DEFAULT 0,
    p_page_views INTEGER DEFAULT 0,
    p_time_on_page_seconds INTEGER DEFAULT 0,
    p_clicked_cta BOOLEAN DEFAULT FALSE,
    p_abandoned BOOLEAN DEFAULT FALSE,
    p_abandon_reason VARCHAR(100) DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    -- Insert or update result
    INSERT INTO ab_test_results (
        experiment_id,
        assignment_id,
        converted,
        revenue,
        conversion_timestamp,
        page_views,
        time_on_page_seconds,
        clicked_cta,
        abandoned,
        abandon_reason
    )
    SELECT
        a.experiment_id,
        p_assignment_id,
        p_converted,
        p_revenue,
        CASE WHEN p_converted THEN NOW() ELSE NULL END,
        p_page_views,
        p_time_on_page_seconds,
        p_clicked_cta,
        p_abandoned,
        p_abandon_reason
    FROM ab_test_assignments a
    WHERE a.id = p_assignment_id
    ON CONFLICT (assignment_id)
    DO UPDATE SET
        converted = EXCLUDED.converted,
        revenue = EXCLUDED.revenue,
        conversion_timestamp = EXCLUDED.conversion_timestamp,
        page_views = EXCLUDED.page_views,
        time_on_page_seconds = EXCLUDED.time_on_page_seconds,
        clicked_cta = EXCLUDED.clicked_cta,
        abandoned = EXCLUDED.abandoned,
        abandon_reason = EXCLUDED.abandon_reason;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- 2. REAL-TIME ANALYSIS QUERIES
-- ================================================================

-- Get current test performance by variant
CREATE OR REPLACE VIEW vw_ab_test_current_performance AS
SELECT
    e.id AS experiment_id,
    e.experiment_name,
    e.product_tier,
    e.status,
    a.variant,
    a.assigned_price,

    -- Sample sizes
    COUNT(DISTINCT a.id) AS total_assigned,
    COUNT(DISTINCT r.id) AS total_responded,

    -- Conversion metrics
    SUM(CASE WHEN r.converted THEN 1 ELSE 0 END) AS conversions,
    ROUND(
        AVG(CASE WHEN r.converted THEN 1.0 ELSE 0.0 END),
        4
    ) AS conversion_rate,

    -- Revenue metrics
    SUM(r.revenue) AS total_revenue,
    ROUND(AVG(r.revenue), 2) AS revenue_per_assignment,
    ROUND(
        SUM(CASE WHEN r.converted THEN r.revenue ELSE 0 END) / NULLIF(SUM(CASE WHEN r.converted THEN 1 ELSE 0 END), 0),
        2
    ) AS revenue_per_conversion,

    -- Engagement metrics
    ROUND(AVG(r.page_views), 2) AS avg_page_views,
    ROUND(AVG(r.time_on_page_seconds), 2) AS avg_time_on_page,
    ROUND(
        AVG(CASE WHEN r.clicked_cta THEN 1.0 ELSE 0.0 END),
        4
    ) AS cta_click_rate,

    -- Abandonment metrics
    SUM(CASE WHEN r.abandoned THEN 1 ELSE 0 END) AS abandonments,
    ROUND(
        AVG(CASE WHEN r.abandoned THEN 1.0 ELSE 0.0 END),
        4
    ) AS abandonment_rate

FROM ab_test_experiments e
JOIN ab_test_assignments a ON e.id = a.experiment_id
LEFT JOIN ab_test_results r ON a.id = r.assignment_id
GROUP BY e.id, e.experiment_name, e.product_tier, e.status, a.variant, a.assigned_price;

-- Statistical significance test (two-proportion z-test)
CREATE OR REPLACE FUNCTION calculate_ab_test_significance(
    p_experiment_id UUID
) RETURNS TABLE (
    experiment_name VARCHAR(200),
    control_n BIGINT,
    treatment_n BIGINT,
    control_conversions BIGINT,
    treatment_conversions BIGINT,
    control_rate NUMERIC,
    treatment_rate NUMERIC,
    absolute_lift NUMERIC,
    relative_lift_percentage NUMERIC,
    z_score NUMERIC,
    p_value NUMERIC,
    is_significant BOOLEAN,
    confidence_interval_lower NUMERIC,
    confidence_interval_upper NUMERIC
) AS $$
DECLARE
    v_control_n BIGINT;
    v_treatment_n BIGINT;
    v_control_conv BIGINT;
    v_treatment_conv BIGINT;
    v_control_rate NUMERIC;
    v_treatment_rate NUMERIC;
    v_p_pooled NUMERIC;
    v_se NUMERIC;
    v_z NUMERIC;
    v_p_value NUMERIC;
    v_abs_lift NUMERIC;
    v_rel_lift NUMERIC;
    v_ci_lower NUMERIC;
    v_ci_upper NUMERIC;
    v_exp_name VARCHAR(200);
BEGIN
    -- Get experiment name
    SELECT experiments.experiment_name INTO v_exp_name
    FROM ab_test_experiments experiments
    WHERE experiments.id = p_experiment_id;

    -- Get control statistics
    SELECT
        COUNT(DISTINCT a.id),
        SUM(CASE WHEN r.converted THEN 1 ELSE 0 END)
    INTO v_control_n, v_control_conv
    FROM ab_test_assignments a
    LEFT JOIN ab_test_results r ON a.id = r.assignment_id
    WHERE a.experiment_id = p_experiment_id
      AND a.variant = 'control';

    -- Get treatment statistics
    SELECT
        COUNT(DISTINCT a.id),
        SUM(CASE WHEN r.converted THEN 1 ELSE 0 END)
    INTO v_treatment_n, v_treatment_conv
    FROM ab_test_assignments a
    LEFT JOIN ab_test_results r ON a.id = r.assignment_id
    WHERE a.experiment_id = p_experiment_id
      AND a.variant = 'treatment';

    -- Calculate rates
    v_control_rate := v_control_conv::NUMERIC / NULLIF(v_control_n, 0);
    v_treatment_rate := v_treatment_conv::NUMERIC / NULLIF(v_treatment_n, 0);

    -- Calculate lifts
    v_abs_lift := v_treatment_rate - v_control_rate;
    v_rel_lift := (v_abs_lift / NULLIF(v_control_rate, 0)) * 100;

    -- Calculate pooled proportion
    v_p_pooled := (v_control_conv + v_treatment_conv)::NUMERIC /
                  NULLIF(v_control_n + v_treatment_n, 0);

    -- Calculate standard error
    v_se := SQRT(v_p_pooled * (1 - v_p_pooled) *
                 (1.0/NULLIF(v_control_n, 0) + 1.0/NULLIF(v_treatment_n, 0)));

    -- Calculate z-score
    v_z := v_abs_lift / NULLIF(v_se, 0);

    -- Calculate two-tailed p-value (approximation)
    -- For production, use a proper cumulative distribution function
    v_p_value := 2 * (1 - (0.5 * (1 + SIGN(v_z) * SQRT(1 - EXP(-2.0 * v_z * v_z / PI())))));

    -- Calculate 95% confidence interval for difference
    v_ci_lower := v_abs_lift - 1.96 * SQRT(
        v_control_rate * (1 - v_control_rate) / NULLIF(v_control_n, 0) +
        v_treatment_rate * (1 - v_treatment_rate) / NULLIF(v_treatment_n, 0)
    );
    v_ci_upper := v_abs_lift + 1.96 * SQRT(
        v_control_rate * (1 - v_control_rate) / NULLIF(v_control_n, 0) +
        v_treatment_rate * (1 - v_treatment_rate) / NULLIF(v_treatment_n, 0)
    );

    -- Return results
    RETURN QUERY SELECT
        v_exp_name,
        v_control_n,
        v_treatment_n,
        v_control_conv,
        v_treatment_conv,
        ROUND(v_control_rate, 4),
        ROUND(v_treatment_rate, 4),
        ROUND(v_abs_lift, 4),
        ROUND(v_rel_lift, 2),
        ROUND(v_z, 4),
        ROUND(v_p_value, 6),
        (v_p_value < 0.05) AS is_significant,
        ROUND(v_ci_lower, 4),
        ROUND(v_ci_upper, 4);
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- 3. MONITORING AND QUALITY CHECKS
-- ================================================================

-- Check test balance (allocation should be close to target ratio)
CREATE OR REPLACE VIEW vw_ab_test_balance_check AS
SELECT
    e.experiment_name,
    e.allocation_ratio AS target_control_ratio,
    a.variant,
    COUNT(*) AS actual_count,
    ROUND(
        COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER (PARTITION BY e.id),
        4
    ) AS actual_ratio,
    ROUND(
        ABS(
            COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER (PARTITION BY e.id) -
            CASE
                WHEN a.variant = 'control' THEN e.allocation_ratio
                ELSE (1 - e.allocation_ratio)
            END
        ),
        4
    ) AS deviation_from_target,
    CASE
        WHEN ABS(
            COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER (PARTITION BY e.id) -
            CASE
                WHEN a.variant = 'control' THEN e.allocation_ratio
                ELSE (1 - e.allocation_ratio)
            END
        ) < 0.05 THEN 'BALANCED'
        ELSE 'IMBALANCED'
    END AS balance_status
FROM ab_test_experiments e
JOIN ab_test_assignments a ON e.id = a.experiment_id
WHERE e.status = 'active'
GROUP BY e.id, e.experiment_name, e.allocation_ratio, a.variant;

-- Check if experiment has reached minimum sample size
CREATE OR REPLACE VIEW vw_ab_test_sample_size_progress AS
SELECT
    e.experiment_name,
    e.minimum_sample_size AS required_per_variant,
    a.variant,
    COUNT(*) AS current_sample_size,
    ROUND(
        COUNT(*)::NUMERIC / e.minimum_sample_size * 100,
        1
    ) AS progress_percentage,
    CASE
        WHEN COUNT(*) >= e.minimum_sample_size THEN 'READY'
        WHEN COUNT(*) >= e.minimum_sample_size * 0.8 THEN 'NEARLY_READY'
        WHEN COUNT(*) >= e.minimum_sample_size * 0.5 THEN 'IN_PROGRESS'
        ELSE 'EARLY_STAGE'
    END AS readiness_status,
    e.minimum_sample_size - COUNT(*) AS samples_needed
FROM ab_test_experiments e
JOIN ab_test_assignments a ON e.id = a.experiment_id
WHERE e.status = 'active'
GROUP BY e.id, e.experiment_name, e.minimum_sample_size, a.variant;

-- ================================================================
-- 4. EXPERIMENT LIFECYCLE MANAGEMENT
-- ================================================================

-- Activate experiment (change from draft to active)
CREATE OR REPLACE FUNCTION activate_experiment(
    p_experiment_id UUID,
    p_duration_days INTEGER
) RETURNS VOID AS $$
BEGIN
    UPDATE ab_test_experiments
    SET
        status = 'active',
        start_date = NOW(),
        end_date = NOW() + (p_duration_days || ' days')::INTERVAL,
        updated_at = NOW()
    WHERE id = p_experiment_id
      AND status = 'draft';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Experiment % not found or not in draft status', p_experiment_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Complete experiment
CREATE OR REPLACE FUNCTION complete_experiment(
    p_experiment_id UUID
) RETURNS VOID AS $$
BEGIN
    UPDATE ab_test_experiments
    SET
        status = 'completed',
        actual_end_date = NOW(),
        updated_at = NOW()
    WHERE id = p_experiment_id
      AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Experiment % not found or not active', p_experiment_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- 5. REPORTING QUERIES
-- ================================================================

-- Comprehensive experiment report
CREATE OR REPLACE VIEW vw_ab_test_comprehensive_report AS
WITH variant_stats AS (
    SELECT
        e.id AS experiment_id,
        e.experiment_name,
        e.product_tier,
        e.control_price,
        e.treatment_price,
        a.variant,
        a.assigned_price,
        COUNT(DISTINCT a.id) AS total_assignments,
        COUNT(DISTINCT r.id) AS total_responses,
        SUM(CASE WHEN r.converted THEN 1 ELSE 0 END) AS conversions,
        SUM(r.revenue) AS total_revenue,
        AVG(CASE WHEN r.converted THEN 1.0 ELSE 0.0 END) AS conversion_rate,
        AVG(r.revenue) AS revenue_per_assignment,
        SUM(CASE WHEN r.abandoned THEN 1 ELSE 0 END) AS abandonments
    FROM ab_test_experiments e
    JOIN ab_test_assignments a ON e.id = a.experiment_id
    LEFT JOIN ab_test_results r ON a.id = r.assignment_id
    GROUP BY e.id, e.experiment_name, e.product_tier, e.control_price,
             e.treatment_price, a.variant, a.assigned_price
)
SELECT
    experiment_name,
    product_tier,
    control_price,
    treatment_price,
    (treatment_price - control_price) AS price_difference,
    ROUND((treatment_price - control_price) / control_price * 100, 2) AS price_increase_percentage,

    -- Control metrics
    MAX(CASE WHEN variant = 'control' THEN total_assignments END) AS control_n,
    MAX(CASE WHEN variant = 'control' THEN conversions END) AS control_conversions,
    MAX(CASE WHEN variant = 'control' THEN conversion_rate END) AS control_conversion_rate,
    MAX(CASE WHEN variant = 'control' THEN total_revenue END) AS control_total_revenue,
    MAX(CASE WHEN variant = 'control' THEN revenue_per_assignment END) AS control_rpu,

    -- Treatment metrics
    MAX(CASE WHEN variant = 'treatment' THEN total_assignments END) AS treatment_n,
    MAX(CASE WHEN variant = 'treatment' THEN conversions END) AS treatment_conversions,
    MAX(CASE WHEN variant = 'treatment' THEN conversion_rate END) AS treatment_conversion_rate,
    MAX(CASE WHEN variant = 'treatment' THEN total_revenue END) AS treatment_total_revenue,
    MAX(CASE WHEN variant = 'treatment' THEN revenue_per_assignment END) AS treatment_rpu,

    -- Lifts
    ROUND(
        MAX(CASE WHEN variant = 'treatment' THEN conversion_rate END) -
        MAX(CASE WHEN variant = 'control' THEN conversion_rate END),
        4
    ) AS conversion_rate_lift_absolute,
    ROUND(
        (MAX(CASE WHEN variant = 'treatment' THEN conversion_rate END) -
         MAX(CASE WHEN variant = 'control' THEN conversion_rate END)) /
        NULLIF(MAX(CASE WHEN variant = 'control' THEN conversion_rate END), 0) * 100,
        2
    ) AS conversion_rate_lift_percentage,

    ROUND(
        MAX(CASE WHEN variant = 'treatment' THEN revenue_per_assignment END) -
        MAX(CASE WHEN variant = 'control' THEN revenue_per_assignment END),
        2
    ) AS rpu_lift_absolute,
    ROUND(
        (MAX(CASE WHEN variant = 'treatment' THEN revenue_per_assignment END) -
         MAX(CASE WHEN variant = 'control' THEN revenue_per_assignment END)) /
        NULLIF(MAX(CASE WHEN variant = 'control' THEN revenue_per_assignment END), 0) * 100,
        2
    ) AS rpu_lift_percentage

FROM variant_stats
GROUP BY experiment_id, experiment_name, product_tier, control_price, treatment_price;

-- ================================================================
-- 6. EXAMPLE USAGE
-- ================================================================

/*
-- Example 1: Create and activate an experiment
BEGIN;

-- Insert experiment
INSERT INTO ab_test_experiments (
    experiment_name, experiment_type, product_tier,
    control_price, treatment_price, allocation_ratio,
    minimum_sample_size, target_statistical_power,
    significance_level, minimum_detectable_effect,
    primary_metric, success_threshold, created_by
) VALUES (
    'basic_tier_value_test_2026', 'price_point', 'basic',
    49.00, 59.00, 0.5,
    1500, 0.80, 0.05, 0.08,
    'revenue', 0.10, 'pricing_team'
) RETURNING id;

-- Activate (assuming returned id is stored in variable)
SELECT activate_experiment('[experiment_id]', 30);  -- 30 day test

COMMIT;

-- Example 2: Assign user to experiment
SELECT * FROM assign_to_ab_test(
    '[experiment_id]'::UUID,
    'user_12345',
    'session_abc123',
    'individual_developers',
    'north_america',
    'mobile'
);

-- Example 3: Record conversion
SELECT record_ab_test_result(
    '[assignment_id]'::UUID,
    true,              -- converted
    59.00,            -- revenue
    5,                -- page views
    180,              -- time on page (seconds)
    true,             -- clicked CTA
    false,            -- not abandoned
    NULL              -- abandon reason
);

-- Example 4: Check test significance
SELECT * FROM calculate_ab_test_significance('[experiment_id]'::UUID);

-- Example 5: View comprehensive report
SELECT * FROM vw_ab_test_comprehensive_report
WHERE experiment_name = 'basic_tier_value_test_2026';

-- Example 6: Complete experiment
SELECT complete_experiment('[experiment_id]'::UUID);
*/
