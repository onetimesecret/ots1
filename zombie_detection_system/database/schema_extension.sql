-- ============================================================================
-- ZOMBIE SUBSCRIPTION DETECTION SYSTEM - DATABASE SCHEMA EXTENSION
-- ============================================================================
-- Purpose: Extends existing OneTimeSecret schema to track customer engagement
--          and identify zombie subscriptions
-- Author: Claude
-- Date: 2025-11-23
-- ============================================================================

-- ----------------------------------------------------------------------------
-- SUBSCRIPTIONS TABLE
-- ----------------------------------------------------------------------------
-- Tracks customer subscription status, billing, and lifecycle
CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGSERIAL PRIMARY KEY,
    custid VARCHAR(255) NOT NULL UNIQUE,
    plan_type VARCHAR(50) NOT NULL DEFAULT 'standard', -- 'free', 'standard', 'premium'
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- 'active', 'canceled', 'paused', 'churned'
    monthly_revenue DECIMAL(10,2) NOT NULL DEFAULT 35.00,
    billing_cycle VARCHAR(20) NOT NULL DEFAULT 'monthly', -- 'monthly', 'annual'
    subscription_start_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    subscription_end_date TIMESTAMP,
    last_billing_date TIMESTAMP,
    next_billing_date TIMESTAMP,
    payment_failures INT DEFAULT 0,
    trial_end_date TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Metadata
    signup_source VARCHAR(100), -- 'organic', 'referral', 'paid_ads', etc.
    company_size VARCHAR(50), -- 'solo', 'small', 'medium', 'enterprise'
    industry VARCHAR(100),

    CONSTRAINT valid_status CHECK (status IN ('active', 'canceled', 'paused', 'churned', 'trial')),
    CONSTRAINT valid_plan CHECK (plan_type IN ('free', 'standard', 'premium', 'enterprise'))
);

CREATE INDEX idx_subscriptions_custid ON subscriptions(custid);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_next_billing ON subscriptions(next_billing_date);

-- ----------------------------------------------------------------------------
-- LOGIN EVENTS TABLE
-- ----------------------------------------------------------------------------
-- Tracks all user authentication events for activity analysis
CREATE TABLE IF NOT EXISTS login_events (
    id BIGSERIAL PRIMARY KEY,
    custid VARCHAR(255) NOT NULL,
    username VARCHAR(255) NOT NULL,
    login_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    login_method VARCHAR(50) DEFAULT 'api_key', -- 'api_key', 'oauth', 'session'
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN NOT NULL DEFAULT true,
    session_duration_seconds INT, -- NULL if session still active

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_login_events_custid ON login_events(custid);
CREATE INDEX idx_login_events_timestamp ON login_events(login_timestamp DESC);
CREATE INDEX idx_login_events_composite ON login_events(custid, login_timestamp DESC);

-- ----------------------------------------------------------------------------
-- API USAGE TABLE
-- ----------------------------------------------------------------------------
-- Tracks all API requests for usage pattern analysis
CREATE TABLE IF NOT EXISTS api_usage (
    id BIGSERIAL PRIMARY KEY,
    custid VARCHAR(255) NOT NULL,
    endpoint VARCHAR(255) NOT NULL,
    http_method VARCHAR(10) NOT NULL,
    request_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    response_status_code INT NOT NULL,
    response_time_ms INT,
    request_size_bytes INT,
    response_size_bytes INT,

    -- Feature categorization
    feature_category VARCHAR(50), -- 'secret_creation', 'secret_retrieval', 'secret_burn', 'admin'
    is_api_call BOOLEAN DEFAULT true,
    is_billable_action BOOLEAN DEFAULT false,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_api_usage_custid ON api_usage(custid);
CREATE INDEX idx_api_usage_timestamp ON api_usage(request_timestamp DESC);
CREATE INDEX idx_api_usage_endpoint ON api_usage(endpoint);
CREATE INDEX idx_api_usage_composite ON api_usage(custid, request_timestamp DESC);
CREATE INDEX idx_api_usage_feature ON api_usage(feature_category);

-- ----------------------------------------------------------------------------
-- FEATURE ADOPTION TABLE
-- ----------------------------------------------------------------------------
-- Tracks which features each customer has ever used
CREATE TABLE IF NOT EXISTS feature_adoption (
    id BIGSERIAL PRIMARY KEY,
    custid VARCHAR(255) NOT NULL,
    feature_name VARCHAR(100) NOT NULL,
    first_used_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usage_count INT NOT NULL DEFAULT 1,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_customer_feature UNIQUE(custid, feature_name)
);

CREATE INDEX idx_feature_adoption_custid ON feature_adoption(custid);
CREATE INDEX idx_feature_adoption_feature ON feature_adoption(feature_name);

-- ----------------------------------------------------------------------------
-- CUSTOMER HEALTH SCORES TABLE
-- ----------------------------------------------------------------------------
-- Stores calculated health scores and zombie status over time
CREATE TABLE IF NOT EXISTS customer_health_scores (
    id BIGSERIAL PRIMARY KEY,
    custid VARCHAR(255) NOT NULL,
    calculated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Overall health score (0-100)
    health_score DECIMAL(5,2) NOT NULL,

    -- Component scores (0-100 each)
    login_score DECIMAL(5,2) NOT NULL,
    api_usage_score DECIMAL(5,2) NOT NULL,
    feature_adoption_score DECIMAL(5,2) NOT NULL,
    collaboration_score DECIMAL(5,2) NOT NULL,
    data_activity_score DECIMAL(5,2) NOT NULL,

    -- Classification
    health_status VARCHAR(50) NOT NULL, -- 'healthy', 'at_risk', 'zombie', 'dead'
    zombie_since TIMESTAMP,
    days_as_zombie INT DEFAULT 0,

    -- Risk indicators
    churn_risk_score DECIMAL(5,2), -- 0-100, higher = more likely to churn
    reactivation_potential DECIMAL(5,2), -- 0-100, higher = more likely to reactivate

    -- Metrics used in calculation
    days_since_last_login INT,
    api_calls_last_30d INT,
    features_used_count INT,
    total_secrets_created INT,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT valid_health_status CHECK (health_status IN ('healthy', 'at_risk', 'zombie', 'dead'))
);

CREATE INDEX idx_health_scores_custid ON customer_health_scores(custid);
CREATE INDEX idx_health_scores_calculated ON customer_health_scores(calculated_at DESC);
CREATE INDEX idx_health_scores_status ON customer_health_scores(health_status);
CREATE INDEX idx_health_scores_composite ON customer_health_scores(custid, calculated_at DESC);

-- ----------------------------------------------------------------------------
-- INTERVENTION CAMPAIGNS TABLE
-- ----------------------------------------------------------------------------
-- Tracks re-engagement campaigns sent to at-risk/zombie customers
CREATE TABLE IF NOT EXISTS intervention_campaigns (
    id BIGSERIAL PRIMARY KEY,
    custid VARCHAR(255) NOT NULL,
    campaign_type VARCHAR(50) NOT NULL, -- 'at_risk_email', 'zombie_sequence', 'winback', 'sunset'
    trigger_health_status VARCHAR(50) NOT NULL,

    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    email_subject TEXT,
    email_template_id VARCHAR(100),

    -- Engagement tracking
    opened_at TIMESTAMP,
    clicked_at TIMESTAMP,
    responded_at TIMESTAMP,

    -- Outcome tracking
    resulted_in_activity BOOLEAN DEFAULT false,
    activity_resumed_at TIMESTAMP,
    resulted_in_churn BOOLEAN DEFAULT false,
    churned_at TIMESTAMP,

    -- Escalation
    escalated_to_csm BOOLEAN DEFAULT false,
    csm_contacted_at TIMESTAMP,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_interventions_custid ON intervention_campaigns(custid);
CREATE INDEX idx_interventions_type ON intervention_campaigns(campaign_type);
CREATE INDEX idx_interventions_sent ON intervention_campaigns(sent_at DESC);

-- ----------------------------------------------------------------------------
-- CUSTOMER LIFECYCLE EVENTS TABLE
-- ----------------------------------------------------------------------------
-- Tracks significant state transitions in customer journey
CREATE TABLE IF NOT EXISTS customer_lifecycle_events (
    id BIGSERIAL PRIMARY KEY,
    custid VARCHAR(255) NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- 'signup', 'first_secret', 'became_zombie', 'reactivated', 'churned'
    event_timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    previous_state VARCHAR(50),
    new_state VARCHAR(50),

    -- Context
    trigger_reason TEXT,
    metadata JSONB, -- Store additional context as needed

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_lifecycle_events_custid ON customer_lifecycle_events(custid);
CREATE INDEX idx_lifecycle_events_type ON customer_lifecycle_events(event_type);
CREATE INDEX idx_lifecycle_events_timestamp ON customer_lifecycle_events(event_timestamp DESC);

-- ----------------------------------------------------------------------------
-- COLLABORATION METRICS TABLE
-- ----------------------------------------------------------------------------
-- Tracks team collaboration patterns (shared secrets, recipients, etc.)
CREATE TABLE IF NOT EXISTS collaboration_metrics (
    id BIGSERIAL PRIMARY KEY,
    custid VARCHAR(255) NOT NULL,
    metric_date DATE NOT NULL,

    -- Collaboration indicators
    unique_recipients_count INT DEFAULT 0,
    shared_secrets_count INT DEFAULT 0,
    team_members_active INT DEFAULT 1, -- Number of users from same account active

    -- Pattern analysis
    avg_secret_recipients DECIMAL(5,2),
    secrets_with_recipients_pct DECIMAL(5,2),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_customer_date UNIQUE(custid, metric_date)
);

CREATE INDEX idx_collab_metrics_custid ON collaboration_metrics(custid);
CREATE INDEX idx_collab_metrics_date ON collaboration_metrics(metric_date DESC);

-- ----------------------------------------------------------------------------
-- AGGREGATE DAILY METRICS TABLE (for performance)
-- ----------------------------------------------------------------------------
-- Pre-computed daily aggregates to speed up queries
CREATE TABLE IF NOT EXISTS daily_customer_metrics (
    id BIGSERIAL PRIMARY KEY,
    custid VARCHAR(255) NOT NULL,
    metric_date DATE NOT NULL,

    -- Activity counts
    login_count INT DEFAULT 0,
    api_calls_count INT DEFAULT 0,
    secrets_created_count INT DEFAULT 0,
    secrets_retrieved_count INT DEFAULT 0,
    secrets_burned_count INT DEFAULT 0,

    -- Feature usage
    features_used_today INT DEFAULT 0,
    new_features_adopted INT DEFAULT 0,

    -- Data metrics
    total_active_secrets INT DEFAULT 0,
    data_storage_bytes BIGINT DEFAULT 0,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT unique_customer_metric_date UNIQUE(custid, metric_date)
);

CREATE INDEX idx_daily_metrics_custid ON daily_customer_metrics(custid);
CREATE INDEX idx_daily_metrics_date ON daily_customer_metrics(metric_date DESC);
CREATE INDEX idx_daily_metrics_composite ON daily_customer_metrics(custid, metric_date DESC);

-- ----------------------------------------------------------------------------
-- TRIGGERS FOR AUTOMATIC TIMESTAMP UPDATES
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_feature_adoption_updated_at BEFORE UPDATE ON feature_adoption
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_intervention_campaigns_updated_at BEFORE UPDATE ON intervention_campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_collaboration_metrics_updated_at BEFORE UPDATE ON collaboration_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_metrics_updated_at BEFORE UPDATE ON daily_customer_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------------------------------------------
-- VIEWS FOR COMMON QUERIES
-- ----------------------------------------------------------------------------

-- Latest health score per customer
CREATE OR REPLACE VIEW v_latest_customer_health AS
SELECT DISTINCT ON (custid)
    custid,
    health_score,
    health_status,
    zombie_since,
    days_as_zombie,
    churn_risk_score,
    days_since_last_login,
    api_calls_last_30d,
    features_used_count,
    calculated_at
FROM customer_health_scores
ORDER BY custid, calculated_at DESC;

-- Active paying customers
CREATE OR REPLACE VIEW v_active_customers AS
SELECT
    s.*,
    h.health_score,
    h.health_status,
    h.days_as_zombie
FROM subscriptions s
LEFT JOIN v_latest_customer_health h ON s.custid = h.custid
WHERE s.status = 'active'
    AND s.plan_type != 'free';

-- Zombie customers summary
CREATE OR REPLACE VIEW v_zombie_customers AS
SELECT
    s.custid,
    s.plan_type,
    s.monthly_revenue,
    s.subscription_start_date,
    h.health_score,
    h.zombie_since,
    h.days_as_zombie,
    h.days_since_last_login,
    h.api_calls_last_30d,
    h.churn_risk_score,
    h.reactivation_potential
FROM subscriptions s
JOIN v_latest_customer_health h ON s.custid = h.custid
WHERE s.status = 'active'
    AND h.health_status = 'zombie';

-- ----------------------------------------------------------------------------
-- SAMPLE DATA INSERTION (for testing)
-- ----------------------------------------------------------------------------

-- Insert sample subscriptions
INSERT INTO subscriptions (custid, plan_type, status, monthly_revenue, subscription_start_date, signup_source)
VALUES
    ('cust_sample_001', 'standard', 'active', 35.00, CURRENT_TIMESTAMP - INTERVAL '6 months', 'organic'),
    ('cust_sample_002', 'premium', 'active', 99.00, CURRENT_TIMESTAMP - INTERVAL '1 year', 'referral'),
    ('cust_sample_003', 'standard', 'active', 35.00, CURRENT_TIMESTAMP - INTERVAL '3 months', 'paid_ads')
ON CONFLICT (custid) DO NOTHING;

-- Insert sample login events
INSERT INTO login_events (custid, username, login_timestamp)
VALUES
    ('cust_sample_001', 'user001', CURRENT_TIMESTAMP - INTERVAL '2 days'),
    ('cust_sample_002', 'user002', CURRENT_TIMESTAMP - INTERVAL '45 days'), -- Zombie candidate
    ('cust_sample_003', 'user003', CURRENT_TIMESTAMP - INTERVAL '1 hour')
ON CONFLICT DO NOTHING;

COMMENT ON TABLE subscriptions IS 'Customer subscription and billing information';
COMMENT ON TABLE login_events IS 'User authentication and login activity tracking';
COMMENT ON TABLE api_usage IS 'API request tracking for usage analysis';
COMMENT ON TABLE feature_adoption IS 'Feature usage tracking per customer';
COMMENT ON TABLE customer_health_scores IS 'Calculated health scores and zombie status';
COMMENT ON TABLE intervention_campaigns IS 'Re-engagement campaign tracking';
COMMENT ON TABLE customer_lifecycle_events IS 'Customer journey state transitions';
COMMENT ON TABLE collaboration_metrics IS 'Team collaboration pattern analysis';
COMMENT ON TABLE daily_customer_metrics IS 'Pre-computed daily aggregates for performance';
