"""
Multi-Segment Price Optimization Analysis
Runs comprehensive pricing analysis across 50+ market segments with
detailed reports, revenue projections, and competitive analysis.
"""

import numpy as np
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, field
import json
from datetime import datetime
import warnings

from van_westendorp import (
    PriceSensitivityData,
    VanWestendorpAnalyzer,
    PriceElasticityCalculator
)
from revenue_optimization import (
    RevenueFunction,
    GradientDescentOptimizer,
    OptimizationConfig,
    PricingCliffDetector
)
from ab_testing import StatisticalPowerCalculator


@dataclass
class MarketCondition:
    """Market condition scenario."""
    name: str
    demand_multiplier: float
    elasticity_adjustment: float
    volatility: float

    BULL = None  # Will be set below
    BASE = None
    BEAR = None


# Define standard market conditions
MarketCondition.BULL = MarketCondition("bull", 1.3, 0.1, 0.08)
MarketCondition.BASE = MarketCondition("base", 1.0, 0.0, 0.12)
MarketCondition.BEAR = MarketCondition("bear", 0.7, -0.15, 0.20)


@dataclass
class ProductTier:
    """Product tier configuration."""
    name: str
    base_price: float
    typical_elasticity: float
    variable_cost: float
    fixed_cost: float


@dataclass
class MarketSegment:
    """Market segment definition."""
    id: str
    name: str
    description: str
    size: int  # Number of potential customers
    base_conversion_rate: float
    price_sensitivity: float  # -1 to 1, higher means more sensitive
    growth_rate: float
    geographic_region: str
    industry: str


@dataclass
class CompetitorPrice:
    """Competitor pricing information."""
    competitor_name: str
    price: float
    market_share: float
    feature_score: float  # 0-100


@dataclass
class OptimalPricing:
    """Optimal pricing recommendation for a tier."""
    tier_name: str
    optimal_price: float
    expected_demand: float
    expected_revenue: float
    expected_profit: float
    confidence_interval_95: Tuple[float, float]
    pricing_cliffs: List[Dict[str, Any]]


@dataclass
class SegmentAnalysisReport:
    """Comprehensive analysis report for a market segment."""
    segment: MarketSegment
    analysis_timestamp: str

    # Pricing recommendations by tier
    tier_pricing: Dict[str, OptimalPricing]

    # Market condition scenarios
    bull_scenario: Dict[str, Any]
    base_scenario: Dict[str, Any]
    bear_scenario: Dict[str, Any]

    # Competitive analysis
    competitive_positioning: Dict[str, Any]
    price_gaps: Dict[str, float]

    # Sensitivity analysis
    sensitivity_results: Dict[str, Any]

    # Risk assessment
    risk_score: float  # 0-100
    risk_factors: List[str]
    mitigation_strategies: List[str]

    # Implementation
    implementation_timeline: Dict[str, str]
    resource_requirements: Dict[str, Any]
    budget_estimate: float

    # KPIs and monitoring
    kpi_targets: Dict[str, float]
    monitoring_alerts: List[Dict[str, str]]

    def to_dict(self) -> Dict[str, Any]:
        """Convert report to dictionary for serialization."""
        return {
            'segment': {
                'id': self.segment.id,
                'name': self.segment.name,
                'description': self.segment.description,
                'size': self.segment.size,
                'base_conversion_rate': self.segment.base_conversion_rate,
                'price_sensitivity': self.segment.price_sensitivity,
                'growth_rate': self.segment.growth_rate,
                'geographic_region': self.segment.geographic_region,
                'industry': self.segment.industry
            },
            'analysis_timestamp': self.analysis_timestamp,
            'tier_pricing': {
                tier: {
                    'optimal_price': pricing.optimal_price,
                    'expected_demand': pricing.expected_demand,
                    'expected_revenue': pricing.expected_revenue,
                    'expected_profit': pricing.expected_profit,
                    'confidence_interval_95': pricing.confidence_interval_95,
                    'pricing_cliffs': pricing.pricing_cliffs
                }
                for tier, pricing in self.tier_pricing.items()
            },
            'bull_scenario': self.bull_scenario,
            'base_scenario': self.base_scenario,
            'bear_scenario': self.bear_scenario,
            'competitive_positioning': self.competitive_positioning,
            'price_gaps': self.price_gaps,
            'sensitivity_results': self.sensitivity_results,
            'risk_score': round(self.risk_score, 2),
            'risk_factors': self.risk_factors,
            'mitigation_strategies': self.mitigation_strategies,
            'implementation_timeline': self.implementation_timeline,
            'resource_requirements': self.resource_requirements,
            'budget_estimate': round(self.budget_estimate, 2),
            'kpi_targets': self.kpi_targets,
            'monitoring_alerts': self.monitoring_alerts
        }


class MultiSegmentAnalyzer:
    """
    Analyze pricing across multiple market segments with comprehensive reporting.
    """

    def __init__(self):
        """Initialize analyzer with standard configurations."""
        # Define standard product tiers
        self.product_tiers = {
            'free': ProductTier('free', 0.0, -0.5, 0, 5000),
            'basic': ProductTier('basic', 29.0, -1.2, 5, 10000),
            'professional': ProductTier('professional', 299.0, -1.5, 50, 25000),
            'enterprise': ProductTier('enterprise', 999.0, -1.8, 150, 50000),
            'premium': ProductTier('premium', 1999.0, -2.0, 300, 100000)
        }

        # Analysis components
        self.vw_analyzer = VanWestendorpAnalyzer(num_price_points=10000)
        self.elasticity_calc = PriceElasticityCalculator()
        self.optimizer = GradientDescentOptimizer(OptimizationConfig(
            learning_rate=0.5,
            max_iterations=10000,
            tolerance=1e-7,
            adaptive_learning=True
        ))
        self.cliff_detector = PricingCliffDetector(sensitivity_threshold=0.08)
        self.power_calc = StatisticalPowerCalculator()

    def analyze_segment(self,
                       segment: MarketSegment,
                       tier_name: str,
                       competitors: List[CompetitorPrice],
                       survey_data: Optional[PriceSensitivityData] = None) -> SegmentAnalysisReport:
        """
        Perform comprehensive pricing analysis for a market segment.

        Args:
            segment: Market segment to analyze
            tier_name: Product tier to analyze
            competitors: List of competitor prices
            survey_data: Optional survey data (will generate if None)

        Returns:
            Comprehensive analysis report
        """
        tier = self.product_tiers[tier_name]

        # Generate or use survey data
        if survey_data is None:
            survey_data = self._generate_synthetic_survey_data(segment, tier)

        # Step 1: Van Westendorp analysis
        vw_results = self.vw_analyzer.analyze(survey_data)

        # Step 2: Optimize pricing for each market condition
        bull_results = self._analyze_market_condition(
            segment, tier, vw_results.optimal_price_point,
            MarketCondition.BULL
        )

        base_results = self._analyze_market_condition(
            segment, tier, vw_results.optimal_price_point,
            MarketCondition.BASE
        )

        bear_results = self._analyze_market_condition(
            segment, tier, vw_results.optimal_price_point,
            MarketCondition.BEAR
        )

        # Step 3: Competitive analysis
        competitive_analysis = self._analyze_competition(
            vw_results.optimal_price_point,
            competitors
        )

        # Step 4: Sensitivity analysis
        sensitivity = self._perform_sensitivity_analysis(
            segment, tier, vw_results.optimal_price_point
        )

        # Step 5: Risk assessment
        risk_score, risk_factors, mitigations = self._assess_risk(
            segment, tier, vw_results, competitive_analysis
        )

        # Step 6: Implementation plan
        timeline = self._generate_implementation_timeline(segment, tier)
        resources = self._estimate_resources(segment)
        budget = self._estimate_budget(segment, tier)

        # Step 7: KPIs and monitoring
        kpis = self._define_kpis(segment, tier, base_results)
        alerts = self._generate_alert_conditions(segment, tier)

        # Step 8: Detect pricing cliffs
        revenue_func = self._create_revenue_function(segment, tier, MarketCondition.BASE)
        cliffs = self.cliff_detector.detect_cliffs(
            revenue_func,
            price_range=(vw_results.acceptable_range_min,
                        vw_results.acceptable_range_max),
            num_points=2000
        )

        # Create optimal pricing for this tier
        optimal_pricing = OptimalPricing(
            tier_name=tier_name,
            optimal_price=vw_results.optimal_price_point,
            expected_demand=base_results['expected_demand'],
            expected_revenue=base_results['expected_revenue'],
            expected_profit=base_results['expected_profit'],
            confidence_interval_95=vw_results.confidence_interval_95,
            pricing_cliffs=[c.to_dict() for c in cliffs]
        )

        # Build comprehensive report
        report = SegmentAnalysisReport(
            segment=segment,
            analysis_timestamp=datetime.now().isoformat(),
            tier_pricing={tier_name: optimal_pricing},
            bull_scenario=bull_results,
            base_scenario=base_results,
            bear_scenario=bear_results,
            competitive_positioning=competitive_analysis,
            price_gaps={c.competitor_name: vw_results.optimal_price_point - c.price
                       for c in competitors},
            sensitivity_results=sensitivity,
            risk_score=risk_score,
            risk_factors=risk_factors,
            mitigation_strategies=mitigations,
            implementation_timeline=timeline,
            resource_requirements=resources,
            budget_estimate=budget,
            kpi_targets=kpis,
            monitoring_alerts=alerts
        )

        return report

    def _generate_synthetic_survey_data(self,
                                       segment: MarketSegment,
                                       tier: ProductTier) -> PriceSensitivityData:
        """Generate synthetic survey data based on segment characteristics."""
        n_responses = max(100, int(segment.size * 0.01))  # 1% of segment size, min 100

        # Adjust prices based on price sensitivity
        sensitivity_factor = 1 + segment.price_sensitivity * 0.3

        base = tier.base_price

        data = PriceSensitivityData(
            too_cheap=np.random.normal(
                base * 0.3 / sensitivity_factor,
                base * 0.1,
                n_responses
            ),
            cheap=np.random.normal(
                base * 0.6 / sensitivity_factor,
                base * 0.15,
                n_responses
            ),
            expensive=np.random.normal(
                base * 1.3 * sensitivity_factor,
                base * 0.2,
                n_responses
            ),
            too_expensive=np.random.normal(
                base * 2.0 * sensitivity_factor,
                base * 0.3,
                n_responses
            )
        )

        return data

    def _create_revenue_function(self,
                                segment: MarketSegment,
                                tier: ProductTier,
                                market_condition: MarketCondition) -> RevenueFunction:
        """Create revenue function for analysis."""
        base_demand = segment.size * segment.base_conversion_rate * market_condition.demand_multiplier

        adjusted_elasticity = tier.typical_elasticity + market_condition.elasticity_adjustment

        revenue_func = RevenueFunction(
            base_demand=base_demand,
            base_price=tier.base_price,
            elasticity=adjusted_elasticity,
            variable_cost=tier.variable_cost,
            fixed_cost=tier.fixed_cost
        )

        return revenue_func

    def _analyze_market_condition(self,
                                 segment: MarketSegment,
                                 tier: ProductTier,
                                 suggested_price: float,
                                 market_condition: MarketCondition) -> Dict[str, Any]:
        """Analyze pricing under specific market condition."""
        revenue_func = self._create_revenue_function(segment, tier, market_condition)

        # Optimize for this condition
        result = self.optimizer.optimize_revenue(
            revenue_func,
            initial_price=suggested_price,
            price_bounds=(tier.base_price * 0.5, tier.base_price * 2.0)
        )

        profit_result = self.optimizer.optimize_profit(
            revenue_func,
            initial_price=suggested_price,
            price_bounds=(tier.base_price * 0.5, tier.base_price * 2.0)
        )

        # Calculate metrics
        expected_demand = revenue_func.demand(result.optimal_price)
        expected_revenue = revenue_func.revenue(result.optimal_price)
        expected_profit = revenue_func.profit(profit_result.optimal_price)

        return {
            'condition': market_condition.name,
            'optimal_price': round(result.optimal_price, 2),
            'profit_optimal_price': round(profit_result.optimal_price, 2),
            'expected_demand': round(expected_demand, 0),
            'expected_revenue': round(expected_revenue, 2),
            'expected_profit': round(expected_profit, 2),
            'demand_multiplier': market_condition.demand_multiplier,
            'volatility': market_condition.volatility
        }

    def _analyze_competition(self,
                            our_price: float,
                            competitors: List[CompetitorPrice]) -> Dict[str, Any]:
        """Analyze competitive positioning."""
        if not competitors:
            return {
                'positioning': 'no_competitors',
                'price_rank': 1,
                'avg_competitor_price': 0
            }

        competitor_prices = [c.price for c in competitors]
        avg_price = np.mean(competitor_prices)
        min_price = np.min(competitor_prices)
        max_price = np.max(competitor_prices)

        # Determine positioning
        if our_price < min_price:
            positioning = 'price_leader'
        elif our_price > max_price:
            positioning = 'premium'
        elif our_price < avg_price:
            positioning = 'competitive'
        else:
            positioning = 'above_average'

        # Calculate price rank (1 = cheapest)
        all_prices = competitor_prices + [our_price]
        price_rank = sorted(all_prices).index(our_price) + 1

        # Calculate weighted competitive score
        total_share = sum(c.market_share for c in competitors)
        weighted_price = sum(c.price * c.market_share for c in competitors) / total_share if total_share > 0 else avg_price

        return {
            'positioning': positioning,
            'our_price': round(our_price, 2),
            'avg_competitor_price': round(avg_price, 2),
            'weighted_competitor_price': round(weighted_price, 2),
            'min_competitor_price': round(min_price, 2),
            'max_competitor_price': round(max_price, 2),
            'price_rank': price_rank,
            'total_competitors': len(competitors),
            'price_vs_avg': round((our_price / avg_price - 1) * 100, 2)
        }

    def _perform_sensitivity_analysis(self,
                                      segment: MarketSegment,
                                      tier: ProductTier,
                                      base_price: float) -> Dict[str, Any]:
        """Perform ±10% sensitivity analysis on input parameters."""
        revenue_func = self._create_revenue_function(segment, tier, MarketCondition.BASE)

        # Base case
        base_revenue = revenue_func.revenue(base_price)

        # Vary demand ±10%
        demand_high = RevenueFunction(
            segment.size * segment.base_conversion_rate * 1.1,
            tier.base_price, tier.typical_elasticity,
            tier.variable_cost, tier.fixed_cost
        )
        demand_low = RevenueFunction(
            segment.size * segment.base_conversion_rate * 0.9,
            tier.base_price, tier.typical_elasticity,
            tier.variable_cost, tier.fixed_cost
        )

        # Vary elasticity ±10%
        elasticity_less = RevenueFunction(
            segment.size * segment.base_conversion_rate,
            tier.base_price, tier.typical_elasticity * 1.1,
            tier.variable_cost, tier.fixed_cost
        )
        elasticity_more = RevenueFunction(
            segment.size * segment.base_conversion_rate,
            tier.base_price, tier.typical_elasticity * 0.9,
            tier.variable_cost, tier.fixed_cost
        )

        return {
            'base_revenue': round(base_revenue, 2),
            'demand_+10%': round(demand_high.revenue(base_price), 2),
            'demand_-10%': round(demand_low.revenue(base_price), 2),
            'demand_sensitivity_%': round(
                (demand_high.revenue(base_price) - demand_low.revenue(base_price)) / base_revenue * 50, 2
            ),
            'elasticity_+10%': round(elasticity_less.revenue(base_price), 2),
            'elasticity_-10%': round(elasticity_more.revenue(base_price), 2),
            'elasticity_sensitivity_%': round(
                (elasticity_more.revenue(base_price) - elasticity_less.revenue(base_price)) / base_revenue * 50, 2
            )
        }

    def _assess_risk(self,
                    segment: MarketSegment,
                    tier: ProductTier,
                    vw_results: Any,
                    competitive_analysis: Dict[str, Any]) -> Tuple[float, List[str], List[str]]:
        """Assess pricing risk and generate mitigation strategies."""
        risk_factors = []
        risk_score = 0

        # Check price sensitivity
        price_range_pct = (vw_results.acceptable_range_max - vw_results.acceptable_range_min) / vw_results.optimal_price_point

        if price_range_pct < 0.3:
            risk_factors.append("Narrow acceptable price range indicates high price sensitivity")
            risk_score += 20

        # Check segment size
        if segment.size < 1000:
            risk_factors.append("Small segment size increases revenue volatility")
            risk_score += 15

        # Check conversion rate
        if segment.base_conversion_rate < 0.05:
            risk_factors.append("Low baseline conversion rate")
            risk_score += 15

        # Check competitive positioning
        if competitive_analysis['positioning'] == 'premium':
            risk_factors.append("Premium positioning requires strong value proposition")
            risk_score += 10

        # Check market growth
        if segment.growth_rate < 0:
            risk_factors.append("Negative market growth")
            risk_score += 25

        # Generate mitigations
        mitigations = []
        if price_range_pct < 0.3:
            mitigations.append("Conduct thorough A/B testing before full rollout")
            mitigations.append("Implement gradual price adjustments")

        if segment.size < 1000:
            mitigations.append("Focus on customer retention to stabilize revenue")

        if competitive_analysis['positioning'] == 'premium':
            mitigations.append("Emphasize unique value propositions in marketing")
            mitigations.append("Consider feature bundling to justify premium price")

        if not mitigations:
            mitigations.append("Monitor KPIs closely during initial rollout")

        return min(risk_score, 100), risk_factors, mitigations

    def _generate_implementation_timeline(self,
                                         segment: MarketSegment,
                                         tier: ProductTier) -> Dict[str, str]:
        """Generate implementation timeline."""
        return {
            'week_1': 'Finalize pricing strategy and obtain approvals',
            'week_2': 'Set up A/B testing infrastructure',
            'week_3-4': 'Run initial A/B test with 10% of traffic',
            'week_5': 'Analyze test results and adjust if needed',
            'week_6': 'Gradual rollout to 50% of segment',
            'week_7-8': 'Monitor performance and adjust',
            'week_9': 'Full rollout to entire segment',
            'week_10+': 'Ongoing monitoring and quarterly re-optimization'
        }

    def _estimate_resources(self, segment: MarketSegment) -> Dict[str, Any]:
        """Estimate resource requirements."""
        return {
            'engineering': '1 engineer for 2 weeks (testing infrastructure)',
            'data_analysis': '1 analyst for 4 weeks (monitoring and analysis)',
            'product_management': '0.5 PM for 8 weeks',
            'marketing': '1 marketer for 2 weeks (messaging updates)',
            'legal_compliance': '0.25 legal for 1 week (pricing compliance review)'
        }

    def _estimate_budget(self, segment: MarketSegment, tier: ProductTier) -> float:
        """Estimate implementation budget."""
        # Base costs
        testing_infrastructure = 5000
        analytics_tools = 2000
        personnel_cost = 35000  # Average blended rate

        # Additional costs based on segment size
        if segment.size > 10000:
            personnel_cost *= 1.5

        return testing_infrastructure + analytics_tools + personnel_cost

    def _define_kpis(self,
                    segment: MarketSegment,
                    tier: ProductTier,
                    base_scenario: Dict[str, Any]) -> Dict[str, float]:
        """Define KPI targets."""
        return {
            'revenue_target_monthly': round(base_scenario['expected_revenue'] * 30, 2),
            'conversion_rate_target': round(segment.base_conversion_rate, 4),
            'customer_acquisition_cost_max': round(tier.base_price * 0.3, 2),
            'churn_rate_max': 0.05,
            'net_revenue_retention_min': 1.0,
            'gross_margin_min': round((tier.base_price - tier.variable_cost) / tier.base_price, 2)
        }

    def _generate_alert_conditions(self,
                                   segment: MarketSegment,
                                   tier: ProductTier) -> List[Dict[str, str]]:
        """Generate monitoring alert conditions."""
        return [
            {
                'metric': 'conversion_rate',
                'condition': f'< {segment.base_conversion_rate * 0.9}',
                'severity': 'warning',
                'action': 'Review pricing and messaging'
            },
            {
                'metric': 'daily_revenue',
                'condition': '7-day MA < 30-day MA by >10%',
                'severity': 'critical',
                'action': 'Initiate pricing review'
            },
            {
                'metric': 'churn_rate',
                'condition': '> 7%',
                'severity': 'warning',
                'action': 'Conduct customer surveys'
            },
            {
                'metric': 'competitor_price_change',
                'condition': 'Change > ±10%',
                'severity': 'info',
                'action': 'Review competitive positioning'
            }
        ]


# Example usage demonstration
if __name__ == "__main__":
    print("=== Multi-Segment Price Optimization Analysis ===\n")

    # Initialize analyzer
    analyzer = MultiSegmentAnalyzer()

    # Define a sample segment
    segment = MarketSegment(
        id="seg_001",
        name="enterprise_tech",
        description="Large technology companies requiring secure secret sharing",
        size=5000,
        base_conversion_rate=0.12,
        price_sensitivity=0.3,
        growth_rate=0.15,
        geographic_region="north_america",
        industry="technology"
    )

    # Define competitors
    competitors = [
        CompetitorPrice("SecretVault Pro", 499.99, 0.15, 75),
        CompetitorPrice("ConfidentialShare", 699.99, 0.22, 82),
        CompetitorPrice("SecurePass", 399.99, 0.08, 68)
    ]

    # Run analysis
    print(f"Analyzing segment: {segment.name}")
    report = analyzer.analyze_segment(
        segment=segment,
        tier_name='enterprise',
        competitors=competitors
    )

    # Display results
    print(f"\nAnalysis completed at: {report.analysis_timestamp}")
    print(f"\nOptimal Pricing for Enterprise Tier:")
    enterprise_pricing = report.tier_pricing['enterprise']
    print(f"  Price: ${enterprise_pricing.optimal_price:.2f}")
    print(f"  Expected Monthly Revenue: ${enterprise_pricing.expected_revenue * 30:.2f}")
    print(f"  Expected Monthly Profit: ${enterprise_pricing.expected_profit * 30:.2f}")
    print(f"  95% CI: ${enterprise_pricing.confidence_interval_95[0]:.2f} - ${enterprise_pricing.confidence_interval_95[1]:.2f}")

    print(f"\nMarket Scenarios:")
    print(f"  Bull: ${report.bull_scenario['optimal_price']:.2f} (Revenue: ${report.bull_scenario['expected_revenue'] * 30:.2f}/mo)")
    print(f"  Base: ${report.base_scenario['optimal_price']:.2f} (Revenue: ${report.base_scenario['expected_revenue'] * 30:.2f}/mo)")
    print(f"  Bear: ${report.bear_scenario['optimal_price']:.2f} (Revenue: ${report.bear_scenario['expected_revenue'] * 30:.2f}/mo)")

    print(f"\nCompetitive Positioning: {report.competitive_positioning['positioning']}")
    print(f"  Our Price: ${report.competitive_positioning['our_price']:.2f}")
    print(f"  Avg Competitor: ${report.competitive_positioning['avg_competitor_price']:.2f}")
    print(f"  vs Average: {report.competitive_positioning['price_vs_avg']:+.1f}%")

    print(f"\nRisk Assessment:")
    print(f"  Risk Score: {report.risk_score:.0f}/100")
    if report.risk_factors:
        print(f"  Risk Factors:")
        for factor in report.risk_factors:
            print(f"    - {factor}")

    print(f"\nImplementation:")
    print(f"  Budget Estimate: ${report.budget_estimate:,.2f}")
    print(f"  Timeline: 10 weeks to full rollout")

    # Export to JSON
    report_dict = report.to_dict()
    output_file = f"segment_analysis_{segment.id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"

    with open(output_file, 'w') as f:
        json.dump(report_dict, f, indent=2)

    print(f"\nFull report exported to: {output_file}")
