# PHASE 5: Monitoring & Compliance Queries

## Overview
This document provides PostgreSQL queries to detect compliance violations in real-time and generate audit reports.

## Database Schema Assumptions

```sql
-- Secrets table (assumed structure)
CREATE TABLE secrets (
  id BIGSERIAL PRIMARY KEY,
  secret_key VARCHAR(255) UNIQUE NOT NULL,
  encrypted_content TEXT NOT NULL,
  passphrase_required BOOLEAN DEFAULT FALSE,
  ttl INTEGER NOT NULL,  -- Time to live in seconds
  max_views INTEGER DEFAULT 1,
  current_views INTEGER DEFAULT 0,
  metadata_json JSONB,  -- Additional metadata
  user_ip INET,
  user_country VARCHAR(2),  -- ISO country code
  user_agent TEXT,
  processing_region VARCHAR(10),  -- Fly.io region code
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  accessed_at TIMESTAMP WITH TIME ZONE,
  deleted_at TIMESTAMP WITH TIME ZONE,
  deletion_reason VARCHAR(50),  -- 'expired', 'max_views', 'user_request', 'admin'
  legal_basis VARCHAR(50),  -- GDPR Article 6 basis
  has_eu_scc BOOLEAN DEFAULT FALSE,
  has_uk_scc BOOLEAN DEFAULT FALSE,
  has_anpd_scc BOOLEAN DEFAULT FALSE,  -- Brazil
  has_japan_consent BOOLEAN DEFAULT FALSE
);

-- Audit log table
CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  secret_id BIGINT REFERENCES secrets(id),
  event_type VARCHAR(50) NOT NULL,  -- 'created', 'viewed', 'deleted', 'breach_attempt'
  user_ip INET,
  user_country VARCHAR(2),
  processing_region VARCHAR(10),
  event_metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Compliance violations table
CREATE TABLE compliance_violations (
  id BIGSERIAL PRIMARY KEY,
  violation_type VARCHAR(100) NOT NULL,
  severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  jurisdiction VARCHAR(50),
  regulation VARCHAR(100),
  article VARCHAR(50),
  secret_id BIGINT REFERENCES secrets(id),
  description TEXT,
  detected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolution TEXT
);

-- Data subject requests table (GDPR Article 15-22)
CREATE TABLE data_subject_requests (
  id BIGSERIAL PRIMARY KEY,
  request_type VARCHAR(50) NOT NULL,  -- 'access', 'erasure', 'portability', 'rectification'
  requester_email VARCHAR(255),
  requester_ip INET,
  status VARCHAR(50) DEFAULT 'pending',  -- 'pending', 'processing', 'completed', 'denied'
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  response_sent_at TIMESTAMP WITH TIME ZONE
);

-- Indexes for compliance queries
CREATE INDEX idx_secrets_user_country ON secrets(user_country);
CREATE INDEX idx_secrets_processing_region ON secrets(processing_region);
CREATE INDEX idx_secrets_created_at ON secrets(created_at);
CREATE INDEX idx_secrets_expires_at ON secrets(expires_at);
CREATE INDEX idx_secrets_deleted_at ON secrets(deleted_at);
CREATE INDEX idx_audit_logs_event_type ON audit_logs(event_type);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_compliance_violations_severity ON compliance_violations(severity);
CREATE INDEX idx_compliance_violations_detected_at ON compliance_violations(detected_at);
```

---

## 1. GDPR Violation Detection Queries

### 1.1 EU Data Processed Outside Adequate Regions (GDPR Article 44)

```sql
-- Detects EU user data processed in non-adequate regions
-- CRITICAL: This is the primary Schrems II compliance check
-- Run: Every hour

WITH eu_countries AS (
  SELECT unnest(ARRAY[
    'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR',
    'DE', 'GR', 'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL',
    'PL', 'PT', 'RO', 'SK', 'SI', 'ES', 'SE', 'NO', 'IS', 'LI'
  ]) AS country_code
),
adequate_regions AS (
  SELECT unnest(ARRAY[
    'ams',  -- Amsterdam
    'fra',  -- Frankfurt
    'cdg',  -- Paris
    'lhr',  -- London (if UK adequacy valid)
    'arn'   -- Stockholm
  ]) AS region_code
)
SELECT
  s.id AS secret_id,
  s.secret_key,
  s.user_country,
  s.processing_region,
  s.created_at,
  s.has_eu_scc,
  'GDPR_ARTICLE_44_VIOLATION' AS violation_type,
  'EU data processed in non-adequate region without SCCs' AS description,
  'CRITICAL' AS severity
FROM
  secrets s
  JOIN eu_countries eu ON s.user_country = eu.country_code
WHERE
  s.processing_region NOT IN (SELECT region_code FROM adequate_regions)
  AND (s.has_eu_scc = FALSE OR s.has_eu_scc IS NULL)
  AND s.deleted_at IS NULL
  AND s.created_at > NOW() - INTERVAL '1 hour'
ORDER BY
  s.created_at DESC;

-- Auto-insert into violations table
INSERT INTO compliance_violations (
  violation_type,
  severity,
  jurisdiction,
  regulation,
  article,
  secret_id,
  description
)
SELECT
  'GDPR_ARTICLE_44_VIOLATION',
  'critical',
  'European Union',
  'GDPR (Regulation 2016/679)',
  'Article 44',
  secret_id,
  description
FROM (
  -- Previous query here
) violations
ON CONFLICT DO NOTHING;
```

### 1.2 Storage Limitation Violation (GDPR Article 5(1)(e))

```sql
-- Detects secrets retained beyond expiry (should be auto-deleted)
-- CRITICAL: Secrets MUST be deleted upon expiry per GDPR
-- Run: Every 15 minutes

SELECT
  s.id AS secret_id,
  s.secret_key,
  s.user_country,
  s.expires_at,
  NOW() - s.expires_at AS overdue_duration,
  s.deleted_at,
  'GDPR_ARTICLE_5_1_E_VIOLATION' AS violation_type,
  'Secret not deleted after expiry (storage limitation)' AS description,
  CASE
    WHEN NOW() - s.expires_at > INTERVAL '1 day' THEN 'CRITICAL'
    WHEN NOW() - s.expires_at > INTERVAL '1 hour' THEN 'HIGH'
    ELSE 'MEDIUM'
  END AS severity
FROM
  secrets s
WHERE
  s.expires_at < NOW()
  AND s.deleted_at IS NULL
ORDER BY
  s.expires_at ASC
LIMIT 100;

-- Remediation: Auto-delete expired secrets
DELETE FROM secrets
WHERE expires_at < NOW()
  AND deleted_at IS NULL
RETURNING id, secret_key, expires_at;
```

### 1.3 Right to Erasure Compliance (GDPR Article 17)

```sql
-- Monitors data subject deletion requests for 30-day compliance
-- GDPR Article 17: Must respond within 30 days
-- Run: Daily

SELECT
  dsr.id AS request_id,
  dsr.requester_email,
  dsr.submitted_at,
  NOW() - dsr.submitted_at AS time_elapsed,
  dsr.status,
  dsr.completed_at,
  CASE
    WHEN dsr.status = 'completed' THEN 'COMPLIANT'
    WHEN NOW() - dsr.submitted_at > INTERVAL '30 days' THEN 'VIOLATION'
    WHEN NOW() - dsr.submitted_at > INTERVAL '25 days' THEN 'WARNING'
    ELSE 'ON_TRACK'
  END AS compliance_status,
  CASE
    WHEN NOW() - dsr.submitted_at > INTERVAL '30 days' THEN 'CRITICAL'
    WHEN NOW() - dsr.submitted_at > INTERVAL '25 days' THEN 'HIGH'
    ELSE 'MEDIUM'
  END AS severity
FROM
  data_subject_requests dsr
WHERE
  dsr.request_type = 'erasure'
  AND dsr.status != 'completed'
ORDER BY
  dsr.submitted_at ASC;

-- Alert on violations
SELECT
  'GDPR_ARTICLE_17_VIOLATION' AS violation_type,
  COUNT(*) AS overdue_requests,
  STRING_AGG(requester_email, ', ') AS affected_users
FROM
  data_subject_requests
WHERE
  request_type = 'erasure'
  AND status != 'completed'
  AND NOW() - submitted_at > INTERVAL '30 days';
```

### 1.4 Breach Notification Compliance (GDPR Article 33)

```sql
-- Monitors for data breaches and 72-hour notification requirement
-- GDPR Article 33: Must notify supervisory authority within 72 hours
-- Run: Continuously (every 5 minutes)

WITH potential_breaches AS (
  SELECT
    event_type,
    COUNT(*) AS event_count,
    MIN(created_at) AS first_occurrence,
    MAX(created_at) AS last_occurrence,
    STRING_AGG(DISTINCT user_ip::TEXT, ', ') AS source_ips
  FROM
    audit_logs
  WHERE
    event_type IN ('breach_attempt', 'unauthorized_access', 'encryption_failure')
    AND created_at > NOW() - INTERVAL '1 hour'
  GROUP BY
    event_type
  HAVING
    COUNT(*) > 10  -- Threshold for potential breach
)
SELECT
  pb.event_type AS breach_type,
  pb.event_count AS incident_count,
  pb.first_occurrence AS breach_detected_at,
  NOW() - pb.first_occurrence AS time_since_detection,
  pb.source_ips,
  CASE
    WHEN NOW() - pb.first_occurrence > INTERVAL '72 hours' THEN 'VIOLATION_CRITICAL'
    WHEN NOW() - pb.first_occurrence > INTERVAL '48 hours' THEN 'VIOLATION_HIGH'
    WHEN NOW() - pb.first_occurrence > INTERVAL '24 hours' THEN 'WARNING'
    ELSE 'MONITORING'
  END AS notification_status,
  CASE
    WHEN NOW() - pb.first_occurrence <= INTERVAL '72 hours' THEN
      72 - EXTRACT(HOUR FROM NOW() - pb.first_occurrence)
    ELSE
      0
  END AS hours_remaining_for_notification
FROM
  potential_breaches pb
ORDER BY
  pb.first_occurrence DESC;
```

### 1.5 Records of Processing Activities (GDPR Article 30)

```sql
-- Generates Records of Processing Activities (ROPA) for GDPR compliance
-- GDPR Article 30: Controllers must maintain records of processing
-- Run: On-demand or weekly for audit

SELECT
  'OneTimeSecret Secret Sharing' AS processing_activity,
  'Temporary storage and sharing of encrypted secrets' AS purpose,
  'Consent (Article 6(1)(a)) or Legitimate Interest (Article 6(1)(f))' AS legal_basis,
  ARRAY[
    'Secret content (encrypted)',
    'IP address',
    'Timestamp',
    'Expiry time',
    'View count'
  ] AS data_categories,
  ARRAY[
    'Users sharing secrets',
    'Recipients of secrets'
  ] AS data_subject_categories,
  ARRAY[
    'Fly.io (Infrastructure)',
    'Upstash (Redis caching)'
  ] AS recipients_processors,
  'EU (Amsterdam, Frankfurt, Paris), UK (London)' AS transfer_destinations,
  ARRAY[
    'Encryption at rest (AES-256)',
    'Encryption in transit (TLS 1.3)',
    'Access logging',
    'Automated deletion',
    'Regular security audits'
  ] AS security_measures,
  'Auto-delete upon expiry or max views; Maximum 30 days' AS retention_period,
  NOW() AS generated_at;

-- Detailed processing statistics
SELECT
  DATE_TRUNC('day', created_at) AS processing_date,
  user_country AS data_subject_country,
  processing_region,
  COUNT(*) AS secrets_processed,
  COUNT(DISTINCT user_ip) AS unique_users,
  legal_basis,
  SUM(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END) AS deleted_secrets,
  AVG(EXTRACT(EPOCH FROM (deleted_at - created_at))) / 3600 AS avg_retention_hours
FROM
  secrets
WHERE
  created_at > NOW() - INTERVAL '30 days'
GROUP BY
  DATE_TRUNC('day', created_at),
  user_country,
  processing_region,
  legal_basis
ORDER BY
  processing_date DESC,
  secrets_processed DESC;
```

---

## 2. Brazil LGPD Violation Detection

### 2.1 ANPD SCC Requirement (Post-Grace Period)

```sql
-- Detects Brazilian data processed without ANPD SCCs after grace period
-- Brazil LGPD + ANPD Resolution 19/2024: SCCs required as of August 23, 2025
-- Run: Hourly

SELECT
  s.id AS secret_id,
  s.secret_key,
  s.user_country,
  s.processing_region,
  s.created_at,
  s.has_anpd_scc,
  'BRAZIL_LGPD_ANPD_SCC_VIOLATION' AS violation_type,
  'Brazilian data processed without ANPD-approved SCCs after grace period' AS description,
  'CRITICAL' AS severity,
  'Fines up to BRL 50 million (2% of revenue)' AS potential_penalty
FROM
  secrets s
WHERE
  s.user_country = 'BR'
  AND s.processing_region NOT IN ('gru', 'sao')  -- São Paulo regions
  AND (s.has_anpd_scc = FALSE OR s.has_anpd_scc IS NULL)
  AND s.created_at > '2025-08-23'::DATE  -- After grace period end
  AND s.deleted_at IS NULL
ORDER BY
  s.created_at DESC;
```

---

## 3. Australia Privacy Act Violation Detection

### 3.1 Healthcare Data Outside Australia

```sql
-- Detects potential Australian healthcare data processed outside Australia
-- Australia My Health Records Act: ABSOLUTE PROHIBITION
-- Run: Every 15 minutes

-- Note: This requires content classification (healthcare detection)
-- Simplified version checks for Australian users + non-AU processing

SELECT
  s.id AS secret_id,
  s.secret_key,
  s.user_country,
  s.processing_region,
  s.metadata_json->>'content_type' AS content_type,
  s.created_at,
  'AUSTRALIA_HEALTHCARE_VIOLATION' AS violation_type,
  'Australian user data processed outside Australia (potential healthcare)' AS description,
  'CRITICAL' AS severity,
  'My Health Records Act Section 75 - Criminal offense' AS potential_penalty
FROM
  secrets s
WHERE
  s.user_country = 'AU'
  AND s.processing_region != 'syd'
  AND s.deleted_at IS NULL
  AND (
    -- Heuristic: Flag if metadata suggests healthcare
    s.metadata_json->>'content_type' = 'healthcare'
    OR s.metadata_json->>'is_healthcare' = 'true'
  )
ORDER BY
  s.created_at DESC;
```

### 3.2 APP 8 Accountability (Cross-Border Disclosure)

```sql
-- Monitors cross-border disclosures for Australian users
-- Australia Privacy Act APP 8: Entity remains accountable for overseas recipients
-- Run: Daily

SELECT
  s.user_country,
  s.processing_region,
  COUNT(*) AS cross_border_disclosures,
  COUNT(DISTINCT s.user_ip) AS unique_users,
  MIN(s.created_at) AS first_disclosure,
  MAX(s.created_at) AS last_disclosure,
  'AUSTRALIA_APP8_CROSS_BORDER' AS monitoring_type,
  CASE
    WHEN COUNT(*) > 1000 THEN 'HIGH_VOLUME_REQUIRES_AUDIT'
    WHEN COUNT(*) > 100 THEN 'MEDIUM_VOLUME_MONITOR'
    ELSE 'LOW_VOLUME_OK'
  END AS risk_level
FROM
  secrets s
WHERE
  s.user_country = 'AU'
  AND s.processing_region NOT IN ('syd', 'mel')  -- Sydney, Melbourne
  AND s.created_at > NOW() - INTERVAL '7 days'
GROUP BY
  s.user_country,
  s.processing_region
ORDER BY
  cross_border_disclosures DESC;
```

---

## 4. Japan APPI Violation Detection

### 4.1 Cross-Border Transfer Without Consent

```sql
-- Detects Japanese user data transferred without required consent or APEC CBPR
-- Japan APPI Article 28: Consent OR adequate country OR APEC CBPR required
-- Run: Hourly

WITH adequate_countries AS (
  -- Japan recognizes these as adequate
  SELECT unnest(ARRAY['EU', 'UK', 'NZ']) AS country_group,
         unnest(ARRAY[
           ARRAY['ams', 'fra', 'cdg', 'arn'],  -- EU regions
           ARRAY['lhr'],  -- UK
           ARRAY['syd', 'akl']  -- NZ (using Sydney, Auckland)
         ]) AS region_code
)
SELECT
  s.id AS secret_id,
  s.secret_key,
  s.user_country,
  s.processing_region,
  s.has_japan_consent,
  s.created_at,
  'JAPAN_APPI_ARTICLE_28_VIOLATION' AS violation_type,
  'Japanese data transferred without consent or to non-adequate country' AS description,
  'HIGH' AS severity
FROM
  secrets s
WHERE
  s.user_country = 'JP'
  AND s.processing_region NOT IN ('nrt', 'kix')  -- Tokyo Narita, Osaka Kansai
  AND s.processing_region NOT IN (SELECT region_code FROM adequate_countries)
  AND (s.has_japan_consent = FALSE OR s.has_japan_consent IS NULL)
  AND s.deleted_at IS NULL
  AND s.created_at > NOW() - INTERVAL '1 hour'
ORDER BY
  s.created_at DESC;
```

---

## 5. Multi-Jurisdiction Compliance Dashboard

### 5.1 Real-Time Compliance Scorecard

```sql
-- Generates a real-time compliance scorecard across all jurisdictions
-- Run: Every 5 minutes for monitoring dashboard

WITH compliance_metrics AS (
  -- EU GDPR Compliance
  SELECT
    'EU_GDPR' AS jurisdiction,
    'Data Residency' AS requirement,
    COUNT(*) FILTER (
      WHERE user_country IN ('AT','BE','BG','HR','CY','CZ','DK','EE','FI','FR','DE','GR','HU','IE','IT','LV','LT','LU','MT','NL','PL','PT','RO','SK','SI','ES','SE','NO','IS','LI')
      AND processing_region NOT IN ('ams','fra','cdg','lhr','arn')
      AND (has_eu_scc = FALSE OR has_eu_scc IS NULL)
    ) AS violations,
    COUNT(*) FILTER (
      WHERE user_country IN ('AT','BE','BG','HR','CY','CZ','DK','EE','FI','FR','DE','GR','HU','IE','IT','LV','LT','LU','MT','NL','PL','PT','RO','SK','SI','ES','SE','NO','IS','LI')
    ) AS total_records
  FROM secrets
  WHERE deleted_at IS NULL
    AND created_at > NOW() - INTERVAL '24 hours'

  UNION ALL

  -- Brazil LGPD Compliance
  SELECT
    'BR_LGPD',
    'ANPD SCCs',
    COUNT(*) FILTER (
      WHERE user_country = 'BR'
      AND processing_region NOT IN ('gru', 'sao')
      AND (has_anpd_scc = FALSE OR has_anpd_scc IS NULL)
      AND created_at > '2025-08-23'::DATE
    ),
    COUNT(*) FILTER (WHERE user_country = 'BR')
  FROM secrets
  WHERE deleted_at IS NULL
    AND created_at > NOW() - INTERVAL '24 hours'

  UNION ALL

  -- Australia Healthcare
  SELECT
    'AU_HEALTHCARE',
    'Data Localization',
    COUNT(*) FILTER (
      WHERE user_country = 'AU'
      AND processing_region != 'syd'
      AND (metadata_json->>'is_healthcare' = 'true')
    ),
    COUNT(*) FILTER (
      WHERE user_country = 'AU'
      AND (metadata_json->>'is_healthcare' = 'true')
    )
  FROM secrets
  WHERE deleted_at IS NULL
    AND created_at > NOW() - INTERVAL '24 hours'

  UNION ALL

  -- Japan APPI
  SELECT
    'JP_APPI',
    'Cross-Border Consent',
    COUNT(*) FILTER (
      WHERE user_country = 'JP'
      AND processing_region NOT IN ('nrt', 'kix', 'ams', 'fra', 'cdg', 'lhr')
      AND (has_japan_consent = FALSE OR has_japan_consent IS NULL)
    ),
    COUNT(*) FILTER (WHERE user_country = 'JP')
  FROM secrets
  WHERE deleted_at IS NULL
    AND created_at > NOW() - INTERVAL '24 hours'
)
SELECT
  jurisdiction,
  requirement,
  violations,
  total_records,
  CASE
    WHEN total_records = 0 THEN 100.0
    ELSE ROUND(((total_records - violations)::NUMERIC / total_records * 100), 2)
  END AS compliance_percentage,
  CASE
    WHEN violations = 0 THEN '✅ COMPLIANT'
    WHEN violations < 10 THEN '⚠️  WARNING'
    WHEN violations < 50 THEN '🚨 VIOLATION'
    ELSE '❌ CRITICAL'
  END AS status
FROM
  compliance_metrics
ORDER BY
  violations DESC,
  jurisdiction;
```

### 5.2 Retention Audit Report

```sql
-- Audits data retention across all secrets
-- Ensures compliance with GDPR Article 5(1)(e) and similar requirements
-- Run: Weekly

SELECT
  DATE_TRUNC('week', created_at) AS week,
  user_country,
  COUNT(*) AS secrets_created,
  COUNT(*) FILTER (WHERE deleted_at IS NOT NULL) AS secrets_deleted,
  COUNT(*) FILTER (WHERE deleted_at IS NULL AND expires_at < NOW()) AS overdue_deletions,
  ROUND(AVG(EXTRACT(EPOCH FROM (COALESCE(deleted_at, NOW()) - created_at))) / 3600, 2) AS avg_lifetime_hours,
  MAX(EXTRACT(EPOCH FROM (COALESCE(deleted_at, NOW()) - created_at)) / 3600) AS max_lifetime_hours
FROM
  secrets
WHERE
  created_at > NOW() - INTERVAL '90 days'
GROUP BY
  DATE_TRUNC('week', created_at),
  user_country
ORDER BY
  week DESC,
  secrets_created DESC;
```

---

## 6. Automated Compliance Actions

### 6.1 Auto-Delete Expired Secrets (Storage Limitation)

```sql
-- Automated deletion of expired secrets (GDPR Article 5(1)(e) compliance)
-- Schedule: Every 5 minutes via cron

WITH deleted_secrets AS (
  UPDATE secrets
  SET
    deleted_at = NOW(),
    deletion_reason = 'expired'
  WHERE
    expires_at < NOW()
    AND deleted_at IS NULL
  RETURNING id, secret_key, user_country, expires_at
)
INSERT INTO audit_logs (secret_id, event_type, event_metadata)
SELECT
  ds.id,
  'auto_deleted_expired',
  jsonb_build_object(
    'secret_key', ds.secret_key,
    'user_country', ds.user_country,
    'expired_at', ds.expires_at,
    'deleted_at', NOW()
  )
FROM
  deleted_secrets ds;
```

### 6.2 Compliance Violation Auto-Reporting

```sql
-- Automatically logs compliance violations for audit
-- Run: Continuously (triggered after violation detection queries)

CREATE OR REPLACE FUNCTION log_compliance_violation()
RETURNS TRIGGER AS $$
BEGIN
  -- This would be triggered after violation detection
  -- Example: Trigger on secrets table for EU region violations

  IF NEW.user_country IN ('DE','FR','NL','BE','ES','IT','PL','AT','DK','SE')
     AND NEW.processing_region NOT IN ('ams','fra','cdg','lhr','arn')
     AND (NEW.has_eu_scc = FALSE OR NEW.has_eu_scc IS NULL) THEN

    INSERT INTO compliance_violations (
      violation_type,
      severity,
      jurisdiction,
      regulation,
      article,
      secret_id,
      description
    ) VALUES (
      'GDPR_ARTICLE_44_VIOLATION',
      'critical',
      'European Union',
      'GDPR (Regulation 2016/679)',
      'Article 44',
      NEW.id,
      'EU data processed in non-adequate region: ' || NEW.processing_region
    );

    -- Also send alert (would integrate with monitoring system)
    PERFORM pg_notify(
      'compliance_alert',
      json_build_object(
        'violation_type', 'GDPR_ARTICLE_44',
        'secret_id', NEW.id,
        'severity', 'critical'
      )::text
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger
CREATE TRIGGER check_compliance_on_secret_creation
AFTER INSERT ON secrets
FOR EACH ROW
EXECUTE FUNCTION log_compliance_violation();
```

---

## 7. Compliance Reporting for Authorities

### 7.1 GDPR Article 30 Export (ROPA)

```sql
-- Exports Records of Processing Activities for supervisory authority
-- Run: On-demand when requested by DPA

COPY (
  SELECT
    'OneTimeSecret' AS controller_name,
    'Secret Sharing Platform' AS controller_activity,
    'Temporary storage and sharing of encrypted secrets' AS processing_purpose,
    ARRAY_TO_STRING(ARRAY[
      'Secret content (encrypted)',
      'IP address',
      'Access logs (sanitized)',
      'Timestamps'
    ], '; ') AS personal_data_categories,
    'Users sharing secrets; Recipients of shared secrets' AS data_subjects,
    'Fly.io (US/EU) - Infrastructure; Upstash (EU) - Redis' AS recipients,
    'EU (Amsterdam, Frankfurt, Paris); UK (London)' AS third_countries,
    'Encryption (AES-256 at rest, TLS 1.3 in transit); Access control; Audit logging; Automated deletion' AS security_measures,
    'Auto-delete upon expiry (max 30 days) or max views' AS retention,
    NOW() AS report_generated_at
) TO '/tmp/gdpr_article_30_ropa.csv' WITH CSV HEADER;
```

### 7.2 Breach Notification Report (GDPR Article 33)

```sql
-- Generates breach notification report for supervisory authority
-- CRITICAL: Must be submitted within 72 hours of breach detection

SELECT
  'OneTimeSecret Breach Report' AS report_title,
  NOW() AS report_date,
  jsonb_build_object(
    'breach_detected_at', MIN(al.created_at),
    'breach_type', al.event_type,
    'affected_records', COUNT(DISTINCT al.secret_id),
    'affected_users', COUNT(DISTINCT al.user_ip),
    'affected_countries', STRING_AGG(DISTINCT s.user_country, ', '),
    'security_measures_in_place', ARRAY[
      'Encryption at rest (AES-256)',
      'Encryption in transit (TLS 1.3)',
      'Access logging',
      'Intrusion detection'
    ],
    'consequences_assessment', 'Under investigation',
    'measures_taken', 'Immediate lockdown of affected systems; User notification; Investigation ongoing',
    'notification_to_dpa_at', NOW(),
    'hours_since_detection', EXTRACT(HOUR FROM NOW() - MIN(al.created_at))
  ) AS breach_details
FROM
  audit_logs al
  LEFT JOIN secrets s ON al.secret_id = s.id
WHERE
  al.event_type IN ('breach_attempt', 'unauthorized_access', 'encryption_failure')
  AND al.created_at > NOW() - INTERVAL '72 hours'
GROUP BY
  al.event_type;
```

---

## 8. Monitoring Integration (Prometheus Metrics)

```sql
-- Example: Export compliance metrics for Prometheus
-- These would be exposed via a metrics endpoint

-- Metric: gdpr_violations_total
SELECT
  'gdpr_violations_total' AS metric_name,
  jurisdiction,
  violation_type,
  COUNT(*) AS value
FROM
  compliance_violations
WHERE
  detected_at > NOW() - INTERVAL '24 hours'
GROUP BY
  jurisdiction,
  violation_type;

-- Metric: secrets_by_region
SELECT
  'secrets_by_region' AS metric_name,
  processing_region AS label,
  COUNT(*) AS value
FROM
  secrets
WHERE
  deleted_at IS NULL
GROUP BY
  processing_region;

-- Metric: compliance_score
SELECT
  'compliance_score' AS metric_name,
  jurisdiction,
  ROUND(((total_records - violations)::NUMERIC / NULLIF(total_records, 0) * 100), 2) AS value
FROM (
  -- Use compliance_metrics CTE from 5.1
  SELECT * FROM compliance_metrics
) cm;
```

---

## Next Steps
- Proceed to Phase 6: Customer Disclosure Requirements
- Implement monitoring queries in application monitoring system
- Set up alerts for critical violations (PagerDuty, Slack)
- Schedule weekly compliance reports
