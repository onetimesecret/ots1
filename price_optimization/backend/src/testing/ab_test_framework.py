"""
A/B Testing Framework with Statistical Power Calculations
For price optimization experiments
Python 3.9+ compatible
"""

import numpy as np
from scipy import stats
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum
import hashlib


class TestStatus(Enum):
    """A/B test statuses"""
    DRAFT = "draft"
    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


@dataclass
class ABTestConfig:
    """Configuration for A/B test"""

    control_price: int  # Control group price (cents)
    variant_prices: List[int]  # Variant group prices (cents)

    # Statistical parameters
    statistical_power: float = 0.80  # 80% power
    significance_level: float = 0.05  # 5% significance (95% confidence)
    minimum_detectable_effect: float = 0.10  # 10% MDE

    # Baseline metrics (for sample size calculation)
    baseline_conversion_rate: float = 0.30
    baseline_revenue_per_visitor: float = 300  # cents

    # Traffic allocation
    traffic_split: Optional[List[float]] = None  # Equal split if None

    # Safety settings
    max_revenue_loss: int = 100000  # Max acceptable loss (cents)
    auto_stop: bool = True  # Auto-stop if variant significantly worse

    def __post_init__(self):
        """Validate and set defaults"""
        if not 0.5 <= self.statistical_power <= 0.99:
            raise ValueError("Statistical power must be between 0.5 and 0.99")

        if not 0.001 <= self.significance_level <= 0.20:
            raise ValueError("Significance level must be between 0.001 and 0.20")

        # Set equal traffic split if not specified
        if self.traffic_split is None:
            n_groups = 1 + len(self.variant_prices)
            self.traffic_split = [1.0 / n_groups] * n_groups


class SampleSizeCalculator:
    """
    Sample size calculator for A/B tests

    Uses exact formulas for:
    1. Proportion tests (conversion rate)
    2. Mean tests (revenue per visitor)
    """

    @staticmethod
    def for_conversion_rate(
        baseline_rate: float,
        minimum_detectable_effect: float,
        statistical_power: float = 0.80,
        significance_level: float = 0.05,
        two_tailed: bool = True
    ) -> int:
        """
        Calculate required sample size per group for conversion rate test

        Formula:
        n = (Z_α/2 + Z_β)² × [p₁(1-p₁) + p₂(1-p₂)] / (p₁ - p₂)²

        Args:
            baseline_rate: Baseline conversion rate (0-1)
            minimum_detectable_effect: Minimum effect size (relative, e.g., 0.10 = 10%)
            statistical_power: Power (1 - β)
            significance_level: α level
            two_tailed: Two-tailed test (default: True)

        Returns:
            Required sample size per group
        """

        # Z-scores
        if two_tailed:
            z_alpha = stats.norm.ppf(1 - significance_level / 2)
        else:
            z_alpha = stats.norm.ppf(1 - significance_level)

        z_beta = stats.norm.ppf(statistical_power)

        # Effect size
        p1 = baseline_rate
        p2 = baseline_rate * (1 + minimum_detectable_effect)
        p2 = min(p2, 0.99)  # Cap at 99%

        # Pooled variance
        p_pooled = (p1 + p2) / 2
        variance = 2 * p_pooled * (1 - p_pooled)

        # Sample size formula
        n = ((z_alpha + z_beta) ** 2 * variance) / ((p2 - p1) ** 2)

        return int(np.ceil(n))

    @staticmethod
    def for_revenue(
        baseline_mean: float,
        baseline_std: float,
        minimum_detectable_effect: float,
        statistical_power: float = 0.80,
        significance_level: float = 0.05,
        two_tailed: bool = True
    ) -> int:
        """
        Calculate required sample size for revenue/continuous metric test

        Formula:
        n = 2 × (Z_α/2 + Z_β)² × σ² / δ²

        Args:
            baseline_mean: Baseline mean revenue
            baseline_std: Standard deviation of revenue
            minimum_detectable_effect: Minimum effect (relative)
            statistical_power: Power (1 - β)
            significance_level: α level
            two_tailed: Two-tailed test

        Returns:
            Required sample size per group
        """

        # Z-scores
        if two_tailed:
            z_alpha = stats.norm.ppf(1 - significance_level / 2)
        else:
            z_alpha = stats.norm.ppf(1 - significance_level)

        z_beta = stats.norm.ppf(statistical_power)

        # Effect size in absolute terms
        delta = baseline_mean * minimum_detectable_effect

        # Sample size formula
        n = 2 * ((z_alpha + z_beta) ** 2) * (baseline_std ** 2) / (delta ** 2)

        return int(np.ceil(n))


class ABTestAssigner:
    """
    Consistent A/B test group assignment using deterministic hashing
    """

    def __init__(self, experiment_id: str, traffic_split: List[float]):
        """
        Initialize assigner

        Args:
            experiment_id: Unique experiment identifier
            traffic_split: List of traffic percentages (must sum to 1.0)
        """
        self.experiment_id = experiment_id
        self.traffic_split = traffic_split

        if not np.isclose(sum(traffic_split), 1.0):
            raise ValueError("Traffic split must sum to 1.0")

    def assign_group(self, user_id: str) -> Tuple[str, int]:
        """
        Assign user to test group consistently

        Uses deterministic hashing to ensure:
        1. Same user always gets same group
        2. Uniform distribution across groups
        3. No bias in assignment

        Args:
            user_id: Unique user identifier

        Returns:
            Tuple of (group_name, group_index)
        """

        # Create deterministic hash
        hash_input = f"{self.experiment_id}:{user_id}".encode('utf-8')
        hash_value = int(hashlib.sha256(hash_input).hexdigest(), 16)

        # Convert to uniform [0, 1)
        uniform_value = (hash_value % 10000) / 10000.0

        # Assign to group based on cumulative traffic split
        cumulative = 0
        for i, split in enumerate(self.traffic_split):
            cumulative += split
            if uniform_value < cumulative:
                group_name = "control" if i == 0 else f"variant_{i}"
                return group_name, i

        # Fallback (should never reach here)
        return "control", 0


class ABTestAnalyzer:
    """
    Statistical analysis for A/B test results
    """

    @staticmethod
    def analyze_conversion_rate(
        control_conversions: int,
        control_total: int,
        variant_conversions: int,
        variant_total: int,
        significance_level: float = 0.05
    ) -> Dict:
        """
        Analyze conversion rate test using Z-test for proportions

        Returns:
            Dict with test results, p-value, confidence intervals, etc.
        """

        # Conversion rates
        p_control = control_conversions / control_total if control_total > 0 else 0
        p_variant = variant_conversions / variant_total if variant_total > 0 else 0

        # Pooled proportion (under null hypothesis)
        p_pooled = (control_conversions + variant_conversions) / (control_total + variant_total)

        # Standard error
        se_pooled = np.sqrt(p_pooled * (1 - p_pooled) * (1/control_total + 1/variant_total))

        # Z-statistic
        z_stat = (p_variant - p_control) / se_pooled if se_pooled > 0 else 0

        # P-value (two-tailed)
        p_value = 2 * (1 - stats.norm.cdf(abs(z_stat)))

        # Confidence interval for difference
        se_diff = np.sqrt(
            p_control * (1 - p_control) / control_total +
            p_variant * (1 - p_variant) / variant_total
        )

        z_critical = stats.norm.ppf(1 - significance_level / 2)
        ci_lower = (p_variant - p_control) - z_critical * se_diff
        ci_upper = (p_variant - p_control) + z_critical * se_diff

        # Relative lift
        relative_lift = (p_variant - p_control) / p_control if p_control > 0 else 0

        # Is significant?
        is_significant = p_value < significance_level

        return {
            "control_rate": p_control,
            "variant_rate": p_variant,
            "absolute_lift": p_variant - p_control,
            "relative_lift": relative_lift,
            "z_statistic": z_stat,
            "p_value": p_value,
            "is_significant": is_significant,
            "confidence_interval": (ci_lower, ci_upper),
            "sample_sizes": {"control": control_total, "variant": variant_total}
        }

    @staticmethod
    def analyze_revenue(
        control_revenues: np.ndarray,
        variant_revenues: np.ndarray,
        significance_level: float = 0.05
    ) -> Dict:
        """
        Analyze revenue using Welch's t-test (unequal variances)

        Returns:
            Dict with test results
        """

        # Descriptive statistics
        mean_control = np.mean(control_revenues)
        mean_variant = np.mean(variant_revenues)
        std_control = np.std(control_revenues, ddof=1)
        std_variant = np.std(variant_revenues, ddof=1)

        # Welch's t-test
        t_stat, p_value = stats.ttest_ind(
            variant_revenues,
            control_revenues,
            equal_var=False  # Welch's t-test
        )

        # Confidence interval for difference
        n_control = len(control_revenues)
        n_variant = len(variant_revenues)

        se_diff = np.sqrt(std_control**2 / n_control + std_variant**2 / n_variant)

        # Degrees of freedom (Welch-Satterthwaite)
        df = (std_control**2/n_control + std_variant**2/n_variant)**2 / (
            (std_control**2/n_control)**2/(n_control-1) +
            (std_variant**2/n_variant)**2/(n_variant-1)
        )

        t_critical = stats.t.ppf(1 - significance_level / 2, df)
        ci_lower = (mean_variant - mean_control) - t_critical * se_diff
        ci_upper = (mean_variant - mean_control) + t_critical * se_diff

        # Relative lift
        relative_lift = (mean_variant - mean_control) / mean_control if mean_control > 0 else 0

        # Is significant?
        is_significant = p_value < significance_level

        return {
            "control_mean": mean_control,
            "variant_mean": mean_variant,
            "control_std": std_control,
            "variant_std": std_variant,
            "absolute_lift": mean_variant - mean_control,
            "relative_lift": relative_lift,
            "t_statistic": t_stat,
            "p_value": p_value,
            "degrees_of_freedom": df,
            "is_significant": is_significant,
            "confidence_interval": (ci_lower, ci_upper),
            "sample_sizes": {"control": n_control, "variant": n_variant}
        }


# =============================================================================
# Example Usage
# =============================================================================

if __name__ == "__main__":
    """
    Example A/B test configuration and analysis
    """

    print("=" * 80)
    print("A/B TESTING FRAMEWORK - SAMPLE SIZE CALCULATION")
    print("=" * 80)

    # Calculate required sample size
    config = ABTestConfig(
        control_price=900,
        variant_prices=[700, 1100],
        baseline_conversion_rate=0.30,
        minimum_detectable_effect=0.15,
        statistical_power=0.80,
        significance_level=0.05
    )

    calc = SampleSizeCalculator()

    # For conversion rate
    n_conversion = calc.for_conversion_rate(
        baseline_rate=config.baseline_conversion_rate,
        minimum_detectable_effect=config.minimum_detectable_effect,
        statistical_power=config.statistical_power,
        significance_level=config.significance_level
    )

    print(f"\nRequired sample size per group (conversion rate test):")
    print(f"  Per group: {n_conversion:,}")
    print(f"  Total (3 groups): {n_conversion * 3:,}")

    # For revenue
    n_revenue = calc.for_revenue(
        baseline_mean=config.baseline_revenue_per_visitor,
        baseline_std=config.baseline_revenue_per_visitor * 0.5,  # Assume 50% CV
        minimum_detectable_effect=config.minimum_detectable_effect,
        statistical_power=config.statistical_power,
        significance_level=config.significance_level
    )

    print(f"\nRequired sample size per group (revenue test):")
    print(f"  Per group: {n_revenue:,}")
    print(f"  Total (3 groups): {n_revenue * 3:,}")

    print("\n" + "=" * 80)
    print("SIMULATED TEST RESULTS ANALYSIS")
    print("=" * 80)

    # Simulate test data
    np.random.seed(42)

    # Control: 30% conversion
    control_total = 5000
    control_conversions = np.random.binomial(control_total, 0.30)

    # Variant: 35% conversion (significant improvement)
    variant_total = 5000
    variant_conversions = np.random.binomial(variant_total, 0.35)

    # Analyze
    analyzer = ABTestAnalyzer()
    results = analyzer.analyze_conversion_rate(
        control_conversions=control_conversions,
        control_total=control_total,
        variant_conversions=variant_conversions,
        variant_total=variant_total
    )

    print(f"\nConversion Rate Analysis:")
    print(f"  Control: {results['control_rate']:.2%}")
    print(f"  Variant: {results['variant_rate']:.2%}")
    print(f"  Absolute Lift: {results['absolute_lift']:.2%}")
    print(f"  Relative Lift: {results['relative_lift']:.2%}")
    print(f"  P-value: {results['p_value']:.6f}")
    print(f"  Significant: {results['is_significant']}")
    print(f"  95% CI: [{results['confidence_interval'][0]:.2%}, {results['confidence_interval'][1]:.2%}]")

    print("\n" + "=" * 80)
