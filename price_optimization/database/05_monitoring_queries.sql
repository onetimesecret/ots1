-- =============================================================================
-- PHASE 5: Monitoring Queries and Alert System
-- Production monitoring and alerting SQL queries
-- =============================================================================

-- =============================================================================
-- REAL-TIME PERFORMANCE DASHBOARD
-- =============================================================================

-- Current pricing metrics across all tiers
CREATE OR REPLACE VIEW current_pricing_dashboard AS
SELECT
    pt.tier_name,
    vwa.recommended_price / 100.0 AS current_price_dollars,
    pm.metric_date,
    pm.total_revenue / 100.0 AS daily_revenue_dollars,
    pm.new_customers,
    pm.churned_customers,
    pm.active_customers,
    ROUND(pm.conversion_rate::NUMERIC, 4) AS conversion_rate,
    pm.total_visitors,
    ROUND((pm.total_revenue::FLOAT / NULLIF(pm.total_visitors, 0))::NUMERIC, 2) AS revenue_per_visitor,
    ROUND(pm.market_share_estimate::NUMERIC, 4) AS market_share
FROM pricing_metrics pm
JOIN product_tiers pt ON pt.tier_id = pm.tier_id
JOIN van_westendorp_analysis vwa ON vwa.tier_id = pm.tier_id AND vwa.is_current = TRUE
WHERE pm.metric_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY pm.metric_date DESC, pt.tier_level;

-- =============================================================================
-- REVENUE TREND ANALYSIS
-- =============================================================================

-- Daily revenue trend with 7-day moving average
WITH daily_revenue AS (
    SELECT
        metric_date,
        tier_id,
        total_revenue / 100.0 AS revenue_dollars
    FROM pricing_metrics
    WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
),
moving_avg AS (
    SELECT
        metric_date,
        tier_id,
        revenue_dollars,
        AVG(revenue_dollars) OVER (
            PARTITION BY tier_id
            ORDER BY metric_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS ma_7day
    FROM daily_revenue
)
SELECT
    ma.metric_date,
    pt.tier_name,
    ROUND(ma.revenue_dollars, 2) AS daily_revenue,
    ROUND(ma.ma_7day, 2) AS ma_7day,
    ROUND(((ma.revenue_dollars - ma.ma_7day) / NULLIF(ma.ma_7day, 0) * 100)::NUMERIC, 2) AS deviation_pct
FROM moving_avg ma
JOIN product_tiers pt ON pt.tier_id = ma.tier_id
ORDER BY ma.metric_date DESC, pt.tier_level;

-- =============================================================================
-- CONVERSION FUNNEL MONITORING
-- =============================================================================

CREATE OR REPLACE VIEW conversion_funnel AS
SELECT
    pt.tier_name,
    pm.metric_date,
    pm.total_visitors AS visitors,
    pm.pricing_page_views AS pricing_views,
    pm.new_customers AS conversions,

    -- Funnel metrics
    ROUND((pm.pricing_page_views::FLOAT / NULLIF(pm.total_visitors, 0))::NUMERIC, 4) AS visitor_to_pricing_rate,
    ROUND((pm.new_customers::FLOAT / NULLIF(pm.pricing_page_views, 0))::NUMERIC, 4) AS pricing_to_conversion_rate,
    ROUND(pm.conversion_rate::NUMERIC, 4) AS overall_conversion_rate,

    -- Dropoff analysis
    (pm.total_visitors - pm.pricing_page_views) AS dropoff_before_pricing,
    (pm.pricing_page_views - pm.new_customers) AS dropoff_at_pricing,

    ROUND(((pm.total_visitors - pm.pricing_page_views)::FLOAT / NULLIF(pm.total_visitors, 0) * 100)::NUMERIC, 2) AS dropoff_before_pricing_pct,
    ROUND(((pm.pricing_page_views - pm.new_customers)::FLOAT / NULLIF(pm.pricing_page_views, 0) * 100)::NUMERIC, 2) AS dropoff_at_pricing_pct
FROM pricing_metrics pm
JOIN product_tiers pt ON pt.tier_id = pm.tier_id
WHERE pm.metric_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY pm.metric_date DESC, pt.tier_level;

-- =============================================================================
-- ALERT DETECTION QUERIES
-- =============================================================================

-- Revenue Drop Alert
CREATE OR REPLACE FUNCTION check_revenue_drop_alert()
RETURNS TABLE (
    alert_triggered BOOLEAN,
    tier_name VARCHAR,
    current_revenue NUMERIC,
    baseline_revenue NUMERIC,
    drop_percentage NUMERIC,
    alert_message TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH recent_revenue AS (
        SELECT
            tier_id,
            AVG(total_revenue) AS avg_recent_revenue
        FROM pricing_metrics
        WHERE metric_date >= CURRENT_DATE - INTERVAL '7 days'
          AND metric_date < CURRENT_DATE
        GROUP BY tier_id
    ),
    baseline_revenue AS (
        SELECT
            tier_id,
            AVG(total_revenue) AS avg_baseline_revenue
        FROM pricing_metrics
        WHERE metric_date >= CURRENT_DATE - INTERVAL '21 days'
          AND metric_date < CURRENT_DATE - INTERVAL '7 days'
        GROUP BY tier_id
    )
    SELECT
        (rr.avg_recent_revenue < br.avg_baseline_revenue * 0.80) AS alert_triggered,
        pt.tier_name,
        ROUND((rr.avg_recent_revenue / 100.0)::NUMERIC, 2) AS current_revenue,
        ROUND((br.avg_baseline_revenue / 100.0)::NUMERIC, 2) AS baseline_revenue,
        ROUND((((rr.avg_recent_revenue - br.avg_baseline_revenue) / NULLIF(br.avg_baseline_revenue, 0)) * 100)::NUMERIC, 2) AS drop_percentage,
        CASE
            WHEN rr.avg_recent_revenue < br.avg_baseline_revenue * 0.80 THEN
                'CRITICAL: Revenue dropped ' ||
                ROUND((((br.avg_baseline_revenue - rr.avg_recent_revenue) / NULLIF(br.avg_baseline_revenue, 0)) * 100)::NUMERIC, 1) ||
                '% for ' || pt.tier_name
            ELSE
                'No alert'
        END AS alert_message
    FROM recent_revenue rr
    JOIN baseline_revenue br ON br.tier_id = rr.tier_id
    JOIN product_tiers pt ON pt.tier_id = rr.tier_id
    WHERE rr.avg_recent_revenue < br.avg_baseline_revenue * 0.80;
END;
$$ LANGUAGE plpgsql;

-- Conversion Rate Drop Alert
CREATE OR REPLACE FUNCTION check_conversion_drop_alert()
RETURNS TABLE (
    alert_triggered BOOLEAN,
    tier_name VARCHAR,
    current_conversion_rate NUMERIC,
    baseline_conversion_rate NUMERIC,
    drop_percentage NUMERIC,
    alert_message TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH recent_conversion AS (
        SELECT
            tier_id,
            AVG(conversion_rate) AS avg_recent_conversion
        FROM pricing_metrics
        WHERE metric_date >= CURRENT_DATE - INTERVAL '3 days'
        GROUP BY tier_id
    ),
    baseline_conversion AS (
        SELECT
            tier_id,
            AVG(conversion_rate) AS avg_baseline_conversion
        FROM pricing_metrics
        WHERE metric_date >= CURRENT_DATE - INTERVAL '14 days'
          AND metric_date < CURRENT_DATE - INTERVAL '3 days'
        GROUP BY tier_id
    )
    SELECT
        (rc.avg_recent_conversion < bc.avg_baseline_conversion * 0.85) AS alert_triggered,
        pt.tier_name,
        ROUND(rc.avg_recent_conversion::NUMERIC, 4) AS current_conversion,
        ROUND(bc.avg_baseline_conversion::NUMERIC, 4) AS baseline_conversion,
        ROUND((((rc.avg_recent_conversion - bc.avg_baseline_conversion) / NULLIF(bc.avg_baseline_conversion, 0)) * 100)::NUMERIC, 2) AS drop_pct,
        CASE
            WHEN rc.avg_recent_conversion < bc.avg_baseline_conversion * 0.85 THEN
                'WARNING: Conversion rate dropped ' ||
                ROUND((((bc.avg_baseline_conversion - rc.avg_recent_conversion) / NULLIF(bc.avg_baseline_conversion, 0)) * 100)::NUMERIC, 1) ||
                '% for ' || pt.tier_name
            ELSE
                'No alert'
        END AS message
    FROM recent_conversion rc
    JOIN baseline_conversion bc ON bc.tier_id = rc.tier_id
    JOIN product_tiers pt ON pt.tier_id = rc.tier_id
    WHERE rc.avg_recent_conversion < bc.avg_baseline_conversion * 0.85;
END;
$$ LANGUAGE plpgsql;

-- Customer Churn Alert
CREATE OR REPLACE FUNCTION check_churn_alert()
RETURNS TABLE (
    alert_triggered BOOLEAN,
    tier_name VARCHAR,
    churned_customers INTEGER,
    active_customers INTEGER,
    churn_rate NUMERIC,
    alert_message TEXT
) AS $$
BEGIN
    RETURN QUERY
    WITH recent_metrics AS (
        SELECT
            tier_id,
            SUM(churned_customers) AS total_churned,
            AVG(active_customers) AS avg_active
        FROM pricing_metrics
        WHERE metric_date >= CURRENT_DATE - INTERVAL '7 days'
        GROUP BY tier_id
    )
    SELECT
        ((rm.total_churned::FLOAT / NULLIF(rm.avg_active, 0)) > 0.10) AS alert_triggered,
        pt.tier_name,
        rm.total_churned::INTEGER,
        ROUND(rm.avg_active)::INTEGER AS active,
        ROUND(((rm.total_churned::FLOAT / NULLIF(rm.avg_active, 0)))::NUMERIC, 4) AS churn,
        CASE
            WHEN (rm.total_churned::FLOAT / NULLIF(rm.avg_active, 0)) > 0.10 THEN
                'WARNING: Churn rate ' ||
                ROUND(((rm.total_churned::FLOAT / NULLIF(rm.avg_active, 0)) * 100)::NUMERIC, 1) ||
                '% exceeds threshold (10%) for ' || pt.tier_name
            ELSE
                'No alert'
        END AS message
    FROM recent_metrics rm
    JOIN product_tiers pt ON pt.tier_id = rm.tier_id
    WHERE (rm.total_churned::FLOAT / NULLIF(rm.avg_active, 0)) > 0.10;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- EXECUTE ALL ALERTS
-- =============================================================================

CREATE OR REPLACE FUNCTION run_all_alerts()
RETURNS TABLE (
    alert_type VARCHAR,
    tier VARCHAR,
    severity VARCHAR,
    message TEXT,
    timestamp TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    -- Revenue alerts
    RETURN QUERY
    SELECT
        'revenue_drop'::VARCHAR AS type,
        r.tier_name AS tier,
        'CRITICAL'::VARCHAR AS severity,
        r.alert_message AS message,
        CURRENT_TIMESTAMP AS ts
    FROM check_revenue_drop_alert() r
    WHERE r.alert_triggered = TRUE;

    -- Conversion alerts
    RETURN QUERY
    SELECT
        'conversion_drop'::VARCHAR,
        c.tier_name,
        'WARNING'::VARCHAR,
        c.alert_message,
        CURRENT_TIMESTAMP
    FROM check_conversion_drop_alert() c
    WHERE c.alert_triggered = TRUE;

    -- Churn alerts
    RETURN QUERY
    SELECT
        'customer_churn'::VARCHAR,
        ch.tier_name,
        'WARNING'::VARCHAR,
        ch.alert_message,
        CURRENT_TIMESTAMP
    FROM check_churn_alert() ch
    WHERE ch.alert_triggered = TRUE;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- PERIODIC MONITORING JOB (Run via cron or scheduler)
-- =============================================================================

-- Log alerts to history table
INSERT INTO alert_history (
    alert_id,
    triggered_at,
    trigger_value,
    threshold_value,
    affected_tier_id,
    notification_sent,
    context_data
)
SELECT
    pa.alert_id,
    CURRENT_TIMESTAMP,
    pm.conversion_rate,
    pa.threshold_value,
    pm.tier_id,
    FALSE,
    jsonb_build_object(
        'metric_date', pm.metric_date,
        'total_visitors', pm.total_visitors,
        'conversion_rate', pm.conversion_rate
    )
FROM pricing_alerts pa
CROSS JOIN LATERAL (
    SELECT *
    FROM pricing_metrics pm2
    WHERE pm2.tier_id = pa.tier_id
      AND pm2.metric_date = CURRENT_DATE - INTERVAL '1 day'
    LIMIT 1
) pm
WHERE pa.is_active = TRUE
  AND pa.alert_type = 'conversion_drop'
  AND (
    CASE pa.threshold_operator
        WHEN '<' THEN pm.conversion_rate < pa.threshold_value
        WHEN '>' THEN pm.conversion_rate > pa.threshold_value
        WHEN '<=' THEN pm.conversion_rate <= pa.threshold_value
        WHEN '>=' THEN pm.conversion_rate >= pa.threshold_value
        ELSE FALSE
    END
  );

-- Update last triggered timestamp
UPDATE pricing_alerts pa
SET
    last_triggered_at = CURRENT_TIMESTAMP,
    trigger_count = trigger_count + 1
FROM alert_history ah
WHERE ah.alert_id = pa.alert_id
  AND ah.triggered_at = CURRENT_TIMESTAMP;

-- =============================================================================
-- COMPETITIVE MONITORING
-- =============================================================================

-- Compare current prices against competitors
CREATE OR REPLACE VIEW competitive_position AS
SELECT
    pt.tier_name AS our_tier,
    vwa.recommended_price / 100.0 AS our_price_dollars,
    cp.competitor_name,
    cp.product_name AS competitor_product,
    cp.current_price / 100.0 AS competitor_price_dollars,
    ROUND(((vwa.recommended_price - cp.current_price)::FLOAT / NULLIF(cp.current_price, 0) * 100)::NUMERIC, 2) AS price_difference_pct,
    CASE
        WHEN vwa.recommended_price < cp.current_price THEN 'Lower (competitive advantage)'
        WHEN vwa.recommended_price > cp.current_price THEN 'Higher (premium positioning)'
        ELSE 'Same'
    END AS positioning,
    cp.market_share_percentage,
    cp.last_verified_at,
    CURRENT_TIMESTAMP - cp.last_verified_at AS data_age
FROM van_westendorp_analysis vwa
JOIN product_tiers pt ON pt.tier_id = vwa.tier_id
JOIN competitive_pricing cp ON cp.tier_equivalent = pt.tier_name
WHERE vwa.is_current = TRUE
  AND cp.verified = TRUE
ORDER BY pt.tier_level, cp.market_share_percentage DESC;

-- =============================================================================
-- SYSTEM HEALTH CHECK
-- =============================================================================

CREATE OR REPLACE FUNCTION system_health_check()
RETURNS TABLE (
    check_name VARCHAR,
    status VARCHAR,
    details TEXT
) AS $$
BEGIN
    -- Check 1: Recent data availability
    RETURN QUERY
    SELECT
        'recent_data_available'::VARCHAR,
        CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*)::TEXT || ' records in last 24 hours'
    FROM pricing_metrics
    WHERE metric_date >= CURRENT_DATE - INTERVAL '1 day';

    -- Check 2: Van Westendorp analysis freshness
    RETURN QUERY
    SELECT
        'vw_analysis_current'::VARCHAR,
        CASE WHEN COUNT(*) >= 1 THEN 'PASS' ELSE 'FAIL' END,
        COUNT(*)::TEXT || ' current analyses'
    FROM van_westendorp_analysis
    WHERE is_current = TRUE
      AND analysis_date >= CURRENT_DATE - INTERVAL '30 days';

    -- Check 3: Active A/B tests
    RETURN QUERY
    SELECT
        'active_ab_tests'::VARCHAR,
        'INFO',
        COUNT(*)::TEXT || ' active experiments'
    FROM ab_test_experiments
    WHERE status = 'active';

    -- Check 4: Alert system active
    RETURN QUERY
    SELECT
        'alert_system_active'::VARCHAR,
        CASE WHEN COUNT(*) >= 3 THEN 'PASS' ELSE 'WARN' END,
        COUNT(*)::TEXT || ' active alerts configured'
    FROM pricing_alerts
    WHERE is_active = TRUE;

    -- Check 5: Data quality score
    RETURN QUERY
    SELECT
        'data_quality'::VARCHAR,
        CASE WHEN AVG(data_quality_score) >= 0.80 THEN 'PASS' ELSE 'WARN' END,
        'Average quality score: ' || ROUND(AVG(data_quality_score)::NUMERIC, 3)::TEXT
    FROM van_westendorp_analysis
    WHERE is_current = TRUE;
END;
$$ LANGUAGE plpgsql;

-- Run system health check
SELECT * FROM system_health_check();
