#!/usr/bin/env python3
"""
Monte Carlo Simulation for OneTimeSecret Pricing Strategy
Simulates revenue projections under different pricing scenarios

Usage:
    python monte_carlo_simulation.py --scenario conservative --iterations 10000
"""

import numpy as np
import pandas as pd
import argparse
from dataclasses import dataclass
from typing import List, Dict, Tuple
import json


@dataclass
class TierConfig:
    """Configuration for a pricing tier"""
    name: str
    price: float
    price_variance: float  # +/- variance for sensitivity analysis
    support_cost: float
    infrastructure_cost: float
    churn_rate_mean: float
    churn_rate_std: float


@dataclass
class CustomerCohort:
    """Represents a customer segment"""
    name: str
    initial_count: int
    target_tier: str
    migration_retention: float  # % who don't churn during migration
    upgrade_probability: float  # % who upgrade to higher tier
    downgrade_probability: float  # % who downgrade to lower tier


class PricingSimulation:
    """Monte Carlo simulation for pricing strategy"""

    def __init__(self, iterations: int = 10000, months: int = 24):
        self.iterations = iterations
        self.months = months
        self.results = []

        # Define pricing tiers
        self.tiers = {
            'individual': TierConfig(
                name='Individual',
                price=19.0,
                price_variance=2.0,
                support_cost=6.0,
                infrastructure_cost=3.0,
                churn_rate_mean=0.08,
                churn_rate_std=0.02
            ),
            'team': TierConfig(
                name='Team',
                price=79.0,
                price_variance=10.0,
                support_cost=8.0,
                infrastructure_cost=10.0,
                churn_rate_mean=0.06,
                churn_rate_std=0.015
            ),
            'enterprise': TierConfig(
                name='Enterprise',
                price=149.0,
                price_variance=20.0,
                support_cost=15.0,
                infrastructure_cost=15.0,
                churn_rate_mean=0.03,
                churn_rate_std=0.01
            ),
            'single_tenant': TierConfig(
                name='Single Tenant',
                price=799.0,
                price_variance=100.0,
                support_cost=25.0,
                infrastructure_cost=200.0,
                churn_rate_mean=0.02,
                churn_rate_std=0.005
            )
        }

        # Current state
        self.current_mrr = 8050.0  # 230 customers * $35
        self.current_customers = 230
        self.current_churn = 0.07

    def define_scenario(self, scenario: str) -> List[CustomerCohort]:
        """Define customer cohorts based on scenario"""

        if scenario == 'conservative':
            # 60% retention, moderate migrations
            cohorts = [
                CustomerCohort(
                    name='Solo Developers',
                    initial_count=58,
                    target_tier='individual',
                    migration_retention=0.92,
                    upgrade_probability=0.05,
                    downgrade_probability=0.0
                ),
                CustomerCohort(
                    name='Small Teams',
                    initial_count=104,
                    target_tier='team',
                    migration_retention=0.88,
                    upgrade_probability=0.15,
                    downgrade_probability=0.12
                ),
                CustomerCohort(
                    name='Mid-size Teams',
                    initial_count=46,
                    target_tier='enterprise',
                    migration_retention=0.91,
                    upgrade_probability=0.08,
                    downgrade_probability=0.05
                ),
                CustomerCohort(
                    name='Enterprise/Custom',
                    initial_count=23,
                    target_tier='single_tenant',
                    migration_retention=0.96,
                    upgrade_probability=0.0,
                    downgrade_probability=0.02
                )
            ]

        elif scenario == 'aggressive':
            # 75% retention, high upgrade rates
            cohorts = [
                CustomerCohort(
                    name='Solo Developers',
                    initial_count=58,
                    target_tier='individual',
                    migration_retention=0.95,
                    upgrade_probability=0.10,
                    downgrade_probability=0.0
                ),
                CustomerCohort(
                    name='Small Teams',
                    initial_count=104,
                    target_tier='team',
                    migration_retention=0.92,
                    upgrade_probability=0.25,
                    downgrade_probability=0.08
                ),
                CustomerCohort(
                    name='Mid-size Teams',
                    initial_count=46,
                    target_tier='enterprise',
                    migration_retention=0.94,
                    upgrade_probability=0.15,
                    downgrade_probability=0.03
                ),
                CustomerCohort(
                    name='Enterprise/Custom',
                    initial_count=23,
                    target_tier='single_tenant',
                    migration_retention=0.98,
                    upgrade_probability=0.0,
                    downgrade_probability=0.01
                )
            ]

        elif scenario == 'pessimistic':
            # 45% retention, high churn
            cohorts = [
                CustomerCohort(
                    name='Solo Developers',
                    initial_count=58,
                    target_tier='individual',
                    migration_retention=0.85,
                    upgrade_probability=0.02,
                    downgrade_probability=0.0
                ),
                CustomerCohort(
                    name='Small Teams',
                    initial_count=104,
                    target_tier='team',
                    migration_retention=0.75,
                    upgrade_probability=0.08,
                    downgrade_probability=0.25
                ),
                CustomerCohort(
                    name='Mid-size Teams',
                    initial_count=46,
                    target_tier='enterprise',
                    migration_retention=0.82,
                    upgrade_probability=0.05,
                    downgrade_probability=0.15
                ),
                CustomerCohort(
                    name='Enterprise/Custom',
                    initial_count=23,
                    target_tier='single_tenant',
                    migration_retention=0.91,
                    upgrade_probability=0.0,
                    downgrade_probability=0.05
                )
            ]

        else:
            raise ValueError(f"Unknown scenario: {scenario}")

        return cohorts

    def run_single_iteration(self, cohorts: List[CustomerCohort]) -> Dict:
        """Run a single Monte Carlo iteration"""

        # Initialize customer counts by tier
        customers = {tier: 0 for tier in self.tiers.keys()}
        monthly_data = []

        # Randomize tier prices for this iteration
        tier_prices = {}
        for tier_key, tier_config in self.tiers.items():
            tier_prices[tier_key] = np.random.uniform(
                tier_config.price - tier_config.price_variance,
                tier_config.price + tier_config.price_variance
            )

        # Month 0: Current state
        monthly_data.append({
            'month': 0,
            'mrr': self.current_mrr,
            'customers': self.current_customers,
            'ebitda': self.current_mrr - 9480  # Current costs
        })

        # Initial migration (Month 1-3)
        for cohort in cohorts:
            # Calculate initial tier placement
            retained = int(cohort.initial_count * cohort.migration_retention)

            # Apply upgrade/downgrade probabilities
            upgrades = int(retained * cohort.upgrade_probability)
            downgrades = int(retained * cohort.downgrade_probability)
            staying = retained - upgrades - downgrades

            # Assign to tiers
            customers[cohort.target_tier] += staying

            # Handle upgrades
            if cohort.target_tier == 'individual':
                customers['team'] += upgrades
            elif cohort.target_tier == 'team':
                customers['enterprise'] += upgrades
                customers['individual'] += downgrades
            elif cohort.target_tier == 'enterprise':
                customers['single_tenant'] += upgrades
                customers['team'] += downgrades
            elif cohort.target_tier == 'single_tenant':
                customers['enterprise'] += downgrades

        # Simulate months 1-24
        for month in range(1, self.months + 1):
            # Apply churn per tier
            for tier_key, tier_config in self.tiers.items():
                if customers[tier_key] > 0:
                    churn_rate = np.random.normal(
                        tier_config.churn_rate_mean,
                        tier_config.churn_rate_std
                    )
                    churn_rate = max(0, min(churn_rate, 0.2))  # Cap at 0-20%
                    churned = int(customers[tier_key] * churn_rate)
                    customers[tier_key] -= churned

            # Add new customer growth (organic)
            new_customer_growth = np.random.normal(0.07, 0.03)  # 7% ± 3% monthly
            new_customer_growth = max(0, min(new_customer_growth, 0.15))  # Cap at 0-15%

            total_customers = sum(customers.values())
            new_customers = int(total_customers * new_customer_growth)

            # Distribute new customers across tiers (based on typical acquisition mix)
            customers['individual'] += int(new_customers * 0.30)
            customers['team'] += int(new_customers * 0.45)
            customers['enterprise'] += int(new_customers * 0.18)
            customers['single_tenant'] += int(new_customers * 0.07)

            # Apply tier migrations (customers upgrading/downgrading monthly)
            if month > 3:  # After initial migration period
                # 5% of team tier upgrades to enterprise annually (0.4% monthly)
                team_to_enterprise = int(customers['team'] * 0.004)
                customers['team'] -= team_to_enterprise
                customers['enterprise'] += team_to_enterprise

                # 3% of enterprise upgrades to single tenant annually (0.25% monthly)
                enterprise_to_single = int(customers['enterprise'] * 0.0025)
                customers['enterprise'] -= enterprise_to_single
                customers['single_tenant'] += enterprise_to_single

            # Calculate revenue
            mrr = sum(
                customers[tier_key] * tier_prices[tier_key]
                for tier_key in self.tiers.keys()
            )

            # Calculate costs
            support_costs = sum(
                customers[tier_key] * self.tiers[tier_key].support_cost
                for tier_key in self.tiers.keys()
            )

            infrastructure_costs = sum(
                customers[tier_key] * self.tiers[tier_key].infrastructure_cost
                for tier_key in self.tiers.keys()
            )

            # Fixed costs (development, overhead)
            if month <= 6:
                fixed_costs = 3000
            elif month <= 12:
                fixed_costs = 3500
            else:
                fixed_costs = 4000

            total_costs = support_costs + infrastructure_costs + fixed_costs
            ebitda = mrr - total_costs

            # Store monthly data
            monthly_data.append({
                'month': month,
                'mrr': mrr,
                'customers': sum(customers.values()),
                'customers_individual': customers['individual'],
                'customers_team': customers['team'],
                'customers_enterprise': customers['enterprise'],
                'customers_single_tenant': customers['single_tenant'],
                'support_costs': support_costs,
                'infrastructure_costs': infrastructure_costs,
                'fixed_costs': fixed_costs,
                'total_costs': total_costs,
                'ebitda': ebitda,
                'ebitda_margin': (ebitda / mrr * 100) if mrr > 0 else 0
            })

        return {
            'monthly_data': monthly_data,
            'final_mrr': monthly_data[-1]['mrr'],
            'final_customers': monthly_data[-1]['customers'],
            'cumulative_cashflow': sum(m['ebitda'] for m in monthly_data[1:]),
            'month_6_mrr': monthly_data[6]['mrr'] if len(monthly_data) > 6 else 0,
            'month_12_mrr': monthly_data[12]['mrr'] if len(monthly_data) > 12 else 0,
        }

    def run_simulation(self, scenario: str) -> pd.DataFrame:
        """Run full Monte Carlo simulation"""

        print(f"Running {self.iterations} iterations for '{scenario}' scenario...")

        cohorts = self.define_scenario(scenario)
        all_results = []

        for i in range(self.iterations):
            if (i + 1) % 1000 == 0:
                print(f"  Completed {i + 1}/{self.iterations} iterations")

            result = self.run_single_iteration(cohorts)
            all_results.append(result)

        # Create summary statistics
        summary = {
            'scenario': scenario,
            'iterations': self.iterations,
            'baseline_mrr': self.current_mrr,
            'baseline_customers': self.current_customers,
        }

        # Calculate percentiles for key metrics
        metrics = ['final_mrr', 'final_customers', 'cumulative_cashflow',
                   'month_6_mrr', 'month_12_mrr']

        for metric in metrics:
            values = [r[metric] for r in all_results]
            summary[f'{metric}_p10'] = np.percentile(values, 10)
            summary[f'{metric}_p50'] = np.percentile(values, 50)
            summary[f'{metric}_p90'] = np.percentile(values, 90)
            summary[f'{metric}_mean'] = np.mean(values)
            summary[f'{metric}_std'] = np.std(values)

        return pd.DataFrame([summary]), all_results

    def export_results(self, summary: pd.DataFrame, scenario: str,
                       detailed_results: List[Dict] = None):
        """Export simulation results to files"""

        # Export summary statistics
        summary_file = f'pricing_simulation_{scenario}_summary.csv'
        summary.to_csv(summary_file, index=False)
        print(f"\nSummary saved to: {summary_file}")

        # Export detailed results (sample of 100 iterations for analysis)
        if detailed_results:
            sample_results = detailed_results[:100]
            detailed_data = []

            for iteration_idx, result in enumerate(sample_results):
                for month_data in result['monthly_data']:
                    row = {'iteration': iteration_idx, **month_data}
                    detailed_data.append(row)

            detailed_df = pd.DataFrame(detailed_data)
            detailed_file = f'pricing_simulation_{scenario}_detailed.csv'
            detailed_df.to_csv(detailed_file, index=False)
            print(f"Detailed results (100 iterations) saved to: {detailed_file}")

        # Print summary statistics
        print(f"\n{'=' * 70}")
        print(f"SIMULATION RESULTS: {scenario.upper()} SCENARIO")
        print(f"{'=' * 70}")
        print(f"\nBaseline (Current State):")
        print(f"  MRR: ${self.current_mrr:,.0f}")
        print(f"  Customers: {self.current_customers}")
        print(f"\nProjected Results (Month 24):")

        row = summary.iloc[0]
        print(f"\n  Final MRR:")
        print(f"    P10 (Pessimistic):  ${row['final_mrr_p10']:,.0f}")
        print(f"    P50 (Median):       ${row['final_mrr_p50']:,.0f}")
        print(f"    P90 (Optimistic):   ${row['final_mrr_p90']:,.0f}")
        print(f"    Mean:               ${row['final_mrr_mean']:,.0f}")

        print(f"\n  Final Customers:")
        print(f"    P10 (Pessimistic):  {row['final_customers_p10']:.0f}")
        print(f"    P50 (Median):       {row['final_customers_p50']:.0f}")
        print(f"    P90 (Optimistic):   {row['final_customers_p90']:.0f}")

        print(f"\n  Cumulative Cashflow (24 months):")
        print(f"    P10 (Pessimistic):  ${row['cumulative_cashflow_p10']:,.0f}")
        print(f"    P50 (Median):       ${row['cumulative_cashflow_p50']:,.0f}")
        print(f"    P90 (Optimistic):   ${row['cumulative_cashflow_p90']:,.0f}")

        print(f"\n  Month 6 MRR:")
        print(f"    P50 (Median):       ${row['month_6_mrr_p50']:,.0f}")
        print(f"    Growth vs Baseline: {(row['month_6_mrr_p50'] / self.current_mrr - 1) * 100:.1f}%")

        print(f"\n  Month 12 MRR:")
        print(f"    P50 (Median):       ${row['month_12_mrr_p50']:,.0f}")
        print(f"    Growth vs Baseline: {(row['month_12_mrr_p50'] / self.current_mrr - 1) * 100:.1f}%")

        print(f"\n{'=' * 70}\n")


def main():
    parser = argparse.ArgumentParser(
        description='Monte Carlo Simulation for OneTimeSecret Pricing Strategy'
    )
    parser.add_argument(
        '--scenario',
        choices=['conservative', 'aggressive', 'pessimistic', 'all'],
        default='conservative',
        help='Scenario to simulate (default: conservative)'
    )
    parser.add_argument(
        '--iterations',
        type=int,
        default=10000,
        help='Number of Monte Carlo iterations (default: 10000)'
    )
    parser.add_argument(
        '--months',
        type=int,
        default=24,
        help='Number of months to project (default: 24)'
    )

    args = parser.parse_args()

    sim = PricingSimulation(iterations=args.iterations, months=args.months)

    scenarios_to_run = ['conservative', 'aggressive', 'pessimistic'] \
        if args.scenario == 'all' else [args.scenario]

    for scenario in scenarios_to_run:
        summary, detailed = sim.run_simulation(scenario)
        sim.export_results(summary, scenario, detailed)


if __name__ == '__main__':
    main()
