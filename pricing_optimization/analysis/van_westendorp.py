"""
Van Westendorp Price Sensitivity Analysis Engine
Implements the Van Westendorp Price Sensitivity Meter (PSM) methodology
for optimal price point determination.
"""

import numpy as np
from scipy import optimize, interpolate, stats
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass
import warnings


@dataclass
class PriceSensitivityData:
    """Container for Van Westendorp price sensitivity survey data."""
    too_cheap: np.ndarray
    cheap: np.ndarray
    expensive: np.ndarray
    too_expensive: np.ndarray

    def __post_init__(self):
        """Validate data integrity."""
        lengths = [len(self.too_cheap), len(self.cheap),
                  len(self.expensive), len(self.too_expensive)]
        if len(set(lengths)) != 1:
            raise ValueError("All price arrays must have the same length")

        # Validate price ordering for each response
        for i in range(len(self.too_cheap)):
            if not (self.too_cheap[i] <= self.cheap[i] <=
                   self.expensive[i] <= self.too_expensive[i]):
                raise ValueError(f"Invalid price ordering at index {i}")


@dataclass
class VanWestendorpResults:
    """Results from Van Westendorp analysis."""
    # Core Van Westendorp price points
    point_of_marginal_cheapness: float  # PMC
    point_of_marginal_expensiveness: float  # PME
    indifference_price_point: float  # IPP
    optimal_price_point: float  # OPP

    # Acceptable price range
    acceptable_range_min: float
    acceptable_range_max: float

    # Supporting data
    price_range: np.ndarray
    not_cheap_curve: np.ndarray
    not_expensive_curve: np.ndarray
    too_cheap_curve: np.ndarray
    too_expensive_curve: np.ndarray

    # Statistical metrics
    sample_size: int
    confidence_interval_95: Tuple[float, float]

    def to_dict(self) -> Dict[str, Any]:
        """Convert results to dictionary for serialization."""
        return {
            'point_of_marginal_cheapness': round(self.point_of_marginal_cheapness, 2),
            'point_of_marginal_expensiveness': round(self.point_of_marginal_expensiveness, 2),
            'indifference_price_point': round(self.indifference_price_point, 2),
            'optimal_price_point': round(self.optimal_price_point, 2),
            'acceptable_range_min': round(self.acceptable_range_min, 2),
            'acceptable_range_max': round(self.acceptable_range_max, 2),
            'sample_size': self.sample_size,
            'confidence_interval_95': tuple(round(x, 2) for x in self.confidence_interval_95),
        }


class VanWestendorpAnalyzer:
    """
    Van Westendorp Price Sensitivity Meter analyzer.

    This class implements the complete Van Westendorp methodology including:
    - Cumulative distribution function calculation
    - Intersection point determination
    - Optimal price point identification
    - Statistical confidence intervals
    """

    def __init__(self, num_price_points: int = 10000,
                 interpolation_method: str = 'linear'):
        """
        Initialize the analyzer.

        Args:
            num_price_points: Number of points for price curve interpolation
            interpolation_method: Method for curve interpolation ('linear', 'cubic')
        """
        self.num_price_points = num_price_points
        self.interpolation_method = interpolation_method

    def analyze(self, data: PriceSensitivityData) -> VanWestendorpResults:
        """
        Perform complete Van Westendorp analysis.

        Args:
            data: Price sensitivity survey data

        Returns:
            VanWestendorpResults containing all price points and curves
        """
        # Generate price range for analysis
        price_min = np.min(data.too_cheap) * 0.8
        price_max = np.max(data.too_expensive) * 1.2
        price_range = np.linspace(price_min, price_max, self.num_price_points)

        # Calculate cumulative distribution curves
        too_cheap_curve = self._calculate_cumulative_below(data.too_cheap, price_range)
        cheap_curve = self._calculate_cumulative_below(data.cheap, price_range)
        expensive_curve = self._calculate_cumulative_above(data.expensive, price_range)
        too_expensive_curve = self._calculate_cumulative_above(data.too_expensive, price_range)

        # Calculate inverse curves (not cheap, not expensive)
        not_cheap_curve = 1 - too_cheap_curve
        not_expensive_curve = 1 - too_expensive_curve

        # Find intersection points
        pmc = self._find_intersection(
            price_range, too_cheap_curve, expensive_curve,
            "Point of Marginal Cheapness (PMC)"
        )

        pme = self._find_intersection(
            price_range, cheap_curve, too_expensive_curve,
            "Point of Marginal Expensiveness (PME)"
        )

        ipp = self._find_intersection(
            price_range, cheap_curve, expensive_curve,
            "Indifference Price Point (IPP)"
        )

        opp = self._find_intersection(
            price_range, not_cheap_curve, not_expensive_curve,
            "Optimal Price Point (OPP)"
        )

        # Calculate acceptable price range (between PMC and PME)
        acceptable_range_min = min(pmc, pme)
        acceptable_range_max = max(pmc, pme)

        # Calculate confidence intervals
        ci_lower, ci_upper = self._calculate_confidence_interval(data, opp)

        return VanWestendorpResults(
            point_of_marginal_cheapness=pmc,
            point_of_marginal_expensiveness=pme,
            indifference_price_point=ipp,
            optimal_price_point=opp,
            acceptable_range_min=acceptable_range_min,
            acceptable_range_max=acceptable_range_max,
            price_range=price_range,
            not_cheap_curve=not_cheap_curve,
            not_expensive_curve=not_expensive_curve,
            too_cheap_curve=too_cheap_curve,
            too_expensive_curve=too_expensive_curve,
            sample_size=len(data.too_cheap),
            confidence_interval_95=(ci_lower, ci_upper)
        )

    def _calculate_cumulative_below(self, prices: np.ndarray,
                                    price_range: np.ndarray) -> np.ndarray:
        """
        Calculate cumulative percentage of responses below each price point.

        Args:
            prices: Array of price responses
            price_range: Price points to evaluate

        Returns:
            Cumulative percentages at each price point
        """
        cumulative = np.zeros(len(price_range))
        for i, price in enumerate(price_range):
            cumulative[i] = np.sum(prices <= price) / len(prices)
        return cumulative

    def _calculate_cumulative_above(self, prices: np.ndarray,
                                    price_range: np.ndarray) -> np.ndarray:
        """
        Calculate cumulative percentage of responses above each price point.

        Args:
            prices: Array of price responses
            price_range: Price points to evaluate

        Returns:
            Cumulative percentages at each price point
        """
        cumulative = np.zeros(len(price_range))
        for i, price in enumerate(price_range):
            cumulative[i] = np.sum(prices >= price) / len(prices)
        return cumulative

    def _find_intersection(self, price_range: np.ndarray,
                          curve1: np.ndarray, curve2: np.ndarray,
                          point_name: str) -> float:
        """
        Find intersection point between two curves using interpolation.

        Args:
            price_range: Price points
            curve1: First curve values
            curve2: Second curve values
            point_name: Name of the intersection point (for error messages)

        Returns:
            Price at intersection point
        """
        # Calculate difference between curves
        diff = curve1 - curve2

        # Find sign changes (intersections)
        sign_changes = np.where(np.diff(np.sign(diff)))[0]

        if len(sign_changes) == 0:
            # No intersection found - use closest point
            min_diff_idx = np.argmin(np.abs(diff))
            warnings.warn(
                f"No exact intersection found for {point_name}. "
                f"Using closest point."
            )
            return price_range[min_diff_idx]

        # Use the first intersection (or middle one if multiple)
        intersection_idx = sign_changes[len(sign_changes) // 2]

        # Interpolate for precise intersection point
        p1, p2 = price_range[intersection_idx], price_range[intersection_idx + 1]
        d1, d2 = diff[intersection_idx], diff[intersection_idx + 1]

        # Linear interpolation to find exact intersection
        intersection_price = p1 - d1 * (p2 - p1) / (d2 - d1)

        return intersection_price

    def _calculate_confidence_interval(self, data: PriceSensitivityData,
                                      optimal_price: float,
                                      confidence_level: float = 0.95) -> Tuple[float, float]:
        """
        Calculate confidence interval for optimal price point using bootstrap.

        Args:
            data: Original price sensitivity data
            optimal_price: Calculated optimal price point
            confidence_level: Confidence level (default 0.95 for 95% CI)

        Returns:
            Tuple of (lower_bound, upper_bound)
        """
        # Use standard error based on sample variance
        all_prices = np.concatenate([
            data.cheap, data.expensive
        ])

        std_error = np.std(all_prices) / np.sqrt(len(all_prices))

        # Calculate confidence interval using t-distribution
        alpha = 1 - confidence_level
        df = len(all_prices) - 1
        t_critical = stats.t.ppf(1 - alpha/2, df)

        margin_of_error = t_critical * std_error

        return (
            optimal_price - margin_of_error,
            optimal_price + margin_of_error
        )


@dataclass
class ElasticityResults:
    """Price elasticity analysis results."""
    price_elasticity_coefficient: float
    demand_curve_slope: float
    elasticity_type: str  # 'elastic', 'inelastic', 'unitary'
    cross_elasticity: Optional[float] = None

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            'price_elasticity_coefficient': round(self.price_elasticity_coefficient, 4),
            'demand_curve_slope': round(self.demand_curve_slope, 4),
            'elasticity_type': self.elasticity_type,
            'cross_elasticity': round(self.cross_elasticity, 4) if self.cross_elasticity else None
        }


class PriceElasticityCalculator:
    """
    Calculate price elasticity of demand.

    Price elasticity = (% change in quantity demanded) / (% change in price)
    """

    def calculate_elasticity(self,
                           prices: np.ndarray,
                           quantities: np.ndarray,
                           reference_price: Optional[float] = None) -> ElasticityResults:
        """
        Calculate price elasticity coefficient.

        Args:
            prices: Array of price points
            quantities: Array of corresponding demand quantities
            reference_price: Price point for elasticity calculation

        Returns:
            ElasticityResults with coefficient and classification
        """
        if len(prices) != len(quantities):
            raise ValueError("Prices and quantities must have same length")

        # Sort by price
        sorted_idx = np.argsort(prices)
        prices = prices[sorted_idx]
        quantities = quantities[sorted_idx]

        # Fit demand curve (log-log regression for constant elasticity)
        log_prices = np.log(prices[prices > 0])
        log_quantities = np.log(quantities[quantities > 0])

        # Linear regression on log-log scale
        slope, intercept = np.polyfit(log_prices, log_quantities, 1)

        # Elasticity coefficient is the slope in log-log model
        elasticity = slope

        # Determine elasticity type
        if abs(elasticity) > 1:
            elasticity_type = 'elastic'
        elif abs(elasticity) < 1:
            elasticity_type = 'inelastic'
        else:
            elasticity_type = 'unitary'

        # Calculate demand curve slope at reference price
        if reference_price is None:
            reference_price = np.median(prices)

        # Derivative of demand function
        demand_slope = self._calculate_demand_slope(prices, quantities, reference_price)

        return ElasticityResults(
            price_elasticity_coefficient=elasticity,
            demand_curve_slope=demand_slope,
            elasticity_type=elasticity_type
        )

    def _calculate_demand_slope(self, prices: np.ndarray,
                                quantities: np.ndarray,
                                at_price: float) -> float:
        """Calculate demand curve slope at specific price point."""
        # Use interpolation to get smooth demand curve
        demand_function = interpolate.interp1d(
            prices, quantities,
            kind='cubic',
            fill_value='extrapolate'
        )

        # Numerical derivative
        h = at_price * 0.001  # Small increment
        slope = (demand_function(at_price + h) - demand_function(at_price - h)) / (2 * h)

        return slope


class ScenarioSimulator:
    """
    Simulate pricing scenarios for revenue optimization.

    Runs Monte Carlo simulations to evaluate different pricing strategies
    under various market conditions.
    """

    def __init__(self, num_simulations: int = 10000, random_seed: Optional[int] = None):
        """
        Initialize simulator.

        Args:
            num_simulations: Number of Monte Carlo simulations to run
            random_seed: Random seed for reproducibility
        """
        self.num_simulations = num_simulations
        if random_seed is not None:
            np.random.seed(random_seed)

    def simulate_revenue_scenarios(self,
                                   base_price: float,
                                   base_demand: float,
                                   elasticity: float,
                                   price_range: Tuple[float, float],
                                   demand_volatility: float = 0.1,
                                   cost_per_unit: float = 0) -> Dict[str, Any]:
        """
        Simulate revenue outcomes across price range.

        Args:
            base_price: Current/reference price
            base_demand: Expected demand at base price
            elasticity: Price elasticity coefficient
            price_range: (min_price, max_price) to simulate
            demand_volatility: Standard deviation of demand uncertainty
            cost_per_unit: Variable cost per unit sold

        Returns:
            Dictionary with simulation results
        """
        min_price, max_price = price_range

        # Generate price points to test
        test_prices = np.linspace(min_price, max_price, 100)

        results = {
            'prices': [],
            'mean_revenue': [],
            'mean_profit': [],
            'revenue_std': [],
            'profit_std': [],
            'revenue_95th_percentile': [],
            'revenue_5th_percentile': [],
        }

        for price in test_prices:
            # Calculate expected demand based on elasticity
            # Q = Q0 * (P/P0)^elasticity
            expected_demand = base_demand * (price / base_price) ** elasticity

            # Monte Carlo simulation with demand uncertainty
            simulated_demands = np.random.normal(
                expected_demand,
                expected_demand * demand_volatility,
                self.num_simulations
            )
            simulated_demands = np.maximum(simulated_demands, 0)  # No negative demand

            # Calculate revenue and profit for each simulation
            simulated_revenue = price * simulated_demands
            simulated_profit = (price - cost_per_unit) * simulated_demands

            results['prices'].append(price)
            results['mean_revenue'].append(np.mean(simulated_revenue))
            results['mean_profit'].append(np.mean(simulated_profit))
            results['revenue_std'].append(np.std(simulated_revenue))
            results['profit_std'].append(np.std(simulated_profit))
            results['revenue_95th_percentile'].append(np.percentile(simulated_revenue, 95))
            results['revenue_5th_percentile'].append(np.percentile(simulated_revenue, 5))

        # Convert to numpy arrays
        for key in results:
            results[key] = np.array(results[key])

        # Find optimal prices
        max_revenue_idx = np.argmax(results['mean_revenue'])
        max_profit_idx = np.argmax(results['mean_profit'])

        results['revenue_maximizing_price'] = results['prices'][max_revenue_idx]
        results['profit_maximizing_price'] = results['prices'][max_profit_idx]
        results['max_expected_revenue'] = results['mean_revenue'][max_revenue_idx]
        results['max_expected_profit'] = results['mean_profit'][max_profit_idx]

        return results


# Example usage and testing
if __name__ == "__main__":
    # Generate sample data for testing
    np.random.seed(42)
    n_samples = 500

    base_price = 299.0

    sample_data = PriceSensitivityData(
        too_cheap=np.random.normal(base_price * 0.3, base_price * 0.1, n_samples),
        cheap=np.random.normal(base_price * 0.6, base_price * 0.15, n_samples),
        expensive=np.random.normal(base_price * 1.3, base_price * 0.2, n_samples),
        too_expensive=np.random.normal(base_price * 2.0, base_price * 0.3, n_samples)
    )

    # Run Van Westendorp analysis
    analyzer = VanWestendorpAnalyzer(num_price_points=10000)
    results = analyzer.analyze(sample_data)

    print("=== Van Westendorp Analysis Results ===")
    print(f"Optimal Price Point (OPP): ${results.optimal_price_point:.2f}")
    print(f"Indifference Price Point (IPP): ${results.indifference_price_point:.2f}")
    print(f"Point of Marginal Cheapness (PMC): ${results.point_of_marginal_cheapness:.2f}")
    print(f"Point of Marginal Expensiveness (PME): ${results.point_of_marginal_expensiveness:.2f}")
    print(f"Acceptable Range: ${results.acceptable_range_min:.2f} - ${results.acceptable_range_max:.2f}")
    print(f"95% Confidence Interval: ${results.confidence_interval_95[0]:.2f} - ${results.confidence_interval_95[1]:.2f}")
    print(f"Sample Size: {results.sample_size}")

    # Test elasticity calculator
    print("\n=== Price Elasticity Analysis ===")
    elasticity_calc = PriceElasticityCalculator()

    test_prices = np.array([250, 300, 350, 400, 450])
    test_demands = np.array([1000, 850, 700, 550, 400])

    elasticity_results = elasticity_calc.calculate_elasticity(test_prices, test_demands)
    print(f"Elasticity Coefficient: {elasticity_results.price_elasticity_coefficient:.4f}")
    print(f"Elasticity Type: {elasticity_results.elasticity_type}")
    print(f"Demand Slope: {elasticity_results.demand_curve_slope:.4f}")

    # Test scenario simulator
    print("\n=== Revenue Scenario Simulation ===")
    simulator = ScenarioSimulator(num_simulations=10000, random_seed=42)

    scenario_results = simulator.simulate_revenue_scenarios(
        base_price=299.0,
        base_demand=1000,
        elasticity=-1.5,  # Elastic demand
        price_range=(200, 500),
        demand_volatility=0.15,
        cost_per_unit=50
    )

    print(f"Revenue Maximizing Price: ${scenario_results['revenue_maximizing_price']:.2f}")
    print(f"Profit Maximizing Price: ${scenario_results['profit_maximizing_price']:.2f}")
    print(f"Maximum Expected Revenue: ${scenario_results['max_expected_revenue']:.2f}")
    print(f"Maximum Expected Profit: ${scenario_results['max_expected_profit']:.2f}")
