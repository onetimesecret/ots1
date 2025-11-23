#!/usr/bin/env python3
"""
Customer Segmentation & Migration Analysis Tool

Analyzes customer usage data to recommend optimal tier placement
and predict migration patterns.

Usage:
    # Analyze customer data from CSV
    python customer_segmentation_analysis.py --input customers.csv

    # Generate sample data for testing
    python customer_segmentation_analysis.py --generate-sample
"""

import pandas as pd
import numpy as np
import argparse
from typing import Dict, List, Tuple
from dataclasses import dataclass
import matplotlib.pyplot as plt
import seaborn as sns


@dataclass
class TierRecommendation:
    """Recommendation for customer tier placement"""
    customer_id: str
    current_plan: str
    recommended_tier: str
    confidence: float
    reasoning: str
    monthly_cost_change: float
    churn_risk: str  # 'low', 'medium', 'high'


class CustomerSegmentationAnalyzer:
    """Analyzes customer data and recommends tier placement"""

    def __init__(self):
        # Define tier thresholds
        self.tier_criteria = {
            'individual': {
                'max_users': 1,
                'max_secrets_per_month': 100,
                'max_api_calls_per_day': 50,
                'price': 19
            },
            'team': {
                'max_users': 10,
                'max_secrets_per_month': 500,
                'max_api_calls_per_day': 200,
                'requires_sso': False,
                'price': 79
            },
            'enterprise': {
                'max_users': 100,
                'max_secrets_per_month': 2000,
                'max_api_calls_per_day': 1000,
                'requires_sso': True,
                'price': 149
            },
            'single_tenant': {
                'max_users': float('inf'),
                'max_secrets_per_month': 10000,
                'max_api_calls_per_day': 5000,
                'requires_compliance': True,
                'price': 799
            }
        }

        self.current_price = 35  # Current $35/month plan

    def recommend_tier(self, customer: pd.Series) -> TierRecommendation:
        """Recommend optimal tier for a customer based on usage"""

        customer_id = customer.get('customer_id', 'unknown')

        # Extract usage metrics
        users = customer.get('active_users', 1)
        secrets_per_month = customer.get('secrets_per_month', 0)
        api_calls_per_day = customer.get('api_calls_per_day', 0)
        needs_sso = customer.get('needs_sso', False)
        needs_compliance = customer.get('needs_compliance', False)
        company_size = customer.get('company_size', 1)

        # Score for each tier
        tier_scores = {}
        tier_reasons = {}

        # Individual tier scoring
        if users <= 1 and secrets_per_month <= 100 and not needs_sso:
            tier_scores['individual'] = 0.9
            tier_reasons['individual'] = "Low usage, single user - perfect for Individual tier"
        else:
            tier_scores['individual'] = 0.0
            tier_reasons['individual'] = "Usage exceeds Individual tier limits"

        # Team tier scoring
        team_score = 0.0
        team_reason_parts = []

        if users <= 10:
            team_score += 0.4
            team_reason_parts.append(f"{users} users fits Team tier")

        if secrets_per_month <= 500:
            team_score += 0.3
            team_reason_parts.append(f"{secrets_per_month} secrets/month within Team limits")

        if not needs_sso and not needs_compliance:
            team_score += 0.3
            team_reason_parts.append("No enterprise features needed")

        tier_scores['team'] = team_score
        tier_reasons['team'] = "; ".join(team_reason_parts) if team_reason_parts else "Does not fit Team tier"

        # Enterprise tier scoring
        enterprise_score = 0.0
        enterprise_reason_parts = []

        if 10 < users <= 100:
            enterprise_score += 0.4
            enterprise_reason_parts.append(f"{users} users requires Enterprise tier")

        if 500 < secrets_per_month <= 2000:
            enterprise_score += 0.3
            enterprise_reason_parts.append(f"{secrets_per_month} secrets/month needs Enterprise capacity")

        if needs_sso:
            enterprise_score += 0.5
            enterprise_reason_parts.append("SSO requirement")

        if company_size >= 50:
            enterprise_score += 0.2
            enterprise_reason_parts.append(f"Company size ({company_size}) suggests Enterprise need")

        tier_scores['enterprise'] = min(enterprise_score, 1.0)
        tier_reasons['enterprise'] = "; ".join(enterprise_reason_parts) if enterprise_reason_parts else "Does not fit Enterprise tier"

        # Single tenant tier scoring
        single_tenant_score = 0.0
        single_tenant_reason_parts = []

        if users > 100:
            single_tenant_score += 0.4
            single_tenant_reason_parts.append(f"{users} users requires dedicated infrastructure")

        if secrets_per_month > 2000:
            single_tenant_score += 0.3
            single_tenant_reason_parts.append(f"{secrets_per_month} secrets/month needs Single Tenant")

        if needs_compliance:
            single_tenant_score += 0.5
            single_tenant_reason_parts.append("Compliance requirements")

        if company_size >= 500:
            single_tenant_score += 0.2
            single_tenant_reason_parts.append(f"Large enterprise ({company_size} employees)")

        tier_scores['single_tenant'] = min(single_tenant_score, 1.0)
        tier_reasons['single_tenant'] = "; ".join(single_tenant_reason_parts) if single_tenant_reason_parts else "Does not fit Single Tenant tier"

        # Select tier with highest score
        recommended_tier = max(tier_scores, key=tier_scores.get)
        confidence = tier_scores[recommended_tier]

        # If no clear match (all scores low), default to team tier
        if confidence < 0.5:
            recommended_tier = 'team'
            confidence = 0.5
            reasoning = "No strong signals - defaulting to Team tier (most common)"
        else:
            reasoning = tier_reasons[recommended_tier]

        # Calculate cost change
        new_price = self.tier_criteria[recommended_tier]['price']
        cost_change = new_price - self.current_price

        # Estimate churn risk
        churn_risk = self._estimate_churn_risk(
            cost_change=cost_change,
            usage_fit=confidence,
            current_usage_ratio=secrets_per_month / self.tier_criteria[recommended_tier]['max_secrets_per_month']
        )

        return TierRecommendation(
            customer_id=customer_id,
            current_plan='legacy_35',
            recommended_tier=recommended_tier,
            confidence=confidence,
            reasoning=reasoning,
            monthly_cost_change=cost_change,
            churn_risk=churn_risk
        )

    def _estimate_churn_risk(self, cost_change: float, usage_fit: float,
                             current_usage_ratio: float) -> str:
        """Estimate churn risk based on multiple factors"""

        risk_score = 0.0

        # Cost change impact
        if cost_change > 100:
            risk_score += 0.4
        elif cost_change > 50:
            risk_score += 0.3
        elif cost_change > 0:
            risk_score += 0.1
        elif cost_change < 0:
            risk_score -= 0.2  # Saving money reduces churn

        # Usage fit impact (lower fit = higher churn risk)
        if usage_fit < 0.5:
            risk_score += 0.3
        elif usage_fit < 0.7:
            risk_score += 0.1

        # Under-utilization risk (paying for unused capacity)
        if current_usage_ratio < 0.3:
            risk_score += 0.2

        # Over-utilization risk (hitting limits frequently)
        if current_usage_ratio > 0.8:
            risk_score -= 0.1  # Actually reduces churn (need the capacity)

        # Categorize risk
        if risk_score > 0.5:
            return 'high'
        elif risk_score > 0.2:
            return 'medium'
        else:
            return 'low'

    def analyze_cohort(self, customers_df: pd.DataFrame) -> pd.DataFrame:
        """Analyze entire customer cohort and generate recommendations"""

        recommendations = []

        for idx, customer in customers_df.iterrows():
            rec = self.recommend_tier(customer)
            recommendations.append({
                'customer_id': rec.customer_id,
                'current_plan': rec.current_plan,
                'recommended_tier': rec.recommended_tier,
                'confidence': rec.confidence,
                'reasoning': rec.reasoning,
                'monthly_cost_change': rec.monthly_cost_change,
                'new_monthly_cost': self.tier_criteria[rec.recommended_tier]['price'],
                'churn_risk': rec.churn_risk
            })

        return pd.DataFrame(recommendations)

    def generate_migration_summary(self, recommendations_df: pd.DataFrame) -> Dict:
        """Generate summary statistics for migration"""

        summary = {
            'total_customers': len(recommendations_df),
            'tier_distribution': recommendations_df['recommended_tier'].value_counts().to_dict(),
            'churn_risk_distribution': recommendations_df['churn_risk'].value_counts().to_dict(),
            'revenue_impact': {
                'current_mrr': len(recommendations_df) * self.current_price,
                'projected_mrr': recommendations_df['new_monthly_cost'].sum(),
                'change_amount': recommendations_df['monthly_cost_change'].sum(),
                'change_percent': (recommendations_df['new_monthly_cost'].sum() /
                                   (len(recommendations_df) * self.current_price) - 1) * 100
            },
            'risk_analysis': {
                'high_risk_customers': len(recommendations_df[recommendations_df['churn_risk'] == 'high']),
                'high_risk_revenue_at_risk': recommendations_df[
                    recommendations_df['churn_risk'] == 'high'
                ]['new_monthly_cost'].sum()
            }
        }

        return summary

    def plot_migration_analysis(self, recommendations_df: pd.DataFrame,
                                 output_file: str = 'migration_analysis.png'):
        """Generate visualization of migration analysis"""

        fig, axes = plt.subplots(2, 2, figsize=(14, 10))
        fig.suptitle('Customer Migration Analysis', fontsize=16, fontweight='bold')

        # 1. Tier distribution
        tier_counts = recommendations_df['recommended_tier'].value_counts()
        axes[0, 0].bar(tier_counts.index, tier_counts.values, color='steelblue')
        axes[0, 0].set_title('Recommended Tier Distribution')
        axes[0, 0].set_xlabel('Tier')
        axes[0, 0].set_ylabel('Number of Customers')
        axes[0, 0].tick_params(axis='x', rotation=45)

        # 2. Cost change distribution
        axes[0, 1].hist(recommendations_df['monthly_cost_change'], bins=30,
                        color='coral', edgecolor='black')
        axes[0, 1].axvline(x=0, color='red', linestyle='--', label='No Change')
        axes[0, 1].set_title('Monthly Cost Change Distribution')
        axes[0, 1].set_xlabel('Cost Change ($)')
        axes[0, 1].set_ylabel('Number of Customers')
        axes[0, 1].legend()

        # 3. Churn risk by tier
        churn_by_tier = pd.crosstab(recommendations_df['recommended_tier'],
                                      recommendations_df['churn_risk'])
        churn_by_tier.plot(kind='bar', stacked=True, ax=axes[1, 0],
                           color=['green', 'yellow', 'red'])
        axes[1, 0].set_title('Churn Risk by Recommended Tier')
        axes[1, 0].set_xlabel('Tier')
        axes[1, 0].set_ylabel('Number of Customers')
        axes[1, 0].legend(title='Churn Risk')
        axes[1, 0].tick_params(axis='x', rotation=45)

        # 4. Confidence distribution
        axes[1, 1].hist(recommendations_df['confidence'], bins=20,
                        color='lightgreen', edgecolor='black')
        axes[1, 1].set_title('Recommendation Confidence Distribution')
        axes[1, 1].set_xlabel('Confidence Score')
        axes[1, 1].set_ylabel('Number of Customers')

        plt.tight_layout()
        plt.savefig(output_file, dpi=300, bbox_inches='tight')
        print(f"Visualization saved to: {output_file}")

        plt.close()


def generate_sample_data(num_customers: int = 230) -> pd.DataFrame:
    """Generate sample customer data for testing"""

    np.random.seed(42)

    # Define customer segments with realistic distributions
    segments = {
        'solo_developer': {
            'proportion': 0.25,
            'active_users': (1, 1),
            'secrets_per_month': (10, 100),
            'api_calls_per_day': (5, 50),
            'needs_sso': 0.0,
            'needs_compliance': 0.0,
            'company_size': (1, 5)
        },
        'small_team': {
            'proportion': 0.45,
            'active_users': (2, 8),
            'secrets_per_month': (50, 400),
            'api_calls_per_day': (20, 150),
            'needs_sso': 0.1,
            'needs_compliance': 0.05,
            'company_size': (5, 50)
        },
        'midsize_team': {
            'proportion': 0.20,
            'active_users': (8, 50),
            'secrets_per_month': (200, 1500),
            'api_calls_per_day': (100, 800),
            'needs_sso': 0.6,
            'needs_compliance': 0.3,
            'company_size': (50, 200)
        },
        'enterprise': {
            'proportion': 0.10,
            'active_users': (20, 200),
            'secrets_per_month': (500, 5000),
            'api_calls_per_day': (500, 3000),
            'needs_sso': 0.9,
            'needs_compliance': 0.7,
            'company_size': (200, 5000)
        }
    }

    customers = []

    for segment_name, segment_props in segments.items():
        segment_size = int(num_customers * segment_props['proportion'])

        for i in range(segment_size):
            customer = {
                'customer_id': f'{segment_name}_{i:04d}',
                'segment': segment_name,
                'active_users': np.random.randint(*segment_props['active_users']),
                'secrets_per_month': np.random.randint(*segment_props['secrets_per_month']),
                'api_calls_per_day': np.random.randint(*segment_props['api_calls_per_day']),
                'needs_sso': np.random.random() < segment_props['needs_sso'],
                'needs_compliance': np.random.random() < segment_props['needs_compliance'],
                'company_size': np.random.randint(*segment_props['company_size'])
            }
            customers.append(customer)

    return pd.DataFrame(customers)


def main():
    parser = argparse.ArgumentParser(
        description='Customer Segmentation & Migration Analysis'
    )
    parser.add_argument(
        '--input',
        help='Input CSV file with customer data'
    )
    parser.add_argument(
        '--generate-sample',
        action='store_true',
        help='Generate sample customer data'
    )
    parser.add_argument(
        '--output',
        default='migration_recommendations.csv',
        help='Output file for recommendations (default: migration_recommendations.csv)'
    )
    parser.add_argument(
        '--visualize',
        action='store_true',
        help='Generate visualization charts'
    )

    args = parser.parse_args()

    analyzer = CustomerSegmentationAnalyzer()

    # Load or generate customer data
    if args.generate_sample:
        print("Generating sample customer data (230 customers)...")
        customers_df = generate_sample_data(230)
        customers_df.to_csv('sample_customers.csv', index=False)
        print("Sample data saved to: sample_customers.csv")
    elif args.input:
        print(f"Loading customer data from: {args.input}")
        customers_df = pd.read_csv(args.input)
    else:
        print("Error: Must provide --input or --generate-sample")
        return

    # Analyze customers
    print(f"\nAnalyzing {len(customers_df)} customers...")
    recommendations_df = analyzer.analyze_cohort(customers_df)

    # Generate summary
    summary = analyzer.generate_migration_summary(recommendations_df)

    # Print summary
    print("\n" + "=" * 70)
    print("MIGRATION ANALYSIS SUMMARY")
    print("=" * 70)
    print(f"\nTotal Customers: {summary['total_customers']}")
    print(f"\nRecommended Tier Distribution:")
    for tier, count in summary['tier_distribution'].items():
        pct = (count / summary['total_customers']) * 100
        print(f"  {tier:20s}: {count:3d} customers ({pct:5.1f}%)")

    print(f"\nChurn Risk Distribution:")
    for risk, count in summary['churn_risk_distribution'].items():
        pct = (count / summary['total_customers']) * 100
        print(f"  {risk:20s}: {count:3d} customers ({pct:5.1f}%)")

    print(f"\nRevenue Impact:")
    print(f"  Current MRR:     ${summary['revenue_impact']['current_mrr']:,.0f}")
    print(f"  Projected MRR:   ${summary['revenue_impact']['projected_mrr']:,.0f}")
    print(f"  Change:          ${summary['revenue_impact']['change_amount']:,.0f} "
          f"({summary['revenue_impact']['change_percent']:+.1f}%)")

    print(f"\nRisk Analysis:")
    print(f"  High-risk customers:        {summary['risk_analysis']['high_risk_customers']}")
    print(f"  Revenue at risk:            ${summary['risk_analysis']['high_risk_revenue_at_risk']:,.0f}")

    print("\n" + "=" * 70 + "\n")

    # Save recommendations
    recommendations_df.to_csv(args.output, index=False)
    print(f"Recommendations saved to: {args.output}")

    # Generate visualization if requested
    if args.visualize:
        try:
            analyzer.plot_migration_analysis(recommendations_df)
        except Exception as e:
            print(f"Warning: Could not generate visualization: {e}")


if __name__ == '__main__':
    main()
