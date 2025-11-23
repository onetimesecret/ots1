# Price Optimization System - Deployment Guide

Complete deployment and usage guide for the Van Westendorp Price Optimization System for OneTimeSecret.

## Table of Contents

1. [System Overview](#system-overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Database Setup](#database-setup)
5. [Python Environment Setup](#python-environment-setup)
6. [Running Analyses](#running-analyses)
7. [API Deployment](#api-deployment)
8. [Monitoring & Alerts](#monitoring--alerts)
9. [A/B Testing](#ab-testing)
10. [Troubleshooting](#troubleshooting)

---

## System Overview

The Price Optimization System uses the Van Westendorp Price Sensitivity Meter methodology combined with:
- **Phase 1**: PostgreSQL database schema for survey data collection
- **Phase 2**: Python analysis engines (Van Westendorp, elasticity, Monte Carlo)
- **Phase 3**: Gradient descent optimization for revenue maximization
- **Phase 4**: A/B testing framework with statistical rigor
- **Phase 5**: Production monitoring and alerting

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Price Optimization System                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │   Survey     │───▶│   Van        │───▶│   Gradient   │     │
│  │   Data       │    │   Westendorp │    │   Descent    │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │   Price      │───▶│   Monte      │───▶│   A/B        │     │
│  │   Elasticity │    │   Carlo      │    │   Testing    │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │   Monitoring │◀───│   Alerts     │◀───│   Metrics    │     │
│  │   Dashboard  │    │   System     │    │   Collector  │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu 20.04+) or macOS
- **Memory**: Minimum 4GB RAM (8GB+ recommended for large simulations)
- **Storage**: 10GB free space
- **Network**: Internet connection for package installation

### Software Requirements

- **PostgreSQL**: 14+ (with extensions: uuid-ossp, pgcrypto)
- **Python**: 3.9 or higher
- **Caddy**: 2.6+ (for API reverse proxy)
- **Git**: For version control

### Optional

- **Docker**: For containerized deployment
- **Prometheus**: For advanced metrics collection
- **Grafana**: For visualization dashboards

---

## Installation

### 1. Clone Repository

```bash
cd /path/to/your/projects
git clone <repository-url>
cd ots1/price_optimization
```

### 2. Install System Dependencies

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y postgresql-14 postgresql-contrib python3.9 python3-pip caddy
```

**macOS (using Homebrew):**
```bash
brew install postgresql@14 python@3.9 caddy
brew services start postgresql@14
```

---

## Database Setup

### 1. Create Database

```bash
# Connect to PostgreSQL
sudo -u postgres psql

# Create database and user
CREATE DATABASE price_optimization;
CREATE USER pricing_admin WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE price_optimization TO pricing_admin;

# Exit psql
\q
```

### 2. Initialize Schema

```bash
# Navigate to database directory
cd /home/user/ots1/price_optimization/database

# Run schema creation
psql -U pricing_admin -d price_optimization -f 01_schema.sql

# Load sample data
psql -U pricing_admin -d price_optimization -f 02_sample_data.sql

# Validate installation
psql -U pricing_admin -d price_optimization -f 03_validation_queries.sql
```

### 3. Verify Installation

```bash
psql -U pricing_admin -d price_optimization -c "
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
"
```

**Expected Output (17 tables):**
```
           table_name
---------------------------------
 ab_test_experiments
 ab_test_participants
 ab_test_results
 alert_history
 competitive_pricing
 market_segments
 optimization_simulations
 price_changes_history
 price_elasticity_coefficients
 price_sensitivity_responses
 pricing_alerts
 pricing_metrics
 product_tiers
 survey_respondents
 van_westendorp_analysis
```

---

## Python Environment Setup

### 1. Create Virtual Environment

```bash
cd /home/user/ots1/price_optimization

# Create virtual environment
python3.9 -m venv venv

# Activate virtual environment
source venv/bin/activate  # Linux/macOS
# or
venv\Scripts\activate     # Windows
```

### 2. Install Python Dependencies

```bash
pip install --upgrade pip
pip install -r backend/requirements.txt
```

### 3. Verify Installation

```python
python -c "
import numpy as np
import scipy
import psycopg2
print('✓ All dependencies installed successfully')
print(f'NumPy version: {np.__version__}')
print(f'SciPy version: {scipy.__version__}')
"
```

---

## Running Analyses

### Phase 2: Van Westendorp Analysis

```bash
cd backend/src/analysis

# Run Van Westendorp analyzer
python van_westendorp.py
```

**Expected Output:**
```
================================================================================
VAN WESTENDORP PRICE SENSITIVITY METER - ANALYSIS RESULTS
================================================================================

Sample Size: 100
Confidence Score: 82.45%
Data Quality Score: 87.32%

--------------------------------------------------------------------------------
KEY PRICE POINTS:
--------------------------------------------------------------------------------
Point of Marginal Cheapness (PMC):      $    6.23
Indifference Price Point (IPP):         $    8.95
Optimal Price Point (OPP):              $   10.12
Point of Marginal Expensiveness (PME):  $   18.47

--------------------------------------------------------------------------------
RECOMMENDED PRICING:
--------------------------------------------------------------------------------
Recommended Price: $9.47
```

### Phase 2: Price Elasticity Calculation

```bash
python price_elasticity.py
```

**Expected Output:**
```
================================================================================
PRICE ELASTICITY OF DEMAND - ESTIMATION RESULTS
================================================================================
True Elasticity: -1.5

Method: LOG_LOG
--------------------------------------------------------------------------------
Estimated Elasticity: -1.5234
Standard Error: 0.0892
95% CI: [-1.6982, -1.3486]
R²: 0.8923
P-value: 0.000001
Statistically Significant: True
Interpretation: Elastic - quantity sensitive to price changes
True value in CI: True
```

### Phase 2: Monte Carlo Simulation

```bash
python monte_carlo_simulation.py
```

**Expected Output:**
```
Running 50 simulations (50 prices × 1 conditions)
Monte Carlo iterations per simulation: up to 10000
Total maximum iterations: 500,000

Simulating: 100%|████████████████████| 50/50 [02:15<00:00, 2.7s/it]

================================================================================
OPTIMAL PRICE RECOMMENDATION
================================================================================
Optimal price: $9.00
Expected annual revenue: $3,888,000.00
Expected ROI: 185.32%
CLV/CAC ratio: 300.00x
Risk score: 0.18/1.00
Breakeven probability: 99.4%
```

### Phase 3: Gradient Descent Optimization

```bash
cd ../optimization
python gradient_descent_optimizer.py
```

**Expected Output:**
```
================================================================================
GRADIENT DESCENT PRICE OPTIMIZATION
================================================================================

Optimizing for: REVENUE
--------------------------------------------------------------------------------
Optimal Price: $9.23
Expected Annual Revenue: $3,950,482.00
Expected Annual Profit: $2,891,234.00
Expected Customers: 35,683
Conversion Rate: 35.68%
Gross Margin: 48.52%
CLV/CAC Ratio: 308.33x
Iterations: 47
Converged: True
Constraints Satisfied: True
95% CI: $8.67 - $9.89
```

### Phase 4: A/B Testing

```bash
cd ../testing
python ab_test_framework.py
```

---

## API Deployment

### 1. Configure Environment

```bash
# Create .env file
cat > /home/user/ots1/price_optimization/config/.env << EOF
DATABASE_URL=postgresql://pricing_admin:your_secure_password@localhost:5432/price_optimization
API_PORT=8000
LOG_LEVEL=INFO
SECRET_KEY=your_secret_key_here
CORS_ORIGINS=http://localhost:3000,https://onetimesecret.com
EOF
```

### 2. Start API Server

```bash
cd /home/user/ots1/price_optimization

# Activate virtual environment
source venv/bin/activate

# Start FastAPI server
uvicorn backend.src.api.main:app --host 0.0.0.0 --port 8000 --reload
```

### 3. Configure Caddy Reverse Proxy

```bash
# Copy Caddy configuration
sudo cp config/Caddyfile /etc/caddy/Caddyfile

# Validate configuration
caddy validate --config /etc/caddy/Caddyfile

# Start Caddy
sudo systemctl start caddy
sudo systemctl enable caddy
```

### 4. Test API Endpoints

```bash
# Health check
curl http://localhost:8080/health

# Van Westendorp analysis
curl -X POST http://localhost:8080/api/v1/analysis/van-westendorp \
  -H "Content-Type: application/json" \
  -d '{
    "too_cheap": [500, 600, 550],
    "bargain": [800, 900, 850],
    "expensive": [1500, 1600, 1550],
    "too_expensive": [2000, 2200, 2100]
  }'

# Price recommendation
curl http://localhost:8080/api/v1/recommend/price?tier=starter
```

---

## Monitoring & Alerts

### 1. Configure Alerts

```sql
-- Connect to database
psql -U pricing_admin -d price_optimization

-- View current alerts
SELECT alert_name, alert_type, is_active, last_triggered_at
FROM pricing_alerts
WHERE is_active = TRUE;

-- Add custom alert
INSERT INTO pricing_alerts (
    alert_name, alert_type,
    threshold_value, threshold_operator,
    notify_emails, is_active
) VALUES (
    'Revenue Drop Severe',
    'revenue_drop',
    -0.30,  -- 30% drop
    '<',
    ARRAY['pricing@onetimesecret.com'],
    TRUE
);
```

### 2. Monitor System Health

```bash
# Run health check
psql -U pricing_admin -d price_optimization -c "SELECT * FROM system_health_check();"

# Check recent alerts
psql -U pricing_admin -d price_optimization -c "SELECT * FROM run_all_alerts();"
```

### 3. View Dashboards

```bash
# Current pricing dashboard
psql -U pricing_admin -d price_optimization -c "
SELECT * FROM current_pricing_dashboard
ORDER BY metric_date DESC
LIMIT 7;
"

# Conversion funnel
psql -U pricing_admin -d price_optimization -c "
SELECT * FROM conversion_funnel
WHERE metric_date >= CURRENT_DATE - INTERVAL '7 days';
"

# Competitive position
psql -U pricing_admin -d price_optimization -c "
SELECT * FROM competitive_position;
"
```

---

## A/B Testing

### 1. Create New Test

```bash
# Run A/B test SQL setup
psql -U pricing_admin -d price_optimization -f database/04_ab_test_queries.sql
```

### 2. Assign Users to Test Groups

```python
from backend.src.testing.ab_test_framework import ABTestAssigner

assigner = ABTestAssigner(
    experiment_id="test-001",
    traffic_split=[0.33, 0.33, 0.34]  # Control + 2 variants
)

# Assign user
group_name, group_index = assigner.assign_group("user@example.com")
print(f"User assigned to: {group_name}")
```

### 3. Analyze Results

```bash
# After test completion
psql -U pricing_admin -d price_optimization << EOF
-- Replace with your experiment ID
\set exp_id 'test0001-0001-0001-0001-000000000001'

-- View results
SELECT * FROM ab_test_results
WHERE experiment_id = :'exp_id';
EOF
```

---

## Performance Benchmarks

### Expected Performance

| Operation | Sample Size | Time | Throughput |
|-----------|------------|------|------------|
| Van Westendorp Analysis | 100 responses | <1s | 100+ analyses/min |
| Price Elasticity | 150 observations | <2s | 50+ calculations/min |
| Monte Carlo (10k iter) | 50 price points | 2-3min | 20+ sims/min |
| Gradient Descent | Single optimization | <5s | 12+ opts/min |
| A/B Test Assignment | 1M users | <30s | 33k+ users/sec |

---

## Troubleshooting

### Database Connection Errors

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -U pricing_admin -d price_optimization -c "SELECT 1;"

# Check credentials
cat ~/.pgpass  # Should contain: localhost:5432:price_optimization:pricing_admin:password
```

### Python Import Errors

```bash
# Verify virtual environment is activated
which python  # Should point to venv/bin/python

# Reinstall dependencies
pip install --force-reinstall -r backend/requirements.txt
```

### Optimization Convergence Issues

If gradient descent doesn't converge:
1. Check if price elasticity is negative (required for normal goods)
2. Verify conversion rates are between 0 and 1
3. Adjust initial guess to be within reasonable bounds
4. Increase max_iterations parameter

### Slow Monte Carlo Simulations

To speed up simulations:
```python
# Enable parallel processing
results = simulator.run_simulation(
    market_conditions=[MarketCondition.BASE],
    parallel=True,  # Enable multiprocessing
    show_progress=True
)

# Reduce iterations (trade accuracy for speed)
params.n_iterations = 1000  # Instead of 10000
```

---

## File Paths Reference

All code and configurations are located in: `/home/user/ots1/price_optimization/`

```
price_optimization/
├── database/
│   ├── 01_schema.sql                 # Database schema
│   ├── 02_sample_data.sql            # Sample data
│   ├── 03_validation_queries.sql     # Validation
│   ├── 04_ab_test_queries.sql        # A/B testing
│   └── 05_monitoring_queries.sql     # Monitoring
├── backend/
│   ├── requirements.txt              # Python dependencies
│   └── src/
│       ├── analysis/
│       │   ├── van_westendorp.py          # Van Westendorp analyzer
│       │   ├── price_elasticity.py        # Elasticity calculator
│       │   └── monte_carlo_simulation.py  # Monte Carlo simulator
│       ├── optimization/
│       │   └── gradient_descent_optimizer.py  # Optimizer
│       └── testing/
│           └── ab_test_framework.py       # A/B testing
└── config/
    ├── Caddyfile                     # Reverse proxy config
    └── .env                          # Environment variables
```

---

## Support

For issues or questions:
- Review validation queries: `database/03_validation_queries.sql`
- Check system health: Run `system_health_check()`
- Review logs: `/var/log/caddy/price-optimization.log`

---

**Last Updated**: 2024-11-23
**Version**: 1.0.0
**Author**: Price Optimization Team
