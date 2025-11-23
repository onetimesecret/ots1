# PHASE 4: Architecture Decision Records (ADRs)

## Overview
This document contains Architecture Decision Records (ADRs) for resolving jurisdiction conflicts identified in Phase 3.

---

## ADR-001: EU vs US Data Handling (GDPR Schrems II Compliance)

### Status
**ACCEPTED** - Critical for legal compliance

### Context
**Legal Conflict**:
- **EU GDPR Article 44**: Personal data transfer to third countries requires adequacy decision or appropriate safeguards (SCCs + Transfer Impact Assessment)
- **US CLOUD Act + FISA 702**: US government can compel access to data held by US companies, even when stored abroad
- **Schrems II Decision (2020)**: Invalidated EU-US Privacy Shield due to inadequate protection against US surveillance

**Evidence of Enforcement**:
- Meta Platforms Ireland: €1.2 billion fine (May 2023) for unlawful EU-US data transfers
- Uber: €290 million fine (2024) for transferring driver data to US without adequate safeguards
- TikTok: €530 million projected fine for failing to protect user data from China access

**OneTimeSecret Impact**:
- Current deployment uses Fly.io, which is a US-based company
- Data sovereignty is CRITICAL for a secret-sharing service
- EU users expect GDPR-level protection
- Reputational risk if secrets accessible by foreign governments

### Decision
Deploy **EU-only infrastructure** for EU users with strict geographic isolation.

### Implementation

#### Option A (SELECTED): Multi-Region with Geo-Fencing
```toml
# fly-eu.toml - EU deployment
app = "onetimesecret-eu"
primary_region = "ams"

[env]
  DEPLOYMENT_REGION = "EU"
  ALLOWED_DATA_REGIONS = "ams,fra,cdg,lhr,arn"
  STRICT_RESIDENCY = "true"

[mounts]
  source = "secrets_eu"
  destination = "/data"
  # Encrypted by default, never leaves EU

[[services]]
  internal_port = 8080
  protocol = "tcp"

  [[services.ports]]
    handlers = ["tls", "http"]
    port = 443
    force_https = true
    [services.ports.tls_options]
      alpn = ["h2", "http/1.1"]
      versions = ["TLSv1.3"]
```

#### Geo-Routing with Caddy
```caddyfile
# Caddyfile for geo-routing
onetimesecret.com {
  # EU users → EU infrastructure
  @eu_users {
    header_regexp country CF-IPCountry ^(DE|FR|NL|BE|ES|IT|PL|AT|DK|SE|FI|IE|PT|GR|CZ|RO|HU|BG|HR|SI|SK|LT|LV|EE|CY|MT|LU|NO|IS|LI)$
  }

  reverse_proxy @eu_users https://onetimesecret-eu.fly.dev {
    header_up X-Data-Residency-Region EU
    header_up X-Processing-Jurisdiction GDPR
  }

  # Non-EU users → Standard infrastructure (or separate US deployment)
  reverse_proxy https://onetimesecret-global.fly.dev
}
```

#### Application-Level Enforcement
```ruby
# app/middleware/data_residency_middleware.rb
class DataResidencyMiddleware
  EU_COUNTRIES = %w[
    AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU
    MT NL PL PT RO SK SI ES SE NO IS LI
  ].freeze

  def call(env)
    request = Rack::Request.new(env)
    user_country = request.env['HTTP_CF_IPCOUNTRY'] # Cloudflare header
    current_region = ENV['FLY_REGION']

    if eu_user?(user_country) && !eu_region?(current_region)
      # CRITICAL VIOLATION - Log and block
      Rails.logger.error(
        "DATA_RESIDENCY_VIOLATION: EU user (#{user_country}) " \
        "attempted processing in non-EU region (#{current_region})"
      )

      return [
        403,
        { 'Content-Type' => 'application/json' },
        [{ error: 'Data residency violation', code: 'GDPR_REGION_MISMATCH' }.to_json]
      ]
    end

    @app.call(env)
  end

  private

  def eu_user?(country)
    EU_COUNTRIES.include?(country)
  end

  def eu_region?(region)
    %w[ams fra cdg lhr arn].include?(region)
  end
end
```

### Consequences

**Positive**:
- **Legal Compliance**: Avoids €1B+ class fines for GDPR violations
- **User Trust**: EU users' secrets never accessible to US government
- **Performance**: EU users get low-latency access (50-100ms vs 150-300ms)
- **Auditable**: Clear geographic separation provable in audits

**Negative**:
- **Infrastructure Cost**: +$150-300/month for separate EU deployment
- **Operational Complexity**: Must manage multiple deployments
- **Code Duplication**: Geo-routing logic adds complexity
- **Backup Complexity**: Must ensure backups also stay in EU

**Cost Delta**: **$200-300/month**
- Fly.io EU deployment: $150/month (3 machines @ $50/each)
- Upstash Redis EU: $50/month
- Caddy routing layer: $0 (can run on Fly.io)
- Monitoring/logging (EU-only): $30/month

### Compliance Validation
```bash
# Daily automated check
#!/bin/bash
# scripts/validate_eu_residency.sh

echo "Validating EU data residency..."

# Check all machines are in EU regions
eu_regions="ams fra cdg lhr arn"
non_compliant=$(fly status -a onetimesecret-eu | grep -v -E "($eu_regions)" | grep -c running)

if [ "$non_compliant" -gt 0 ]; then
  echo "❌ CRITICAL: Found machines outside EU regions!"
  curl -X POST "https://hooks.slack.com/..." -d '{"text": "🚨 EU Data Residency Violation Detected"}'
  exit 1
fi

# Check volume locations
fly volumes list -a onetimesecret-eu | grep -v -E "($eu_regions)"
if [ $? -eq 0 ]; then
  echo "❌ CRITICAL: Found volumes outside EU regions!"
  exit 1
fi

echo "✅ All EU data in compliant regions"
```

### Review Date
**June 2025** - Monitor EU-US Data Privacy Framework developments

---

## ADR-002: Australia Healthcare Data Absolute Localization

### Status
**ACCEPTED** - Statutory requirement, no alternatives

### Context
**Legal Conflict**:
- **Australia My Health Records Act 2012, Section 75**: "My Health Record information must not be taken or sent outside Australia"
- **EU GDPR Article 44**: Allows transfers with adequate safeguards

**Key Difference**:
- EU GDPR: Transfers allowed with SCCs/adequacy
- Australia Healthcare: **ABSOLUTE PROHIBITION** - no exceptions, no safeguards sufficient

### Decision
**Prohibit healthcare data** in OneTimeSecret Terms of Service for Australian users OR implement geographic detection and hard block.

### Implementation

#### Option A (SELECTED): Service Restriction via Terms of Service
```markdown
# Terms of Service - Prohibited Use Section

## Prohibited Content (Australia-Specific)

If you are accessing OneTimeSecret from Australia, you **MUST NOT** use the
service to share:

1. **My Health Record information** or any data derived from My Health Records
2. **Personal health information** as defined under Australian privacy law
3. **Medicare or healthcare provider information**

**Legal Basis**: Australia's My Health Records Act 2012 Section 75 prohibits
healthcare information from leaving Australia under any circumstances.
OneTimeSecret's infrastructure may process data outside Australia.

**Violation**: Use of OneTimeSecret for prohibited health information may result
in:
- Immediate account termination
- Reporting to Australian authorities as required by law
- Personal liability for regulatory violations (fines up to AUD $126,000)

**Alternative**: For healthcare information, use Australia-based secure
communication tools that guarantee data remains in Australia.
```

#### Option B (Future): Australian Sovereign Deployment
```toml
# fly-au.toml - Australia-only deployment
app = "onetimesecret-au"
primary_region = "syd"

[env]
  DEPLOYMENT_REGION = "AUSTRALIA_SOVEREIGN"
  ALLOWED_DATA_REGIONS = "syd"  # ONLY Sydney
  STRICT_RESIDENCY = "true"
  HEALTHCARE_ALLOWED = "true"

# This deployment would ONLY serve Australian users
# Data NEVER leaves Sydney region
```

#### Detection and Blocking (If healthcare detection possible)
```ruby
# app/models/secret.rb
class Secret < ApplicationRecord
  before_validation :detect_healthcare_content, if: :australian_user?

  HEALTHCARE_PATTERNS = [
    /medicare\s*(?:card|number)/i,
    /my\s*health\s*record/i,
    /patient\s*(?:id|number|record)/i,
    /prescription\s*number/i,
    /healthcare\s*identifier/i,
    /IHI\s*number/i,  # Individual Healthcare Identifier
  ].freeze

  def detect_healthcare_content
    return unless australian_user?

    if HEALTHCARE_PATTERNS.any? { |pattern| secret_content.match?(pattern) }
      errors.add(
        :base,
        "Australian users cannot share healthcare information via OneTimeSecret. " \
        "This violates the My Health Records Act 2012. " \
        "Please use Australia-based secure communication tools."
      )
    end
  end

  def australian_user?
    user_country == 'AU' || server_region == 'syd'
  end
end
```

### Consequences

**Positive**:
- **Legal Compliance**: Avoids criminal liability under My Health Records Act
- **Clear Boundaries**: Users understand service limitations
- **No Infrastructure Cost**: For Option A (ToS restriction)
- **Protects Company**: Explicit prohibition shifts liability to user

**Negative**:
- **Service Limitation**: Cannot serve Australian healthcare market
- **Detection Difficulty**: Hard to programmatically detect healthcare content
- **User Frustration**: Australian users may need separate tool for healthcare
- **Market Restriction**: Excludes potentially lucrative healthcare vertical

**Cost Delta**:
- **Option A (ToS Restriction)**: $0/month (legal disclaimer only)
- **Option B (AU Sovereign Deployment)**: $250/month (dedicated infrastructure)

### Compliance Validation
```sql
-- Detect potential healthcare content from Australian users (weekly audit)
SELECT
  secret_id,
  created_at,
  user_ip,
  user_country,
  processing_region,
  LENGTH(secret_content) as content_length,
  -- Redacted content check
  CASE
    WHEN secret_content ~* 'medicare|health record|patient|prescription|IHI'
    THEN 'POTENTIAL_HEALTHCARE'
    ELSE 'OK'
  END as risk_flag
FROM
  secrets
WHERE
  user_country = 'AU'
  AND created_at > NOW() - INTERVAL '7 days'
  AND processing_region != 'syd'
ORDER BY
  created_at DESC;
```

### Review Date
**Annual** - Monitor changes to My Health Records Act

---

## ADR-003: Brazil LGPD ANPD Standard Contractual Clauses

### Status
**REQUIRED** - Effective August 23, 2025 (grace period ended)

### Context
**Legal Conflict**:
- **Brazil LGPD + ANPD Resolution CD/ANPD No. 19/2024**: Cross-border data transfers require ANPD-approved Standard Contractual Clauses (SCCs)
- **Grace Period**: Ended August 23, 2025
- **Current State**: OneTimeSecret may not have Brazil-specific SCCs

**Enforcement Risk**:
- Brazil has aggressive enforcement (inspired by GDPR)
- ANPD can impose fines up to 2% of company revenue (max BRL 50 million)

### Decision
**Implement ANPD-approved SCCs** for any Brazilian user data processed outside Brazil OR **deploy to São Paulo region** for data residency.

### Implementation

#### Option A (SELECTED for MVP): Temporary Block Until SCCs Implemented
```ruby
# app/middleware/brazil_compliance_middleware.rb
class BrazilComplianceMiddleware
  SCC_IMPLEMENTATION_DATE = Date.parse('2025-09-30')  # Target date

  def call(env)
    request = Rack::Request.new(env)
    user_country = request.env['HTTP_CF_IPCOUNTRY']

    if brazil_user?(user_country) && !sccs_implemented?
      return [
        451,  # HTTP 451 Unavailable For Legal Reasons
        { 'Content-Type' => 'application/json' },
        [{
          error: 'Service temporarily unavailable in Brazil',
          code: 'BRAZIL_LGPD_COMPLIANCE',
          message: 'OneTimeSecret is implementing required data protection agreements ' \
                   'to comply with ANPD Resolution 19/2024. ' \
                   'Expected availability: September 30, 2025.',
          alternative: 'For urgent needs, consider Brazil-based alternatives.',
          legal_basis: 'LGPD Article 33 + ANPD Resolution CD/ANPD No. 19/2024'
        }.to_json]
      ]
    end

    @app.call(env)
  end

  private

  def brazil_user?(country)
    country == 'BR'
  end

  def sccs_implemented?
    Date.current >= SCC_IMPLEMENTATION_DATE
  end
end
```

#### Option B (Long-term): Implement ANPD SCCs
```ruby
# config/initializers/data_transfer_agreements.rb

# ANPD-approved SCC template (simplified - actual implementation requires legal review)
ANPD_SCC_TEMPLATE = {
  controller: 'OneTimeSecret Inc.',
  processor: 'Fly.io (or regional processor)',
  data_categories: [
    'Secret content (encrypted)',
    'Metadata (IP address, timestamp, expiry)',
    'Access logs (sanitized)'
  ],
  processing_purposes: [
    'Temporary secret storage and sharing',
    'Security and fraud prevention',
    'Service improvement'
  ],
  security_measures: [
    'AES-256 encryption at rest',
    'TLS 1.3 encryption in transit',
    'Access logging and monitoring',
    'Automated data deletion upon expiry'
  ],
  data_subject_rights: [
    'Right to access (Article 18 LGPD)',
    'Right to deletion (Article 18 LGPD)',
    'Right to data portability (Article 18 LGPD)',
    'Right to information about processing (Article 9 LGPD)'
  ],
  subprocessors: [
    { name: 'Fly.io', location: 'US/EU', service: 'Infrastructure' },
    { name: 'Upstash', location: 'EU', service: 'Redis caching' }
  ],
  incident_notification: '72 hours to ANPD; Immediate to data subjects if high risk',
  audit_rights: 'Annual audit by independent third party',
  term: '12 months (renewable)',
  governing_law: 'Brazilian law',
  dispute_resolution: 'Brazilian courts'
}.freeze

# Database migration to track SCC acceptance
class AddBrazilSccsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :brazil_scc_accepted, :boolean, default: false
    add_column :users, :brazil_scc_accepted_at, :datetime
    add_column :users, :brazil_scc_version, :string
  end
end
```

#### Option C (Alternative): Brazilian Regional Deployment
```toml
# fly-br.toml
app = "onetimesecret-br"
primary_region = "gru"  # São Paulo, Brazil

[env]
  DEPLOYMENT_REGION = "BRAZIL"
  ALLOWED_DATA_REGIONS = "gru"  # Keep data in Brazil
  LGPD_COMPLIANT = "true"
  ANPD_SCC_REQUIRED = "false"  # Not required if data stays in Brazil

[mounts]
  source = "secrets_br"
  destination = "/data"
```

### Consequences

**Positive**:
- **Legal Compliance**: Avoids ANPD fines (up to BRL 50M)
- **Market Access**: Can serve Brazilian users legally
- **Clear Framework**: ANPD SCCs provide legal certainty
- **Scalability**: Once implemented, can serve all of Latin America

**Negative**:
- **Legal Costs**: SCC implementation requires legal review ($5,000-15,000)
- **Operational Overhead**: Must track SCC versions, updates, renewals
- **User Friction**: May require user acceptance of SCCs
- **Temporary Block**: Option A blocks Brazilian users until implementation

**Cost Delta**:
- **Option A (Temporary Block)**: $0/month (plus opportunity cost)
- **Option B (SCC Implementation)**: $100/month (ongoing compliance) + $10k one-time legal
- **Option C (Brazil Region)**: $150/month (infrastructure)

**Recommendation**: Option B (SCCs) for scalability; Option C (Brazil region) if serving primarily Brazilian users

### Compliance Validation
```ruby
# Daily check for Brazil compliance
# scripts/brazil_compliance_check.rb

require 'date'

puts "Checking Brazil LGPD compliance..."

# Check if processing Brazilian data
brazilian_secrets_count = Secret.where(user_country: 'BR')
                                .where('created_at > ?', Date.parse('2025-08-23'))
                                .count

if brazilian_secrets_count > 0
  # Check if SCCs are in place
  sccs_implemented = ENV['ANPD_SCC_VERSION'].present?

  unless sccs_implemented
    puts "❌ CRITICAL: Processing Brazilian data without ANPD SCCs!"
    puts "   Secrets from Brazil: #{brazilian_secrets_count}"
    puts "   Legal risk: ANPD fines up to BRL 50 million"

    # Alert
    SlackNotifier.ping(
      "🚨 Brazil LGPD Violation: Processing #{brazilian_secrets_count} secrets without ANPD SCCs",
      channel: '#compliance'
    )

    exit 1
  else
    puts "✅ Brazil LGPD compliant (SCC version: #{ENV['ANPD_SCC_VERSION']})"
  end
else
  puts "ℹ️  No Brazilian user data being processed"
end
```

### Review Date
**Quarterly** - Monitor ANPD guidance updates and SCC template revisions

---

## ADR-004: Canada PIPEDA Transparency vs EU GDPR Minimization

### Status
**ACCEPTED** - Requires dual privacy policy approach

### Context
**Legal Conflict**:
- **Canada PIPEDA**: Requires explicit disclosure that data may be accessed by foreign authorities (e.g., US CLOUD Act)
- **EU GDPR Article 48**: Prohibits compliance with foreign government requests without MLAT (Mutual Legal Assistance Treaty)

**Specific Issue**:
- Canada requires: "Your data is stored in [country] and may be accessed by [country] authorities"
- EU requires: "We will not disclose your data to foreign governments except via MLAT"
- **These are contradictory**: Canada requires transparency about potential access; EU prohibits that access

### Decision
Implement **jurisdiction-specific privacy policies** and **separate infrastructure** for Canada and EU.

### Implementation

#### Geo-Specific Privacy Policies
```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def privacy_policy
    @privacy_policy = case user_jurisdiction
                      when 'CA'
                        render 'privacy_policies/canada'
                      when *EU_COUNTRIES
                        render 'privacy_policies/eu'
                      when 'BR'
                        render 'privacy_policies/brazil'
                      else
                        render 'privacy_policies/default'
                      end
  end

  private

  def user_jurisdiction
    request.headers['CF-IPCountry'] || session[:jurisdiction] || 'US'
  end

  EU_COUNTRIES = %w[AT BE BG HR CY CZ DK EE FI FR DE GR HU IE IT LV LT LU
                    MT NL PL PT RO SK SI ES SE NO IS LI].freeze
end
```

#### Canada-Specific Privacy Policy Excerpt
```markdown
# Privacy Policy for Canadian Users

## Data Storage and Cross-Border Transfers (PIPEDA Requirement)

**Your data may be processed in Canada and the European Union.**

Under Canadian law (PIPEDA), we must inform you that:

1. **Data Location**: Your personal information may be stored and processed in:
   - Canada (Toronto data center)
   - European Union (if using EU infrastructure)
   - United States (for infrastructure services provided by Fly.io)

2. **Foreign Authority Access**: When your data is processed outside Canada,
   it may be accessible to foreign government authorities under their laws,
   including:
   - **US CLOUD Act**: US authorities may compel access to data held by US companies
   - **EU GDPR Article 48**: EU-based data protected against foreign requests without MLAT

3. **Your Rights**: You have the right to:
   - Withdraw consent to cross-border processing
   - Request deletion of your data
   - Request details of all countries where your data is processed

4. **Our Safeguards**: We protect your data through:
   - End-to-end encryption (AES-256)
   - Contractual protections with processors
   - Regular security audits
   - Limited data retention (secrets auto-delete)

**Consent**: By using OneTimeSecret from Canada, you consent to cross-border
data processing as described above.
```

#### EU-Specific Privacy Policy Excerpt
```markdown
# Privacy Policy for EU/EEA Users

## Data Storage and Transfers (GDPR Compliance)

**Your data is processed exclusively in the European Economic Area.**

1. **Data Location**: Your personal information is stored and processed ONLY in:
   - Amsterdam, Netherlands (primary)
   - Frankfurt, Germany (backup)
   - Paris, France (backup)

2. **No Third-Country Transfers**: We do NOT transfer your data outside the
   EU/EEA, except in the following limited circumstances:
   - **Adequacy Decision Countries**: UK, Switzerland, Japan (with adequacy decision)
   - **Standard Contractual Clauses**: Only if you explicitly consent AND we implement
     EU Commission-approved Standard Contractual Clauses

3. **Protection Against Foreign Requests**: Under GDPR Article 48:
   - We will NOT comply with foreign government data requests unless via MLAT
   - We will notify you of any government request (unless legally prohibited)
   - We will challenge unlawful requests in court

4. **Your Rights**: You have the right to:
   - Access your data (Article 15)
   - Erasure (Article 17)
   - Data portability (Article 20)
   - Object to processing (Article 21)
   - Lodge a complaint with your Data Protection Authority

**Legal Basis**: We process your data based on:
- Consent (GDPR Article 6(1)(a)) for non-essential processing
- Legitimate interest (GDPR Article 6(1)(f)) for security and fraud prevention
```

#### Infrastructure Separation
```toml
# fly-ca.toml - Canada deployment
app = "onetimesecret-ca"
primary_region = "yyz"  # Toronto

[env]
  DEPLOYMENT_REGION = "CANADA"
  ALLOWED_DATA_REGIONS = "yyz,yyc"  # Toronto, Calgary
  PIPEDA_COMPLIANT = "true"
  CLOUD_ACT_DISCLOSURE = "true"  # Canadian policy requires this disclosure

---

# fly-eu.toml - EU deployment (from ADR-001)
app = "onetimesecret-eu"
primary_region = "ams"

[env]
  DEPLOYMENT_REGION = "EU"
  ALLOWED_DATA_REGIONS = "ams,fra,cdg"
  GDPR_ARTICLE_48_PROTECTED = "true"  # EU policy - no foreign access
```

### Consequences

**Positive**:
- **Legal Compliance**: Satisfies both PIPEDA and GDPR requirements
- **Transparency**: Users clearly understand data handling
- **Trust**: Jurisdictionally appropriate privacy protections
- **Flexibility**: Can add more jurisdiction-specific policies as needed

**Negative**:
- **Complexity**: Multiple privacy policies to maintain
- **Infrastructure**: Separate Canadian deployment adds cost
- **Legal Review**: Each policy needs legal review ($3,000-5,000 each)
- **User Confusion**: Different policies for different jurisdictions

**Cost Delta**: **$200/month**
- Canada deployment: $150/month
- Legal review (amortized): $50/month (annual review)

### Compliance Validation
```ruby
# Test that correct privacy policy is shown based on jurisdiction
# spec/controllers/pages_controller_spec.rb

RSpec.describe PagesController, type: :controller do
  describe 'GET #privacy_policy' do
    context 'when user is from Canada' do
      before { request.headers['CF-IPCountry'] = 'CA' }

      it 'shows PIPEDA-compliant policy' do
        get :privacy_policy
        expect(response.body).to include('PIPEDA')
        expect(response.body).to include('US CLOUD Act')
        expect(response.body).to include('foreign government authorities')
      end
    end

    context 'when user is from EU' do
      before { request.headers['CF-IPCountry'] = 'DE' }

      it 'shows GDPR-compliant policy' do
        get :privacy_policy
        expect(response.body).to include('GDPR')
        expect(response.body).to include('Article 48')
        expect(response.body).to include('exclusively in the European Economic Area')
        expect(response.body).not_to include('US CLOUD Act')
      end
    end
  end
end
```

### Review Date
**June 2025** - Monitor Bill C-27 developments (Canada privacy law reform)

---

## ADR-005: UK Adequacy Decision Sunset Contingency

### Status
**MONITORING** - Becomes critical June 2025

### Context
**Legal Situation**:
- **Current**: UK has EU adequacy decision (since June 2021)
- **Expiry**: June 2025 (4-year sunset clause)
- **Risk**: If not renewed, UK becomes "third country" requiring SCCs for EU data transfers

**Likelihood Assessment**:
- **Renewal likely**: UK GDPR closely mirrors EU GDPR
- **Political risk**: Brexit tensions could affect renewal
- **Precedent**: Switzerland renewed in 2024 without issue

### Decision
**Contingency planning**: Prepare SCCs for UK transfers but assume renewal for now.

### Implementation

#### Monitoring and Alerting
```ruby
# lib/tasks/compliance.rake
namespace :compliance do
  desc 'Check UK adequacy decision status'
  task check_uk_adequacy: :environment do
    uk_adequacy_expiry = Date.parse('2025-06-30')
    days_until_expiry = (uk_adequacy_expiry - Date.current).to_i

    if days_until_expiry < 90 && days_until_expiry > 0
      puts "⚠️  WARNING: UK adequacy decision expires in #{days_until_expiry} days"
      puts "   Action required: Prepare UK SCCs or migrate UK users to EU regions"

      # Alert compliance team
      ComplianceNotifier.uk_adequacy_expiring(days_until_expiry).deliver_now
    elsif days_until_expiry <= 0
      puts "🚨 CRITICAL: UK adequacy decision has expired!"
      puts "   EU-UK data transfers now require SCCs"

      # Critical alert
      PagerDutyNotifier.trigger(
        summary: 'UK adequacy decision expired - SCCs required',
        severity: 'critical'
      )
    else
      puts "✅ UK adequacy decision valid (expires #{uk_adequacy_expiry})"
    end
  end
end
```

#### Contingency Plan: Automated SCC Implementation
```ruby
# config/initializers/uk_scc_contingency.rb

# Trigger SCCs automatically if adequacy lapses
UK_ADEQUACY_DECISION_EXPIRY = Date.parse('2025-06-30')

if Date.current > UK_ADEQUACY_DECISION_EXPIRY
  # Check if renewal announced
  unless ENV['UK_ADEQUACY_RENEWED'] == 'true'
    Rails.logger.warn "UK adequacy decision expired - enabling SCC mode"

    # Enable UK SCCs
    Rails.application.config.uk_scc_required = true
    Rails.application.config.uk_treated_as_third_country = true
  end
end
```

#### Caddy Routing Update (Contingency)
```caddyfile
# If UK adequacy lapses, route UK users to EU infrastructure with SCCs
onetimesecret.com {
  # UK users after adequacy lapse
  @uk_users_post_adequacy {
    header_regexp country CF-IPCountry ^GB$
    expression {env.UK_ADEQUACY_RENEWED} != "true"
  }

  reverse_proxy @uk_users_post_adequacy https://onetimesecret-eu.fly.dev {
    header_up X-Data-Residency-Region EU
    header_up X-Processing-Jurisdiction GDPR
    header_up X-UK-SCC-Required true  # Trigger SCC acceptance flow
  }
}
```

### Consequences

**Positive**:
- **Proactive**: Prepared for adequacy lapse
- **Minimal Disruption**: Can switch to SCCs seamlessly
- **Cost Efficiency**: Don't build expensive infrastructure unless needed

**Negative**:
- **Uncertainty**: Can't finalize architecture until June 2025
- **User Friction**: UK users may need to accept SCCs if adequacy lapses
- **Legal Costs**: SCC preparation requires legal review

**Cost Delta**:
- **Current (adequacy valid)**: $0/month
- **If adequacy lapses**: +$50/month (SCC compliance overhead)

### Decision Timeline
```
2025-03-01: Review EU Commission announcements
2025-04-01: If no renewal announced, prepare UK SCCs
2025-05-01: Final contingency testing (SCCs ready to deploy)
2025-06-30: Adequacy expires (activate SCCs if not renewed)
```

### Review Date
**Monthly until June 2025**, then **Quarterly** if renewed

---

## Summary of ADRs

| ADR | Conflict | Decision | Cost | Status | Review |
|-----|----------|----------|------|--------|--------|
| ADR-001 | EU vs US (Schrems II) | EU-only infrastructure | $200-300/mo | **ACTIVE** | Jun 2025 |
| ADR-002 | Australia Healthcare | Prohibit healthcare in ToS | $0/mo | **ACTIVE** | Annual |
| ADR-003 | Brazil LGPD SCCs | Implement ANPD SCCs or block | $100/mo | **REQUIRED** | Quarterly |
| ADR-004 | Canada vs EU Privacy | Dual privacy policies + infrastructure | $200/mo | **ACTIVE** | Jun 2025 |
| ADR-005 | UK Adequacy Sunset | Contingency SCCs (monitor) | $0-50/mo | **MONITORING** | Monthly |

**Total Estimated Cost**: $500-650/month for multi-jurisdiction compliance

## Next Steps
- Proceed to Phase 5: Monitoring and Compliance Queries
- Implement ADR validation scripts in CI/CD
- Schedule legal review of privacy policies
