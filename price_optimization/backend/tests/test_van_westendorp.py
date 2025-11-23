"""
Unit tests for Van Westendorp Price Sensitivity Meter
"""

import pytest
import numpy as np
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from analysis.van_westendorp import (
    PriceSensitivityData,
    VanWestendorpAnalyzer,
    VanWestendorpResults
)


class TestPriceSensitivityData:
    """Test PriceSensitivityData validation"""

    def test_valid_data(self):
        """Test valid price sensitivity data"""
        data = PriceSensitivityData(
            too_cheap=np.array([500, 600, 550]),
            bargain=np.array([800, 900, 850]),
            expensive=np.array([1500, 1600, 1550]),
            too_expensive=np.array([2000, 2200, 2100])
        )
        assert len(data.too_cheap) == 3

    def test_invalid_array_lengths(self):
        """Test that mismatched array lengths raise ValueError"""
        with pytest.raises(ValueError, match="same length"):
            PriceSensitivityData(
                too_cheap=np.array([500, 600]),
                bargain=np.array([800, 900, 850]),  # Different length
                expensive=np.array([1500, 1600]),
                too_expensive=np.array([2000, 2200])
            )

    def test_minimum_sample_size(self):
        """Test that less than 10 responses raises ValueError"""
        with pytest.raises(ValueError, match="Minimum 10 responses"):
            PriceSensitivityData(
                too_cheap=np.array([500]),
                bargain=np.array([800]),
                expensive=np.array([1500]),
                too_expensive=np.array([2000])
            )

    def test_invalid_price_ordering(self):
        """Test that invalid price ordering raises ValueError"""
        with pytest.raises(ValueError, match="Invalid price ordering"):
            PriceSensitivityData(
                too_cheap=np.array([1000] * 10),  # Too cheap > bargain (invalid)
                bargain=np.array([800] * 10),
                expensive=np.array([1500] * 10),
                too_expensive=np.array([2000] * 10)
            )


class TestVanWestendorpAnalyzer:
    """Test Van Westendorp analyzer functionality"""

    @pytest.fixture
    def sample_data(self):
        """Generate sample data for testing"""
        np.random.seed(42)
        n = 100

        too_cheap = np.random.gamma(2, 250, n).astype(int)
        bargain = too_cheap + np.random.gamma(2, 200, n).astype(int)
        expensive = bargain + np.random.gamma(2, 300, n).astype(int)
        too_expensive = expensive + np.random.gamma(2, 250, n).astype(int)

        return PriceSensitivityData(
            too_cheap=too_cheap,
            bargain=bargain,
            expensive=expensive,
            too_expensive=too_expensive
        )

    def test_analyzer_initialization(self):
        """Test analyzer initialization"""
        analyzer = VanWestendorpAnalyzer()
        assert analyzer.interpolation_method == 'linear'
        assert analyzer.num_price_points == 10000

    def test_analyze_returns_results(self, sample_data):
        """Test that analyze returns VanWestendorpResults"""
        analyzer = VanWestendorpAnalyzer()
        results = analyzer.analyze(sample_data)
        assert isinstance(results, VanWestendorpResults)

    def test_price_points_logical_order(self, sample_data):
        """Test that key price points are in logical order"""
        analyzer = VanWestendorpAnalyzer()
        results = analyzer.analyze(sample_data)

        # PMC should be less than PME
        assert results.point_of_marginal_cheapness < results.point_of_marginal_expensiveness

        # Acceptable range should be between PMC and PME
        assert results.acceptable_range_lower == results.point_of_marginal_cheapness
        assert results.acceptable_range_upper == results.point_of_marginal_expensiveness

        # Recommended price should be within acceptable range
        assert results.acceptable_range_lower <= results.recommended_price <= results.acceptable_range_upper

    def test_confidence_scores_valid_range(self, sample_data):
        """Test that confidence scores are between 0 and 1"""
        analyzer = VanWestendorpAnalyzer()
        results = analyzer.analyze(sample_data)

        assert 0 <= results.confidence_score <= 1
        assert 0 <= results.data_quality_score <= 1

    def test_sample_size_recorded(self, sample_data):
        """Test that sample size is correctly recorded"""
        analyzer = VanWestendorpAnalyzer()
        results = analyzer.analyze(sample_data)

        assert results.sample_size == len(sample_data.too_cheap)

    def test_cumulative_curves_structure(self, sample_data):
        """Test that cumulative curves are properly structured"""
        analyzer = VanWestendorpAnalyzer()
        results = analyzer.analyze(sample_data)

        # Should have all four curves
        assert 'too_cheap' in results.cumulative_curves
        assert 'bargain' in results.cumulative_curves
        assert 'expensive' in results.cumulative_curves
        assert 'too_expensive' in results.cumulative_curves

        # Each curve should have 100 points (downsampled)
        for curve in results.cumulative_curves.values():
            assert len(curve) == 100
            # Each point is (price, percentage)
            assert all(len(point) == 2 for point in curve)

    def test_to_dict_serialization(self, sample_data):
        """Test that results can be serialized to dict"""
        analyzer = VanWestendorpAnalyzer()
        results = analyzer.analyze(sample_data)

        result_dict = results.to_dict()

        assert isinstance(result_dict, dict)
        assert 'point_of_marginal_cheapness' in result_dict
        assert 'recommended_price' in result_dict
        assert 'confidence_score' in result_dict
        assert isinstance(result_dict['sample_size'], int)

    def test_to_json_valid(self, sample_data):
        """Test that results can be serialized to JSON"""
        analyzer = VanWestendorpAnalyzer()
        results = analyzer.analyze(sample_data)

        import json
        json_str = results.to_json()
        parsed = json.loads(json_str)

        assert isinstance(parsed, dict)
        assert parsed['algorithm_version'] == '1.0.0'


class TestEdgeCases:
    """Test edge cases and boundary conditions"""

    def test_identical_responses(self):
        """Test with all identical responses"""
        # All respondents give same answers
        data = PriceSensitivityData(
            too_cheap=np.array([500] * 10),
            bargain=np.array([800] * 10),
            expensive=np.array([1500] * 10),
            too_expensive=np.array([2000] * 10)
        )

        analyzer = VanWestendorpAnalyzer()
        results = analyzer.analyze(data)

        # Should still produce results
        assert results.recommended_price > 0
        # But confidence might be lower due to no variation
        assert 0 <= results.confidence_score <= 1

    def test_wide_price_range(self):
        """Test with very wide price range"""
        np.random.seed(42)
        data = PriceSensitivityData(
            too_cheap=np.random.randint(100, 1000, 50),
            bargain=np.random.randint(1000, 5000, 50),
            expensive=np.random.randint(5000, 10000, 50),
            too_expensive=np.random.randint(10000, 50000, 50)
        )

        analyzer = VanWestendorpAnalyzer()
        results = analyzer.analyze(data)

        # Should handle wide range
        assert results.recommended_price > 0
        assert results.acceptable_range_upper > results.acceptable_range_lower


# Performance benchmarks
class TestPerformance:
    """Performance benchmarks"""

    @pytest.mark.benchmark
    def test_analyze_performance_100_responses(self, benchmark):
        """Benchmark analysis with 100 responses"""
        np.random.seed(42)
        n = 100

        too_cheap = np.random.gamma(2, 250, n).astype(int)
        bargain = too_cheap + np.random.gamma(2, 200, n).astype(int)
        expensive = bargain + np.random.gamma(2, 300, n).astype(int)
        too_expensive = expensive + np.random.gamma(2, 250, n).astype(int)

        data = PriceSensitivityData(
            too_cheap=too_cheap,
            bargain=bargain,
            expensive=expensive,
            too_expensive=too_expensive
        )

        analyzer = VanWestendorpAnalyzer()

        # Should complete in under 1 second
        result = benchmark(analyzer.analyze, data)
        assert result.recommended_price > 0


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--tb=short'])
