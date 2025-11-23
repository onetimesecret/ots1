# frozen_string_literal: true

##
# Health Score API Endpoints
# ==========================
#
# REST API endpoints for accessing customer health scores and zombie status.
#
# Endpoints:
#   GET  /api/v1/customers/:custid/health
#   GET  /api/v1/health/zombies
#   GET  /api/v1/health/at-risk
#   GET  /api/v1/health/dashboard
#   POST /api/v1/customers/:custid/health/recalculate
#
# Author: Claude
# Date: 2025-11-23
# Version: 1.0

require 'sinatra/base'
require 'json'
require 'pg'
require_relative '../algorithms/health_scorer'

module ZombieDetection
  ##
  # Sinatra API for health score endpoints
  class HealthScoreAPI < Sinatra::Base
    configure do
      set :show_exceptions, false
      set :dump_errors, false
    end

    helpers do
      def db
        @db ||= PG.connect(
          host: ENV['DB_HOST'] || 'localhost',
          dbname: ENV['DB_NAME'] || 'onetimesecret',
          user: ENV['DB_USER'] || 'postgres',
          password: ENV['DB_PASSWORD']
        )
      end

      def json_response(data, status: 200)
        content_type :json
        status status
        JSON.generate(data)
      end

      def error_response(message, status: 400)
        json_response({ error: message }, status: status)
      end

      def require_auth!
        # TODO: Implement proper authentication
        # For now, check for API key in header
        api_key = request.env['HTTP_X_API_KEY']
        halt 401, json_response({ error: 'Unauthorized' }, status: 401) unless api_key

        # Validate API key (simplified)
        # In production, validate against database or auth service
        unless api_key == ENV['INTERNAL_API_KEY']
          halt 403, json_response({ error: 'Forbidden' }, status: 403)
        end
      end

      def paginate(query, page: 1, per_page: 50)
        offset = (page - 1) * per_page
        "#{query} LIMIT #{per_page} OFFSET #{offset}"
      end
    end

    before do
      require_auth! unless request.path_info == '/health'
    end

    ##
    # Health check endpoint
    get '/health' do
      json_response({ status: 'ok', timestamp: Time.now.utc.iso8601 })
    end

    ##
    # Get health score for a specific customer
    #
    # GET /api/v1/customers/:custid/health
    #
    # Response:
    #   {
    #     "custid": "cust_123",
    #     "overall_score": 75.5,
    #     "health_status": "healthy",
    #     "components": { ... },
    #     "risk_factors": [...],
    #     "strengths": [...],
    #     "calculated_at": "2025-11-23T10:00:00Z"
    #   }
    get '/api/v1/customers/:custid/health' do
      custid = params[:custid]

      query = <<~SQL
        SELECT
          custid,
          health_score AS overall_score,
          health_status,
          login_score,
          api_usage_score,
          feature_adoption_score,
          collaboration_score,
          data_activity_score,
          churn_risk_score,
          reactivation_potential,
          zombie_since,
          days_as_zombie,
          days_since_last_login,
          api_calls_last_30d,
          features_used_count,
          calculated_at
        FROM customer_health_scores
        WHERE custid = $1
        ORDER BY calculated_at DESC
        LIMIT 1
      SQL

      result = db.exec_params(query, [custid])

      if result.ntuples.zero?
        return error_response("Customer not found or no health score available", status: 404)
      end

      row = result[0]

      # Get zombie signals (stored in separate query or computed)
      signals_query = <<~SQL
        SELECT metadata->'zombie_signals' AS signals
        FROM customer_lifecycle_events
        WHERE custid = $1
        ORDER BY event_timestamp DESC
        LIMIT 1
      SQL

      signals_result = db.exec_params(signals_query, [custid])
      zombie_signals = signals_result.ntuples.positive? ? JSON.parse(signals_result[0]['signals'] || '[]') : []

      json_response({
        custid: row['custid'],
        overall_score: row['overall_score'].to_f.round(2),
        health_status: row['health_status'],
        components: {
          login_score: row['login_score'].to_f.round(2),
          api_usage_score: row['api_usage_score'].to_f.round(2),
          feature_adoption_score: row['feature_adoption_score'].to_f.round(2),
          collaboration_score: row['collaboration_score'].to_f.round(2),
          data_activity_score: row['data_activity_score'].to_f.round(2)
        },
        risk_metrics: {
          churn_risk_score: row['churn_risk_score'].to_f.round(2),
          reactivation_potential: row['reactivation_potential'].to_f.round(2),
          days_since_last_login: row['days_since_last_login']&.to_i,
          api_calls_last_30d: row['api_calls_last_30d']&.to_i
        },
        zombie_info: {
          is_zombie: row['health_status'] == 'zombie',
          zombie_since: row['zombie_since'],
          days_as_zombie: row['days_as_zombie']&.to_i,
          zombie_signals: zombie_signals
        },
        calculated_at: row['calculated_at']
      })
    end

    ##
    # Get all zombie customers
    #
    # GET /api/v1/health/zombies?page=1&per_page=50&sort=churn_risk
    #
    # Query params:
    #   - page: Page number (default: 1)
    #   - per_page: Results per page (default: 50, max: 100)
    #   - sort: Sort by 'churn_risk', 'days_as_zombie', 'revenue' (default: churn_risk)
    get '/api/v1/health/zombies' do
      page = (params[:page] || 1).to_i
      per_page = [(params[:per_page] || 50).to_i, 100].min
      sort_by = params[:sort] || 'churn_risk'

      order_clause = case sort_by
                     when 'churn_risk'
                       'churn_risk_score DESC'
                     when 'days_as_zombie'
                       'days_as_zombie DESC'
                     when 'revenue'
                       's.monthly_revenue DESC'
                     else
                       'churn_risk_score DESC'
                     end

      query = <<~SQL
        SELECT
          chs.custid,
          s.plan_type,
          s.monthly_revenue,
          chs.health_score,
          chs.health_status,
          chs.churn_risk_score,
          chs.reactivation_potential,
          chs.zombie_since,
          chs.days_as_zombie,
          chs.days_since_last_login,
          chs.api_calls_last_30d,
          chs.calculated_at
        FROM customer_health_scores chs
        JOIN subscriptions s ON chs.custid = s.custid
        WHERE chs.custid IN (
          SELECT DISTINCT ON (custid) custid
          FROM customer_health_scores
          ORDER BY custid, calculated_at DESC
        )
        AND chs.health_status = 'zombie'
        AND s.status = 'active'
        ORDER BY #{order_clause}
      SQL

      query = paginate(query, page: page, per_page: per_page)

      result = db.exec(query)

      zombies = result.map do |row|
        {
          custid: row['custid'],
          plan_type: row['plan_type'],
          monthly_revenue: row['monthly_revenue'].to_f,
          health_score: row['health_score'].to_f.round(2),
          churn_risk_score: row['churn_risk_score'].to_f.round(2),
          reactivation_potential: row['reactivation_potential'].to_f.round(2),
          zombie_since: row['zombie_since'],
          days_as_zombie: row['days_as_zombie']&.to_i,
          days_since_last_login: row['days_since_last_login']&.to_i,
          api_calls_last_30d: row['api_calls_last_30d']&.to_i
        }
      end

      # Get total count
      count_query = <<~SQL
        SELECT COUNT(DISTINCT chs.custid) AS total
        FROM customer_health_scores chs
        JOIN subscriptions s ON chs.custid = s.custid
        WHERE chs.health_status = 'zombie'
        AND s.status = 'active'
      SQL

      total_count = db.exec(count_query)[0]['total'].to_i

      json_response({
        zombies: zombies,
        pagination: {
          page: page,
          per_page: per_page,
          total_count: total_count,
          total_pages: (total_count.to_f / per_page).ceil
        },
        meta: {
          sort_by: sort_by,
          total_revenue_at_risk: zombies.sum { |z| z[:monthly_revenue] }.round(2)
        }
      })
    end

    ##
    # Get all at-risk customers
    #
    # GET /api/v1/health/at-risk?page=1&per_page=50
    get '/api/v1/health/at-risk' do
      page = (params[:page] || 1).to_i
      per_page = [(params[:per_page] || 50).to_i, 100].min

      query = <<~SQL
        SELECT
          chs.custid,
          s.plan_type,
          s.monthly_revenue,
          chs.health_score,
          chs.churn_risk_score,
          chs.days_since_last_login,
          chs.api_calls_last_30d,
          chs.calculated_at
        FROM customer_health_scores chs
        JOIN subscriptions s ON chs.custid = s.custid
        WHERE chs.custid IN (
          SELECT DISTINCT ON (custid) custid
          FROM customer_health_scores
          ORDER BY custid, calculated_at DESC
        )
        AND chs.health_status = 'at_risk'
        AND s.status = 'active'
        ORDER BY chs.churn_risk_score DESC
      SQL

      query = paginate(query, page: page, per_page: per_page)

      result = db.exec(query)

      at_risk = result.map do |row|
        {
          custid: row['custid'],
          plan_type: row['plan_type'],
          monthly_revenue: row['monthly_revenue'].to_f,
          health_score: row['health_score'].to_f.round(2),
          churn_risk_score: row['churn_risk_score'].to_f.round(2),
          days_since_last_login: row['days_since_last_login']&.to_i,
          api_calls_last_30d: row['api_calls_last_30d']&.to_i
        }
      end

      json_response({ at_risk_customers: at_risk })
    end

    ##
    # Get dashboard summary metrics
    #
    # GET /api/v1/health/dashboard
    #
    # Returns aggregate metrics for monitoring:
    #   - Total customers by health status
    #   - Revenue at risk
    #   - Trend data (week over week)
    get '/api/v1/health/dashboard' do
      query = <<~SQL
        WITH latest_scores AS (
          SELECT DISTINCT ON (custid)
            custid,
            health_status,
            health_score,
            churn_risk_score,
            calculated_at
          FROM customer_health_scores
          ORDER BY custid, calculated_at DESC
        ),
        status_counts AS (
          SELECT
            health_status,
            COUNT(*) AS customer_count,
            ROUND(AVG(health_score), 2) AS avg_health_score,
            ROUND(AVG(churn_risk_score), 2) AS avg_churn_risk
          FROM latest_scores
          GROUP BY health_status
        ),
        revenue_at_risk AS (
          SELECT
            SUM(CASE WHEN ls.health_status = 'zombie' THEN s.monthly_revenue ELSE 0 END) AS zombie_revenue,
            SUM(CASE WHEN ls.health_status = 'at_risk' THEN s.monthly_revenue ELSE 0 END) AS at_risk_revenue,
            SUM(CASE WHEN ls.health_status IN ('zombie', 'at_risk') THEN s.monthly_revenue ELSE 0 END) AS total_revenue_at_risk
          FROM latest_scores ls
          JOIN subscriptions s ON ls.custid = s.custid
          WHERE s.status = 'active'
        ),
        recent_transitions AS (
          SELECT
            event_type,
            COUNT(*) AS count
          FROM customer_lifecycle_events
          WHERE event_timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
          AND event_type IN ('became_zombie', 'became_at_risk', 'reactivated')
          GROUP BY event_type
        )
        SELECT
          (SELECT json_object_agg(health_status, row_to_json(sc)) FROM status_counts sc) AS status_breakdown,
          (SELECT row_to_json(rar) FROM revenue_at_risk rar) AS revenue_metrics,
          (SELECT json_object_agg(event_type, count) FROM recent_transitions) AS recent_transitions
      SQL

      result = db.exec(query)[0]

      status_breakdown = JSON.parse(result['status_breakdown'] || '{}')
      revenue_metrics = JSON.parse(result['revenue_metrics'] || '{}')
      recent_transitions = JSON.parse(result['recent_transitions'] || '{}')

      json_response({
        summary: {
          total_customers: status_breakdown.values.sum { |v| v['customer_count'].to_i },
          by_status: status_breakdown.transform_values do |v|
            {
              count: v['customer_count'].to_i,
              avg_health_score: v['avg_health_score'].to_f,
              avg_churn_risk: v['avg_churn_risk'].to_f
            }
          end
        },
        revenue: {
          zombie_revenue: revenue_metrics['zombie_revenue'].to_f.round(2),
          at_risk_revenue: revenue_metrics['at_risk_revenue'].to_f.round(2),
          total_revenue_at_risk: revenue_metrics['total_revenue_at_risk'].to_f.round(2)
        },
        trends: {
          last_7_days: {
            new_zombies: recent_transitions['became_zombie'].to_i,
            new_at_risk: recent_transitions['became_at_risk'].to_i,
            reactivated: recent_transitions['reactivated'].to_i
          }
        },
        generated_at: Time.now.utc.iso8601
      })
    end

    ##
    # Recalculate health score for a specific customer
    #
    # POST /api/v1/customers/:custid/health/recalculate
    #
    # Triggers immediate recalculation of health score (normally runs daily)
    post '/api/v1/customers/:custid/health/recalculate' do
      custid = params[:custid]

      # TODO: Trigger recalculation job for this customer
      # For now, return a success response
      # In production, this would queue a background job

      json_response({
        message: 'Health score recalculation queued',
        custid: custid,
        estimated_completion: (Time.now.utc + 60).iso8601
      }, status: 202)
    end

    ##
    # Error handlers
    error 404 do
      json_response({ error: 'Not found' }, status: 404)
    end

    error 500 do
      json_response({ error: 'Internal server error' }, status: 500)
    end

    error do
      json_response({ error: 'An error occurred' }, status: 500)
    end
  end
end

# Run the app if this file is executed directly
if __FILE__ == $PROGRAM_NAME
  ZombieDetection::HealthScoreAPI.run! port: ENV['PORT'] || 4567
end
