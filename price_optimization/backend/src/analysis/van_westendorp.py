"""
Van Westendorp Price Sensitivity Meter Analysis Engine
Uses scipy.optimize for curve intersection calculations and price point determination
Python 3.9+ compatible
"""

import numpy as np
from scipy import interpolate, optimize
from scipy.stats import norm
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
import json


@dataclass
class PriceSensitivityData:
    """Container for Van Westendorp price sensitivity survey responses"""
    too_cheap: np.ndarray  # Prices respondents consider too cheap (quality concerns)
    bargain: np.ndarray    # Prices considered a bargain (good value)
    expensive: np.ndarray  # Prices considered expensive but acceptable
    too_expensive: np.ndarray  # Prices considered too expensive (won't buy)

    def __post_init__(self):
        """Validate input data"""
        if not all(len(arr) == len(self.too_cheap) for arr in [self.bargain, self.expensive, self.too_expensive]):
            raise ValueError("All price arrays must have the same length")

        if len(self.too_cheap) < 10:
            raise ValueError("Minimum 10 responses required for valid analysis")

        # Validate price ordering for each response
        for i in range(len(self.too_cheap)):
            if not (self.too_cheap[i] <= self.bargain[i] <= self.expensive[i] <= self.too_expensive[i]):
                raise ValueError(f"Invalid price ordering at index {i}")


@dataclass
class VanWestendorpResults:
    """Results from Van Westendorp Price Sensitivity Meter analysis"""

    # Primary price points (in cents)
    point_of_marginal_cheapness: int  # PMC: too_cheap ∩ expensive
    point_of_marginal_expensiveness: int  # PME: bargain ∩ too_expensive
    optimal_price_point: int  # OPP: too_cheap ∩ too_expensive
    indifference_price_point: int  # IPP: bargain ∩ expensive

    # Acceptable price range
    acceptable_range_lower: int  # PMC
    acceptable_range_upper: int  # PME

    # Recommended pricing
    recommended_price: int

    # Statistical measures
    sample_size: int
    confidence_score: float  # 0-1 scale
    data_quality_score: float  # 0-1 scale

    # Descriptive statistics
    median_acceptable: int
    mean_acceptable: int
    std_dev: int

    # Curve data for visualization
    cumulative_curves: Dict[str, List[Tuple[int, float]]]

    # Metadata
    algorithm_version: str = "1.0.0"

    def to_dict(self) -> dict:
        """Convert results to dictionary for JSON serialization"""
        return {
            "point_of_marginal_cheapness": self.point_of_marginal_cheapness,
            "point_of_marginal_expensiveness": self.point_of_marginal_expensiveness,
            "optimal_price_point": self.optimal_price_point,
            "indifference_price_point": self.indifference_price_point,
            "acceptable_range_lower": self.acceptable_range_lower,
            "acceptable_range_upper": self.acceptable_range_upper,
            "recommended_price": self.recommended_price,
            "sample_size": self.sample_size,
            "confidence_score": round(self.confidence_score, 4),
            "data_quality_score": round(self.data_quality_score, 4),
            "median_acceptable": self.median_acceptable,
            "mean_acceptable": self.mean_acceptable,
            "std_dev": self.std_dev,
            "cumulative_curves": self.cumulative_curves,
            "algorithm_version": self.algorithm_version
        }

    def to_json(self) -> str:
        """Convert results to JSON string"""
        return json.dumps(self.to_dict(), indent=2)


class VanWestendorpAnalyzer:
    """
    Van Westendorp Price Sensitivity Meter Analysis Engine

    Implements the Van Westendorp methodology for determining optimal price points
    by analyzing the intersection of cumulative distribution curves.

    Algorithm:
    1. Generate cumulative distribution functions for four price perceptions
    2. Find intersection points of specific curve pairs
    3. Calculate confidence metrics based on sample characteristics
    4. Determine recommended pricing strategy

    Parameters for scipy.optimize:
    - method: 'brentq' for robust root finding
    - xtol: 0.01 (1 cent tolerance for price intersection)
    - maxiter: 1000 iterations
    """

    def __init__(self, interpolation_method: str = 'linear', num_price_points: int = 10000):
        """
        Initialize Van Westendorp analyzer

        Args:
            interpolation_method: Method for curve interpolation ('linear', 'cubic')
            num_price_points: Number of points for curve discretization (default: 10000)
        """
        self.interpolation_method = interpolation_method
        self.num_price_points = num_price_points

    def analyze(self, data: PriceSensitivityData) -> VanWestendorpResults:
        """
        Perform complete Van Westendorp analysis

        Args:
            data: PriceSensitivityData object containing survey responses

        Returns:
            VanWestendorpResults object with analysis results
        """
        # Generate cumulative distribution curves
        price_range, curves = self._generate_cumulative_curves(data)

        # Find key intersection points
        pmc = self._find_intersection(
            price_range, curves['too_cheap'], curves['expensive'],
            "Point of Marginal Cheapness"
        )

        pme = self._find_intersection(
            price_range, curves['bargain'], curves['too_expensive'],
            "Point of Marginal Expensiveness"
        )

        opp = self._find_intersection(
            price_range, curves['too_cheap'], curves['too_expensive'],
            "Optimal Price Point"
        )

        ipp = self._find_intersection(
            price_range, curves['bargain'], curves['expensive'],
            "Indifference Price Point"
        )

        # Calculate statistical measures
        all_acceptable_prices = np.concatenate([
            data.bargain,
            data.expensive
        ])

        median_acceptable = int(np.median(all_acceptable_prices))
        mean_acceptable = int(np.mean(all_acceptable_prices))
        std_dev = int(np.std(all_acceptable_prices))

        # Calculate confidence and quality scores
        confidence_score = self._calculate_confidence_score(data, pmc, pme)
        quality_score = self._calculate_data_quality_score(data)

        # Determine recommended price
        recommended_price = self._calculate_recommended_price(pmc, pme, opp, ipp, median_acceptable)

        # Prepare curve data for visualization
        cumulative_curves = self._serialize_curves(price_range, curves)

        return VanWestendorpResults(
            point_of_marginal_cheapness=pmc,
            point_of_marginal_expensiveness=pme,
            optimal_price_point=opp,
            indifference_price_point=ipp,
            acceptable_range_lower=pmc,
            acceptable_range_upper=pme,
            recommended_price=recommended_price,
            sample_size=len(data.too_cheap),
            confidence_score=confidence_score,
            data_quality_score=quality_score,
            median_acceptable=median_acceptable,
            mean_acceptable=mean_acceptable,
            std_dev=std_dev,
            cumulative_curves=cumulative_curves
        )

    def _generate_cumulative_curves(
        self, data: PriceSensitivityData
    ) -> Tuple[np.ndarray, Dict[str, np.ndarray]]:
        """
        Generate cumulative distribution functions for all four price perceptions

        Returns:
            Tuple of (price_range, curves_dict) where curves_dict contains:
            - 'too_cheap': Cumulative % who say price is too cheap
            - 'bargain': Cumulative % who say price is a bargain
            - 'expensive': Cumulative % who say price is expensive
            - 'too_expensive': Cumulative % who say price is too expensive
        """
        # Determine price range for analysis
        min_price = min(
            np.min(data.too_cheap),
            np.min(data.bargain),
            np.min(data.expensive),
            np.min(data.too_expensive)
        )
        max_price = max(
            np.max(data.too_cheap),
            np.max(data.bargain),
            np.max(data.expensive),
            np.max(data.too_expensive)
        )

        # Add 10% buffer on each end
        price_buffer = (max_price - min_price) * 0.1
        min_price = max(0, min_price - price_buffer)
        max_price = max_price + price_buffer

        # Create uniform price range
        price_range = np.linspace(min_price, max_price, self.num_price_points)

        # Calculate cumulative percentages for each price perception
        n = len(data.too_cheap)

        curves = {
            'too_cheap': self._cumulative_percentage(data.too_cheap, price_range, ascending=True),
            'bargain': self._cumulative_percentage(data.bargain, price_range, ascending=False),
            'expensive': self._cumulative_percentage(data.expensive, price_range, ascending=True),
            'too_expensive': self._cumulative_percentage(data.too_expensive, price_range, ascending=True)
        }

        return price_range, curves

    def _cumulative_percentage(
        self, prices: np.ndarray, price_range: np.ndarray, ascending: bool = True
    ) -> np.ndarray:
        """
        Calculate cumulative percentage for a given set of price responses

        Args:
            prices: Array of price responses
            price_range: Array of prices to evaluate
            ascending: If True, calculate ascending cumulative (≥ price)
                      If False, calculate descending cumulative (≤ price)

        Returns:
            Array of cumulative percentages (0-1) for each price in price_range
        """
        n = len(prices)
        cumulative = np.zeros_like(price_range)

        for i, price in enumerate(price_range):
            if ascending:
                # Percentage of respondents who gave this price or lower
                count = np.sum(prices <= price)
            else:
                # Percentage of respondents who gave this price or higher
                count = np.sum(prices >= price)

            cumulative[i] = count / n

        return cumulative

    def _find_intersection(
        self,
        price_range: np.ndarray,
        curve1: np.ndarray,
        curve2: np.ndarray,
        intersection_name: str
    ) -> int:
        """
        Find intersection point of two cumulative curves using scipy.optimize

        Uses Brent's method (brentq) for robust root finding with the following parameters:
        - xtol: 0.01 (1 cent absolute tolerance)
        - rtol: 1e-6 (relative tolerance)
        - maxiter: 1000

        Args:
            price_range: Array of price values
            curve1: First cumulative curve
            curve2: Second cumulative curve
            intersection_name: Name of intersection point (for error messages)

        Returns:
            Price at intersection point (in cents)
        """
        # Create interpolation functions for smooth curves
        f1 = interpolate.interp1d(price_range, curve1, kind=self.interpolation_method,
                                   fill_value='extrapolate')
        f2 = interpolate.interp1d(price_range, curve2, kind=self.interpolation_method,
                                   fill_value='extrapolate')

        # Define difference function (root is intersection)
        def difference(price):
            return f1(price) - f2(price)

        # Find all sign changes in the difference function
        diff_values = curve1 - curve2
        sign_changes = np.where(np.diff(np.sign(diff_values)))[0]

        if len(sign_changes) == 0:
            # No intersection found - return fallback value
            # Use the price where curves are closest
            min_diff_idx = np.argmin(np.abs(diff_values))
            return int(price_range[min_diff_idx])

        # Use the first intersection point
        idx = sign_changes[0]

        # Narrow the search range around the sign change
        search_min = price_range[idx]
        search_max = price_range[min(idx + 1, len(price_range) - 1)]

        try:
            # Use Brent's method for robust root finding
            intersection_price = optimize.brentq(
                difference,
                search_min,
                search_max,
                xtol=0.01,  # 1 cent tolerance
                rtol=1e-6,
                maxiter=1000
            )
            return int(round(intersection_price))

        except (ValueError, RuntimeError) as e:
            # Fallback to midpoint if optimization fails
            print(f"Warning: Could not find exact intersection for {intersection_name}: {e}")
            return int(round((search_min + search_max) / 2))

    def _calculate_confidence_score(
        self,
        data: PriceSensitivityData,
        pmc: int,
        pme: int
    ) -> float:
        """
        Calculate confidence score for the analysis

        Factors considered:
        1. Sample size (larger = higher confidence)
        2. Price range consistency (narrower acceptable range = higher confidence)
        3. Response variance (lower variance = higher confidence)

        Returns:
            Confidence score from 0 to 1
        """
        n = len(data.too_cheap)

        # Sample size factor (asymptotic to 1 as n increases)
        # Uses formula: 1 - exp(-n/100)
        sample_factor = 1 - np.exp(-n / 100)

        # Range consistency factor
        # Narrower acceptable range indicates more agreement
        acceptable_range = pme - pmc
        median_price = (pmc + pme) / 2

        if median_price > 0:
            range_ratio = acceptable_range / median_price
            # Lower ratio = higher confidence
            range_factor = np.exp(-range_ratio)
        else:
            range_factor = 0.5

        # Variance factor
        # Calculate coefficient of variation for each price type
        cvs = []
        for prices in [data.too_cheap, data.bargain, data.expensive, data.too_expensive]:
            mean_price = np.mean(prices)
            if mean_price > 0:
                cv = np.std(prices) / mean_price
                cvs.append(cv)

        avg_cv = np.mean(cvs)
        # Lower CV = higher confidence
        variance_factor = np.exp(-avg_cv)

        # Weighted combination
        confidence = (
            0.4 * sample_factor +
            0.3 * range_factor +
            0.3 * variance_factor
        )

        return min(1.0, max(0.0, confidence))

    def _calculate_data_quality_score(self, data: PriceSensitivityData) -> float:
        """
        Calculate data quality score based on response patterns

        Checks for:
        1. Logical price ordering
        2. Absence of duplicate responses (possible bots)
        3. Reasonable price ranges
        4. Distribution normality

        Returns:
            Quality score from 0 to 1
        """
        n = len(data.too_cheap)
        quality_factors = []

        # Check 1: Logical ordering (should be 100% if validation passed)
        logical_count = 0
        for i in range(n):
            if (data.too_cheap[i] <= data.bargain[i] <=
                data.expensive[i] <= data.too_expensive[i]):
                logical_count += 1
        quality_factors.append(logical_count / n)

        # Check 2: Response uniqueness (detect potential bots/duplicates)
        all_responses = np.column_stack([
            data.too_cheap, data.bargain, data.expensive, data.too_expensive
        ])
        unique_responses = len(np.unique(all_responses, axis=0))
        uniqueness_ratio = unique_responses / n
        quality_factors.append(uniqueness_ratio)

        # Check 3: Reasonable price spread
        # Each respondent should have meaningful spread between too_cheap and too_expensive
        spreads = data.too_expensive - data.too_cheap
        median_spread = np.median(spreads)
        reasonable_spread_count = np.sum(spreads >= median_spread * 0.3)
        quality_factors.append(reasonable_spread_count / n)

        # Check 4: Distribution shape (should be roughly normal)
        # Use Shapiro-Wilk test approximation
        from scipy.stats import shapiro
        try:
            normality_scores = []
            for prices in [data.too_cheap, data.bargain, data.expensive, data.too_expensive]:
                if len(prices) >= 3:
                    _, p_value = shapiro(prices)
                    # Higher p-value = more normal (0.05 threshold)
                    normality_scores.append(min(1.0, p_value * 10))

            if normality_scores:
                quality_factors.append(np.mean(normality_scores))
        except Exception:
            # If normality test fails, assume moderate quality
            quality_factors.append(0.7)

        # Calculate weighted average
        return np.mean(quality_factors)

    def _calculate_recommended_price(
        self,
        pmc: int,
        pme: int,
        opp: int,
        ipp: int,
        median: int
    ) -> int:
        """
        Determine recommended price based on Van Westendorp analysis

        Strategy:
        1. Start with the Indifference Price Point (IPP) as baseline
        2. Adjust based on optimal price point (OPP)
        3. Ensure it falls within acceptable range (PMC to PME)
        4. Consider median for validation

        Returns:
            Recommended price in cents
        """
        # Primary recommendation: Use IPP as it represents maximum market size
        recommended = ipp

        # Adjustment factor based on OPP
        # If OPP is significantly different from IPP, blend them
        if abs(opp - ipp) > (pme - pmc) * 0.2:
            recommended = int(0.6 * ipp + 0.4 * opp)

        # Ensure recommendation is within acceptable range
        recommended = max(pmc, min(recommended, pme))

        # Final sanity check against median
        # If recommendation is far from median, pull it closer
        if abs(recommended - median) > (pme - pmc) * 0.5:
            recommended = int(0.7 * recommended + 0.3 * median)

        return recommended

    def _serialize_curves(
        self,
        price_range: np.ndarray,
        curves: Dict[str, np.ndarray]
    ) -> Dict[str, List[Tuple[int, float]]]:
        """
        Serialize curve data for JSON storage and visualization

        Downsamples curves to 100 points for efficiency

        Returns:
            Dictionary of curve name to list of (price, percentage) tuples
        """
        # Downsample to 100 points for efficiency
        sample_indices = np.linspace(0, len(price_range) - 1, 100, dtype=int)

        serialized = {}
        for curve_name, curve_values in curves.items():
            points = [
                (int(price_range[i]), round(float(curve_values[i]), 4))
                for i in sample_indices
            ]
            serialized[curve_name] = points

        return serialized


# =============================================================================
# Example Usage and Testing
# =============================================================================

if __name__ == "__main__":
    """
    Example usage with test data

    Expected Results:
    - PMC: ~$5-7
    - PME: ~$18-22
    - OPP: ~$10-12
    - IPP: ~$8-10
    - Recommended: ~$9-11
    """

    # Generate synthetic test data
    np.random.seed(42)
    n_responses = 100

    # Simulate realistic price distributions (in cents)
    too_cheap = np.random.gamma(2, 250, n_responses).astype(int)  # Mean ~$5
    bargain = too_cheap + np.random.gamma(2, 200, n_responses).astype(int)  # Mean ~$9
    expensive = bargain + np.random.gamma(2, 300, n_responses).astype(int)  # Mean ~$15
    too_expensive = expensive + np.random.gamma(2, 250, n_responses).astype(int)  # Mean ~$20

    # Create data object
    data = PriceSensitivityData(
        too_cheap=too_cheap,
        bargain=bargain,
        expensive=expensive,
        too_expensive=too_expensive
    )

    # Run analysis
    analyzer = VanWestendorpAnalyzer()
    results = analyzer.analyze(data)

    # Print results
    print("=" * 80)
    print("VAN WESTENDORP PRICE SENSITIVITY METER - ANALYSIS RESULTS")
    print("=" * 80)
    print(f"\nSample Size: {results.sample_size}")
    print(f"Confidence Score: {results.confidence_score:.2%}")
    print(f"Data Quality Score: {results.data_quality_score:.2%}")
    print("\n" + "-" * 80)
    print("KEY PRICE POINTS:")
    print("-" * 80)
    print(f"Point of Marginal Cheapness (PMC):      ${results.point_of_marginal_cheapness/100:>8.2f}")
    print(f"Indifference Price Point (IPP):         ${results.indifference_price_point/100:>8.2f}")
    print(f"Optimal Price Point (OPP):              ${results.optimal_price_point/100:>8.2f}")
    print(f"Point of Marginal Expensiveness (PME):  ${results.point_of_marginal_expensiveness/100:>8.2f}")
    print("\n" + "-" * 80)
    print("ACCEPTABLE PRICE RANGE:")
    print("-" * 80)
    print(f"Lower Bound (PMC): ${results.acceptable_range_lower/100:.2f}")
    print(f"Upper Bound (PME): ${results.acceptable_range_upper/100:.2f}")
    print(f"Range Width: ${(results.acceptable_range_upper - results.acceptable_range_lower)/100:.2f}")
    print("\n" + "-" * 80)
    print("RECOMMENDED PRICING:")
    print("-" * 80)
    print(f"Recommended Price: ${results.recommended_price/100:.2f}")
    print("\n" + "-" * 80)
    print("STATISTICAL MEASURES:")
    print("-" * 80)
    print(f"Median Acceptable Price: ${results.median_acceptable/100:.2f}")
    print(f"Mean Acceptable Price:   ${results.mean_acceptable/100:.2f}")
    print(f"Standard Deviation:      ${results.std_dev/100:.2f}")
    print("\n" + "=" * 80)

    # Export to JSON
    print("\nJSON Export:")
    print(results.to_json())
