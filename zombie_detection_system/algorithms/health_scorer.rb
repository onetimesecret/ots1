# frozen_string_literal: true

##
# Customer Health Scoring Algorithm
# ==================================
#
# Calculates customer health scores based on multiple engagement signals.
#
# Author: Claude
# Date: 2025-11-23
# Version: 1.0
#

require 'date'
require 'time'

module ZombieDetection
  ##
  # Customer health classification levels
  module HealthStatus
    HEALTHY = 'healthy'
    AT_RISK = 'at_risk'
    ZOMBIE = 'zombie'
    DEAD = 'dead'
  end

  ##
  # API usage trend classification
  module UsageTrend
    GROWING = 'growing'
    STABLE = 'stable'
    DECLINING = 'declining'
    NONE = 'none'
  end

  ##
  # Input metrics for health score calculation
  class CustomerMetrics
    attr_accessor :custid, :plan_type, :monthly_revenue
    attr_accessor :subscription_start_date, :account_age_days
    attr_accessor :login_days_30d, :days_since_last_login, :total_login_count
    attr_accessor :api_calls_30d, :api_calls_60d, :api_calls_90d
    attr_accessor :active_days_30d, :usage_trend
    attr_accessor :total_features_used, :total_available_features
    attr_accessor :features_used_30d, :features_used_90d
    attr_accessor :team_members_active, :unique_recipients, :collaboration_days_30d
    attr_accessor :secrets_created_30d, :secrets_created_60d, :secrets_created_90d
    attr_accessor :net_secret_change_30d, :current_active_secrets

    def initialize(attributes = {})
      @custid = attributes[:custid]
      @plan_type = attributes[:plan_type]
      @monthly_revenue = attributes[:monthly_revenue]
      @subscription_start_date = attributes[:subscription_start_date]
      @account_age_days = attributes[:account_age_days]
      @login_days_30d = attributes[:login_days_30d] || 0
      @days_since_last_login = attributes[:days_since_last_login]
      @total_login_count = attributes[:total_login_count] || 0
      @api_calls_30d = attributes[:api_calls_30d] || 0
      @api_calls_60d = attributes[:api_calls_60d] || 0
      @api_calls_90d = attributes[:api_calls_90d] || 0
      @active_days_30d = attributes[:active_days_30d] || 0
      @usage_trend = attributes[:usage_trend] || UsageTrend::NONE
      @total_features_used = attributes[:total_features_used] || 0
      @total_available_features = attributes[:total_available_features] || 10
      @features_used_30d = attributes[:features_used_30d] || 0
      @features_used_90d = attributes[:features_used_90d] || 0
      @team_members_active = attributes[:team_members_active] || 1
      @unique_recipients = attributes[:unique_recipients] || 0
      @collaboration_days_30d = attributes[:collaboration_days_30d] || 0
      @secrets_created_30d = attributes[:secrets_created_30d] || 0
      @secrets_created_60d = attributes[:secrets_created_60d] || 0
      @secrets_created_90d = attributes[:secrets_created_90d] || 0
      @net_secret_change_30d = attributes[:net_secret_change_30d] || 0
      @current_active_secrets = attributes[:current_active_secrets] || 0
    end
  end

  ##
  # Output health score with component breakdown
  class HealthScore
    attr_reader :custid, :overall_score, :health_status
    attr_reader :login_score, :api_usage_score, :feature_adoption_score
    attr_reader :collaboration_score, :data_activity_score
    attr_reader :churn_risk_score, :reactivation_potential
    attr_reader :zombie_signals, :zombie_signal_count, :days_as_zombie
    attr_reader :primary_risk_factors, :strengths, :calculated_at

    def initialize(attributes = {})
      @custid = attributes[:custid]
      @overall_score = attributes[:overall_score].round(2)
      @health_status = attributes[:health_status]
      @login_score = attributes[:login_score].round(2)
      @api_usage_score = attributes[:api_usage_score].round(2)
      @feature_adoption_score = attributes[:feature_adoption_score].round(2)
      @collaboration_score = attributes[:collaboration_score].round(2)
      @data_activity_score = attributes[:data_activity_score].round(2)
      @churn_risk_score = attributes[:churn_risk_score].round(2)
      @reactivation_potential = attributes[:reactivation_potential].round(2)
      @zombie_signals = attributes[:zombie_signals] || []
      @zombie_signal_count = attributes[:zombie_signal_count] || 0
      @days_as_zombie = attributes[:days_as_zombie]
      @primary_risk_factors = attributes[:primary_risk_factors] || []
      @strengths = attributes[:strengths] || []
      @calculated_at = attributes[:calculated_at] || Time.now.utc
    end

    def to_h
      {
        custid: @custid,
        overall_score: @overall_score,
        health_status: @health_status,
        login_score: @login_score,
        api_usage_score: @api_usage_score,
        feature_adoption_score: @feature_adoption_score,
        collaboration_score: @collaboration_score,
        data_activity_score: @data_activity_score,
        churn_risk_score: @churn_risk_score,
        reactivation_potential: @reactivation_potential,
        zombie_signals: @zombie_signals,
        zombie_signal_count: @zombie_signal_count,
        days_as_zombie: @days_as_zombie,
        primary_risk_factors: @primary_risk_factors,
        strengths: @strengths,
        calculated_at: @calculated_at
      }
    end
  end

  ##
  # Customer health scoring engine
  class HealthScorer
    # Component weights (must sum to 1.0)
    WEIGHT_LOGIN = 0.25
    WEIGHT_API_USAGE = 0.30
    WEIGHT_FEATURE_ADOPTION = 0.20
    WEIGHT_COLLABORATION = 0.15
    WEIGHT_DATA_ACTIVITY = 0.10

    # Classification thresholds
    THRESHOLD_HEALTHY = 70.0
    THRESHOLD_AT_RISK = 40.0
    THRESHOLD_ZOMBIE = 15.0

    # Decay parameters
    LOGIN_DECAY_HALFLIFE = 7 # days
    FEATURE_DECAY_WINDOW = 90 # days

    attr_reader :conservative_mode

    def initialize(conservative_mode: false)
      @conservative_mode = conservative_mode
      @threshold_at_risk = conservative_mode ? 60.0 : THRESHOLD_AT_RISK
      @threshold_zombie = conservative_mode ? 30.0 : THRESHOLD_ZOMBIE
    end

    ##
    # Calculate overall health score for a customer
    #
    # @param metrics [CustomerMetrics] Customer engagement metrics
    # @return [HealthScore] Health score with component breakdown
    def calculate_health_score(metrics)
      # Calculate component scores
      login_score = calculate_login_score(metrics)
      api_usage_score = calculate_api_usage_score(metrics)
      feature_score = calculate_feature_adoption_score(metrics)
      collab_score = calculate_collaboration_score(metrics)
      data_score = calculate_data_activity_score(metrics)

      # Calculate weighted overall score
      overall_score = (
        login_score * WEIGHT_LOGIN +
        api_usage_score * WEIGHT_API_USAGE +
        feature_score * WEIGHT_FEATURE_ADOPTION +
        collab_score * WEIGHT_COLLABORATION +
        data_score * WEIGHT_DATA_ACTIVITY
      )

      # Detect zombie signals
      zombie_signals, zombie_count = detect_zombie_signals(metrics)

      # Classify health status (with override rules)
      health_status = classify_health_status(overall_score, metrics, zombie_count)

      # Calculate risk metrics
      churn_risk = calculate_churn_risk(overall_score, zombie_count, metrics)
      reactivation_potential = calculate_reactivation_potential(metrics)

      # Generate explanations
      risk_factors = identify_risk_factors(metrics, zombie_signals)
      strengths = identify_strengths(metrics)

      HealthScore.new(
        custid: metrics.custid,
        overall_score: overall_score,
        health_status: health_status,
        login_score: login_score,
        api_usage_score: api_usage_score,
        feature_adoption_score: feature_score,
        collaboration_score: collab_score,
        data_activity_score: data_score,
        churn_risk_score: churn_risk,
        reactivation_potential: reactivation_potential,
        zombie_signals: zombie_signals,
        zombie_signal_count: zombie_count,
        primary_risk_factors: risk_factors,
        strengths: strengths
      )
    end

    private

    ##
    # Calculate login frequency score (0-100)
    def calculate_login_score(metrics)
      # Base score from login days
      base_score = [100.0, (metrics.login_days_30d.to_f / 20) * 100].min

      # Apply recency decay
      return 0.0 if metrics.days_since_last_login.nil?

      decay_factor = exponential_decay(metrics.days_since_last_login, LOGIN_DECAY_HALFLIFE)
      final_score = base_score * decay_factor

      [[0.0, final_score].max, 100.0].min
    end

    ##
    # Calculate API usage score (0-100)
    def calculate_api_usage_score(metrics)
      # Base score from API call volume
      base_score = [100.0, (metrics.api_calls_30d.to_f / 100) * 100].min

      # Trend adjustment
      trend_multipliers = {
        UsageTrend::GROWING => 1.1,
        UsageTrend::STABLE => 1.0,
        UsageTrend::DECLINING => 0.85,
        UsageTrend::NONE => 0.5
      }
      trend_multiplier = trend_multipliers[metrics.usage_trend] || 1.0

      # Engagement depth bonus
      engagement_bonus = case metrics.active_days_30d
                         when 15.. then 10
                         when 10.. then 5
                         else 0
                         end

      final_score = (base_score * trend_multiplier) + engagement_bonus
      [[0.0, final_score].max, 100.0].min
    end

    ##
    # Calculate feature adoption depth score (0-100)
    def calculate_feature_adoption_score(metrics)
      return 0.0 if metrics.total_available_features.zero?

      # Calculate adoption percentage
      adoption_pct = (metrics.total_features_used.to_f / metrics.total_available_features) * 100

      # Depth adjustment based on absolute feature count
      depth_multiplier = case metrics.total_features_used
                         when 7.. then 1.2  # Power user bonus
                         when 4.. then 1.0  # Healthy
                         when 2.. then 0.8  # Minimal
                         else 0.5           # Critical
                         end

      # Recency penalty for dormant features
      recency_penalty = if metrics.features_used_30d.zero?
                          0.5 # No recent feature usage
                        elsif metrics.total_features_used.positive? &&
                              metrics.features_used_30d < metrics.total_features_used * 0.3
                          0.75 # Some dormancy
                        else
                          1.0 # Active feature usage
                        end

      final_score = adoption_pct * depth_multiplier * recency_penalty
      [[0.0, final_score].max, 100.0].min
    end

    ##
    # Calculate collaboration/team usage score (0-100)
    def calculate_collaboration_score(metrics)
      # Team size component (50% of score)
      team_score = [50.0, (metrics.team_members_active.to_f / 5) * 50].min

      # Sharing component (50% of score)
      sharing_score = [50.0, (metrics.unique_recipients.to_f / 10) * 50].min

      # Recency adjustment
      recency_factor = case metrics.collaboration_days_30d
                       when 10.. then 1.0
                       when 5.. then 0.8
                       when 1.. then 0.5
                       else 0.2 # Inactive collaboration
                       end

      base_score = (team_score + sharing_score) * recency_factor

      # Special cases
      # Solo user with no sharing gets a baseline score (not penalized)
      base_score = [base_score, 20.0].max if metrics.team_members_active == 1 && metrics.unique_recipients.zero?

      # Team accounts get minimum score
      base_score = [base_score, 40.0].max if metrics.team_members_active >= 3

      # High collaboration gets minimum score
      base_score = [base_score, 50.0].max if metrics.unique_recipients >= 10

      [[0.0, base_score].max, 100.0].min
    end

    ##
    # Calculate data activity/storage growth score (0-100)
    def calculate_data_activity_score(metrics)
      # Creation rate (60% of score)
      creation_score = [60.0, (metrics.secrets_created_30d.to_f / 20) * 60].min

      # Growth rate (40% of score)
      growth_score = case metrics.net_secret_change_30d
                     when 10.. then 40.0
                     when 5.. then 30.0
                     when 0.. then 20.0
                     else 10.0 # Declining
                     end

      final_score = creation_score + growth_score
      [[0.0, final_score].max, 100.0].min
    end

    ##
    # Detect zombie confirmation signals
    #
    # @return [Array<Array, Integer>] Array of [signal descriptions, count]
    def detect_zombie_signals(metrics)
      signals = []

      signals << 'No login in 60+ days' if metrics.days_since_last_login && metrics.days_since_last_login > 60
      signals << 'Minimal API usage (< 5 calls/30d)' if metrics.api_calls_30d < 5
      signals << 'Minimal feature adoption (≤ 2 features)' if metrics.total_features_used <= 2
      signals << 'No data activity (0 secrets created)' if metrics.secrets_created_30d.zero?

      if metrics.unique_recipients.zero? && metrics.team_members_active == 1
        signals << 'No collaboration (solo user, no sharing)'
      end

      [signals, signals.length]
    end

    ##
    # Classify customer health status with override rules
    #
    # @param overall_score [Float] Calculated overall health score
    # @param metrics [CustomerMetrics] Customer metrics
    # @param zombie_signal_count [Integer] Number of zombie signals detected
    # @return [String] HealthStatus classification
    def classify_health_status(overall_score, metrics, zombie_signal_count)
      # Override Rule 1: Dead classification
      if metrics.account_age_days > 14 &&
         metrics.api_calls_90d.zero? &&
         (metrics.days_since_last_login.nil? || metrics.days_since_last_login > 90) &&
         metrics.total_features_used.zero?
        return HealthStatus::DEAD
      end

      # Override Rule 2: Zombie classification (3+ confirmation signals)
      return HealthStatus::ZOMBIE if zombie_signal_count >= 3

      # Override Rule 3: At-risk classification (2+ signals)
      at_risk_signals = 0
      at_risk_signals += 1 if metrics.days_since_last_login && metrics.days_since_last_login > 30
      at_risk_signals += 1 if metrics.api_calls_30d < 10
      at_risk_signals += 1 if metrics.usage_trend == UsageTrend::DECLINING

      return HealthStatus::AT_RISK if at_risk_signals >= 2 && overall_score < THRESHOLD_HEALTHY

      # Standard threshold-based classification
      return HealthStatus::HEALTHY if overall_score >= THRESHOLD_HEALTHY
      return HealthStatus::AT_RISK if overall_score >= @threshold_at_risk
      return HealthStatus::ZOMBIE if overall_score >= @threshold_zombie

      HealthStatus::DEAD
    end

    ##
    # Calculate churn risk score (0-100, higher = more risk)
    def calculate_churn_risk(overall_score, zombie_signal_count, metrics)
      # Base risk is inverse of health
      base_risk = 100 - overall_score

      # Amplify risk for zombie signals
      zombie_risk_boost = zombie_signal_count * 10 # 10 points per signal

      # Recent usage decline is a strong risk signal
      decline_boost = metrics.usage_trend == UsageTrend::DECLINING ? 15 : 0

      total_risk = base_risk + zombie_risk_boost + decline_boost
      [[0.0, total_risk].max, 100.0].min
    end

    ##
    # Calculate likelihood of successful reactivation (0-100)
    def calculate_reactivation_potential(metrics)
      potential = 50.0 # Base potential

      # Feature adoption indicates they understood product value
      potential += case metrics.total_features_used
                   when 4.. then 20
                   when 2.. then 10
                   else 0
                   end

      # Historical engagement indicates past value realization
      potential += case metrics.api_calls_90d
                   when 50.. then 15
                   when 20.. then 8
                   else 0
                   end

      # Collaboration indicates network effects
      potential += case metrics.unique_recipients
                   when 3.. then 10
                   when 1.. then 5
                   else 0
                   end

      # Recent activity (even if minimal) indicates salvageable relationship
      potential += 10 if metrics.api_calls_30d.positive?

      # Account age (more invested customers easier to win back)
      potential += 5 if metrics.account_age_days >= 180

      # Long dormancy reduces potential
      if metrics.days_since_last_login
        potential -= if metrics.days_since_last_login > 90
                       25
                     elsif metrics.days_since_last_login > 60
                       15
                     else
                       0
                     end
      end

      [[0.0, potential].max, 100.0].min
    end

    ##
    # Identify primary risk factors for the customer
    def identify_risk_factors(metrics, zombie_signals)
      factors = zombie_signals[0..2] # Top 3 signals

      # Add additional context
      factors << 'Usage declining month-over-month' if metrics.usage_trend == UsageTrend::DECLINING

      if metrics.features_used_30d.zero? && metrics.total_features_used.positive?
        factors << 'Previously used features now dormant'
      end

      if metrics.account_age_days < 30 && metrics.api_calls_30d < 10
        factors << 'Poor onboarding - low initial engagement'
      end

      factors[0..4] # Return top 5 risk factors
    end

    ##
    # Identify positive engagement signals
    def identify_strengths(metrics)
      strengths = []

      strengths << 'High login frequency (15+ days/month)' if metrics.login_days_30d >= 15
      strengths << 'Strong API usage (50+ calls/month)' if metrics.api_calls_30d >= 50

      if metrics.total_features_used >= 5
        strengths << "Good feature adoption (#{metrics.total_features_used} features used)"
      end

      if metrics.team_members_active >= 3
        strengths << "Team account (#{metrics.team_members_active} active members)"
      end

      if metrics.unique_recipients >= 5
        strengths << "High collaboration (#{metrics.unique_recipients} recipients)"
      end

      strengths << 'Growing usage trend' if metrics.usage_trend == UsageTrend::GROWING
      strengths << 'Strong data growth' if metrics.net_secret_change_30d >= 10

      strengths
    end

    ##
    # Calculate exponential decay factor
    #
    # @param days [Integer] Number of days since event
    # @param half_life [Integer] Half-life in days
    # @return [Float] Decay factor between 0 and 1
    def exponential_decay(days, half_life)
      1.0 / (1 + (days.to_f / half_life))
    end

    ##
    # Calculate linear decay factor
    #
    # @param days [Integer] Number of days since event
    # @param max_days [Integer] Days for full decay (0 weight)
    # @return [Float] Decay factor between 0 and 1
    def linear_decay(days, max_days)
      [[0.0, 1.0 - (days.to_f / max_days)].max, 1.0].min
    end
  end
end

# Example usage and test cases
if __FILE__ == $PROGRAM_NAME
  include ZombieDetection

  # Test Case 1: Healthy customer
  healthy_customer = CustomerMetrics.new(
    custid: 'cust_healthy_001',
    plan_type: 'standard',
    monthly_revenue: 35.00,
    subscription_start_date: Time.now - (180 * 24 * 60 * 60),
    account_age_days: 180,
    login_days_30d: 18,
    days_since_last_login: 1,
    total_login_count: 150,
    api_calls_30d: 145,
    api_calls_60d: 290,
    api_calls_90d: 420,
    active_days_30d: 22,
    usage_trend: UsageTrend::GROWING,
    total_features_used: 7,
    total_available_features: 10,
    features_used_30d: 6,
    features_used_90d: 7,
    team_members_active: 3,
    unique_recipients: 8,
    collaboration_days_30d: 15,
    secrets_created_30d: 42,
    secrets_created_60d: 85,
    secrets_created_90d: 125,
    net_secret_change_30d: 25,
    current_active_secrets: 87
  )

  # Test Case 2: Zombie customer
  zombie_customer = CustomerMetrics.new(
    custid: 'cust_zombie_001',
    plan_type: 'standard',
    monthly_revenue: 35.00,
    subscription_start_date: Time.now - (120 * 24 * 60 * 60),
    account_age_days: 120,
    login_days_30d: 0,
    days_since_last_login: 75,
    total_login_count: 8,
    api_calls_30d: 2,
    api_calls_60d: 5,
    api_calls_90d: 18,
    active_days_30d: 1,
    usage_trend: UsageTrend::DECLINING,
    total_features_used: 2,
    total_available_features: 10,
    features_used_30d: 0,
    features_used_90d: 1,
    team_members_active: 1,
    unique_recipients: 0,
    collaboration_days_30d: 0,
    secrets_created_30d: 0,
    secrets_created_60d: 2,
    secrets_created_90d: 8,
    net_secret_change_30d: 0,
    current_active_secrets: 3
  )

  # Calculate scores
  scorer = HealthScorer.new

  puts '=' * 80
  puts 'CUSTOMER HEALTH SCORING - TEST RESULTS (Ruby)'
  puts '=' * 80

  [healthy_customer, zombie_customer].each do |customer|
    score = scorer.calculate_health_score(customer)

    puts "\nCustomer: #{score.custid}"
    puts "Overall Score: #{score.overall_score} / 100"
    puts "Health Status: #{score.health_status.upcase}"
    puts "Churn Risk: #{score.churn_risk_score}%"
    puts "Reactivation Potential: #{score.reactivation_potential}%"
    puts "\nComponent Scores:"
    puts "  - Login Frequency:  #{score.login_score} / 100 (weight: 25%)"
    puts "  - API Usage:        #{score.api_usage_score} / 100 (weight: 30%)"
    puts "  - Feature Adoption: #{score.feature_adoption_score} / 100 (weight: 20%)"
    puts "  - Collaboration:    #{score.collaboration_score} / 100 (weight: 15%)"
    puts "  - Data Activity:    #{score.data_activity_score} / 100 (weight: 10%)"
    puts "\nZombie Signals (#{score.zombie_signal_count}):"
    score.zombie_signals.each { |signal| puts "  ⚠ #{signal}" }
    puts "\nRisk Factors:"
    score.primary_risk_factors.each { |factor| puts "  ⚠ #{factor}" }
    puts "\nStrengths:"
    score.strengths.each { |strength| puts "  ✓ #{strength}" }
    puts '-' * 80
  end
end
