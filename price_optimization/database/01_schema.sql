-- =============================================================================
-- PHASE 1: Price Sensitivity Data Collection Schema
-- Van Westendorp Methodology for OneTimeSecret Price Optimization
-- Database: PostgreSQL 14+
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- Market Segments
-- =============================================================================
CREATE TABLE market_segments (
    segment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_name VARCHAR(255) NOT NULL UNIQUE,
    segment_description TEXT,
    geographic_region VARCHAR(100),
    company_size VARCHAR(50) CHECK (company_size IN ('enterprise', 'mid-market', 'small-business', 'individual')),
    industry VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_market_segments_active ON market_segments(is_active);
CREATE INDEX idx_market_segments_company_size ON market_segments(company_size);
CREATE INDEX idx_market_segments_region ON market_segments(geographic_region);

-- =============================================================================
-- Product Tiers
-- =============================================================================
CREATE TABLE product_tiers (
    tier_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tier_name VARCHAR(100) NOT NULL UNIQUE,
    tier_level INTEGER NOT NULL CHECK (tier_level BETWEEN 1 AND 5),
    feature_description TEXT,
    max_secrets_per_month INTEGER,
    max_ttl_days INTEGER,
    api_access_level VARCHAR(50) CHECK (api_access_level IN ('none', 'basic', 'standard', 'premium', 'enterprise')),
    support_level VARCHAR(50) CHECK (support_level IN ('community', 'email', 'priority', 'dedicated')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_product_tiers_level ON product_tiers(tier_level);
CREATE INDEX idx_product_tiers_active ON product_tiers(is_active);

-- =============================================================================
-- Survey Respondents
-- =============================================================================
CREATE TABLE survey_respondents (
    respondent_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_id UUID REFERENCES market_segments(segment_id) ON DELETE CASCADE,
    email_hash VARCHAR(64), -- SHA-256 hashed email for privacy
    demographic_data JSONB, -- Flexible structure for demographic info
    completed_at TIMESTAMP WITH TIME ZONE,
    survey_version VARCHAR(20) NOT NULL,
    ip_address_hash VARCHAR(64), -- Hashed IP for fraud detection
    user_agent TEXT,
    response_time_seconds INTEGER,
    is_valid BOOLEAN DEFAULT TRUE,
    validation_flags JSONB, -- Store validation issues
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_respondents_segment ON survey_respondents(segment_id);
CREATE INDEX idx_respondents_completed ON survey_respondents(completed_at);
CREATE INDEX idx_respondents_valid ON survey_respondents(is_valid);
CREATE INDEX idx_respondents_demographic ON survey_respondents USING GIN (demographic_data);

-- =============================================================================
-- Van Westendorp Price Sensitivity Questions
-- =============================================================================
CREATE TABLE price_sensitivity_responses (
    response_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    respondent_id UUID REFERENCES survey_respondents(respondent_id) ON DELETE CASCADE,
    tier_id UUID REFERENCES product_tiers(tier_id) ON DELETE CASCADE,

    -- Van Westendorp Four Price Points (in USD cents)
    too_cheap_price INTEGER NOT NULL CHECK (too_cheap_price >= 0),
    bargain_price INTEGER NOT NULL CHECK (bargain_price >= too_cheap_price),
    expensive_price INTEGER NOT NULL CHECK (expensive_price >= bargain_price),
    too_expensive_price INTEGER NOT NULL CHECK (too_expensive_price >= expensive_price),

    -- Additional context
    current_spending INTEGER, -- Current monthly spend on similar services
    willingness_to_switch INTEGER CHECK (willingness_to_switch BETWEEN 1 AND 10),
    price_sensitivity_score INTEGER CHECK (price_sensitivity_score BETWEEN 1 AND 10),

    -- Elasticity indicators
    alternatives_considered TEXT[],
    switching_cost_estimate INTEGER,

    -- Quality perception
    perceived_value_score INTEGER CHECK (perceived_value_score BETWEEN 1 AND 10),
    feature_importance JSONB, -- {"encryption": 10, "ttl": 8, "api": 7, ...}

    -- Response metadata
    response_duration_seconds INTEGER,
    confidence_level INTEGER CHECK (confidence_level BETWEEN 1 AND 10),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Ensure logical ordering
    CONSTRAINT check_price_order CHECK (
        too_cheap_price <= bargain_price AND
        bargain_price <= expensive_price AND
        expensive_price <= too_expensive_price
    )
);

CREATE INDEX idx_price_responses_respondent ON price_sensitivity_responses(respondent_id);
CREATE INDEX idx_price_responses_tier ON price_sensitivity_responses(tier_id);
CREATE INDEX idx_price_responses_created ON price_sensitivity_responses(created_at);
CREATE INDEX idx_price_responses_feature_importance ON price_sensitivity_responses USING GIN (feature_importance);

-- =============================================================================
-- Competitive Pricing Data
-- =============================================================================
CREATE TABLE competitive_pricing (
    competitor_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    competitor_name VARCHAR(255) NOT NULL,
    product_name VARCHAR(255),
    tier_equivalent VARCHAR(100), -- Maps to our product_tiers

    -- Pricing details (in USD cents)
    current_price INTEGER NOT NULL CHECK (current_price >= 0),
    billing_period VARCHAR(50) CHECK (billing_period IN ('monthly', 'quarterly', 'annual', 'one-time')),

    -- Feature comparison
    feature_matrix JSONB, -- Detailed feature comparison
    market_share_percentage DECIMAL(5,2) CHECK (market_share_percentage BETWEEN 0 AND 100),

    -- Pricing history
    price_history JSONB, -- [{"date": "2024-01-01", "price": 1999}, ...]

    -- Data collection metadata
    data_source VARCHAR(255),
    verified BOOLEAN DEFAULT FALSE,
    last_verified_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_competitive_pricing_tier ON competitive_pricing(tier_equivalent);
CREATE INDEX idx_competitive_pricing_verified ON competitive_pricing(verified);
CREATE INDEX idx_competitive_pricing_updated ON competitive_pricing(updated_at);

-- =============================================================================
-- Price Elasticity Coefficients
-- =============================================================================
CREATE TABLE price_elasticity_coefficients (
    coefficient_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_id UUID REFERENCES market_segments(segment_id) ON DELETE CASCADE,
    tier_id UUID REFERENCES product_tiers(tier_id) ON DELETE CASCADE,

    -- Elasticity measures
    price_elasticity_of_demand DECIMAL(10,4) NOT NULL, -- Typically negative
    cross_price_elasticity DECIMAL(10,4), -- Substitution effect
    income_elasticity DECIMAL(10,4),

    -- Statistical confidence
    standard_error DECIMAL(10,4),
    r_squared DECIMAL(5,4) CHECK (r_squared BETWEEN 0 AND 1),
    p_value DECIMAL(10,8),
    confidence_interval_lower DECIMAL(10,4),
    confidence_interval_upper DECIMAL(10,4),

    -- Sample characteristics
    sample_size INTEGER NOT NULL CHECK (sample_size > 0),
    calculation_method VARCHAR(100) NOT NULL,

    -- Model parameters
    model_parameters JSONB, -- Store full model details

    -- Validity period
    valid_from TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP WITH TIME ZONE,
    is_current BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(segment_id, tier_id, valid_from)
);

CREATE INDEX idx_elasticity_segment_tier ON price_elasticity_coefficients(segment_id, tier_id);
CREATE INDEX idx_elasticity_current ON price_elasticity_coefficients(is_current);
CREATE INDEX idx_elasticity_valid_period ON price_elasticity_coefficients(valid_from, valid_to);

-- =============================================================================
-- Van Westendorp Analysis Results
-- =============================================================================
CREATE TABLE van_westendorp_analysis (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    segment_id UUID REFERENCES market_segments(segment_id) ON DELETE CASCADE,
    tier_id UUID REFERENCES product_tiers(tier_id) ON DELETE CASCADE,
    analysis_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Van Westendorp Key Price Points (in USD cents)
    point_of_marginal_cheapness INTEGER NOT NULL, -- PMC: Intersection of "too cheap" and "expensive"
    point_of_marginal_expensiveness INTEGER NOT NULL, -- PME: Intersection of "bargain" and "too expensive"
    optimal_price_point INTEGER NOT NULL, -- OPP: Intersection of "too cheap" and "too expensive"
    indifference_price_point INTEGER NOT NULL, -- IPP: Intersection of "bargain" and "expensive"

    -- Acceptable price range
    acceptable_price_range_lower INTEGER NOT NULL,
    acceptable_price_range_upper INTEGER NOT NULL,

    -- Revenue optimization
    recommended_price INTEGER NOT NULL,
    expected_conversion_rate DECIMAL(5,4) CHECK (expected_conversion_rate BETWEEN 0 AND 1),
    expected_revenue_per_customer INTEGER,

    -- Analysis quality metrics
    sample_size INTEGER NOT NULL,
    confidence_score DECIMAL(5,4) CHECK (confidence_score BETWEEN 0 AND 1),
    data_quality_score DECIMAL(5,4) CHECK (data_quality_score BETWEEN 0 AND 1),

    -- Statistical measures
    median_acceptable_price INTEGER,
    mean_acceptable_price INTEGER,
    standard_deviation INTEGER,

    -- Curve data for visualization (stored as JSON arrays)
    cumulative_curves JSONB, -- {"too_cheap": [...], "bargain": [...], ...}

    -- Analysis metadata
    algorithm_version VARCHAR(50) NOT NULL,
    analysis_parameters JSONB,

    -- Validity
    is_current BOOLEAN DEFAULT TRUE,
    superseded_by UUID REFERENCES van_westendorp_analysis(analysis_id),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(segment_id, tier_id, analysis_date)
);

CREATE INDEX idx_vw_analysis_segment_tier ON van_westendorp_analysis(segment_id, tier_id);
CREATE INDEX idx_vw_analysis_current ON van_westendorp_analysis(is_current);
CREATE INDEX idx_vw_analysis_date ON van_westendorp_analysis(analysis_date);

-- =============================================================================
-- Optimization Simulations
-- =============================================================================
CREATE TABLE optimization_simulations (
    simulation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_id UUID REFERENCES van_westendorp_analysis(analysis_id) ON DELETE CASCADE,
    simulation_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Simulation parameters
    price_point_tested INTEGER NOT NULL CHECK (price_point_tested >= 0),
    market_condition VARCHAR(50) CHECK (market_condition IN ('bull', 'base', 'bear')),

    -- Revenue projections (in USD cents)
    projected_monthly_revenue BIGINT,
    projected_annual_revenue BIGINT,

    -- Customer metrics
    projected_conversion_rate DECIMAL(5,4) CHECK (projected_conversion_rate BETWEEN 0 AND 1),
    projected_customer_count INTEGER,
    projected_churn_rate DECIMAL(5,4) CHECK (projected_churn_rate BETWEEN 0 AND 1),
    customer_lifetime_value INTEGER,

    -- Cost factors
    customer_acquisition_cost INTEGER,
    operating_cost_per_customer INTEGER,

    -- Profitability
    gross_margin DECIMAL(5,4) CHECK (gross_margin BETWEEN -1 AND 1),
    net_revenue BIGINT,
    roi DECIMAL(10,4),

    -- Risk metrics
    revenue_at_risk INTEGER,
    risk_score DECIMAL(5,4) CHECK (risk_score BETWEEN 0 AND 1),

    -- Confidence intervals
    revenue_ci_lower BIGINT,
    revenue_ci_upper BIGINT,
    conversion_ci_lower DECIMAL(5,4),
    conversion_ci_upper DECIMAL(5,4),

    -- Simulation metadata
    monte_carlo_iterations INTEGER,
    random_seed INTEGER,
    convergence_achieved BOOLEAN,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_simulations_analysis ON optimization_simulations(analysis_id);
CREATE INDEX idx_simulations_price ON optimization_simulations(price_point_tested);
CREATE INDEX idx_simulations_market ON optimization_simulations(market_condition);
CREATE INDEX idx_simulations_date ON optimization_simulations(simulation_date);

-- =============================================================================
-- A/B Test Experiments
-- =============================================================================
CREATE TABLE ab_test_experiments (
    experiment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_name VARCHAR(255) NOT NULL UNIQUE,
    segment_id UUID REFERENCES market_segments(segment_id),
    tier_id UUID REFERENCES product_tiers(tier_id),

    -- Experiment configuration
    control_price INTEGER NOT NULL CHECK (control_price >= 0),
    variant_prices INTEGER[] NOT NULL, -- Array of test prices

    -- Statistical design
    required_sample_size INTEGER NOT NULL,
    statistical_power DECIMAL(5,4) DEFAULT 0.80 CHECK (statistical_power BETWEEN 0 AND 1),
    significance_level DECIMAL(5,4) DEFAULT 0.05 CHECK (significance_level BETWEEN 0 AND 1),
    minimum_detectable_effect DECIMAL(5,4) NOT NULL,

    -- Experiment timeline
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    planned_end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    actual_end_date TIMESTAMP WITH TIME ZONE,

    -- Status
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'cancelled')),

    -- Success criteria
    primary_metric VARCHAR(100) NOT NULL, -- e.g., 'revenue_per_visitor'
    secondary_metrics TEXT[],
    success_threshold DECIMAL(10,4),

    -- Risk management
    max_allowed_revenue_loss INTEGER,
    auto_stop_enabled BOOLEAN DEFAULT TRUE,

    -- Metadata
    created_by VARCHAR(255),
    hypothesis TEXT,
    notes TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CHECK (planned_end_date > start_date)
);

CREATE INDEX idx_experiments_status ON ab_test_experiments(status);
CREATE INDEX idx_experiments_dates ON ab_test_experiments(start_date, planned_end_date);
CREATE INDEX idx_experiments_segment_tier ON ab_test_experiments(segment_id, tier_id);

-- =============================================================================
-- A/B Test Participants
-- =============================================================================
CREATE TABLE ab_test_participants (
    participant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    experiment_id UUID REFERENCES ab_test_experiments(experiment_id) ON DELETE CASCADE,

    -- User identification (hashed for privacy)
    user_id_hash VARCHAR(64) NOT NULL,
    session_id VARCHAR(255),

    -- Assignment
    test_group VARCHAR(50) NOT NULL, -- 'control', 'variant_1', 'variant_2', etc.
    assigned_price INTEGER NOT NULL,

    -- Assignment method
    assignment_method VARCHAR(50) DEFAULT 'random' CHECK (assignment_method IN ('random', 'stratified', 'deterministic')),
    assignment_hash VARCHAR(64), -- For consistent assignment

    -- Timestamps
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    first_exposure_at TIMESTAMP WITH TIME ZONE,

    -- Metadata
    user_properties JSONB, -- Segment, location, etc.

    UNIQUE(experiment_id, user_id_hash)
);

CREATE INDEX idx_participants_experiment ON ab_test_participants(experiment_id);
CREATE INDEX idx_participants_group ON ab_test_participants(experiment_id, test_group);
CREATE INDEX idx_participants_user ON ab_test_participants(user_id_hash);

-- =============================================================================
-- A/B Test Results
-- =============================================================================
CREATE TABLE ab_test_results (
    result_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    participant_id UUID REFERENCES ab_test_participants(participant_id) ON DELETE CASCADE,
    experiment_id UUID REFERENCES ab_test_experiments(experiment_id) ON DELETE CASCADE,

    -- Event tracking
    event_type VARCHAR(100) NOT NULL, -- 'page_view', 'signup', 'conversion', 'churn'
    event_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Financial metrics (in USD cents)
    revenue_amount INTEGER DEFAULT 0,

    -- Conversion funnel
    viewed BOOLEAN DEFAULT FALSE,
    clicked BOOLEAN DEFAULT FALSE,
    signed_up BOOLEAN DEFAULT FALSE,
    converted BOOLEAN DEFAULT FALSE,

    -- Engagement metrics
    time_on_page_seconds INTEGER,
    pages_viewed INTEGER,

    -- Additional data
    event_properties JSONB,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_results_participant ON ab_test_results(participant_id);
CREATE INDEX idx_results_experiment ON ab_test_results(experiment_id);
CREATE INDEX idx_results_event_type ON ab_test_results(event_type);
CREATE INDEX idx_results_timestamp ON ab_test_results(event_timestamp);
CREATE INDEX idx_results_converted ON ab_test_results(converted) WHERE converted = TRUE;

-- =============================================================================
-- Price Changes History
-- =============================================================================
CREATE TABLE price_changes_history (
    change_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tier_id UUID REFERENCES product_tiers(tier_id) ON DELETE CASCADE,
    segment_id UUID REFERENCES market_segments(segment_id),

    -- Price change details
    previous_price INTEGER NOT NULL,
    new_price INTEGER NOT NULL CHECK (new_price >= 0),
    price_change_percentage DECIMAL(10,4),

    -- Implementation
    effective_date TIMESTAMP WITH TIME ZONE NOT NULL,
    announcement_date TIMESTAMP WITH TIME ZONE,

    -- Justification
    change_reason VARCHAR(255) NOT NULL,
    supporting_analysis_id UUID REFERENCES van_westendorp_analysis(analysis_id),
    experiment_id UUID REFERENCES ab_test_experiments(experiment_id),

    -- Impact tracking
    expected_revenue_impact BIGINT,
    actual_revenue_impact BIGINT,
    expected_customer_impact INTEGER,
    actual_customer_impact INTEGER,

    -- Approval workflow
    requested_by VARCHAR(255),
    approved_by VARCHAR(255),
    approval_date TIMESTAMP WITH TIME ZONE,

    -- Rollback capability
    can_rollback BOOLEAN DEFAULT TRUE,
    rolled_back BOOLEAN DEFAULT FALSE,
    rollback_date TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_price_changes_tier ON price_changes_history(tier_id);
CREATE INDEX idx_price_changes_effective ON price_changes_history(effective_date);
CREATE INDEX idx_price_changes_segment ON price_changes_history(segment_id);

-- =============================================================================
-- Monitoring Metrics
-- =============================================================================
CREATE TABLE pricing_metrics (
    metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tier_id UUID REFERENCES product_tiers(tier_id) ON DELETE CASCADE,
    segment_id UUID REFERENCES market_segments(segment_id),
    metric_date DATE NOT NULL,

    -- Revenue metrics (in USD cents)
    total_revenue BIGINT DEFAULT 0,
    average_revenue_per_user INTEGER,

    -- Customer metrics
    new_customers INTEGER DEFAULT 0,
    churned_customers INTEGER DEFAULT 0,
    active_customers INTEGER DEFAULT 0,

    -- Conversion metrics
    total_visitors INTEGER DEFAULT 0,
    pricing_page_views INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,4),

    -- Pricing compliance
    price_displayed INTEGER NOT NULL,
    discounts_applied INTEGER DEFAULT 0,
    discount_amount INTEGER DEFAULT 0,

    -- Competitive position
    market_share_estimate DECIMAL(5,4),
    price_vs_market_average DECIMAL(10,4), -- Percentage difference

    -- Alerts triggered
    alert_count INTEGER DEFAULT 0,
    alert_types TEXT[],

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(tier_id, segment_id, metric_date)
);

CREATE INDEX idx_metrics_date ON pricing_metrics(metric_date DESC);
CREATE INDEX idx_metrics_tier_segment ON pricing_metrics(tier_id, segment_id);
CREATE INDEX idx_metrics_revenue ON pricing_metrics(total_revenue DESC);

-- =============================================================================
-- Alerts Configuration
-- =============================================================================
CREATE TABLE pricing_alerts (
    alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_name VARCHAR(255) NOT NULL UNIQUE,
    alert_type VARCHAR(100) NOT NULL CHECK (alert_type IN ('revenue_drop', 'conversion_drop', 'competitor_change', 'price_deviation', 'customer_churn')),

    -- Trigger conditions
    threshold_value DECIMAL(10,4) NOT NULL,
    threshold_operator VARCHAR(10) CHECK (threshold_operator IN ('>', '<', '>=', '<=', '=')),
    lookback_period_days INTEGER DEFAULT 7,

    -- Scope
    tier_id UUID REFERENCES product_tiers(tier_id),
    segment_id UUID REFERENCES market_segments(segment_id),

    -- Actions
    notify_emails TEXT[],
    webhook_url VARCHAR(500),
    auto_rollback BOOLEAN DEFAULT FALSE,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    last_triggered_at TIMESTAMP WITH TIME ZONE,
    trigger_count INTEGER DEFAULT 0,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alerts_active ON pricing_alerts(is_active);
CREATE INDEX idx_alerts_type ON pricing_alerts(alert_type);

-- =============================================================================
-- Alert History
-- =============================================================================
CREATE TABLE alert_history (
    history_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_id UUID REFERENCES pricing_alerts(alert_id) ON DELETE CASCADE,

    -- Trigger details
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    trigger_value DECIMAL(10,4) NOT NULL,
    threshold_value DECIMAL(10,4) NOT NULL,

    -- Context
    affected_tier_id UUID REFERENCES product_tiers(tier_id),
    affected_segment_id UUID REFERENCES market_segments(segment_id),

    -- Response
    notification_sent BOOLEAN DEFAULT FALSE,
    action_taken VARCHAR(255),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by VARCHAR(255),

    -- Additional data
    context_data JSONB,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alert_history_alert ON alert_history(alert_id);
CREATE INDEX idx_alert_history_triggered ON alert_history(triggered_at DESC);
CREATE INDEX idx_alert_history_resolved ON alert_history(resolved_at);

-- =============================================================================
-- Utility Functions
-- =============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_market_segments_updated_at BEFORE UPDATE ON market_segments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_tiers_updated_at BEFORE UPDATE ON product_tiers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_competitive_pricing_updated_at BEFORE UPDATE ON competitive_pricing
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_experiments_updated_at BEFORE UPDATE ON ab_test_experiments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_price_changes_updated_at BEFORE UPDATE ON price_changes_history
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alerts_updated_at BEFORE UPDATE ON pricing_alerts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate price change percentage
CREATE OR REPLACE FUNCTION calculate_price_change_percentage()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.previous_price > 0 THEN
        NEW.price_change_percentage = ((NEW.new_price - NEW.previous_price)::DECIMAL / NEW.previous_price) * 100;
    ELSE
        NEW.price_change_percentage = 100.0; -- If no previous price, assume 100% increase from 0
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER calculate_price_change BEFORE INSERT OR UPDATE ON price_changes_history
    FOR EACH ROW EXECUTE FUNCTION calculate_price_change_percentage();

-- =============================================================================
-- Comments for documentation
-- =============================================================================
COMMENT ON TABLE market_segments IS 'Defines distinct market segments for price optimization analysis';
COMMENT ON TABLE product_tiers IS 'Product tier definitions for OneTimeSecret service offerings';
COMMENT ON TABLE survey_respondents IS 'Participants in Van Westendorp price sensitivity surveys';
COMMENT ON TABLE price_sensitivity_responses IS 'Van Westendorp four price point responses (too cheap, bargain, expensive, too expensive)';
COMMENT ON TABLE competitive_pricing IS 'Competitive intelligence on competitor pricing and features';
COMMENT ON TABLE price_elasticity_coefficients IS 'Calculated price elasticity of demand for each segment/tier';
COMMENT ON TABLE van_westendorp_analysis IS 'Results of Van Westendorp analysis including optimal price points';
COMMENT ON TABLE optimization_simulations IS 'Monte Carlo simulations of revenue at different price points';
COMMENT ON TABLE ab_test_experiments IS 'A/B test experiment configurations for price testing';
COMMENT ON TABLE ab_test_participants IS 'User assignments to A/B test groups';
COMMENT ON TABLE ab_test_results IS 'Event tracking and conversion data for A/B tests';
COMMENT ON TABLE price_changes_history IS 'Audit trail of all price changes with impact analysis';
COMMENT ON TABLE pricing_metrics IS 'Daily aggregated metrics for monitoring pricing performance';
COMMENT ON TABLE pricing_alerts IS 'Alert configurations for automated monitoring';
COMMENT ON TABLE alert_history IS 'Historical record of triggered alerts and responses';
