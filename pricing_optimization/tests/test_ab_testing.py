"""
Unit tests for A/B Testing Framework
"""

import unittest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from analysis.ab_testing import (
    StatisticalPowerCalculator,
    ABTestAnalyzer,
    SequentialTestingAnalyzer,
    SignificanceResult
)


class TestStatisticalPowerCalculator(unittest.TestCase):
    """Test statistical power calculations."""

    def setUp(self):
        """Set up power calculator."""
        self.calculator = StatisticalPowerCalculator()

    def test_sample_size_calculation(self):
        """Test sample size calculation."""
        n = self.calculator.calculate_sample_size(
            baseline_conversion_rate=0.10,
            minimum_detectable_effect=0.10,  # 10% relative change
            statistical_power=0.80,
            significance_level=0.05
        )

        self.assertGreater(n, 100)
        self.assertIsInstance(n, int)

    def test_higher_power_needs_more_samples(self):
        """Test that higher power requires larger sample size."""
        n_80 = self.calculator.calculate_sample_size(
            baseline_conversion_rate=0.10,
            minimum_detectable_effect=0.10,
            statistical_power=0.80
        )

        n_90 = self.calculator.calculate_sample_size(
            baseline_conversion_rate=0.10,
            minimum_detectable_effect=0.10,
            statistical_power=0.90
        )

        self.assertGreater(n_90, n_80)

    def test_smaller_effect_needs_more_samples(self):
        """Test that detecting smaller effects requires larger sample."""
        n_large_effect = self.calculator.calculate_sample_size(
            baseline_conversion_rate=0.10,
            minimum_detectable_effect=0.20,  # 20% change
            statistical_power=0.80
        )

        n_small_effect = self.calculator.calculate_sample_size(
            baseline_conversion_rate=0.10,
            minimum_detectable_effect=0.05,  # 5% change
            statistical_power=0.80
        )

        self.assertGreater(n_small_effect, n_large_effect)

    def test_power_calculation(self):
        """Test statistical power calculation."""
        power = self.calculator.calculate_power(
            baseline_conversion_rate=0.10,
            expected_effect=0.10,
            sample_size=2000
        )

        self.assertGreater(power, 0)
        self.assertLessEqual(power, 1.0)

    def test_experiment_design(self):
        """Test complete experiment design."""
        design = self.calculator.design_experiment(
            baseline_conversion_rate=0.10,
            minimum_detectable_effect=0.10,
            daily_traffic=500,
            allocation_ratio=0.5,
            statistical_power=0.80
        )

        self.assertGreater(design.required_sample_size_per_variant, 0)
        self.assertEqual(design.statistical_power, 0.80)
        self.assertGreater(design.expected_duration_days, 0)

    def test_design_to_dict(self):
        """Test experiment design serialization."""
        design = self.calculator.design_experiment(
            baseline_conversion_rate=0.10,
            minimum_detectable_effect=0.10,
            daily_traffic=500
        )

        design_dict = design.to_dict()

        self.assertIsInstance(design_dict, dict)
        self.assertIn('required_sample_size_per_variant', design_dict)


class TestABTestAnalyzer(unittest.TestCase):
    """Test A/B test analysis."""

    def setUp(self):
        """Set up analyzer."""
        self.analyzer = ABTestAnalyzer(significance_level=0.05)

    def test_significant_positive_result(self):
        """Test detection of significant positive result."""
        # Large sample with clear winner
        results = self.analyzer.analyze_test(
            control_conversions=100,
            control_total=1000,
            treatment_conversions=150,
            treatment_total=1000,
            control_revenue=100 * 99.0,
            treatment_revenue=150 * 99.0
        )

        self.assertEqual(results.significance_result, SignificanceResult.SIGNIFICANT_POSITIVE)
        self.assertLess(results.p_value, 0.05)
        self.assertGreater(results.relative_lift_percentage, 0)

    def test_significant_negative_result(self):
        """Test detection of significant negative result."""
        # Treatment performs worse
        results = self.analyzer.analyze_test(
            control_conversions=150,
            control_total=1000,
            treatment_conversions=100,
            treatment_total=1000,
            control_revenue=150 * 99.0,
            treatment_revenue=100 * 99.0
        )

        self.assertEqual(results.significance_result, SignificanceResult.SIGNIFICANT_NEGATIVE)
        self.assertLess(results.p_value, 0.05)
        self.assertLess(results.relative_lift_percentage, 0)

    def test_not_significant_result(self):
        """Test detection of non-significant result."""
        # Small difference, large p-value
        results = self.analyzer.analyze_test(
            control_conversions=100,
            control_total=1000,
            treatment_conversions=105,
            treatment_total=1000,
            control_revenue=100 * 99.0,
            treatment_revenue=105 * 99.0
        )

        self.assertEqual(results.significance_result, SignificanceResult.NOT_SIGNIFICANT)
        self.assertGreaterEqual(results.p_value, 0.05)

    def test_insufficient_data(self):
        """Test detection of insufficient data."""
        # Very small sample
        results = self.analyzer.analyze_test(
            control_conversions=5,
            control_total=20,
            treatment_conversions=8,
            treatment_total=20,
            control_revenue=5 * 99.0,
            treatment_revenue=8 * 99.0
        )

        self.assertEqual(results.significance_result, SignificanceResult.INSUFFICIENT_DATA)

    def test_confidence_interval_calculation(self):
        """Test confidence interval calculation."""
        results = self.analyzer.analyze_test(
            control_conversions=100,
            control_total=1000,
            treatment_conversions=120,
            treatment_total=1000,
            control_revenue=100 * 99.0,
            treatment_revenue=120 * 99.0
        )

        ci = results.confidence_interval

        self.assertLess(ci.lower_bound, ci.point_estimate)
        self.assertGreater(ci.upper_bound, ci.point_estimate)
        self.assertEqual(ci.confidence_level, 0.95)

    def test_revenue_per_user_calculation(self):
        """Test revenue per user calculation."""
        control_revenue = 10000.0
        treatment_revenue = 12000.0
        control_total = 1000
        treatment_total = 1000

        results = self.analyzer.analyze_test(
            control_conversions=100,
            control_total=control_total,
            treatment_conversions=120,
            treatment_total=treatment_total,
            control_revenue=control_revenue,
            treatment_revenue=treatment_revenue
        )

        expected_control_rpu = control_revenue / control_total
        expected_treatment_rpu = treatment_revenue / treatment_total

        self.assertAlmostEqual(results.control_revenue_per_user, expected_control_rpu, places=2)
        self.assertAlmostEqual(results.treatment_revenue_per_user, expected_treatment_rpu, places=2)

    def test_recommendation_generated(self):
        """Test that recommendation is generated."""
        results = self.analyzer.analyze_test(
            control_conversions=100,
            control_total=1000,
            treatment_conversions=150,
            treatment_total=1000,
            control_revenue=100 * 99.0,
            treatment_revenue=150 * 99.0
        )

        self.assertIsInstance(results.recommendation, str)
        self.assertGreater(len(results.recommendation), 0)
        self.assertGreater(results.confidence_score, 0)
        self.assertLessEqual(results.confidence_score, 1.0)

    def test_to_dict_serialization(self):
        """Test result serialization."""
        results = self.analyzer.analyze_test(
            control_conversions=100,
            control_total=1000,
            treatment_conversions=120,
            treatment_total=1000,
            control_revenue=10000.0,
            treatment_revenue=12000.0
        )

        results_dict = results.to_dict()

        self.assertIsInstance(results_dict, dict)
        self.assertIn('p_value', results_dict)
        self.assertIn('significance_result', results_dict)
        self.assertIn('recommendation', results_dict)


class TestSequentialTestingAnalyzer(unittest.TestCase):
    """Test sequential testing with early stopping."""

    def setUp(self):
        """Set up sequential analyzer."""
        self.analyzer = SequentialTestingAnalyzer(significance_level=0.05)

    def test_cannot_stop_before_minimum(self):
        """Test that test cannot stop before reaching minimum sample."""
        can_stop, reason = self.analyzer.can_stop_early(
            control_conversions=10,
            control_total=50,
            treatment_conversions=15,
            treatment_total=50,
            minimum_sample_size=100
        )

        self.assertFalse(can_stop)
        self.assertIn('minimum', reason.lower())

    def test_can_stop_with_strong_effect(self):
        """Test that test can stop early with strong significant effect."""
        can_stop, reason = self.analyzer.can_stop_early(
            control_conversions=100,
            control_total=1000,
            treatment_conversions=200,
            treatment_total=1000,
            minimum_sample_size=100
        )

        # With 100% lift and large sample, should be able to stop
        self.assertTrue(can_stop)

    def test_cannot_stop_without_significance(self):
        """Test that test cannot stop without significance."""
        can_stop, reason = self.analyzer.can_stop_early(
            control_conversions=100,
            control_total=1000,
            treatment_conversions=105,
            treatment_total=1000,
            minimum_sample_size=100
        )

        self.assertFalse(can_stop)


class TestIntegration(unittest.TestCase):
    """Integration tests for complete A/B testing workflow."""

    def test_complete_ab_test_workflow(self):
        """Test complete A/B test workflow from design to analysis."""
        # Step 1: Design experiment
        power_calc = StatisticalPowerCalculator()
        design = power_calc.design_experiment(
            baseline_conversion_rate=0.10,
            minimum_detectable_effect=0.10,
            daily_traffic=500,
            statistical_power=0.80
        )

        # Step 2: Simulate test results
        # (In production, this would be actual user data)
        required_n = design.required_sample_size_per_variant

        # Simulate a successful test with 15% lift
        control_rate = 0.10
        treatment_rate = 0.115

        control_conversions = int(required_n * control_rate)
        treatment_conversions = int(required_n * treatment_rate)

        # Step 3: Analyze results
        analyzer = ABTestAnalyzer()
        results = analyzer.analyze_test(
            control_conversions=control_conversions,
            control_total=required_n,
            treatment_conversions=treatment_conversions,
            treatment_total=required_n,
            control_revenue=control_conversions * 99.0,
            treatment_revenue=treatment_conversions * 99.0
        )

        # Step 4: Check for early stopping
        sequential = SequentialTestingAnalyzer()
        can_stop, reason = sequential.can_stop_early(
            control_conversions=control_conversions,
            control_total=required_n,
            treatment_conversions=treatment_conversions,
            treatment_total=required_n
        )

        # Verify workflow produces valid results
        self.assertIsNotNone(design.required_sample_size_per_variant)
        self.assertIsNotNone(results.significance_result)
        self.assertIsNotNone(results.recommendation)
        self.assertIsNotNone(can_stop)

    def test_varying_conversion_rates(self):
        """Test analysis with various conversion rate scenarios."""
        analyzer = ABTestAnalyzer()

        # Scenario 1: High conversion rates
        high_results = analyzer.analyze_test(
            control_conversions=300,
            control_total=1000,
            treatment_conversions=350,
            treatment_total=1000,
            control_revenue=30000.0,
            treatment_revenue=35000.0
        )

        # Scenario 2: Low conversion rates
        low_results = analyzer.analyze_test(
            control_conversions=30,
            control_total=1000,
            treatment_conversions=45,
            treatment_total=1000,
            control_revenue=3000.0,
            treatment_revenue=4500.0
        )

        # Both should produce valid results
        self.assertIsNotNone(high_results.significance_result)
        self.assertIsNotNone(low_results.significance_result)

        # Relative lifts should be similar (both ~50% lift in conversions)
        self.assertAlmostEqual(
            high_results.relative_lift_percentage,
            low_results.relative_lift_percentage,
            delta=10
        )


if __name__ == '__main__':
    unittest.main(verbosity=2)
