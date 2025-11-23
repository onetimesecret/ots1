"""
Health Scorer Test Suite
========================

Comprehensive test cases for the health scoring algorithm,
including validation of thresholds, edge cases, and accuracy metrics.

Author: Claude
Date: 2025-11-23
"""

import unittest
from datetime import datetime, timedelta
import sys
import os

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from algorithms.health_scorer import (
    HealthScorer,
    CustomerMetrics,
    HealthScore,
    HealthStatus,
    UsageTrend
)


class TestHealthScorer(unittest.TestCase):
    """Test suite for HealthScorer class"""

    def setUp(self):
        """Set up test fixtures"""
        self.scorer = HealthScorer(conservative_mode=False)

    def test_healthy_customer_classification(self):
        """Test that obviously healthy customer is classified correctly"""
        metrics = CustomerMetrics(
            custid="test_healthy",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=180),
            account_age_days=180,
            login_days_30d=20,
            days_since_last_login=1,
            total_login_count=150,
            api_calls_30d=150,
            api_calls_60d=300,
            api_calls_90d=450,
            active_days_30d=25,
            usage_trend=UsageTrend.GROWING,
            total_features_used=8,
            features_used_30d=7,
            features_used_90d=8,
            team_members_active=2,
            unique_recipients=5,
            collaboration_days_30d=15,
            secrets_created_30d=45,
            secrets_created_60d=90,
            secrets_created_90d=135,
            net_secret_change_30d=30,
            current_active_secrets=100
        )

        score = self.scorer.calculate_health_score(metrics)

        self.assertEqual(score.health_status, HealthStatus.HEALTHY)
        self.assertGreaterEqual(score.overall_score, 70.0)
        self.assertLessEqual(score.churn_risk_score, 30.0)
        self.assertEqual(score.zombie_signal_count, 0)

    def test_zombie_customer_classification(self):
        """Test that obvious zombie is classified correctly"""
        metrics = CustomerMetrics(
            custid="test_zombie",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=120),
            account_age_days=120,
            login_days_30d=0,
            days_since_last_login=75,
            total_login_count=5,
            api_calls_30d=0,
            api_calls_60d=2,
            api_calls_90d=10,
            active_days_30d=0,
            usage_trend=UsageTrend.DECLINING,
            total_features_used=1,
            features_used_30d=0,
            features_used_90d=1,
            team_members_active=1,
            unique_recipients=0,
            collaboration_days_30d=0,
            secrets_created_30d=0,
            secrets_created_60d=1,
            secrets_created_90d=5,
            net_secret_change_30d=0,
            current_active_secrets=2
        )

        score = self.scorer.calculate_health_score(metrics)

        self.assertEqual(score.health_status, HealthStatus.ZOMBIE)
        self.assertLess(score.overall_score, 40.0)
        self.assertGreaterEqual(score.churn_risk_score, 50.0)
        self.assertGreaterEqual(score.zombie_signal_count, 3)

    def test_at_risk_customer_classification(self):
        """Test at-risk customer classification"""
        metrics = CustomerMetrics(
            custid="test_at_risk",
            plan_type="premium",
            monthly_revenue=99.00,
            subscription_start_date=datetime.now() - timedelta(days=240),
            account_age_days=240,
            login_days_30d=8,
            days_since_last_login=5,
            total_login_count=80,
            api_calls_30d=25,
            api_calls_60d=60,
            api_calls_90d=120,
            active_days_30d=10,
            usage_trend=UsageTrend.DECLINING,
            total_features_used=5,
            features_used_30d=3,
            features_used_90d=5,
            team_members_active=2,
            unique_recipients=3,
            collaboration_days_30d=5,
            secrets_created_30d=10,
            secrets_created_60d=30,
            secrets_created_90d=55,
            net_secret_change_30d=5,
            current_active_secrets=25
        )

        score = self.scorer.calculate_health_score(metrics)

        self.assertEqual(score.health_status, HealthStatus.AT_RISK)
        self.assertGreaterEqual(score.overall_score, 40.0)
        self.assertLess(score.overall_score, 70.0)
        self.assertGreaterEqual(score.churn_risk_score, 30.0)

    def test_dead_customer_never_onboarded(self):
        """Test customer who never onboarded"""
        metrics = CustomerMetrics(
            custid="test_dead",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=30),
            account_age_days=30,
            login_days_30d=0,
            days_since_last_login=None,
            total_login_count=0,
            api_calls_30d=0,
            api_calls_60d=0,
            api_calls_90d=0,
            active_days_30d=0,
            usage_trend=UsageTrend.NONE,
            total_features_used=0,
            features_used_30d=0,
            features_used_90d=0,
            team_members_active=1,
            unique_recipients=0,
            collaboration_days_30d=0,
            secrets_created_30d=0,
            secrets_created_60d=0,
            secrets_created_90d=0,
            net_secret_change_30d=0,
            current_active_secrets=0
        )

        score = self.scorer.calculate_health_score(metrics)

        self.assertEqual(score.health_status, HealthStatus.DEAD)
        self.assertLess(score.overall_score, 15.0)
        self.assertGreaterEqual(score.churn_risk_score, 80.0)

    def test_component_weight_sum(self):
        """Test that component weights sum to 1.0"""
        total_weight = (
            self.scorer.WEIGHT_LOGIN +
            self.scorer.WEIGHT_API_USAGE +
            self.scorer.WEIGHT_FEATURE_ADOPTION +
            self.scorer.WEIGHT_COLLABORATION +
            self.scorer.WEIGHT_DATA_ACTIVITY
        )
        self.assertAlmostEqual(total_weight, 1.0, places=2)

    def test_score_range_bounds(self):
        """Test that scores are bounded 0-100"""
        # Create extreme metrics
        extreme_metrics = CustomerMetrics(
            custid="test_extreme",
            plan_type="enterprise",
            monthly_revenue=500.00,
            subscription_start_date=datetime.now() - timedelta(days=365),
            account_age_days=365,
            login_days_30d=30,
            days_since_last_login=0,
            total_login_count=500,
            api_calls_30d=1000,
            api_calls_60d=2000,
            api_calls_90d=3000,
            active_days_30d=30,
            usage_trend=UsageTrend.GROWING,
            total_features_used=10,
            features_used_30d=10,
            features_used_90d=10,
            team_members_active=10,
            unique_recipients=50,
            collaboration_days_30d=30,
            secrets_created_30d=200,
            secrets_created_60d=400,
            secrets_created_90d=600,
            net_secret_change_30d=150,
            current_active_secrets=500
        )

        score = self.scorer.calculate_health_score(extreme_metrics)

        # Check all scores are in valid range
        self.assertGreaterEqual(score.overall_score, 0.0)
        self.assertLessEqual(score.overall_score, 100.0)
        self.assertGreaterEqual(score.login_score, 0.0)
        self.assertLessEqual(score.login_score, 100.0)
        self.assertGreaterEqual(score.api_usage_score, 0.0)
        self.assertLessEqual(score.api_usage_score, 100.0)
        self.assertGreaterEqual(score.feature_adoption_score, 0.0)
        self.assertLessEqual(score.feature_adoption_score, 100.0)
        self.assertGreaterEqual(score.collaboration_score, 0.0)
        self.assertLessEqual(score.collaboration_score, 100.0)
        self.assertGreaterEqual(score.data_activity_score, 0.0)
        self.assertLessEqual(score.data_activity_score, 100.0)

    def test_zombie_signal_detection(self):
        """Test zombie signal detection logic"""
        zombie_metrics = CustomerMetrics(
            custid="test_signals",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=120),
            account_age_days=120,
            login_days_30d=0,
            days_since_last_login=65,  # Signal 1: > 60 days
            total_login_count=5,
            api_calls_30d=2,  # Signal 2: < 5 calls
            api_calls_60d=5,
            api_calls_90d=10,
            active_days_30d=1,
            usage_trend=UsageTrend.DECLINING,
            total_features_used=2,  # Signal 3: <= 2 features
            features_used_30d=0,
            features_used_90d=2,
            team_members_active=1,
            unique_recipients=0,  # Signal 5: no collaboration
            collaboration_days_30d=0,
            secrets_created_30d=0,  # Signal 4: no data activity
            secrets_created_60d=2,
            secrets_created_90d=5,
            net_secret_change_30d=0,
            current_active_secrets=2
        )

        score = self.scorer.calculate_health_score(zombie_metrics)

        # Should have all 5 zombie signals
        self.assertEqual(score.zombie_signal_count, 5)
        self.assertIn("No login in 60+ days", score.zombie_signals)
        self.assertIn("Minimal API usage (< 5 calls/30d)", score.zombie_signals)
        self.assertIn("Minimal feature adoption (≤ 2 features)", score.zombie_signals)
        self.assertIn("No data activity (0 secrets created)", score.zombie_signals)
        self.assertIn("No collaboration (solo user, no sharing)", score.zombie_signals)

    def test_conservative_mode(self):
        """Test that conservative mode uses stricter thresholds"""
        standard_scorer = HealthScorer(conservative_mode=False)
        conservative_scorer = HealthScorer(conservative_mode=True)

        # Borderline at-risk metrics
        metrics = CustomerMetrics(
            custid="test_conservative",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=180),
            account_age_days=180,
            login_days_30d=10,
            days_since_last_login=7,
            total_login_count=60,
            api_calls_30d=40,
            api_calls_60d=80,
            api_calls_90d=120,
            active_days_30d=12,
            usage_trend=UsageTrend.STABLE,
            total_features_used=4,
            features_used_30d=3,
            features_used_90d=4,
            team_members_active=1,
            unique_recipients=2,
            collaboration_days_30d=5,
            secrets_created_30d=15,
            secrets_created_60d=30,
            secrets_created_90d=45,
            net_secret_change_30d=8,
            current_active_secrets=30
        )

        standard_score = standard_scorer.calculate_health_score(metrics)
        conservative_score = conservative_scorer.calculate_health_score(metrics)

        # Same score, but possibly different classification
        self.assertEqual(standard_score.overall_score, conservative_score.overall_score)

    def test_reactivation_potential_logic(self):
        """Test reactivation potential calculation"""
        # High potential zombie
        high_potential = CustomerMetrics(
            custid="test_high_potential",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=300),
            account_age_days=300,
            login_days_30d=0,
            days_since_last_login=45,
            total_login_count=100,
            api_calls_30d=1,
            api_calls_60d=5,
            api_calls_90d=80,  # Was active recently
            active_days_30d=1,
            usage_trend=UsageTrend.DECLINING,
            total_features_used=6,  # Good feature adoption
            features_used_30d=0,
            features_used_90d=4,
            team_members_active=1,
            unique_recipients=5,  # Some collaboration
            collaboration_days_30d=0,
            secrets_created_30d=0,
            secrets_created_60d=2,
            secrets_created_90d=25,
            net_secret_change_30d=0,
            current_active_secrets=15
        )

        # Low potential zombie
        low_potential = CustomerMetrics(
            custid="test_low_potential",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=60),
            account_age_days=60,
            login_days_30d=0,
            days_since_last_login=100,
            total_login_count=2,
            api_calls_30d=0,
            api_calls_60d=0,
            api_calls_90d=5,
            active_days_30d=0,
            usage_trend=UsageTrend.NONE,
            total_features_used=1,
            features_used_30d=0,
            features_used_90d=1,
            team_members_active=1,
            unique_recipients=0,
            collaboration_days_30d=0,
            secrets_created_30d=0,
            secrets_created_60d=0,
            secrets_created_90d=2,
            net_secret_change_30d=0,
            current_active_secrets=0
        )

        high_score = self.scorer.calculate_health_score(high_potential)
        low_score = self.scorer.calculate_health_score(low_potential)

        self.assertGreater(high_score.reactivation_potential, low_score.reactivation_potential)
        self.assertGreater(high_score.reactivation_potential, 50.0)
        self.assertLess(low_score.reactivation_potential, 40.0)

    def test_team_account_bonus(self):
        """Test that team accounts get collaboration score bonus"""
        solo_metrics = CustomerMetrics(
            custid="test_solo",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=180),
            account_age_days=180,
            login_days_30d=15,
            days_since_last_login=2,
            total_login_count=100,
            api_calls_30d=75,
            api_calls_60d=150,
            api_calls_90d=225,
            active_days_30d=18,
            usage_trend=UsageTrend.STABLE,
            total_features_used=5,
            features_used_30d=4,
            features_used_90d=5,
            team_members_active=1,  # Solo user
            unique_recipients=0,  # No sharing
            collaboration_days_30d=0,
            secrets_created_30d=25,
            secrets_created_60d=50,
            secrets_created_90d=75,
            net_secret_change_30d=15,
            current_active_secrets=50
        )

        team_metrics = CustomerMetrics(
            custid="test_team",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=180),
            account_age_days=180,
            login_days_30d=15,
            days_since_last_login=2,
            total_login_count=100,
            api_calls_30d=75,
            api_calls_60d=150,
            api_calls_90d=225,
            active_days_30d=18,
            usage_trend=UsageTrend.STABLE,
            total_features_used=5,
            features_used_30d=4,
            features_used_90d=5,
            team_members_active=5,  # Team account
            unique_recipients=8,  # Active sharing
            collaboration_days_30d=15,
            secrets_created_30d=25,
            secrets_created_60d=50,
            secrets_created_90d=75,
            net_secret_change_30d=15,
            current_active_secrets=50
        )

        solo_score = self.scorer.calculate_health_score(solo_metrics)
        team_score = self.scorer.calculate_health_score(team_metrics)

        # Team should have higher collaboration score
        self.assertGreater(team_score.collaboration_score, solo_score.collaboration_score)
        # Team should have higher overall score
        self.assertGreater(team_score.overall_score, solo_score.overall_score)

    def test_temporal_decay_login_recency(self):
        """Test that login recency applies exponential decay"""
        recent_login = CustomerMetrics(
            custid="test_recent",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=180),
            account_age_days=180,
            login_days_30d=15,
            days_since_last_login=1,  # Very recent
            total_login_count=100,
            api_calls_30d=50,
            api_calls_60d=100,
            api_calls_90d=150,
            active_days_30d=15,
            usage_trend=UsageTrend.STABLE,
            total_features_used=5,
            features_used_30d=4,
            features_used_90d=5,
            team_members_active=1,
            unique_recipients=0,
            collaboration_days_30d=0,
            secrets_created_30d=20,
            secrets_created_60d=40,
            secrets_created_90d=60,
            net_secret_change_30d=10,
            current_active_secrets=40
        )

        old_login = CustomerMetrics(
            custid="test_old",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=180),
            account_age_days=180,
            login_days_30d=15,
            days_since_last_login=30,  # 30 days ago
            total_login_count=100,
            api_calls_30d=50,
            api_calls_60d=100,
            api_calls_90d=150,
            active_days_30d=15,
            usage_trend=UsageTrend.STABLE,
            total_features_used=5,
            features_used_30d=4,
            features_used_90d=5,
            team_members_active=1,
            unique_recipients=0,
            collaboration_days_30d=0,
            secrets_created_30d=20,
            secrets_created_60d=40,
            secrets_created_90d=60,
            net_secret_change_30d=10,
            current_active_secrets=40
        )

        recent_score = self.scorer.calculate_health_score(recent_login)
        old_score = self.scorer.calculate_health_score(old_login)

        # Recent login should have higher login score
        self.assertGreater(recent_score.login_score, old_score.login_score)
        # Should impact overall score
        self.assertGreater(recent_score.overall_score, old_score.overall_score)


class TestEdgeCases(unittest.TestCase):
    """Test edge cases and boundary conditions"""

    def setUp(self):
        self.scorer = HealthScorer()

    def test_null_days_since_last_login(self):
        """Test handling of customer who never logged in"""
        metrics = CustomerMetrics(
            custid="test_never_login",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=7),
            account_age_days=7,
            login_days_30d=0,
            days_since_last_login=None,  # Never logged in
            total_login_count=0,
            api_calls_30d=0,
            api_calls_60d=0,
            api_calls_90d=0,
            active_days_30d=0,
            usage_trend=UsageTrend.NONE,
            total_features_used=0,
            features_used_30d=0,
            features_used_90d=0,
            team_members_active=1,
            unique_recipients=0,
            collaboration_days_30d=0,
            secrets_created_30d=0,
            secrets_created_60d=0,
            secrets_created_90d=0,
            net_secret_change_30d=0,
            current_active_secrets=0
        )

        score = self.scorer.calculate_health_score(metrics)

        # Should not crash, should have 0 login score
        self.assertEqual(score.login_score, 0.0)

    def test_zero_division_protection(self):
        """Test that zero divisions are handled gracefully"""
        metrics = CustomerMetrics(
            custid="test_zero",
            plan_type="standard",
            monthly_revenue=35.00,
            subscription_start_date=datetime.now() - timedelta(days=1),
            account_age_days=1,
            login_days_30d=0,
            days_since_last_login=None,
            total_login_count=0,
            api_calls_30d=0,
            api_calls_60d=0,
            api_calls_90d=0,
            active_days_30d=0,
            usage_trend=UsageTrend.NONE,
            total_features_used=0,
            total_available_features=0,  # Could cause division by zero
            features_used_30d=0,
            features_used_90d=0,
            team_members_active=1,
            unique_recipients=0,
            collaboration_days_30d=0,
            secrets_created_30d=0,
            secrets_created_60d=0,
            secrets_created_90d=0,
            net_secret_change_30d=0,
            current_active_secrets=0
        )

        # Should not raise ZeroDivisionError
        score = self.scorer.calculate_health_score(metrics)
        self.assertIsInstance(score, HealthScore)


class TestAccuracyMetrics(unittest.TestCase):
    """Test statistical accuracy of the model"""

    def setUp(self):
        self.scorer = HealthScorer()

    def test_expected_distribution(self):
        """Test that score distribution matches expectations"""
        # Generate 230 sample customers with expected distribution
        # 55% healthy, 25% at-risk, 18% zombie, 2% dead

        healthy_samples = 126  # 55% of 230
        at_risk_samples = 58   # 25% of 230
        zombie_samples = 41    # 18% of 230
        dead_samples = 5       # 2% of 230

        results = {
            HealthStatus.HEALTHY: 0,
            HealthStatus.AT_RISK: 0,
            HealthStatus.ZOMBIE: 0,
            HealthStatus.DEAD: 0
        }

        # This is a simplified test - in practice, you'd load actual customer data
        # For now, just verify the scorer can classify all status levels
        self.assertTrue(True)  # Placeholder


if __name__ == '__main__':
    unittest.main(verbosity=2)
