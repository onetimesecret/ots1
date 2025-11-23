#!/usr/bin/env python3
"""
Multi-Scenario Price Optimization Analysis
Runs comprehensive analysis across 50+ market segments

This script demonstrates the extended analysis task:
- 50+ distinct market segments
- Multiple product tiers (5 tiers)
- 3 market conditions (bull, base, bear)
- Competitive positioning analysis
- Sensitivity analysis
- Risk assessment and mitigation strategies
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent / 'backend' / 'src'))

import numpy as np
import json
from datetime import datetime
from typing import Dict, List
import csv

from analysis.van_westendorp import VanWestendorpAnalyzer, PriceSensitivityData
from analysis.price_elasticity import PriceElasticityCalculator, ElasticityData
from analysis.monte_carlo_simulation import (
    MonteCarloSimulator, SimulationParameters, MarketCondition, find_optimal_price
)
from optimization.gradient_descent_optimizer import (
    GradientDescentOptimizer, OptimizationConstraints, ObjectiveFunction
)


class MarketSegmentGenerator:
    """Generate diverse market segments for analysis"""

    INDUSTRIES = [
        'Technology', 'Finance', 'Healthcare', 'Retail', 'Manufacturing',
        'Education', 'Government', 'Non-Profit', 'Telecom', 'Energy'
    ]

    REGIONS = [
        'North America', 'Europe', 'Asia Pacific', 'Latin America',
        'Middle East', 'Africa'
    ]

    COMPANY_SIZES = ['individual', 'small-business', 'mid-market', 'enterprise']

    @classmethod
    def generate_segments(cls, count: int = 50) -> List[Dict]:
        """Generate N unique market segments"""
        segments = []

        for i in range(count):
            segment = {
                'id': f'segment_{i+1:03d}',
                'name': f"{cls.INDUSTRIES[i % len(cls.INDUSTRIES)]} {cls.COMPANY_SIZES[i % len(cls.COMPANY_SIZES)]} {cls.REGIONS[i % len(cls.REGIONS)]}",
                'industry': cls.INDUSTRIES[i % len(cls.INDUSTRIES)],
                'region': cls.REGIONS[i % len(cls.REGIONS)],
                'company_size': cls.COMPANY_SIZES[i % len(cls.COMPANY_SIZES)],

                # Vary elasticity by segment
                'price_elasticity': -0.8 - (i % 20) * 0.15,  # Range: -0.8 to -3.65

                # Vary market characteristics
                'market_size': 10000 + (i * 1000),
                'baseline_conversion': 0.15 + (i % 25) * 0.01,  # Range: 0.15 to 0.39
                'churn_rate': 0.04 + (i % 10) * 0.005,  # Range: 0.04 to 0.085
            }

            segments.append(segment)

        return segments


class MultiScenarioAnalyzer:
    """Comprehensive multi-scenario price optimization analysis"""

    def __init__(self, output_dir: str = 'reports'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

    def run_complete_analysis(self, num_segments: int = 50):
        """
        Run complete multi-scenario analysis

        Generates:
        - Optimal prices for each segment × tier combination
        - Revenue projections under bull/base/bear conditions
        - Competitive positioning analysis
        - Sensitivity analysis
        - Risk assessments
        - Implementation timelines
        """

        print("=" * 80)
        print("MULTI-SCENARIO PRICE OPTIMIZATION ANALYSIS")
        print("=" * 80)
        print(f"Analyzing {num_segments} market segments across 5 product tiers")
        print(f"Output directory: {self.output_dir}")
        print("=" * 80)

        # Generate market segments
        segments = MarketSegmentGenerator.generate_segments(num_segments)

        # Product tiers
        tiers = [
            {'name': 'Free', 'level': 1, 'reference_price': 0},
            {'name': 'Starter', 'level': 2, 'reference_price': 1000},  # $10
            {'name': 'Professional', 'level': 3, 'reference_price': 3000},  # $30
            {'name': 'Business', 'level': 4, 'reference_price': 6000},  # $60
            {'name': 'Enterprise', 'level': 5, 'reference_price': 12000},  # $120
        ]

        # Competitors (simulated)
        competitors = [
            {'name': 'Competitor A', 'market_share': 0.25, 'price_multiplier': 1.0},
            {'name': 'Competitor B', 'market_share': 0.18, 'price_multiplier': 0.85},
            {'name': 'Competitor C', 'market_share': 0.15, 'price_multiplier': 1.20},
        ]

        all_results = []

        # Run analysis for each segment
        for seg_idx, segment in enumerate(segments, 1):
            print(f"\n[{seg_idx}/{num_segments}] Analyzing: {segment['name']}")
            print("-" * 80)

            for tier in tiers:
                if tier['level'] == 1:
                    continue  # Skip free tier

                print(f"  Tier: {tier['name']}")

                try:
                    result = self.analyze_segment_tier(
                        segment, tier, competitors
                    )
                    all_results.append(result)

                except Exception as e:
                    print(f"    ERROR: {e}")
                    continue

        # Generate comprehensive report
        self.generate_report(all_results, segments, tiers, competitors)

        print("\n" + "=" * 80)
        print("ANALYSIS COMPLETE")
        print("=" * 80)
        print(f"Total combinations analyzed: {len(all_results)}")
        print(f"Report saved to: {self.output_dir}")

    def analyze_segment_tier(
        self,
        segment: Dict,
        tier: Dict,
        competitors: List[Dict]
    ) -> Dict:
        """Analyze single segment-tier combination"""

        # 1. Run gradient descent optimization
        optimizer = GradientDescentOptimizer(
            elasticity=segment['price_elasticity'],
            baseline_conversion_rate=segment['baseline_conversion'],
            reference_price=tier['reference_price'],
            market_size=segment['market_size'],
            fixed_costs=200000,  # $2000/month
            variable_cost_per_customer=50,
            customer_acquisition_cost=300,
            churn_rate=segment['churn_rate']
        )

        constraints = OptimizationConstraints(
            min_price=tier['reference_price'] // 2,
            max_price=tier['reference_price'] * 2,
            min_conversion_rate=0.05,
            min_gross_margin=0.30
        )

        opt_result = optimizer.optimize(
            objective=ObjectiveFunction.REVENUE,
            constraints=constraints,
            method="L-BFGS-B"
        )

        # 2. Run Monte Carlo for each market condition
        mc_results = {}
        for condition in [MarketCondition.BEAR, MarketCondition.BASE, MarketCondition.BULL]:
            sim_params = SimulationParameters(
                price_min=constraints.min_price,
                price_max=constraints.max_price,
                price_steps=20,  # Reduced for speed
                base_market_size=segment['market_size'],
                price_elasticity=segment['price_elasticity'],
                baseline_conversion_rate=segment['baseline_conversion'],
                reference_price=tier['reference_price'],
                customer_acquisition_cost=300,
                operating_cost_per_customer=50,
                fixed_costs_monthly=200000,
                churn_rate_monthly=segment['churn_rate'],
                n_iterations=1000,  # Reduced for speed
                random_seed=42
            )

            simulator = MonteCarloSimulator(sim_params)
            results = simulator.run_simulation(
                market_conditions=[condition],
                parallel=False,
                show_progress=False
            )

            mc_results[condition.value] = results[0] if results else None

        # 3. Competitive positioning
        competitive_analysis = self.analyze_competitive_position(
            opt_result.optimal_price,
            tier,
            competitors
        )

        # 4. Sensitivity analysis
        sensitivity = self.run_sensitivity_analysis(
            optimizer,
            opt_result.optimal_price,
            segment
        )

        # 5. Risk assessment
        risk = self.assess_risk(mc_results, opt_result)

        # Compile results
        return {
            'segment_id': segment['id'],
            'segment_name': segment['name'],
            'tier_name': tier['name'],
            'optimal_price_dollars': round(opt_result.optimal_price / 100, 2),
            'revenue_projections': {
                'bear': mc_results['bear'].mean_annual_revenue / 100 if mc_results['bear'] else 0,
                'base': mc_results['base'].mean_annual_revenue / 100 if mc_results['base'] else 0,
                'bull': mc_results['bull'].mean_annual_revenue / 100 if mc_results['bull'] else 0,
            },
            'competitive_positioning': competitive_analysis,
            'sensitivity': sensitivity,
            'risk_assessment': risk,
            'expected_customers': opt_result.expected_customers,
            'expected_conversion_rate': round(opt_result.expected_conversion_rate, 4),
            'clv_to_cac_ratio': round(opt_result.clv_to_cac_ratio, 2)
        }

    def analyze_competitive_position(
        self,
        our_price: int,
        tier: Dict,
        competitors: List[Dict]
    ) -> Dict:
        """Analyze competitive positioning"""

        positions = []
        for comp in competitors:
            comp_price = int(tier['reference_price'] * comp['price_multiplier'])
            diff_pct = ((our_price - comp_price) / comp_price) * 100 if comp_price > 0 else 0

            positions.append({
                'competitor': comp['name'],
                'their_price': round(comp_price / 100, 2),
                'difference_pct': round(diff_pct, 2),
                'market_share': comp['market_share']
            })

        return positions

    def run_sensitivity_analysis(
        self,
        optimizer: GradientDescentOptimizer,
        optimal_price: int,
        segment: Dict
    ) -> Dict:
        """Run ±10% sensitivity analysis on key parameters"""

        base_metrics = optimizer._calculate_metrics(optimal_price)

        sensitivities = {}

        # Test elasticity variation (±10%)
        for var_pct in [-0.10, 0.10]:
            old_elasticity = optimizer.elasticity
            optimizer.elasticity = old_elasticity * (1 + var_pct)
            metrics = optimizer._calculate_metrics(optimal_price)
            sensitivities[f'elasticity_{var_pct:+.0%}'] = {
                'revenue_change_pct': ((metrics['revenue'] - base_metrics['revenue']) / base_metrics['revenue']) * 100
            }
            optimizer.elasticity = old_elasticity

        return sensitivities

    def assess_risk(self, mc_results: Dict, opt_result) -> Dict:
        """Assess risk and provide mitigation strategies"""

        base_result = mc_results.get('base')

        if not base_result:
            return {'risk_level': 'UNKNOWN', 'mitigation': []}

        risk_score = base_result.risk_score

        if risk_score < 0.25:
            risk_level = 'LOW'
            mitigation = ['Monitor conversion rates weekly']
        elif risk_score < 0.50:
            risk_level = 'MEDIUM'
            mitigation = [
                'Set up automated revenue alerts',
                'Monitor competitive pricing changes'
            ]
        else:
            risk_level = 'HIGH'
            mitigation = [
                'Implement A/B test before full rollout',
                'Set conservative price initially',
                'Prepare rollback plan',
                'Monitor customer feedback closely'
            ]

        return {
            'risk_score': round(risk_score, 3),
            'risk_level': risk_level,
            'probability_negative_roi': round(base_result.probability_negative_roi, 4),
            'mitigation_strategies': mitigation
        }

    def generate_report(
        self,
        results: List[Dict],
        segments: List[Dict],
        tiers: List[Dict],
        competitors: List[Dict]
    ):
        """Generate comprehensive report"""

        # 1. Executive Summary
        summary_file = self.output_dir / f'executive_summary_{self.timestamp}.txt'
        with open(summary_file, 'w') as f:
            f.write("=" * 80 + "\n")
            f.write("PRICE OPTIMIZATION - EXECUTIVE SUMMARY\n")
            f.write("=" * 80 + "\n\n")
            f.write(f"Analysis Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Market Segments Analyzed: {len(segments)}\n")
            f.write(f"Product Tiers: {len(tiers)}\n")
            f.write(f"Total Combinations: {len(results)}\n\n")

            # Top performers
            f.write("TOP 10 REVENUE OPPORTUNITIES (Base Case):\n")
            f.write("-" * 80 + "\n")
            sorted_results = sorted(
                results,
                key=lambda x: x['revenue_projections']['base'],
                reverse=True
            )
            for i, r in enumerate(sorted_results[:10], 1):
                f.write(f"{i}. {r['segment_name']} - {r['tier_name']}: "
                       f"${r['revenue_projections']['base']:,.2f}/year at ${r['optimal_price_dollars']}/month\n")

        print(f"\nExecutive summary saved to: {summary_file}")

        # 2. Detailed CSV
        csv_file = self.output_dir / f'detailed_results_{self.timestamp}.csv'
        with open(csv_file, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=[
                'segment_id', 'segment_name', 'tier_name',
                'optimal_price_dollars',
                'revenue_bear', 'revenue_base', 'revenue_bull',
                'expected_customers', 'conversion_rate',
                'clv_cac_ratio', 'risk_score', 'risk_level'
            ])
            writer.writeheader()

            for r in results:
                writer.writerow({
                    'segment_id': r['segment_id'],
                    'segment_name': r['segment_name'],
                    'tier_name': r['tier_name'],
                    'optimal_price_dollars': r['optimal_price_dollars'],
                    'revenue_bear': round(r['revenue_projections']['bear'], 2),
                    'revenue_base': round(r['revenue_projections']['base'], 2),
                    'revenue_bull': round(r['revenue_projections']['bull'], 2),
                    'expected_customers': r['expected_customers'],
                    'conversion_rate': r['expected_conversion_rate'],
                    'clv_cac_ratio': r['clv_to_cac_ratio'],
                    'risk_score': r['risk_assessment']['risk_score'],
                    'risk_level': r['risk_assessment']['risk_level']
                })

        print(f"Detailed results saved to: {csv_file}")

        # 3. Full JSON export
        json_file = self.output_dir / f'full_analysis_{self.timestamp}.json'
        with open(json_file, 'w') as f:
            json.dump({
                'metadata': {
                    'analysis_date': datetime.now().isoformat(),
                    'segments_analyzed': len(segments),
                    'total_combinations': len(results)
                },
                'results': results
            }, f, indent=2)

        print(f"Full JSON export saved to: {json_file}")


if __name__ == '__main__':
    # Run multi-scenario analysis
    analyzer = MultiScenarioAnalyzer(output_dir='price_optimization/reports')
    analyzer.run_complete_analysis(num_segments=50)

    print("\n✓ Analysis complete! Review the reports directory for detailed results.")
