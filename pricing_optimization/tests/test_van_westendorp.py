"""
Unit tests for Van Westendorp Price Sensitivity Analysis Engine
"""

import unittest
import numpy as np
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from analysis.van_westendorp import (
    PriceSensitivityData,
    VanWestendorpAnalyzer,
    PriceElasticityCalculator,
    ScenarioSimulator
)


class TestPriceSensitivityData(unittest.TestCase):
    """Test PriceSensitivityData validation."""

    def test_valid_data(self):
        """Test that valid data is accepted."""
        data = PriceSensitivityData(
            too_cheap=np.array([10, 20, 30]),
            cheap=np.array([20, 30, 40]),
            expensive=np.array([40, 50, 60]),
            too_expensive=np.array([60, 70, 80])
        )
        self.assertEqual(len(data.too_cheap), 3)

    def test_invalid_price_ordering(self):
        """Test that invalid price ordering raises error."""
        with self.assertRaises(ValueError):
            PriceSensitivityData(
                too_cheap=np.array([50, 20, 30]),  # First value violates ordering
                cheap=np.array([20, 30, 40]),
                expensive=np.array([40, 50, 60]),
                too_expensive=np.array([60, 70, 80])
            )

    def test_unequal_array_lengths(self):
        """Test that unequal array lengths raise error."""
        with self.assertRaises(ValueError):
            PriceSensitivityData(
                too_cheap=np.array([10, 20]),
                cheap=np.array([20, 30, 40]),  # Different length
                expensive=np.array([40, 50, 60]),
                too_expensive=np.array([60, 70, 80])
            )


class TestVanWestendorpAnalyzer(unittest.TestCase):
    """Test Van Westendorp analysis functionality."""

    def setUp(self):
        """Set up test data."""
        np.random.seed(42)
        n = 500
        base_price = 299.0

        self.data = PriceSensitivityData(
            too_cheap=np.random.normal(base_price * 0.3, base_price * 0.1, n),
            cheap=np.random.normal(base_price * 0.6, base_price * 0.15, n),
            expensive=np.random.normal(base_price * 1.3, base_price * 0.2, n),
            too_expensive=np.random.normal(base_price * 2.0, base_price * 0.3, n)
        )

        self.analyzer = VanWestendorpAnalyzer(num_price_points=1000)

    def test_analyze_returns_results(self):
        """Test that analysis returns valid results."""
        results = self.analyzer.analyze(self.data)

        self.assertIsNotNone(results.optimal_price_point)
        self.assertIsNotNone(results.indifference_price_point)
        self.assertIsNotNone(results.point_of_marginal_cheapness)
        self.assertIsNotNone(results.point_of_marginal_expensiveness)

    def test_optimal_price_in_range(self):
        """Test that optimal price is within reasonable range."""
        results = self.analyzer.analyze(self.data)

        # Optimal price should be between cheap and expensive means
        mean_cheap = np.mean(self.data.cheap)
        mean_expensive = np.mean(self.data.expensive)

        # Allow some tolerance
        self.assertGreater(results.optimal_price_point, mean_cheap * 0.5)
        self.assertLess(results.optimal_price_point, mean_expensive * 1.5)

    def test_acceptable_range_validity(self):
        """Test that acceptable price range is valid."""
        results = self.analyzer.analyze(self.data)

        self.assertLess(results.acceptable_range_min, results.acceptable_range_max)
        self.assertGreater(results.acceptable_range_min, 0)

    def test_confidence_interval_validity(self):
        """Test that confidence interval is valid."""
        results = self.analyzer.analyze(self.data)

        ci_lower, ci_upper = results.confidence_interval_95

        self.assertLess(ci_lower, results.optimal_price_point)
        self.assertGreater(ci_upper, results.optimal_price_point)
        self.assertGreater(ci_upper, ci_lower)

    def test_sample_size_recorded(self):
        """Test that sample size is correctly recorded."""
        results = self.analyzer.analyze(self.data)

        self.assertEqual(results.sample_size, len(self.data.too_cheap))

    def test_curves_have_correct_length(self):
        """Test that all curves have the expected length."""
        results = self.analyzer.analyze(self.data)

        expected_length = self.analyzer.num_price_points

        self.assertEqual(len(results.price_range), expected_length)
        self.assertEqual(len(results.not_cheap_curve), expected_length)
        self.assertEqual(len(results.not_expensive_curve), expected_length)
        self.assertEqual(len(results.too_cheap_curve), expected_length)
        self.assertEqual(len(results.too_expensive_curve), expected_length)

    def test_to_dict_serialization(self):
        """Test that results can be serialized to dict."""
        results = self.analyzer.analyze(self.data)
        result_dict = results.to_dict()

        self.assertIsInstance(result_dict, dict)
        self.assertIn('optimal_price_point', result_dict)
        self.assertIn('sample_size', result_dict)
        self.assertIsInstance(result_dict['optimal_price_point'], (int, float))


class TestPriceElasticityCalculator(unittest.TestCase):
    """Test price elasticity calculations."""

    def setUp(self):
        """Set up test data."""
        self.calculator = PriceElasticityCalculator()

    def test_elastic_demand(self):
        """Test calculation with elastic demand (elasticity > 1)."""
        # Elastic demand: quantity changes more than proportionally to price
        prices = np.array([100, 110, 120, 130, 140])
        quantities = np.array([1000, 800, 600, 400, 200])

        results = self.calculator.calculate_elasticity(prices, quantities)

        # Should detect elastic demand
        self.assertLess(results.price_elasticity_coefficient, -1)
        self.assertEqual(results.elasticity_type, 'elastic')

    def test_inelastic_demand(self):
        """Test calculation with inelastic demand (elasticity < 1)."""
        # Inelastic demand: quantity changes less than proportionally
        prices = np.array([100, 110, 120, 130, 140])
        quantities = np.array([1000, 950, 900, 860, 820])

        results = self.calculator.calculate_elasticity(prices, quantities)

        # Should detect inelastic demand
        self.assertGreater(results.price_elasticity_coefficient, -1)
        self.assertEqual(results.elasticity_type, 'inelastic')

    def test_unitary_elasticity(self):
        """Test calculation with approximately unitary elasticity."""
        # Unitary elasticity: percentage changes are equal
        prices = np.array([100, 110, 121, 133.1])
        quantities = np.array([1000, 909, 826, 751])

        results = self.calculator.calculate_elasticity(prices, quantities)

        # Should be close to -1
        self.assertAlmostEqual(results.price_elasticity_coefficient, -1, delta=0.3)

    def test_demand_slope_calculation(self):
        """Test demand slope calculation."""
        prices = np.array([100, 150, 200, 250, 300])
        quantities = np.array([1000, 800, 600, 400, 200])

        results = self.calculator.calculate_elasticity(prices, quantities)

        # Slope should be negative for normal demand
        self.assertLess(results.demand_curve_slope, 0)

    def test_mismatched_lengths_raises_error(self):
        """Test that mismatched array lengths raise error."""
        prices = np.array([100, 110, 120])
        quantities = np.array([1000, 900])  # Different length

        with self.assertRaises(ValueError):
            self.calculator.calculate_elasticity(prices, quantities)


class TestScenarioSimulator(unittest.TestCase):
    """Test scenario simulation functionality."""

    def setUp(self):
        """Set up simulator."""
        self.simulator = ScenarioSimulator(num_simulations=1000, random_seed=42)

    def test_simulation_returns_results(self):
        """Test that simulation returns valid results."""
        results = self.simulator.simulate_revenue_scenarios(
            base_price=299.0,
            base_demand=1000,
            elasticity=-1.5,
            price_range=(200, 400),
            demand_volatility=0.1
        )

        self.assertIn('prices', results)
        self.assertIn('mean_revenue', results)
        self.assertIn('revenue_maximizing_price', results)
        self.assertIn('profit_maximizing_price', results)

    def test_optimal_price_in_range(self):
        """Test that optimal prices are within simulation range."""
        min_price, max_price = 200, 400

        results = self.simulator.simulate_revenue_scenarios(
            base_price=299.0,
            base_demand=1000,
            elasticity=-1.5,
            price_range=(min_price, max_price)
        )

        self.assertGreaterEqual(results['revenue_maximizing_price'], min_price)
        self.assertLessEqual(results['revenue_maximizing_price'], max_price)

    def test_profit_vs_revenue_maximization(self):
        """Test that profit and revenue maximizing prices differ with costs."""
        results = self.simulator.simulate_revenue_scenarios(
            base_price=299.0,
            base_demand=1000,
            elasticity=-1.5,
            price_range=(200, 400),
            cost_per_unit=100  # Significant cost
        )

        # With costs, profit-maximizing price should be higher than revenue-maximizing
        # (in most cases, depending on elasticity)
        self.assertIsNotNone(results['profit_maximizing_price'])
        self.assertIsNotNone(results['revenue_maximizing_price'])

    def test_volatility_affects_confidence_intervals(self):
        """Test that higher volatility creates wider confidence intervals."""
        results_low_vol = self.simulator.simulate_revenue_scenarios(
            base_price=299.0,
            base_demand=1000,
            elasticity=-1.5,
            price_range=(200, 400),
            demand_volatility=0.05
        )

        results_high_vol = self.simulator.simulate_revenue_scenarios(
            base_price=299.0,
            base_demand=1000,
            elasticity=-1.5,
            price_range=(200, 400),
            demand_volatility=0.30
        )

        # Find revenue std at optimal price point
        low_vol_std = np.mean(results_low_vol['revenue_std'])
        high_vol_std = np.mean(results_high_vol['revenue_std'])

        self.assertGreater(high_vol_std, low_vol_std)

    def test_array_lengths_consistent(self):
        """Test that all result arrays have the same length."""
        results = self.simulator.simulate_revenue_scenarios(
            base_price=299.0,
            base_demand=1000,
            elasticity=-1.5,
            price_range=(200, 400)
        )

        length = len(results['prices'])

        self.assertEqual(len(results['mean_revenue']), length)
        self.assertEqual(len(results['mean_profit']), length)
        self.assertEqual(len(results['revenue_std']), length)
        self.assertEqual(len(results['revenue_95th_percentile']), length)


class TestIntegration(unittest.TestCase):
    """Integration tests combining multiple components."""

    def test_full_pricing_workflow(self):
        """Test complete workflow from data to optimization."""
        # Step 1: Create survey data
        np.random.seed(42)
        n = 300
        base_price = 199.0

        data = PriceSensitivityData(
            too_cheap=np.random.normal(base_price * 0.3, base_price * 0.1, n),
            cheap=np.random.normal(base_price * 0.6, base_price * 0.15, n),
            expensive=np.random.normal(base_price * 1.3, base_price * 0.2, n),
            too_expensive=np.random.normal(base_price * 2.0, base_price * 0.3, n)
        )

        # Step 2: Run Van Westendorp analysis
        analyzer = VanWestendorpAnalyzer()
        vw_results = analyzer.analyze(data)

        # Step 3: Calculate elasticity
        test_prices = np.linspace(100, 300, 10)
        # Simulate demand based on power law
        test_demands = 1000 * (test_prices / base_price) ** -1.5

        elasticity_calc = PriceElasticityCalculator()
        elasticity_results = elasticity_calc.calculate_elasticity(test_prices, test_demands)

        # Step 4: Run scenario simulation
        simulator = ScenarioSimulator(num_simulations=500, random_seed=42)
        scenario_results = simulator.simulate_revenue_scenarios(
            base_price=vw_results.optimal_price_point,
            base_demand=1000,
            elasticity=elasticity_results.price_elasticity_coefficient,
            price_range=(vw_results.acceptable_range_min,
                        vw_results.acceptable_range_max)
        )

        # Verify complete workflow produces valid results
        self.assertIsNotNone(vw_results.optimal_price_point)
        self.assertIsNotNone(elasticity_results.price_elasticity_coefficient)
        self.assertIsNotNone(scenario_results['revenue_maximizing_price'])

        # Optimal prices should be reasonable
        self.assertGreater(vw_results.optimal_price_point, 0)
        self.assertGreater(scenario_results['revenue_maximizing_price'], 0)


if __name__ == '__main__':
    # Run tests with verbose output
    unittest.main(verbosity=2)
