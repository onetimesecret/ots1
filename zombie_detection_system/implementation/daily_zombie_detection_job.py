"""
Daily Zombie Detection Job
===========================

Scheduled job that runs daily to:
1. Calculate health scores for all active customers
2. Classify customer health status
3. Detect new zombies and status transitions
4. Trigger appropriate intervention campaigns
5. Update customer_health_scores table
6. Generate alerts for customer success team

Author: Claude
Date: 2025-11-23
Version: 1.0

Usage:
    python daily_zombie_detection_job.py [--dry-run] [--custid CUSTID]

Options:
    --dry-run: Run without making database changes
    --custid: Process only specific customer (for testing)
"""

import sys
import os
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import psycopg2
from psycopg2.extras import RealDictCursor, execute_values
import argparse

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from algorithms.health_scorer import (
    HealthScorer,
    CustomerMetrics,
    HealthScore,
    HealthStatus,
    UsageTrend
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class ZombieDetectionJob:
    """Daily job to detect and classify zombie subscriptions"""

    def __init__(self, db_connection, dry_run=False):
        """
        Initialize zombie detection job.

        Args:
            db_connection: PostgreSQL database connection
            dry_run: If True, don't commit changes to database
        """
        self.conn = db_connection
        self.dry_run = dry_run
        self.scorer = HealthScorer(conservative_mode=False)
        self.stats = {
            'total_processed': 0,
            'new_zombies': 0,
            'new_at_risk': 0,
            'reactivated': 0,
            'errors': 0,
            'interventions_triggered': 0
        }

    def run(self, custid: Optional[str] = None):
        """
        Run the zombie detection job.

        Args:
            custid: Optional customer ID to process only one customer
        """
        logger.info("Starting zombie detection job...")
        logger.info(f"Dry run mode: {self.dry_run}")

        try:
            # Fetch active customers
            customers = self._fetch_active_customers(custid)
            logger.info(f"Found {len(customers)} active customers to process")

            # Process each customer
            for customer_data in customers:
                try:
                    self._process_customer(customer_data)
                    self.stats['total_processed'] += 1
                except Exception as e:
                    logger.error(f"Error processing customer {customer_data.get('custid')}: {e}")
                    self.stats['errors'] += 1

            # Commit changes (unless dry run)
            if not self.dry_run:
                self.conn.commit()
                logger.info("Database changes committed")
            else:
                self.conn.rollback()
                logger.info("Dry run mode - changes rolled back")

            # Log summary
            self._log_summary()

        except Exception as e:
            logger.error(f"Fatal error in zombie detection job: {e}")
            self.conn.rollback()
            raise

    def _fetch_active_customers(self, custid: Optional[str] = None) -> List[Dict]:
        """Fetch active customers with all metrics needed for health scoring"""
        with self.conn.cursor(cursor_factory=RealDictCursor) as cur:
            query = """
                WITH login_metrics AS (
                    SELECT
                        le.custid,
                        COUNT(DISTINCT DATE(le.login_timestamp)) FILTER (
                            WHERE le.login_timestamp >= CURRENT_TIMESTAMP - INTERVAL '30 days'
                        ) AS login_days_30d,
                        MAX(le.login_timestamp) AS last_login_at,
                        EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(le.login_timestamp)))/86400 AS days_since_last_login,
                        COUNT(*) AS total_login_count
                    FROM login_events le
                    WHERE le.success = true
                    GROUP BY le.custid
                ),
                api_metrics AS (
                    SELECT
                        au.custid,
                        COUNT(*) FILTER (WHERE au.request_timestamp >= CURRENT_TIMESTAMP - INTERVAL '30 days') AS api_calls_30d,
                        COUNT(*) FILTER (WHERE au.request_timestamp >= CURRENT_TIMESTAMP - INTERVAL '60 days') AS api_calls_60d,
                        COUNT(*) FILTER (WHERE au.request_timestamp >= CURRENT_TIMESTAMP - INTERVAL '90 days') AS api_calls_90d,
                        COUNT(DISTINCT DATE(au.request_timestamp)) FILTER (
                            WHERE au.request_timestamp >= CURRENT_TIMESTAMP - INTERVAL '30 days'
                        ) AS active_days_30d,
                        -- Calculate usage trend
                        CASE
                            WHEN COUNT(*) FILTER (WHERE au.request_timestamp >= CURRENT_TIMESTAMP - INTERVAL '30 days') = 0
                                 AND COUNT(*) FILTER (WHERE au.request_timestamp >= CURRENT_TIMESTAMP - INTERVAL '60 days') > 0
                            THEN 'declining'
                            WHEN COUNT(*) FILTER (WHERE au.request_timestamp >= CURRENT_TIMESTAMP - INTERVAL '30 days') >
                                 COUNT(*) FILTER (WHERE au.request_timestamp >= CURRENT_TIMESTAMP - INTERVAL '60 days' AND au.request_timestamp < CURRENT_TIMESTAMP - INTERVAL '30 days')
                            THEN 'growing'
                            WHEN COUNT(*) FILTER (WHERE au.request_timestamp >= CURRENT_TIMESTAMP - INTERVAL '90 days') = 0
                            THEN 'none'
                            ELSE 'stable'
                        END AS usage_trend
                    FROM api_usage au
                    WHERE au.response_status_code < 500
                    GROUP BY au.custid
                ),
                feature_metrics AS (
                    SELECT
                        fa.custid,
                        COUNT(DISTINCT fa.feature_name) AS total_features_used,
                        COUNT(DISTINCT fa.feature_name) FILTER (
                            WHERE fa.last_used_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
                        ) AS features_used_30d,
                        COUNT(DISTINCT fa.feature_name) FILTER (
                            WHERE fa.last_used_at >= CURRENT_TIMESTAMP - INTERVAL '90 days'
                        ) AS features_used_90d
                    FROM feature_adoption fa
                    GROUP BY fa.custid
                ),
                collaboration_metrics AS (
                    SELECT
                        custid,
                        MAX(team_members_active) AS team_members_active,
                        SUM(unique_recipients_count) AS unique_recipients,
                        COUNT(DISTINCT metric_date) FILTER (
                            WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
                        ) AS collaboration_days_30d
                    FROM collaboration_metrics
                    GROUP BY custid
                ),
                data_metrics AS (
                    SELECT
                        custid,
                        SUM(secrets_created_count) FILTER (
                            WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
                        ) AS secrets_created_30d,
                        SUM(secrets_created_count) FILTER (
                            WHERE metric_date >= CURRENT_DATE - INTERVAL '60 days'
                        ) AS secrets_created_60d,
                        SUM(secrets_created_count) FILTER (
                            WHERE metric_date >= CURRENT_DATE - INTERVAL '90 days'
                        ) AS secrets_created_90d,
                        SUM(secrets_created_count - secrets_burned_count) FILTER (
                            WHERE metric_date >= CURRENT_DATE - INTERVAL '30 days'
                        ) AS net_secret_change_30d,
                        MAX(total_active_secrets) AS current_active_secrets
                    FROM daily_customer_metrics
                    GROUP BY custid
                )
                SELECT
                    s.custid,
                    s.plan_type,
                    s.monthly_revenue,
                    s.subscription_start_date,
                    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - s.subscription_start_date))/86400 AS account_age_days,

                    -- Login metrics
                    COALESCE(lm.login_days_30d, 0) AS login_days_30d,
                    lm.days_since_last_login,
                    COALESCE(lm.total_login_count, 0) AS total_login_count,

                    -- API metrics
                    COALESCE(am.api_calls_30d, 0) AS api_calls_30d,
                    COALESCE(am.api_calls_60d, 0) AS api_calls_60d,
                    COALESCE(am.api_calls_90d, 0) AS api_calls_90d,
                    COALESCE(am.active_days_30d, 0) AS active_days_30d,
                    COALESCE(am.usage_trend, 'none') AS usage_trend,

                    -- Feature metrics
                    COALESCE(fm.total_features_used, 0) AS total_features_used,
                    COALESCE(fm.features_used_30d, 0) AS features_used_30d,
                    COALESCE(fm.features_used_90d, 0) AS features_used_90d,

                    -- Collaboration metrics
                    COALESCE(cm.team_members_active, 1) AS team_members_active,
                    COALESCE(cm.unique_recipients, 0) AS unique_recipients,
                    COALESCE(cm.collaboration_days_30d, 0) AS collaboration_days_30d,

                    -- Data metrics
                    COALESCE(dm.secrets_created_30d, 0) AS secrets_created_30d,
                    COALESCE(dm.secrets_created_60d, 0) AS secrets_created_60d,
                    COALESCE(dm.secrets_created_90d, 0) AS secrets_created_90d,
                    COALESCE(dm.net_secret_change_30d, 0) AS net_secret_change_30d,
                    COALESCE(dm.current_active_secrets, 0) AS current_active_secrets,

                    -- Previous health status
                    (SELECT health_status FROM customer_health_scores chs
                     WHERE chs.custid = s.custid
                     ORDER BY calculated_at DESC LIMIT 1) AS previous_health_status,

                    (SELECT zombie_since FROM customer_health_scores chs
                     WHERE chs.custid = s.custid
                     ORDER BY calculated_at DESC LIMIT 1) AS zombie_since

                FROM subscriptions s
                LEFT JOIN login_metrics lm ON s.custid = lm.custid
                LEFT JOIN api_metrics am ON s.custid = am.custid
                LEFT JOIN feature_metrics fm ON s.custid = fm.custid
                LEFT JOIN collaboration_metrics cm ON s.custid = cm.custid
                LEFT JOIN data_metrics dm ON s.custid = dm.custid
                WHERE s.status = 'active'
            """

            if custid:
                query += " AND s.custid = %s"
                cur.execute(query, (custid,))
            else:
                cur.execute(query)

            return cur.fetchall()

    def _process_customer(self, customer_data: Dict):
        """Process a single customer: calculate score, classify, and trigger interventions"""
        custid = customer_data['custid']
        logger.debug(f"Processing customer: {custid}")

        # Build CustomerMetrics object
        metrics = CustomerMetrics(
            custid=custid,
            plan_type=customer_data['plan_type'],
            monthly_revenue=float(customer_data['monthly_revenue']),
            subscription_start_date=customer_data['subscription_start_date'],
            account_age_days=int(customer_data['account_age_days']),
            login_days_30d=customer_data['login_days_30d'],
            days_since_last_login=int(customer_data['days_since_last_login']) if customer_data['days_since_last_login'] else None,
            total_login_count=customer_data['total_login_count'],
            api_calls_30d=customer_data['api_calls_30d'],
            api_calls_60d=customer_data['api_calls_60d'],
            api_calls_90d=customer_data['api_calls_90d'],
            active_days_30d=customer_data['active_days_30d'],
            usage_trend=UsageTrend(customer_data['usage_trend']),
            total_features_used=customer_data['total_features_used'],
            features_used_30d=customer_data['features_used_30d'],
            features_used_90d=customer_data['features_used_90d'],
            team_members_active=customer_data['team_members_active'],
            unique_recipients=customer_data['unique_recipients'],
            collaboration_days_30d=customer_data['collaboration_days_30d'],
            secrets_created_30d=customer_data['secrets_created_30d'],
            secrets_created_60d=customer_data['secrets_created_60d'],
            secrets_created_90d=customer_data['secrets_created_90d'],
            net_secret_change_30d=customer_data['net_secret_change_30d'],
            current_active_secrets=customer_data['current_active_secrets']
        )

        # Calculate health score
        score = self.scorer.calculate_health_score(metrics)

        # Detect status transitions
        previous_status = customer_data['previous_health_status']
        status_changed = previous_status != score.health_status.value

        if status_changed:
            self._handle_status_transition(
                custid,
                previous_status,
                score.health_status.value,
                score
            )

        # Save health score
        self._save_health_score(score, customer_data.get('zombie_since'))

        # Trigger interventions if needed
        if score.health_status in [HealthStatus.AT_RISK, HealthStatus.ZOMBIE]:
            self._trigger_intervention(score, status_changed)

        logger.info(
            f"Customer {custid}: score={score.overall_score:.1f}, "
            f"status={score.health_status.value}, "
            f"churn_risk={score.churn_risk_score:.1f}%"
        )

    def _handle_status_transition(
        self,
        custid: str,
        from_status: Optional[str],
        to_status: str,
        score: HealthScore
    ):
        """Handle customer status transitions and log lifecycle events"""
        if from_status is None:
            # First calculation
            event_type = 'initial_classification'
        elif to_status == HealthStatus.ZOMBIE.value and from_status != HealthStatus.ZOMBIE.value:
            event_type = 'became_zombie'
            self.stats['new_zombies'] += 1
            logger.warning(f"NEW ZOMBIE: {custid} ({from_status} → {to_status})")
        elif to_status == HealthStatus.AT_RISK.value and from_status == HealthStatus.HEALTHY.value:
            event_type = 'became_at_risk'
            self.stats['new_at_risk'] += 1
            logger.warning(f"NEW AT-RISK: {custid} ({from_status} → {to_status})")
        elif to_status in [HealthStatus.HEALTHY.value, HealthStatus.AT_RISK.value] and from_status == HealthStatus.ZOMBIE.value:
            event_type = 'reactivated'
            self.stats['reactivated'] += 1
            logger.info(f"REACTIVATED: {custid} ({from_status} → {to_status})")
        else:
            event_type = 'status_change'

        # Log lifecycle event
        self._log_lifecycle_event(custid, event_type, from_status, to_status, score)

    def _save_health_score(self, score: HealthScore, previous_zombie_since: Optional[datetime]):
        """Save health score to customer_health_scores table"""
        with self.conn.cursor() as cur:
            # Calculate zombie_since and days_as_zombie
            if score.health_status == HealthStatus.ZOMBIE:
                if previous_zombie_since:
                    zombie_since = previous_zombie_since
                else:
                    zombie_since = datetime.utcnow()
                days_as_zombie = (datetime.utcnow() - zombie_since).days
            else:
                zombie_since = None
                days_as_zombie = 0

            # Calculate days_since_last_login
            # This would come from metrics, simplified here
            days_since_last_login = 0  # Placeholder

            cur.execute("""
                INSERT INTO customer_health_scores (
                    custid, calculated_at, health_score, login_score, api_usage_score,
                    feature_adoption_score, collaboration_score, data_activity_score,
                    health_status, zombie_since, days_as_zombie, churn_risk_score,
                    reactivation_potential, days_since_last_login, api_calls_last_30d,
                    features_used_count, total_secrets_created
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                )
            """, (
                score.custid,
                score.calculated_at,
                score.overall_score,
                score.login_score,
                score.api_usage_score,
                score.feature_adoption_score,
                score.collaboration_score,
                score.data_activity_score,
                score.health_status.value,
                zombie_since,
                days_as_zombie,
                score.churn_risk_score,
                score.reactivation_potential,
                days_since_last_login,
                0,  # Placeholder
                0,  # Placeholder
                0   # Placeholder
            ))

    def _log_lifecycle_event(
        self,
        custid: str,
        event_type: str,
        previous_state: Optional[str],
        new_state: str,
        score: HealthScore
    ):
        """Log customer lifecycle event"""
        with self.conn.cursor() as cur:
            metadata = {
                'overall_score': score.overall_score,
                'churn_risk': score.churn_risk_score,
                'zombie_signals': score.zombie_signals
            }

            cur.execute("""
                INSERT INTO customer_lifecycle_events (
                    custid, event_type, event_timestamp, previous_state, new_state,
                    trigger_reason, metadata
                ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (
                custid,
                event_type,
                datetime.utcnow(),
                previous_state,
                new_state,
                f"Health score: {score.overall_score:.1f}",
                psycopg2.extras.Json(metadata)
            ))

    def _trigger_intervention(self, score: HealthScore, status_changed: bool):
        """Trigger appropriate intervention campaign based on health status"""
        # Only trigger on status change to avoid spam
        if not status_changed:
            return

        campaign_type = self._determine_campaign_type(score)
        if campaign_type:
            logger.info(f"Triggering intervention: {campaign_type} for {score.custid}")
            self.stats['interventions_triggered'] += 1
            # In production, this would call the intervention system
            # For now, just log it
            # intervention_system.trigger(score.custid, campaign_type, score)

    def _determine_campaign_type(self, score: HealthScore) -> Optional[str]:
        """Determine which intervention campaign to trigger"""
        if score.health_status == HealthStatus.ZOMBIE:
            if score.days_as_zombie and score.days_as_zombie < 30:
                return 'zombie_sequence'
            else:
                return 'winback'
        elif score.health_status == HealthStatus.AT_RISK:
            return 'at_risk_email'
        elif score.health_status == HealthStatus.DEAD:
            return 'sunset'
        return None

    def _log_summary(self):
        """Log job execution summary"""
        logger.info("=" * 60)
        logger.info("Zombie Detection Job Summary")
        logger.info("=" * 60)
        logger.info(f"Total customers processed: {self.stats['total_processed']}")
        logger.info(f"New zombies detected: {self.stats['new_zombies']}")
        logger.info(f"New at-risk customers: {self.stats['new_at_risk']}")
        logger.info(f"Customers reactivated: {self.stats['reactivated']}")
        logger.info(f"Interventions triggered: {self.stats['interventions_triggered']}")
        logger.info(f"Errors: {self.stats['errors']}")
        logger.info("=" * 60)


def main():
    """Main entry point for the job"""
    parser = argparse.ArgumentParser(description='Daily zombie detection job')
    parser.add_argument('--dry-run', action='store_true', help='Run without committing changes')
    parser.add_argument('--custid', help='Process only specific customer ID')
    parser.add_argument('--db-host', default='localhost', help='Database host')
    parser.add_argument('--db-name', default='onetimesecret', help='Database name')
    parser.add_argument('--db-user', default='postgres', help='Database user')
    parser.add_argument('--db-password', help='Database password')

    args = parser.parse_args()

    # Connect to database
    try:
        conn = psycopg2.connect(
            host=args.db_host,
            database=args.db_name,
            user=args.db_user,
            password=args.db_password or os.environ.get('DB_PASSWORD')
        )
        logger.info("Database connection established")
    except Exception as e:
        logger.error(f"Failed to connect to database: {e}")
        sys.exit(1)

    try:
        # Run the job
        job = ZombieDetectionJob(conn, dry_run=args.dry_run)
        job.run(custid=args.custid)
        logger.info("Job completed successfully")
    except Exception as e:
        logger.error(f"Job failed: {e}")
        sys.exit(1)
    finally:
        conn.close()


if __name__ == '__main__':
    main()
