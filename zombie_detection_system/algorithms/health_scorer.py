"""
Customer Health Scoring Algorithm
==================================

Calculates customer health scores based on multiple engagement signals.

Author: Claude
Date: 2025-11-23
Version: 1.0
"""

import math
from dataclasses import dataclass
from datetime import datetime, timedelta
from enum import Enum
from typing import Optional, Dict, List, Tuple


class HealthStatus(Enum):
    """Customer health classification levels"""
    HEALTHY = "healthy"
    AT_RISK = "at_risk"
    ZOMBIE = "zombie"
    DEAD = "dead"


class UsageTrend(Enum):
    """API usage trend classification"""
    GROWING = "growing"
    STABLE = "stable"
    DECLINING = "declining"
    NONE = "none"


@dataclass
class CustomerMetrics:
    """Input metrics for health score calculation"""

    # Identifiers
    custid: str
    plan_type: str
    monthly_revenue: float

    # Subscription info
    subscription_start_date: datetime
    account_age_days: int

    # Login signals
    login_days_30d: int  # Number of days with login in last 30 days
    days_since_last_login: Optional[int]  # None if never logged in
    total_login_count: int

    # API usage signals
    api_calls_30d: int
    api_calls_60d: int
    api_calls_90d: int
    active_days_30d: int  # Days with API activity
    usage_trend: UsageTrend

    # Feature adoption signals
    total_features_used: int
    total_available_features: int = 10  # Default platform features
    features_used_30d: int
    features_used_90d: int

    # Collaboration signals
    team_members_active: int = 1
    unique_recipients: int = 0
    collaboration_days_30d: int = 0

    # Data activity signals
    secrets_created_30d: int
    secrets_created_60d: int
    secrets_created_90d: int
    net_secret_change_30d: int  # Created - burned
    current_active_secrets: int


@dataclass
class HealthScore:
    """Output health score with component breakdown"""

    custid: str
    overall_score: float  # 0-100
    health_status: HealthStatus

    # Component scores (0-100 each)
    login_score: float
    api_usage_score: float
    feature_adoption_score: float
    collaboration_score: float
    data_activity_score: float

    # Risk metrics
    churn_risk_score: float  # 0-100, higher = more risk
    reactivation_potential: float  # 0-100, higher = easier to reactivate

    # Zombie detection signals
    zombie_signals: List[str]
    zombie_signal_count: int
    days_as_zombie: Optional[int] = None

    # Explanation
    primary_risk_factors: List[str]
    strengths: List[str]

    calculated_at: datetime = None

    def __post_init__(self):
        if self.calculated_at is None:
            self.calculated_at = datetime.utcnow()


class HealthScorer:
    """Customer health scoring engine"""

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
    LOGIN_DECAY_HALFLIFE = 7  # days
    FEATURE_DECAY_WINDOW = 90  # days

    def __init__(self, conservative_mode: bool = False):
        """
        Initialize health scorer.

        Args:
            conservative_mode: If True, use stricter thresholds to reduce false positives
        """
        self.conservative_mode = conservative_mode
        if conservative_mode:
            self.THRESHOLD_AT_RISK = 60.0
            self.THRESHOLD_ZOMBIE = 30.0

    def calculate_health_score(self, metrics: CustomerMetrics) -> HealthScore:
        """
        Calculate overall health score for a customer.

        Args:
            metrics: Customer engagement metrics

        Returns:
            HealthScore object with overall score and component breakdown
        """
        # Calculate component scores
        login_score = self._calculate_login_score(metrics)
        api_usage_score = self._calculate_api_usage_score(metrics)
        feature_score = self._calculate_feature_adoption_score(metrics)
        collab_score = self._calculate_collaboration_score(metrics)
        data_score = self._calculate_data_activity_score(metrics)

        # Calculate weighted overall score
        overall_score = (
            login_score * self.WEIGHT_LOGIN +
            api_usage_score * self.WEIGHT_API_USAGE +
            feature_score * self.WEIGHT_FEATURE_ADOPTION +
            collab_score * self.WEIGHT_COLLABORATION +
            data_score * self.WEIGHT_DATA_ACTIVITY
        )

        # Detect zombie signals
        zombie_signals, zombie_count = self._detect_zombie_signals(metrics)

        # Classify health status (with override rules)
        health_status = self._classify_health_status(
            overall_score, metrics, zombie_count
        )

        # Calculate risk metrics
        churn_risk = self._calculate_churn_risk(overall_score, zombie_count, metrics)
        reactivation_potential = self._calculate_reactivation_potential(metrics)

        # Generate explanations
        risk_factors = self._identify_risk_factors(metrics, zombie_signals)
        strengths = self._identify_strengths(metrics)

        return HealthScore(
            custid=metrics.custid,
            overall_score=round(overall_score, 2),
            health_status=health_status,
            login_score=round(login_score, 2),
            api_usage_score=round(api_usage_score, 2),
            feature_adoption_score=round(feature_score, 2),
            collaboration_score=round(collab_score, 2),
            data_activity_score=round(data_score, 2),
            churn_risk_score=round(churn_risk, 2),
            reactivation_potential=round(reactivation_potential, 2),
            zombie_signals=zombie_signals,
            zombie_signal_count=zombie_count,
            primary_risk_factors=risk_factors,
            strengths=strengths
        )

    def _calculate_login_score(self, metrics: CustomerMetrics) -> float:
        """Calculate login frequency score (0-100)"""
        # Base score from login days
        base_score = min(100.0, (metrics.login_days_30d / 20) * 100)

        # Apply recency decay
        if metrics.days_since_last_login is None:
            # Never logged in
            return 0.0

        decay_factor = self._exponential_decay(
            metrics.days_since_last_login,
            half_life=self.LOGIN_DECAY_HALFLIFE
        )

        final_score = base_score * decay_factor
        return max(0.0, min(100.0, final_score))

    def _calculate_api_usage_score(self, metrics: CustomerMetrics) -> float:
        """Calculate API usage score (0-100)"""
        # Base score from API call volume
        base_score = min(100.0, (metrics.api_calls_30d / 100) * 100)

        # Trend adjustment
        trend_multipliers = {
            UsageTrend.GROWING: 1.1,
            UsageTrend.STABLE: 1.0,
            UsageTrend.DECLINING: 0.85,
            UsageTrend.NONE: 0.5
        }
        trend_multiplier = trend_multipliers.get(metrics.usage_trend, 1.0)

        # Engagement depth bonus
        engagement_bonus = 0
        if metrics.active_days_30d >= 15:
            engagement_bonus = 10
        elif metrics.active_days_30d >= 10:
            engagement_bonus = 5

        final_score = (base_score * trend_multiplier) + engagement_bonus
        return max(0.0, min(100.0, final_score))

    def _calculate_feature_adoption_score(self, metrics: CustomerMetrics) -> float:
        """Calculate feature adoption depth score (0-100)"""
        # Calculate adoption percentage
        if metrics.total_available_features == 0:
            return 0.0

        adoption_pct = (metrics.total_features_used / metrics.total_available_features) * 100

        # Depth adjustment based on absolute feature count
        if metrics.total_features_used >= 7:
            depth_multiplier = 1.2  # Power user bonus
        elif metrics.total_features_used >= 4:
            depth_multiplier = 1.0  # Healthy
        elif metrics.total_features_used >= 2:
            depth_multiplier = 0.8  # Minimal
        else:
            depth_multiplier = 0.5  # Critical

        # Recency penalty for dormant features
        if metrics.features_used_30d == 0:
            recency_penalty = 0.5  # No recent feature usage
        elif metrics.total_features_used > 0 and metrics.features_used_30d < metrics.total_features_used * 0.3:
            recency_penalty = 0.75  # Some dormancy
        else:
            recency_penalty = 1.0  # Active feature usage

        final_score = adoption_pct * depth_multiplier * recency_penalty
        return max(0.0, min(100.0, final_score))

    def _calculate_collaboration_score(self, metrics: CustomerMetrics) -> float:
        """Calculate collaboration/team usage score (0-100)"""
        # Team size component (50% of score)
        team_score = min(50.0, (metrics.team_members_active / 5) * 50)

        # Sharing component (50% of score)
        sharing_score = min(50.0, (metrics.unique_recipients / 10) * 50)

        # Recency adjustment
        if metrics.collaboration_days_30d >= 10:
            recency_factor = 1.0
        elif metrics.collaboration_days_30d >= 5:
            recency_factor = 0.8
        elif metrics.collaboration_days_30d >= 1:
            recency_factor = 0.5
        else:
            recency_factor = 0.2  # Inactive collaboration

        base_score = (team_score + sharing_score) * recency_factor

        # Special cases
        # Solo user with no sharing gets a baseline score (not penalized)
        if metrics.team_members_active == 1 and metrics.unique_recipients == 0:
            base_score = max(base_score, 20.0)

        # Team accounts get minimum score
        if metrics.team_members_active >= 3:
            base_score = max(base_score, 40.0)

        # High collaboration gets minimum score
        if metrics.unique_recipients >= 10:
            base_score = max(base_score, 50.0)

        return max(0.0, min(100.0, base_score))

    def _calculate_data_activity_score(self, metrics: CustomerMetrics) -> float:
        """Calculate data activity/storage growth score (0-100)"""
        # Creation rate (60% of score)
        creation_score = min(60.0, (metrics.secrets_created_30d / 20) * 60)

        # Growth rate (40% of score)
        if metrics.net_secret_change_30d >= 10:
            growth_score = 40.0
        elif metrics.net_secret_change_30d >= 5:
            growth_score = 30.0
        elif metrics.net_secret_change_30d >= 0:
            growth_score = 20.0
        else:
            growth_score = 10.0  # Declining

        final_score = creation_score + growth_score
        return max(0.0, min(100.0, final_score))

    def _detect_zombie_signals(self, metrics: CustomerMetrics) -> Tuple[List[str], int]:
        """
        Detect zombie confirmation signals.

        Returns:
            Tuple of (list of signal descriptions, count of signals)
        """
        signals = []

        if metrics.days_since_last_login is not None and metrics.days_since_last_login > 60:
            signals.append("No login in 60+ days")

        if metrics.api_calls_30d < 5:
            signals.append("Minimal API usage (< 5 calls/30d)")

        if metrics.total_features_used <= 2:
            signals.append("Minimal feature adoption (≤ 2 features)")

        if metrics.secrets_created_30d == 0:
            signals.append("No data activity (0 secrets created)")

        if metrics.unique_recipients == 0 and metrics.team_members_active == 1:
            signals.append("No collaboration (solo user, no sharing)")

        return signals, len(signals)

    def _classify_health_status(
        self,
        overall_score: float,
        metrics: CustomerMetrics,
        zombie_signal_count: int
    ) -> HealthStatus:
        """
        Classify customer health status with override rules.

        Args:
            overall_score: Calculated overall health score
            metrics: Customer metrics
            zombie_signal_count: Number of zombie signals detected

        Returns:
            HealthStatus classification
        """
        # Override Rule 1: Dead classification
        if (
            metrics.account_age_days > 14 and
            metrics.api_calls_90d == 0 and
            (metrics.days_since_last_login is None or metrics.days_since_last_login > 90) and
            metrics.total_features_used == 0
        ):
            return HealthStatus.DEAD

        # Override Rule 2: Zombie classification (3+ confirmation signals)
        if zombie_signal_count >= 3:
            return HealthStatus.ZOMBIE

        # Override Rule 3: At-risk classification (2+ signals)
        at_risk_signals = 0
        if metrics.days_since_last_login is not None and metrics.days_since_last_login > 30:
            at_risk_signals += 1
        if metrics.api_calls_30d < 10:
            at_risk_signals += 1
        if metrics.usage_trend == UsageTrend.DECLINING:
            at_risk_signals += 1

        if at_risk_signals >= 2 and overall_score < self.THRESHOLD_HEALTHY:
            return HealthStatus.AT_RISK

        # Standard threshold-based classification
        if overall_score >= self.THRESHOLD_HEALTHY:
            return HealthStatus.HEALTHY
        elif overall_score >= self.THRESHOLD_AT_RISK:
            return HealthStatus.AT_RISK
        elif overall_score >= self.THRESHOLD_ZOMBIE:
            return HealthStatus.ZOMBIE
        else:
            return HealthStatus.DEAD

    def _calculate_churn_risk(
        self,
        overall_score: float,
        zombie_signal_count: int,
        metrics: CustomerMetrics
    ) -> float:
        """
        Calculate churn risk score (0-100, higher = more risk).

        Inverse of health score with adjustments for zombie signals.
        """
        # Base risk is inverse of health
        base_risk = 100 - overall_score

        # Amplify risk for zombie signals
        zombie_risk_boost = zombie_signal_count * 10  # 10 points per signal

        # Recent usage decline is a strong risk signal
        if metrics.usage_trend == UsageTrend.DECLINING:
            decline_boost = 15
        else:
            decline_boost = 0

        total_risk = base_risk + zombie_risk_boost + decline_boost
        return max(0.0, min(100.0, total_risk))

    def _calculate_reactivation_potential(self, metrics: CustomerMetrics) -> float:
        """
        Calculate likelihood of successful reactivation (0-100).

        Higher scores indicate easier reactivation.
        """
        potential = 50.0  # Base potential

        # Feature adoption indicates they understood product value
        if metrics.total_features_used >= 4:
            potential += 20
        elif metrics.total_features_used >= 2:
            potential += 10

        # Historical engagement indicates past value realization
        if metrics.api_calls_90d >= 50:
            potential += 15
        elif metrics.api_calls_90d >= 20:
            potential += 8

        # Collaboration indicates network effects
        if metrics.unique_recipients >= 3:
            potential += 10
        elif metrics.unique_recipients >= 1:
            potential += 5

        # Recent activity (even if minimal) indicates salvageable relationship
        if metrics.api_calls_30d > 0:
            potential += 10

        # Account age (more invested customers easier to win back)
        if metrics.account_age_days >= 180:
            potential += 5

        # Long dormancy reduces potential
        if metrics.days_since_last_login is not None:
            if metrics.days_since_last_login > 90:
                potential -= 25
            elif metrics.days_since_last_login > 60:
                potential -= 15

        return max(0.0, min(100.0, potential))

    def _identify_risk_factors(
        self,
        metrics: CustomerMetrics,
        zombie_signals: List[str]
    ) -> List[str]:
        """Identify primary risk factors for the customer"""
        factors = []

        # Use zombie signals as starting point
        factors.extend(zombie_signals[:3])  # Top 3 signals

        # Add additional context
        if metrics.usage_trend == UsageTrend.DECLINING:
            factors.append("Usage declining month-over-month")

        if metrics.features_used_30d == 0 and metrics.total_features_used > 0:
            factors.append("Previously used features now dormant")

        if metrics.account_age_days < 30 and metrics.api_calls_30d < 10:
            factors.append("Poor onboarding - low initial engagement")

        return factors[:5]  # Return top 5 risk factors

    def _identify_strengths(self, metrics: CustomerMetrics) -> List[str]:
        """Identify positive engagement signals"""
        strengths = []

        if metrics.login_days_30d >= 15:
            strengths.append("High login frequency (15+ days/month)")

        if metrics.api_calls_30d >= 50:
            strengths.append("Strong API usage (50+ calls/month)")

        if metrics.total_features_used >= 5:
            strengths.append(f"Good feature adoption ({metrics.total_features_used} features used)")

        if metrics.team_members_active >= 3:
            strengths.append(f"Team account ({metrics.team_members_active} active members)")

        if metrics.unique_recipients >= 5:
            strengths.append(f"High collaboration ({metrics.unique_recipients} recipients)")

        if metrics.usage_trend == UsageTrend.GROWING:
            strengths.append("Growing usage trend")

        if metrics.net_secret_change_30d >= 10:
            strengths.append("Strong data growth")

        return strengths

    @staticmethod
    def _exponential_decay(days: int, half_life: int) -> float:
        """
        Calculate exponential decay factor.

        Args:
            days: Number of days since event
            half_life: Half-life in days

        Returns:
            Decay factor between 0 and 1
        """
        return 1.0 / (1 + (days / half_life))

    @staticmethod
    def _linear_decay(days: int, max_days: int) -> float:
        """
        Calculate linear decay factor.

        Args:
            days: Number of days since event
            max_days: Days for full decay (0 weight)

        Returns:
            Decay factor between 0 and 1
        """
        return max(0.0, 1.0 - (days / max_days))


# Example usage and test cases
if __name__ == "__main__":
    # Test Case 1: Healthy customer
    healthy_customer = CustomerMetrics(
        custid="cust_healthy_001",
        plan_type="standard",
        monthly_revenue=35.00,
        subscription_start_date=datetime.now() - timedelta(days=180),
        account_age_days=180,
        login_days_30d=18,
        days_since_last_login=1,
        total_login_count=150,
        api_calls_30d=145,
        api_calls_60d=290,
        api_calls_90d=420,
        active_days_30d=22,
        usage_trend=UsageTrend.GROWING,
        total_features_used=7,
        total_available_features=10,
        features_used_30d=6,
        features_used_90d=7,
        team_members_active=3,
        unique_recipients=8,
        collaboration_days_30d=15,
        secrets_created_30d=42,
        secrets_created_60d=85,
        secrets_created_90d=125,
        net_secret_change_30d=25,
        current_active_secrets=87
    )

    # Test Case 2: Zombie customer
    zombie_customer = CustomerMetrics(
        custid="cust_zombie_001",
        plan_type="standard",
        monthly_revenue=35.00,
        subscription_start_date=datetime.now() - timedelta(days=120),
        account_age_days=120,
        login_days_30d=0,
        days_since_last_login=75,
        total_login_count=8,
        api_calls_30d=2,
        api_calls_60d=5,
        api_calls_90d=18,
        active_days_30d=1,
        usage_trend=UsageTrend.DECLINING,
        total_features_used=2,
        total_available_features=10,
        features_used_30d=0,
        features_used_90d=1,
        team_members_active=1,
        unique_recipients=0,
        collaboration_days_30d=0,
        secrets_created_30d=0,
        secrets_created_60d=2,
        secrets_created_90d=8,
        net_secret_change_30d=0,
        current_active_secrets=3
    )

    # Test Case 3: At-risk customer
    at_risk_customer = CustomerMetrics(
        custid="cust_atrisk_001",
        plan_type="premium",
        monthly_revenue=99.00,
        subscription_start_date=datetime.now() - timedelta(days=240),
        account_age_days=240,
        login_days_30d=8,
        days_since_last_login=5,
        total_login_count=95,
        api_calls_30d=28,
        api_calls_60d=75,
        api_calls_90d=145,
        active_days_30d=12,
        usage_trend=UsageTrend.DECLINING,
        total_features_used=5,
        total_available_features=10,
        features_used_30d=3,
        features_used_90d=5,
        team_members_active=2,
        unique_recipients=4,
        collaboration_days_30d=6,
        secrets_created_30d=12,
        secrets_created_60d=35,
        secrets_created_90d=68,
        net_secret_change_30d=5,
        current_active_secrets=42
    )

    # Calculate scores
    scorer = HealthScorer()

    print("=" * 80)
    print("CUSTOMER HEALTH SCORING - TEST RESULTS")
    print("=" * 80)

    for customer in [healthy_customer, at_risk_customer, zombie_customer]:
        score = scorer.calculate_health_score(customer)

        print(f"\nCustomer: {score.custid}")
        print(f"Overall Score: {score.overall_score:.2f} / 100")
        print(f"Health Status: {score.health_status.value.upper()}")
        print(f"Churn Risk: {score.churn_risk_score:.2f}%")
        print(f"Reactivation Potential: {score.reactivation_potential:.2f}%")
        print(f"\nComponent Scores:")
        print(f"  - Login Frequency:  {score.login_score:.2f} / 100 (weight: 25%)")
        print(f"  - API Usage:        {score.api_usage_score:.2f} / 100 (weight: 30%)")
        print(f"  - Feature Adoption: {score.feature_adoption_score:.2f} / 100 (weight: 20%)")
        print(f"  - Collaboration:    {score.collaboration_score:.2f} / 100 (weight: 15%)")
        print(f"  - Data Activity:    {score.data_activity_score:.2f} / 100 (weight: 10%)")
        print(f"\nZombie Signals ({score.zombie_signal_count}):")
        for signal in score.zombie_signals:
            print(f"  ⚠ {signal}")
        print(f"\nRisk Factors:")
        for factor in score.primary_risk_factors:
            print(f"  ⚠ {factor}")
        print(f"\nStrengths:")
        for strength in score.strengths:
            print(f"  ✓ {strength}")
        print("-" * 80)
