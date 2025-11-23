#!/usr/bin/env python3
"""
Monte Carlo Pricing Simulation for OneTimeSecret
Simulates 10,000+ pricing scenarios to find optimal revenue capture points

Based on:
- Current: 230 customers at $35/month
- Planned: $25 (individual), $75 (team), $150 (enterprise), $500 (dedicated)
- Proposed: Add intermediate tiers at $45-49, $125, $275-300
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
from datetime import datetime
import json

# Set random seed for reproducibility
np.random.seed(42)

class PricingSimulator:
    def __init__(self, num_simulations=10000):
        self.num_simulations = num_simulations
        self.current_customers = 230
        self.current_mrr = 230 * 35  # $8,050/month

        # Customer segmentation based on usage patterns
        self.segments = {
            'hobbyists': {'ratio': 0.35, 'wtp_mean': 25, 'wtp_std': 8},
            'small_teams': {'ratio': 0.30, 'wtp_mean': 60, 'wtp_std': 20},
            'businesses': {'ratio': 0.25, 'wtp_mean': 140, 'wtp_std': 40},
            'enterprises': {'ratio': 0.10, 'wtp_mean': 350, 'wtp_std': 150}
        }

        # Pricing scenarios to test
        self.scenarios = {
            'current_35': [35],
            'planned_4tier': [25, 75, 150, 500],
            'optimized_6tier': [25, 45, 75, 125, 150, 300],
            'optimized_7tier': [25, 45, 75, 125, 150, 300, 500],
            'aggressive_8tier': [19, 35, 59, 89, 139, 199, 349, 500],
        }

        # Feature value multipliers for different tiers
        self.feature_values = {
            25: {'api_limit': 1.0, 'ttl_days': 30, 'users': 1, 'support': 'email'},
            35: {'api_limit': 1.5, 'ttl_days': 60, 'users': 3, 'support': 'email'},
            45: {'api_limit': 2.5, 'ttl_days': 90, 'users': 10, 'support': 'priority_email'},
            49: {'api_limit': 2.5, 'ttl_days': 90, 'users': 10, 'support': 'priority_email'},
            59: {'api_limit': 3.5, 'ttl_days': 120, 'users': 15, 'support': 'priority_email'},
            75: {'api_limit': 5.0, 'ttl_days': 180, 'users': 25, 'support': 'chat'},
            89: {'api_limit': 7.0, 'ttl_days': 270, 'users': 50, 'support': 'chat+sso'},
            125: {'api_limit': 10.0, 'ttl_days': 365, 'users': 100, 'support': 'phone+sso+audit'},
            139: {'api_limit': 12.0, 'ttl_days': 365, 'users': 150, 'support': 'phone+sso+audit'},
            150: {'api_limit': 15.0, 'ttl_days': 730, 'users': 250, 'support': 'phone+sla'},
            199: {'api_limit': 20.0, 'ttl_days': 730, 'users': 500, 'support': 'dedicated+sla'},
            300: {'api_limit': 30.0, 'ttl_days': 'unlimited', 'users': 1000, 'support': 'dedicated+sla'},
            349: {'api_limit': 40.0, 'ttl_days': 'unlimited', 'users': 2000, 'support': 'dedicated+sla'},
            500: {'api_limit': 'unlimited', 'ttl_days': 'unlimited', 'users': 'unlimited', 'support': '24/7+dedicated'}
        }

    def assign_customer_willingness_to_pay(self):
        """Assign WTP curves to each customer based on segments"""
        customers = []
        for segment, props in self.segments.items():
            count = int(self.current_customers * props['ratio'])
            wtp_values = np.random.normal(
                props['wtp_mean'],
                props['wtp_std'],
                count
            )
            # Ensure non-negative values
            wtp_values = np.maximum(wtp_values, 0)

            for wtp in wtp_values:
                customers.append({
                    'segment': segment,
                    'willingness_to_pay': wtp,
                    'current_plan': 35
                })

        return pd.DataFrame(customers)

    def calculate_upgrade_probability(self, current_price, new_price, wtp, price_sensitivity=0.5):
        """
        Calculate probability of upgrading based on:
        - Willingness to pay
        - Price difference
        - Switching costs
        """
        if new_price <= current_price:
            return 0  # No downgrade modeled

        if wtp < new_price:
            # WTP is below new price
            shortage = new_price - wtp
            # Exponential decay based on shortage
            return np.exp(-price_sensitivity * (shortage / current_price))
        else:
            # WTP is above new price
            excess = wtp - new_price
            # Sigmoid function for upgrade probability
            base_prob = 0.5  # Base 50% chance if WTP equals new price
            # Increases with excess WTP
            return min(0.95, base_prob + (excess / (2 * current_price)))

    def calculate_churn_probability(self, current_price, new_price, wtp):
        """Calculate churn probability when price increases"""
        if new_price <= current_price:
            return 0.01  # Minimal churn on same/lower price

        price_increase_ratio = new_price / current_price

        if wtp < current_price:
            # Already price-sensitive, high churn risk
            return 0.7 + (0.3 * (price_increase_ratio - 1))
        elif wtp < new_price:
            # WTP between current and new price
            return 0.3 + (0.4 * (new_price - wtp) / (new_price - current_price))
        else:
            # WTP above new price, low churn
            return 0.05 * (price_increase_ratio - 1)

    def simulate_scenario(self, scenario_name, pricing_tiers):
        """Run single scenario simulation"""
        results = []

        for sim in range(self.num_simulations):
            customers_df = self.assign_customer_willingness_to_pay()

            # Assign customers to optimal tiers
            final_tier_assignment = []
            total_revenue = 0
            churned_count = 0

            for idx, customer in customers_df.iterrows():
                wtp = customer['willingness_to_pay']
                current = customer['current_plan']

                # Find best tier for this customer
                best_tier = None
                best_value = -float('inf')

                for tier in sorted(pricing_tiers):
                    if tier <= wtp:
                        # Customer can afford this tier
                        # Value = tier features - cost, normalized
                        perceived_value = wtp - tier
                        if perceived_value > best_value:
                            best_value = perceived_value
                            best_tier = tier

                # Check if customer churns
                if best_tier is None:
                    # No affordable tier
                    churn_prob = self.calculate_churn_probability(current, min(pricing_tiers), wtp)
                    if np.random.random() < churn_prob:
                        churned_count += 1
                        continue
                    else:
                        # Customer stays at lowest tier even if stretching budget
                        best_tier = min(pricing_tiers)

                # Check churn on current → new tier migration
                if best_tier != current:
                    churn_prob = self.calculate_churn_probability(current, best_tier, wtp)
                    if np.random.random() < churn_prob:
                        churned_count += 1
                        continue

                final_tier_assignment.append(best_tier)
                total_revenue += best_tier

            # Calculate metrics
            retained_customers = len(final_tier_assignment)
            retention_rate = retained_customers / self.current_customers
            mrr = total_revenue
            arpu = mrr / retained_customers if retained_customers > 0 else 0
            revenue_change = ((mrr - self.current_mrr) / self.current_mrr) * 100

            # Tier distribution
            tier_dist = pd.Series(final_tier_assignment).value_counts().to_dict()

            results.append({
                'simulation': sim,
                'scenario': scenario_name,
                'mrr': mrr,
                'retained_customers': retained_customers,
                'churned_customers': churned_count,
                'retention_rate': retention_rate,
                'arpu': arpu,
                'revenue_change_pct': revenue_change,
                'tier_distribution': tier_dist
            })

        return pd.DataFrame(results)

    def run_all_scenarios(self):
        """Run simulations for all pricing scenarios"""
        all_results = []

        print(f"Running {self.num_simulations} simulations for each scenario...")
        print(f"Current baseline: {self.current_customers} customers @ $35/mo = ${self.current_mrr} MRR\n")

        for scenario_name, tiers in self.scenarios.items():
            print(f"Simulating: {scenario_name} - Tiers: {tiers}")
            scenario_results = self.simulate_scenario(scenario_name, tiers)
            all_results.append(scenario_results)

        return pd.concat(all_results, ignore_index=True)

    def analyze_results(self, results_df):
        """Analyze simulation results and generate insights"""
        summary = results_df.groupby('scenario').agg({
            'mrr': ['mean', 'std', 'min', 'max', lambda x: np.percentile(x, 5), lambda x: np.percentile(x, 95)],
            'retained_customers': ['mean', 'std'],
            'retention_rate': ['mean', 'std'],
            'arpu': ['mean', 'std'],
            'revenue_change_pct': ['mean', 'std', 'min', 'max']
        }).round(2)

        summary.columns = ['_'.join(col).strip() for col in summary.columns.values]

        return summary

    def calculate_confidence_intervals(self, results_df):
        """Calculate 95% confidence intervals for key metrics"""
        ci_results = []

        for scenario in results_df['scenario'].unique():
            scenario_data = results_df[results_df['scenario'] == scenario]

            mrr_mean = scenario_data['mrr'].mean()
            mrr_ci = stats.t.interval(
                0.95,
                len(scenario_data) - 1,
                loc=mrr_mean,
                scale=stats.sem(scenario_data['mrr'])
            )

            revenue_change_mean = scenario_data['revenue_change_pct'].mean()
            revenue_change_ci = stats.t.interval(
                0.95,
                len(scenario_data) - 1,
                loc=revenue_change_mean,
                scale=stats.sem(scenario_data['revenue_change_pct'])
            )

            retention_mean = scenario_data['retention_rate'].mean()
            retention_ci = stats.t.interval(
                0.95,
                len(scenario_data) - 1,
                loc=retention_mean,
                scale=stats.sem(scenario_data['retention_rate'])
            )

            ci_results.append({
                'scenario': scenario,
                'mrr_mean': mrr_mean,
                'mrr_ci_lower': mrr_ci[0],
                'mrr_ci_upper': mrr_ci[1],
                'revenue_change_mean': revenue_change_mean,
                'revenue_change_ci_lower': revenue_change_ci[0],
                'revenue_change_ci_upper': revenue_change_ci[1],
                'retention_mean': retention_mean,
                'retention_ci_lower': retention_ci[0],
                'retention_ci_upper': retention_ci[1]
            })

        return pd.DataFrame(ci_results)

    def calculate_cannibalization(self, results_df):
        """Analyze tier cannibalization patterns"""
        cannibalization_analysis = []

        for scenario in results_df['scenario'].unique():
            scenario_data = results_df[results_df['scenario'] == scenario]

            # Aggregate tier distributions across all simulations
            tier_counts = {}
            for tier_dist in scenario_data['tier_distribution']:
                for tier, count in tier_dist.items():
                    tier_counts[tier] = tier_counts.get(tier, 0) + count

            # Calculate average distribution
            avg_tier_dist = {tier: count / len(scenario_data) for tier, count in tier_counts.items()}

            cannibalization_analysis.append({
                'scenario': scenario,
                'tier_distribution': avg_tier_dist
            })

        return pd.DataFrame(cannibalization_analysis)

    def export_results(self, results_df, summary_df, ci_df, cannibalization_df, output_prefix='simulation'):
        """Export results to CSV and JSON"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

        # Export detailed results
        results_df.to_csv(f'{output_prefix}_detailed_{timestamp}.csv', index=False)

        # Export summary
        summary_df.to_csv(f'{output_prefix}_summary_{timestamp}.csv')

        # Export confidence intervals
        ci_df.to_csv(f'{output_prefix}_confidence_intervals_{timestamp}.csv', index=False)

        # Export cannibalization
        cannibalization_df.to_csv(f'{output_prefix}_cannibalization_{timestamp}.csv', index=False)

        # Export JSON summary
        json_summary = {
            'simulation_parameters': {
                'num_simulations': self.num_simulations,
                'current_customers': self.current_customers,
                'current_mrr': self.current_mrr,
                'customer_segments': self.segments,
                'scenarios_tested': {k: v for k, v in self.scenarios.items()}
            },
            'results_summary': summary_df.to_dict(),
            'confidence_intervals': ci_df.to_dict('records'),
            'cannibalization': cannibalization_df.to_dict('records')
        }

        with open(f'{output_prefix}_full_report_{timestamp}.json', 'w') as f:
            json.dump(json_summary, f, indent=2)

        print(f"\nResults exported:")
        print(f"  - {output_prefix}_detailed_{timestamp}.csv")
        print(f"  - {output_prefix}_summary_{timestamp}.csv")
        print(f"  - {output_prefix}_confidence_intervals_{timestamp}.csv")
        print(f"  - {output_prefix}_cannibalization_{timestamp}.csv")
        print(f"  - {output_prefix}_full_report_{timestamp}.json")

    def plot_results(self, results_df, ci_df):
        """Generate visualization plots"""
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))

        # Plot 1: MRR Distribution by Scenario
        ax1 = axes[0, 0]
        results_df.boxplot(column='mrr', by='scenario', ax=ax1)
        ax1.axhline(y=self.current_mrr, color='r', linestyle='--', label='Current MRR')
        ax1.set_title('MRR Distribution by Pricing Scenario')
        ax1.set_xlabel('Scenario')
        ax1.set_ylabel('Monthly Recurring Revenue ($)')
        ax1.legend()

        # Plot 2: Revenue Change %
        ax2 = axes[0, 1]
        ci_df_sorted = ci_df.sort_values('revenue_change_mean', ascending=False)
        ax2.barh(ci_df_sorted['scenario'], ci_df_sorted['revenue_change_mean'])
        ax2.set_title('Average Revenue Change by Scenario')
        ax2.set_xlabel('Revenue Change (%)')
        ax2.set_ylabel('Scenario')
        ax2.axvline(x=0, color='k', linestyle='-', linewidth=0.5)

        # Plot 3: Retention Rate
        ax3 = axes[1, 0]
        retention_data = results_df.groupby('scenario')['retention_rate'].mean().sort_values(ascending=False)
        ax3.bar(range(len(retention_data)), retention_data.values)
        ax3.set_xticks(range(len(retention_data)))
        ax3.set_xticklabels(retention_data.index, rotation=45, ha='right')
        ax3.set_title('Average Customer Retention by Scenario')
        ax3.set_ylabel('Retention Rate')
        ax3.axhline(y=0.9, color='g', linestyle='--', label='90% target')
        ax3.legend()

        # Plot 4: ARPU
        ax4 = axes[1, 1]
        arpu_data = results_df.groupby('scenario')['arpu'].mean().sort_values(ascending=False)
        ax4.bar(range(len(arpu_data)), arpu_data.values)
        ax4.set_xticks(range(len(arpu_data)))
        ax4.set_xticklabels(arpu_data.index, rotation=45, ha='right')
        ax4.set_title('Average Revenue Per User (ARPU) by Scenario')
        ax4.set_ylabel('ARPU ($)')
        ax4.axhline(y=35, color='r', linestyle='--', label='Current ARPU')
        ax4.legend()

        plt.tight_layout()
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        plt.savefig(f'simulation_results_{timestamp}.png', dpi=300, bbox_inches='tight')
        print(f"\nVisualization saved: simulation_results_{timestamp}.png")

        return fig


def main():
    """Main execution function"""
    print("=" * 80)
    print("ONETIMESECRET MONTE CARLO PRICING SIMULATION")
    print("=" * 80)
    print()

    # Initialize simulator
    simulator = PricingSimulator(num_simulations=10000)

    # Run simulations
    results = simulator.run_all_scenarios()

    print("\n" + "=" * 80)
    print("ANALYZING RESULTS")
    print("=" * 80)

    # Analyze results
    summary = simulator.analyze_results(results)
    print("\nSummary Statistics:")
    print(summary)

    # Calculate confidence intervals
    confidence_intervals = simulator.calculate_confidence_intervals(results)
    print("\n95% Confidence Intervals:")
    print(confidence_intervals)

    # Analyze cannibalization
    cannibalization = simulator.calculate_cannibalization(results)
    print("\nTier Distribution (Cannibalization Analysis):")
    print(cannibalization)

    # Export results
    print("\n" + "=" * 80)
    print("EXPORTING RESULTS")
    print("=" * 80)
    simulator.export_results(results, summary, confidence_intervals, cannibalization)

    # Generate plots
    print("\n" + "=" * 80)
    print("GENERATING VISUALIZATIONS")
    print("=" * 80)
    simulator.plot_results(results, confidence_intervals)

    # Print recommendations
    print("\n" + "=" * 80)
    print("RECOMMENDATIONS")
    print("=" * 80)

    best_scenario = confidence_intervals.loc[confidence_intervals['revenue_change_mean'].idxmax()]
    print(f"\nOptimal Pricing Scenario: {best_scenario['scenario']}")
    print(f"  Expected MRR: ${best_scenario['mrr_mean']:.2f}")
    print(f"  95% CI: ${best_scenario['mrr_ci_lower']:.2f} - ${best_scenario['mrr_ci_upper']:.2f}")
    print(f"  Revenue Change: {best_scenario['revenue_change_mean']:.2f}%")
    print(f"  95% CI: {best_scenario['revenue_change_ci_lower']:.2f}% - {best_scenario['revenue_change_ci_upper']:.2f}%")
    print(f"  Expected Retention: {best_scenario['retention_mean']*100:.1f}%")
    print(f"  95% CI: {best_scenario['retention_ci_lower']*100:.1f}% - {best_scenario['retention_ci_upper']*100:.1f}%")

    print("\n" + "=" * 80)
    print("SIMULATION COMPLETE")
    print("=" * 80)


if __name__ == '__main__':
    main()
