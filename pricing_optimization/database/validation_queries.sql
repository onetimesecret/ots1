-- ================================================================
-- DATA VALIDATION QUERIES
-- Price Optimization System Quality Assurance
-- ================================================================

-- ================================================================
-- 1. DATA QUALITY CHECKS
-- ================================================================

-- Check for invalid price orderings
SELECT
    'Invalid Price Ordering' AS check_name,
    COUNT(*) AS violation_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM price_sensitivity_responses
WHERE NOT (
    too_cheap_price <= cheap_price AND
    cheap_price <= expensive_price AND
    expensive_price <= too_expensive_price
);

-- Check for response quality scores
SELECT
    'Response Quality Distribution' AS check_name,
    COUNT(*) AS total_responses,
    AVG(response_quality_score) AS avg_quality,
    MIN(response_quality_score) AS min_quality,
    MAX(response_quality_score) AS max_quality,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY response_quality_score) AS median_quality,
    COUNT(CASE WHEN response_quality_score >= 0.7 THEN 1 END) AS high_quality_count,
    ROUND(
        COUNT(CASE WHEN response_quality_score >= 0.7 THEN 1 END)::numeric /
        COUNT(*)::numeric * 100, 2
    ) AS high_quality_percentage
FROM price_sensitivity_responses;

-- Check for duplicate sessions
SELECT
    'Duplicate Sessions' AS check_name,
    COUNT(*) AS duplicate_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM (
    SELECT session_id, COUNT(*) as cnt
    FROM price_sensitivity_responses
    GROUP BY session_id
    HAVING COUNT(*) > 1
) duplicates;

-- Check for NULL values in critical fields
SELECT
    'NULL Value Validation' AS check_name,
    field_name,
    null_count,
    total_count,
    ROUND(null_count::numeric / total_count::numeric * 100, 2) AS null_percentage,
    CASE
        WHEN null_count = 0 THEN 'PASS'
        ELSE 'WARNING'
    END AS status
FROM (
    SELECT 'session_id' AS field_name,
           SUM(CASE WHEN session_id IS NULL THEN 1 ELSE 0 END) AS null_count,
           COUNT(*) AS total_count
    FROM price_sensitivity_responses
    UNION ALL
    SELECT 'product_tier',
           SUM(CASE WHEN product_tier IS NULL THEN 1 ELSE 0 END),
           COUNT(*)
    FROM price_sensitivity_responses
    UNION ALL
    SELECT 'market_segment',
           SUM(CASE WHEN market_segment IS NULL THEN 1 ELSE 0 END),
           COUNT(*)
    FROM price_sensitivity_responses
) sub;

-- ================================================================
-- 2. STATISTICAL VALIDATION
-- ================================================================

-- Van Westendorp price points by segment
SELECT
    'Van Westendorp Price Points' AS analysis_type,
    product_tier,
    market_segment,
    COUNT(*) AS sample_size,
    ROUND(AVG(too_cheap_price), 2) AS avg_too_cheap,
    ROUND(AVG(cheap_price), 2) AS avg_cheap,
    ROUND(AVG(expensive_price), 2) AS avg_expensive,
    ROUND(AVG(too_expensive_price), 2) AS avg_too_expensive,
    ROUND(STDDEV(cheap_price), 2) AS std_cheap,
    ROUND(STDDEV(expensive_price), 2) AS std_expensive,
    ROUND(
        (AVG(expensive_price) - AVG(cheap_price)) / AVG(cheap_price) * 100,
        2
    ) AS price_range_percentage
FROM price_sensitivity_responses
WHERE response_quality_score >= 0.7
GROUP BY product_tier, market_segment
ORDER BY product_tier, market_segment;

-- Sample size adequacy check (minimum 30 responses per segment)
SELECT
    'Sample Size Adequacy' AS check_name,
    product_tier,
    market_segment,
    COUNT(*) AS sample_size,
    CASE
        WHEN COUNT(*) >= 30 THEN 'ADEQUATE'
        WHEN COUNT(*) >= 20 THEN 'MARGINAL'
        ELSE 'INSUFFICIENT'
    END AS adequacy_status
FROM price_sensitivity_responses
GROUP BY product_tier, market_segment
ORDER BY COUNT(*) ASC;

-- Price variance analysis
SELECT
    'Price Variance Analysis' AS analysis_type,
    product_tier,
    ROUND(AVG(cheap_price), 2) AS mean_cheap_price,
    ROUND(VARIANCE(cheap_price), 2) AS variance_cheap,
    ROUND(STDDEV(cheap_price), 2) AS stddev_cheap,
    ROUND(STDDEV(cheap_price) / AVG(cheap_price) * 100, 2) AS coefficient_variation_cheap,
    ROUND(AVG(expensive_price), 2) AS mean_expensive_price,
    ROUND(VARIANCE(expensive_price), 2) AS variance_expensive,
    ROUND(STDDEV(expensive_price), 2) AS stddev_expensive,
    ROUND(STDDEV(expensive_price) / AVG(expensive_price) * 100, 2) AS coefficient_variation_expensive
FROM price_sensitivity_responses
GROUP BY product_tier
ORDER BY product_tier;

-- ================================================================
-- 3. SEGMENT VALIDATION
-- ================================================================

-- Geographic distribution
SELECT
    'Geographic Distribution' AS metric,
    geographic_region,
    COUNT(*) AS response_count,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 2) AS percentage,
    COUNT(DISTINCT market_segment) AS segments_represented
FROM price_sensitivity_responses
GROUP BY geographic_region
ORDER BY response_count DESC;

-- Market segment distribution
SELECT
    'Market Segment Distribution' AS metric,
    market_segment,
    COUNT(*) AS response_count,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 2) AS percentage,
    COUNT(DISTINCT product_tier) AS tiers_represented,
    ROUND(AVG(response_quality_score), 3) AS avg_quality
FROM price_sensitivity_responses
GROUP BY market_segment
ORDER BY response_count DESC;

-- Product tier distribution
SELECT
    'Product Tier Distribution' AS metric,
    product_tier,
    COUNT(*) AS response_count,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER () * 100, 2) AS percentage,
    ROUND(AVG(expensive_price - cheap_price), 2) AS avg_acceptable_range
FROM price_sensitivity_responses
GROUP BY product_tier
ORDER BY
    CASE product_tier
        WHEN 'free' THEN 1
        WHEN 'basic' THEN 2
        WHEN 'professional' THEN 3
        WHEN 'enterprise' THEN 4
        WHEN 'premium' THEN 5
    END;

-- ================================================================
-- 4. A/B TEST VALIDATION
-- ================================================================

-- A/B test balance check
SELECT
    'A/B Test Balance' AS check_name,
    e.experiment_name,
    a.variant,
    COUNT(*) AS assignment_count,
    ROUND(COUNT(*)::numeric / SUM(COUNT(*)) OVER (PARTITION BY e.id) * 100, 2) AS percentage,
    CASE
        WHEN ABS(COUNT(*)::numeric / SUM(COUNT(*)) OVER (PARTITION BY e.id) - 0.5) <= 0.05
        THEN 'BALANCED'
        ELSE 'IMBALANCED'
    END AS balance_status
FROM ab_test_experiments e
JOIN ab_test_assignments a ON e.id = a.experiment_id
WHERE e.status = 'active'
GROUP BY e.experiment_name, e.id, a.variant
ORDER BY e.experiment_name, a.variant;

-- A/B test performance summary
SELECT
    'A/B Test Performance' AS metric,
    e.experiment_name,
    a.variant,
    COUNT(DISTINCT a.id) AS total_assignments,
    COUNT(DISTINCT r.id) AS total_responses,
    SUM(CASE WHEN r.converted THEN 1 ELSE 0 END) AS conversions,
    ROUND(AVG(CASE WHEN r.converted THEN 1.0 ELSE 0.0 END), 4) AS conversion_rate,
    ROUND(SUM(r.revenue), 2) AS total_revenue,
    ROUND(AVG(r.revenue), 2) AS avg_revenue_per_assignment,
    ROUND(SUM(CASE WHEN r.converted THEN r.revenue ELSE 0 END) / NULLIF(SUM(CASE WHEN r.converted THEN 1 ELSE 0 END), 0), 2) AS avg_revenue_per_conversion
FROM ab_test_experiments e
JOIN ab_test_assignments a ON e.id = a.experiment_id
LEFT JOIN ab_test_results r ON a.id = r.assignment_id
WHERE e.status = 'active'
GROUP BY e.experiment_name, a.variant
ORDER BY e.experiment_name, a.variant;

-- Statistical significance check for A/B tests
WITH test_stats AS (
    SELECT
        e.experiment_name,
        e.id AS experiment_id,
        COUNT(DISTINCT CASE WHEN a.variant = 'control' THEN a.id END) AS control_n,
        COUNT(DISTINCT CASE WHEN a.variant = 'treatment' THEN a.id END) AS treatment_n,
        AVG(CASE WHEN a.variant = 'control' AND r.converted THEN 1.0 ELSE 0.0 END) AS control_rate,
        AVG(CASE WHEN a.variant = 'treatment' AND r.converted THEN 1.0 ELSE 0.0 END) AS treatment_rate,
        STDDEV(CASE WHEN a.variant = 'control' THEN (CASE WHEN r.converted THEN 1.0 ELSE 0.0 END) END) AS control_std,
        STDDEV(CASE WHEN a.variant = 'treatment' THEN (CASE WHEN r.converted THEN 1.0 ELSE 0.0 END) END) AS treatment_std
    FROM ab_test_experiments e
    JOIN ab_test_assignments a ON e.id = a.experiment_id
    LEFT JOIN ab_test_results r ON a.id = r.assignment_id
    WHERE e.status = 'active'
    GROUP BY e.experiment_name, e.id
)
SELECT
    'Statistical Significance' AS check_name,
    experiment_name,
    control_n,
    treatment_n,
    ROUND(control_rate::numeric, 4) AS control_conversion_rate,
    ROUND(treatment_rate::numeric, 4) AS treatment_conversion_rate,
    ROUND((treatment_rate - control_rate)::numeric, 4) AS absolute_lift,
    ROUND(((treatment_rate - control_rate) / NULLIF(control_rate, 0) * 100)::numeric, 2) AS relative_lift_percentage,
    CASE
        WHEN control_n >= 100 AND treatment_n >= 100 THEN 'SUFFICIENT'
        WHEN control_n >= 50 AND treatment_n >= 50 THEN 'MARGINAL'
        ELSE 'INSUFFICIENT'
    END AS sample_size_status
FROM test_stats;

-- ================================================================
-- 5. REVENUE VALIDATION
-- ================================================================

-- Revenue metrics data completeness
SELECT
    'Revenue Metrics Completeness' AS check_name,
    COUNT(DISTINCT metric_date) AS unique_dates,
    MIN(metric_date) AS earliest_date,
    MAX(metric_date) AS latest_date,
    MAX(metric_date) - MIN(metric_date) + 1 AS date_range_days,
    COUNT(*) AS total_records,
    COUNT(DISTINCT product_tier) AS tiers_tracked,
    COUNT(DISTINCT market_segment) AS segments_tracked
FROM revenue_metrics;

-- Revenue trends validation
SELECT
    'Revenue Trends' AS metric,
    product_tier,
    COUNT(DISTINCT metric_date) AS days_tracked,
    ROUND(SUM(daily_revenue), 2) AS total_revenue,
    ROUND(AVG(daily_revenue), 2) AS avg_daily_revenue,
    ROUND(MIN(daily_revenue), 2) AS min_daily_revenue,
    ROUND(MAX(daily_revenue), 2) AS max_daily_revenue,
    ROUND(STDDEV(daily_revenue), 2) AS revenue_volatility,
    SUM(new_customers) AS total_new_customers,
    SUM(churned_customers) AS total_churned_customers,
    SUM(new_customers) - SUM(churned_customers) AS net_customer_growth
FROM revenue_metrics
WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY product_tier
ORDER BY total_revenue DESC;

-- Conversion rate validation
SELECT
    'Conversion Rate Analysis' AS metric,
    product_tier,
    market_segment,
    ROUND(AVG(conversion_rate), 4) AS avg_conversion_rate,
    ROUND(MIN(conversion_rate), 4) AS min_conversion_rate,
    ROUND(MAX(conversion_rate), 4) AS max_conversion_rate,
    ROUND(STDDEV(conversion_rate), 4) AS std_conversion_rate,
    CASE
        WHEN AVG(conversion_rate) > 0.15 THEN 'EXCELLENT'
        WHEN AVG(conversion_rate) > 0.10 THEN 'GOOD'
        WHEN AVG(conversion_rate) > 0.05 THEN 'AVERAGE'
        ELSE 'NEEDS_IMPROVEMENT'
    END AS performance_rating
FROM revenue_metrics
WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY product_tier, market_segment
ORDER BY avg_conversion_rate DESC;

-- ================================================================
-- 6. COMPETITOR PRICING VALIDATION
-- ================================================================

-- Competitor pricing landscape
SELECT
    'Competitor Pricing Landscape' AS analysis,
    product_tier,
    COUNT(DISTINCT competitor_name) AS competitor_count,
    ROUND(MIN(price), 2) AS min_price,
    ROUND(AVG(price), 2) AS avg_price,
    ROUND(MAX(price), 2) AS max_price,
    ROUND(STDDEV(price), 2) AS price_std,
    ROUND((MAX(price) - MIN(price)) / MIN(price) * 100, 2) AS price_range_percentage
FROM competitor_pricing
WHERE verified = true
GROUP BY product_tier
ORDER BY
    CASE product_tier
        WHEN 'basic' THEN 1
        WHEN 'professional' THEN 2
        WHEN 'enterprise' THEN 3
    END;

-- ================================================================
-- 7. ALERT SYSTEM VALIDATION
-- ================================================================

-- Alert distribution
SELECT
    'Alert Distribution' AS metric,
    alert_type,
    severity,
    COUNT(*) AS alert_count,
    COUNT(CASE WHEN status = 'open' THEN 1 END) AS open_alerts,
    COUNT(CASE WHEN status = 'acknowledged' THEN 1 END) AS acknowledged_alerts,
    COUNT(CASE WHEN status = 'resolved' THEN 1 END) AS resolved_alerts,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (COALESCE(acknowledged_at, NOW()) - created_at)) / 3600),
        2
    ) AS avg_time_to_acknowledge_hours
FROM pricing_alerts
GROUP BY alert_type, severity
ORDER BY
    CASE severity
        WHEN 'critical' THEN 1
        WHEN 'warning' THEN 2
        WHEN 'info' THEN 3
    END,
    alert_count DESC;

-- ================================================================
-- 8. COMPREHENSIVE VALIDATION SUMMARY
-- ================================================================

SELECT
    '=== VALIDATION SUMMARY ===' AS report_section,
    (SELECT COUNT(*) FROM price_sensitivity_responses) AS total_survey_responses,
    (SELECT COUNT(*) FROM price_sensitivity_responses WHERE response_quality_score >= 0.7) AS high_quality_responses,
    (SELECT COUNT(DISTINCT market_segment) FROM price_sensitivity_responses) AS active_market_segments,
    (SELECT COUNT(*) FROM ab_test_experiments WHERE status = 'active') AS active_experiments,
    (SELECT SUM(daily_revenue) FROM revenue_metrics WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days') AS last_30_days_revenue,
    (SELECT COUNT(*) FROM pricing_alerts WHERE status = 'open') AS open_alerts,
    (SELECT COUNT(*) FROM competitor_pricing WHERE verified = true) AS verified_competitor_prices;

-- ================================================================
-- 9. DATA INTEGRITY CONSTRAINTS
-- ================================================================

-- Check referential integrity
SELECT
    'Referential Integrity' AS check_name,
    'ab_test_assignments' AS table_name,
    COUNT(*) AS orphaned_records
FROM ab_test_assignments a
WHERE NOT EXISTS (
    SELECT 1 FROM ab_test_experiments e WHERE e.id = a.experiment_id
)
UNION ALL
SELECT
    'Referential Integrity',
    'ab_test_results',
    COUNT(*)
FROM ab_test_results r
WHERE NOT EXISTS (
    SELECT 1 FROM ab_test_assignments a WHERE a.id = r.assignment_id
);

-- ================================================================
-- 10. PERFORMANCE BENCHMARKS
-- ================================================================

-- Expected test results for sample data
SELECT
    '=== EXPECTED VALIDATION RESULTS ===' AS section,
    '1. Total responses should be ~3400' AS check_1,
    '2. High quality responses (>=0.7) should be ~85%' AS check_2,
    '3. Market segments should be 5' AS check_3,
    '4. Active A/B tests should be 2' AS check_4,
    '5. All price orderings should be valid' AS check_5,
    '6. No duplicate sessions should exist' AS check_6,
    '7. A/B test variants should be balanced (50/50 ±5%)' AS check_7,
    '8. Revenue metrics should cover 90 days' AS check_8,
    '9. No orphaned records in test tables' AS check_9,
    '10. Sample sizes per segment should be adequate (>=30)' AS check_10;
