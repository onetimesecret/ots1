"""
Comprehensive Multi-Segment Pricing Analysis Runner
Executes pricing optimization across 50+ market segments and generates
detailed reports with revenue projections, competitive analysis, and dashboards.
"""

import numpy as np
import json
import os
from datetime import datetime
from typing import List, Dict, Any
import warnings

warnings.filterwarnings('ignore')

from multi_segment_analyzer import (
    MultiSegmentAnalyzer,
    MarketSegment,
    CompetitorPrice,
    MarketCondition
)


def generate_market_segments() -> List[MarketSegment]:
    """Generate 50+ diverse market segments for analysis."""
    segments = []

    # Enterprise segments by industry (10 segments)
    enterprise_industries = [
        ("technology", 0.15, 0.3, 0.20),
        ("finance", 0.12, -0.2, 0.15),
        ("healthcare", 0.13, -0.1, 0.18),
        ("manufacturing", 0.10, 0.4, 0.12),
        ("retail", 0.11, 0.5, 0.10),
        ("telecommunications", 0.14, 0.2, 0.16),
        ("energy", 0.09, -0.3, 0.08),
        ("government", 0.08, -0.5, 0.05),
        ("education", 0.10, 0.3, 0.14),
        ("media", 0.12, 0.4, 0.22)
    ]

    for i, (industry, conv_rate, price_sens, growth) in enumerate(enterprise_industries):
        segments.append(MarketSegment(
            id=f"ent_{industry}_{i+1:02d}",
            name=f"enterprise_{industry}",
            description=f"Large {industry} companies",
            size=np.random.randint(2000, 8000),
            base_conversion_rate=conv_rate,
            price_sensitivity=price_sens,
            growth_rate=growth,
            geographic_region=np.random.choice(["north_america", "europe", "asia_pacific"]),
            industry=industry
        ))

    # SMB segments by region (15 segments)
    regions = ["north_america", "europe", "asia_pacific", "latin_america", "middle_east"]
    business_types = ["saas", "ecommerce", "services"]

    for region in regions:
        for biz_type in business_types:
            segments.append(MarketSegment(
                id=f"smb_{region}_{biz_type}",
                name=f"smb_{region}_{biz_type}",
                description=f"SMB {biz_type} companies in {region}",
                size=np.random.randint(8000, 20000),
                base_conversion_rate=np.random.uniform(0.08, 0.14),
                price_sensitivity=np.random.uniform(0.2, 0.6),
                growth_rate=np.random.uniform(0.15, 0.35),
                geographic_region=region,
                industry=biz_type
            ))

    # Startup segments by stage (10 segments)
    funding_stages = ["seed", "series_a", "series_b", "series_c", "late_stage"]
    startup_industries = ["fintech", "healthtech"]

    for stage in funding_stages:
        for industry in startup_industries:
            segments.append(MarketSegment(
                id=f"startup_{stage}_{industry}",
                name=f"startup_{stage}_{industry}",
                description=f"{stage.replace('_', ' ').title()} startups in {industry}",
                size=np.random.randint(5000, 15000),
                base_conversion_rate=np.random.uniform(0.10, 0.18),
                price_sensitivity=np.random.uniform(0.3, 0.7),
                growth_rate=np.random.uniform(0.25, 0.50),
                geographic_region=np.random.choice(["north_america", "europe", "asia_pacific"]),
                industry=industry
            ))

    # Individual developer segments (8 segments)
    dev_types = ["frontend", "backend", "fullstack", "devops", "mobile", "data", "ml", "security"]

    for dev_type in dev_types:
        segments.append(MarketSegment(
            id=f"dev_{dev_type}",
            name=f"individual_{dev_type}_developers",
            description=f"Individual {dev_type} developers and freelancers",
            size=np.random.randint(15000, 50000),
            base_conversion_rate=np.random.uniform(0.04, 0.08),
            price_sensitivity=np.random.uniform(0.5, 0.8),
            growth_rate=np.random.uniform(0.20, 0.40),
            geographic_region=np.random.choice(["north_america", "europe", "asia_pacific", "global"]),
            industry="technology"
        ))

    # Vertical-specific segments (10 segments)
    verticals = [
        ("legal", 0.11, -0.2, 0.12),
        ("consulting", 0.13, 0.3, 0.18),
        ("marketing_agency", 0.14, 0.4, 0.22),
        ("real_estate", 0.10, 0.3, 0.15),
        ("insurance", 0.09, -0.1, 0.08),
        ("logistics", 0.10, 0.2, 0.14),
        ("hospitality", 0.08, 0.5, 0.10),
        ("non_profit", 0.07, 0.6, 0.08),
        ("gaming", 0.15, 0.4, 0.30),
        ("crypto", 0.12, 0.5, 0.40)
    ]

    for industry, conv_rate, price_sens, growth in verticals:
        segments.append(MarketSegment(
            id=f"vert_{industry}",
            name=f"vertical_{industry}",
            description=f"{industry.replace('_', ' ').title()} sector",
            size=np.random.randint(3000, 12000),
            base_conversion_rate=conv_rate,
            price_sensitivity=price_sens,
            growth_rate=growth,
            geographic_region=np.random.choice(["north_america", "europe", "asia_pacific"]),
            industry=industry
        ))

    return segments


def generate_competitors(tier_name: str) -> List[CompetitorPrice]:
    """Generate competitor pricing data for a tier."""
    # Base prices by tier
    tier_base_prices = {
        'free': 0,
        'basic': 29,
        'professional': 299,
        'enterprise': 999,
        'premium': 1999
    }

    base = tier_base_prices.get(tier_name, 299)

    if tier_name == 'free':
        return []  # No paid competitors for free tier

    competitors = [
        CompetitorPrice(
            "SecretVault Pro",
            base * np.random.uniform(0.8, 1.2),
            np.random.uniform(0.10, 0.20),
            np.random.randint(70, 85)
        ),
        CompetitorPrice(
            "ConfidentialShare",
            base * np.random.uniform(0.9, 1.4),
            np.random.uniform(0.15, 0.25),
            np.random.randint(75, 90)
        ),
        CompetitorPrice(
            "SecurePass",
            base * np.random.uniform(0.6, 1.0),
            np.random.uniform(0.05, 0.12),
            np.random.randint(60, 75)
        )
    ]

    return competitors


def run_comprehensive_analysis(output_dir: str = "./reports"):
    """
    Run comprehensive pricing analysis across all segments and tiers.

    Args:
        output_dir: Directory to save reports
    """
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)

    print("=" * 80)
    print("COMPREHENSIVE MULTI-SEGMENT PRICING OPTIMIZATION ANALYSIS")
    print("=" * 80)
    print(f"\nStart time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Output directory: {output_dir}\n")

    # Initialize analyzer
    analyzer = MultiSegmentAnalyzer()

    # Generate segments
    print("Generating market segments...")
    segments = generate_market_segments()
    print(f"✓ Generated {len(segments)} market segments\n")

    # Tier priority for analysis
    tier_priority = ['basic', 'professional', 'enterprise']

    # Storage for aggregated results
    all_reports = []
    summary_stats = {
        'total_segments_analyzed': 0,
        'total_projected_revenue': 0,
        'total_projected_profit': 0,
        'average_optimal_prices': {},
        'best_segments': [],
        'high_risk_segments': []
    }

    # Run analysis for each segment
    print("Running pricing analysis...")
    print("-" * 80)

    for idx, segment in enumerate(segments, 1):
        print(f"\n[{idx}/{len(segments)}] Analyzing: {segment.name}")
        print(f"  Size: {segment.size:,} | Conv Rate: {segment.base_conversion_rate:.2%} | Region: {segment.geographic_region}")

        segment_reports = {}

        # Analyze each tier for this segment
        for tier_name in tier_priority:
            try:
                # Generate competitors
                competitors = generate_competitors(tier_name)

                # Run analysis
                report = analyzer.analyze_segment(
                    segment=segment,
                    tier_name=tier_name,
                    competitors=competitors
                )

                segment_reports[tier_name] = report

                # Extract key metrics
                tier_pricing = report.tier_pricing[tier_name]
                monthly_revenue = tier_pricing.expected_revenue * 30
                monthly_profit = tier_pricing.expected_profit * 30

                print(f"  [{tier_name}] Price: ${tier_pricing.optimal_price:.2f} | "
                      f"Monthly Revenue: ${monthly_revenue:,.0f} | "
                      f"Risk: {report.risk_score:.0f}/100")

                # Update summary stats
                summary_stats['total_projected_revenue'] += monthly_revenue
                summary_stats['total_projected_profit'] += monthly_profit

                if tier_name not in summary_stats['average_optimal_prices']:
                    summary_stats['average_optimal_prices'][tier_name] = []
                summary_stats['average_optimal_prices'][tier_name].append(tier_pricing.optimal_price)

                # Track best and high-risk segments
                if monthly_revenue > 100000:
                    summary_stats['best_segments'].append({
                        'segment': segment.name,
                        'tier': tier_name,
                        'monthly_revenue': monthly_revenue,
                        'monthly_profit': monthly_profit
                    })

                if report.risk_score > 70:
                    summary_stats['high_risk_segments'].append({
                        'segment': segment.name,
                        'tier': tier_name,
                        'risk_score': report.risk_score,
                        'risk_factors': report.risk_factors
                    })

            except Exception as e:
                print(f"  [ERROR] Failed to analyze {tier_name}: {str(e)}")
                continue

        # Save individual segment report
        if segment_reports:
            summary_stats['total_segments_analyzed'] += 1

            report_file = os.path.join(
                output_dir,
                f"segment_{segment.id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            )

            # Combine all tier reports for this segment
            combined_report = {
                'segment': segment_reports[next(iter(segment_reports))].to_dict()['segment'],
                'analysis_timestamp': datetime.now().isoformat(),
                'tiers': {
                    tier: report.to_dict()
                    for tier, report in segment_reports.items()
                }
            }

            with open(report_file, 'w') as f:
                json.dump(combined_report, f, indent=2)

            all_reports.append(combined_report)

    print("\n" + "=" * 80)
    print("ANALYSIS COMPLETE")
    print("=" * 80)

    # Generate summary report
    print("\n📊 SUMMARY STATISTICS")
    print("-" * 80)
    print(f"Total Segments Analyzed: {summary_stats['total_segments_analyzed']}")
    print(f"Total Projected Monthly Revenue: ${summary_stats['total_projected_revenue']:,.2f}")
    print(f"Total Projected Monthly Profit: ${summary_stats['total_projected_profit']:,.2f}")

    print(f"\nAverage Optimal Prices by Tier:")
    for tier, prices in summary_stats['average_optimal_prices'].items():
        avg_price = np.mean(prices)
        std_price = np.std(prices)
        print(f"  {tier.capitalize()}: ${avg_price:.2f} (±${std_price:.2f})")

    print(f"\n🏆 TOP 10 REVENUE-GENERATING SEGMENTS:")
    best_segments = sorted(
        summary_stats['best_segments'],
        key=lambda x: x['monthly_revenue'],
        reverse=True
    )[:10]

    for i, seg in enumerate(best_segments, 1):
        print(f"  {i}. {seg['segment']} ({seg['tier']}): ${seg['monthly_revenue']:,.0f}/mo "
              f"(Profit: ${seg['monthly_profit']:,.0f}/mo)")

    print(f"\n⚠️  HIGH-RISK SEGMENTS ({len(summary_stats['high_risk_segments'])} total):")
    for seg in summary_stats['high_risk_segments'][:5]:
        print(f"  • {seg['segment']} ({seg['tier']}) - Risk: {seg['risk_score']:.0f}/100")
        for factor in seg['risk_factors'][:2]:
            print(f"    - {factor}")

    # Save summary report
    summary_file = os.path.join(
        output_dir,
        f"SUMMARY_REPORT_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    )

    with open(summary_file, 'w') as f:
        json.dump({
            'analysis_metadata': {
                'timestamp': datetime.now().isoformat(),
                'total_segments': len(segments),
                'segments_analyzed': summary_stats['total_segments_analyzed'],
                'tiers_analyzed': tier_priority
            },
            'financial_projections': {
                'monthly_revenue': round(summary_stats['total_projected_revenue'], 2),
                'monthly_profit': round(summary_stats['total_projected_profit'], 2),
                'annual_revenue': round(summary_stats['total_projected_revenue'] * 12, 2),
                'annual_profit': round(summary_stats['total_projected_profit'] * 12, 2)
            },
            'average_prices': {
                tier: round(np.mean(prices), 2)
                for tier, prices in summary_stats['average_optimal_prices'].items()
            },
            'top_segments': best_segments[:20],
            'high_risk_segments': summary_stats['high_risk_segments']
        }, f, indent=2)

    print(f"\n📁 Reports saved to: {output_dir}")
    print(f"   - {len(all_reports)} individual segment reports")
    print(f"   - 1 summary report: {os.path.basename(summary_file)}")

    # Generate dashboard data
    dashboard_file = os.path.join(output_dir, "dashboard_data.json")

    dashboard_data = {
        'last_updated': datetime.now().isoformat(),
        'kpi_summary': {
            'total_monthly_revenue': round(summary_stats['total_projected_revenue'], 2),
            'total_monthly_profit': round(summary_stats['total_projected_profit'], 2),
            'segments_analyzed': summary_stats['total_segments_analyzed'],
            'avg_risk_score': round(
                np.mean([s['risk_score'] for s in summary_stats['high_risk_segments']])
                if summary_stats['high_risk_segments'] else 0,
                2
            )
        },
        'tier_distribution': {
            tier: {
                'avg_price': round(np.mean(prices), 2),
                'min_price': round(np.min(prices), 2),
                'max_price': round(np.max(prices), 2),
                'std_dev': round(np.std(prices), 2),
                'segment_count': len(prices)
            }
            for tier, prices in summary_stats['average_optimal_prices'].items()
        },
        'geographic_breakdown': _calculate_geographic_breakdown(all_reports),
        'industry_breakdown': _calculate_industry_breakdown(all_reports),
        'risk_distribution': _calculate_risk_distribution(summary_stats['high_risk_segments'])
    }

    with open(dashboard_file, 'w') as f:
        json.dump(dashboard_data, f, indent=2)

    print(f"   - 1 dashboard data file: {os.path.basename(dashboard_file)}")

    print(f"\n✅ Analysis complete! {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 80)

    return all_reports, summary_stats


def _calculate_geographic_breakdown(reports: List[Dict]) -> Dict[str, Any]:
    """Calculate revenue breakdown by geographic region."""
    geo_revenue = {}

    for report in reports:
        region = report['segment']['geographic_region']
        for tier_data in report['tiers'].values():
            revenue = tier_data['tier_pricing'][next(iter(tier_data['tier_pricing']))]['expected_revenue'] * 30

            if region not in geo_revenue:
                geo_revenue[region] = 0
            geo_revenue[region] += revenue

    return {
        region: round(revenue, 2)
        for region, revenue in sorted(geo_revenue.items(), key=lambda x: x[1], reverse=True)
    }


def _calculate_industry_breakdown(reports: List[Dict]) -> Dict[str, Any]:
    """Calculate revenue breakdown by industry."""
    industry_revenue = {}

    for report in reports:
        industry = report['segment']['industry']
        for tier_data in report['tiers'].values():
            revenue = tier_data['tier_pricing'][next(iter(tier_data['tier_pricing']))]['expected_revenue'] * 30

            if industry not in industry_revenue:
                industry_revenue[industry] = 0
            industry_revenue[industry] += revenue

    return {
        industry: round(revenue, 2)
        for industry, revenue in sorted(industry_revenue.items(), key=lambda x: x[1], reverse=True)[:15]
    }


def _calculate_risk_distribution(high_risk_segments: List[Dict]) -> Dict[str, int]:
    """Calculate distribution of risk scores."""
    risk_buckets = {
        '0-20': 0,
        '21-40': 0,
        '41-60': 0,
        '61-80': 0,
        '81-100': 0
    }

    for seg in high_risk_segments:
        score = seg['risk_score']
        if score <= 20:
            risk_buckets['0-20'] += 1
        elif score <= 40:
            risk_buckets['21-40'] += 1
        elif score <= 60:
            risk_buckets['41-60'] += 1
        elif score <= 80:
            risk_buckets['61-80'] += 1
        else:
            risk_buckets['81-100'] += 1

    return risk_buckets


if __name__ == "__main__":
    # Set random seed for reproducibility
    np.random.seed(42)

    # Run comprehensive analysis
    reports, stats = run_comprehensive_analysis(output_dir="./pricing_reports")
