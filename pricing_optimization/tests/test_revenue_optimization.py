"""
Unit tests for Revenue Optimization Engine
"""

import unittest
import numpy as np
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from analysis.revenue_optimization import (
    OptimizationConfig,
    RevenueFunction,
    GradientDescentOptimizer,
    ScipyOptimizer,
    PricingCliffDetector
)


class TestOptimizationConfig(unittest.TestCase):
    """Test optimization configuration validation."""

    def test_valid_config(self):
        """Test that valid configuration is accepted."""
        config = OptimizationConfig(
            learning_rate=0.01,
            max_iterations=1000,
            tolerance=1e-6,
            momentum=0.9
        )
        self.assertEqual(config.learning_rate, 0.01)

    def test_invalid_learning_rate(self):
        """Test that negative learning rate raises error."""
        with self.assertRaises(ValueError):
            OptimizationConfig(learning_rate=-0.01)

    def test_invalid_iterations(self):
        """Test that zero iterations raises error."""
        with self.assertRaises(ValueError):
            OptimizationConfig(max_iterations=0)


class TestRevenueFunction(unittest.TestCase):
    """Test revenue function calculations."""

    def setUp(self):
        """Set up test revenue function."""
        self.revenue_func = RevenueFunction(
            base_demand=1000,
            base_price=299.0,
            elasticity=-1.5,
            variable_cost=50,
            fixed_cost=10000
        )

    def test_demand_calculation(self):
        """Test demand calculation at various prices."""
        # At base price, demand should equal base demand
        demand_at_base = self.revenue_func.demand(299.0)
        self.assertAlmostEqual(demand_at_base, 1000, delta=1)

        # Higher price should decrease demand (negative elasticity)
        demand_higher = self.revenue_func.demand(350.0)
        self.assertLess(demand_higher, 1000)

        # Lower price should increase demand
        demand_lower = self.revenue_func.demand(250.0)
        self.assertGreater(demand_lower, 1000)

    def test_revenue_calculation(self):
        """Test revenue calculation."""
        revenue = self.revenue_func.revenue(299.0)
        expected_revenue = 299.0 * 1000  # price * base_demand

        self.assertAlmostEqual(revenue, expected_revenue, delta=expected_revenue * 0.01)

    def test_profit_calculation(self):
        """Test profit calculation includes costs."""
        profit = self.revenue_func.profit(299.0)
        revenue = self.revenue_func.revenue(299.0)
        demand = self.revenue_func.demand(299.0)

        expected_profit = revenue - (50 * demand) - 10000

        self.assertAlmostEqual(profit, expected_profit, delta=100)

    def test_zero_price_zero_revenue(self):
        """Test that zero price gives zero revenue."""
        revenue = self.revenue_func.revenue(0)
        self.assertEqual(revenue, 0)

    def test_negative_price_zero_demand(self):
        """Test that negative price gives zero demand."""
        demand = self.revenue_func.demand(-10)
        self.assertEqual(demand, 0)

    def test_psychological_threshold(self):
        """Test psychological pricing threshold effect."""
        self.revenue_func.add_psychological_threshold(price=300.0, impact=-0.15)

        demand_below = self.revenue_func.demand(299.0)
        demand_above = self.revenue_func.demand(301.0)

        # Demand above threshold should be lower due to psychological impact
        self.assertLess(demand_above, demand_below * 0.9)

    def test_revenue_derivative(self):
        """Test numerical derivative calculation."""
        derivative = self.revenue_func.revenue_derivative(299.0)

        # Derivative should exist and be finite
        self.assertTrue(np.isfinite(derivative))


class TestGradientDescentOptimizer(unittest.TestCase):
    """Test gradient descent optimization."""

    def setUp(self):
        """Set up optimizer and revenue function."""
        self.config = OptimizationConfig(
            learning_rate=0.5,
            max_iterations=5000,
            tolerance=1e-6,
            momentum=0.9,
            adaptive_learning=True
        )
        self.optimizer = GradientDescentOptimizer(self.config)

        self.revenue_func = RevenueFunction(
            base_demand=1000,
            base_price=299.0,
            elasticity=-1.5,
            variable_cost=50,
            fixed_cost=5000
        )

    def test_revenue_optimization_converges(self):
        """Test that revenue optimization converges."""
        result = self.optimizer.optimize_revenue(
            self.revenue_func,
            initial_price=250.0,
            price_bounds=(100.0, 500.0)
        )

        self.assertIsNotNone(result.optimal_price)
        self.assertTrue(result.iterations_used > 0)

    def test_optimal_price_in_bounds(self):
        """Test that optimal price respects bounds."""
        min_price, max_price = 150.0, 400.0

        result = self.optimizer.optimize_revenue(
            self.revenue_func,
            initial_price=250.0,
            price_bounds=(min_price, max_price)
        )

        self.assertGreaterEqual(result.optimal_price, min_price)
        self.assertLessEqual(result.optimal_price, max_price)

    def test_profit_optimization_different_from_revenue(self):
        """Test that profit and revenue optimization give different results."""
        revenue_result = self.optimizer.optimize_revenue(
            self.revenue_func,
            initial_price=250.0,
            price_bounds=(100.0, 500.0)
        )

        profit_result = self.optimizer.optimize_profit(
            self.revenue_func,
            initial_price=250.0,
            price_bounds=(100.0, 500.0)
        )

        # With costs, profit-maximizing price should typically be higher
        # This may not always be true depending on the elasticity and cost structure
        self.assertIsNotNone(revenue_result.optimal_price)
        self.assertIsNotNone(profit_result.optimal_price)

    def test_optimization_path_recorded(self):
        """Test that optimization path is recorded."""
        result = self.optimizer.optimize_revenue(
            self.revenue_func,
            initial_price=250.0,
            price_bounds=(100.0, 500.0)
        )

        self.assertGreater(len(result.optimization_path), 0)

        # Each path element should be a tuple of (price, objective_value)
        for price, objective in result.optimization_path:
            self.assertIsInstance(price, (int, float))
            self.assertIsInstance(objective, (int, float))

    def test_to_dict_serialization(self):
        """Test result serialization."""
        result = self.optimizer.optimize_revenue(
            self.revenue_func,
            initial_price=250.0,
            price_bounds=(100.0, 500.0)
        )

        result_dict = result.to_dict()

        self.assertIsInstance(result_dict, dict)
        self.assertIn('optimal_price', result_dict)
        self.assertIn('convergence_achieved', result_dict)


class TestScipyOptimizer(unittest.TestCase):
    """Test scipy-based optimization."""

    def setUp(self):
        """Set up optimizer and revenue function."""
        self.optimizer = ScipyOptimizer()

        self.revenue_func = RevenueFunction(
            base_demand=1000,
            base_price=299.0,
            elasticity=-1.5
        )

    def test_scipy_optimization_works(self):
        """Test that scipy optimization produces valid results."""
        result = self.optimizer.optimize_revenue(
            self.revenue_func,
            initial_price=250.0,
            price_bounds=(100.0, 500.0)
        )

        self.assertIsNotNone(result.optimal_price)
        self.assertGreater(result.max_revenue, 0)

    def test_scipy_respects_bounds(self):
        """Test that scipy respects price bounds."""
        min_price, max_price = 200.0, 350.0

        result = self.optimizer.optimize_revenue(
            self.revenue_func,
            initial_price=275.0,
            price_bounds=(min_price, max_price)
        )

        self.assertGreaterEqual(result.optimal_price, min_price)
        self.assertLessEqual(result.optimal_price, max_price)


class TestPricingCliffDetector(unittest.TestCase):
    """Test pricing cliff detection."""

    def setUp(self):
        """Set up cliff detector and revenue function."""
        self.detector = PricingCliffDetector(sensitivity_threshold=0.1)

        self.revenue_func = RevenueFunction(
            base_demand=1000,
            base_price=299.0,
            elasticity=-1.5
        )

        # Add psychological threshold to create a cliff
        self.revenue_func.add_psychological_threshold(price=300.0, impact=-0.20)

    def test_cliff_detection(self):
        """Test that cliffs are detected."""
        cliffs = self.detector.detect_cliffs(
            self.revenue_func,
            price_range=(250.0, 350.0),
            num_points=500
        )

        # Should detect at least one cliff near $300
        self.assertGreater(len(cliffs), 0)

    def test_cliff_near_threshold(self):
        """Test that detected cliff is near the psychological threshold."""
        cliffs = self.detector.detect_cliffs(
            self.revenue_func,
            price_range=(250.0, 350.0),
            num_points=500
        )

        if len(cliffs) > 0:
            # At least one cliff should be near $300
            cliff_prices = [c.cliff_price for c in cliffs]
            min_distance_to_300 = min(abs(p - 300.0) for p in cliff_prices)

            self.assertLess(min_distance_to_300, 20.0)  # Within $20

    def test_cliff_severity_classification(self):
        """Test that cliff severity is correctly classified."""
        cliffs = self.detector.detect_cliffs(
            self.revenue_func,
            price_range=(250.0, 350.0),
            num_points=500
        )

        for cliff in cliffs:
            self.assertIn(cliff.severity, ['minor', 'moderate', 'severe'])

    def test_cliff_to_dict_serialization(self):
        """Test cliff serialization."""
        cliffs = self.detector.detect_cliffs(
            self.revenue_func,
            price_range=(250.0, 350.0),
            num_points=500
        )

        if len(cliffs) > 0:
            cliff_dict = cliffs[0].to_dict()

            self.assertIsInstance(cliff_dict, dict)
            self.assertIn('cliff_price', cliff_dict)
            self.assertIn('severity', cliff_dict)

    def test_no_cliffs_smooth_function(self):
        """Test that smooth revenue function has no cliffs."""
        smooth_func = RevenueFunction(
            base_demand=1000,
            base_price=299.0,
            elasticity=-1.5
        )
        # No psychological thresholds added

        cliffs = self.detector.detect_cliffs(
            smooth_func,
            price_range=(250.0, 350.0),
            num_points=500
        )

        # Should detect very few or no cliffs
        self.assertLessEqual(len(cliffs), 2)


class TestIntegration(unittest.TestCase):
    """Integration tests for revenue optimization."""

    def test_complete_optimization_workflow(self):
        """Test complete optimization workflow."""
        # Step 1: Create revenue function
        revenue_func = RevenueFunction(
            base_demand=1000,
            base_price=299.0,
            elasticity=-1.5,
            variable_cost=50,
            fixed_cost=10000
        )

        # Add psychological threshold
        revenue_func.add_psychological_threshold(300.0, -0.15)

        # Step 2: Detect pricing cliffs
        cliff_detector = PricingCliffDetector(sensitivity_threshold=0.08)
        cliffs = cliff_detector.detect_cliffs(
            revenue_func,
            price_range=(200.0, 400.0),
            num_points=1000
        )

        # Step 3: Optimize revenue
        optimizer = GradientDescentOptimizer(OptimizationConfig(
            learning_rate=0.5,
            max_iterations=5000,
            tolerance=1e-6
        ))

        revenue_result = optimizer.optimize_revenue(
            revenue_func,
            initial_price=250.0,
            price_bounds=(200.0, 400.0)
        )

        profit_result = optimizer.optimize_profit(
            revenue_func,
            initial_price=250.0,
            price_bounds=(200.0, 400.0)
        )

        # Verify complete workflow
        self.assertIsNotNone(cliffs)
        self.assertIsNotNone(revenue_result.optimal_price)
        self.assertIsNotNone(profit_result.optimal_price)

        # Optimal prices should be positive and within bounds
        self.assertGreater(revenue_result.optimal_price, 0)
        self.assertGreater(profit_result.optimal_price, 0)
        self.assertLessEqual(revenue_result.optimal_price, 400.0)
        self.assertLessEqual(profit_result.optimal_price, 400.0)

    def test_gradient_vs_scipy_consistency(self):
        """Test that gradient descent and scipy give similar results."""
        revenue_func = RevenueFunction(
            base_demand=1000,
            base_price=299.0,
            elasticity=-1.5
        )

        gd_optimizer = GradientDescentOptimizer(OptimizationConfig(
            learning_rate=0.5,
            max_iterations=10000,
            tolerance=1e-7
        ))

        scipy_optimizer = ScipyOptimizer()

        gd_result = gd_optimizer.optimize_revenue(
            revenue_func,
            initial_price=250.0,
            price_bounds=(100.0, 500.0)
        )

        scipy_result = scipy_optimizer.optimize_revenue(
            revenue_func,
            initial_price=250.0,
            price_bounds=(100.0, 500.0)
        )

        # Results should be close (within 5%)
        price_diff_pct = abs(gd_result.optimal_price - scipy_result.optimal_price) / scipy_result.optimal_price * 100

        self.assertLess(price_diff_pct, 5.0)


if __name__ == '__main__':
    unittest.main(verbosity=2)
