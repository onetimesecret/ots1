-- ================================================================
-- PRICE OPTIMIZATION SYSTEM - DATABASE SCHEMA
-- Van Westendorp Price Sensitivity Analysis
-- ================================================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ================================================================
-- CORE PRICE SENSITIVITY TABLES
-- ================================================================

-- Price sensitivity survey responses
CREATE TABLE price_sensitivity_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id VARCHAR(255),
    session_id VARCHAR(255) NOT NULL,
    product_tier VARCHAR(50) NOT NULL CHECK (product_tier IN ('free', 'basic', 'professional', 'enterprise', 'premium')),
    market_segment VARCHAR(100) NOT NULL,
    geographic_region VARCHAR(50) NOT NULL,

    -- Van Westendorp Four Key Price Points
    too_cheap_price DECIMAL(10,2) NOT NULL CHECK (too_cheap_price >= 0),
    cheap_price DECIMAL(10,2) NOT NULL CHECK (cheap_price >= too_cheap_price),
    expensive_price DECIMAL(10,2) NOT NULL CHECK (expensive_price >= cheap_price),
    too_expensive_price DECIMAL(10,2) NOT NULL CHECK (too_expensive_price >= expensive_price),

    -- Additional Context
    current_price_paid DECIMAL(10,2),
    willingness_to_switch DECIMAL(3,2) CHECK (willingness_to_switch BETWEEN 0 AND 1),
    usage_frequency VARCHAR(20) CHECK (usage_frequency IN ('daily', 'weekly', 'monthly', 'quarterly', 'yearly')),
    company_size VARCHAR(20) CHECK (company_size IN ('individual', 'small', 'medium', 'large', 'enterprise')),
    industry VARCHAR(100),

    -- Metadata
    survey_version VARCHAR(20) NOT NULL DEFAULT 'v1.0',
    response_quality_score DECIMAL(3,2) CHECK (response_quality_score BETWEEN 0 AND 1),
    response_time_seconds INTEGER,
    device_type VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_price_order CHECK (
        too_cheap_price <= cheap_price AND
        cheap_price <= expensive_price AND
        expensive_price <= too_expensive_price
    )
);

-- Indexes for performance
CREATE INDEX idx_price_sensitivity_product_tier ON price_sensitivity_responses(product_tier);
CREATE INDEX idx_price_sensitivity_market_segment ON price_sensitivity_responses(market_segment);
CREATE INDEX idx_price_sensitivity_geographic_region ON price_sensitivity_responses(geographic_region);
CREATE INDEX idx_price_sensitivity_created_at ON price_sensitivity_responses(created_at);
CREATE INDEX idx_price_sensitivity_session_id ON price_sensitivity_responses(session_id);

-- ================================================================
-- PRICE OPTIMIZATION ANALYSIS RESULTS
-- ================================================================

CREATE TABLE price_optimization_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_id VARCHAR(100) NOT NULL UNIQUE,
    product_tier VARCHAR(50) NOT NULL,
    market_segment VARCHAR(100) NOT NULL,
    geographic_region VARCHAR(50),

    -- Van Westendorp Optimal Price Points
    point_of_marginal_cheapness DECIMAL(10,2) NOT NULL,
    point_of_marginal_expensiveness DECIMAL(10,2) NOT NULL,
    indifference_price_point DECIMAL(10,2) NOT NULL,
    optimal_price_point DECIMAL(10,2) NOT NULL,

    -- Acceptable Price Range
    acceptable_price_range_min DECIMAL(10,2) NOT NULL,
    acceptable_price_range_max DECIMAL(10,2) NOT NULL,

    -- Revenue Optimization
    revenue_maximizing_price DECIMAL(10,2) NOT NULL,
    profit_maximizing_price DECIMAL(10,2) NOT NULL,
    market_penetration_price DECIMAL(10,2) NOT NULL,

    -- Elasticity Metrics
    price_elasticity_coefficient DECIMAL(10,4) NOT NULL,
    demand_curve_slope DECIMAL(10,4),
    cross_elasticity_coefficient DECIMAL(10,4),

    -- Projections
    estimated_conversion_rate DECIMAL(5,4) CHECK (estimated_conversion_rate BETWEEN 0 AND 1),
    estimated_monthly_revenue DECIMAL(15,2),
    estimated_annual_revenue DECIMAL(15,2),
    confidence_interval_95_lower DECIMAL(10,2),
    confidence_interval_95_upper DECIMAL(10,2),

    -- Statistical Validity
    sample_size INTEGER NOT NULL,
    statistical_power DECIMAL(3,2) CHECK (statistical_power BETWEEN 0 AND 1),
    p_value DECIMAL(10,8),

    -- Metadata
    analysis_timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    algorithm_version VARCHAR(20) NOT NULL,
    convergence_iterations INTEGER,
    computation_time_ms INTEGER,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_optimization_product_tier ON price_optimization_results(product_tier);
CREATE INDEX idx_optimization_market_segment ON price_optimization_results(market_segment);
CREATE INDEX idx_optimization_analysis_timestamp ON price_optimization_results(analysis_timestamp);

-- ================================================================
-- A/B TESTING FRAMEWORK
-- ================================================================

CREATE TABLE ab_test_experiments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_name VARCHAR(200) NOT NULL UNIQUE,
    experiment_type VARCHAR(50) NOT NULL CHECK (experiment_type IN ('price_point', 'tier_structure', 'discount', 'bundling')),
    product_tier VARCHAR(50) NOT NULL,

    -- Experiment Configuration
    control_price DECIMAL(10,2) NOT NULL,
    treatment_price DECIMAL(10,2) NOT NULL,
    allocation_ratio DECIMAL(3,2) NOT NULL DEFAULT 0.5 CHECK (allocation_ratio BETWEEN 0 AND 1),

    -- Statistical Parameters
    minimum_sample_size INTEGER NOT NULL DEFAULT 1000,
    target_statistical_power DECIMAL(3,2) NOT NULL DEFAULT 0.80,
    significance_level DECIMAL(4,3) NOT NULL DEFAULT 0.05,
    minimum_detectable_effect DECIMAL(5,4) NOT NULL DEFAULT 0.05,

    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'cancelled')),
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    actual_end_date TIMESTAMP,

    -- Success Criteria
    primary_metric VARCHAR(50) NOT NULL DEFAULT 'revenue' CHECK (primary_metric IN ('revenue', 'conversion', 'arpu', 'ltv')),
    success_threshold DECIMAL(10,4),

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255),

    CONSTRAINT valid_experiment_dates CHECK (end_date IS NULL OR start_date < end_date)
);

CREATE TABLE ab_test_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_id UUID NOT NULL REFERENCES ab_test_experiments(id) ON DELETE CASCADE,
    user_id VARCHAR(255),
    session_id VARCHAR(255) NOT NULL,

    variant VARCHAR(20) NOT NULL CHECK (variant IN ('control', 'treatment')),
    assigned_price DECIMAL(10,2) NOT NULL,

    -- User Context
    market_segment VARCHAR(100),
    geographic_region VARCHAR(50),
    device_type VARCHAR(20),

    assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),

    UNIQUE(experiment_id, session_id)
);

CREATE INDEX idx_ab_assignments_experiment ON ab_test_assignments(experiment_id);
CREATE INDEX idx_ab_assignments_variant ON ab_test_assignments(variant);
CREATE INDEX idx_ab_assignments_session ON ab_test_assignments(session_id);

CREATE TABLE ab_test_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_id UUID NOT NULL REFERENCES ab_test_experiments(id) ON DELETE CASCADE,
    assignment_id UUID NOT NULL REFERENCES ab_test_assignments(id) ON DELETE CASCADE,

    -- Outcome Metrics
    converted BOOLEAN NOT NULL DEFAULT FALSE,
    revenue DECIMAL(10,2) DEFAULT 0,
    conversion_timestamp TIMESTAMP,

    -- Engagement Metrics
    page_views INTEGER DEFAULT 0,
    time_on_page_seconds INTEGER DEFAULT 0,
    clicked_cta BOOLEAN DEFAULT FALSE,

    -- User Behavior
    abandoned BOOLEAN DEFAULT FALSE,
    abandon_reason VARCHAR(100),

    recorded_at TIMESTAMP NOT NULL DEFAULT NOW(),

    UNIQUE(assignment_id)
);

CREATE INDEX idx_ab_results_experiment ON ab_test_results(experiment_id);
CREATE INDEX idx_ab_results_converted ON ab_test_results(converted);

-- ================================================================
-- MARKET SEGMENTATION
-- ================================================================

CREATE TABLE market_segments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_name VARCHAR(100) NOT NULL UNIQUE,
    segment_description TEXT,

    -- Characteristics
    size_estimate INTEGER,
    growth_rate DECIMAL(5,4),
    avg_customer_lifetime_value DECIMAL(10,2),
    churn_rate DECIMAL(5,4),

    -- Price Sensitivity
    price_sensitivity_index DECIMAL(5,4) CHECK (price_sensitivity_index BETWEEN -1 AND 1),
    optimal_pricing_strategy VARCHAR(50),

    -- Targeting
    targeting_criteria JSONB,
    priority_score INTEGER CHECK (priority_score BETWEEN 1 AND 100),

    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ================================================================
-- COMPETITIVE PRICING
-- ================================================================

CREATE TABLE competitor_pricing (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    competitor_name VARCHAR(200) NOT NULL,
    product_name VARCHAR(200) NOT NULL,
    product_tier VARCHAR(50) NOT NULL,

    -- Pricing
    price DECIMAL(10,2) NOT NULL,
    billing_cycle VARCHAR(20) CHECK (billing_cycle IN ('monthly', 'quarterly', 'annual', 'one-time')),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',

    -- Features
    features JSONB,
    feature_count INTEGER,

    -- Market Position
    market_share DECIMAL(5,4),
    estimated_customers INTEGER,

    -- Data Source
    data_source VARCHAR(100),
    scraped_at TIMESTAMP,
    verified BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    UNIQUE(competitor_name, product_tier, scraped_at)
);

CREATE INDEX idx_competitor_pricing_tier ON competitor_pricing(product_tier);
CREATE INDEX idx_competitor_pricing_scraped ON competitor_pricing(scraped_at DESC);

-- ================================================================
-- MONITORING AND COMPLIANCE
-- ================================================================

CREATE TABLE price_changes_audit (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_tier VARCHAR(50) NOT NULL,

    -- Price Change
    old_price DECIMAL(10,2) NOT NULL,
    new_price DECIMAL(10,2) NOT NULL,
    change_percentage DECIMAL(10,4) NOT NULL,

    -- Context
    change_reason TEXT NOT NULL,
    analysis_id VARCHAR(100) REFERENCES price_optimization_results(analysis_id),
    experiment_id UUID REFERENCES ab_test_experiments(id),

    -- Approval
    approved_by VARCHAR(255),
    approval_timestamp TIMESTAMP,

    -- Execution
    effective_date TIMESTAMP NOT NULL,
    executed_date TIMESTAMP,
    rollback_date TIMESTAMP,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_by VARCHAR(255) NOT NULL
);

CREATE INDEX idx_price_audit_tier ON price_changes_audit(product_tier);
CREATE INDEX idx_price_audit_effective ON price_changes_audit(effective_date);

CREATE TABLE pricing_alerts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN (
        'price_deviation', 'conversion_drop', 'revenue_decline',
        'competitor_change', 'elasticity_shift', 'experiment_failure'
    )),
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),

    -- Alert Details
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    metric_name VARCHAR(100),
    current_value DECIMAL(15,4),
    threshold_value DECIMAL(15,4),
    deviation_percentage DECIMAL(10,4),

    -- Context
    product_tier VARCHAR(50),
    market_segment VARCHAR(100),
    related_entity_id UUID,
    related_entity_type VARCHAR(50),

    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'acknowledged', 'resolved', 'dismissed')),
    acknowledged_by VARCHAR(255),
    acknowledged_at TIMESTAMP,
    resolved_at TIMESTAMP,

    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_alerts_status ON pricing_alerts(status);
CREATE INDEX idx_alerts_severity ON pricing_alerts(severity);
CREATE INDEX idx_alerts_created ON pricing_alerts(created_at DESC);

-- ================================================================
-- REVENUE TRACKING
-- ================================================================

CREATE TABLE revenue_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    metric_date DATE NOT NULL,
    product_tier VARCHAR(50) NOT NULL,
    market_segment VARCHAR(100),

    -- Revenue Metrics
    daily_revenue DECIMAL(15,2) NOT NULL DEFAULT 0,
    new_customer_revenue DECIMAL(15,2) NOT NULL DEFAULT 0,
    expansion_revenue DECIMAL(15,2) NOT NULL DEFAULT 0,
    churn_revenue DECIMAL(15,2) NOT NULL DEFAULT 0,

    -- Volume Metrics
    new_customers INTEGER NOT NULL DEFAULT 0,
    churned_customers INTEGER NOT NULL DEFAULT 0,
    total_active_customers INTEGER NOT NULL DEFAULT 0,

    -- Performance Metrics
    conversion_rate DECIMAL(5,4),
    average_revenue_per_user DECIMAL(10,2),
    customer_acquisition_cost DECIMAL(10,2),
    customer_lifetime_value DECIMAL(10,2),

    -- Price Point
    effective_price DECIMAL(10,2) NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    UNIQUE(metric_date, product_tier, market_segment)
);

CREATE INDEX idx_revenue_date ON revenue_metrics(metric_date DESC);
CREATE INDEX idx_revenue_tier ON revenue_metrics(product_tier);

-- ================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- ================================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_price_sensitivity_responses_updated_at
    BEFORE UPDATE ON price_sensitivity_responses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_price_optimization_results_updated_at
    BEFORE UPDATE ON price_optimization_results
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ab_test_experiments_updated_at
    BEFORE UPDATE ON ab_test_experiments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_market_segments_updated_at
    BEFORE UPDATE ON market_segments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_competitor_pricing_updated_at
    BEFORE UPDATE ON competitor_pricing
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================================================
-- VIEWS FOR COMMON QUERIES
-- ================================================================

-- Aggregated price sensitivity by segment
CREATE OR REPLACE VIEW vw_price_sensitivity_summary AS
SELECT
    product_tier,
    market_segment,
    geographic_region,
    COUNT(*) as response_count,
    AVG(too_cheap_price) as avg_too_cheap,
    AVG(cheap_price) as avg_cheap,
    AVG(expensive_price) as avg_expensive,
    AVG(too_expensive_price) as avg_too_expensive,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cheap_price) as median_cheap,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY expensive_price) as median_expensive,
    AVG(response_quality_score) as avg_quality_score,
    MIN(created_at) as first_response_date,
    MAX(created_at) as last_response_date
FROM price_sensitivity_responses
WHERE response_quality_score >= 0.7
GROUP BY product_tier, market_segment, geographic_region;

-- Active A/B test performance
CREATE OR REPLACE VIEW vw_ab_test_performance AS
SELECT
    e.experiment_name,
    e.product_tier,
    a.variant,
    COUNT(DISTINCT a.id) as assigned_users,
    COUNT(DISTINCT r.id) as completed_responses,
    SUM(CASE WHEN r.converted THEN 1 ELSE 0 END) as conversions,
    SUM(r.revenue) as total_revenue,
    AVG(CASE WHEN r.converted THEN 1 ELSE 0 END) as conversion_rate,
    AVG(r.revenue) as avg_revenue_per_user,
    AVG(r.time_on_page_seconds) as avg_time_on_page
FROM ab_test_experiments e
JOIN ab_test_assignments a ON e.id = a.experiment_id
LEFT JOIN ab_test_results r ON a.id = r.assignment_id
WHERE e.status = 'active'
GROUP BY e.experiment_name, e.product_tier, a.variant;

-- Revenue trends
CREATE OR REPLACE VIEW vw_revenue_trends AS
SELECT
    metric_date,
    product_tier,
    SUM(daily_revenue) as total_revenue,
    SUM(new_customers) as new_customers,
    AVG(conversion_rate) as avg_conversion_rate,
    AVG(customer_lifetime_value) as avg_ltv,
    SUM(total_active_customers) as total_active
FROM revenue_metrics
GROUP BY metric_date, product_tier
ORDER BY metric_date DESC;
