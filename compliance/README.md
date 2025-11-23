# OneTimeSecret Multi-Jurisdiction Compliance Research

## Executive Summary

This comprehensive compliance research covers data residency and privacy requirements for OneTimeSecret's expansion into multiple jurisdictions. The research follows a structured 6-phase approach to identify legal requirements, technical implementations, conflicts, and customer disclosure obligations.

**Target Jurisdictions**:
- **Current**: EU, Canada, New Zealand, US
- **Expansion**: Singapore, Japan, Australia, UK post-Brexit, Switzerland, Brazil

**Research Completion**: November 23, 2025

---

## Research Phases Completed

### ✅ Phase 1: Legal Requirement Extraction
**File**: `phase1-eu-legal-requirements.md`

Extracted specific legal requirements from EU regulations (GDPR + ePrivacy Directive) with exact article citations, enforcement examples, and real fine amounts.

**Key Findings**:
- **GDPR Article 44-46**: €1.2B fine (Meta) for unlawful EU-US transfers
- **GDPR Article 32**: Encryption expected (not optional) for secrets
- **GDPR Article 5(1)(e)**: OneTimeSecret's time-limited model ALIGNS with storage limitation
- **GDPR Article 33**: 72-hour breach notification requirement

---

### ✅ Phase 2: Technical Implementation Matrix
**File**: `phase2-eu-technical-implementation.md`

Maps each legal requirement to specific Fly.io and Northflank configurations with actual code snippets.

**Key Deliverables**:
- Fly.io `fly.toml` configurations for EU deployment
- SQLCipher encryption setup (AES-256)
- Redis (Upstash) EU-region configuration
- Application-level region enforcement code
- GDPR-compliant logging configuration
- Backup residency validation scripts

**Example Configuration**:
```toml
app = "onetimesecret-eu"
primary_region = "ams"  # Amsterdam

[env]
  ALLOWED_REGIONS = "ams,fra,cdg,lhr,arn"
  DATA_RESIDENCY_MODE = "EU_STRICT"
  ENCRYPTION_REQUIRED = "true"
```

---

### ✅ Phase 3: Jurisdiction Conflict Detection
**File**: `phase3-jurisdiction-conflicts.md`

Identified 12 specific conflicts between jurisdictions with SQL schema for tracking.

**Critical Conflicts**:

| Conflict | Type | Cost Impact | Resolution |
|----------|------|-------------|------------|
| **EU vs US (Schrems II)** | IMPOSSIBLE | $300/mo | Separate EU infrastructure |
| **EU vs Australia Healthcare** | IMPOSSIBLE | $250/mo | Prohibit healthcare in ToS |
| **Japan vs Brazil (SCCs)** | EXPENSIVE | $150/mo | Dual SCC framework |
| **Canada vs EU (Transparency)** | EXPENSIVE | $200/mo | Separate privacy policies |
| **UK Adequacy Sunset (June 2025)** | EXPENSIVE | $100/mo | Contingency SCCs |

**Total Estimated Cost for Multi-Jurisdiction**: $500-700/month

---

### ✅ Phase 4: Architecture Decision Records (ADRs)
**File**: `phase4-architecture-decision-records.md`

Created 5 detailed ADRs for critical conflicts:

1. **ADR-001**: EU vs US Data Handling (Schrems II)
   - **Decision**: EU-only infrastructure for EU users
   - **Cost**: $200-300/month
   - **Implementation**: Geo-routing with Caddy

2. **ADR-002**: Australia Healthcare Data Localization
   - **Decision**: Prohibit healthcare data in ToS
   - **Cost**: $0/month (service restriction)

3. **ADR-003**: Brazil LGPD ANPD SCCs
   - **Decision**: Implement ANPD SCCs or block Brazil
   - **Cost**: $100/month + $10k legal
   - **Deadline**: August 23, 2025 (CRITICAL)

4. **ADR-004**: Canada PIPEDA vs EU GDPR Privacy
   - **Decision**: Dual privacy policies + infrastructure
   - **Cost**: $200/month

5. **ADR-005**: UK Adequacy Decision Sunset
   - **Decision**: Contingency planning; assume renewal
   - **Monitor**: June 2025

---

### ✅ Phase 5: Monitoring & Compliance Queries
**File**: `phase5-monitoring-compliance-queries.md`

Created PostgreSQL queries for automated compliance monitoring:

**Real-Time Violation Detection**:
- EU data in non-adequate regions (GDPR Article 44)
- Storage limitation violations (expired secrets not deleted)
- Right to erasure compliance (30-day tracking)
- Breach notification timeline (72-hour monitoring)
- Brazil ANPD SCC violations (post-grace period)
- Australia healthcare data outside Australia

**Compliance Dashboard**:
- Real-time compliance scorecard across all jurisdictions
- Retention audit reports
- Records of Processing Activities (ROPA) generation
- Breach notification report templates

**Automated Actions**:
- Auto-delete expired secrets (every 5 minutes)
- Compliance violation logging (triggers)
- Prometheus metrics export

---

### ✅ Phase 6: Customer Disclosure Requirements
**File**: `phase6-customer-disclosure-requirements.md`

Generated jurisdiction-specific privacy policies, UI notifications, consent forms, and breach templates.

**Deliverables**:

| Jurisdiction | Privacy Policy | UI Notifications | Consent Checkboxes | Deletion Timeframe | Breach Notification |
|--------------|---------------|------------------|--------------------|--------------------|---------------------|
| **EU** | GDPR Articles 13-14 compliant | Cookie banner + Data notice | Cross-border (if applicable) | 30 days | 72 hours to DPA |
| **Canada** | PIPEDA 10 principles | US CLOUD Act warning | Cross-border consent | 30 days | Reasonable time |
| **Brazil** | Bilingual (PT/EN) | ANPD SCC notice | LGPD consent | 15 days | Reasonable time |
| **Australia** | APP compliance | Healthcare prohibition | Cross-border disclosure | 30 days | Immediate if harm |
| **Japan** | APPI Article 28 | Transfer consent notice | Opt-in for transfers | 30 days | Without delay |

**Example: EU Cookie Consent Banner** (ePrivacy Directive compliant)
**Example: Canada CLOUD Act Disclosure** (PIPEDA requirement)
**Example: Brazil Bilingual Policy** (LGPD requirement)

---

## Unified Compliance Data

**File**: `unified-compliance-data.json`

Programmatically consumable JSON containing all research data:
- Legal requirements per jurisdiction
- Technical configurations
- Conflict matrix
- Deployment patterns
- Compliance metrics
- Sources and citations

---

## Recommended Deployment Patterns

### Pattern 1: EU-Strict (MVP) ⭐ RECOMMENDED
**Cost**: $150-200/month
**Jurisdictions**: EU, UK, Switzerland, Norway, Iceland

**Pros**:
- ✅ Minimal compliance risk
- ✅ Single regulatory framework (GDPR)
- ✅ Low operational complexity
- ✅ Covers 3-4 major jurisdictions

**Cons**:
- ❌ Higher latency for APAC/Americas (150-300ms)
- ❌ Cannot serve Brazil (until ANPD SCCs)
- ❌ Cannot serve Australia healthcare

**Configuration**:
```bash
fly deploy --config fly-eu.toml --region ams
fly redis create --region ams --name onetimesecret-redis-eu
```

---

### Pattern 2: Multi-Region with Geo-Fencing
**Cost**: $500-800/month
**Jurisdictions**: EU, UK, CH, JP, SG, CA, NZ, AU (non-healthcare)

**Architecture**:
- **EU Cluster**: ams, fra, cdg → Serves EU, UK, CH
- **APAC Cluster**: sin, nrt, syd → Serves JP, SG, AU, NZ
- **Americas Cluster**: yyz, ewr → Serves CA, US

**Pros**:
- ✅ Global low latency (50-100ms)
- ✅ Compliance with 8+ jurisdictions
- ✅ Scalable for growth

**Cons**:
- ❌ 3x infrastructure cost
- ❌ Complex geo-routing (Caddy)
- ❌ Multiple privacy policies
- ❌ SCC maintenance overhead

---

### Pattern 3: Hybrid (EU Base + SCCs)
**Cost**: $200-350/month
**Jurisdictions**: EU, UK, CH, JP, SG, CA, NZ (with SCCs)

**Strategy**: Single EU deployment + Standard Contractual Clauses for other jurisdictions

**Pros**:
- ✅ Lower cost than multi-region
- ✅ Serves most jurisdictions
- ✅ Simpler operations

**Cons**:
- ❌ Higher latency for APAC/Americas (150-300ms)
- ❌ Requires robust SCC framework ($10k legal)
- ❌ Some jurisdictions blocked (AU healthcare, BR initially)

---

## Critical Deadlines & Actions

### ⚠️ IMMEDIATE (Next 30 Days)

1. **Brazil ANPD SCCs** 🚨 OVERDUE
   - **Deadline**: August 23, 2025 (GRACE PERIOD ENDED)
   - **Action**: Implement ANPD-approved SCCs OR block Brazil
   - **Cost**: $100/month + $10k one-time legal
   - **Status**: **CRITICAL - Service currently non-compliant if serving Brazil**

2. **Legal Review of Privacy Policies**
   - **Action**: Engage privacy lawyer for EU, Canada, Brazil policies
   - **Cost**: $5,000-15,000
   - **Timeline**: 2-4 weeks

3. **Deploy EU-Strict Pattern (MVP)**
   - **Action**: Configure Fly.io for EU-only deployment
   - **Cost**: $150-200/month
   - **Timeline**: 1 week

---

### 📅 SHORT-TERM (3-6 Months)

4. **UK Adequacy Decision Monitoring** 🇬🇧
   - **Deadline**: June 2025 (adequacy expires)
   - **Action**: Monitor EC announcements; prepare SCCs as contingency
   - **Cost**: $50/month (if SCCs needed)

5. **APEC CBPR Certification** (Japan)
   - **Action**: Apply for APEC Cross-Border Privacy Rules certification
   - **Benefit**: Simplifies Japan compliance
   - **Timeline**: 6-12 months

6. **Compliance Monitoring Dashboard**
   - **Action**: Implement Phase 5 queries in production
   - **Tools**: PostgreSQL + Grafana/Prometheus
   - **Cost**: Included in hosting

---

### 🔄 ONGOING

7. **Quarterly Compliance Reviews**
   - Review privacy policies for regulatory changes
   - Audit data residency compliance
   - Update SCCs if templates change

8. **Annual Security Audits**
   - Third-party penetration testing
   - GDPR Article 32 compliance verification
   - Encryption standards review (state-of-the-art)

9. **Breach Notification Drills**
   - **Frequency**: Every 6 months
   - **Purpose**: Test 72-hour notification procedures
   - **Participants**: DPO, DevOps, Legal, Support

---

## Risk Assessment

| Risk Category | Risk Level | Mitigation | Residual Risk |
|---------------|------------|------------|---------------|
| **EU-US Data Transfers** | 🔴 CRITICAL | EU-only infrastructure | 🟢 LOW |
| **Brazil ANPD SCCs** | 🔴 CRITICAL | Implement SCCs OR block | 🟡 MEDIUM (until implemented) |
| **Australia Healthcare** | 🔴 CRITICAL | ToS prohibition | 🟢 LOW |
| **UK Adequacy Lapse (June 2025)** | 🟡 MEDIUM | Contingency SCCs prepared | 🟢 LOW |
| **Encryption Key Compromise** | 🟡 MEDIUM | Key rotation, HSM storage | 🟡 MEDIUM |
| **Breach Notification Delay** | 🟡 MEDIUM | Monitoring + procedures | 🟡 MEDIUM |
| **Storage Limitation** | 🟢 LOW | Automated deletion | 🟢 LOW |
| **Logging Sensitive Data** | 🟢 LOW | Sanitization middleware | 🟢 LOW |

---

## Budget Estimate

### MVP (EU-Strict Pattern)
| Item | Monthly Cost | One-Time Cost |
|------|--------------|---------------|
| Fly.io EU deployment (3 machines) | $150 | - |
| Upstash Redis EU | $50 | - |
| Legal review (amortized) | $50 | $5,000 |
| Monitoring/logging | $30 | - |
| **TOTAL** | **$280/month** | **$5,000** |

### Full Multi-Jurisdiction (Year 1)
| Item | Monthly Cost | One-Time Cost |
|------|--------------|---------------|
| EU Cluster | $200 | - |
| APAC Cluster | $200 | - |
| Americas Cluster | $150 | - |
| Caddy routing layer | $0 | - |
| Brazil ANPD SCCs compliance | $100 | $10,000 |
| Japan APEC CBPR certification | $50 | $3,000 |
| Legal review (multi-jurisdiction) | $100 | $15,000 |
| **TOTAL** | **$800/month** | **$28,000** |

---

## Implementation Roadmap

### Month 1-2: Foundation
- [ ] Legal review of EU, Canada privacy policies
- [ ] Deploy EU-strict pattern to Fly.io
- [ ] Implement GDPR-compliant logging
- [ ] Set up compliance monitoring queries
- [ ] Create breach notification procedures
- [ ] **Decision**: Brazil ANPD SCCs OR block Brazil users

### Month 3-4: Expansion Preparation
- [ ] Monitor UK adequacy decision renewal (June 2025)
- [ ] Prepare Japan APEC CBPR application
- [ ] Implement geo-routing prototype (Caddy)
- [ ] Draft Australia ToS healthcare prohibition
- [ ] Test multi-region deployment in staging

### Month 5-6: Scale (If Needed)
- [ ] Deploy APAC cluster (if traffic justifies)
- [ ] Implement Brazil ANPD SCCs (if market justifies)
- [ ] Launch Japan with APEC CBPR
- [ ] Quarterly compliance audit
- [ ] First breach notification drill

---

## Key Contacts

### Regulatory Authorities

**EU**: European Data Protection Board (EDPB)
- Website: https://edpb.europa.eu/

**UK**: Information Commissioner's Office (ICO)
- Website: https://ico.org.uk/
- Phone: 0303 123 1113

**Canada**: Office of the Privacy Commissioner
- Website: https://www.priv.gc.ca/
- Phone: 1-800-282-1376

**Brazil**: ANPD (Autoridade Nacional de Proteção de Dados)
- Website: https://www.gov.br/anpd/

**Australia**: OAIC (Office of the Australian Information Commissioner)
- Website: https://www.oaic.gov.au/
- Phone: 1300 363 992

**Japan**: Personal Information Protection Commission (PPC)
- Website: https://www.ppc.go.jp/en/

---

## Files Generated

1. **phase1-eu-legal-requirements.md** - Legal requirement extraction
2. **phase2-eu-technical-implementation.md** - Technical configurations
3. **phase3-jurisdiction-conflicts.md** - Conflict detection + SQL
4. **phase4-architecture-decision-records.md** - ADRs for conflicts
5. **phase5-monitoring-compliance-queries.md** - Monitoring queries
6. **phase6-customer-disclosure-requirements.md** - Privacy policies + UI
7. **unified-compliance-data.json** - Programmatic data
8. **README.md** - This summary document

---

## Sources & References

All legal requirements include citations to actual regulations and enforcement actions. Key sources:

- **GDPR Enforcement Tracker**: https://www.enforcementtracker.com/
- **CMS Law GDPR Report 2024/2025**: Fines and statistics
- **Official GDPR Text**: https://gdpr-info.eu/
- **Canada PIPEDA Guidelines**: https://www.priv.gc.ca/
- **Brazil ANPD Resolution 19/2024**: SCCs for international transfers
- **Fly.io Documentation**: https://fly.io/docs/reference/regions/
- **Northflank Cloud Providers**: https://northflank.com/cloud/

---

## Validation Rules Applied

✅ Every legal requirement includes real fine/enforcement action or marked "unenforced"
✅ Every technical control includes actual config code (not descriptions)
✅ Every conflict demonstrable with specific scenario
✅ No generic statements like "ensure compliance"
✅ Data not found marked as "RESEARCH_FAILED" (none in this research)

---

## Next Steps

1. **Review this research** with legal counsel
2. **Choose deployment pattern** (recommend EU-Strict for MVP)
3. **Implement Phase 2 configurations** in staging
4. **Deploy Phase 5 monitoring** in production
5. **Legal review** of Phase 6 privacy policies
6. **Decide on Brazil**: ANPD SCCs or block until implemented
7. **Monitor UK adequacy** (June 2025 deadline)

---

## Questions or Updates

For questions about this research, contact:
- **Project**: OneTimeSecret Compliance Research
- **Date**: November 23, 2025
- **Researcher**: Claude (Anthropic)

**Maintenance**: This research should be reviewed quarterly and updated when:
- New regulations come into effect
- Adequacy decisions change (e.g., UK June 2025)
- Major enforcement actions occur
- New jurisdictions targeted for expansion
