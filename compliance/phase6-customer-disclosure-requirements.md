# PHASE 6: Customer Disclosure Requirements

## Overview
This document contains required privacy policy clauses, UI notifications, consent checkboxes, data deletion timeframes, and breach notification templates for each jurisdiction.

---

## 1. European Union (GDPR)

### 1.1 Required Privacy Policy Clauses

```markdown
# Privacy Policy for EU/EEA Users

**Effective Date**: [DATE]
**Data Controller**: OneTimeSecret Inc., [Address]
**Data Protection Officer**: [Email]
**Supervisory Authority**: [Relevant EU DPA based on controller location]

## 1. Legal Basis for Processing (Article 6 GDPR)

We process your personal data based on the following legal grounds:

- **Consent (Article 6(1)(a))**: When you explicitly agree to share a secret
- **Legitimate Interest (Article 6(1)(f))**: For security, fraud prevention, and service improvement

## 2. Data We Collect

### 2.1 Data Categories (Article 13 GDPR)
- **Secret Content**: Encrypted text you choose to share (encrypted at rest with AES-256)
- **Technical Data**: IP address, timestamp, browser type, device information
- **Usage Data**: Number of views, expiry settings, access logs (sanitized)

### 2.2 Purpose Limitation (Article 5(1)(b) GDPR)
We collect this data ONLY for:
- Providing the secret-sharing service
- Security and fraud prevention
- Compliance with legal obligations
- Service improvement (anonymized analytics)

## 3. Data Retention (Article 5(1)(e) GDPR)

**Your secrets are automatically deleted**:
- Upon expiry time you set (maximum 30 days)
- After maximum number of views reached
- Immediately upon your deletion request

**Access logs retained**: 90 days (security requirement)
**Backups retained**: 5 days (disaster recovery)

## 4. Data Location and Transfers (Articles 44-46 GDPR)

### 4.1 Data Residency
Your data is processed EXCLUSIVELY in the European Economic Area:
- **Primary**: Amsterdam, Netherlands (Fly.io region: ams)
- **Backup**: Frankfurt, Germany (Fly.io region: fra)
- **Backup**: Paris, France (Fly.io region: cdg)

### 4.2 Third-Country Transfers
We do NOT transfer your data outside the EU/EEA, EXCEPT:
- **To adequacy decision countries** (UK, Switzerland, Japan, New Zealand) with your consent
- **With Standard Contractual Clauses** approved by the European Commission

### 4.3 Processors (Article 28 GDPR)
We use the following processors:
- **Fly.io**: Infrastructure hosting (EU regions only) - [Data Processing Agreement]
- **Upstash**: Redis caching (EU regions only) - [Data Processing Agreement]

All processors have signed GDPR-compliant Data Processing Agreements.

## 5. Your Rights (Chapter III GDPR)

You have the following rights:

### 5.1 Right of Access (Article 15)
Request a copy of your personal data we hold.
**How to exercise**: Email [dpo@onetimesecret.com]
**Response time**: Within 30 days

### 5.2 Right to Erasure / "Right to be Forgotten" (Article 17)
Request deletion of your personal data.
**How to exercise**: Email [dpo@onetimesecret.com] or use the deletion feature in-app
**Response time**: Within 30 days (usually immediate for active secrets)

### 5.3 Right to Data Portability (Article 20)
Receive your data in a structured, machine-readable format (JSON).
**How to exercise**: Email [dpo@onetimesecret.com]
**Response time**: Within 30 days

### 5.4 Right to Object (Article 21)
Object to processing based on legitimate interest.
**How to exercise**: Email [dpo@onetimesecret.com]
**Response time**: Within 30 days

### 5.5 Right to Lodge a Complaint (Article 77)
You may lodge a complaint with your national Data Protection Authority:
- **List of EU DPAs**: https://edpb.europa.eu/about-edpb/board/members_en

## 6. Security Measures (Article 32 GDPR)

We implement state-of-the-art security:
- **Encryption at Rest**: AES-256 bit encryption (SQLCipher)
- **Encryption in Transit**: TLS 1.3 only (no older protocols)
- **Access Control**: Role-based access with audit logging
- **Monitoring**: 24/7 intrusion detection
- **Regular Audits**: Annual third-party security audits

## 7. Data Breach Notification (Articles 33-34 GDPR)

In the event of a data breach that poses a risk to your rights and freedoms:
- **Authority Notification**: We will notify the supervisory authority within 72 hours
- **Individual Notification**: We will notify you without undue delay if high risk exists
- **Notification Contents**: Nature of breach, likely consequences, measures taken

## 8. Automated Decision-Making (Article 22 GDPR)

We do NOT use automated decision-making or profiling.

## 9. Data Protection by Design and Default (Article 25 GDPR)

Our service is designed with privacy as the default:
- **Encryption enabled by default** (you cannot opt out)
- **Minimal data collection** (we don't require accounts for basic use)
- **Automatic deletion** (secrets expire automatically)
- **No tracking cookies** (only essential session cookies)

## 10. Children's Data (Article 8 GDPR)

Our service is not directed at children under 16. We do not knowingly collect data from children.

## 11. Contact Information

**Data Controller**: OneTimeSecret Inc.
**Data Protection Officer**: [Name], [Email]
**Supervisory Authority**: [Relevant DPA]

**Last Updated**: [DATE]
```

### 1.2 Required UI Notifications

#### Cookie Consent Banner (ePrivacy Directive Article 5(3))
```html
<!-- EU Cookie Consent (required by ePrivacy Directive) -->
<div class="gdpr-cookie-banner" id="cookie-consent">
  <div class="cookie-content">
    <h3>🍪 Cookie Consent</h3>
    <p>
      We use essential cookies to provide our service. We do NOT use
      tracking, advertising, or analytics cookies.
    </p>

    <details>
      <summary>What cookies we use</summary>
      <ul>
        <li><strong>session_id</strong>: Essential for service functionality (expires: 24 hours)</li>
        <li><strong>csrf_token</strong>: Essential for security (expires: 24 hours)</li>
        <li><strong>consent_given</strong>: Records your cookie consent (expires: 1 year)</li>
      </ul>
      <p>No personal data is collected via cookies except session management.</p>
    </details>

    <div class="cookie-actions">
      <button class="btn-accept" onclick="acceptCookies()">
        Accept Essential Cookies
      </button>
      <a href="/privacy-policy#cookies" class="link-learn-more">
        Learn More
      </a>
    </div>
  </div>
</div>

<script>
function acceptCookies() {
  // Set consent cookie (1 year)
  document.cookie = "consent_given=true; max-age=31536000; path=/; secure; samesite=strict";
  document.getElementById('cookie-consent').style.display = 'none';

  // Log consent (GDPR Article 7 - proof of consent)
  fetch('/api/consent', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      consent_type: 'cookies',
      consent_given: true,
      timestamp: new Date().toISOString()
    })
  });
}

// Show banner if consent not given
if (!document.cookie.includes('consent_given=true')) {
  document.getElementById('cookie-consent').style.display = 'block';
}
</script>
```

#### Data Processing Notice (Before Secret Creation)
```html
<!-- GDPR Article 13 - Information to be provided when collecting data -->
<div class="gdpr-notice" id="data-processing-notice">
  <h4>ℹ️  How We Handle Your Data</h4>
  <p>
    <strong>Your data stays in the EU.</strong> We process your secret in
    Amsterdam (NL), Frankfurt (DE), or Paris (FR). Your data is encrypted
    with AES-256 and automatically deleted after expiry.
  </p>

  <ul>
    <li>✅ Encrypted at rest and in transit</li>
    <li>✅ Never transferred outside EU/EEA</li>
    <li>✅ Auto-deleted upon expiry or max views</li>
    <li>✅ No user account required</li>
  </ul>

  <p class="small-text">
    By clicking "Share Secret", you consent to processing under GDPR Article 6(1)(a).
    You can request deletion anytime at <a href="mailto:dpo@onetimesecret.com">dpo@onetimesecret.com</a>.
  </p>

  <a href="/privacy-policy" class="link-privacy">Full Privacy Policy</a>
</div>
```

### 1.3 Required Consent Checkboxes

```html
<!-- GDPR Article 7 - Conditions for consent -->
<form id="create-secret-form">
  <textarea name="secret" placeholder="Enter your secret..." required></textarea>

  <!-- Optional: Cross-border transfer consent (if applicable) -->
  <div class="consent-checkbox" id="cross-border-consent" style="display: none;">
    <label>
      <input type="checkbox" name="consent_cross_border" id="consent-cross-border" required />
      <span>
        I consent to my data being processed in [COUNTRY] (outside EU/EEA).
        I understand that data protection laws may differ. I can withdraw this
        consent at any time. <a href="/privacy-policy#transfers" target="_blank">Learn more</a>
      </span>
    </label>
  </div>

  <!-- Consent for analytics (optional processing) -->
  <div class="consent-checkbox">
    <label>
      <input type="checkbox" name="consent_analytics" id="consent-analytics" />
      <span>
        I consent to anonymized usage analytics to improve the service
        (optional - service works without this).
      </span>
    </label>
  </div>

  <button type="submit">Share Secret</button>

  <p class="consent-notice small-text">
    By clicking "Share Secret", you consent to processing as described in our
    <a href="/privacy-policy">Privacy Policy</a>. You can withdraw consent anytime.
  </p>
</form>
```

### 1.4 Required Data Deletion Timeframes

| Data Type | Retention Period | Legal Basis | Deletion Method |
|-----------|-----------------|-------------|-----------------|
| **Secret Content** | Until expiry (max 30 days) or max views | GDPR Article 5(1)(e) - Storage Limitation | Automated deletion via cron; Secure overwrite |
| **Access Logs** | 90 days | GDPR Article 32 - Security; Legitimate Interest | Automated deletion; Rolling deletion |
| **User IP Address** | Same as secret (max 30 days) | GDPR Article 6(1)(f) - Legitimate Interest (fraud prevention) | Deleted with secret |
| **Backups** | 5 days | GDPR Article 32 - Availability and Resilience | Automated snapshot expiry |
| **Audit Logs (Security Events)** | 2 years | GDPR Article 32 - Security | Manual review then deletion |
| **Data Subject Requests** | 3 years | Legal obligation (evidence of compliance) | After retention period, securely deleted |

### 1.5 Breach Notification Template (GDPR Articles 33-34)

#### To Supervisory Authority (Article 33)
```markdown
**Subject**: Data Breach Notification - OneTimeSecret Inc. (Controller ID: [ID])

**To**: [Relevant DPA Email]
**From**: [DPO Email]
**Date**: [DATE]
**Time of Notification**: [TIMESTAMP]

---

## Personal Data Breach Notification (GDPR Article 33)

### 1. Breach Details

**Controller**: OneTimeSecret Inc., [Address]
**DPO Contact**: [Name], [Email], [Phone]

**Breach Detected**: [DATE] at [TIME] ([TIMEZONE])
**Notification Time**: [HOURS] hours after detection (within 72-hour requirement)

### 2. Nature of the Breach

**Breach Type**: [Confidentiality Breach / Availability Breach / Integrity Breach]

**Description**:
[Detailed description of what happened, e.g., "Unauthorized access to encrypted
database via compromised credentials. Attacker accessed [X] records between
[TIME] and [TIME]."]

**Root Cause**: [E.g., "Phishing attack led to credential compromise"]

### 3. Categories and Approximate Number of Data Subjects and Records

**Data Subjects Affected**:
- Total individuals: [NUMBER]
- By country: EU: [NUMBER], UK: [NUMBER], Other: [NUMBER]

**Personal Data Records Affected**:
- Total records: [NUMBER]
- Secret content (encrypted): [NUMBER]
- IP addresses: [NUMBER]
- Access logs: [NUMBER]

**Data Categories**:
- ✅ Secret content (ENCRYPTED with AES-256 - keys NOT compromised)
- ✅ IP addresses
- ✅ Timestamps
- ❌ No names, emails, or payment data (not collected)

### 4. Data Protection Officer Contact

**Name**: [DPO Name]
**Email**: [Email]
**Phone**: [Phone]
**Available**: 24/7 for this incident

### 5. Likely Consequences

**Risk Assessment**:
- **Confidentiality Impact**: LOW (data encrypted; keys not compromised)
- **Availability Impact**: MEDIUM (service disrupted for [X] hours)
- **Integrity Impact**: LOW (no data modification detected)

**Affected Individuals**:
- **Financial Risk**: None (no payment data collected)
- **Identity Theft Risk**: Low (no personal identifiers collected)
- **Reputational Risk**: Medium (trust in service affected)

### 6. Measures Taken or Proposed

**Immediate Actions** (completed):
- [TIMESTAMP]: Breach detected via intrusion detection system
- [TIMESTAMP]: Affected systems isolated from network
- [TIMESTAMP]: Compromised credentials revoked
- [TIMESTAMP]: All active sessions terminated
- [TIMESTAMP]: Encryption keys rotated
- [TIMESTAMP]: Forensic investigation initiated

**Ongoing Actions**:
- Individual notification (Article 34 assessment in progress)
- Full forensic analysis
- Security patch deployment
- Third-party security audit

**Preventive Measures**:
- Multi-factor authentication (MFA) implementation
- Enhanced intrusion detection rules
- Quarterly penetration testing

### 7. Cross-Border Element

**Data Locations Affected**:
- Amsterdam (NL): [NUMBER] records
- Frankfurt (DE): [NUMBER] records
- Paris (FR): [NUMBER] records

**Other Supervisory Authorities**:
- [If applicable, list other DPAs being notified]

### 8. Follow-Up

We commit to providing updates on:
- **+24 hours**: Forensic analysis results
- **+48 hours**: Individual notification plan (if required)
- **+7 days**: Full incident report

**Contact for Questions**: [DPO Email], [Phone]

---

**Attachments**:
1. Forensic investigation logs (redacted)
2. Affected records list (encrypted)
3. Technical incident report
```

#### To Individuals (Article 34)
```markdown
**Subject**: Security Incident Notification - Your OneTimeSecret Data

**From**: [DPO Email]
**To**: [Affected Individual]
**Date**: [DATE]

---

Dear User,

We are writing to inform you of a security incident that may have affected your data.

## What Happened

On [DATE] at [TIME], we detected unauthorized access to our systems. The incident
was immediately contained, and all affected systems were secured.

## What Data Was Affected

The following data related to your use of OneTimeSecret may have been accessed:
- **Secret content**: ENCRYPTED (encryption keys were NOT compromised)
- **IP address**: [YOUR IP]
- **Timestamp**: When you created the secret
- **Access logs**: Record of when secret was viewed (sanitized)

**Good News**:
- ✅ Your secret content was encrypted with AES-256 and remains secure
- ✅ Encryption keys were NOT compromised
- ✅ We do not collect names, emails, or payment information

## Likely Consequences

**Risk to You**: **LOW**

The accessed data was encrypted and does not contain personal identifiers. We
assess the risk of harm to your rights and freedoms as LOW.

However, your IP address was exposed, which could theoretically be used to
identify your approximate location at the time of secret creation.

## What We've Done

- ✅ Isolated affected systems immediately
- ✅ Revoked compromised credentials
- ✅ Rotated all encryption keys
- ✅ Notified supervisory authority (within 72 hours as required)
- ✅ Engaged third-party security firm for forensic analysis

## What You Should Do

1. **If your secret contained sensitive information** and you're concerned:
   - Consider it potentially compromised (though still encrypted)
   - Take any necessary precautions (e.g., change passwords if password was shared)

2. **Monitor for suspicious activity** related to the secret content

3. **Contact us** if you have questions or concerns: [dpo@onetimesecret.com]

## Your Rights

Under GDPR, you have the right to:
- Request details about what data was affected
- Lodge a complaint with your Data Protection Authority:
  [Relevant DPA contact info]

## More Information

For more details, see our full incident report: [URL]

**Contact Us**:
- Email: [dpo@onetimesecret.com]
- Data Protection Officer: [Name]

We sincerely apologize for this incident and are taking all necessary steps to
prevent future occurrences.

Sincerely,
[DPO Name]
Data Protection Officer
OneTimeSecret Inc.
```

---

## 2. Canada (PIPEDA)

### 2.1 Required Privacy Policy Clauses

```markdown
# Privacy Policy for Canadian Users

**Effective Date**: [DATE]
**Organization**: OneTimeSecret Inc.
**Privacy Officer**: [Name], [Email]
**Jurisdiction**: Governed by Canada's Personal Information Protection and Electronic Documents Act (PIPEDA)

## 1. Accountability (PIPEDA Principle 1)

OneTimeSecret Inc. is responsible for personal information under our control.
Our Privacy Officer can be reached at [email].

## 2. Identifying Purposes (PIPEDA Principle 2)

We collect personal information for the following purposes:
- Providing the secret-sharing service
- Security and fraud prevention
- Compliance with legal obligations

## 3. Consent (PIPEDA Principle 3)

### 3.1 How We Obtain Consent
By using OneTimeSecret, you consent to:
- Collection of IP address and technical data
- Processing of secret content (encrypted)
- Cross-border data transfer (see Section 6)

### 3.2 Withdrawing Consent
You may withdraw consent at any time by:
- Deleting your secret (immediate)
- Emailing [privacy@onetimesecret.com]

Note: Withdrawing consent may prevent use of the service.

## 4. Limiting Collection (PIPEDA Principle 4)

We collect ONLY:
- Secret content (encrypted)
- IP address
- Timestamp
- Browser type

We do NOT collect:
- Names or email addresses (unless you choose to include in secret)
- Payment information
- Tracking cookies

## 5. Limiting Use, Disclosure, and Retention (PIPEDA Principles 5-6)

### 5.1 Use and Disclosure
Your personal information is used ONLY for the purposes identified.

We do NOT:
- Sell your data
- Share with third parties except processors (Fly.io, Upstash)
- Use for marketing

### 5.2 Retention
- **Secrets**: Automatically deleted after expiry (max 30 days) or max views
- **Logs**: Retained for 90 days (security requirement)
- **Backups**: Retained for 5 days

## 6. Cross-Border Data Transfers (PIPEDA Requirement)

### 6.1 Where Your Data is Processed

**IMPORTANT**: Under PIPEDA, we must inform you that your personal information
may be processed and stored in the following countries:

| Location | Purpose | Governing Law |
|----------|---------|---------------|
| **Canada** (Toronto) | Primary processing | Canadian law |
| **European Union** (Amsterdam, Frankfurt) | Infrastructure | EU GDPR |
| **United States** (Infrastructure provider: Fly.io) | Cloud infrastructure | US law (CLOUD Act applies) |

### 6.2 Foreign Government Access

**Critical Disclosure**: When your data is processed in the United States or
European Union, it may be accessible to foreign government authorities under
their laws:

- **US CLOUD Act**: US government may compel Fly.io to produce data, even
  if stored in Canada or EU
- **US FISA 702**: US intelligence agencies may access data of non-US persons
  under certain circumstances
- **EU GDPR Article 48**: EU law prohibits disclosure to foreign governments
  without Mutual Legal Assistance Treaty (MLAT)

### 6.3 Your Consent to Cross-Border Transfer

By using OneTimeSecret from Canada, you explicitly consent to:
1. Processing of your data in Canada, EU, and US
2. Potential access by foreign government authorities as described above
3. Protection measures we implement (encryption, access controls)

**You can withdraw this consent** by ceasing use of the service.

## 7. Safeguards (PIPEDA Principle 7)

We protect your personal information through:
- **Encryption**: AES-256 at rest, TLS 1.3 in transit
- **Access Control**: Limited personnel access with audit logging
- **Monitoring**: 24/7 intrusion detection
- **Agreements**: Data Processing Agreements with all processors

## 8. Openness (PIPEDA Principle 8)

This privacy policy is publicly available at [URL]. We will notify you of
material changes by posting an updated policy.

## 9. Individual Access (PIPEDA Principle 9)

You have the right to:
- Request access to your personal information
- Challenge the accuracy of your information
- Request correction or deletion

**How to exercise**: Email [privacy@onetimesecret.com]
**Response time**: Within 30 days

## 10. Challenging Compliance (PIPEDA Principle 10)

If you believe we are not complying with PIPEDA, you may:
1. Contact our Privacy Officer: [email]
2. File a complaint with the Office of the Privacy Commissioner of Canada:
   - Website: https://www.priv.gc.ca
   - Phone: 1-800-282-1376

**Last Updated**: [DATE]
```

### 2.2 Required UI Notifications

```html
<!-- PIPEDA Cross-Border Disclosure Notice -->
<div class="pipeda-notice" id="canada-cross-border-notice">
  <h4>🇨🇦 Notice to Canadian Users</h4>
  <p>
    <strong>Your data may be accessed by foreign authorities.</strong>
  </p>

  <p>
    Under Canadian law (PIPEDA), we must inform you that your data is processed in:
  </p>

  <ul>
    <li><strong>Canada</strong> (Toronto) - Primary processing</li>
    <li><strong>European Union</strong> (Amsterdam, Frankfurt) - Infrastructure</li>
    <li><strong>United States</strong> (Fly.io) - Cloud provider</li>
  </ul>

  <div class="warning-box">
    <strong>⚠️ US CLOUD Act Notice</strong>
    <p>
      Because our infrastructure provider (Fly.io) is a US company, US government
      authorities may compel access to your data under the CLOUD Act, even if
      your data is stored in Canada or the EU.
    </p>
  </div>

  <p>
    We protect your data with encryption (AES-256), but we cannot prevent lawful
    government access.
  </p>

  <details>
    <summary>What this means for you</summary>
    <ul>
      <li>Your secret is encrypted, but encryption keys are theoretically accessible</li>
      <li>Canadian law enforcement can request data via legal process</li>
      <li>US authorities can request data via CLOUD Act</li>
      <li>EU authorities can request data via MLAT</li>
    </ul>
  </details>

  <p class="small-text">
    By using OneTimeSecret, you consent to this cross-border processing.
    <a href="/privacy-policy#cross-border">Learn more</a>
  </p>
</div>
```

### 2.3 Required Consent Checkboxes

```html
<!-- PIPEDA-specific consent for cross-border transfer -->
<form id="create-secret-form-canada">
  <textarea name="secret" placeholder="Enter your secret..." required></textarea>

  <div class="consent-checkbox pipeda-consent">
    <label>
      <input type="checkbox" name="consent_pipeda_cross_border" required />
      <span>
        <strong>I consent to cross-border data processing</strong>
        <br>
        I understand that my data may be processed in Canada, the EU, and the US,
        and may be accessible to foreign government authorities (including US
        authorities under the CLOUD Act).
        <a href="/privacy-policy-canada#cross-border" target="_blank">Read full disclosure</a>
      </span>
    </label>
  </div>

  <button type="submit">Share Secret</button>
</form>
```

---

## 3. Brazil (LGPD)

### 3.1 Required Privacy Policy Clauses

```markdown
# Política de Privacidade para Usuários Brasileiros
# Privacy Policy for Brazilian Users

**Data de Vigência / Effective Date**: [DATE]
**Controlador / Controller**: OneTimeSecret Inc.
**Encarregado de Dados / DPO**: [Name], [Email]
**Lei Aplicável / Applicable Law**: Lei Geral de Proteção de Dados (LGPD) - Lei nº 13.709/2018

## 1. Base Legal para Tratamento / Legal Basis for Processing (LGPD Article 7)

Processamos seus dados pessoais com base em:
We process your personal data based on:

- **Consentimento / Consent** (LGPD Art. 7, I): When you explicitly agree
- **Legítimo Interesse / Legitimate Interest** (LGPD Art. 7, IX): For security and fraud prevention

## 2. Dados Coletados / Data Collected (LGPD Article 9)

### 2.1 Categorias de Dados / Data Categories
- **Conteúdo do Segredo / Secret Content**: Encrypted text (criptografado com AES-256)
- **Endereço IP / IP Address**: For security and fraud prevention
- **Dados Técnicos / Technical Data**: Timestamp, browser type, device info

### 2.2 Finalidade / Purpose
Coletamos dados APENAS para:
We collect data ONLY for:
- Fornecer o serviço de compartilhamento de segredos
- Providing the secret-sharing service
- Segurança e prevenção de fraudes
- Security and fraud prevention

## 3. Compartilhamento e Transferência Internacional / Sharing and International Transfer

### 3.1 Operadores / Processors (LGPD Article 5, VII)
Compartilhamos dados com:
We share data with:
- **Fly.io**: Infraestrutura de hospedagem / Hosting infrastructure (US/EU)
- **Upstash**: Cache Redis / Redis caching (EU)

**Contratos / Agreements**: Todos os operadores assinaram as Cláusulas Contratuais Padrão (SCCs) aprovadas pela ANPD.
All processors have signed ANPD-approved Standard Contractual Clauses (SCCs).

### 3.2 Transferência Internacional / International Transfer (LGPD Article 33)

**IMPORTANTE / IMPORTANT**: Seus dados podem ser processados fora do Brasil:
Your data may be processed outside Brazil:

- **União Europeia / European Union** (Amsterdam, Frankfurt, Paris)
- **Estados Unidos / United States** (if using US infrastructure)

**Garantias / Safeguards**:
- ✅ Cláusulas Contratuais Padrão da ANPD / ANPD Standard Contractual Clauses
- ✅ Criptografia AES-256 / AES-256 Encryption
- ✅ Controle de acesso rigoroso / Strict access control

**Conformidade ANPD / ANPD Compliance**:
Implementamos a Resolução CD/ANPD nº 19/2024 (vigente desde 23/08/2025).
We implement ANPD Resolution CD/ANPD No. 19/2024 (effective since 08/23/2025).

## 4. Retenção de Dados / Data Retention (LGPD Article 15)

**Seus segredos são excluídos automaticamente:**
Your secrets are automatically deleted:
- Após o tempo de expiração (máximo 30 dias)
- After expiry time (maximum 30 days)
- Após o número máximo de visualizações
- After maximum number of views
- Imediatamente após sua solicitação de exclusão
- Immediately upon your deletion request

## 5. Seus Direitos / Your Rights (LGPD Chapter III)

Você tem os seguintes direitos:
You have the following rights:

### 5.1 Confirmação e Acesso / Confirmation and Access (LGPD Article 18, I-II)
Confirmar se tratamos seus dados e solicitar acesso.
Confirm whether we process your data and request access.

### 5.2 Correção / Correction (LGPD Article 18, III)
Solicitar correção de dados incompletos, inexatos ou desatualizados.
Request correction of incomplete, inaccurate, or outdated data.

### 5.3 Eliminação / Deletion (LGPD Article 18, VI)
Solicitar exclusão de dados tratados com seu consentimento.
Request deletion of data processed with your consent.

### 5.4 Portabilidade / Portability (LGPD Article 18, V)
Receber seus dados em formato estruturado (JSON).
Receive your data in structured format (JSON).

### 5.5 Revogação do Consentimento / Consent Withdrawal (LGPD Article 18, IX)
Revogar consentimento a qualquer momento.
Withdraw consent at any time.

**Como Exercer Seus Direitos / How to Exercise Your Rights**:
Email: [dpo@onetimesecret.com]
Prazo de Resposta / Response Time: 15 dias / 15 days (LGPD requirement)

### 5.6 Reclamar à ANPD / Complain to ANPD (LGPD Article 18, §1º)
Você pode registrar reclamação na Autoridade Nacional de Proteção de Dados (ANPD):
You may file a complaint with the Brazilian National Data Protection Authority (ANPD):
- Website: https://www.gov.br/anpd
- Email: [ANPD contact]

## 6. Segurança / Security (LGPD Article 46)

Implementamos medidas técnicas e organizacionais:
We implement technical and organizational measures:
- Criptografia em repouso e em trânsito / Encryption at rest and in transit
- Controle de acesso baseado em função / Role-based access control
- Monitoramento 24/7
- Auditorias regulares / Regular audits

## 7. Violação de Dados / Data Breach (LGPD Article 48)

Em caso de incidente de segurança:
In the event of a security incident:
- Notificaremos a ANPD em prazo razoável / We will notify ANPD in reasonable time
- Notificaremos você se houver risco / We will notify you if there is risk
- Tomaremos medidas para mitigar danos / We will take measures to mitigate harm

**Última Atualização / Last Updated**: [DATE]
```

### 3.2 Required Consent Checkboxes

```html
<!-- Brazil LGPD-specific consent -->
<form id="create-secret-form-brazil">
  <textarea name="secret" placeholder="Digite seu segredo..." required></textarea>

  <div class="consent-checkbox lgpd-consent">
    <label>
      <input type="checkbox" name="consent_lgpd_processing" required />
      <span>
        <strong>Eu consinto com o processamento de meus dados pessoais</strong>
        <br>
        <strong>I consent to the processing of my personal data</strong>
        <br>
        <small>
          Concordo que o OneTimeSecret processe meus dados conforme descrito na
          <a href="/privacy-policy-brazil" target="_blank">Política de Privacidade</a>,
          incluindo transferência internacional para a UE com Cláusulas Contratuais
          Padrão da ANPD (Resolução CD/ANPD nº 19/2024).
          <br>
          I agree that OneTimeSecret processes my data as described in the
          <a href="/privacy-policy-brazil" target="_blank">Privacy Policy</a>,
          including international transfer to EU with ANPD Standard Contractual
          Clauses (Resolution CD/ANPD No. 19/2024).
        </small>
      </span>
    </label>
  </div>

  <button type="submit">Compartilhar Segredo / Share Secret</button>

  <p class="consent-notice small-text">
    Você pode revogar este consentimento a qualquer momento.
    You can withdraw this consent at any time.
  </p>
</form>
```

---

## 4. Summary: Disclosure Requirements by Jurisdiction

| Jurisdiction | Privacy Policy Clauses | UI Notifications | Consent Checkboxes | Deletion Timeframe | Breach Notification |
|--------------|------------------------|------------------|--------------------|--------------------|---------------------|
| **EU (GDPR)** | Articles 13-14 info; Rights (15-22); DPO contact | Cookie banner; Data processing notice | Cross-border transfer (if applicable); Analytics (optional) | 30 days | 72 hours to DPA; Immediate to individuals if high risk |
| **Canada (PIPEDA)** | 10 Fair Information Principles; Cross-border disclosure | US CLOUD Act warning; Foreign access notice | Cross-border processing consent | 30 days (best practice) | Reasonable time to OPC; Immediate to individuals if real risk |
| **Brazil (LGPD)** | Bilingual (PT/EN); ANPD SCC reference; Rights (Art. 18) | International transfer notice (ANPD SCCs) | LGPD processing consent; International transfer consent | 15 days | Reasonable time to ANPD; Immediate if risk |
| **Australia** | APP 1 (privacy policy); APP 8 (cross-border); My Health Records prohibition | Healthcare data prohibited warning | Cross-border disclosure acknowledgment | 30 days (best practice) | Immediate if likely serious harm |
| **Japan (APPI)** | Cross-border transfer disclosure; Consent requirement | Consent for third-country transfer | Explicit opt-in for non-adequate countries | 30 days (best practice) | Without delay to PPC if significant harm |
| **New Zealand** | IPP 12 (comparable safeguards); Privacy principles | Cross-border disclosure risks | Authorization if no comparable safeguards | 20 working days | Immediate if risk of serious harm |
| **Singapore (PDPA)** | Comparable protection standard; Accountability | Data transfer notification | Consent for transfer (if no adequacy) | 30 days (best practice) | 3 calendar days to PDPC if significant harm |
| **Switzerland (FADP)** | Similar to GDPR; Swiss-US DPF reference | Cross-border transfer disclosure | Consent or adequate country | 30 days (best practice) | Immediate to FDPIC if high risk |
| **UK (UK GDPR)** | Same as EU GDPR; ICO as authority | Same as EU; UK adequacy status | Same as EU | 30 days | 72 hours to ICO; Immediate if high risk |

---

## 5. Implementation Checklist

### Pre-Launch
- [ ] Privacy policies drafted for each jurisdiction
- [ ] Legal review completed ($5,000-15,000)
- [ ] UI notifications implemented in codebase
- [ ] Consent checkboxes tested (A/B testing for acceptance rates)
- [ ] Breach notification templates prepared and tested (tabletop exercise)
- [ ] DPO/Privacy Officer designated and contact published

### Post-Launch Monitoring
- [ ] Monthly review of consent rates by jurisdiction
- [ ] Quarterly legal compliance audit
- [ ] Annual privacy policy update
- [ ] Breach notification drill (every 6 months)
- [ ] User rights request response time tracking (SLA: 30 days)

---

## Next Steps
- Finalize Phase 7: Expand research to remaining jurisdictions (detailed)
- Create unified JSON for programmatic consumption
- Implement disclosure requirements in application code
- Schedule legal review of all privacy policies
- Train support team on data subject rights requests
