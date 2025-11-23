-- ================================================================
-- MONITORING QUERIES AND ALERT SYSTEM
-- Real-time pricing compliance and performance tracking
-- ================================================================

-- ================================================================
-- 1. REVENUE PERFORMANCE MONITORING
-- ================================================================

-- Daily revenue performance vs targets
CREATE OR REPLACE VIEW vw_revenue_performance_daily AS
WITH daily_targets AS (
    SELECT
        product_tier,
        market_segment,
        -- Target revenue based on historical 30-day average * 1.1 (10% growth)
        AVG(daily_revenue) * 1.1 AS target_daily_revenue,
        AVG(conversion_rate) AS target_conversion_rate
    FROM revenue_metrics
    WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
      AND metric_date < CURRENT_DATE - INTERVAL '7 days'
    GROUP BY product_tier, market_segment
),
recent_performance AS (
    SELECT
        product_tier,
        market_segment,
        metric_date,
        daily_revenue,
        conversion_rate,
        new_customers,
        churned_customers
    FROM revenue_metrics
    WHERE metric_date >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT
    r.metric_date,
    r.product_tier,
    r.market_segment,
    r.daily_revenue,
    t.target_daily_revenue,
    ROUND((r.daily_revenue / NULLIF(t.target_daily_revenue, 0) * 100) - 100, 2) AS revenue_vs_target_percentage,
    r.conversion_rate,
    t.target_conversion_rate,
    ROUND((r.conversion_rate / NULLIF(t.target_conversion_rate, 0) * 100) - 100, 2) AS conversion_vs_target_percentage,
    r.new_customers,
    r.churned_customers,
    r.new_customers - r.churned_customers AS net_customer_growth,
    CASE
        WHEN r.daily_revenue < t.target_daily_revenue * 0.9 THEN 'UNDERPERFORMING'
        WHEN r.daily_revenue > t.target_daily_revenue * 1.1 THEN 'EXCEEDING'
        ELSE 'ON_TARGET'
    END AS performance_status
FROM recent_performance r
JOIN daily_targets t ON r.product_tier = t.product_tier
                    AND r.market_segment = t.market_segment
ORDER BY r.metric_date DESC, r.product_tier, r.market_segment;

-- Revenue trend analysis (7-day vs 30-day moving averages)
CREATE OR REPLACE VIEW vw_revenue_trends AS
WITH metrics_with_ma AS (
    SELECT
        metric_date,
        product_tier,
        market_segment,
        daily_revenue,
        conversion_rate,
        AVG(daily_revenue) OVER (
            PARTITION BY product_tier, market_segment
            ORDER BY metric_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS ma_7day_revenue,
        AVG(daily_revenue) OVER (
            PARTITION BY product_tier, market_segment
            ORDER BY metric_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS ma_30day_revenue,
        AVG(conversion_rate) OVER (
            PARTITION BY product_tier, market_segment
            ORDER BY metric_date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS ma_7day_conversion,
        AVG(conversion_rate) OVER (
            PARTITION BY product_tier, market_segment
            ORDER BY metric_date
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS ma_30day_conversion
    FROM revenue_metrics
    WHERE metric_date >= CURRENT_DATE - INTERVAL '60 days'
)
SELECT
    metric_date,
    product_tier,
    market_segment,
    ROUND(daily_revenue, 2) AS daily_revenue,
    ROUND(ma_7day_revenue, 2) AS ma_7day_revenue,
    ROUND(ma_30day_revenue, 2) AS ma_30day_revenue,
    ROUND(((ma_7day_revenue - ma_30day_revenue) / NULLIF(ma_30day_revenue, 0) * 100), 2) AS trend_percentage,
    ROUND(conversion_rate, 4) AS conversion_rate,
    ROUND(ma_7day_conversion, 4) AS ma_7day_conversion,
    ROUND(ma_30day_conversion, 4) AS ma_30day_conversion,
    CASE
        WHEN ma_7day_revenue > ma_30day_revenue * 1.05 THEN 'TRENDING_UP'
        WHEN ma_7day_revenue < ma_30day_revenue * 0.95 THEN 'TRENDING_DOWN'
        ELSE 'STABLE'
    END AS trend_direction
FROM metrics_with_ma
WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY metric_date DESC, product_tier, market_segment;

-- ================================================================
-- 2. CONVERSION RATE MONITORING
-- ================================================================

-- Conversion rate anomaly detection
CREATE OR REPLACE VIEW vw_conversion_anomalies AS
WITH conversion_stats AS (
    SELECT
        product_tier,
        market_segment,
        AVG(conversion_rate) AS mean_conversion,
        STDDEV(conversion_rate) AS std_conversion
    FROM revenue_metrics
    WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
      AND metric_date < CURRENT_DATE - INTERVAL '7 days'
    GROUP BY product_tier, market_segment
),
recent_conversions AS (
    SELECT
        metric_date,
        product_tier,
        market_segment,
        conversion_rate,
        new_customers,
        total_active_customers
    FROM revenue_metrics
    WHERE metric_date >= CURRENT_DATE - INTERVAL '7 days'
)
SELECT
    r.metric_date,
    r.product_tier,
    r.market_segment,
    r.conversion_rate,
    s.mean_conversion AS expected_conversion,
    s.std_conversion,
    -- Z-score for anomaly detection
    ROUND(
        (r.conversion_rate - s.mean_conversion) / NULLIF(s.std_conversion, 0),
        2
    ) AS z_score,
    CASE
        WHEN ABS((r.conversion_rate - s.mean_conversion) / NULLIF(s.std_conversion, 0)) > 2 THEN 'ANOMALY'
        WHEN ABS((r.conversion_rate - s.mean_conversion) / NULLIF(s.std_conversion, 0)) > 1 THEN 'WARNING'
        ELSE 'NORMAL'
    END AS anomaly_status,
    r.new_customers,
    r.total_active_customers
FROM recent_conversions r
JOIN conversion_stats s ON r.product_tier = s.product_tier
                        AND r.market_segment = s.market_segment
WHERE ABS((r.conversion_rate - s.mean_conversion) / NULLIF(s.std_conversion, 0)) > 1
ORDER BY ABS((r.conversion_rate - s.mean_conversion) / NULLIF(s.std_conversion, 0)) DESC;

-- ================================================================
-- 3. COMPETITOR PRICE MONITORING
-- ================================================================

-- Recent competitor price changes
CREATE OR REPLACE VIEW vw_competitor_price_changes AS
WITH latest_prices AS (
    SELECT DISTINCT ON (competitor_name, product_tier)
        competitor_name,
        product_tier,
        price AS current_price,
        scraped_at AS current_scraped_at
    FROM competitor_pricing
    WHERE verified = true
    ORDER BY competitor_name, product_tier, scraped_at DESC
),
previous_prices AS (
    SELECT DISTINCT ON (competitor_name, product_tier)
        competitor_name,
        product_tier,
        price AS previous_price,
        scraped_at AS previous_scraped_at
    FROM competitor_pricing cp1
    WHERE verified = true
      AND EXISTS (
          SELECT 1 FROM competitor_pricing cp2
          WHERE cp2.competitor_name = cp1.competitor_name
            AND cp2.product_tier = cp1.product_tier
            AND cp2.scraped_at > cp1.scraped_at
            AND cp2.verified = true
      )
    ORDER BY competitor_name, product_tier, scraped_at DESC
)
SELECT
    l.competitor_name,
    l.product_tier,
    p.previous_price,
    p.previous_scraped_at,
    l.current_price,
    l.current_scraped_at,
    ROUND(l.current_price - p.previous_price, 2) AS price_change,
    ROUND((l.current_price - p.previous_price) / NULLIF(p.previous_price, 0) * 100, 2) AS price_change_percentage,
    EXTRACT(DAY FROM l.current_scraped_at - p.previous_scraped_at) AS days_since_change,
    CASE
        WHEN l.current_price > p.previous_price THEN 'INCREASE'
        WHEN l.current_price < p.previous_price THEN 'DECREASE'
        ELSE 'NO_CHANGE'
    END AS change_direction
FROM latest_prices l
JOIN previous_prices p ON l.competitor_name = p.competitor_name
                      AND l.product_tier = p.product_tier
WHERE l.current_price != p.previous_price
ORDER BY l.current_scraped_at DESC;

-- ================================================================
-- 4. PRICING COMPLIANCE MONITORING
-- ================================================================

-- Check for unauthorized price deviations
CREATE OR REPLACE VIEW vw_pricing_compliance AS
WITH approved_prices AS (
    SELECT DISTINCT ON (product_tier)
        product_tier,
        new_price AS approved_price,
        effective_date,
        approved_by
    FROM price_changes_audit
    WHERE approval_timestamp IS NOT NULL
      AND executed_date IS NOT NULL
      AND rollback_date IS NULL
    ORDER BY product_tier, effective_date DESC
),
current_active_prices AS (
    -- This would come from your active pricing configuration
    -- For now, using most recent revenue metrics
    SELECT DISTINCT ON (product_tier)
        product_tier,
        effective_price AS current_price,
        metric_date AS last_observed
    FROM revenue_metrics
    ORDER BY product_tier, metric_date DESC
)
SELECT
    c.product_tier,
    c.current_price,
    a.approved_price,
    a.effective_date AS approved_on,
    a.approved_by,
    ROUND(ABS(c.current_price - a.approved_price), 2) AS price_deviation,
    ROUND(ABS(c.current_price - a.approved_price) / NULLIF(a.approved_price, 0) * 100, 2) AS deviation_percentage,
    c.last_observed,
    CASE
        WHEN ABS(c.current_price - a.approved_price) / NULLIF(a.approved_price, 0) > 0.01 THEN 'NON_COMPLIANT'
        ELSE 'COMPLIANT'
    END AS compliance_status
FROM current_active_prices c
LEFT JOIN approved_prices a ON c.product_tier = a.product_tier
WHERE ABS(c.current_price - a.approved_price) / NULLIF(a.approved_price, 0) > 0.01
   OR a.approved_price IS NULL;

-- ================================================================
-- 5. AUTOMATED ALERT GENERATION
-- ================================================================

-- Function to generate alerts based on monitoring rules
CREATE OR REPLACE FUNCTION generate_pricing_alerts()
RETURNS TABLE (
    alert_type VARCHAR(50),
    severity VARCHAR(20),
    title VARCHAR(200),
    description TEXT,
    product_tier VARCHAR(50),
    market_segment VARCHAR(100),
    metric_value DECIMAL(15,4),
    threshold_value DECIMAL(15,4)
) AS $$
BEGIN
    -- Alert 1: Revenue decline > 10% from 7-day MA
    RETURN QUERY
    SELECT
        'revenue_decline'::VARCHAR(50),
        CASE
            WHEN trend_percentage < -20 THEN 'critical'::VARCHAR(20)
            WHEN trend_percentage < -10 THEN 'warning'::VARCHAR(20)
            ELSE 'info'::VARCHAR(20)
        END,
        ('Revenue declining for ' || vr.product_tier || ' - ' || vr.market_segment)::VARCHAR(200),
        ('7-day moving average is ' || ABS(trend_percentage)::TEXT || '% below 30-day average')::TEXT,
        vr.product_tier::VARCHAR(50),
        vr.market_segment::VARCHAR(100),
        vr.ma_7day_revenue,
        vr.ma_30day_revenue
    FROM vw_revenue_trends vr
    WHERE vr.metric_date = CURRENT_DATE - INTERVAL '1 day'
      AND vr.trend_percentage < -10;

    -- Alert 2: Conversion rate anomalies
    RETURN QUERY
    SELECT
        'conversion_anomaly'::VARCHAR(50),
        CASE
            WHEN ca.anomaly_status = 'ANOMALY' THEN 'critical'::VARCHAR(20)
            ELSE 'warning'::VARCHAR(20)
        END,
        ('Conversion rate anomaly: ' || ca.product_tier || ' - ' || ca.market_segment)::VARCHAR(200),
        ('Conversion rate ' || ca.conversion_rate::TEXT || ' is ' || ABS(ca.z_score)::TEXT ||
         ' standard deviations from expected ' || ca.expected_conversion::TEXT)::TEXT,
        ca.product_tier::VARCHAR(50),
        ca.market_segment::VARCHAR(100),
        ca.conversion_rate,
        ca.expected_conversion
    FROM vw_conversion_anomalies ca
    WHERE ca.metric_date >= CURRENT_DATE - INTERVAL '1 day'
      AND ca.anomaly_status IN ('ANOMALY', 'WARNING');

    -- Alert 3: Competitor price changes
    RETURN QUERY
    SELECT
        'competitor_change'::VARCHAR(50),
        CASE
            WHEN ABS(cpc.price_change_percentage) > 15 THEN 'critical'::VARCHAR(20)
            WHEN ABS(cpc.price_change_percentage) > 10 THEN 'warning'::VARCHAR(20)
            ELSE 'info'::VARCHAR(20)
        END,
        ('Competitor price change: ' || cpc.competitor_name || ' ' || cpc.product_tier)::VARCHAR(200),
        (cpc.competitor_name || ' changed ' || cpc.product_tier || ' tier price by ' ||
         cpc.price_change_percentage::TEXT || '% (from $' || cpc.previous_price::TEXT ||
         ' to $' || cpc.current_price::TEXT || ')')::TEXT,
        cpc.product_tier::VARCHAR(50),
        NULL::VARCHAR(100),
        cpc.current_price,
        cpc.previous_price
    FROM vw_competitor_price_changes cpc
    WHERE cpc.days_since_change <= 7
      AND ABS(cpc.price_change_percentage) >= 5;

    -- Alert 4: Pricing compliance violations
    RETURN QUERY
    SELECT
        'price_deviation'::VARCHAR(50),
        'critical'::VARCHAR(20),
        ('Pricing compliance violation: ' || pc.product_tier)::VARCHAR(200),
        ('Current price $' || pc.current_price::TEXT || ' deviates ' ||
         pc.deviation_percentage::TEXT || '% from approved price $' ||
         pc.approved_price::TEXT)::TEXT,
        pc.product_tier::VARCHAR(50),
        NULL::VARCHAR(100),
        pc.current_price,
        pc.approved_price
    FROM vw_pricing_compliance pc
    WHERE pc.compliance_status = 'NON_COMPLIANT';

END;
$$ LANGUAGE plpgsql;

-- Insert new alerts (run periodically via cron)
CREATE OR REPLACE FUNCTION insert_new_alerts()
RETURNS INTEGER AS $$
DECLARE
    v_alert_count INTEGER := 0;
BEGIN
    -- Insert alerts that don't already exist
    INSERT INTO pricing_alerts (
        alert_type,
        severity,
        title,
        description,
        product_tier,
        market_segment,
        current_value,
        threshold_value,
        status
    )
    SELECT
        ga.alert_type,
        ga.severity,
        ga.title,
        ga.description,
        ga.product_tier,
        ga.market_segment,
        ga.metric_value,
        ga.threshold_value,
        'open'
    FROM generate_pricing_alerts() ga
    WHERE NOT EXISTS (
        SELECT 1 FROM pricing_alerts pa
        WHERE pa.alert_type = ga.alert_type
          AND pa.product_tier = ga.product_tier
          AND COALESCE(pa.market_segment, '') = COALESCE(ga.market_segment, '')
          AND pa.status IN ('open', 'acknowledged')
          AND pa.created_at > NOW() - INTERVAL '24 hours'
    );

    GET DIAGNOSTICS v_alert_count = ROW_COUNT;

    RETURN v_alert_count;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- 6. ALERT MANAGEMENT
-- ================================================================

-- Acknowledge alert
CREATE OR REPLACE FUNCTION acknowledge_alert(
    p_alert_id UUID,
    p_acknowledged_by VARCHAR(255)
) RETURNS VOID AS $$
BEGIN
    UPDATE pricing_alerts
    SET
        status = 'acknowledged',
        acknowledged_by = p_acknowledged_by,
        acknowledged_at = NOW()
    WHERE id = p_alert_id
      AND status = 'open';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Alert % not found or not in open status', p_alert_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Resolve alert
CREATE OR REPLACE FUNCTION resolve_alert(
    p_alert_id UUID
) RETURNS VOID AS $$
BEGIN
    UPDATE pricing_alerts
    SET
        status = 'resolved',
        resolved_at = NOW()
    WHERE id = p_alert_id
      AND status IN ('open', 'acknowledged');

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Alert % not found or already resolved', p_alert_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- 7. PERFORMANCE DASHBOARDS
-- ================================================================

-- Executive dashboard summary
CREATE OR REPLACE VIEW vw_executive_dashboard AS
SELECT
    -- Time period
    CURRENT_DATE - INTERVAL '1 day' AS report_date,

    -- Revenue metrics (last 30 days)
    (SELECT SUM(daily_revenue)
     FROM revenue_metrics
     WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days') AS revenue_30d,

    -- Revenue growth (30d vs previous 30d)
    ROUND(
        ((SELECT SUM(daily_revenue)
          FROM revenue_metrics
          WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days') -
         (SELECT SUM(daily_revenue)
          FROM revenue_metrics
          WHERE metric_date >= CURRENT_DATE - INTERVAL '60 days'
            AND metric_date < CURRENT_DATE - INTERVAL '30 days')) /
        NULLIF((SELECT SUM(daily_revenue)
                FROM revenue_metrics
                WHERE metric_date >= CURRENT_DATE - INTERVAL '60 days'
                  AND metric_date < CURRENT_DATE - INTERVAL '30 days'), 0) * 100,
        2
    ) AS revenue_growth_percentage,

    -- Customer metrics
    (SELECT SUM(new_customers)
     FROM revenue_metrics
     WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days') AS new_customers_30d,

    (SELECT SUM(churned_customers)
     FROM revenue_metrics
     WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days') AS churned_customers_30d,

    -- Active experiments
    (SELECT COUNT(*)
     FROM ab_test_experiments
     WHERE status = 'active') AS active_experiments,

    -- Open alerts
    (SELECT COUNT(*)
     FROM pricing_alerts
     WHERE status = 'open') AS open_alerts,

    -- Critical alerts
    (SELECT COUNT(*)
     FROM pricing_alerts
     WHERE status = 'open' AND severity = 'critical') AS critical_alerts,

    -- Average conversion rate (last 7 days)
    (SELECT ROUND(AVG(conversion_rate), 4)
     FROM revenue_metrics
     WHERE metric_date >= CURRENT_DATE - INTERVAL '7 days') AS avg_conversion_rate_7d,

    -- Top performing tier
    (SELECT product_tier
     FROM revenue_metrics
     WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
     GROUP BY product_tier
     ORDER BY SUM(daily_revenue) DESC
     LIMIT 1) AS top_performing_tier,

    -- Price optimization recommendations pending
    (SELECT COUNT(DISTINCT product_tier)
     FROM price_optimization_results
     WHERE analysis_timestamp >= CURRENT_DATE - INTERVAL '7 days'
       AND NOT EXISTS (
           SELECT 1 FROM price_changes_audit
           WHERE price_changes_audit.analysis_id = price_optimization_results.analysis_id
             AND approval_timestamp IS NOT NULL
       )) AS pending_optimization_recommendations;

-- KPI tracker (Key Performance Indicators)
CREATE OR REPLACE VIEW vw_kpi_tracker AS
SELECT
    product_tier,
    market_segment,

    -- Revenue KPIs
    SUM(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '7 days' THEN daily_revenue ELSE 0 END) AS revenue_7d,
    SUM(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '30 days' THEN daily_revenue ELSE 0 END) AS revenue_30d,
    SUM(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '90 days' THEN daily_revenue ELSE 0 END) AS revenue_90d,

    -- Growth rates
    ROUND(
        (SUM(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '7 days' THEN daily_revenue ELSE 0 END) /
         SUM(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '14 days'
                   AND metric_date < CURRENT_DATE - INTERVAL '7 days' THEN daily_revenue ELSE 0 END) - 1) * 100,
        2
    ) AS wow_growth_percentage,

    ROUND(
        (SUM(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '30 days' THEN daily_revenue ELSE 0 END) /
         SUM(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '60 days'
                   AND metric_date < CURRENT_DATE - INTERVAL '30 days' THEN daily_revenue ELSE 0 END) - 1) * 100,
        2
    ) AS mom_growth_percentage,

    -- Customer metrics
    SUM(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '30 days' THEN new_customers ELSE 0 END) AS new_customers_30d,
    SUM(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '30 days' THEN churned_customers ELSE 0 END) AS churned_30d,

    -- Average metrics
    ROUND(AVG(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '30 days' THEN conversion_rate END), 4) AS avg_conversion_rate,
    ROUND(AVG(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '30 days' THEN customer_lifetime_value END), 2) AS avg_ltv,
    ROUND(AVG(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '30 days' THEN customer_acquisition_cost END), 2) AS avg_cac,

    -- LTV/CAC ratio
    ROUND(
        AVG(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '30 days' THEN customer_lifetime_value END) /
        NULLIF(AVG(CASE WHEN metric_date >= CURRENT_DATE - INTERVAL '30 days' THEN customer_acquisition_cost END), 0),
        2
    ) AS ltv_cac_ratio

FROM revenue_metrics
WHERE metric_date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY product_tier, market_segment
ORDER BY revenue_30d DESC;

-- ================================================================
-- 8. SCHEDULED MONITORING JOBS
-- ================================================================

/*
-- Example cron job configuration (to be set up in PostgreSQL pg_cron extension)

-- Run alert generation every hour
SELECT cron.schedule('generate-pricing-alerts', '0 * * * *', $$
    SELECT insert_new_alerts();
$$);

-- Auto-resolve old acknowledged alerts (after 7 days)
SELECT cron.schedule('auto-resolve-old-alerts', '0 2 * * *', $$
    UPDATE pricing_alerts
    SET status = 'dismissed'
    WHERE status = 'acknowledged'
      AND acknowledged_at < NOW() - INTERVAL '7 days';
$$);

-- Daily KPI snapshot
SELECT cron.schedule('daily-kpi-snapshot', '0 1 * * *', $$
    -- Log KPIs to separate tracking table for historical analysis
    INSERT INTO kpi_snapshots (snapshot_date, kpi_data)
    SELECT CURRENT_DATE, jsonb_agg(row_to_json(vw_kpi_tracker))
    FROM vw_kpi_tracker;
$$);
*/

-- ================================================================
-- 9. EXAMPLE QUERIES FOR MONITORING
-- ================================================================

-- Check current open alerts
SELECT
    alert_type,
    severity,
    title,
    description,
    product_tier,
    market_segment,
    created_at,
    EXTRACT(HOUR FROM NOW() - created_at) AS hours_open
FROM pricing_alerts
WHERE status = 'open'
ORDER BY
    CASE severity
        WHEN 'critical' THEN 1
        WHEN 'warning' THEN 2
        ELSE 3
    END,
    created_at;

-- Revenue performance summary
SELECT * FROM vw_revenue_performance_daily
WHERE metric_date >= CURRENT_DATE - INTERVAL '7 days'
  AND performance_status != 'ON_TARGET'
ORDER BY
    CASE performance_status
        WHEN 'UNDERPERFORMING' THEN 1
        ELSE 2
    END,
    revenue_vs_target_percentage;

-- Executive dashboard
SELECT * FROM vw_executive_dashboard;
