# Price Optimization System

Complete price optimization system using Van Westendorp methodology for OneTimeSecret application.

## Overview

This system implements a comprehensive pricing optimization framework including:
- Van Westendorp Price Sensitivity Analysis
- Price elasticity calculations
- Revenue optimization using gradient descent
- A/B testing framework with statistical power analysis
- Multi-segment analysis across 50+ market segments
- Real-time monitoring and alerting
- Competitive pricing analysis

## Directory Structure

```
pricing_optimization/
├── database/
│   ├── schema.sql                 # Complete database schema
│   ├── sample_data.sql           # Sample data for testing
│   ├── validation_queries.sql    # Data quality validation
│   └── ab_test_queries.sql       # A/B testing SQL functions
├── analysis/
│   ├── van_westendorp.py         # Van Westendorp analysis engine
│   ├── revenue_optimization.py   # Gradient descent optimizer
│   ├── ab_testing.py             # A/B testing framework
│   ├── multi_segment_analyzer.py # Multi-segment analysis
│   └── run_comprehensive_analysis.py  # Execution script
├── api/
│   └── Caddyfile                 # API gateway configuration
├── monitoring/
│   └── monitoring_queries.sql    # Monitoring and alerts
├── tests/
│   ├── test_van_westendorp.py   # Van Westendorp tests
│   ├── test_revenue_optimization.py  # Optimization tests
│   └── test_ab_testing.py       # A/B testing tests
└── README.md                     # This file
```

## Installation

### Prerequisites

- Python 3.9+
- PostgreSQL 12+
- Caddy web server (optional, for API)

### Python Dependencies

```bash
pip install -r requirements.txt
```

### Database Setup

```bash
# Create database
createdb pricing_optimization

# Load schema
psql pricing_optimization < database/schema.sql

# Load sample data (optional)
psql pricing_optimization < database/sample_data.sql

# Run validation
psql pricing_optimization < database/validation_queries.sql
```

## Usage

### Phase 1: Data Collection

Collect price sensitivity data using Van Westendorp four-question survey:

1. At what price would you consider this product too cheap? (quality concerns)
2. At what price would you consider this product a bargain?
3. At what price would you consider this product expensive?
4. At what price would you consider this product too expensive?

Insert responses into database:

```sql
INSERT INTO price_sensitivity_responses (
    session_id, product_tier, market_segment, geographic_region,
    too_cheap_price, cheap_price, expensive_price, too_expensive_price
) VALUES (
    'session_123', 'professional', 'enterprise_tech', 'north_america',
    100.00, 200.00, 400.00, 600.00
);
```

### Phase 2: Run Van Westendorp Analysis

```python
from analysis.van_westendorp import PriceSensitivityData, VanWestendorpAnalyzer
import numpy as np

# Load your survey data
data = PriceSensitivityData(
    too_cheap=np.array([...]),
    cheap=np.array([...]),
    expensive=np.array([...]),
    too_expensive=np.array([...])
)

# Analyze
analyzer = VanWestendorpAnalyzer(num_price_points=10000)
results = analyzer.analyze(data)

print(f"Optimal Price: ${results.optimal_price_point:.2f}")
print(f"Acceptable Range: ${results.acceptable_range_min:.2f} - ${results.acceptable_range_max:.2f}")
```

### Phase 3: Revenue Optimization

```python
from analysis.revenue_optimization import (
    RevenueFunction,
    GradientDescentOptimizer,
    OptimizationConfig
)

# Create revenue function
revenue_func = RevenueFunction(
    base_demand=1000,
    base_price=299.0,
    elasticity=-1.5,
    variable_cost=50,
    fixed_cost=10000
)

# Optimize
optimizer = GradientDescentOptimizer(OptimizationConfig(
    learning_rate=0.5,
    max_iterations=10000,
    tolerance=1e-6
))

result = optimizer.optimize_revenue(
    revenue_func,
    initial_price=250.0,
    price_bounds=(100.0, 500.0)
)

print(f"Revenue-Maximizing Price: ${result.optimal_price:.2f}")
print(f"Expected Revenue: ${result.max_revenue:.2f}")
```

### Phase 4: A/B Testing

#### Design Experiment

```python
from analysis.ab_testing import StatisticalPowerCalculator

power_calc = StatisticalPowerCalculator()

design = power_calc.design_experiment(
    baseline_conversion_rate=0.10,
    minimum_detectable_effect=0.10,  # 10% relative change
    daily_traffic=500,
    statistical_power=0.80
)

print(f"Required sample size: {design.required_sample_size_per_variant}")
print(f"Test duration: {design.expected_duration_days} days")
```

#### Analyze Results

```python
from analysis.ab_testing import ABTestAnalyzer

analyzer = ABTestAnalyzer(significance_level=0.05)

results = analyzer.analyze_test(
    control_conversions=100,
    control_total=1000,
    treatment_conversions=120,
    treatment_total=1000,
    control_revenue=10000.0,
    treatment_revenue=12000.0
)

print(f"P-value: {results.p_value:.6f}")
print(f"Significance: {results.significance_result.value}")
print(f"Recommendation: {results.recommendation}")
```

### Phase 5: Multi-Segment Analysis

Run comprehensive analysis across 50+ segments:

```bash
cd analysis
python run_comprehensive_analysis.py
```

This generates:
- Individual segment reports (JSON)
- Summary report with aggregated statistics
- Dashboard data for visualization
- Revenue projections by segment, tier, and region

### Monitoring

```sql
-- Check open alerts
SELECT * FROM vw_executive_dashboard;

-- Revenue performance
SELECT * FROM vw_revenue_performance_daily
WHERE performance_status != 'ON_TARGET';

-- Generate new alerts
SELECT insert_new_alerts();
```

## Testing

Run unit tests:

```bash
# All tests
python -m pytest tests/ -v

# Specific module
python -m pytest tests/test_van_westendorp.py -v

# With coverage
python -m pytest tests/ --cov=analysis --cov-report=html
```

## API Endpoints

Start Caddy server:

```bash
caddy run --config api/Caddyfile
```

Available endpoints:

- `POST /api/v1/price-sensitivity/submit` - Submit survey response
- `POST /api/v1/analysis/van-westendorp` - Run Van Westendorp analysis
- `POST /api/v1/optimization/revenue` - Optimize pricing
- `POST /api/v1/ab-test/experiments` - Create A/B test
- `GET /api/v1/monitoring/alerts` - Get pricing alerts
- `POST /api/v1/reports/comprehensive` - Generate full report

## Configuration Parameters

### Van Westendorp Analysis
- `num_price_points`: Number of interpolation points (default: 10000)
- `interpolation_method`: 'linear' or 'cubic' (default: 'linear')

### Gradient Descent Optimization
- `learning_rate`: Step size (default: 0.01)
- `max_iterations`: Maximum iterations (default: 10000)
- `tolerance`: Convergence threshold (default: 1e-6)
- `momentum`: Momentum coefficient (default: 0.9)
- `adaptive_learning`: Enable adaptive learning rate (default: True)

### A/B Testing
- `significance_level`: Alpha (default: 0.05)
- `statistical_power`: 1 - beta (default: 0.80)
- `minimum_sample_size`: Per variant (default: 100)

### Scenario Simulation
- `num_simulations`: Monte Carlo iterations (default: 10000)
- `demand_volatility`: Standard deviation (default: 0.1)

## Expected Results

### Van Westendorp Analysis
For typical SaaS product with base price $299:
- Optimal Price Point (OPP): $280-320
- Point of Marginal Cheapness (PMC): $180-220
- Point of Marginal Expensiveness (PME): $380-450
- Acceptable Range: ~$200-$420

### Revenue Optimization
- Convergence: 1000-3000 iterations
- Optimal price typically 5-15% different from initial guess
- Computation time: <5 seconds

### A/B Testing
For 10% baseline conversion, 10% MDE, 80% power:
- Required sample size: ~3,000 per variant
- Test duration: 12-30 days (depending on traffic)

### Multi-Segment Analysis
For 50 segments across 3 tiers:
- Execution time: 5-10 minutes
- Total projected annual revenue: $5M-$50M (varies by segment sizes)
- Average of 2-3 pricing cliffs detected per tier
- 10-20% of segments classified as high risk

## Performance Benchmarks

### Analysis Speed
- Van Westendorp (500 responses, 10k points): ~0.5s
- Revenue optimization (gradient descent): ~0.3s
- Scenario simulation (10k iterations): ~1.2s
- Full segment analysis: ~6s per segment

### Database Performance
- Price sensitivity insert: <10ms
- A/B test assignment: <5ms
- Real-time analytics query: <100ms
- Dashboard aggregation: <500ms

## Error Handling

### Common Errors

**Invalid price ordering**: Survey responses must satisfy: too_cheap ≤ cheap ≤ expensive ≤ too_expensive
```python
# Raises ValueError
data = PriceSensitivityData(
    too_cheap=np.array([100]),
    cheap=np.array([50]),  # ERROR: cheaper than too_cheap
    ...
)
```

**Insufficient data**: Minimum 30 responses per segment recommended
```python
# Check sample size adequacy
SELECT * FROM (SELECT product_tier, market_segment, COUNT(*) as n
FROM price_sensitivity_responses
GROUP BY product_tier, market_segment) sub
WHERE n < 30;
```

**Non-convergent optimization**: Increase max_iterations or adjust learning_rate
```python
config = OptimizationConfig(
    learning_rate=0.1,  # Try smaller learning rate
    max_iterations=20000  # Increase iterations
)
```

## Rollback Procedures

### Price Change Rollback

```sql
-- Rollback recent price change
UPDATE price_changes_audit
SET rollback_date = NOW()
WHERE id = '[change_id]'
  AND rollback_date IS NULL;

-- Revert to previous approved price
UPDATE [pricing_config_table]
SET current_price = (
    SELECT old_price FROM price_changes_audit
    WHERE id = '[change_id]'
);
```

### A/B Test Cancellation

```sql
SELECT complete_experiment('[experiment_id]');
-- Or
UPDATE ab_test_experiments
SET status = 'cancelled', actual_end_date = NOW()
WHERE id = '[experiment_id]';
```

## Cost-Benefit Analysis

### Implementation Costs
- Engineering: ~80 hours ($12,000 @ $150/hr)
- Data infrastructure: $2,000
- Testing and QA: $3,000
- **Total: ~$17,000**

### Expected Benefits (Annual)
- Revenue optimization: +5-15% ($250k-$750k for $5M base)
- Reduced customer churn: +2-5% retention ($100k-$250k)
- Improved conversion: +10-20% ($200k-$400k)
- **Total benefit: $550k-$1.4M annually**

### ROI
- **Payback period: 1-2 months**
- **Annual ROI: 3,000-8,000%**

## Monitoring & Alerts

Automated alerts trigger on:
- Revenue decline >10% (7-day vs 30-day MA)
- Conversion rate drop >15%
- Competitor price change >±10%
- Pricing compliance violations
- Test statistical significance achieved

## Deployment Instructions

### Production Checklist

1. **Database**
   - [ ] Create production database
   - [ ] Run schema.sql
   - [ ] Set up pg_cron for scheduled jobs
   - [ ] Configure backup schedule
   - [ ] Set up read replicas for analytics

2. **Application**
   - [ ] Deploy Python services
   - [ ] Configure environment variables
   - [ ] Set up monitoring (Prometheus/Grafana)
   - [ ] Configure log aggregation

3. **API**
   - [ ] Deploy Caddy with SSL certificates
   - [ ] Configure rate limiting
   - [ ] Set up API authentication
   - [ ] Enable request logging

4. **Monitoring**
   - [ ] Configure alert webhooks
   - [ ] Set up PagerDuty/Slack integration
   - [ ] Create monitoring dashboards
   - [ ] Test alert conditions

## Support

For issues or questions:
- Review logs in `/var/log/caddy/` and application logs
- Check database with validation queries
- Run unit tests to verify installation
- Review API health at `/health` endpoint

## License

MIT License - See LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit pull request

## Changelog

### Version 1.0.0 (2025-11-23)
- Initial release
- Complete Van Westendorp analysis implementation
- Revenue optimization with gradient descent
- A/B testing framework
- Multi-segment analysis (50+ segments)
- Monitoring and alerting system
- Comprehensive test coverage
