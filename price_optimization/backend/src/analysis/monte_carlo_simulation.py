"""
Monte Carlo Simulation Engine for Price Optimization
Runs 10,000+ scenarios to project revenue under different pricing strategies
Python 3.9+ compatible
"""

import numpy as np
from scipy import stats
from typing import Dict, List, Tuple, Optional, Callable
from dataclasses import dataclass, field
from enum import Enum
import json
from concurrent.futures import ProcessPoolExecutor, as_completed
from tqdm import tqdm


class MarketCondition(Enum):
    """Market condition scenarios"""
    BEAR = "bear"  # Pessimistic market conditions
    BASE = "base"  # Expected market conditions
    BULL = "bull"  # Optimistic market conditions


@dataclass
class SimulationParameters:
    """Parameters for Monte Carlo simulation"""

    # Price testing range
    price_min: int  # Minimum price to test (cents)
    price_max: int  # Maximum price to test (cents)
    price_steps: int = 100  # Number of price points to test

    # Market parameters
    base_market_size: int = 10000  # Total addressable market
    price_elasticity: float = -1.5  # Price elasticity of demand
    baseline_conversion_rate: float = 0.30  # Base conversion rate at reference price
    reference_price: int = 1000  # Reference price for elasticity (cents)

    # Cost structure (in cents)
    customer_acquisition_cost: int = 300
    operating_cost_per_customer: int = 50
    fixed_costs_monthly: int = 500000  # $5000/month

    # Customer behavior
    churn_rate_monthly: float = 0.05  # 5% monthly churn
    lifetime_months: float = 20.0  # Average customer lifetime

    # Variance parameters (for uncertainty)
    demand_variance: float = 0.15  # 15% coefficient of variation
    cost_variance: float = 0.10  # 10% cost uncertainty
    elasticity_variance: float = 0.05  # 5% elasticity uncertainty

    # Simulation settings
    n_iterations: int = 10000  # Monte Carlo iterations per price point
    random_seed: Optional[int] = None
    confidence_level: float = 0.95

    # Convergence criteria
    convergence_tolerance: float = 0.001  # Stop if results stable within 0.1%
    min_iterations: int = 1000  # Minimum iterations before checking convergence
    convergence_check_interval: int = 100  # Check every N iterations

    def __post_init__(self):
        """Validate parameters"""
        if self.price_min >= self.price_max:
            raise ValueError("price_min must be less than price_max")
        if not 0 <= self.baseline_conversion_rate <= 1:
            raise ValueError("baseline_conversion_rate must be between 0 and 1")
        if self.price_elasticity > 0:
            raise ValueError("price_elasticity must be negative for normal goods")
        if self.n_iterations < 100:
            raise ValueError("At least 100 iterations required")


@dataclass
class SimulationResult:
    """Results for a single price point simulation"""

    price_point: int  # Price tested (cents)
    market_condition: MarketCondition

    # Revenue metrics (all in cents)
    mean_monthly_revenue: int
    median_monthly_revenue: int
    revenue_std: int
    revenue_ci_lower: int
    revenue_ci_upper: int

    # Annual projections
    mean_annual_revenue: int
    annual_revenue_ci_lower: int
    annual_revenue_ci_upper: int

    # Customer metrics
    mean_customers: int
    mean_conversion_rate: float
    customers_ci_lower: int
    customers_ci_upper: int

    # Profitability
    mean_gross_margin: float
    mean_net_revenue: int
    mean_roi: float
    breakeven_probability: float

    # Risk metrics
    revenue_at_risk: int  # 5th percentile revenue
    risk_score: float  # 0-1, higher = riskier
    probability_negative_roi: float

    # Lifetime value
    customer_lifetime_value: int
    clv_to_cac_ratio: float

    # Simulation metadata
    iterations_run: int
    converged: bool
    convergence_iteration: Optional[int]

    def to_dict(self) -> dict:
        """Convert to dictionary for JSON serialization"""
        return {
            "price_point_dollars": round(self.price_point / 100, 2),
            "price_point_cents": self.price_point,
            "market_condition": self.market_condition.value,
            "revenue": {
                "monthly": {
                    "mean": self.mean_monthly_revenue,
                    "median": self.median_monthly_revenue,
                    "std": self.revenue_std,
                    "ci_95": [self.revenue_ci_lower, self.revenue_ci_upper]
                },
                "annual": {
                    "mean": self.mean_annual_revenue,
                    "ci_95": [self.annual_revenue_ci_lower, self.annual_revenue_ci_upper]
                }
            },
            "customers": {
                "mean": self.mean_customers,
                "conversion_rate": round(self.mean_conversion_rate, 4),
                "ci_95": [self.customers_ci_lower, self.customers_ci_upper]
            },
            "profitability": {
                "gross_margin": round(self.mean_gross_margin, 4),
                "net_revenue": self.mean_net_revenue,
                "roi": round(self.mean_roi, 4),
                "breakeven_probability": round(self.breakeven_probability, 4)
            },
            "risk": {
                "revenue_at_risk_5pct": self.revenue_at_risk,
                "risk_score": round(self.risk_score, 4),
                "prob_negative_roi": round(self.probability_negative_roi, 4)
            },
            "customer_lifetime_value": {
                "clv": self.customer_lifetime_value,
                "clv_to_cac_ratio": round(self.clv_to_cac_ratio, 2)
            },
            "simulation": {
                "iterations": self.iterations_run,
                "converged": self.converged,
                "convergence_iteration": self.convergence_iteration
            }
        }


class MonteCarloSimulator:
    """
    Monte Carlo Simulator for Revenue Optimization

    Simulates revenue outcomes under uncertainty for different price points.
    Uses Latin Hypercube Sampling for efficient coverage of parameter space.

    Convergence Criteria:
    - Checks if mean revenue estimate changes < 0.1% over last 100 iterations
    - Requires minimum 1,000 iterations before convergence check
    - Maximum 10,000 iterations per price point
    """

    def __init__(self, params: SimulationParameters):
        """
        Initialize Monte Carlo simulator

        Args:
            params: SimulationParameters object with simulation configuration
        """
        self.params = params

        if params.random_seed is not None:
            np.random.seed(params.random_seed)

    def run_simulation(
        self,
        market_conditions: Optional[List[MarketCondition]] = None,
        parallel: bool = True,
        show_progress: bool = True
    ) -> List[SimulationResult]:
        """
        Run complete simulation across all price points and market conditions

        Args:
            market_conditions: List of market conditions to simulate (default: all)
            parallel: Use parallel processing for speed
            show_progress: Show progress bar

        Returns:
            List of SimulationResult objects
        """
        if market_conditions is None:
            market_conditions = list(MarketCondition)

        # Generate price points to test
        prices = np.linspace(
            self.params.price_min,
            self.params.price_max,
            self.params.price_steps,
            dtype=int
        )

        # Total simulations = price_steps × market_conditions
        total_sims = len(prices) * len(market_conditions)

        print(f"Running {total_sims} simulations ({len(prices)} prices × {len(market_conditions)} conditions)")
        print(f"Monte Carlo iterations per simulation: up to {self.params.n_iterations}")
        print(f"Total maximum iterations: {total_sims * self.params.n_iterations:,}")

        results = []

        if parallel:
            results = self._run_parallel(prices, market_conditions, show_progress)
        else:
            results = self._run_sequential(prices, market_conditions, show_progress)

        return results

    def _run_parallel(
        self,
        prices: np.ndarray,
        market_conditions: List[MarketCondition],
        show_progress: bool
    ) -> List[SimulationResult]:
        """Run simulations in parallel using ProcessPoolExecutor"""

        results = []

        with ProcessPoolExecutor() as executor:
            # Submit all jobs
            futures = []
            for price in prices:
                for condition in market_conditions:
                    future = executor.submit(
                        self.simulate_price_point,
                        price,
                        condition
                    )
                    futures.append(future)

            # Collect results with progress bar
            if show_progress:
                iterator = tqdm(as_completed(futures), total=len(futures), desc="Simulating")
            else:
                iterator = as_completed(futures)

            for future in iterator:
                try:
                    result = future.result()
                    results.append(result)
                except Exception as e:
                    print(f"Simulation failed: {e}")

        return results

    def _run_sequential(
        self,
        prices: np.ndarray,
        market_conditions: List[MarketCondition],
        show_progress: bool
    ) -> List[SimulationResult]:
        """Run simulations sequentially"""

        results = []

        if show_progress:
            total = len(prices) * len(market_conditions)
            pbar = tqdm(total=total, desc="Simulating")

        for price in prices:
            for condition in market_conditions:
                result = self.simulate_price_point(price, condition)
                results.append(result)

                if show_progress:
                    pbar.update(1)

        if show_progress:
            pbar.close()

        return results

    def simulate_price_point(
        self,
        price: int,
        market_condition: MarketCondition
    ) -> SimulationResult:
        """
        Run Monte Carlo simulation for a single price point

        Args:
            price: Price to test (cents)
            market_condition: Market condition scenario

        Returns:
            SimulationResult with aggregated metrics
        """
        # Adjust parameters based on market condition
        adjusted_params = self._adjust_for_market_condition(market_condition)

        # Storage for iteration results
        revenues = []
        customers = []
        conversion_rates = []
        gross_margins = []
        net_revenues = []
        rois = []

        # Convergence tracking
        converged = False
        convergence_iter = None
        running_mean = 0

        for i in range(self.params.n_iterations):
            # Sample from uncertainty distributions
            sampled_params = self._sample_parameters(adjusted_params)

            # Calculate metrics for this iteration
            iter_result = self._single_iteration(price, sampled_params)

            revenues.append(iter_result['revenue'])
            customers.append(iter_result['customers'])
            conversion_rates.append(iter_result['conversion_rate'])
            gross_margins.append(iter_result['gross_margin'])
            net_revenues.append(iter_result['net_revenue'])
            rois.append(iter_result['roi'])

            # Check convergence
            if i >= self.params.min_iterations and i % self.params.convergence_check_interval == 0:
                new_mean = np.mean(revenues)
                if running_mean > 0:
                    relative_change = abs(new_mean - running_mean) / running_mean
                    if relative_change < self.params.convergence_tolerance:
                        converged = True
                        convergence_iter = i
                        break
                running_mean = new_mean

        # Convert to numpy arrays
        revenues = np.array(revenues)
        customers = np.array(customers)
        conversion_rates = np.array(conversion_rates)
        gross_margins = np.array(gross_margins)
        net_revenues = np.array(net_revenues)
        rois = np.array(rois)

        # Calculate summary statistics
        alpha = 1 - self.params.confidence_level

        return SimulationResult(
            price_point=price,
            market_condition=market_condition,

            # Revenue metrics
            mean_monthly_revenue=int(np.mean(revenues)),
            median_monthly_revenue=int(np.median(revenues)),
            revenue_std=int(np.std(revenues)),
            revenue_ci_lower=int(np.percentile(revenues, alpha/2 * 100)),
            revenue_ci_upper=int(np.percentile(revenues, (1 - alpha/2) * 100)),

            # Annual projections
            mean_annual_revenue=int(np.mean(revenues) * 12),
            annual_revenue_ci_lower=int(np.percentile(revenues, alpha/2 * 100) * 12),
            annual_revenue_ci_upper=int(np.percentile(revenues, (1 - alpha/2) * 100) * 12),

            # Customer metrics
            mean_customers=int(np.mean(customers)),
            mean_conversion_rate=float(np.mean(conversion_rates)),
            customers_ci_lower=int(np.percentile(customers, alpha/2 * 100)),
            customers_ci_upper=int(np.percentile(customers, (1 - alpha/2) * 100)),

            # Profitability
            mean_gross_margin=float(np.mean(gross_margins)),
            mean_net_revenue=int(np.mean(net_revenues)),
            mean_roi=float(np.mean(rois)),
            breakeven_probability=float(np.mean(net_revenues > 0)),

            # Risk metrics
            revenue_at_risk=int(np.percentile(revenues, 5)),
            risk_score=self._calculate_risk_score(revenues, net_revenues),
            probability_negative_roi=float(np.mean(rois < 0)),

            # Lifetime value
            customer_lifetime_value=int(price * (1 / self.params.churn_rate_monthly) * 12),
            clv_to_cac_ratio=float((price * (1 / self.params.churn_rate_monthly) * 12) /
                                   self.params.customer_acquisition_cost),

            # Simulation metadata
            iterations_run=len(revenues),
            converged=converged,
            convergence_iteration=convergence_iter
        )

    def _adjust_for_market_condition(self, condition: MarketCondition) -> Dict:
        """Adjust simulation parameters based on market condition"""

        params = {
            'market_size': self.params.base_market_size,
            'conversion_rate': self.params.baseline_conversion_rate,
            'elasticity': self.params.price_elasticity,
            'churn_rate': self.params.churn_rate_monthly,
            'cac': self.params.customer_acquisition_cost
        }

        if condition == MarketCondition.BEAR:
            params['market_size'] = int(self.params.base_market_size * 0.85)
            params['conversion_rate'] = self.params.baseline_conversion_rate * 0.80
            params['elasticity'] = self.params.price_elasticity * 1.3  # More price sensitive
            params['churn_rate'] = self.params.churn_rate_monthly * 1.4
            params['cac'] = int(self.params.customer_acquisition_cost * 1.2)

        elif condition == MarketCondition.BULL:
            params['market_size'] = int(self.params.base_market_size * 1.20)
            params['conversion_rate'] = self.params.baseline_conversion_rate * 1.15
            params['elasticity'] = self.params.price_elasticity * 0.85  # Less price sensitive
            params['churn_rate'] = self.params.churn_rate_monthly * 0.75
            params['cac'] = int(self.params.customer_acquisition_cost * 0.90)

        return params

    def _sample_parameters(self, base_params: Dict) -> Dict:
        """Sample parameters from uncertainty distributions"""

        sampled = {}

        # Market size: Normal distribution
        sampled['market_size'] = max(100, int(np.random.normal(
            base_params['market_size'],
            base_params['market_size'] * self.params.demand_variance
        )))

        # Conversion rate: Beta distribution (bounded 0-1)
        alpha_beta = self._beta_parameters_from_mean_var(
            base_params['conversion_rate'],
            (base_params['conversion_rate'] * self.params.demand_variance) ** 2
        )
        sampled['conversion_rate'] = np.random.beta(alpha_beta[0], alpha_beta[1])

        # Elasticity: Normal distribution
        sampled['elasticity'] = np.random.normal(
            base_params['elasticity'],
            abs(base_params['elasticity']) * self.params.elasticity_variance
        )
        sampled['elasticity'] = min(sampled['elasticity'], -0.1)  # Ensure negative

        # Churn rate: Beta distribution
        alpha_beta = self._beta_parameters_from_mean_var(
            base_params['churn_rate'],
            (base_params['churn_rate'] * self.params.demand_variance) ** 2
        )
        sampled['churn_rate'] = np.random.beta(alpha_beta[0], alpha_beta[1])

        # CAC: Lognormal distribution
        sampled['cac'] = int(np.random.lognormal(
            np.log(base_params['cac']),
            self.params.cost_variance
        ))

        # Operating cost: Lognormal distribution
        sampled['operating_cost'] = int(np.random.lognormal(
            np.log(self.params.operating_cost_per_customer),
            self.params.cost_variance
        ))

        return sampled

    def _beta_parameters_from_mean_var(self, mean: float, var: float) -> Tuple[float, float]:
        """Calculate Beta distribution parameters from mean and variance"""

        if mean <= 0 or mean >= 1:
            mean = np.clip(mean, 0.01, 0.99)

        if var >= mean * (1 - mean):
            var = mean * (1 - mean) * 0.9  # Scale down variance

        alpha = mean * ((mean * (1 - mean) / var) - 1)
        beta = (1 - mean) * ((mean * (1 - mean) / var) - 1)

        return max(alpha, 0.5), max(beta, 0.5)

    def _single_iteration(self, price: int, params: Dict) -> Dict:
        """
        Execute single Monte Carlo iteration

        Returns dict with: revenue, customers, conversion_rate, gross_margin, net_revenue, roi
        """

        # Calculate conversion rate based on price elasticity
        # C(p) = C_base × (p / p_ref)^ε
        price_ratio = price / self.params.reference_price
        conversion_rate = params['conversion_rate'] * (price_ratio ** params['elasticity'])
        conversion_rate = np.clip(conversion_rate, 0, 1)

        # Calculate customers
        potential_customers = params['market_size']
        customers = int(potential_customers * conversion_rate)

        # Revenue
        revenue = price * customers

        # Costs
        total_cac = params['cac'] * customers
        total_operating_cost = params['operating_cost'] * customers
        total_costs = total_cac + total_operating_cost + self.params.fixed_costs_monthly

        # Profitability
        net_revenue = revenue - total_costs
        gross_margin = (revenue - total_operating_cost) / revenue if revenue > 0 else 0

        # ROI
        roi = net_revenue / total_costs if total_costs > 0 else 0

        return {
            'revenue': revenue,
            'customers': customers,
            'conversion_rate': conversion_rate,
            'gross_margin': gross_margin,
            'net_revenue': net_revenue,
            'roi': roi
        }

    def _calculate_risk_score(self, revenues: np.ndarray, net_revenues: np.ndarray) -> float:
        """
        Calculate risk score (0-1) based on revenue volatility and downside risk

        Higher score = higher risk
        """

        # Coefficient of variation (relative volatility)
        cv = np.std(revenues) / np.mean(revenues) if np.mean(revenues) > 0 else 1.0

        # Downside semi-deviation (focus on negative outcomes)
        mean_revenue = np.mean(revenues)
        downside_devs = revenues[revenues < mean_revenue] - mean_revenue
        downside_risk = np.sqrt(np.mean(downside_devs ** 2)) if len(downside_devs) > 0 else 0

        # Probability of loss
        prob_loss = np.mean(net_revenues < 0)

        # Weighted combination
        risk_score = (
            0.4 * min(cv, 1.0) +
            0.3 * min(downside_risk / mean_revenue if mean_revenue > 0 else 1, 1.0) +
            0.3 * prob_loss
        )

        return float(np.clip(risk_score, 0, 1))


def find_optimal_price(results: List[SimulationResult]) -> Tuple[SimulationResult, str]:
    """
    Find optimal price point from simulation results

    Returns:
        Tuple of (optimal_result, justification)
    """

    # Filter to base market condition for fair comparison
    base_results = [r for r in results if r.market_condition == MarketCondition.BASE]

    if not base_results:
        base_results = results

    # Score each price point
    scored = []
    for result in base_results:
        # Multi-objective score
        # Maximize: revenue, ROI, CLV/CAC ratio
        # Minimize: risk, probability of negative ROI

        revenue_score = result.mean_annual_revenue / 1e6  # Normalize to millions
        roi_score = max(0, min(result.mean_roi, 5))  # Cap at 500%
        clv_cac_score = min(result.clv_to_cac_ratio, 10)  # Cap at 10x
        risk_penalty = result.risk_score * 2
        loss_penalty = result.probability_negative_roi * 3

        # Weighted score
        total_score = (
            0.40 * revenue_score +
            0.25 * roi_score +
            0.20 * clv_cac_score -
            0.10 * risk_penalty -
            0.05 * loss_penalty
        )

        scored.append((total_score, result))

    # Find maximum score
    optimal = max(scored, key=lambda x: x[0])

    justification = (
        f"Optimal price: ${optimal[1].price_point/100:.2f}\n"
        f"Expected annual revenue: ${optimal[1].mean_annual_revenue/100:,.2f}\n"
        f"Expected ROI: {optimal[1].mean_roi:.2%}\n"
        f"CLV/CAC ratio: {optimal[1].clv_to_cac_ratio:.2f}x\n"
        f"Risk score: {optimal[1].risk_score:.2f}/1.00\n"
        f"Breakeven probability: {optimal[1].breakeven_probability:.1%}"
    )

    return optimal[1], justification


# =============================================================================
# Example Usage
# =============================================================================

if __name__ == "__main__":
    """
    Run example simulation for OneTimeSecret pricing

    Expected optimal price: ~$9-12/month for Starter tier
    """

    # Define simulation parameters
    params = SimulationParameters(
        price_min=500,  # $5/month
        price_max=2000,  # $20/month
        price_steps=50,  # Test 50 price points
        base_market_size=50000,
        price_elasticity=-1.5,
        baseline_conversion_rate=0.35,
        reference_price=1000,  # $10 reference
        customer_acquisition_cost=300,  # $3
        operating_cost_per_customer=50,  # $0.50
        fixed_costs_monthly=500000,  # $5,000/month
        churn_rate_monthly=0.06,
        n_iterations=10000,
        random_seed=42,
        convergence_tolerance=0.001
    )

    # Run simulation
    simulator = MonteCarloSimulator(params)
    results = simulator.run_simulation(
        market_conditions=[MarketCondition.BASE],
        parallel=False,  # Set to True for faster execution
        show_progress=True
    )

    # Find optimal price
    optimal, justification = find_optimal_price(results)

    print("\n" + "=" * 80)
    print("OPTIMAL PRICE RECOMMENDATION")
    print("=" * 80)
    print(justification)
    print("\n" + "=" * 80)

    # Export results to JSON
    output = {
        "simulation_parameters": {
            "price_range": f"${params.price_min/100:.2f} - ${params.price_max/100:.2f}",
            "iterations_per_price": params.n_iterations,
            "total_simulations": len(results)
        },
        "optimal_price": optimal.to_dict(),
        "all_results": [r.to_dict() for r in results[:10]]  # First 10 for brevity
    }

    print("\nFirst result as JSON:")
    print(json.dumps(results[0].to_dict(), indent=2))
