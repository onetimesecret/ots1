"""
Revenue Optimization Engine
Implements gradient descent and advanced optimization algorithms for pricing.
"""

import numpy as np
from scipy import optimize
from typing import Dict, List, Tuple, Optional, Callable, Any
from dataclasses import dataclass, field
import warnings


@dataclass
class OptimizationConfig:
    """Configuration for gradient descent optimization."""
    learning_rate: float = 0.01
    max_iterations: int = 10000
    tolerance: float = 1e-6
    momentum: float = 0.9
    adaptive_learning: bool = True
    early_stopping_patience: int = 50

    def __post_init__(self):
        """Validate configuration parameters."""
        if self.learning_rate <= 0:
            raise ValueError("Learning rate must be positive")
        if self.max_iterations < 1:
            raise ValueError("Maximum iterations must be at least 1")
        if self.tolerance <= 0:
            raise ValueError("Tolerance must be positive")
        if not (0 <= self.momentum < 1):
            raise ValueError("Momentum must be in [0, 1)")


@dataclass
class OptimizationResult:
    """Results from revenue optimization."""
    optimal_price: float
    max_revenue: float
    iterations_used: int
    convergence_achieved: bool
    final_gradient: float
    optimization_path: List[Tuple[float, float]] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            'optimal_price': round(self.optimal_price, 2),
            'max_revenue': round(self.max_revenue, 2),
            'iterations_used': self.iterations_used,
            'convergence_achieved': self.convergence_achieved,
            'final_gradient': round(self.final_gradient, 6),
            'path_length': len(self.optimization_path)
        }


@dataclass
class PricingCliff:
    """Represents a pricing cliff or discontinuity."""
    cliff_price: float
    revenue_drop: float
    drop_percentage: float
    severity: str  # 'minor', 'moderate', 'severe'

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            'cliff_price': round(self.cliff_price, 2),
            'revenue_drop': round(self.revenue_drop, 2),
            'drop_percentage': round(self.drop_percentage, 2),
            'severity': self.severity
        }


class RevenueFunction:
    """
    Revenue function model for optimization.

    Revenue = Price × Demand(Price)
    Demand(Price) = Base_Demand × (Price / Base_Price)^elasticity × conversion_rate(Price)
    """

    def __init__(self,
                 base_demand: float,
                 base_price: float,
                 elasticity: float,
                 variable_cost: float = 0,
                 fixed_cost: float = 0):
        """
        Initialize revenue function.

        Args:
            base_demand: Demand at base price
            base_price: Reference price point
            elasticity: Price elasticity of demand (typically negative)
            variable_cost: Variable cost per unit
            fixed_cost: Fixed costs
        """
        self.base_demand = base_demand
        self.base_price = base_price
        self.elasticity = elasticity
        self.variable_cost = variable_cost
        self.fixed_cost = fixed_cost

        # Price sensitivity factors
        self.psychological_thresholds = []  # Price points with psychological impact

    def add_psychological_threshold(self, price: float, impact: float):
        """
        Add psychological pricing threshold (e.g., $99 vs $100).

        Args:
            price: Threshold price
            impact: Impact on conversion rate (e.g., -0.1 for 10% drop above threshold)
        """
        self.psychological_thresholds.append((price, impact))

    def demand(self, price: float) -> float:
        """
        Calculate demand at given price.

        Args:
            price: Price point

        Returns:
            Expected demand
        """
        if price <= 0:
            return 0

        # Base demand curve using power law
        demand = self.base_demand * (price / self.base_price) ** self.elasticity

        # Apply psychological threshold effects
        for threshold_price, impact in self.psychological_thresholds:
            if price > threshold_price:
                demand *= (1 + impact)

        return max(0, demand)

    def revenue(self, price: float) -> float:
        """
        Calculate revenue at given price.

        Args:
            price: Price point

        Returns:
            Expected revenue
        """
        return price * self.demand(price)

    def profit(self, price: float) -> float:
        """
        Calculate profit at given price.

        Args:
            price: Price point

        Returns:
            Expected profit
        """
        demand = self.demand(price)
        revenue = price * demand
        variable_costs = self.variable_cost * demand
        return revenue - variable_costs - self.fixed_cost

    def revenue_derivative(self, price: float, h: float = 0.01) -> float:
        """
        Calculate numerical derivative of revenue function.

        Args:
            price: Price point
            h: Step size for numerical differentiation

        Returns:
            Revenue gradient at price
        """
        # Central difference method
        return (self.revenue(price + h) - self.revenue(price - h)) / (2 * h)

    def profit_derivative(self, price: float, h: float = 0.01) -> float:
        """
        Calculate numerical derivative of profit function.

        Args:
            price: Price point
            h: Step size for numerical differentiation

        Returns:
            Profit gradient at price
        """
        # Central difference method
        return (self.profit(price + h) - self.profit(price - h)) / (2 * h)


class GradientDescentOptimizer:
    """
    Gradient descent optimizer for revenue/profit maximization.

    Implements:
    - Standard gradient descent
    - Momentum-based gradient descent
    - Adaptive learning rate
    - Early stopping
    """

    def __init__(self, config: OptimizationConfig = OptimizationConfig()):
        """
        Initialize optimizer.

        Args:
            config: Optimization configuration
        """
        self.config = config

    def optimize_revenue(self,
                        revenue_func: RevenueFunction,
                        initial_price: float,
                        price_bounds: Tuple[float, float]) -> OptimizationResult:
        """
        Optimize price for maximum revenue using gradient descent.

        Args:
            revenue_func: Revenue function to optimize
            initial_price: Starting price
            price_bounds: (min_price, max_price)

        Returns:
            OptimizationResult with optimal price and convergence info
        """
        return self._optimize(
            objective_func=revenue_func.revenue,
            gradient_func=revenue_func.revenue_derivative,
            initial_value=initial_price,
            bounds=price_bounds,
            maximize=True
        )

    def optimize_profit(self,
                       revenue_func: RevenueFunction,
                       initial_price: float,
                       price_bounds: Tuple[float, float]) -> OptimizationResult:
        """
        Optimize price for maximum profit using gradient descent.

        Args:
            revenue_func: Revenue function to optimize
            initial_price: Starting price
            price_bounds: (min_price, max_price)

        Returns:
            OptimizationResult with optimal price and convergence info
        """
        return self._optimize(
            objective_func=revenue_func.profit,
            gradient_func=revenue_func.profit_derivative,
            initial_value=initial_price,
            bounds=price_bounds,
            maximize=True
        )

    def _optimize(self,
                  objective_func: Callable[[float], float],
                  gradient_func: Callable[[float], float],
                  initial_value: float,
                  bounds: Tuple[float, float],
                  maximize: bool = True) -> OptimizationResult:
        """
        Core gradient descent optimization loop.

        Args:
            objective_func: Function to optimize
            gradient_func: Gradient of objective function
            initial_value: Starting point
            bounds: (min_value, max_value) constraints
            maximize: If True, maximize; if False, minimize

        Returns:
            OptimizationResult
        """
        min_bound, max_bound = bounds
        current_value = np.clip(initial_value, min_bound, max_bound)

        learning_rate = self.config.learning_rate
        velocity = 0  # For momentum
        best_objective = objective_func(current_value)
        best_value = current_value
        no_improvement_count = 0

        optimization_path = [(current_value, best_objective)]

        for iteration in range(self.config.max_iterations):
            # Calculate gradient
            gradient = gradient_func(current_value)

            # Flip gradient direction if maximizing
            if maximize:
                gradient = -gradient

            # Check for convergence
            if abs(gradient) < self.config.tolerance:
                return OptimizationResult(
                    optimal_price=best_value,
                    max_revenue=best_objective,
                    iterations_used=iteration + 1,
                    convergence_achieved=True,
                    final_gradient=gradient,
                    optimization_path=optimization_path
                )

            # Update with momentum
            velocity = self.config.momentum * velocity - learning_rate * gradient
            current_value = current_value + velocity

            # Apply bounds
            current_value = np.clip(current_value, min_bound, max_bound)

            # Evaluate objective
            current_objective = objective_func(current_value)
            optimization_path.append((current_value, current_objective))

            # Update best solution
            if (maximize and current_objective > best_objective) or \
               (not maximize and current_objective < best_objective):
                best_objective = current_objective
                best_value = current_value
                no_improvement_count = 0

                # Increase learning rate on improvement (if adaptive)
                if self.config.adaptive_learning:
                    learning_rate = min(learning_rate * 1.05, self.config.learning_rate * 10)
            else:
                no_improvement_count += 1

                # Decrease learning rate on no improvement (if adaptive)
                if self.config.adaptive_learning:
                    learning_rate = max(learning_rate * 0.95, self.config.learning_rate * 0.1)

            # Early stopping
            if no_improvement_count >= self.config.early_stopping_patience:
                return OptimizationResult(
                    optimal_price=best_value,
                    max_revenue=best_objective,
                    iterations_used=iteration + 1,
                    convergence_achieved=False,
                    final_gradient=gradient_func(best_value),
                    optimization_path=optimization_path
                )

        # Max iterations reached
        return OptimizationResult(
            optimal_price=best_value,
            max_revenue=best_objective,
            iterations_used=self.config.max_iterations,
            convergence_achieved=False,
            final_gradient=gradient_func(best_value),
            optimization_path=optimization_path
        )


class ScipyOptimizer:
    """
    Wrapper for scipy optimization methods for comparison.

    Uses L-BFGS-B algorithm which is more efficient for bounded optimization.
    """

    def optimize_revenue(self,
                        revenue_func: RevenueFunction,
                        initial_price: float,
                        price_bounds: Tuple[float, float]) -> OptimizationResult:
        """
        Optimize revenue using scipy L-BFGS-B.

        Args:
            revenue_func: Revenue function
            initial_price: Starting price
            price_bounds: Price constraints

        Returns:
            OptimizationResult
        """
        # Negative because scipy minimizes by default
        def negative_revenue(price):
            return -revenue_func.revenue(price[0])

        def negative_gradient(price):
            return np.array([-revenue_func.revenue_derivative(price[0])])

        result = optimize.minimize(
            negative_revenue,
            x0=np.array([initial_price]),
            method='L-BFGS-B',
            jac=negative_gradient,
            bounds=[price_bounds],
            options={'maxiter': 10000, 'ftol': 1e-8}
        )

        return OptimizationResult(
            optimal_price=result.x[0],
            max_revenue=-result.fun,
            iterations_used=result.nit,
            convergence_achieved=result.success,
            final_gradient=revenue_func.revenue_derivative(result.x[0]),
            optimization_path=[]
        )


class PricingCliffDetector:
    """
    Detect pricing cliffs and discontinuities in revenue function.

    Pricing cliffs occur at psychological thresholds or competitive price points
    where small price increases cause disproportionate demand drops.
    """

    def __init__(self, sensitivity_threshold: float = 0.1):
        """
        Initialize cliff detector.

        Args:
            sensitivity_threshold: Minimum revenue drop percentage to flag as cliff
        """
        self.sensitivity_threshold = sensitivity_threshold

    def detect_cliffs(self,
                     revenue_func: RevenueFunction,
                     price_range: Tuple[float, float],
                     num_points: int = 1000) -> List[PricingCliff]:
        """
        Detect pricing cliffs in the given price range.

        Args:
            revenue_func: Revenue function to analyze
            price_range: (min_price, max_price) to scan
            num_points: Number of points to sample

        Returns:
            List of detected PricingCliff objects
        """
        min_price, max_price = price_range
        prices = np.linspace(min_price, max_price, num_points)
        revenues = np.array([revenue_func.revenue(p) for p in prices])

        cliffs = []

        # Calculate local derivatives (rate of change)
        for i in range(1, len(prices) - 1):
            # Look at revenue change around this point
            prev_revenue = revenues[i - 1]
            curr_revenue = revenues[i]
            next_revenue = revenues[i + 1]

            # Check for sudden drop
            drop_from_prev = (prev_revenue - curr_revenue) / max(prev_revenue, 1e-6)
            drop_to_next = (curr_revenue - next_revenue) / max(curr_revenue, 1e-6)

            # Detect cliff if revenue drops sharply
            if drop_from_prev > self.sensitivity_threshold or drop_to_next > self.sensitivity_threshold:
                revenue_drop = max(prev_revenue - curr_revenue, curr_revenue - next_revenue)
                drop_percentage = (revenue_drop / max(prev_revenue, curr_revenue, 1e-6)) * 100

                # Classify severity
                if drop_percentage > 20:
                    severity = 'severe'
                elif drop_percentage > 10:
                    severity = 'moderate'
                else:
                    severity = 'minor'

                cliff = PricingCliff(
                    cliff_price=prices[i],
                    revenue_drop=revenue_drop,
                    drop_percentage=drop_percentage,
                    severity=severity
                )
                cliffs.append(cliff)

        # Merge nearby cliffs
        merged_cliffs = self._merge_nearby_cliffs(cliffs, threshold=5.0)

        return merged_cliffs

    def _merge_nearby_cliffs(self, cliffs: List[PricingCliff],
                            threshold: float) -> List[PricingCliff]:
        """
        Merge cliffs that are close together.

        Args:
            cliffs: List of detected cliffs
            threshold: Price distance threshold for merging

        Returns:
            Merged list of cliffs
        """
        if not cliffs:
            return []

        # Sort by price
        sorted_cliffs = sorted(cliffs, key=lambda c: c.cliff_price)

        merged = [sorted_cliffs[0]]

        for cliff in sorted_cliffs[1:]:
            last_merged = merged[-1]

            if abs(cliff.cliff_price - last_merged.cliff_price) <= threshold:
                # Merge: keep the more severe cliff
                if cliff.drop_percentage > last_merged.drop_percentage:
                    merged[-1] = cliff
            else:
                merged.append(cliff)

        return merged


# Example usage
if __name__ == "__main__":
    print("=== Revenue Optimization Engine ===\n")

    # Create revenue function
    revenue_func = RevenueFunction(
        base_demand=1000,
        base_price=299.0,
        elasticity=-1.5,
        variable_cost=50,
        fixed_cost=10000
    )

    # Add psychological pricing threshold at $300
    revenue_func.add_psychological_threshold(price=300.0, impact=-0.15)

    # Gradient descent optimization
    print("1. Gradient Descent Optimization")
    config = OptimizationConfig(
        learning_rate=0.5,
        max_iterations=10000,
        tolerance=1e-6,
        momentum=0.9,
        adaptive_learning=True,
        early_stopping_patience=100
    )

    optimizer = GradientDescentOptimizer(config)
    result_revenue = optimizer.optimize_revenue(
        revenue_func,
        initial_price=250.0,
        price_bounds=(100.0, 500.0)
    )

    print(f"Revenue Maximizing Price: ${result_revenue.optimal_price:.2f}")
    print(f"Maximum Revenue: ${result_revenue.max_revenue:.2f}")
    print(f"Iterations: {result_revenue.iterations_used}")
    print(f"Converged: {result_revenue.convergence_achieved}")
    print(f"Final Gradient: {result_revenue.final_gradient:.6f}")

    result_profit = optimizer.optimize_profit(
        revenue_func,
        initial_price=250.0,
        price_bounds=(100.0, 500.0)
    )

    print(f"\nProfit Maximizing Price: ${result_profit.optimal_price:.2f}")
    print(f"Maximum Profit: ${result_profit.max_revenue:.2f}")
    print(f"Iterations: {result_profit.iterations_used}")
    print(f"Converged: {result_profit.convergence_achieved}")

    # Scipy optimization for comparison
    print("\n2. Scipy L-BFGS-B Optimization (for comparison)")
    scipy_optimizer = ScipyOptimizer()
    scipy_result = scipy_optimizer.optimize_revenue(
        revenue_func,
        initial_price=250.0,
        price_bounds=(100.0, 500.0)
    )

    print(f"Optimal Price (Scipy): ${scipy_result.optimal_price:.2f}")
    print(f"Maximum Revenue (Scipy): ${scipy_result.max_revenue:.2f}")
    print(f"Converged: {scipy_result.convergence_achieved}")

    # Detect pricing cliffs
    print("\n3. Pricing Cliff Detection")
    cliff_detector = PricingCliffDetector(sensitivity_threshold=0.05)
    cliffs = cliff_detector.detect_cliffs(
        revenue_func,
        price_range=(200.0, 400.0),
        num_points=2000
    )

    if cliffs:
        print(f"Detected {len(cliffs)} pricing cliff(s):")
        for i, cliff in enumerate(cliffs, 1):
            print(f"\n  Cliff {i}:")
            print(f"    Price: ${cliff.cliff_price:.2f}")
            print(f"    Revenue Drop: ${cliff.revenue_drop:.2f}")
            print(f"    Drop Percentage: {cliff.drop_percentage:.1f}%")
            print(f"    Severity: {cliff.severity}")
    else:
        print("No significant pricing cliffs detected.")

    # Calculate intermediate revenue steps
    print("\n4. Revenue Calculation Examples")
    test_prices = [250, 280, 299, 300, 320, 350]
    print(f"{'Price':>8} {'Demand':>10} {'Revenue':>12} {'Profit':>12}")
    print("-" * 46)
    for price in test_prices:
        demand = revenue_func.demand(price)
        revenue = revenue_func.revenue(price)
        profit = revenue_func.profit(price)
        print(f"${price:>6.2f} {demand:>10.1f} ${revenue:>11.2f} ${profit:>11.2f}")
