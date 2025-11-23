# PHASE 1: Legal Requirement Extraction - European Union

## Overview
This document extracts specific legal requirements from EU data protection regulations applicable to OneTimeSecret's secret-sharing service.

## Legal Requirements CSV

| Jurisdiction | Law/Regulation | Article/Section | Requirement Text | Applies To | Trigger | Enforcement Date | Latest Enforcement Action |
|--------------|----------------|-----------------|------------------|------------|---------|------------------|---------------------------|
| European Union | GDPR (Regulation 2016/679) | Article 44 | "Any transfer of personal data which are undergoing processing or are intended for processing after transfer to a third country or to an international organisation shall take place only if the conditions laid down in this Chapter are complied with by the controller and processor" | both | all-data | 2018-05-25 | Meta Platforms Ireland Ltd - €1.2 billion (May 2023) - Irish DPC Case for unlawful data transfers to US |
| European Union | GDPR (Regulation 2016/679) | Article 45(1) | "A transfer of personal data to a third country or an international organisation may take place where the Commission has decided that the third country ensures an adequate level of protection" | both | all-data | 2018-05-25 | Meta Platforms Ireland Ltd - €1.2 billion (May 2023) |
| European Union | GDPR (Regulation 2016/679) | Article 46(1) | "In the absence of a decision pursuant to Article 45(3), a controller or processor may transfer personal data to a third country only if the controller or processor has provided appropriate safeguards" | both | all-data | 2018-05-25 | Uber - €290 million (2024) - Dutch DPA for transferring driver data to US without adequate safeguards |
| European Union | GDPR (Regulation 2016/679) | Article 5(1)(e) | "Personal data shall be kept in a form which permits identification of data subjects for no longer than is necessary for the purposes for which the personal data are processed (storage limitation)" | data-at-rest | all-data | 2018-05-25 | Multiple enforcement actions - specific retention period violations |
| European Union | GDPR (Regulation 2016/679) | Article 5(1)(c) | "Personal data shall be adequate, relevant and limited to what is necessary in relation to the purposes for which they are processed (data minimisation)" | both | all-data | 2018-05-25 | LinkedIn - €310 million (October 2024) - Irish DPC for unlawful processing beyond necessary purposes |
| European Union | GDPR (Regulation 2016/679) | Article 17(1) | "The data subject shall have the right to obtain from the controller the erasure of personal data concerning him or her without undue delay and the controller shall have the obligation to erase personal data without undue delay" | data-at-rest | all-data | 2018-05-25 | Multiple enforcement actions - 30-day response requirement |
| European Union | GDPR (Regulation 2016/679) | Article 32(1)(a) | "Taking into account the state of the art and the costs of implementation and the nature, scope, context and purposes of processing, implement appropriate technical and organisational measures, including the pseudonymisation and encryption of personal data" | both | all-data | 2018-05-25 | Meta - €251 million (2024) - Irish DPC for 2018 data breach exposing unencrypted data |
| European Union | GDPR (Regulation 2016/679) | Article 32(1)(b) | "The ability to ensure the ongoing confidentiality, integrity, availability and resilience of processing systems and services" | both | all-data | 2018-05-25 | Multiple enforcement actions for inadequate security |
| European Union | GDPR (Regulation 2016/679) | Article 33(1) | "In the case of a personal data breach, the controller shall without undue delay and, where feasible, not later than 72 hours after having become aware of it, notify the personal data breach to the supervisory authority" | both | all-data | 2018-05-25 | Multiple enforcement actions for late breach notification |
| European Union | GDPR (Regulation 2016/679) | Article 30(1) | "Each controller and, where applicable, the controller's representative, shall maintain a record of processing activities under its responsibility" | both | all-data | 2018-05-25 | Fines up to €10 million or 2% of annual turnover for non-compliance |
| European Union | ePrivacy Directive 2002/58/EC | Article 5(1) | "Member States shall ensure the confidentiality of communications and the related traffic data by means of a national law. They shall prohibit listening, tapping, storage or other kinds of interception or surveillance of communications" | both | all-data | 2002-07-31 (Amended 2009) | Various national implementations - enforcement varies by member state |
| European Union | ePrivacy Directive 2002/58/EC | Article 5(3) | "The storing of information, or the gaining of access to information already stored, in the terminal equipment of a subscriber or user is only allowed on condition that the subscriber or user concerned has given consent" | data-at-rest | all-data | 2002-07-31 (Amended 2009) | Multiple cookie consent violations - enforcement under national laws |
| European Union | ePrivacy Directive 2002/58/EC | Article 4(1) | "The provider of a publicly available electronic communications service must take appropriate technical and organizational measures to safeguard security of its services. If necessary, these measures may be taken in conjunction with the provider of the public communications network" | both | all-data | 2002-07-31 (Amended 2009) | National enforcement - varies by member state |
| European Union | GDPR (Regulation 2016/679) | Article 6(1) | "Processing shall be lawful only if and to the extent that at least one of the following applies: (a) the data subject has given consent; (b) processing is necessary for the performance of a contract; (c) processing is necessary for compliance with a legal obligation" | both | all-data | 2018-05-25 | TikTok - €530 million (May 2025 projected) - Irish DPC for processing without lawful basis |
| European Union | GDPR (Regulation 2016/679) | Article 25(1) | "The controller shall implement appropriate technical and organisational measures designed to implement data-protection principles, such as data minimisation, in an effective manner (data protection by design)" | both | all-data | 2018-05-25 | Multiple enforcement actions for lack of privacy by design |

## Key Findings for OneTimeSecret

### Critical Requirements for Secret-Sharing Service:

1. **Data Residency (Articles 44-46)**
   - Secrets from EU users MUST remain in EU unless adequate safeguards (SCCs) are in place
   - Current adequacy decisions: UK, Switzerland, Japan (partial), New Zealand (partial)
   - NO adequacy decision for: US (post-Schrems II, awaiting DPF validation), Canada, Australia, Brazil, Singapore

2. **Encryption (Article 32)**
   - Encryption is EXPECTED (not optional) for a service handling secrets
   - Required for both data at rest and data in transit
   - Must be "state of the art" - outdated encryption algorithms may constitute violation

3. **Storage Limitation (Article 5(1)(e))**
   - OneTimeSecret's time-limited storage model ALIGNS with GDPR
   - Must demonstrate that retention periods are technically enforced
   - Automatic deletion upon expiry is REQUIRED, not optional

4. **Data Minimization (Article 5(1)(c))**
   - Collect ONLY what's necessary (secret content, expiry, view count)
   - IP address logging may be questioned unless justified for security
   - Metadata collection must be minimized

5. **Breach Notification (Article 33)**
   - 72-hour notification to supervisory authority
   - If encryption keys are compromised, ALL secrets are considered breached
   - Processor (hosting provider) must notify OneTimeSecret "without undue delay"

6. **Right to Erasure (Article 17)**
   - Must respond within 30 days
   - For expired secrets, automatic deletion satisfies this
   - For non-expired secrets, manual deletion mechanism required

7. **Records of Processing (Article 30)**
   - Must maintain documentation of all data processing activities
   - Must be available to supervisory authority on request
   - Electronic format acceptable (can be automated)

## Enforcement Trends (2024-2025)

### High-Risk Areas:
1. **International Data Transfers**: €1.2 billion (Meta), €290 million (Uber), €530 million (TikTok projected)
2. **Inadequate Security**: €251 million (Meta breach)
3. **Unlawful Processing**: €310 million (LinkedIn)
4. **Lack of Consent/Legal Basis**: €30.5 million (Clearview AI)

### Key Regulators:
- **Ireland DPC**: Most aggressive enforcer (€3.5 billion total fines)
- **Dutch DPA**: Focus on international transfers
- **French CNIL**: Focus on consent and cookies

## OneTimeSecret Risk Assessment

| Risk Category | Risk Level | Rationale |
|---------------|------------|-----------|
| International Transfers | **HIGH** | Multi-region deployment requires careful SCCs or adequacy mapping |
| Encryption | **MEDIUM** | Already implementing encryption, but must ensure "state of the art" |
| Storage Limitation | **LOW** | Business model inherently compliant (time-limited secrets) |
| Data Minimization | **MEDIUM** | Need to review metadata collection (IPs, user agents, etc.) |
| Breach Notification | **HIGH** | Encryption key compromise = catastrophic breach |
| Right to Erasure | **LOW** | Auto-deletion handles most cases |

## Next Steps for Phase 2
- Map each requirement to specific Fly.io and Northflank configurations
- Determine which data can be processed where
- Identify logging restrictions
- Define backup residency requirements
