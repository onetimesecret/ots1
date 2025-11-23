-- =============================================================================
-- PHASE 1: Sample Data for Testing
-- Van Westendorp Price Optimization System
-- =============================================================================

-- =============================================================================
-- Sample Market Segments
-- =============================================================================
INSERT INTO market_segments (segment_id, segment_name, segment_description, geographic_region, company_size, industry) VALUES
('11111111-1111-1111-1111-111111111111', 'Enterprise Technology', 'Large technology companies with advanced security needs', 'North America', 'enterprise', 'Technology'),
('22222222-2222-2222-2222-222222222222', 'Financial Services SMB', 'Small to mid-size financial institutions', 'North America', 'mid-market', 'Finance'),
('33333333-3333-3333-3333-333333333333', 'Healthcare Compliance', 'Healthcare providers requiring HIPAA compliance', 'North America', 'mid-market', 'Healthcare'),
('44444444-4444-4444-4444-444444444444', 'Individual Developers', 'Solo developers and small dev teams', 'Global', 'individual', 'Technology'),
('55555555-5555-5555-5555-555555555555', 'European Enterprise', 'Large European corporations with GDPR focus', 'Europe', 'enterprise', 'Various');

-- =============================================================================
-- Sample Product Tiers
-- =============================================================================
INSERT INTO product_tiers (tier_id, tier_name, tier_level, feature_description, max_secrets_per_month, max_ttl_days, api_access_level, support_level) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Free', 1, 'Basic secret sharing for personal use', 10, 7, 'none', 'community'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Starter', 2, 'For small teams and projects', 100, 30, 'basic', 'email'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Professional', 3, 'Advanced features for professional use', 1000, 90, 'standard', 'priority'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Business', 4, 'Complete solution for businesses', 10000, 365, 'premium', 'priority'),
('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Enterprise', 5, 'Unlimited usage with dedicated support', 999999, 365, 'enterprise', 'dedicated');

-- =============================================================================
-- Sample Survey Respondents
-- =============================================================================
INSERT INTO survey_respondents (respondent_id, segment_id, email_hash, demographic_data, completed_at, survey_version, is_valid) VALUES
-- Enterprise Technology segment
('r0000001-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
 encode(digest('user1@enterprise.com', 'sha256'), 'hex'),
 '{"role": "CTO", "company_employees": 5000, "budget_authority": true}',
 '2024-11-01 10:00:00-05', 'v1.0', true),

('r0000002-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
 encode(digest('user2@enterprise.com', 'sha256'), 'hex'),
 '{"role": "Security Engineer", "company_employees": 3000, "budget_authority": false}',
 '2024-11-01 11:30:00-05', 'v1.0', true),

-- Financial Services SMB segment
('r0000003-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222',
 encode(digest('user3@fintech.com', 'sha256'), 'hex'),
 '{"role": "Compliance Officer", "company_employees": 150, "budget_authority": true}',
 '2024-11-02 09:15:00-05', 'v1.0', true),

('r0000004-0000-0000-0000-000000000004', '22222222-2222-2222-2222-222222222222',
 encode(digest('user4@fintech.com', 'sha256'), 'hex'),
 '{"role": "IT Manager", "company_employees": 200, "budget_authority": true}',
 '2024-11-02 14:20:00-05', 'v1.0', true),

-- Healthcare segment
('r0000005-0000-0000-0000-000000000005', '33333333-3333-3333-3333-333333333333',
 encode(digest('user5@healthcare.com', 'sha256'), 'hex'),
 '{"role": "HIPAA Officer", "company_employees": 500, "budget_authority": true}',
 '2024-11-03 08:45:00-05', 'v1.0', true),

-- Individual Developers
('r0000006-0000-0000-0000-000000000006', '44444444-4444-4444-4444-444444444444',
 encode(digest('dev1@freelance.com', 'sha256'), 'hex'),
 '{"role": "Freelance Developer", "company_employees": 1, "budget_authority": true}',
 '2024-11-04 16:30:00-05', 'v1.0', true),

('r0000007-0000-0000-0000-000000000007', '44444444-4444-4444-4444-444444444444',
 encode(digest('dev2@startup.com', 'sha256'), 'hex'),
 '{"role": "Startup Founder", "company_employees": 5, "budget_authority": true}',
 '2024-11-04 17:00:00-05', 'v1.0', true);

-- =============================================================================
-- Sample Price Sensitivity Responses (Van Westendorp)
-- All prices in USD cents
-- =============================================================================

-- Enterprise tier responses from Enterprise Technology segment
INSERT INTO price_sensitivity_responses (
    respondent_id, tier_id,
    too_cheap_price, bargain_price, expensive_price, too_expensive_price,
    current_spending, willingness_to_switch, price_sensitivity_score,
    perceived_value_score, feature_importance
) VALUES
('r0000001-0000-0000-0000-000000000001', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
 50000, 75000, 150000, 200000, -- $500, $750, $1500, $2000 per month
 120000, 7, 6, 9,
 '{"encryption": 10, "api_access": 9, "support": 10, "compliance": 9, "ttl": 7}'::jsonb),

('r0000002-0000-0000-0000-000000000002', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
 40000, 60000, 120000, 180000,
 100000, 6, 7, 8,
 '{"encryption": 10, "api_access": 8, "support": 8, "compliance": 10, "ttl": 6}'::jsonb);

-- Business tier responses from Financial Services SMB
INSERT INTO price_sensitivity_responses (
    respondent_id, tier_id,
    too_cheap_price, bargain_price, expensive_price, too_expensive_price,
    current_spending, willingness_to_switch, price_sensitivity_score,
    perceived_value_score, feature_importance
) VALUES
('r0000003-0000-0000-0000-000000000003', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
 2000, 3500, 7500, 12000, -- $20, $35, $75, $120 per month
 5000, 8, 7, 8,
 '{"encryption": 10, "api_access": 7, "support": 9, "compliance": 10, "ttl": 8}'::jsonb),

('r0000004-0000-0000-0000-000000000004', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
 2500, 4000, 8000, 15000,
 6000, 7, 6, 9,
 '{"encryption": 9, "api_access": 8, "support": 8, "compliance": 10, "ttl": 7}'::jsonb);

-- Professional tier responses from Healthcare
INSERT INTO price_sensitivity_responses (
    respondent_id, tier_id,
    too_cheap_price, bargain_price, expensive_price, too_expensive_price,
    current_spending, willingness_to_switch, price_sensitivity_score,
    perceived_value_score, feature_importance
) VALUES
('r0000005-0000-0000-0000-000000000005', 'cccccccc-cccc-cccc-cccc-cccccccccccc',
 1000, 2000, 5000, 8000, -- $10, $20, $50, $80 per month
 3000, 6, 5, 8,
 '{"encryption": 10, "api_access": 6, "support": 7, "compliance": 10, "ttl": 8}'::jsonb);

-- Starter tier responses from Individual Developers
INSERT INTO price_sensitivity_responses (
    respondent_id, tier_id,
    too_cheap_price, bargain_price, expensive_price, too_expensive_price,
    current_spending, willingness_to_switch, price_sensitivity_score,
    perceived_value_score, feature_importance
) VALUES
('r0000006-0000-0000-0000-000000000006', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
 300, 500, 1500, 2500, -- $3, $5, $15, $25 per month
 800, 9, 8, 7,
 '{"encryption": 8, "api_access": 9, "support": 5, "compliance": 4, "ttl": 7}'::jsonb),

('r0000007-0000-0000-0000-000000000007', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
 400, 700, 2000, 3000,
 1200, 8, 7, 8,
 '{"encryption": 9, "api_access": 10, "support": 6, "compliance": 5, "ttl": 8}'::jsonb);

-- =============================================================================
-- Sample Competitive Pricing Data
-- =============================================================================
INSERT INTO competitive_pricing (
    competitor_name, product_name, tier_equivalent,
    current_price, billing_period, feature_matrix, market_share_percentage,
    price_history, data_source, verified, last_verified_at
) VALUES
('PrivateBin', 'Free Tier', 'Free',
 0, 'monthly',
 '{"encryption": true, "api": false, "support": "community", "max_secrets": "unlimited", "ttl": "1 year"}'::jsonb,
 15.5,
 '[{"date": "2024-01-01", "price": 0}, {"date": "2024-06-01", "price": 0}]'::jsonb,
 'Public Website', true, '2024-11-01 00:00:00-05'),

('Yopass', 'Self-Hosted', 'Professional',
 0, 'one-time',
 '{"encryption": true, "api": true, "support": "community", "max_secrets": "unlimited", "ttl": "custom"}'::jsonb,
 8.3,
 '[{"date": "2024-01-01", "price": 0}]'::jsonb,
 'GitHub', true, '2024-11-01 00:00:00-05'),

('SecureNote Pro', 'Business Plan', 'Business',
 4999, 'monthly', -- $49.99/month
 '{"encryption": true, "api": true, "support": "email", "max_secrets": 5000, "ttl": "90 days"}'::jsonb,
 12.1,
 '[{"date": "2024-01-01", "price": 3999}, {"date": "2024-07-01", "price": 4999}]'::jsonb,
 'Competitor Website', true, '2024-11-15 00:00:00-05'),

('VaultShare', 'Enterprise', 'Enterprise',
 99900, 'monthly', -- $999/month
 '{"encryption": true, "api": true, "support": "dedicated", "max_secrets": "unlimited", "ttl": "custom", "sso": true}'::jsonb,
 5.7,
 '[{"date": "2023-12-01", "price": 89900}, {"date": "2024-06-01", "price": 99900}]'::jsonb,
 'Sales Call', true, '2024-11-10 00:00:00-05'),

('SecretDrop', 'Premium', 'Professional',
 2999, 'monthly', -- $29.99/month
 '{"encryption": true, "api": true, "support": "priority", "max_secrets": 1000, "ttl": "60 days"}'::jsonb,
 18.9,
 '[{"date": "2024-01-01", "price": 2499}, {"date": "2024-05-01", "price": 2999}]'::jsonb,
 'Competitor Website', true, '2024-11-20 00:00:00-05');

-- =============================================================================
-- Sample Price Elasticity Coefficients
-- =============================================================================
INSERT INTO price_elasticity_coefficients (
    segment_id, tier_id,
    price_elasticity_of_demand, cross_price_elasticity, income_elasticity,
    standard_error, r_squared, p_value,
    confidence_interval_lower, confidence_interval_upper,
    sample_size, calculation_method, model_parameters
) VALUES
-- Enterprise segment, Enterprise tier (less price sensitive)
('11111111-1111-1111-1111-111111111111', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
 -0.85, 0.45, 1.2,
 0.08, 0.89, 0.001,
 -0.95, -0.75,
 150, 'Log-log regression',
 '{"method": "OLS", "controls": ["company_size", "industry"], "time_period": "12_months"}'::jsonb),

-- Financial Services, Business tier (moderately price sensitive)
('22222222-2222-2222-2222-222222222222', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
 -1.35, 0.68, 0.95,
 0.12, 0.82, 0.003,
 -1.50, -1.20,
 95, 'Log-log regression',
 '{"method": "OLS", "controls": ["company_size", "compliance_requirements"], "time_period": "12_months"}'::jsonb),

-- Healthcare, Professional tier (moderately price sensitive)
('33333333-3333-3333-3333-333333333333', 'cccccccc-cccc-cccc-cccc-cccccccccccc',
 -1.15, 0.52, 1.05,
 0.10, 0.86, 0.002,
 -1.28, -1.02,
 78, 'Log-log regression',
 '{"method": "OLS", "controls": ["compliance_requirements", "patient_count"], "time_period": "12_months"}'::jsonb),

-- Individual Developers, Starter tier (highly price sensitive)
('44444444-4444-4444-4444-444444444444', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
 -2.15, 0.95, 0.65,
 0.18, 0.75, 0.008,
 -2.45, -1.85,
 220, 'Log-log regression',
 '{"method": "OLS", "controls": ["usage_frequency", "free_alternatives_available"], "time_period": "12_months"}'::jsonb);

-- =============================================================================
-- Sample Van Westendorp Analysis Results
-- =============================================================================
INSERT INTO van_westendorp_analysis (
    segment_id, tier_id, analysis_date,
    point_of_marginal_cheapness, point_of_marginal_expensiveness,
    optimal_price_point, indifference_price_point,
    acceptable_price_range_lower, acceptable_price_range_upper,
    recommended_price, expected_conversion_rate, expected_revenue_per_customer,
    sample_size, confidence_score, data_quality_score,
    median_acceptable_price, mean_acceptable_price, standard_deviation,
    algorithm_version
) VALUES
-- Enterprise tier analysis
('11111111-1111-1111-1111-111111111111', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
 '2024-11-15 00:00:00-05',
 65000, 165000,  -- PMC: $650, PME: $1650
 110000, 95000,  -- OPP: $1100, IPP: $950
 75000, 150000,  -- Acceptable range: $750-$1500
 120000, 0.2850, 120000,  -- Recommended: $1200, 28.5% conversion
 150, 0.92, 0.94,
 110000, 112500, 28000,
 '1.0.0'),

-- Business tier analysis
('22222222-2222-2222-2222-222222222222', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
 '2024-11-15 00:00:00-05',
 3200, 9500,    -- PMC: $32, PME: $95
 5800, 4900,    -- OPP: $58, IPP: $49
 3500, 8000,    -- Acceptable range: $35-$80
 5500, 0.3250, 5500,  -- Recommended: $55, 32.5% conversion
 95, 0.88, 0.91,
 5800, 5950, 1850,
 '1.0.0'),

-- Professional tier analysis
('33333333-3333-3333-3333-333333333333', 'cccccccc-cccc-cccc-cccc-cccccccccccc',
 '2024-11-15 00:00:00-05',
 1500, 6000,    -- PMC: $15, PME: $60
 3400, 2800,    -- OPP: $34, IPP: $28
 2000, 5000,    -- Acceptable range: $20-$50
 3200, 0.3580, 3200,  -- Recommended: $32, 35.8% conversion
 78, 0.85, 0.89,
 3400, 3550, 1200,
 '1.0.0'),

-- Starter tier analysis
('44444444-4444-4444-4444-444444444444', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
 '2024-11-15 00:00:00-05',
 450, 2200,     -- PMC: $4.50, PME: $22
 1100, 900,     -- OPP: $11, IPP: $9
 500, 1500,     -- Acceptable range: $5-$15
 900, 0.4250, 900,  -- Recommended: $9, 42.5% conversion
 220, 0.82, 0.87,
 1100, 1150, 520,
 '1.0.0');

-- =============================================================================
-- Sample Optimization Simulations
-- =============================================================================
-- Generate simulations for different price points and market conditions
INSERT INTO optimization_simulations (
    analysis_id, price_point_tested, market_condition,
    projected_monthly_revenue, projected_annual_revenue,
    projected_conversion_rate, projected_customer_count,
    projected_churn_rate, customer_lifetime_value,
    customer_acquisition_cost, operating_cost_per_customer,
    gross_margin, net_revenue, roi,
    revenue_at_risk, risk_score,
    revenue_ci_lower, revenue_ci_upper,
    conversion_ci_lower, conversion_ci_upper,
    monte_carlo_iterations, random_seed, convergence_achieved
)
SELECT
    vwa.analysis_id,
    price_point,
    market_cond,
    -- Revenue calculations
    ROUND(price_point * customers * conversion)::BIGINT AS projected_monthly_revenue,
    ROUND(price_point * customers * conversion * 12)::BIGINT AS projected_annual_revenue,
    conversion AS projected_conversion_rate,
    ROUND(customers * conversion)::INTEGER AS projected_customer_count,
    churn_rate AS projected_churn_rate,
    ROUND(price_point * (1 / churn_rate) * 12)::INTEGER AS customer_lifetime_value,
    -- Costs
    ROUND(price_point * 0.3)::INTEGER AS customer_acquisition_cost,
    ROUND(price_point * 0.15)::INTEGER AS operating_cost_per_customer,
    -- Profitability
    0.55 AS gross_margin,
    ROUND(price_point * customers * conversion * 0.55)::BIGINT AS net_revenue,
    1.85 AS roi,
    -- Risk
    ROUND(price_point * customers * conversion * 0.15)::INTEGER AS revenue_at_risk,
    risk AS risk_score,
    -- Confidence intervals
    ROUND(price_point * customers * conversion * 0.85)::BIGINT AS revenue_ci_lower,
    ROUND(price_point * customers * conversion * 1.15)::BIGINT AS revenue_ci_upper,
    conversion * 0.92 AS conversion_ci_lower,
    conversion * 1.08 AS conversion_ci_upper,
    -- Simulation metadata
    10000 AS monte_carlo_iterations,
    42 AS random_seed,
    true AS convergence_achieved
FROM van_westendorp_analysis vwa
CROSS JOIN LATERAL (
    VALUES
        (vwa.recommended_price * 0.8, 'bear', 1000, 0.25, 0.08, 0.35),
        (vwa.recommended_price * 0.9, 'bear', 1000, 0.27, 0.07, 0.28),
        (vwa.recommended_price, 'base', 1000, vwa.expected_conversion_rate, 0.06, 0.18),
        (vwa.recommended_price * 1.1, 'base', 1000, vwa.expected_conversion_rate * 0.92, 0.06, 0.22),
        (vwa.recommended_price * 1.2, 'bull', 1000, vwa.expected_conversion_rate * 0.85, 0.05, 0.25)
) AS sim(price_point, market_cond, customers, conversion, churn_rate, risk)
WHERE vwa.is_current = true;

-- =============================================================================
-- Sample A/B Test Experiment
-- =============================================================================
INSERT INTO ab_test_experiments (
    experiment_id, experiment_name, segment_id, tier_id,
    control_price, variant_prices,
    required_sample_size, statistical_power, significance_level, minimum_detectable_effect,
    start_date, planned_end_date, status,
    primary_metric, secondary_metrics, success_threshold,
    max_allowed_revenue_loss, auto_stop_enabled,
    hypothesis
) VALUES
('test0001-0001-0001-0001-000000000001', 'Starter Tier Price Test Q4 2024',
 '44444444-4444-4444-4444-444444444444', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
 900, ARRAY[700, 900, 1100], -- Control: $9, Variants: $7, $9, $11
 3840, 0.80, 0.05, 0.15,
 '2024-11-01 00:00:00-05', '2024-12-01 00:00:00-05', 'completed',
 'revenue_per_visitor', ARRAY['conversion_rate', 'customer_lifetime_value', 'churn_rate'],
 1.10, -- 10% revenue increase
 50000, true,
 'Lowering price from $9 to $7 will increase conversion rate enough to offset lower per-customer revenue');

-- =============================================================================
-- Sample Price Change History
-- =============================================================================
INSERT INTO price_changes_history (
    tier_id, segment_id,
    previous_price, new_price,
    effective_date, announcement_date,
    change_reason, expected_revenue_impact,
    requested_by, approved_by, approval_date
) VALUES
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', NULL,
 1000, 900, -- Changed from $10 to $9
 '2024-10-01 00:00:00-05', '2024-09-15 00:00:00-05',
 'Van Westendorp analysis showed optimal price point at $9',
 15000000, -- Expected $150k annual increase
 'pricing_team', 'cfo', '2024-09-20 00:00:00-05'),

('cccccccc-cccc-cccc-cccc-cccccccccccc', NULL,
 3500, 3200,
 '2024-10-15 00:00:00-05', '2024-10-01 00:00:00-05',
 'Competitive response to SecretDrop pricing',
 8000000,
 'pricing_team', 'ceo', '2024-10-05 00:00:00-05');

-- =============================================================================
-- Sample Pricing Metrics (Last 30 days)
-- =============================================================================
INSERT INTO pricing_metrics (
    tier_id, segment_id, metric_date,
    total_revenue, average_revenue_per_user,
    new_customers, churned_customers, active_customers,
    total_visitors, pricing_page_views, conversion_rate,
    price_displayed, discounts_applied, discount_amount,
    market_share_estimate
)
SELECT
    tier_id,
    segment_id,
    date_val,
    ROUND(RANDOM() * 50000 + 20000)::BIGINT AS total_revenue,
    ROUND(RANDOM() * 5000 + 2000)::INTEGER AS arpu,
    ROUND(RANDOM() * 50 + 10)::INTEGER AS new_customers,
    ROUND(RANDOM() * 10 + 2)::INTEGER AS churned_customers,
    ROUND(RANDOM() * 200 + 100)::INTEGER AS active_customers,
    ROUND(RANDOM() * 1000 + 500)::INTEGER AS total_visitors,
    ROUND(RANDOM() * 300 + 100)::INTEGER AS pricing_page_views,
    (RANDOM() * 0.2 + 0.25)::DECIMAL(5,4) AS conversion_rate,
    vwa.recommended_price,
    ROUND(RANDOM() * 5)::INTEGER AS discounts_applied,
    ROUND(RANDOM() * 500)::INTEGER AS discount_amount,
    (RANDOM() * 0.05 + 0.10)::DECIMAL(5,4) AS market_share
FROM van_westendorp_analysis vwa
CROSS JOIN generate_series(
    CURRENT_DATE - INTERVAL '30 days',
    CURRENT_DATE - INTERVAL '1 day',
    INTERVAL '1 day'
) AS date_val
WHERE vwa.is_current = true;

-- =============================================================================
-- Sample Alert Configurations
-- =============================================================================
INSERT INTO pricing_alerts (
    alert_name, alert_type,
    threshold_value, threshold_operator, lookback_period_days,
    tier_id, segment_id,
    notify_emails, auto_rollback, is_active
) VALUES
('Revenue Drop Critical', 'revenue_drop',
 -0.20, '<', 7,
 NULL, NULL,
 ARRAY['pricing-team@onetimesecret.com', 'cfo@onetimesecret.com'],
 true, true),

('Conversion Rate Drop', 'conversion_drop',
 -0.15, '<', 3,
 NULL, NULL,
 ARRAY['pricing-team@onetimesecret.com'],
 false, true),

('High Customer Churn', 'customer_churn',
 0.10, '>', 7,
 NULL, NULL,
 ARRAY['customer-success@onetimesecret.com', 'pricing-team@onetimesecret.com'],
 false, true),

('Competitor Price Change', 'competitor_change',
 0.05, '>', 1,
 NULL, NULL,
 ARRAY['competitive-intel@onetimesecret.com', 'pricing-team@onetimesecret.com'],
 false, true);

-- =============================================================================
-- Verification Queries Summary
-- =============================================================================
-- Run these to verify the data was inserted correctly:
--
-- SELECT COUNT(*) FROM market_segments;           -- Expected: 5
-- SELECT COUNT(*) FROM product_tiers;            -- Expected: 5
-- SELECT COUNT(*) FROM survey_respondents;       -- Expected: 7
-- SELECT COUNT(*) FROM price_sensitivity_responses; -- Expected: 7
-- SELECT COUNT(*) FROM competitive_pricing;      -- Expected: 5
-- SELECT COUNT(*) FROM price_elasticity_coefficients; -- Expected: 4
-- SELECT COUNT(*) FROM van_westendorp_analysis;  -- Expected: 4
-- SELECT COUNT(*) FROM optimization_simulations; -- Expected: 20 (4 analyses × 5 scenarios)
-- SELECT COUNT(*) FROM ab_test_experiments;      -- Expected: 1
-- SELECT COUNT(*) FROM price_changes_history;    -- Expected: 2
-- SELECT COUNT(*) FROM pricing_metrics;          -- Expected: 120 (4 current analyses × 30 days)
-- SELECT COUNT(*) FROM pricing_alerts;           -- Expected: 4
