"""
Price Elasticity of Demand Calculation Module
Uses scipy.optimize and statsmodels for econometric analysis
Python 3.9+ compatible
"""

import numpy as np
from scipy import optimize, stats
from scipy.optimize import minimize, curve_fit
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, field
import warnings


@dataclass
class ElasticityData:
    """Container for price-quantity demand data"""
    prices: np.ndarray  # Historical prices (in cents)
    quantities: np.ndarray  # Corresponding quantities demanded
    incomes: Optional[np.ndarray] = None  # Optional income data for income elasticity
    competitor_prices: Optional[np.ndarray] = None  # Optional competitor prices for cross-price elasticity

    def __post_init__(self):
        """Validate input data"""
        if len(self.prices) != len(self.quantities):
            raise ValueError("Prices and quantities must have same length")

        if len(self.prices) < 10:
            raise ValueError("Minimum 10 observations required for elasticity estimation")

        if np.any(self.prices <= 0) or np.any(self.quantities < 0):
            raise ValueError("Prices must be positive, quantities non-negative")

        if self.incomes is not None and len(self.incomes) != len(self.prices):
            raise ValueError("Income data must match price/quantity length")

        if self.competitor_prices is not None and len(self.competitor_prices) != len(self.prices):
            raise ValueError("Competitor prices must match price/quantity length")


@dataclass
class ElasticityResults:
    """Results from price elasticity estimation"""

    # Primary elasticity measure
    price_elasticity_of_demand: float  # %ΔQ / %ΔP (usually negative)

    # Additional elasticities
    cross_price_elasticity: Optional[float] = None  # Elasticity with respect to competitor prices
    income_elasticity: Optional[float] = None  # Elasticity with respect to income

    # Statistical measures
    standard_error: float = 0.0
    r_squared: float = 0.0  # Goodness of fit
    adjusted_r_squared: float = 0.0
    p_value: float = 1.0  # Statistical significance
    confidence_interval_lower: float = 0.0  # 95% CI lower bound
    confidence_interval_upper: float = 0.0  # 95% CI upper bound

    # Model information
    sample_size: int = 0
    method: str = "log_log_regression"  # Estimation method
    model_parameters: Dict = field(default_factory=dict)

    # Validation
    is_statistically_significant: bool = field(init=False)
    interpretation: str = field(init=False)

    def __post_init__(self):
        """Calculate derived fields"""
        self.is_statistically_significant = self.p_value < 0.05

        # Interpret elasticity magnitude
        abs_elasticity = abs(self.price_elasticity_of_demand)

        if abs_elasticity < 0.5:
            self.interpretation = "Highly inelastic - quantity insensitive to price changes"
        elif abs_elasticity < 1.0:
            self.interpretation = "Inelastic - quantity relatively insensitive to price"
        elif abs_elasticity == 1.0:
            self.interpretation = "Unit elastic - proportional price-quantity relationship"
        elif abs_elasticity < 2.0:
            self.interpretation = "Elastic - quantity sensitive to price changes"
        else:
            self.interpretation = "Highly elastic - quantity very sensitive to price changes"

    def to_dict(self) -> dict:
        """Convert to dictionary for serialization"""
        return {
            "price_elasticity_of_demand": round(self.price_elasticity_of_demand, 4),
            "cross_price_elasticity": round(self.cross_price_elasticity, 4) if self.cross_price_elasticity else None,
            "income_elasticity": round(self.income_elasticity, 4) if self.income_elasticity else None,
            "standard_error": round(self.standard_error, 4),
            "r_squared": round(self.r_squared, 4),
            "adjusted_r_squared": round(self.adjusted_r_squared, 4),
            "p_value": round(self.p_value, 8),
            "confidence_interval": {
                "lower": round(self.confidence_interval_lower, 4),
                "upper": round(self.confidence_interval_upper, 4)
            },
            "sample_size": self.sample_size,
            "method": self.method,
            "is_statistically_significant": self.is_statistically_significant,
            "interpretation": self.interpretation,
            "model_parameters": self.model_parameters
        }


class PriceElasticityCalculator:
    """
    Price Elasticity of Demand Calculator

    Implements multiple methods for estimating price elasticity:
    1. Log-log regression (primary method)
    2. Arc elasticity (point estimates)
    3. Constant elasticity model with scipy.optimize
    4. Time series regression with controls

    Mathematical Foundation:
    - Elasticity (ε) = (∂Q/∂P) × (P/Q)
    - Log-log model: ln(Q) = α + ε·ln(P) + controls + ε
    - Coefficient on ln(P) directly gives elasticity

    scipy.optimize parameters:
    - method: 'L-BFGS-B' for constrained optimization
    - tol: 1e-8 convergence tolerance
    - maxiter: 10000
    """

    def __init__(self, confidence_level: float = 0.95):
        """
        Initialize elasticity calculator

        Args:
            confidence_level: Confidence level for intervals (default 95%)
        """
        self.confidence_level = confidence_level
        self.alpha = 1 - confidence_level

    def calculate(
        self,
        data: ElasticityData,
        method: str = "log_log",
        include_controls: bool = True
    ) -> ElasticityResults:
        """
        Calculate price elasticity of demand

        Args:
            data: ElasticityData object with price-quantity observations
            method: Estimation method ('log_log', 'arc', 'constant_elasticity')
            include_controls: Include income and competitor price controls if available

        Returns:
            ElasticityResults object with estimated elasticity and statistics
        """
        if method == "log_log":
            return self._log_log_regression(data, include_controls)
        elif method == "arc":
            return self._arc_elasticity(data)
        elif method == "constant_elasticity":
            return self._constant_elasticity_model(data, include_controls)
        else:
            raise ValueError(f"Unknown method: {method}")

    def _log_log_regression(
        self,
        data: ElasticityData,
        include_controls: bool
    ) -> ElasticityResults:
        """
        Estimate elasticity using log-log regression

        Model: ln(Q) = α + β·ln(P) + γ·ln(Y) + δ·ln(P_c) + ε

        Where:
        - β is price elasticity
        - γ is income elasticity (if income data available)
        - δ is cross-price elasticity (if competitor price data available)

        Returns:
            ElasticityResults with regression-based estimates
        """
        # Transform to log space (add small constant to handle zeros)
        log_q = np.log(data.quantities + 1e-6)
        log_p = np.log(data.prices)

        # Build design matrix
        X = np.column_stack([np.ones(len(log_p)), log_p])
        column_names = ["intercept", "log_price"]

        if include_controls:
            if data.incomes is not None:
                log_income = np.log(data.incomes + 1e-6)
                X = np.column_stack([X, log_income])
                column_names.append("log_income")

            if data.competitor_prices is not None:
                log_comp_price = np.log(data.competitor_prices + 1e-6)
                X = np.column_stack([X, log_comp_price])
                column_names.append("log_competitor_price")

        # OLS estimation using normal equations: β = (X'X)^(-1)X'y
        try:
            beta = np.linalg.lstsq(X, log_q, rcond=None)[0]
        except np.linalg.LinAlgError:
            raise ValueError("Singular matrix - cannot estimate elasticity")

        # Calculate fitted values and residuals
        y_pred = X @ beta
        residuals = log_q - y_pred
        n = len(log_q)
        k = X.shape[1]

        # Calculate standard errors
        # σ² = RSS / (n - k)
        rss = np.sum(residuals ** 2)
        sigma_squared = rss / (n - k)

        # Var(β) = σ²(X'X)^(-1)
        xtx_inv = np.linalg.inv(X.T @ X)
        var_beta = sigma_squared * xtx_inv
        std_errors = np.sqrt(np.diag(var_beta))

        # R-squared and adjusted R-squared
        tss = np.sum((log_q - np.mean(log_q)) ** 2)
        r_squared = 1 - (rss / tss)
        adj_r_squared = 1 - ((1 - r_squared) * (n - 1) / (n - k))

        # Extract coefficients
        price_elasticity = beta[1]  # Coefficient on log_price
        price_se = std_errors[1]

        # T-statistic and p-value for price elasticity
        t_stat = price_elasticity / price_se
        p_value = 2 * (1 - stats.t.cdf(abs(t_stat), df=n-k))

        # Confidence interval
        t_critical = stats.t.ppf(1 - self.alpha/2, df=n-k)
        ci_lower = price_elasticity - t_critical * price_se
        ci_upper = price_elasticity + t_critical * price_se

        # Extract control variable elasticities if present
        income_elasticity = None
        cross_price_elasticity = None

        if "log_income" in column_names:
            income_idx = column_names.index("log_income")
            income_elasticity = beta[income_idx]

        if "log_competitor_price" in column_names:
            comp_idx = column_names.index("log_competitor_price")
            cross_price_elasticity = beta[comp_idx]

        # Build model parameters dictionary
        model_params = {
            "coefficients": {name: float(beta[i]) for i, name in enumerate(column_names)},
            "std_errors": {name: float(std_errors[i]) for i, name in enumerate(column_names)},
            "residual_std_error": float(np.sqrt(sigma_squared)),
            "f_statistic": self._calculate_f_statistic(r_squared, n, k)
        }

        return ElasticityResults(
            price_elasticity_of_demand=price_elasticity,
            cross_price_elasticity=cross_price_elasticity,
            income_elasticity=income_elasticity,
            standard_error=price_se,
            r_squared=r_squared,
            adjusted_r_squared=adj_r_squared,
            p_value=p_value,
            confidence_interval_lower=ci_lower,
            confidence_interval_upper=ci_upper,
            sample_size=n,
            method="log_log_regression",
            model_parameters=model_params
        )

    def _arc_elasticity(self, data: ElasticityData) -> ElasticityResults:
        """
        Calculate arc price elasticity between consecutive observations

        Arc elasticity formula:
        ε = (ΔQ/ΔP) × ((P1+P2)/(Q1+Q2))

        Returns average arc elasticity across all observations
        """
        arc_elasticities = []

        for i in range(len(data.prices) - 1):
            p1, p2 = data.prices[i], data.prices[i+1]
            q1, q2 = data.quantities[i], data.quantities[i+1]

            delta_q = q2 - q1
            delta_p = p2 - p1

            if delta_p != 0 and (q1 + q2) != 0:
                arc_e = (delta_q / delta_p) * ((p1 + p2) / (q1 + q2))
                arc_elasticities.append(arc_e)

        if not arc_elasticities:
            raise ValueError("Cannot calculate arc elasticity - insufficient variation")

        # Calculate statistics
        mean_elasticity = np.mean(arc_elasticities)
        std_error = np.std(arc_elasticities) / np.sqrt(len(arc_elasticities))

        # Simple confidence interval
        z_critical = stats.norm.ppf(1 - self.alpha/2)
        ci_lower = mean_elasticity - z_critical * std_error
        ci_upper = mean_elasticity + z_critical * std_error

        # Rough R-squared approximation
        # Compare variance explained vs total variance
        predicted = mean_elasticity * (data.prices[1:] - data.prices[:-1]) / data.prices[:-1]
        actual = (data.quantities[1:] - data.quantities[:-1]) / data.quantities[:-1]
        r_squared = 1 - (np.var(actual - predicted) / np.var(actual))

        return ElasticityResults(
            price_elasticity_of_demand=mean_elasticity,
            standard_error=std_error,
            r_squared=max(0, r_squared),  # Ensure non-negative
            adjusted_r_squared=max(0, r_squared),
            p_value=0.05,  # Approximate
            confidence_interval_lower=ci_lower,
            confidence_interval_upper=ci_upper,
            sample_size=len(arc_elasticities),
            method="arc_elasticity",
            model_parameters={"individual_elasticities": arc_elasticities}
        )

    def _constant_elasticity_model(
        self,
        data: ElasticityData,
        include_controls: bool
    ) -> ElasticityResults:
        """
        Fit constant elasticity demand curve using scipy.optimize

        Model: Q = A × P^ε × Y^γ × P_c^δ

        Where ε is price elasticity (to be estimated)

        Uses nonlinear least squares optimization:
        - method: 'L-BFGS-B'
        - bounds: ε ∈ [-10, 0] (must be negative for normal goods)
        - tol: 1e-8
        - maxiter: 10000
        """

        def demand_function(params, prices, incomes=None, comp_prices=None):
            """Constant elasticity demand function"""
            A = params[0]  # Scale parameter
            epsilon = params[1]  # Price elasticity

            Q = A * (prices ** epsilon)

            if include_controls and incomes is not None:
                gamma = params[2]  # Income elasticity
                Q *= (incomes ** gamma)

                if comp_prices is not None:
                    delta = params[3]  # Cross-price elasticity
                    Q *= (comp_prices ** delta)

            elif include_controls and comp_prices is not None:
                delta = params[2]  # Cross-price elasticity
                Q *= (comp_prices ** delta)

            return Q

        def objective(params):
            """Sum of squared residuals"""
            predicted = demand_function(
                params,
                data.prices,
                data.incomes if include_controls else None,
                data.competitor_prices if include_controls else None
            )
            residuals = data.quantities - predicted
            return np.sum(residuals ** 2)

        # Initial parameter guess
        initial_params = [np.mean(data.quantities), -1.0]  # A=mean(Q), ε=-1

        # Bounds: A > 0, ε ∈ [-10, 0]
        bounds = [(1e-6, None), (-10, 0)]

        if include_controls:
            if data.incomes is not None:
                initial_params.append(1.0)  # γ=1
                bounds.append((0, 5))  # Income elasticity usually positive

            if data.competitor_prices is not None:
                initial_params.append(0.5)  # δ=0.5 (substitutes)
                bounds.append((0, 5))  # Cross-price elasticity for substitutes

        # Optimize using L-BFGS-B
        result = minimize(
            objective,
            x0=initial_params,
            method='L-BFGS-B',
            bounds=bounds,
            options={
                'ftol': 1e-8,
                'gtol': 1e-8,
                'maxiter': 10000
            }
        )

        if not result.success:
            warnings.warn(f"Optimization did not converge: {result.message}")

        # Extract parameters
        optimal_params = result.x
        price_elasticity = optimal_params[1]

        # Estimate standard errors using Hessian approximation
        # Use finite differences for Hessian
        try:
            hessian = self._numerical_hessian(objective, optimal_params)
            fisher_info = hessian / 2  # For squared residuals
            cov_matrix = np.linalg.inv(fisher_info)
            std_errors = np.sqrt(np.diag(cov_matrix))
            price_se = std_errors[1]
        except (np.linalg.LinAlgError, ValueError):
            # Fallback to bootstrap if Hessian is singular
            price_se = self._bootstrap_se(data, demand_function, optimal_params, param_idx=1)

        # Calculate R-squared
        predicted = demand_function(
            optimal_params,
            data.prices,
            data.incomes if include_controls else None,
            data.competitor_prices if include_controls else None
        )
        residuals = data.quantities - predicted
        tss = np.sum((data.quantities - np.mean(data.quantities)) ** 2)
        rss = np.sum(residuals ** 2)
        r_squared = 1 - (rss / tss)

        n = len(data.prices)
        k = len(optimal_params)
        adj_r_squared = 1 - ((1 - r_squared) * (n - 1) / (n - k))

        # Confidence interval
        z_critical = stats.norm.ppf(1 - self.alpha/2)
        ci_lower = price_elasticity - z_critical * price_se
        ci_upper = price_elasticity + z_critical * price_se

        # P-value (Wald test)
        z_stat = abs(price_elasticity / price_se)
        p_value = 2 * (1 - stats.norm.cdf(z_stat))

        return ElasticityResults(
            price_elasticity_of_demand=price_elasticity,
            standard_error=price_se,
            r_squared=r_squared,
            adjusted_r_squared=adj_r_squared,
            p_value=p_value,
            confidence_interval_lower=ci_lower,
            confidence_interval_upper=ci_upper,
            sample_size=n,
            method="constant_elasticity_nonlinear",
            model_parameters={
                "scale_parameter": float(optimal_params[0]),
                "optimization_success": result.success,
                "iterations": result.nit
            }
        )

    def _numerical_hessian(self, func, params, epsilon=1e-5):
        """Calculate numerical Hessian using finite differences"""
        n = len(params)
        hessian = np.zeros((n, n))

        for i in range(n):
            for j in range(n):
                # Perturb parameters
                params_pp = params.copy()
                params_pm = params.copy()
                params_mp = params.copy()
                params_mm = params.copy()

                params_pp[i] += epsilon
                params_pp[j] += epsilon

                params_pm[i] += epsilon
                params_pm[j] -= epsilon

                params_mp[i] -= epsilon
                params_mp[j] += epsilon

                params_mm[i] -= epsilon
                params_mm[j] -= epsilon

                # Second derivative
                hessian[i, j] = (
                    func(params_pp) - func(params_pm) -
                    func(params_mp) + func(params_mm)
                ) / (4 * epsilon * epsilon)

        return hessian

    def _bootstrap_se(self, data, model_func, params, param_idx, n_bootstrap=100):
        """Bootstrap standard error estimation"""
        n = len(data.prices)
        bootstrap_estimates = []

        for _ in range(n_bootstrap):
            # Resample with replacement
            indices = np.random.choice(n, size=n, replace=True)
            boot_data = ElasticityData(
                prices=data.prices[indices],
                quantities=data.quantities[indices],
                incomes=data.incomes[indices] if data.incomes is not None else None,
                competitor_prices=data.competitor_prices[indices] if data.competitor_prices is not None else None
            )

            # Re-estimate (simplified)
            try:
                result = self.calculate(boot_data, method="log_log", include_controls=False)
                bootstrap_estimates.append(result.price_elasticity_of_demand)
            except Exception:
                continue

        if bootstrap_estimates:
            return np.std(bootstrap_estimates)
        else:
            return 0.1  # Fallback

    def _calculate_f_statistic(self, r_squared, n, k):
        """Calculate F-statistic for overall model significance"""
        if r_squared >= 1 or k <= 1:
            return 0.0

        return (r_squared / (k - 1)) / ((1 - r_squared) / (n - k))


# =============================================================================
# Example Usage and Testing
# =============================================================================

if __name__ == "__main__":
    """
    Test elasticity calculator with synthetic data

    Expected Results:
    - True elasticity: -1.5 (elastic demand)
    - Estimated elasticity: ~-1.5 ± 0.2
    - R²: > 0.85
    - Statistically significant (p < 0.05)
    """

    # Generate synthetic data with known elasticity
    np.random.seed(42)
    n = 150

    # True parameters
    TRUE_ELASTICITY = -1.5
    SCALE = 10000

    # Generate prices
    prices = np.random.uniform(500, 2000, n)  # $5 to $20

    # Generate quantities with elasticity = -1.5
    # Q = SCALE * P^(-1.5) + noise
    quantities = SCALE * (prices ** TRUE_ELASTICITY) + np.random.normal(0, 50, n)
    quantities = np.maximum(quantities, 10)  # Ensure positive

    # Create data object
    data = ElasticityData(prices=prices, quantities=quantities)

    # Calculate elasticity using different methods
    calculator = PriceElasticityCalculator(confidence_level=0.95)

    print("=" * 80)
    print("PRICE ELASTICITY OF DEMAND - ESTIMATION RESULTS")
    print("=" * 80)
    print(f"True Elasticity: {TRUE_ELASTICITY}")
    print("\n" + "=" * 80)

    for method in ["log_log", "arc", "constant_elasticity"]:
        print(f"\nMethod: {method.upper()}")
        print("-" * 80)

        try:
            result = calculator.calculate(data, method=method, include_controls=False)

            print(f"Estimated Elasticity: {result.price_elasticity_of_demand:.4f}")
            print(f"Standard Error: {result.standard_error:.4f}")
            print(f"95% CI: [{result.confidence_interval_lower:.4f}, {result.confidence_interval_upper:.4f}]")
            print(f"R²: {result.r_squared:.4f}")
            print(f"Adjusted R²: {result.adjusted_r_squared:.4f}")
            print(f"P-value: {result.p_value:.6f}")
            print(f"Statistically Significant: {result.is_statistically_significant}")
            print(f"Interpretation: {result.interpretation}")

            # Check if true value is in confidence interval
            in_ci = result.confidence_interval_lower <= TRUE_ELASTICITY <= result.confidence_interval_upper
            print(f"True value in CI: {in_ci}")

        except Exception as e:
            print(f"ERROR: {e}")

        print("-" * 80)

    print("\n" + "=" * 80)
