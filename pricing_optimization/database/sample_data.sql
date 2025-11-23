-- ================================================================
-- SAMPLE DATA FOR PRICE OPTIMIZATION SYSTEM
-- Van Westendorp Price Sensitivity Analysis
-- ================================================================

-- Clear existing test data (if any)
TRUNCATE TABLE
    revenue_metrics,
    pricing_alerts,
    price_changes_audit,
    competitor_pricing,
    market_segments,
    ab_test_results,
    ab_test_assignments,
    ab_test_experiments,
    price_optimization_results,
    price_sensitivity_responses
CASCADE;

-- ================================================================
-- MARKET SEGMENTS
-- ================================================================

INSERT INTO market_segments (segment_name, segment_description, size_estimate, growth_rate, avg_customer_lifetime_value, churn_rate, price_sensitivity_index, optimal_pricing_strategy, targeting_criteria, priority_score) VALUES
('enterprise_tech', 'Large technology companies requiring secure secret sharing', 5000, 0.15, 12000.00, 0.08, -0.3, 'value_based', '{"company_size": "large", "industry": ["technology", "software"]}'::jsonb, 95),
('startup_growth', 'Fast-growing startups in growth phase', 15000, 0.35, 3600.00, 0.18, 0.2, 'competitive', '{"company_size": "small", "funding_stage": ["series_a", "series_b"]}'::jsonb, 85),
('individual_developers', 'Independent developers and freelancers', 50000, 0.25, 480.00, 0.25, 0.6, 'penetration', '{"company_size": "individual", "profession": "developer"}'::jsonb, 70),
('financial_services', 'Banks and financial institutions', 2000, 0.12, 24000.00, 0.05, -0.5, 'premium', '{"industry": ["banking", "finance", "insurance"]}'::jsonb, 98),
('healthcare_providers', 'Healthcare organizations handling sensitive data', 8000, 0.20, 15000.00, 0.10, -0.2, 'value_based', '{"industry": "healthcare", "compliance": ["hipaa"]}'::jsonb, 92);

-- ================================================================
-- PRICE SENSITIVITY RESPONSES - ENTERPRISE TECH SEGMENT
-- ================================================================

INSERT INTO price_sensitivity_responses (
    user_id, session_id, product_tier, market_segment, geographic_region,
    too_cheap_price, cheap_price, expensive_price, too_expensive_price,
    current_price_paid, willingness_to_switch, usage_frequency, company_size, industry,
    survey_version, response_quality_score, response_time_seconds, device_type
)
SELECT
    'user_' || generate_series,
    'session_' || generate_series || '_' || floor(random() * 1000000),
    tier,
    'enterprise_tech',
    region,
    ROUND((base_price * 0.3 + random() * base_price * 0.2)::numeric, 2),
    ROUND((base_price * 0.6 + random() * base_price * 0.2)::numeric, 2),
    ROUND((base_price * 1.3 + random() * base_price * 0.3)::numeric, 2),
    ROUND((base_price * 2.0 + random() * base_price * 0.5)::numeric, 2),
    ROUND((current_price + random() * 50)::numeric, 2),
    ROUND((0.6 + random() * 0.3)::numeric, 2),
    (ARRAY['daily', 'weekly', 'monthly'])[floor(random() * 3 + 1)],
    'large',
    (ARRAY['technology', 'software', 'saas'])[floor(random() * 3 + 1)],
    'v1.0',
    ROUND((0.8 + random() * 0.2)::numeric, 2),
    floor(120 + random() * 180)::integer,
    (ARRAY['desktop', 'mobile'])[floor(random() * 2 + 1)]
FROM (
    SELECT
        generate_series,
        (ARRAY['professional', 'enterprise'])[floor(random() * 2 + 1)] as tier,
        (ARRAY['north_america', 'europe', 'asia_pacific'])[floor(random() * 3 + 1)] as region,
        CASE
            WHEN floor(random() * 2 + 1) = 1 THEN 499.0
            ELSE 999.0
        END as base_price,
        CASE
            WHEN floor(random() * 2 + 1) = 1 THEN 450.0
            ELSE 900.0
        END as current_price
    FROM generate_series(1, 500)
) sub;

-- ================================================================
-- PRICE SENSITIVITY RESPONSES - STARTUP GROWTH SEGMENT
-- ================================================================

INSERT INTO price_sensitivity_responses (
    user_id, session_id, product_tier, market_segment, geographic_region,
    too_cheap_price, cheap_price, expensive_price, too_expensive_price,
    current_price_paid, willingness_to_switch, usage_frequency, company_size, industry,
    survey_version, response_quality_score, response_time_seconds, device_type
)
SELECT
    'user_' || (500 + generate_series),
    'session_' || (500 + generate_series) || '_' || floor(random() * 1000000),
    tier,
    'startup_growth',
    region,
    ROUND((base_price * 0.2 + random() * base_price * 0.15)::numeric, 2),
    ROUND((base_price * 0.5 + random() * base_price * 0.2)::numeric, 2),
    ROUND((base_price * 1.2 + random() * base_price * 0.3)::numeric, 2),
    ROUND((base_price * 1.8 + random() * base_price * 0.4)::numeric, 2),
    ROUND((current_price + random() * 30)::numeric, 2),
    ROUND((0.4 + random() * 0.4)::numeric, 2),
    (ARRAY['daily', 'weekly'])[floor(random() * 2 + 1)],
    (ARRAY['small', 'medium'])[floor(random() * 2 + 1)],
    (ARRAY['technology', 'startup', 'ecommerce'])[floor(random() * 3 + 1)],
    'v1.0',
    ROUND((0.75 + random() * 0.25)::numeric, 2),
    floor(100 + random() * 150)::integer,
    (ARRAY['desktop', 'mobile'])[floor(random() * 2 + 1)]
FROM (
    SELECT
        generate_series,
        (ARRAY['basic', 'professional'])[floor(random() * 2 + 1)] as tier,
        (ARRAY['north_america', 'europe', 'asia_pacific'])[floor(random() * 3 + 1)] as region,
        CASE
            WHEN floor(random() * 2 + 1) = 1 THEN 99.0
            ELSE 299.0
        END as base_price,
        CASE
            WHEN floor(random() * 2 + 1) = 1 THEN 79.0
            ELSE 249.0
        END as current_price
    FROM generate_series(1, 800)
) sub;

-- ================================================================
-- PRICE SENSITIVITY RESPONSES - INDIVIDUAL DEVELOPERS SEGMENT
-- ================================================================

INSERT INTO price_sensitivity_responses (
    user_id, session_id, product_tier, market_segment, geographic_region,
    too_cheap_price, cheap_price, expensive_price, too_expensive_price,
    current_price_paid, willingness_to_switch, usage_frequency, company_size, industry,
    survey_version, response_quality_score, response_time_seconds, device_type
)
SELECT
    'user_' || (1300 + generate_series),
    'session_' || (1300 + generate_series) || '_' || floor(random() * 1000000),
    tier,
    'individual_developers',
    region,
    ROUND((base_price * 0.1 + random() * base_price * 0.1)::numeric, 2),
    ROUND((base_price * 0.4 + random() * base_price * 0.2)::numeric, 2),
    ROUND((base_price * 1.0 + random() * base_price * 0.3)::numeric, 2),
    ROUND((base_price * 1.5 + random() * base_price * 0.4)::numeric, 2),
    CASE WHEN random() > 0.5 THEN ROUND((current_price + random() * 10)::numeric, 2) ELSE NULL END,
    ROUND((0.3 + random() * 0.5)::numeric, 2),
    (ARRAY['weekly', 'monthly', 'quarterly'])[floor(random() * 3 + 1)],
    'individual',
    'technology',
    'v1.0',
    ROUND((0.7 + random() * 0.3)::numeric, 2),
    floor(80 + random() * 120)::integer,
    (ARRAY['desktop', 'mobile'])[floor(random() * 2 + 1)]
FROM (
    SELECT
        generate_series,
        (ARRAY['free', 'basic'])[floor(random() * 2 + 1)] as tier,
        (ARRAY['north_america', 'europe', 'asia_pacific', 'latin_america'])[floor(random() * 4 + 1)] as region,
        CASE
            WHEN floor(random() * 2 + 1) = 1 THEN 0.0
            ELSE 29.0
        END as base_price,
        CASE
            WHEN floor(random() * 2 + 1) = 1 THEN 0.0
            ELSE 19.0
        END as current_price
    FROM generate_series(1, 1200)
) sub;

-- ================================================================
-- PRICE SENSITIVITY RESPONSES - FINANCIAL SERVICES SEGMENT
-- ================================================================

INSERT INTO price_sensitivity_responses (
    user_id, session_id, product_tier, market_segment, geographic_region,
    too_cheap_price, cheap_price, expensive_price, too_expensive_price,
    current_price_paid, willingness_to_switch, usage_frequency, company_size, industry,
    survey_version, response_quality_score, response_time_seconds, device_type
)
SELECT
    'user_' || (2500 + generate_series),
    'session_' || (2500 + generate_series) || '_' || floor(random() * 1000000),
    'enterprise',
    'financial_services',
    region,
    ROUND((1500.0 + random() * 500)::numeric, 2),
    ROUND((2500.0 + random() * 500)::numeric, 2),
    ROUND((4000.0 + random() * 1000)::numeric, 2),
    ROUND((6000.0 + random() * 2000)::numeric, 2),
    ROUND((2800.0 + random() * 400)::numeric, 2),
    ROUND((0.2 + random() * 0.3)::numeric, 2),
    (ARRAY['daily', 'weekly'])[floor(random() * 2 + 1)],
    'enterprise',
    (ARRAY['banking', 'finance', 'insurance'])[floor(random() * 3 + 1)],
    'v1.0',
    ROUND((0.85 + random() * 0.15)::numeric, 2),
    floor(150 + random() * 200)::integer,
    'desktop'
FROM (
    SELECT
        generate_series,
        (ARRAY['north_america', 'europe', 'asia_pacific'])[floor(random() * 3 + 1)] as region
    FROM generate_series(1, 300)
) sub;

-- ================================================================
-- PRICE SENSITIVITY RESPONSES - HEALTHCARE PROVIDERS SEGMENT
-- ================================================================

INSERT INTO price_sensitivity_responses (
    user_id, session_id, product_tier, market_segment, geographic_region,
    too_cheap_price, cheap_price, expensive_price, too_expensive_price,
    current_price_paid, willingness_to_switch, usage_frequency, company_size, industry,
    survey_version, response_quality_score, response_time_seconds, device_type
)
SELECT
    'user_' || (2800 + generate_series),
    'session_' || (2800 + generate_series) || '_' || floor(random() * 1000000),
    tier,
    'healthcare_providers',
    region,
    ROUND((base_price * 0.35 + random() * base_price * 0.15)::numeric, 2),
    ROUND((base_price * 0.65 + random() * base_price * 0.2)::numeric, 2),
    ROUND((base_price * 1.25 + random() * base_price * 0.25)::numeric, 2),
    ROUND((base_price * 1.9 + random() * base_price * 0.4)::numeric, 2),
    ROUND((current_price + random() * 100)::numeric, 2),
    ROUND((0.3 + random() * 0.3)::numeric, 2),
    (ARRAY['daily', 'weekly'])[floor(random() * 2 + 1)],
    (ARRAY['medium', 'large', 'enterprise'])[floor(random() * 3 + 1)],
    'healthcare',
    'v1.0',
    ROUND((0.8 + random() * 0.2)::numeric, 2),
    floor(130 + random() * 170)::integer,
    'desktop'
FROM (
    SELECT
        generate_series,
        (ARRAY['professional', 'enterprise'])[floor(random() * 2 + 1)] as tier,
        (ARRAY['north_america', 'europe'])[floor(random() * 2 + 1)] as region,
        CASE
            WHEN floor(random() * 2 + 1) = 1 THEN 699.0
            ELSE 1299.0
        END as base_price,
        CASE
            WHEN floor(random() * 2 + 1) = 1 THEN 599.0
            ELSE 1199.0
        END as current_price
    FROM generate_series(1, 600)
) sub;

-- ================================================================
-- COMPETITOR PRICING DATA
-- ================================================================

INSERT INTO competitor_pricing (
    competitor_name, product_name, product_tier, price, billing_cycle, currency,
    features, feature_count, market_share, estimated_customers, data_source, scraped_at, verified
) VALUES
-- Competitor A
('SecretVault Pro', 'SecretVault Pro Personal', 'basic', 19.99, 'monthly', 'USD',
    '{"storage": "100MB", "secrets": 50, "ttl": "7 days", "support": "email"}'::jsonb, 4, 0.15, 25000, 'public_pricing', NOW(), true),
('SecretVault Pro', 'SecretVault Pro Team', 'professional', 99.99, 'monthly', 'USD',
    '{"storage": "1GB", "secrets": "unlimited", "ttl": "30 days", "support": "priority", "api": true}'::jsonb, 6, 0.15, 8000, 'public_pricing', NOW(), true),
('SecretVault Pro', 'SecretVault Pro Enterprise', 'enterprise', 499.99, 'monthly', 'USD',
    '{"storage": "unlimited", "secrets": "unlimited", "ttl": "custom", "support": "24/7", "api": true, "sso": true, "audit": true}'::jsonb, 10, 0.15, 2000, 'public_pricing', NOW(), true),

-- Competitor B
('ConfidentialShare', 'ConfidentialShare Starter', 'basic', 24.99, 'monthly', 'USD',
    '{"storage": "250MB", "secrets": 100, "ttl": "14 days", "support": "chat"}'::jsonb, 4, 0.22, 35000, 'public_pricing', NOW(), true),
('ConfidentialShare', 'ConfidentialShare Business', 'professional', 149.99, 'monthly', 'USD',
    '{"storage": "5GB", "secrets": "unlimited", "ttl": "90 days", "support": "priority", "api": true, "webhooks": true}'::jsonb, 7, 0.22, 12000, 'public_pricing', NOW(), true),
('ConfidentialShare', 'ConfidentialShare Corporate', 'enterprise', 699.99, 'monthly', 'USD',
    '{"storage": "unlimited", "secrets": "unlimited", "ttl": "custom", "support": "24/7", "api": true, "sso": true, "audit": true, "compliance": true}'::jsonb, 11, 0.22, 3000, 'public_pricing', NOW(), true),

-- Competitor C
('SecurePass', 'SecurePass Individual', 'basic', 9.99, 'monthly', 'USD',
    '{"storage": "50MB", "secrets": 25, "ttl": "3 days", "support": "email"}'::jsonb, 3, 0.08, 15000, 'public_pricing', NOW(), true),
('SecurePass', 'SecurePass Professional', 'professional', 79.99, 'monthly', 'USD',
    '{"storage": "500MB", "secrets": 500, "ttl": "30 days", "support": "email", "api": true}'::jsonb, 5, 0.08, 5000, 'public_pricing', NOW(), true),
('SecurePass', 'SecurePass Enterprise', 'enterprise', 399.99, 'monthly', 'USD',
    '{"storage": "10GB", "secrets": "unlimited", "ttl": "custom", "support": "priority", "api": true, "sso": true}'::jsonb, 8, 0.08, 1500, 'public_pricing', NOW(), true);

-- ================================================================
-- A/B TEST EXPERIMENTS
-- ================================================================

INSERT INTO ab_test_experiments (
    experiment_name, experiment_type, product_tier,
    control_price, treatment_price, allocation_ratio,
    minimum_sample_size, target_statistical_power, significance_level, minimum_detectable_effect,
    status, start_date, end_date, primary_metric, success_threshold, created_by
) VALUES
('professional_tier_price_increase_q4_2025', 'price_point', 'professional',
    299.00, 349.00, 0.5, 2000, 0.80, 0.05, 0.05,
    'active', NOW() - INTERVAL '14 days', NOW() + INTERVAL '16 days', 'revenue', 0.10, 'pricing_team'),

('enterprise_value_pricing_test', 'price_point', 'enterprise',
    999.00, 1299.00, 0.5, 1000, 0.85, 0.05, 0.08,
    'active', NOW() - INTERVAL '7 days', NOW() + INTERVAL '23 days', 'revenue', 0.15, 'pricing_team'),

('basic_tier_penetration_pricing', 'price_point', 'basic',
    49.00, 39.00, 0.5, 3000, 0.80, 0.05, 0.05,
    'completed', NOW() - INTERVAL '45 days', NOW() - INTERVAL '15 days', 'conversion', 0.20, 'growth_team');

-- ================================================================
-- A/B TEST ASSIGNMENTS (for active experiments)
-- ================================================================

-- Professional tier test assignments
INSERT INTO ab_test_assignments (
    experiment_id, user_id, session_id, variant, assigned_price,
    market_segment, geographic_region, device_type
)
SELECT
    (SELECT id FROM ab_test_experiments WHERE experiment_name = 'professional_tier_price_increase_q4_2025'),
    'ab_user_' || generate_series,
    'ab_session_prof_' || generate_series || '_' || floor(random() * 1000000),
    CASE WHEN random() < 0.5 THEN 'control' ELSE 'treatment' END,
    CASE WHEN random() < 0.5 THEN 299.00 ELSE 349.00 END,
    (ARRAY['enterprise_tech', 'startup_growth', 'healthcare_providers'])[floor(random() * 3 + 1)],
    (ARRAY['north_america', 'europe', 'asia_pacific'])[floor(random() * 3 + 1)],
    (ARRAY['desktop', 'mobile'])[floor(random() * 2 + 1)]
FROM generate_series(1, 1500);

-- Enterprise tier test assignments
INSERT INTO ab_test_assignments (
    experiment_id, user_id, session_id, variant, assigned_price,
    market_segment, geographic_region, device_type
)
SELECT
    (SELECT id FROM ab_test_experiments WHERE experiment_name = 'enterprise_value_pricing_test'),
    'ab_user_ent_' || generate_series,
    'ab_session_ent_' || generate_series || '_' || floor(random() * 1000000),
    CASE WHEN random() < 0.5 THEN 'control' ELSE 'treatment' END,
    CASE WHEN random() < 0.5 THEN 999.00 ELSE 1299.00 END,
    (ARRAY['enterprise_tech', 'financial_services', 'healthcare_providers'])[floor(random() * 3 + 1)],
    (ARRAY['north_america', 'europe', 'asia_pacific'])[floor(random() * 3 + 1)],
    'desktop'
FROM generate_series(1, 800);

-- ================================================================
-- A/B TEST RESULTS
-- ================================================================

-- Professional tier test results
INSERT INTO ab_test_results (
    experiment_id, assignment_id, converted, revenue, conversion_timestamp,
    page_views, time_on_page_seconds, clicked_cta, abandoned, abandon_reason
)
SELECT
    a.experiment_id,
    a.id,
    CASE
        WHEN a.variant = 'control' THEN random() < 0.12
        ELSE random() < 0.10
    END,
    CASE
        WHEN (CASE WHEN a.variant = 'control' THEN random() < 0.12 ELSE random() < 0.10 END)
        THEN a.assigned_price
        ELSE 0
    END,
    CASE
        WHEN (CASE WHEN a.variant = 'control' THEN random() < 0.12 ELSE random() < 0.10 END)
        THEN a.assigned_at + (random() * INTERVAL '3 days')
        ELSE NULL
    END,
    floor(1 + random() * 10)::integer,
    floor(30 + random() * 300)::integer,
    random() < 0.3,
    CASE WHEN NOT (CASE WHEN a.variant = 'control' THEN random() < 0.12 ELSE random() < 0.10 END) THEN random() < 0.4 ELSE false END,
    CASE
        WHEN random() < 0.4 THEN (ARRAY['too_expensive', 'missing_features', 'competitor', NULL])[floor(random() * 4 + 1)]
        ELSE NULL
    END
FROM ab_test_assignments a
WHERE a.experiment_id = (SELECT id FROM ab_test_experiments WHERE experiment_name = 'professional_tier_price_increase_q4_2025');

-- Enterprise tier test results
INSERT INTO ab_test_results (
    experiment_id, assignment_id, converted, revenue, conversion_timestamp,
    page_views, time_on_page_seconds, clicked_cta, abandoned, abandon_reason
)
SELECT
    a.experiment_id,
    a.id,
    CASE
        WHEN a.variant = 'control' THEN random() < 0.08
        ELSE random() < 0.095
    END,
    CASE
        WHEN (CASE WHEN a.variant = 'control' THEN random() < 0.08 ELSE random() < 0.095 END)
        THEN a.assigned_price
        ELSE 0
    END,
    CASE
        WHEN (CASE WHEN a.variant = 'control' THEN random() < 0.08 ELSE random() < 0.095 END)
        THEN a.assigned_at + (random() * INTERVAL '5 days')
        ELSE NULL
    END,
    floor(2 + random() * 15)::integer,
    floor(60 + random() * 450)::integer,
    random() < 0.5,
    CASE WHEN NOT (CASE WHEN a.variant = 'control' THEN random() < 0.08 ELSE random() < 0.095 END) THEN random() < 0.3 ELSE false END,
    CASE
        WHEN random() < 0.3 THEN (ARRAY['needs_approval', 'budget_constraints', 'evaluation_period', NULL])[floor(random() * 4 + 1)]
        ELSE NULL
    END
FROM ab_test_assignments a
WHERE a.experiment_id = (SELECT id FROM ab_test_experiments WHERE experiment_name = 'enterprise_value_pricing_test');

-- ================================================================
-- REVENUE METRICS (Last 90 days)
-- ================================================================

INSERT INTO revenue_metrics (
    metric_date, product_tier, market_segment,
    daily_revenue, new_customer_revenue, expansion_revenue, churn_revenue,
    new_customers, churned_customers, total_active_customers,
    conversion_rate, average_revenue_per_user, customer_acquisition_cost, customer_lifetime_value,
    effective_price
)
SELECT
    dates.metric_date,
    tiers.tier,
    segments.segment,
    -- Revenue calculations
    ROUND((base_revenue * (1 + (random() - 0.5) * 0.3))::numeric, 2),
    ROUND((base_revenue * 0.3 * (1 + (random() - 0.5) * 0.4))::numeric, 2),
    ROUND((base_revenue * 0.1 * (1 + (random() - 0.5) * 0.5))::numeric, 2),
    ROUND((base_revenue * 0.05 * (1 + (random() - 0.5) * 0.6))::numeric, 2),
    -- Customer counts
    floor(new_customers * (1 + (random() - 0.5) * 0.4))::integer,
    floor(churned * (1 + (random() - 0.5) * 0.5))::integer,
    floor(active_base * (1 + idx * 0.01))::integer,
    -- Performance metrics
    ROUND((conversion * (1 + (random() - 0.5) * 0.2))::numeric, 4),
    ROUND((arpu * (1 + (random() - 0.5) * 0.15))::numeric, 2),
    ROUND((cac * (1 + (random() - 0.5) * 0.25))::numeric, 2),
    ROUND((ltv * (1 + (random() - 0.5) * 0.2))::numeric, 2),
    effective_price
FROM (
    SELECT generate_series::date AS metric_date, generate_series AS idx
    FROM generate_series(CURRENT_DATE - INTERVAL '90 days', CURRENT_DATE - INTERVAL '1 day', '1 day'::interval)
) dates
CROSS JOIN (
    VALUES
        ('free', 0.00),
        ('basic', 29.00),
        ('professional', 299.00),
        ('enterprise', 999.00),
        ('premium', 1999.00)
) AS tiers(tier, effective_price)
CROSS JOIN (
    VALUES
        ('enterprise_tech', 5000.0, 15, 3, 250, 0.0850, 250.00, 120.00, 12000.00),
        ('startup_growth', 8000.0, 25, 6, 400, 0.1200, 180.00, 80.00, 3600.00),
        ('individual_developers', 2000.0, 50, 15, 800, 0.0500, 40.00, 25.00, 480.00),
        ('financial_services', 12000.0, 8, 2, 150, 0.0650, 800.00, 200.00, 24000.00),
        ('healthcare_providers', 7000.0, 12, 3, 280, 0.0750, 450.00, 150.00, 15000.00)
) AS segments(segment, base_revenue, new_customers, churned, active_base, conversion, arpu, cac, ltv);

-- ================================================================
-- SAMPLE PRICING ALERTS
-- ================================================================

INSERT INTO pricing_alerts (
    alert_type, severity, title, description,
    metric_name, current_value, threshold_value, deviation_percentage,
    product_tier, market_segment, status
) VALUES
('conversion_drop', 'critical', 'Professional Tier Conversion Rate Drop',
    'Professional tier conversion rate has dropped 15% below target in the last 7 days',
    'conversion_rate', 0.0950, 0.1200, -20.83,
    'professional', 'startup_growth', 'open'),

('competitor_change', 'warning', 'Competitor Price Decrease Detected',
    'ConfidentialShare reduced Business tier price from $149.99 to $129.99',
    'competitor_price', 129.99, 149.99, -13.34,
    'professional', NULL, 'acknowledged'),

('revenue_decline', 'warning', 'Enterprise Revenue Declining',
    'Enterprise tier daily revenue trending down 8% over last 14 days',
    'daily_revenue', 11040.00, 12000.00, -8.00,
    'enterprise', 'financial_services', 'open');

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================

-- Summary statistics
DO $$
DECLARE
    response_count INTEGER;
    segment_count INTEGER;
    experiment_count INTEGER;
    metric_days INTEGER;
BEGIN
    SELECT COUNT(*) INTO response_count FROM price_sensitivity_responses;
    SELECT COUNT(*) INTO segment_count FROM market_segments;
    SELECT COUNT(*) INTO experiment_count FROM ab_test_experiments;
    SELECT COUNT(DISTINCT metric_date) INTO metric_days FROM revenue_metrics;

    RAISE NOTICE '=== Sample Data Summary ===';
    RAISE NOTICE 'Price Sensitivity Responses: %', response_count;
    RAISE NOTICE 'Market Segments: %', segment_count;
    RAISE NOTICE 'A/B Test Experiments: %', experiment_count;
    RAISE NOTICE 'Revenue Metric Days: %', metric_days;
END $$;
