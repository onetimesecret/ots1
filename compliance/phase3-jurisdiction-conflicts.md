# PHASE 3: Jurisdiction Conflict Detection

## Overview
This document identifies conflicts between jurisdiction requirements that would make it impossible or expensive to serve users from multiple jurisdictions with a single deployment.

## Conflict Detection SQL Schema

```sql
CREATE TABLE jurisdiction_conflicts (
  conflict_id SERIAL PRIMARY KEY,
  requirement_a TEXT NOT NULL,
  jurisdiction_a TEXT NOT NULL,
  requirement_b TEXT NOT NULL,
  jurisdiction_b TEXT NOT NULL,
  conflict_type TEXT CHECK (conflict_type IN ('impossible', 'expensive')),
  resolution_pattern TEXT NOT NULL,
  estimated_cost_delta_monthly_usd INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for efficient querying
CREATE INDEX idx_jurisdiction_a ON jurisdiction_conflicts(jurisdiction_a);
CREATE INDEX idx_jurisdiction_b ON jurisdiction_conflicts(jurisdiction_b);
CREATE INDEX idx_conflict_type ON jurisdiction_conflicts(conflict_type);
```

## Populated Conflicts

```sql
INSERT INTO jurisdiction_conflicts (
  requirement_a,
  jurisdiction_a,
  requirement_b,
  jurisdiction_b,
  conflict_type,
  resolution_pattern,
  estimated_cost_delta_monthly_usd
) VALUES
-- Conflict 1: EU vs US (No adequacy decision for general US hosting)
(
  'GDPR Article 44: Data transfer to third countries requires adequacy decision or SCCs',
  'European Union',
  'US providers subject to CLOUD Act, FISA 702 (government access without EU-level protections)',
  'United States',
  'impossible',
  'Deploy separate infrastructure: EU users on EU-only regions (ams/fra/cdg), US users on US regions. OR: Use EU regions for all with SCCs + TIA (Transfer Impact Assessment)',
  300
),

-- Conflict 2: China (Not in scope but illustrative)
-- Note: China has data localization requirements but OneTimeSecret not targeting China currently
-- Included for future reference if expansion considered

-- Conflict 3: Japan APPI vs Brazil LGPD (Different SCC requirements)
(
  'Japan APPI Article 28: Cross-border transfer requires consent OR adequate country OR APEC CBPR certification',
  'Japan',
  'Brazil LGPD + ANPD Resolution 19/2024: Cross-border transfer requires ANPD-approved SCCs (specific format)',
  'Brazil',
  'expensive',
  'Multi-lateral SCC approach: Use ANPD SCCs for Brazil; Separate consent flow for Japan (or APEC CBPR certification); Deploy to adequacy countries where possible',
  150
),

-- Conflict 4: Australia Healthcare Data vs General Deployment
(
  'Australia My Health Records Act: Health records MUST NOT leave Australia under any circumstances',
  'Australia',
  'EU GDPR Article 44: EU data should remain in EU unless adequacy/SCCs',
  'European Union',
  'impossible',
  'Service restriction: Do NOT offer OneTimeSecret for healthcare data in Australia. Add ToS clause prohibiting health information. OR: Dedicated Australia-only deployment for Australian users',
  250
),

-- Conflict 5: Canada PIPEDA Transparency vs EU GDPR Minimization
(
  'Canada PIPEDA: Must disclose that data may be accessed by foreign authorities (e.g., US CLOUD Act)',
  'Canada',
  'EU GDPR Article 5(1)(c): Data minimization - collect only necessary information; Article 48: GDPR takes precedence over foreign government requests without MLAT',
  'European Union',
  'expensive',
  'Separate privacy policies: EU version emphasizes GDPR protection; Canada version includes CLOUD Act disclosure; Implement geographic routing to ensure Canadian data on Canadian infrastructure (if using BYOC)',
  200
),

-- Conflict 6: Singapore No Data Residency vs Implicit Regional Deployment
(
  'Singapore PDPA: No data residency requirement - only "comparable protection" required for transfers',
  'Singapore',
  'EU GDPR Article 44-46: Strict data residency or adequacy requirements',
  'European Union',
  'expensive',
  'Shared infrastructure viable BUT: If serving EU + Singapore from EU regions, performance may suffer for Singapore users; If serving from Singapore region, must implement SCCs for any EU user data cached there',
  100
),

-- Conflict 7: Switzerland Adequacy for US vs EU Skepticism
(
  'Switzerland FADP + DPO Annex 1: US certified under Swiss-US DPF (adequacy for certified companies as of Sept 2024)',
  'Switzerland',
  'EU GDPR Post-Schrems II: EU-US DPF exists but under scrutiny; Schrems III litigation ongoing',
  'European Union',
  'expensive',
  'Conservative approach: Treat Switzerland like EU (deploy to EU/Swiss regions only); Liberal approach: Use Swiss-US DPF for Switzerland users, separate SCCs for EU users',
  50
),

-- Conflict 8: UK Adequacy Sunset vs Long-Term Architecture
(
  'UK GDPR + EU Adequacy Decision: EU adequacy for UK expires June 2025 unless renewed',
  'United Kingdom',
  'EU GDPR Article 44: If UK adequacy lapses, UK becomes third country requiring SCCs',
  'European Union',
  'expensive',
  'Contingency planning: Current state - treat UK as adequate (lhr region viable for EU data); Post-June 2025 if not renewed - implement SCCs or migrate UK users to EU regions',
  100
),

-- Conflict 9: Japan Consent vs EU Legitimate Interest
(
  'Japan APPI Article 28: Cross-border transfer typically requires explicit opt-in consent',
  'Japan',
  'EU GDPR Article 6: Consent is ONE lawful basis; Legitimate interest often preferred for operational transfers',
  'European Union',
  'expensive',
  'Dual legal basis: For EU users - rely on legitimate interest (documented LIA); For Japan users - obtain explicit consent for any cross-border transfer; Shared infrastructure requires more restrictive approach (consent)',
  75
),

-- Conflict 10: Australia APP 8 Accountability vs US Subprocessor Chains
(
  'Australia Privacy Act APP 8: Australian entity remains accountable for overseas recipient actions (strict liability)',
  'Australia',
  'US Cloud Providers: Often use subprocessors across multiple jurisdictions; CLOUD Act allows US government access',
  'United States',
  'expensive',
  'Contractual mitigation: Require cloud provider to limit subprocessors to Australia + adequate countries; Audit trail of all subprocessor changes; Consider Australian sovereign cloud providers OR separate Australian deployment',
  200
),

-- Conflict 11: New Zealand IPP 12 vs BYOC Compliance Overhead
(
  'New Zealand Privacy Act IPP 12: Requires comparable safeguards OR explicit authorization with disclosure of risks',
  'New Zealand',
  'Multi-jurisdiction deployment: Each foreign region requires assessment of comparable safeguards',
  'Multiple',
  'expensive',
  'Documentation overhead: Assess each deployment region for comparable safeguards; Maintain register of assessments; Update on regulatory changes; NZ is similar to AU - can often share assessment',
  50
),

-- Conflict 12: Brazil Grace Period End vs Deployment Timeline
(
  'Brazil LGPD + ANPD Resolution 19/2024: SCC grace period ended August 23, 2025 - now mandatory',
  'Brazil',
  'OneTimeSecret current state: May not have Brazil-specific SCCs implemented',
  'Current Deployment',
  'expensive',
  'Immediate action if serving Brazil users: Implement ANPD-approved SCCs for any cross-border data flow; Alternative: Deploy to Brazil region (São Paulo) and keep Brazilian user data in Brazil',
  100
);
```

## Conflict Matrix Summary

| Jurisdiction A | Jurisdiction B | Conflict Type | Primary Issue | Resolution Cost (Monthly USD) |
|----------------|----------------|---------------|---------------|-------------------------------|
| **EU** | **US** | **IMPOSSIBLE** | Schrems II invalidated Privacy Shield; CLOUD Act vs GDPR | **$300** |
| EU | Australia (Healthcare) | IMPOSSIBLE | Australian health data cannot leave Australia | $250 |
| Japan | Brazil | EXPENSIVE | Different SCC formats and consent requirements | $150 |
| Canada | EU | EXPENSIVE | Conflicting transparency vs minimization requirements | $200 |
| Singapore | EU | EXPENSIVE | No residency requirement vs strict EU residency preference | $100 |
| Switzerland | EU | EXPENSIVE | Swiss-US DPF adequacy vs EU skepticism | $50 |
| UK | EU | EXPENSIVE | Adequacy decision expiring June 2025 | $100 |
| Japan | EU | EXPENSIVE | Consent requirement vs legitimate interest | $75 |
| Australia | US | EXPENSIVE | Strict accountability vs subprocessor complexity | $200 |
| New Zealand | Multiple | EXPENSIVE | Assessment overhead for each region | $50 |
| Brazil | Current State | EXPENSIVE | New SCC requirement as of August 2025 | $100 |

## Key Findings

### IMPOSSIBLE Conflicts (Cannot serve both from single deployment)

1. **EU + US (General US Hosting)**
   - **Problem**: Post-Schrems II, general US cloud hosting is not adequate for EU data
   - **Evidence**: Meta €1.2B fine, Uber €290M fine, TikTok €530M projected fine
   - **Resolution**: MUST use EU regions for EU users OR implement SCCs + Transfer Impact Assessment (TIA) demonstrating US provider has EU-level protections
   - **Cost**: Separate infrastructure or extensive legal assessment

2. **EU + Australia Healthcare**
   - **Problem**: Australian My Health Records Act prohibits healthcare data from leaving Australia under ANY circumstances
   - **Evidence**: Statutory requirement, no exceptions
   - **Resolution**: Either prohibit healthcare data in ToS OR separate Australian deployment
   - **Cost**: Service restriction or dedicated infrastructure

### EXPENSIVE Conflicts (Can serve both but with significant overhead)

1. **Japan + Brazil** ($150/month)
   - **Problem**: Japan requires consent or APEC CBPR; Brazil requires ANPD-specific SCCs
   - **Resolution**: Implement both frameworks; APEC CBPR certification recommended for Japan

2. **Canada + EU** ($200/month)
   - **Problem**: Canada requires transparency about foreign government access; EU GDPR Article 48 prohibits compliance with foreign requests without MLAT
   - **Resolution**: Separate privacy policies; consider Canadian deployment region

3. **Australia + US** ($200/month)
   - **Problem**: Australian entity strictly liable for overseas recipient violations; US CLOUD Act creates legal conflict
   - **Resolution**: Australian sovereign cloud OR extensive contractual protections

4. **UK + EU Post-June 2025** ($100/month)
   - **Problem**: UK adequacy decision expires June 2025
   - **Resolution**: Contingency planning; implement SCCs before expiry or confirm renewal

## Non-Conflicting Jurisdictions

### Compatible Pairings (Can serve from shared infrastructure):

1. **EU + Switzerland**
   - Both have similar data protection standards
   - Switzerland FADP closely aligned with GDPR
   - Can deploy to `fra` (Frankfurt) or `ams` (Amsterdam) for both

2. **EU + UK (Current State, pre-June 2025)**
   - UK has EU adequacy decision
   - Can deploy to `lhr` (London) for both
   - Monitor June 2025 renewal

3. **New Zealand + Australia**
   - Both have "comparable safeguards" approach
   - NZ IPP 12 and AU APP 8 are similar
   - Can deploy to Sydney region for both

4. **Japan + Singapore**
   - Japan recognizes APEC CBPR
   - Singapore PDPA has "comparable protection" standard
   - Both can be served from `sin` or `nrt` (Tokyo) regions

5. **Canada + US**
   - Canada PIPEDA allows US processing with disclosure
   - Can deploy to US regions with proper privacy policy

## Deployment Architecture Patterns

### Pattern 1: EU-Strict (Recommended for MVP)
**Target Jurisdictions**: EU, UK, Switzerland, potentially Norway/Iceland

**Configuration**:
```toml
primary_region = "ams"  # Amsterdam
allowed_regions = ["ams", "fra", "cdg", "lhr"]  # EU + UK
```

**Pros**:
- Minimal compliance risk
- Single regulatory framework (GDPR-based)
- Adequate for 3-4 jurisdictions

**Cons**:
- Higher latency for APAC/Americas users
- Cannot legally serve some jurisdictions (AU healthcare, Brazil without SCCs)

**Estimated Cost**: $100-200/month (base Fly.io deployment)

---

### Pattern 2: Multi-Region with Geo-Fencing
**Target Jurisdictions**: EU, UK, Switzerland, Japan, Singapore, Canada, New Zealand, Australia (non-healthcare)

**Configuration**:
```toml
# EU cluster
primary_region = "ams"
allowed_regions = ["ams", "fra", "cdg", "lhr"]

# APAC cluster (separate deployment)
primary_region = "sin"  # Singapore
allowed_regions = ["sin", "nrt", "syd"]  # Singapore, Tokyo, Sydney

# Americas cluster (separate deployment)
primary_region = "yyz"  # Toronto (Canada)
allowed_regions = ["yyz", "ewr"]  # Toronto, New Jersey (for US users)
```

**User Routing Logic**:
- EU/UK/CH users → EU cluster
- Japan/Singapore users → APAC cluster
- Australia users → Sydney ONLY (data residency)
- New Zealand users → Sydney (with NZ-specific SCCs)
- Canada users → Toronto (with PIPEDA disclosures)
- Brazil users → Blocked until ANPD SCCs implemented

**Pros**:
- Lower latency globally
- Compliance with most jurisdictions
- Scalable architecture

**Cons**:
- 3x infrastructure cost
- Complex geo-routing logic
- Multiple privacy policies
- SCC maintenance overhead

**Estimated Cost**: $500-800/month (3 regional deployments + Caddy routing layer)

---

### Pattern 3: Hybrid (EU Base + Selective Regional Expansion)
**Target Jurisdictions**: EU, UK, Switzerland (primary); Japan, Singapore, Canada (secondary with SCCs)

**Configuration**:
```toml
# Primary EU deployment
primary_region = "ams"
allowed_regions = ["ams", "fra", "cdg", "lhr"]

# SCCs configured for:
# - Japan (APEC CBPR certification as alternative)
# - Singapore (PDPA comparable protection assessment)
# - Canada (PIPEDA with transparency disclosure)
# - New Zealand (IPP 12 comparable safeguards)
```

**User Routing Logic**:
- EU/UK/CH users → EU regions (fast path)
- Japan/Singapore/Canada/NZ users → EU regions (with SCCs and consent)
- Australia users → Require explicit acknowledgment of EU processing OR block
- Brazil users → Require ANPD SCCs OR block
- US users → Allowed with GDPR-level protections (strict)

**Pros**:
- Single infrastructure (lower cost)
- Serves most jurisdictions
- Simpler operations

**Cons**:
- Higher latency for APAC/Americas
- Requires robust SCC framework
- Some jurisdictions blocked (AU healthcare, Brazil initially)

**Estimated Cost**: $200-350/month (single deployment + SCC legal compliance)

## Recommended Resolution Pattern

### Phase 1 (MVP): EU-Strict Pattern
- Deploy to Amsterdam (`ams`) primary, Frankfurt (`fra`) backup
- Serve: EU, UK, Switzerland, Norway, Iceland, Liechtenstein
- Block: Australia (healthcare), Brazil (until ANPD SCCs), explicitly warn for others
- **Timeline**: Immediate
- **Cost**: $150/month

### Phase 2 (Expansion): Add APAC with SCCs
- Maintain EU deployment
- Add Japan + Singapore via SCCs or APEC CBPR
- Add New Zealand via IPP 12 agreement
- **Timeline**: 3-6 months
- **Additional Cost**: +$100/month (legal compliance)

### Phase 3 (Global): Multi-Region Architecture
- Deploy APAC cluster (Singapore/Tokyo/Sydney)
- Deploy Americas cluster (Toronto/US)
- Implement geo-routing with Caddy
- Full SCC framework
- **Timeline**: 6-12 months
- **Additional Cost**: +$400-600/month (infrastructure + legal)

## Monitoring Queries for Conflict Detection

```sql
-- Query 1: Detect EU user data processed in non-adequate regions
SELECT
  user_id,
  user_country,
  processing_region,
  'GDPR_VIOLATION' as violation_type,
  'EU data processed outside adequate regions' as description
FROM
  secrets_audit
WHERE
  user_country IN ('DE', 'FR', 'NL', 'BE', 'ES', 'IT', 'PL', 'AT', 'DK', 'SE', 'FI', 'IE', 'PT', 'GR', 'CZ', 'RO', 'HU', 'BG', 'HR', 'SI', 'SK', 'LT', 'LV', 'EE', 'CY', 'MT', 'LU')
  AND processing_region NOT IN ('ams', 'fra', 'cdg', 'lhr', 'arn')
  AND created_at > NOW() - INTERVAL '24 hours';

-- Query 2: Detect Australian healthcare data outside Australia
SELECT
  secret_id,
  user_country,
  processing_region,
  'AUSTRALIAN_HEALTHCARE_VIOLATION' as violation_type,
  'Australian healthcare data outside Australia' as description
FROM
  secrets_audit
WHERE
  user_country = 'AU'
  AND secret_type = 'healthcare'  -- Assuming type classification
  AND processing_region != 'syd'
  AND created_at > NOW() - INTERVAL '24 hours';

-- Query 3: Detect Brazil data without SCCs (post-grace period)
SELECT
  secret_id,
  user_country,
  processing_region,
  has_anpd_scc,
  'BRAZIL_SCC_VIOLATION' as violation_type
FROM
  secrets_audit
WHERE
  user_country = 'BR'
  AND processing_region NOT IN ('gru', 'sao')  -- São Paulo region
  AND (has_anpd_scc = FALSE OR has_anpd_scc IS NULL)
  AND created_at > '2025-08-23'  -- After grace period
ORDER BY
  created_at DESC;

-- Query 4: Detect cross-border transfers without valid legal basis
SELECT
  sa.secret_id,
  sa.user_country,
  sa.processing_region,
  sa.legal_basis,
  jc.jurisdiction_a,
  jc.conflict_type
FROM
  secrets_audit sa
  LEFT JOIN jurisdiction_conflicts jc
    ON sa.user_country = jc.jurisdiction_a
WHERE
  sa.processing_region NOT IN (
    -- Region allowlist for user's country
    SELECT allowed_region
    FROM region_jurisdiction_mapping
    WHERE jurisdiction = sa.user_country
  )
  AND (sa.legal_basis IS NULL OR sa.legal_basis = '')
  AND sa.created_at > NOW() - INTERVAL '7 days'
ORDER BY
  sa.created_at DESC;

-- Query 5: Detect UK data post-adequacy lapse (future-proofing)
SELECT
  secret_id,
  user_country,
  processing_region,
  has_uk_scc,
  'UK_POST_ADEQUACY_VIOLATION' as violation_type
FROM
  secrets_audit
WHERE
  user_country = 'GB'
  AND created_at > '2025-06-30'  -- After June 2025 adequacy expiry
  AND processing_region NOT IN ('lhr', 'ams', 'fra', 'cdg')  -- UK or EU regions
  AND (has_uk_scc = FALSE OR has_uk_scc IS NULL);
```

## Next Steps
- Proceed to Phase 4: Generate Architecture Decision Records for each conflict resolution
- Document specific technical implementation for each pattern
- Create compliance monitoring dashboards
