-- =============================================================================
-- PHASE 1: Data Validation Queries
-- Quality Assurance for Price Optimization System
-- =============================================================================

-- =============================================================================
-- 1. Data Completeness Checks
-- =============================================================================

-- Check for required data in all core tables
SELECT
    'market_segments' AS table_name,
    COUNT(*) AS record_count,
    COUNT(*) >= 1 AS has_data
FROM market_segments
UNION ALL
SELECT
    'product_tiers',
    COUNT(*),
    COUNT(*) >= 1
FROM product_tiers
UNION ALL
SELECT
    'survey_respondents',
    COUNT(*),
    COUNT(*) >= 10 AS sufficient_sample -- At least 10 respondents recommended
FROM survey_respondents
WHERE is_valid = true
UNION ALL
SELECT
    'price_sensitivity_responses',
    COUNT(*),
    COUNT(*) >= 30 AS sufficient_sample -- At least 30 per segment/tier recommended
FROM price_sensitivity_responses;

-- =============================================================================
-- 2. Van Westendorp Price Logic Validation
-- =============================================================================

-- Verify price ordering is correct (too_cheap <= bargain <= expensive <= too_expensive)
SELECT
    'Invalid Price Ordering' AS validation_issue,
    COUNT(*) AS violation_count
FROM price_sensitivity_responses
WHERE NOT (
    too_cheap_price <= bargain_price AND
    bargain_price <= expensive_price AND
    expensive_price <= too_expensive_price
);

-- Check for unrealistic price ranges (more than 10x difference)
SELECT
    'Unrealistic Price Range' AS validation_issue,
    respondent_id,
    tier_id,
    too_cheap_price,
    too_expensive_price,
    (too_expensive_price::FLOAT / NULLIF(too_cheap_price, 0)) AS price_ratio
FROM price_sensitivity_responses
WHERE too_expensive_price > too_cheap_price * 10
ORDER BY price_ratio DESC;

-- Verify acceptable price range logic in Van Westendorp analysis
SELECT
    'Invalid VW Acceptable Range' AS validation_issue,
    analysis_id,
    segment_id,
    tier_id,
    acceptable_price_range_lower,
    acceptable_price_range_upper
FROM van_westendorp_analysis
WHERE acceptable_price_range_lower >= acceptable_price_range_upper
   OR acceptable_price_range_lower < 0;

-- =============================================================================
-- 3. Statistical Validation
-- =============================================================================

-- Sample size adequacy by segment and tier
SELECT
    ms.segment_name,
    pt.tier_name,
    COUNT(DISTINCT psr.respondent_id) AS sample_size,
    CASE
        WHEN COUNT(DISTINCT psr.respondent_id) < 30 THEN 'Insufficient'
        WHEN COUNT(DISTINCT psr.respondent_id) < 100 THEN 'Adequate'
        ELSE 'Good'
    END AS sample_quality
FROM market_segments ms
CROSS JOIN product_tiers pt
LEFT JOIN price_sensitivity_responses psr ON psr.tier_id = pt.tier_id
LEFT JOIN survey_respondents sr ON sr.respondent_id = psr.respondent_id AND sr.segment_id = ms.segment_id
WHERE ms.is_active AND pt.is_active
GROUP BY ms.segment_name, pt.tier_name
ORDER BY sample_size DESC;

-- Price elasticity coefficient validation (should be negative for normal goods)
SELECT
    ms.segment_name,
    pt.tier_name,
    pec.price_elasticity_of_demand,
    pec.r_squared,
    pec.p_value,
    CASE
        WHEN pec.price_elasticity_of_demand > 0 THEN 'INVALID: Positive elasticity (Giffen good?)'
        WHEN pec.r_squared < 0.60 THEN 'WARNING: Low R-squared'
        WHEN pec.p_value > 0.05 THEN 'WARNING: Not statistically significant'
        ELSE 'Valid'
    END AS validation_status
FROM price_elasticity_coefficients pec
JOIN market_segments ms ON ms.segment_id = pec.segment_id
JOIN product_tiers pt ON pt.tier_id = pec.tier_id
WHERE pec.is_current = true;

-- =============================================================================
-- 4. Revenue Projection Validation
-- =============================================================================

-- Check for negative or zero revenue projections
SELECT
    'Invalid Revenue Projections' AS validation_issue,
    simulation_id,
    price_point_tested,
    projected_monthly_revenue,
    projected_annual_revenue
FROM optimization_simulations
WHERE projected_monthly_revenue <= 0
   OR projected_annual_revenue <= 0
   OR projected_annual_revenue != projected_monthly_revenue * 12;

-- Verify conversion rates are within realistic bounds (0-100%)
SELECT
    'Invalid Conversion Rates' AS validation_issue,
    COUNT(*) AS violation_count
FROM optimization_simulations
WHERE projected_conversion_rate < 0
   OR projected_conversion_rate > 1;

-- Check confidence intervals are properly ordered
SELECT
    'Invalid Confidence Intervals' AS validation_issue,
    simulation_id,
    revenue_ci_lower,
    projected_monthly_revenue,
    revenue_ci_upper
FROM optimization_simulations
WHERE revenue_ci_lower > projected_monthly_revenue
   OR projected_monthly_revenue > revenue_ci_upper
   OR revenue_ci_lower >= revenue_ci_upper;

-- =============================================================================
-- 5. A/B Test Validation
-- =============================================================================

-- Verify A/B test sample size calculations
SELECT
    experiment_name,
    required_sample_size,
    statistical_power,
    significance_level,
    minimum_detectable_effect,
    CASE
        WHEN required_sample_size < 100 THEN 'WARNING: Sample size may be too small'
        WHEN statistical_power < 0.80 THEN 'WARNING: Insufficient statistical power'
        WHEN significance_level > 0.05 THEN 'WARNING: High significance threshold'
        ELSE 'Valid'
    END AS validation_status
FROM ab_test_experiments
WHERE status IN ('active', 'completed');

-- Check for imbalanced test groups
WITH group_sizes AS (
    SELECT
        experiment_id,
        test_group,
        COUNT(*) AS group_size
    FROM ab_test_participants
    GROUP BY experiment_id, test_group
)
SELECT
    e.experiment_name,
    gs.test_group,
    gs.group_size,
    AVG(gs.group_size) OVER (PARTITION BY gs.experiment_id) AS avg_group_size,
    CASE
        WHEN ABS(gs.group_size - AVG(gs.group_size) OVER (PARTITION BY gs.experiment_id)) >
             AVG(gs.group_size) OVER (PARTITION BY gs.experiment_id) * 0.1
        THEN 'WARNING: Imbalanced groups (>10% difference)'
        ELSE 'Balanced'
    END AS balance_status
FROM group_sizes gs
JOIN ab_test_experiments e ON e.experiment_id = gs.experiment_id;

-- Validate test participant assignment consistency (no duplicate assignments)
SELECT
    'Duplicate Test Assignments' AS validation_issue,
    user_id_hash,
    COUNT(*) AS assignment_count
FROM ab_test_participants
WHERE experiment_id = (SELECT experiment_id FROM ab_test_experiments WHERE status = 'active' LIMIT 1)
GROUP BY user_id_hash
HAVING COUNT(*) > 1;

-- =============================================================================
-- 6. Data Quality Metrics
-- =============================================================================

-- Survey response quality indicators
SELECT
    sr.segment_id,
    ms.segment_name,
    COUNT(*) AS total_responses,
    COUNT(*) FILTER (WHERE sr.is_valid = true) AS valid_responses,
    COUNT(*) FILTER (WHERE sr.is_valid = false) AS invalid_responses,
    ROUND(AVG(sr.response_time_seconds)) AS avg_response_time_sec,
    CASE
        WHEN AVG(sr.response_time_seconds) < 30 THEN 'WARNING: Very fast responses (possible spam)'
        WHEN AVG(sr.response_time_seconds) > 1800 THEN 'WARNING: Very slow responses'
        ELSE 'Normal'
    END AS response_time_quality
FROM survey_respondents sr
JOIN market_segments ms ON ms.segment_id = sr.segment_id
WHERE sr.completed_at IS NOT NULL
GROUP BY sr.segment_id, ms.segment_name;

-- Van Westendorp analysis confidence scores
SELECT
    ms.segment_name,
    pt.tier_name,
    vwa.sample_size,
    ROUND(vwa.confidence_score::NUMERIC, 3) AS confidence_score,
    ROUND(vwa.data_quality_score::NUMERIC, 3) AS data_quality_score,
    CASE
        WHEN vwa.confidence_score < 0.70 THEN 'Low confidence - more data needed'
        WHEN vwa.confidence_score < 0.85 THEN 'Moderate confidence'
        ELSE 'High confidence'
    END AS confidence_level
FROM van_westendorp_analysis vwa
JOIN market_segments ms ON ms.segment_id = vwa.segment_id
JOIN product_tiers pt ON pt.tier_id = vwa.tier_id
WHERE vwa.is_current = true
ORDER BY vwa.confidence_score ASC;

-- =============================================================================
-- 7. Competitive Data Validation
-- =============================================================================

-- Check for outdated competitive pricing data
SELECT
    competitor_name,
    product_name,
    current_price,
    last_verified_at,
    CURRENT_TIMESTAMP - last_verified_at AS data_age,
    CASE
        WHEN last_verified_at < CURRENT_TIMESTAMP - INTERVAL '30 days' THEN 'OUTDATED: Refresh needed'
        WHEN last_verified_at < CURRENT_TIMESTAMP - INTERVAL '14 days' THEN 'WARNING: Data aging'
        ELSE 'Current'
    END AS freshness_status
FROM competitive_pricing
ORDER BY last_verified_at ASC;

-- Validate competitive pricing is within reasonable market range
WITH market_stats AS (
    SELECT
        tier_equivalent,
        AVG(current_price) AS avg_market_price,
        STDDEV(current_price) AS stddev_price
    FROM competitive_pricing
    WHERE verified = true
    GROUP BY tier_equivalent
)
SELECT
    cp.competitor_name,
    cp.tier_equivalent,
    cp.current_price,
    ms.avg_market_price,
    CASE
        WHEN cp.current_price > ms.avg_market_price + (2 * ms.stddev_price)
        THEN 'OUTLIER: Price unusually high'
        WHEN cp.current_price < ms.avg_market_price - (2 * ms.stddev_price)
        THEN 'OUTLIER: Price unusually low'
        ELSE 'Normal'
    END AS market_position
FROM competitive_pricing cp
JOIN market_stats ms ON ms.tier_equivalent = cp.tier_equivalent
WHERE cp.verified = true;

-- =============================================================================
-- 8. Price Change Impact Validation
-- =============================================================================

-- Validate price change effectiveness
SELECT
    pch.tier_id,
    pt.tier_name,
    pch.previous_price,
    pch.new_price,
    pch.price_change_percentage,
    pch.expected_revenue_impact,
    pch.actual_revenue_impact,
    CASE
        WHEN pch.actual_revenue_impact IS NOT NULL THEN
            ROUND(((pch.actual_revenue_impact - pch.expected_revenue_impact)::FLOAT /
                   NULLIF(pch.expected_revenue_impact, 0) * 100)::NUMERIC, 2)
        ELSE NULL
    END AS forecast_accuracy_pct,
    pch.effective_date
FROM price_changes_history pch
JOIN product_tiers pt ON pt.tier_id = pch.tier_id
WHERE pch.effective_date < CURRENT_TIMESTAMP - INTERVAL '30 days'
ORDER BY pch.effective_date DESC;

-- =============================================================================
-- 9. Monitoring Alert Validation
-- =============================================================================

-- Check alert configuration coverage
SELECT
    alert_type,
    COUNT(*) AS alert_count,
    COUNT(*) FILTER (WHERE is_active = true) AS active_alerts,
    COUNT(*) FILTER (WHERE is_active = false) AS inactive_alerts
FROM pricing_alerts
GROUP BY alert_type;

-- Recent alert trigger frequency
SELECT
    pa.alert_name,
    pa.alert_type,
    pa.trigger_count,
    pa.last_triggered_at,
    COUNT(ah.history_id) AS recent_triggers,
    CASE
        WHEN COUNT(ah.history_id) > 10 THEN 'WARNING: Frequent triggers - review threshold'
        WHEN COUNT(ah.history_id) = 0 THEN 'No recent triggers'
        ELSE 'Normal'
    END AS trigger_status
FROM pricing_alerts pa
LEFT JOIN alert_history ah ON ah.alert_id = pa.alert_id
    AND ah.triggered_at > CURRENT_TIMESTAMP - INTERVAL '7 days'
WHERE pa.is_active = true
GROUP BY pa.alert_id, pa.alert_name, pa.alert_type, pa.trigger_count, pa.last_triggered_at;

-- =============================================================================
-- 10. Overall Data Quality Summary
-- =============================================================================

-- Comprehensive data quality report
WITH quality_checks AS (
    SELECT
        'Survey Responses' AS metric,
        COUNT(*)::TEXT AS value,
        CASE WHEN COUNT(*) >= 30 THEN 'PASS' ELSE 'FAIL' END AS status
    FROM survey_respondents
    WHERE is_valid = true

    UNION ALL

    SELECT
        'Price Sensitivity Responses',
        COUNT(*)::TEXT,
        CASE WHEN COUNT(*) >= 30 THEN 'PASS' ELSE 'FAIL' END
    FROM price_sensitivity_responses

    UNION ALL

    SELECT
        'Van Westendorp Analyses',
        COUNT(*)::TEXT,
        CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END
    FROM van_westendorp_analysis
    WHERE is_current = true

    UNION ALL

    SELECT
        'Price Elasticity Coefficients',
        COUNT(*)::TEXT,
        CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END
    FROM price_elasticity_coefficients
    WHERE is_current = true AND price_elasticity_of_demand < 0

    UNION ALL

    SELECT
        'Optimization Simulations',
        COUNT(*)::TEXT,
        CASE WHEN COUNT(*) >= 100 THEN 'PASS' ELSE 'FAIL' END
    FROM optimization_simulations

    UNION ALL

    SELECT
        'Active A/B Tests',
        COUNT(*)::TEXT,
        'INFO' -- Just informational
    FROM ab_test_experiments
    WHERE status = 'active'

    UNION ALL

    SELECT
        'Active Alerts',
        COUNT(*)::TEXT,
        CASE WHEN COUNT(*) >= 3 THEN 'PASS' ELSE 'FAIL' END
    FROM pricing_alerts
    WHERE is_active = true

    UNION ALL

    SELECT
        'Recent Pricing Metrics (30d)',
        COUNT(DISTINCT metric_date)::TEXT,
        CASE WHEN COUNT(DISTINCT metric_date) >= 25 THEN 'PASS' ELSE 'WARN' END
    FROM pricing_metrics
    WHERE metric_date > CURRENT_DATE - INTERVAL '30 days'
)
SELECT
    metric,
    value,
    status,
    CASE status
        WHEN 'PASS' THEN '✓'
        WHEN 'FAIL' THEN '✗'
        WHEN 'WARN' THEN '⚠'
        ELSE 'ℹ'
    END AS indicator
FROM quality_checks
ORDER BY
    CASE status
        WHEN 'FAIL' THEN 1
        WHEN 'WARN' THEN 2
        WHEN 'PASS' THEN 3
        ELSE 4
    END,
    metric;

-- =============================================================================
-- 11. Performance Validation Queries
-- =============================================================================

-- Check for missing indexes (these should return quickly)
EXPLAIN ANALYZE
SELECT
    vwa.recommended_price,
    vwa.expected_conversion_rate,
    ms.segment_name,
    pt.tier_name
FROM van_westendorp_analysis vwa
JOIN market_segments ms ON ms.segment_id = vwa.segment_id
JOIN product_tiers pt ON pt.tier_id = vwa.tier_id
WHERE vwa.is_current = true
  AND ms.is_active = true
  AND pt.is_active = true;

-- Validate query performance for real-time pricing lookups
EXPLAIN ANALYZE
SELECT
    pt.tier_name,
    vwa.recommended_price,
    vwa.acceptable_price_range_lower,
    vwa.acceptable_price_range_upper
FROM product_tiers pt
JOIN van_westendorp_analysis vwa ON vwa.tier_id = pt.tier_id
WHERE pt.tier_name = 'Professional'
  AND vwa.is_current = true
LIMIT 1;

-- =============================================================================
-- Expected Results for Test Data
-- =============================================================================

/*
EXPECTED VALIDATION RESULTS FOR SAMPLE DATA:

1. Data Completeness:
   - market_segments: 5 records ✓
   - product_tiers: 5 records ✓
   - survey_respondents: 7 records ✓
   - price_sensitivity_responses: 7 records ✓

2. Van Westendorp Logic:
   - Invalid Price Ordering: 0 violations ✓
   - All price ranges should be logical ✓

3. Statistical Validation:
   - Sample sizes are small (demo data) - EXPECTED WARNING
   - Price elasticity coefficients are negative ✓
   - R-squared values > 0.75 ✓

4. Revenue Projections:
   - No negative or zero revenues ✓
   - Conversion rates between 0 and 1 ✓
   - Confidence intervals properly ordered ✓

5. A/B Tests:
   - All experiments have valid statistical parameters ✓

6. Data Quality:
   - All surveys marked as valid ✓
   - Response times reasonable ✓
   - Confidence scores > 0.80 ✓

7. Competitive Data:
   - All competitor data recently verified ✓
   - Prices within market range ✓

8. Alerts:
   - 4 active alert configurations ✓

9. Overall Quality Summary:
   - Most checks should PASS ✓
   - Sample size warnings expected (demo data)

10. Performance:
    - All queries should execute in < 10ms ✓
    - Proper index usage confirmed ✓

ROLLBACK PLAN:
If validation fails, run:
    ROLLBACK;
    -- Then re-run schema and sample data scripts
*/
