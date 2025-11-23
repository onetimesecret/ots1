# PHASE 2: Technical Implementation Matrix - European Union

## Overview
This document maps each EU legal requirement to specific technical controls and platform configurations for OneTimeSecret deployment.

## Technical Implementation Matrix

| Requirement ID | Technical Control Required | Fly.io Implementation | Northflank Implementation | SQLite Implication | Redis Implication | Logging Restriction | Backup Restriction |
|----------------|---------------------------|----------------------|--------------------------|-------------------|------------------|--------------------|--------------------|
| GDPR-44 | Data must remain in EU or use SCCs for third-country transfers | `primary_region = "ams"` or `"fra"` or `"cdg"` in fly.toml; Ensure volumes and machines in EU regions only | Deploy to `europe-west-netherlands` (Northflank managed) or BYOC to AWS eu-west-1, eu-central-1 | yes - local storage on EU volume | yes - must create in EU region (ams/fra/cdg) | Access logs must not transfer IP to non-EU analytics | Backups must remain in same region or EU-only regions |
| GDPR-45 | Use adequacy decision countries or implement SCCs | For non-EU replicas: use only adequate countries (UK, Switzerland, Japan, NZ) with explicit SCCs | Same - restrict BYOC to adequate jurisdictions | yes - no replication outside EU | conditional - read replicas only in adequate countries | Cannot log to US-based services (e.g., Datadog US region) | Backup replication only to adequate countries |
| GDPR-46 | Implement appropriate safeguards (SCCs, BCRs) when transferring to third countries | Add `FLY_REGION` check in app; Block creation if region not in allowlist | Environment variable `ALLOWED_REGIONS=ams,fra,cdg,lhr` | yes - app-level region check before DB write | yes - app-level region check before cache write | Log region of processing; alert on non-EU regions | Automated backup region validation |
| GDPR-5(1)(e) | Storage limitation - data must not be kept longer than necessary | Use Redis TTL for secrets; SQLite triggers for expiry; `EXPIRE` command | Same - application-level TTL enforcement | conditional - requires application-level deletion triggers | yes - native TTL support (`SETEX`, `EXPIRE`) | Log retention policy: 90 days maximum | Backups auto-delete after 5 days (configurable 1-60) |
| GDPR-5(1)(c) | Data minimization - collect only necessary data | Remove unnecessary metadata collection (user-agent, referer headers) | Same - application code change | yes - schema must minimize columns | yes - minimize cached metadata | Do NOT log: full URLs (may contain secrets), cookie values, authorization headers | Do NOT backup: temporary session data |
| GDPR-17 | Right to erasure - delete within 30 days of request | Immediate deletion API endpoint; Redis `DEL` command; SQLite `DELETE` with secure overwrite | Same - application-level deletion | conditional - requires secure deletion (VACUUM after DELETE) | yes - immediate deletion with DEL | Log deletion requests and completion | Ensure backups can exclude deleted records |
| GDPR-32(1)(a) | Encryption of personal data (state of the art) | Volume encryption (default): `fly volumes create --encrypted` (AES-256); TLS 1.3 for transit | BYOC with encrypted EBS/persistent disks; TLS 1.3 | yes - use SQLCipher with AES-256; `PRAGMA key='...'` | yes - Upstash Redis TLS mandatory in prod | Do NOT log: encryption keys, secret content, plaintext passwords | Backups inherit volume encryption |
| GDPR-32(1)(b) | Ensure confidentiality, integrity, availability, resilience | Multi-region deployment: `fly scale count 3 --region ams,fra,cdg` | Multi-region BYOC across eu-west-1, eu-central-1 | conditional - SQLite write-ahead log (WAL) for resilience | yes - Upstash automatic replication within region | Log availability metrics; alert on <99.9% uptime | Cross-region backup replication (EU only) |
| GDPR-33 | Breach notification within 72 hours | Monitoring: detect unauthorized access via audit logs; Alert to PagerDuty/email | Same - application-level monitoring | yes - log all DB access with timestamps | yes - log all cache access | Log ALL access attempts (success and failure) | Backup access logs for 2 years |
| GDPR-30 | Records of processing activities | Document all processing in ROPA; Export to JSON/CSV | Same - automated ROPA generation from logs | yes - log all queries (sanitized) | yes - log all commands (sanitized) | Log processing activities but sanitize secret content | Backup ROPA separately (long-term retention) |
| ePrivacy-5(1) | Confidentiality of communications | End-to-end encryption option; No logging of secret content | Same - application-level encryption | yes - secrets encrypted at rest | yes - secrets encrypted in cache | NEVER log secret content (even encrypted) | NEVER backup unencrypted secrets |
| ePrivacy-5(3) | User consent for storing info in terminal | Cookie consent banner; localStorage only with consent | Same - frontend implementation | n/a | n/a | Log consent decisions | Backup consent records (legal requirement) |
| ePrivacy-4 | Security of processing for electronic communications | TLS 1.3 mandatory; HSTS enabled; Certificate pinning option | Same - TLS configuration in load balancer | n/a | yes - TLS for Redis connections | Log TLS version used; alert on TLS 1.2 or lower | n/a |
| GDPR-6 | Lawful basis for processing | Legitimate interest assessment; Document legal basis in ROPA | Same - documentation requirement | yes - store legal basis per record if needed | n/a | Log consent/legal basis for processing | Backup legal basis documentation |
| GDPR-25 | Data protection by design and default | Privacy by default settings; Encryption enabled by default | Same - secure defaults in code | yes - default encryption with SQLCipher | yes - default TLS, default short TTL | Log privacy settings; alert on insecure defaults | n/a |

## Detailed Configuration Examples

### Fly.io Configuration (fly.toml)

```toml
app = "onetimesecret-eu"
primary_region = "ams"  # Amsterdam - EU data residency

[build]
  dockerfile = "Dockerfile"

[env]
  ALLOWED_REGIONS = "ams,fra,cdg,lhr,arn"  # EU + adequate countries
  DATA_RESIDENCY_MODE = "EU_STRICT"
  ENCRYPTION_REQUIRED = "true"
  LOG_RETENTION_DAYS = "90"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = false
  auto_start_machines = true
  min_machines_running = 2

  [http_service.concurrency]
    type = "requests"
    hard_limit = 250
    soft_limit = 200

[[http_service.checks]]
  interval = "10s"
  timeout = "2s"
  grace_period = "5s"
  method = "GET"
  path = "/health"

# Volume for SQLite database - encrypted by default
[mounts]
  source = "onetimesecret_data"
  destination = "/data"
  initial_size = "10gb"

# Deploy to multiple EU regions for resilience
[deploy]
  strategy = "rolling"

# Health checks
[[services.http_checks]]
  interval = 10000
  timeout = 2000
  grace_period = 5000
  method = "GET"
  path = "/health"
  protocol = "http"
  tls_skip_verify = false

# Enforce TLS 1.3
[[services.ports]]
  handlers = ["tls", "http"]
  port = 443
  force_https = true

  [services.ports.tls_options]
    alpn = ["h2", "http/1.1"]
    versions = ["TLSv1.3"]  # Only TLS 1.3
```

### Create Encrypted Volume (Fly.io)

```bash
# Create encrypted volume in Amsterdam
fly volumes create onetimesecret_data \
  --region ams \
  --size 10 \
  --encrypted \
  --snapshot-retention 5

# Verify encryption
fly volumes list

# Create Redis in EU region (primary: Amsterdam)
fly redis create \
  --name onetimesecret-redis-eu \
  --region ams \
  --enable-eviction \
  --no-replicas  # Or add replicas in other EU regions only

# To add EU replicas later:
fly redis update onetimesecret-redis-eu \
  --add-replica-region fra \
  --add-replica-region cdg
```

### SQLite Configuration (SQLCipher)

```ruby
# Ruby example using SQLCipher
require 'sqlite3'

# Initialize encrypted database
db = SQLite3::Database.new('/data/secrets.db')

# Set encryption key (load from secure environment variable)
encryption_key = ENV['SQLITE_ENCRYPTION_KEY']
db.execute("PRAGMA key = '#{encryption_key}'")

# Verify encryption is active
cipher_version = db.execute("PRAGMA cipher_version").first
puts "SQLCipher version: #{cipher_version}"

# Enable secure deletion (overwrite deleted data)
db.execute("PRAGMA secure_delete = ON")

# Enable write-ahead logging for resilience
db.execute("PRAGMA journal_mode = WAL")

# Set page size for performance
db.execute("PRAGMA page_size = 4096")

# Set cache size
db.execute("PRAGMA cache_size = -2000")  # 2MB cache
```

### Redis Configuration (Upstash via Fly.io)

```bash
# Redis connection with TLS (required for EU compliance)
redis-cli -u rediss://default:PASSWORD@fly-onetimesecret-redis-eu.upstash.io:6379

# Set secret with TTL (storage limitation)
SET secret:abc123 "encrypted_secret_data" EX 3600  # 1 hour TTL

# Delete secret immediately (right to erasure)
DEL secret:abc123

# Verify deletion
EXISTS secret:abc123  # Should return 0
```

### Application-Level Region Enforcement

```ruby
# Check if current region is allowed (data residency control)
class RegionValidator
  ALLOWED_EU_REGIONS = %w[ams fra cdg lhr arn].freeze

  def self.validate!
    current_region = ENV['FLY_REGION']

    unless ALLOWED_EU_REGIONS.include?(current_region)
      raise "Data residency violation: Cannot process EU data in region #{current_region}"
    end

    # Log the validation (compliance audit trail)
    logger.info("Region validation passed: #{current_region}")
  end
end

# Use in controllers
class SecretsController < ApplicationController
  before_action :validate_data_residency

  private

  def validate_data_residency
    RegionValidator.validate! if user_from_eu?
  end

  def user_from_eu?
    # Implement EU user detection (e.g., via IP geolocation)
    # For strict compliance: assume EU unless proven otherwise
    true
  end
end
```

### Logging Configuration (GDPR-compliant)

```ruby
# Custom logger that sanitizes sensitive data
class GdprCompliantLogger < Logger
  SENSITIVE_PATTERNS = [
    /secret=[^&\s]+/,           # Secret parameters
    /password=[^&\s]+/,         # Passwords
    /Authorization: [^\r\n]+/,  # Auth headers
    /Cookie: [^\r\n]+/,         # Cookies
    /\b[A-Za-z0-9]{20,}\b/,     # Potential secrets (20+ alphanumeric)
  ].freeze

  def add(severity, message = nil, progname = nil)
    sanitized_message = sanitize(message || progname)
    super(severity, sanitized_message, progname)
  end

  private

  def sanitize(message)
    return message unless message.is_a?(String)

    sanitized = message.dup
    SENSITIVE_PATTERNS.each do |pattern|
      sanitized.gsub!(pattern, '[REDACTED]')
    end
    sanitized
  end
end

# Configure in application
Rails.application.configure do
  config.logger = GdprCompliantLogger.new(STDOUT)

  # Log retention (GDPR storage limitation)
  config.log_retention_days = 90

  # Disable logging of secret content
  config.filter_parameters += [
    :secret,
    :password,
    :passphrase,
    :metadata,
    :content,
    :secret_key,
    :encryption_key,
  ]
end
```

### Backup Configuration (Data Residency)

```bash
# Fly.io volume snapshots (stay in same region by default)
fly volumes snapshots create onetimesecret_data

# Configure snapshot retention (GDPR storage limitation)
fly volumes update onetimesecret_data --snapshot-retention 5

# List snapshots to verify region
fly volumes snapshots list onetimesecret_data

# Restore from snapshot (must be in same or EU region)
fly volumes create onetimesecret_data_restore \
  --region ams \
  --snapshot-id vs_abc123 \
  --encrypted

# IMPORTANT: Backups must NOT cross into non-adequate countries
# Verify snapshot locations regularly
```

### Northflank Configuration (BYOC Example)

```yaml
# Northflank deployment manifest (BYOC to AWS EU regions)
apiVersion: v1
kind: Deployment
metadata:
  name: onetimesecret-eu
spec:
  region: eu-west-1  # Ireland (EU)
  cloudProvider: aws

  deployment:
    instances: 3
    resources:
      cpu: 0.5
      memory: 1Gi

    volumes:
      - name: secrets-db
        size: 10Gi
        encrypted: true
        snapshotPolicy:
          retention: 5d
          region: eu-west-1  # Keep snapshots in EU

  environment:
    - name: ALLOWED_REGIONS
      value: "eu-west-1,eu-central-1"
    - name: DATA_RESIDENCY_MODE
      value: "EU_STRICT"
    - name: SQLITE_ENCRYPTION_KEY
      valueFrom:
        secretKeyRef:
          name: db-encryption-key
          key: key

  networking:
    tls:
      enabled: true
      minVersion: "1.3"

  backup:
    enabled: true
    schedule: "0 2 * * *"  # Daily at 2 AM
    retention: 5
    regions:
      - eu-west-1  # Backups stay in EU
```

## Compliance Validation Checklist

### Pre-Deployment Validation

- [ ] **Region Configuration**
  - [ ] `primary_region` set to EU region (ams/fra/cdg)
  - [ ] No machines deployed outside allowed regions
  - [ ] `FLY_REGION` environment variable checked in application
  - [ ] Geo-IP blocking configured for non-EU admin access (optional)

- [ ] **Encryption**
  - [ ] Volumes created with `--encrypted` flag
  - [ ] SQLCipher enabled with strong key (256-bit minimum)
  - [ ] Redis TLS enabled (rediss:// protocol)
  - [ ] TLS 1.3 enforced for HTTPS
  - [ ] HSTS headers configured

- [ ] **Data Minimization**
  - [ ] Removed unnecessary metadata collection
  - [ ] Logging sanitized (no secret content, passwords, tokens)
  - [ ] Cookie consent implemented
  - [ ] Analytics configured for privacy (no cross-border transfers)

- [ ] **Storage Limitation**
  - [ ] Redis TTL configured for all secrets
  - [ ] SQLite triggers for expiry enforcement
  - [ ] Backup retention set to 5 days (or business requirement)
  - [ ] Log retention set to 90 days

- [ ] **Access Controls**
  - [ ] Audit logging enabled for all data access
  - [ ] Access logs retained for 2 years (breach notification requirement)
  - [ ] Monitoring configured for unauthorized access attempts
  - [ ] Breach notification procedures documented and tested

### Post-Deployment Validation

```bash
# Verify region deployment
fly status | grep -E "ams|fra|cdg|lhr|arn"

# Verify volume encryption
fly volumes list | grep -E "encrypted.*true"

# Verify Redis region
fly redis status onetimesecret-redis-eu | grep region

# Test TLS version
curl -I --tlsv1.3 --tls-max 1.3 https://onetimesecret.fly.dev

# Test region enforcement
curl -X POST https://onetimesecret.fly.dev/api/secrets \
  -H "Content-Type: application/json" \
  -d '{"secret": "test", "region_check": true}'

# Verify logging sanitization
fly logs | grep -i "secret=" | wc -l  # Should be 0

# Verify backup region
fly volumes snapshots list onetimesecret_data | grep region
```

## Risk Mitigation Matrix

| Risk | Mitigation | Validation Method | Residual Risk |
|------|-----------|-------------------|--------------|
| Data transfer to non-EU | Region enforcement in code + infrastructure | Automated region checks in CI/CD | LOW - requires misconfiguration |
| Encryption key compromise | Key stored in Fly secrets (encrypted at rest); Rotate quarterly | Key rotation audit logs | MEDIUM - catastrophic if compromised |
| Backup data residency violation | Snapshots in same region; Automated validation | Daily backup region verification script | LOW - Fly.io default behavior |
| Logging sensitive data | Sanitization in logger; Filter parameters | Automated log scanning (regex) | LOW - requires code change to bypass |
| Prolonged data retention | Automated TTL enforcement; Cron job cleanup | Daily retention audit query | LOW - technical enforcement |
| Breach notification delay | Monitoring + alerting; Documented procedure | Quarterly breach notification drill | MEDIUM - depends on detection speed |
| Inadequate encryption | TLS 1.3 + SQLCipher AES-256; Annual review | Quarterly security audit | LOW - current state of the art |

## Next Steps
- Proceed to Phase 3: Conflict Detection (multi-jurisdiction analysis)
- Create ADRs for architecture decisions (Phase 4)
- Generate compliance monitoring queries (Phase 5)
