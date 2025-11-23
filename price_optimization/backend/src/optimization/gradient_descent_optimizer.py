"""
Gradient Descent Price Optimization Engine
Uses scipy.optimize for finding optimal price points that maximize revenue
Python 3.9+ compatible
"""

import numpy as np
from scipy import optimize
from scipy.optimize import minimize, differential_evolution
from typing import Dict, List, Tuple, Optional, Callable
from dataclasses import dataclass, field
from enum import Enum
import warnings


class ObjectiveFunction(Enum):
    """Optimization objectives"""
    REVENUE = "revenue"  # Maximize total revenue
    PROFIT = "profit"  # Maximize profit (revenue - costs)
    CLV = "customer_lifetime_value"  # Maximize CLV
    MARKET_SHARE = "market_share"  # Maximize customer acquisition


@dataclass
class OptimizationConstraints:
    """Constraints for price optimization"""

    # Price bounds
    min_price: int  # Minimum allowable price (cents)
    max_price: int  # Maximum allowable price (cents)

    # Business constraints
    min_conversion_rate: Optional[float] = 0.05  # Minimum 5% conversion
    min_gross_margin: Optional[float] = 0.30  # Minimum 30% margin
    max_customer_acquisition_cost: Optional[int] = None  # Max CAC (cents)

    # Market constraints
    min_market_share: Optional[float] = None  # Minimum market share
    max_churn_rate: Optional[float] = 0.15  # Maximum 15% churn

    # Strategic constraints
    competitor_price_min_diff: Optional[int] = None  # Min difference from competitors (cents)
    maintain_price_perception: bool = False  # Avoid "too cheap" perception


@dataclass
class OptimizationResult:
    """Result from price optimization"""

    # Optimal solution
    optimal_price: int  # Optimal price (cents)
    optimal_revenue: int  # Revenue at optimal price (cents)
    optimal_profit: int  # Profit at optimal price (cents)

    # Supporting metrics
    expected_customers: int
    expected_conversion_rate: float
    expected_churn_rate: float
    gross_margin: float
    clv_to_cac_ratio: float

    # Optimization metadata
    objective_function: ObjectiveFunction
    iterations: int
    convergence_achieved: bool
    optimization_method: str

    # Sensitivity analysis
    price_range_95_ci: Tuple[int, int]  # 95% confidence interval for optimal price
    revenue_sensitivity: float  # dRevenue/dPrice at optimal

    # Constraints satisfied
    constraints_satisfied: bool
    constraint_violations: List[str] = field(default_factory=list)

    def to_dict(self) -> dict:
        """Convert to dictionary"""
        return {
            "optimal_solution": {
                "price_dollars": round(self.optimal_price / 100, 2),
                "price_cents": self.optimal_price,
                "annual_revenue_dollars": round(self.optimal_revenue * 12 / 100, 2),
                "monthly_revenue_cents": self.optimal_revenue,
                "annual_profit_dollars": round(self.optimal_profit * 12 / 100, 2),
                "monthly_profit_cents": self.optimal_profit
            },
            "expected_metrics": {
                "customers": self.expected_customers,
                "conversion_rate": round(self.expected_conversion_rate, 4),
                "churn_rate": round(self.expected_churn_rate, 4),
                "gross_margin": round(self.gross_margin, 4),
                "clv_to_cac_ratio": round(self.clv_to_cac_ratio, 2)
            },
            "optimization": {
                "objective": self.objective_function.value,
                "method": self.optimization_method,
                "iterations": self.iterations,
                "converged": self.convergence_achieved
            },
            "sensitivity": {
                "price_ci_95_dollars": [round(p/100, 2) for p in self.price_range_95_ci],
                "revenue_sensitivity": round(self.revenue_sensitivity, 2)
            },
            "constraints": {
                "satisfied": self.constraints_satisfied,
                "violations": self.constraint_violations
            }
        }


class GradientDescentOptimizer:
    """
    Gradient Descent Price Optimizer

    Uses scipy.optimize with multiple optimization algorithms:
    1. L-BFGS-B for smooth, bounded optimization
    2. SLSQP for constrained optimization
    3. Differential Evolution for global optimization

    Exact Parameters:
    - Learning rate (alpha): Adaptive via L-BFGS-B line search
    - Tolerance: ftol=1e-9, gtol=1e-8
    - Max iterations: 10000
    - Gradient: Numerical using finite differences with step=1e-8
    """

    def __init__(
        self,
        elasticity: float,
        baseline_conversion_rate: float,
        reference_price: int,
        market_size: int,
        fixed_costs: int,
        variable_cost_per_customer: int,
        customer_acquisition_cost: int,
        churn_rate: float
    ):
        """
        Initialize optimizer with market parameters

        Args:
            elasticity: Price elasticity of demand (negative value)
            baseline_conversion_rate: Conversion rate at reference price
            reference_price: Reference price for elasticity calculation (cents)
            market_size: Total addressable market
            fixed_costs: Fixed monthly costs (cents)
            variable_cost_per_customer: Variable cost per customer (cents)
            customer_acquisition_cost: CAC (cents)
            churn_rate: Monthly churn rate
        """
        self.elasticity = elasticity
        self.baseline_conversion = baseline_conversion_rate
        self.reference_price = reference_price
        self.market_size = market_size
        self.fixed_costs = fixed_costs
        self.variable_cost = variable_cost_per_customer
        self.cac = customer_acquisition_cost
        self.churn_rate = churn_rate

        # Derived metrics
        self.lifetime_months = 1 / churn_rate if churn_rate > 0 else 12

    def optimize(
        self,
        objective: ObjectiveFunction,
        constraints: OptimizationConstraints,
        method: str = "L-BFGS-B",
        initial_guess: Optional[int] = None
    ) -> OptimizationResult:
        """
        Find optimal price point

        Args:
            objective: Optimization objective (revenue, profit, etc.)
            constraints: Business and market constraints
            method: Optimization algorithm ('L-BFGS-B', 'SLSQP', 'differential_evolution')
            initial_guess: Starting price for optimization (default: midpoint)

        Returns:
            OptimizationResult with optimal price and metrics
        """

        # Define objective function to MINIMIZE (we negate for maximization)
        def objective_func(price_array):
            price = int(price_array[0])
            metrics = self._calculate_metrics(price)

            if objective == ObjectiveFunction.REVENUE:
                return -metrics['revenue']  # Negate for maximization
            elif objective == ObjectiveFunction.PROFIT:
                return -metrics['profit']
            elif objective == ObjectiveFunction.CLV:
                return -metrics['clv']
            elif objective == ObjectiveFunction.MARKET_SHARE:
                return -metrics['customers']
            else:
                raise ValueError(f"Unknown objective: {objective}")

        # Define gradient function (numerical)
        def gradient_func(price_array):
            price = price_array[0]
            epsilon = 1e-2  # 1 cent step for finite difference

            f_plus = objective_func([price + epsilon])
            f_minus = objective_func([price - epsilon])

            gradient = (f_plus - f_minus) / (2 * epsilon)
            return np.array([gradient])

        # Define constraints for SLSQP
        scipy_constraints = self._build_scipy_constraints(constraints)

        # Bounds
        bounds = [(constraints.min_price, constraints.max_price)]

        # Initial guess
        if initial_guess is None:
            initial_guess = (constraints.min_price + constraints.max_price) // 2

        x0 = np.array([float(initial_guess)])

        # Optimize based on method
        if method == "L-BFGS-B":
            result = optimize.minimize(
                objective_func,
                x0=x0,
                method='L-BFGS-B',
                jac=gradient_func,
                bounds=bounds,
                options={
                    'ftol': 1e-9,  # Function tolerance
                    'gtol': 1e-8,  # Gradient tolerance
                    'maxiter': 10000,
                    'disp': False
                }
            )

        elif method == "SLSQP":
            result = optimize.minimize(
                objective_func,
                x0=x0,
                method='SLSQP',
                bounds=bounds,
                constraints=scipy_constraints,
                options={
                    'ftol': 1e-9,
                    'maxiter': 10000,
                    'disp': False
                }
            )

        elif method == "differential_evolution":
            # Global optimization - doesn't need initial guess
            result = optimize.differential_evolution(
                objective_func,
                bounds=bounds,
                strategy='best1bin',
                maxiter=1000,
                tol=1e-7,
                atol=1e-7,
                seed=42,
                workers=1
            )

        else:
            raise ValueError(f"Unknown method: {method}")

        # Extract optimal price
        optimal_price = int(round(result.x[0]))

        # Calculate metrics at optimal price
        metrics = self._calculate_metrics(optimal_price)

        # Check constraints
        violations = self._check_constraints(optimal_price, metrics, constraints)
        constraints_satisfied = len(violations) == 0

        # Sensitivity analysis
        price_ci, revenue_sensitivity = self._sensitivity_analysis(
            optimal_price,
            objective_func
        )

        return OptimizationResult(
            optimal_price=optimal_price,
            optimal_revenue=metrics['revenue'],
            optimal_profit=metrics['profit'],
            expected_customers=metrics['customers'],
            expected_conversion_rate=metrics['conversion_rate'],
            expected_churn_rate=self.churn_rate,
            gross_margin=metrics['gross_margin'],
            clv_to_cac_ratio=metrics['clv'] / self.cac if self.cac > 0 else 0,
            objective_function=objective,
            iterations=result.nit if hasattr(result, 'nit') else 0,
            convergence_achieved=result.success,
            optimization_method=method,
            price_range_95_ci=price_ci,
            revenue_sensitivity=revenue_sensitivity,
            constraints_satisfied=constraints_satisfied,
            constraint_violations=violations
        )

    def _calculate_metrics(self, price: int) -> Dict:
        """
        Calculate all business metrics for a given price

        Returns:
            Dict with: revenue, profit, customers, conversion_rate, gross_margin, clv
        """

        # Conversion rate based on price elasticity
        # C(p) = C_base × (p / p_ref)^ε
        price_ratio = price / self.reference_price if self.reference_price > 0 else 1
        conversion_rate = self.baseline_conversion * (price_ratio ** self.elasticity)
        conversion_rate = np.clip(conversion_rate, 0, 1)

        # Customer acquisition
        customers = int(self.market_size * conversion_rate)

        # Revenue
        revenue = price * customers

        # Costs
        total_cac = self.cac * customers
        total_variable_costs = self.variable_cost * customers
        total_costs = total_cac + total_variable_costs + self.fixed_costs

        # Profit
        profit = revenue - total_costs

        # Gross margin (excluding CAC and fixed costs)
        gross_margin = (price - self.variable_cost) / price if price > 0 else 0

        # Customer Lifetime Value
        clv = price * self.lifetime_months * 12  # Annual CLV

        return {
            'revenue': revenue,
            'profit': profit,
            'customers': customers,
            'conversion_rate': conversion_rate,
            'gross_margin': gross_margin,
            'clv': clv
        }

    def _build_scipy_constraints(
        self,
        constraints: OptimizationConstraints
    ) -> List[Dict]:
        """Build scipy-compatible constraint definitions"""

        scipy_constraints = []

        # Minimum conversion rate constraint
        if constraints.min_conversion_rate is not None:
            def conversion_constraint(price_array):
                price = price_array[0]
                metrics = self._calculate_metrics(int(price))
                return metrics['conversion_rate'] - constraints.min_conversion_rate

            scipy_constraints.append({
                'type': 'ineq',
                'fun': conversion_constraint
            })

        # Minimum gross margin constraint
        if constraints.min_gross_margin is not None:
            def margin_constraint(price_array):
                price = price_array[0]
                metrics = self._calculate_metrics(int(price))
                return metrics['gross_margin'] - constraints.min_gross_margin

            scipy_constraints.append({
                'type': 'ineq',
                'fun': margin_constraint
            })

        # Maximum churn constraint
        if constraints.max_churn_rate is not None:
            def churn_constraint(price_array):
                # Higher prices typically increase churn
                # This is a simplified model
                return constraints.max_churn_rate - self.churn_rate

            scipy_constraints.append({
                'type': 'ineq',
                'fun': churn_constraint
            })

        return scipy_constraints

    def _check_constraints(
        self,
        price: int,
        metrics: Dict,
        constraints: OptimizationConstraints
    ) -> List[str]:
        """Check if solution satisfies all constraints"""

        violations = []

        if price < constraints.min_price:
            violations.append(f"Price ${price/100:.2f} below minimum ${constraints.min_price/100:.2f}")

        if price > constraints.max_price:
            violations.append(f"Price ${price/100:.2f} above maximum ${constraints.max_price/100:.2f}")

        if constraints.min_conversion_rate and metrics['conversion_rate'] < constraints.min_conversion_rate:
            violations.append(
                f"Conversion rate {metrics['conversion_rate']:.2%} below minimum "
                f"{constraints.min_conversion_rate:.2%}"
            )

        if constraints.min_gross_margin and metrics['gross_margin'] < constraints.min_gross_margin:
            violations.append(
                f"Gross margin {metrics['gross_margin']:.2%} below minimum "
                f"{constraints.min_gross_margin:.2%}"
            )

        if constraints.max_churn_rate and self.churn_rate > constraints.max_churn_rate:
            violations.append(
                f"Churn rate {self.churn_rate:.2%} above maximum "
                f"{constraints.max_churn_rate:.2%}"
            )

        if constraints.max_customer_acquisition_cost and self.cac > constraints.max_customer_acquisition_cost:
            violations.append(
                f"CAC ${self.cac/100:.2f} above maximum "
                f"${constraints.max_customer_acquisition_cost/100:.2f}"
            )

        return violations

    def _sensitivity_analysis(
        self,
        optimal_price: int,
        objective_func: Callable
    ) -> Tuple[Tuple[int, int], float]:
        """
        Perform sensitivity analysis around optimal price

        Returns:
            Tuple of (95% CI for price, revenue sensitivity)
        """

        # Calculate objective value at optimal
        optimal_value = -objective_func([optimal_price])  # Un-negate

        # Find prices that give 95% of optimal value
        threshold_value = optimal_value * 0.95

        def value_diff_lower(price):
            return -objective_func([price]) - threshold_value

        def value_diff_upper(price):
            return -objective_func([price]) - threshold_value

        # Search for bounds
        try:
            # Lower bound
            if optimal_price > 100:
                lower_ci = int(optimize.brentq(
                    value_diff_lower,
                    optimal_price * 0.5,
                    optimal_price,
                    xtol=1
                ))
            else:
                lower_ci = optimal_price

            # Upper bound
            upper_ci = int(optimize.brentq(
                value_diff_upper,
                optimal_price,
                optimal_price * 1.5,
                xtol=1
            ))

        except (ValueError, RuntimeError):
            # Fallback to ±10%
            lower_ci = int(optimal_price * 0.9)
            upper_ci = int(optimal_price * 1.1)

        # Revenue sensitivity (numerical derivative)
        epsilon = 1.0  # 1 cent
        revenue_plus = -objective_func([optimal_price + epsilon])
        revenue_minus = -objective_func([optimal_price - epsilon])
        sensitivity = (revenue_plus - revenue_minus) / (2 * epsilon)

        return (lower_ci, upper_ci), sensitivity


class PricingCliffDetector:
    """
    Detects pricing cliffs and discontinuities in revenue function

    A pricing cliff occurs when small price changes cause large revenue drops,
    indicating a threshold where many customers become unwilling to pay.
    """

    def __init__(self, optimizer: GradientDescentOptimizer):
        """
        Initialize cliff detector

        Args:
            optimizer: GradientDescentOptimizer instance with market parameters
        """
        self.optimizer = optimizer

    def detect_cliffs(
        self,
        price_range: Tuple[int, int],
        num_points: int = 500,
        cliff_threshold: float = 0.20
    ) -> List[Dict]:
        """
        Detect pricing cliffs in the revenue function

        Args:
            price_range: (min_price, max_price) to analyze
            num_points: Number of price points to sample
            cliff_threshold: Minimum revenue drop % to qualify as cliff

        Returns:
            List of detected cliffs with locations and magnitudes
        """

        prices = np.linspace(price_range[0], price_range[1], num_points, dtype=int)

        revenues = []
        for price in prices:
            metrics = self.optimizer._calculate_metrics(price)
            revenues.append(metrics['revenue'])

        revenues = np.array(revenues)

        # Calculate first derivative (revenue change rate)
        revenue_gradient = np.gradient(revenues, prices)

        # Calculate second derivative (acceleration)
        revenue_acceleration = np.gradient(revenue_gradient, prices)

        # Detect cliffs as points with large negative acceleration
        cliffs = []

        for i in range(1, len(prices) - 1):
            # Check for significant negative acceleration
            if revenue_acceleration[i] < -cliff_threshold * revenues[i] / (prices[i] ** 2):
                # Calculate revenue drop magnitude
                revenue_before = revenues[max(0, i - 5)]
                revenue_after = revenues[min(len(revenues) - 1, i + 5)]
                drop_pct = (revenue_before - revenue_after) / revenue_before if revenue_before > 0 else 0

                if drop_pct > cliff_threshold:
                    cliffs.append({
                        'price': int(prices[i]),
                        'price_dollars': round(prices[i] / 100, 2),
                        'revenue_drop_percent': round(drop_pct * 100, 2),
                        'acceleration': float(revenue_acceleration[i]),
                        'severity': 'high' if drop_pct > 0.4 else 'medium' if drop_pct > 0.25 else 'low'
                    })

        return cliffs


# =============================================================================
# Example Usage
# =============================================================================

if __name__ == "__main__":
    """
    Test gradient descent optimizer with realistic parameters
    """

    # Initialize optimizer with market parameters
    optimizer = GradientDescentOptimizer(
        elasticity=-1.5,
        baseline_conversion_rate=0.35,
        reference_price=1000,  # $10
        market_size=50000,
        fixed_costs=500000,  # $5,000/month
        variable_cost_per_customer=50,  # $0.50
        customer_acquisition_cost=300,  # $3
        churn_rate=0.06  # 6% monthly churn
    )

    # Define constraints
    constraints = OptimizationConstraints(
        min_price=500,  # $5
        max_price=2000,  # $20
        min_conversion_rate=0.10,
        min_gross_margin=0.40
    )

    print("=" * 80)
    print("GRADIENT DESCENT PRICE OPTIMIZATION")
    print("=" * 80)

    # Test different objectives
    for objective in [ObjectiveFunction.REVENUE, ObjectiveFunction.PROFIT, ObjectiveFunction.CLV]:
        print(f"\nOptimizing for: {objective.value.upper()}")
        print("-" * 80)

        result = optimizer.optimize(
            objective=objective,
            constraints=constraints,
            method="L-BFGS-B"
        )

        print(f"Optimal Price: ${result.optimal_price/100:.2f}")
        print(f"Expected Annual Revenue: ${result.optimal_revenue * 12/100:,.2f}")
        print(f"Expected Annual Profit: ${result.optimal_profit * 12/100:,.2f}")
        print(f"Expected Customers: {result.expected_customers:,}")
        print(f"Conversion Rate: {result.expected_conversion_rate:.2%}")
        print(f"Gross Margin: {result.gross_margin:.2%}")
        print(f"CLV/CAC Ratio: {result.clv_to_cac_ratio:.2f}x")
        print(f"Iterations: {result.iterations}")
        print(f"Converged: {result.convergence_achieved}")
        print(f"Constraints Satisfied: {result.constraints_satisfied}")
        if result.constraint_violations:
            print(f"Violations: {', '.join(result.constraint_violations)}")
        print(f"95% CI: ${result.price_range_95_ci[0]/100:.2f} - ${result.price_range_95_ci[1]/100:.2f}")

    # Detect pricing cliffs
    print("\n" + "=" * 80)
    print("PRICING CLIFF DETECTION")
    print("=" * 80)

    cliff_detector = PricingCliffDetector(optimizer)
    cliffs = cliff_detector.detect_cliffs(
        price_range=(500, 2000),
        num_points=500,
        cliff_threshold=0.15
    )

    if cliffs:
        print(f"\nDetected {len(cliffs)} pricing cliff(s):")
        for i, cliff in enumerate(cliffs, 1):
            print(f"\n  Cliff #{i}:")
            print(f"    Price: ${cliff['price_dollars']}")
            print(f"    Revenue Drop: {cliff['revenue_drop_percent']}%")
            print(f"    Severity: {cliff['severity']}")
    else:
        print("\nNo significant pricing cliffs detected.")

    print("\n" + "=" * 80)
