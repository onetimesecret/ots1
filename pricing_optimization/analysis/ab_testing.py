"""
A/B Testing Framework for Price Optimization
Statistical analysis, power calculations, and experiment design.
"""

import numpy as np
from scipy import stats
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass
from enum import Enum
import math


class TestStatus(Enum):
    """A/B test status."""
    DRAFT = "draft"
    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class SignificanceResult(Enum):
    """Statistical significance result."""
    SIGNIFICANT_POSITIVE = "significant_positive"  # Treatment significantly better
    SIGNIFICANT_NEGATIVE = "significant_negative"  # Control significantly better
    NOT_SIGNIFICANT = "not_significant"  # No significant difference
    INSUFFICIENT_DATA = "insufficient_data"  # Not enough data


@dataclass
class PowerAnalysisResult:
    """Statistical power analysis results."""
    required_sample_size_per_variant: int
    statistical_power: float
    minimum_detectable_effect: float
    significance_level: float
    expected_duration_days: int

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            'required_sample_size_per_variant': self.required_sample_size_per_variant,
            'statistical_power': round(self.statistical_power, 4),
            'minimum_detectable_effect': round(self.minimum_detectable_effect, 4),
            'significance_level': round(self.significance_level, 4),
            'expected_duration_days': self.expected_duration_days
        }


@dataclass
class ConfidenceInterval:
    """Confidence interval for a metric."""
    lower_bound: float
    upper_bound: float
    confidence_level: float
    point_estimate: float

    def contains_zero(self) -> bool:
        """Check if interval contains zero (indicating no difference)."""
        return self.lower_bound <= 0 <= self.upper_bound

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            'lower_bound': round(self.lower_bound, 4),
            'upper_bound': round(self.upper_bound, 4),
            'confidence_level': round(self.confidence_level, 2),
            'point_estimate': round(self.point_estimate, 4)
        }


@dataclass
class ABTestResults:
    """Complete A/B test analysis results."""
    # Sample sizes
    control_n: int
    treatment_n: int

    # Conversion rates
    control_conversion_rate: float
    treatment_conversion_rate: float

    # Revenue metrics
    control_revenue_per_user: float
    treatment_revenue_per_user: float
    control_total_revenue: float
    treatment_total_revenue: float

    # Statistical tests
    p_value: float
    significance_result: SignificanceResult
    confidence_interval: ConfidenceInterval

    # Effect sizes
    absolute_lift: float
    relative_lift_percentage: float

    # Recommendations
    recommendation: str
    confidence_score: float  # 0-1, how confident we are in the result

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            'control_n': self.control_n,
            'treatment_n': self.treatment_n,
            'control_conversion_rate': round(self.control_conversion_rate, 4),
            'treatment_conversion_rate': round(self.treatment_conversion_rate, 4),
            'control_revenue_per_user': round(self.control_revenue_per_user, 2),
            'treatment_revenue_per_user': round(self.treatment_revenue_per_user, 2),
            'control_total_revenue': round(self.control_total_revenue, 2),
            'treatment_total_revenue': round(self.treatment_total_revenue, 2),
            'p_value': round(self.p_value, 6),
            'significance_result': self.significance_result.value,
            'confidence_interval': self.confidence_interval.to_dict(),
            'absolute_lift': round(self.absolute_lift, 4),
            'relative_lift_percentage': round(self.relative_lift_percentage, 2),
            'recommendation': self.recommendation,
            'confidence_score': round(self.confidence_score, 4)
        }


class StatisticalPowerCalculator:
    """
    Calculate required sample sizes and statistical power for A/B tests.

    Uses standard formulas for two-proportion z-test.
    """

    def __init__(self):
        """Initialize calculator."""
        pass

    def calculate_sample_size(self,
                            baseline_conversion_rate: float,
                            minimum_detectable_effect: float,
                            statistical_power: float = 0.80,
                            significance_level: float = 0.05) -> int:
        """
        Calculate required sample size per variant.

        Args:
            baseline_conversion_rate: Expected control conversion rate
            minimum_detectable_effect: Minimum relative change to detect (e.g., 0.05 for 5%)
            statistical_power: Desired statistical power (1 - beta)
            significance_level: Significance level (alpha), typically 0.05

        Returns:
            Required sample size per variant
        """
        # Calculate effect size
        p1 = baseline_conversion_rate
        p2 = baseline_conversion_rate * (1 + minimum_detectable_effect)

        # Pooled probability
        p_pooled = (p1 + p2) / 2

        # Z-scores for alpha and beta
        z_alpha = stats.norm.ppf(1 - significance_level / 2)  # Two-tailed
        z_beta = stats.norm.ppf(statistical_power)

        # Sample size formula
        numerator = (z_alpha * math.sqrt(2 * p_pooled * (1 - p_pooled)) +
                    z_beta * math.sqrt(p1 * (1 - p1) + p2 * (1 - p2))) ** 2
        denominator = (p2 - p1) ** 2

        n = math.ceil(numerator / denominator)

        return max(n, 100)  # Minimum 100 per variant

    def calculate_power(self,
                       baseline_conversion_rate: float,
                       expected_effect: float,
                       sample_size: int,
                       significance_level: float = 0.05) -> float:
        """
        Calculate statistical power given sample size.

        Args:
            baseline_conversion_rate: Control conversion rate
            expected_effect: Expected relative change
            sample_size: Sample size per variant
            significance_level: Significance level (alpha)

        Returns:
            Statistical power (probability of detecting effect if it exists)
        """
        p1 = baseline_conversion_rate
        p2 = baseline_conversion_rate * (1 + expected_effect)

        # Pooled probability
        p_pooled = (p1 + p2) / 2

        # Effect size
        effect_size = abs(p2 - p1) / math.sqrt(p_pooled * (1 - p_pooled))

        # Z-score for alpha
        z_alpha = stats.norm.ppf(1 - significance_level / 2)

        # Calculate power
        z_beta = effect_size * math.sqrt(sample_size / 2) - z_alpha
        power = stats.norm.cdf(z_beta)

        return max(0.0, min(1.0, power))

    def design_experiment(self,
                         baseline_conversion_rate: float,
                         minimum_detectable_effect: float,
                         daily_traffic: int,
                         allocation_ratio: float = 0.5,
                         statistical_power: float = 0.80,
                         significance_level: float = 0.05) -> PowerAnalysisResult:
        """
        Design complete experiment with timeline.

        Args:
            baseline_conversion_rate: Expected control conversion rate
            minimum_detectable_effect: Minimum relative change to detect
            daily_traffic: Daily eligible users
            allocation_ratio: Fraction allocated to each variant (0.5 = 50/50 split)
            statistical_power: Desired power
            significance_level: Significance level

        Returns:
            PowerAnalysisResult with experiment parameters
        """
        # Calculate required sample size
        n_per_variant = self.calculate_sample_size(
            baseline_conversion_rate,
            minimum_detectable_effect,
            statistical_power,
            significance_level
        )

        # Calculate duration
        daily_users_per_variant = daily_traffic * allocation_ratio
        duration_days = math.ceil(n_per_variant / daily_users_per_variant)

        return PowerAnalysisResult(
            required_sample_size_per_variant=n_per_variant,
            statistical_power=statistical_power,
            minimum_detectable_effect=minimum_detectable_effect,
            significance_level=significance_level,
            expected_duration_days=duration_days
        )


class ABTestAnalyzer:
    """
    Analyze A/B test results with statistical rigor.

    Implements:
    - Two-proportion z-test
    - Confidence intervals
    - Sequential testing
    - Revenue analysis
    """

    def __init__(self, significance_level: float = 0.05):
        """
        Initialize analyzer.

        Args:
            significance_level: Significance level for hypothesis tests
        """
        self.significance_level = significance_level

    def analyze_test(self,
                    control_conversions: int,
                    control_total: int,
                    treatment_conversions: int,
                    treatment_total: int,
                    control_revenue: float,
                    treatment_revenue: float) -> ABTestResults:
        """
        Perform complete A/B test analysis.

        Args:
            control_conversions: Number of conversions in control
            control_total: Total users in control
            treatment_conversions: Number of conversions in treatment
            treatment_total: Total users in treatment
            control_revenue: Total revenue from control
            treatment_revenue: Total revenue from treatment

        Returns:
            ABTestResults with complete analysis
        """
        # Calculate conversion rates
        control_rate = control_conversions / control_total if control_total > 0 else 0
        treatment_rate = treatment_conversions / treatment_total if treatment_total > 0 else 0

        # Calculate revenue per user
        control_rpu = control_revenue / control_total if control_total > 0 else 0
        treatment_rpu = treatment_revenue / treatment_total if treatment_total > 0 else 0

        # Two-proportion z-test
        p_value, significance_result = self._two_proportion_test(
            control_conversions, control_total,
            treatment_conversions, treatment_total
        )

        # Confidence interval for difference
        ci = self._confidence_interval_difference(
            control_rate, control_total,
            treatment_rate, treatment_total
        )

        # Effect sizes
        absolute_lift = treatment_rate - control_rate
        relative_lift = (absolute_lift / control_rate * 100) if control_rate > 0 else 0

        # Generate recommendation
        recommendation, confidence = self._generate_recommendation(
            significance_result,
            relative_lift,
            control_total,
            treatment_total,
            p_value
        )

        return ABTestResults(
            control_n=control_total,
            treatment_n=treatment_total,
            control_conversion_rate=control_rate,
            treatment_conversion_rate=treatment_rate,
            control_revenue_per_user=control_rpu,
            treatment_revenue_per_user=treatment_rpu,
            control_total_revenue=control_revenue,
            treatment_total_revenue=treatment_revenue,
            p_value=p_value,
            significance_result=significance_result,
            confidence_interval=ci,
            absolute_lift=absolute_lift,
            relative_lift_percentage=relative_lift,
            recommendation=recommendation,
            confidence_score=confidence
        )

    def _two_proportion_test(self,
                            control_conversions: int,
                            control_total: int,
                            treatment_conversions: int,
                            treatment_total: int) -> Tuple[float, SignificanceResult]:
        """
        Perform two-proportion z-test.

        Args:
            control_conversions: Conversions in control
            control_total: Total in control
            treatment_conversions: Conversions in treatment
            treatment_total: Total in treatment

        Returns:
            (p_value, significance_result)
        """
        # Check for sufficient data
        if control_total < 30 or treatment_total < 30:
            return 1.0, SignificanceResult.INSUFFICIENT_DATA

        p1 = control_conversions / control_total
        p2 = treatment_conversions / treatment_total

        # Pooled proportion
        p_pooled = (control_conversions + treatment_conversions) / (control_total + treatment_total)

        # Standard error
        se = math.sqrt(p_pooled * (1 - p_pooled) * (1/control_total + 1/treatment_total))

        # Avoid division by zero
        if se == 0:
            return 1.0, SignificanceResult.NOT_SIGNIFICANT

        # Z-statistic
        z = (p2 - p1) / se

        # P-value (two-tailed)
        p_value = 2 * (1 - stats.norm.cdf(abs(z)))

        # Determine significance
        if p_value < self.significance_level:
            if p2 > p1:
                result = SignificanceResult.SIGNIFICANT_POSITIVE
            else:
                result = SignificanceResult.SIGNIFICANT_NEGATIVE
        else:
            result = SignificanceResult.NOT_SIGNIFICANT

        return p_value, result

    def _confidence_interval_difference(self,
                                       p1: float,
                                       n1: int,
                                       p2: float,
                                       n2: int,
                                       confidence_level: float = 0.95) -> ConfidenceInterval:
        """
        Calculate confidence interval for difference in proportions.

        Args:
            p1: Control proportion
            n1: Control sample size
            p2: Treatment proportion
            n2: Treatment sample size
            confidence_level: Confidence level

        Returns:
            ConfidenceInterval for (p2 - p1)
        """
        # Difference
        diff = p2 - p1

        # Standard error of difference
        se = math.sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)

        # Z-score for confidence level
        z = stats.norm.ppf((1 + confidence_level) / 2)

        # Margin of error
        margin = z * se

        return ConfidenceInterval(
            lower_bound=diff - margin,
            upper_bound=diff + margin,
            confidence_level=confidence_level,
            point_estimate=diff
        )

    def _generate_recommendation(self,
                                significance_result: SignificanceResult,
                                relative_lift: float,
                                control_n: int,
                                treatment_n: int,
                                p_value: float) -> Tuple[str, float]:
        """
        Generate actionable recommendation.

        Args:
            significance_result: Statistical significance
            relative_lift: Relative lift percentage
            control_n: Control sample size
            treatment_n: Treatment sample size
            p_value: P-value from test

        Returns:
            (recommendation_text, confidence_score)
        """
        total_n = control_n + treatment_n

        if significance_result == SignificanceResult.INSUFFICIENT_DATA:
            return (
                f"Insufficient data. Continue test until reaching at least 100 users per variant. "
                f"Current: {control_n} control, {treatment_n} treatment.",
                0.0
            )

        if significance_result == SignificanceResult.SIGNIFICANT_POSITIVE:
            confidence = 1 - p_value

            if relative_lift > 10:
                impact = "strong positive"
            elif relative_lift > 5:
                impact = "moderate positive"
            else:
                impact = "small positive"

            return (
                f"IMPLEMENT TREATMENT: Statistically significant {impact} impact "
                f"({relative_lift:+.1f}% lift). "
                f"Based on {total_n} total observations with p={p_value:.4f}.",
                confidence
            )

        if significance_result == SignificanceResult.SIGNIFICANT_NEGATIVE:
            confidence = 1 - p_value
            return (
                f"KEEP CONTROL: Treatment performed significantly worse "
                f"({relative_lift:+.1f}% change). "
                f"Based on {total_n} total observations with p={p_value:.4f}.",
                confidence
            )

        # Not significant
        if total_n < 1000:
            return (
                f"CONTINUE TEST: No significant difference detected yet "
                f"(observed {relative_lift:+.1f}% change, p={p_value:.4f}). "
                f"Recommend collecting more data. Current sample: {total_n} users.",
                0.5
            )
        else:
            return (
                f"NO CLEAR WINNER: After {total_n} observations, no significant difference "
                f"detected (p={p_value:.4f}). Consider implementing based on other factors "
                f"or declaring test inconclusive.",
                0.3
            )


class SequentialTestingAnalyzer:
    """
    Sequential testing with early stopping for A/B tests.

    Implements methods to check if test can be stopped early with confidence.
    """

    def __init__(self, significance_level: float = 0.05):
        """Initialize sequential analyzer."""
        self.significance_level = significance_level

    def can_stop_early(self,
                      control_conversions: int,
                      control_total: int,
                      treatment_conversions: int,
                      treatment_total: int,
                      minimum_sample_size: int = 100) -> Tuple[bool, str]:
        """
        Check if test can be stopped early.

        Args:
            control_conversions: Control conversions
            control_total: Control total
            treatment_conversions: Treatment conversions
            treatment_total: Treatment total
            minimum_sample_size: Minimum required sample before early stopping

        Returns:
            (can_stop, reason)
        """
        # Don't stop before minimum sample
        if control_total < minimum_sample_size or treatment_total < minimum_sample_size:
            return False, f"Need minimum {minimum_sample_size} samples per variant"

        # Perform standard test
        analyzer = ABTestAnalyzer(self.significance_level)
        results = analyzer.analyze_test(
            control_conversions, control_total,
            treatment_conversions, treatment_total,
            0, 0  # Revenue not needed for early stopping
        )

        # Can stop if significant and strong effect
        if results.significance_result == SignificanceResult.SIGNIFICANT_POSITIVE:
            if abs(results.relative_lift_percentage) > 10:
                return True, f"Strong significant effect detected: {results.relative_lift_percentage:+.1f}%"

        if results.significance_result == SignificanceResult.SIGNIFICANT_NEGATIVE:
            if abs(results.relative_lift_percentage) > 10:
                return True, f"Strong negative effect detected: {results.relative_lift_percentage:+.1f}%"

        return False, "Continue testing"


# Example usage
if __name__ == "__main__":
    print("=== A/B Testing Framework ===\n")

    # 1. Power analysis and experiment design
    print("1. Experiment Design & Power Analysis")
    power_calc = StatisticalPowerCalculator()

    experiment_design = power_calc.design_experiment(
        baseline_conversion_rate=0.10,
        minimum_detectable_effect=0.10,  # 10% relative change
        daily_traffic=500,
        allocation_ratio=0.5,
        statistical_power=0.80,
        significance_level=0.05
    )

    print(f"Required sample size per variant: {experiment_design.required_sample_size_per_variant}")
    print(f"Statistical power: {experiment_design.statistical_power}")
    print(f"Minimum detectable effect: {experiment_design.minimum_detectable_effect:.1%}")
    print(f"Significance level: {experiment_design.significance_level}")
    print(f"Expected test duration: {experiment_design.expected_duration_days} days")

    # 2. Analyze running test
    print("\n2. Test Analysis (Professional Tier Price Test)")

    analyzer = ABTestAnalyzer(significance_level=0.05)

    # Simulated test data
    control_conversions = 180
    control_total = 1500
    treatment_conversions = 150
    treatment_total = 1500
    control_revenue = 180 * 299.0
    treatment_revenue = 150 * 349.0

    results = analyzer.analyze_test(
        control_conversions, control_total,
        treatment_conversions, treatment_total,
        control_revenue, treatment_revenue
    )

    print(f"\nControl Group:")
    print(f"  Sample size: {results.control_n}")
    print(f"  Conversion rate: {results.control_conversion_rate:.2%}")
    print(f"  Revenue per user: ${results.control_revenue_per_user:.2f}")
    print(f"  Total revenue: ${results.control_total_revenue:.2f}")

    print(f"\nTreatment Group:")
    print(f"  Sample size: {results.treatment_n}")
    print(f"  Conversion rate: {results.treatment_conversion_rate:.2%}")
    print(f"  Revenue per user: ${results.treatment_revenue_per_user:.2f}")
    print(f"  Total revenue: ${results.treatment_total_revenue:.2f}")

    print(f"\nStatistical Analysis:")
    print(f"  P-value: {results.p_value:.6f}")
    print(f"  Significance: {results.significance_result.value}")
    print(f"  Absolute lift: {results.absolute_lift:+.4f}")
    print(f"  Relative lift: {results.relative_lift_percentage:+.2f}%")
    print(f"  95% CI: [{results.confidence_interval.lower_bound:.4f}, {results.confidence_interval.upper_bound:.4f}]")

    print(f"\nRecommendation:")
    print(f"  {results.recommendation}")
    print(f"  Confidence: {results.confidence_score:.2%}")

    # 3. Sequential testing
    print("\n3. Sequential Testing (Early Stopping Check)")
    sequential = SequentialTestingAnalyzer()

    can_stop, reason = sequential.can_stop_early(
        control_conversions, control_total,
        treatment_conversions, treatment_total,
        minimum_sample_size=100
    )

    print(f"Can stop early: {can_stop}")
    print(f"Reason: {reason}")
