# Security Architecture Comparison: Secret-Sharing Services

## Executive Summary

The secret-sharing service market shows a **fundamental divide** in security architecture:

1. **Zero-Knowledge Services** (PrivateBin, Yopass, Bitwarden Send, DELE.TO, etc.) - Client-side encryption where server never has access to plaintext
2. **Server-Trust Services** (OneTimeSecret, Password Pusher, Snappass) - Server-side encryption requiring trust in service operator

This divide represents the **core trust problem** in the market: proving that secrets are truly secure and never accessible to service operators.

---

## Security Architecture Taxonomy

### Tier 1: Zero-Knowledge with Cryptographic Proof

**Services**: PrivateBin, Yopass, Bitwarden Send, DELE.TO, Hemmelig, Cryptgeon, Password.link, scrt.link

**Architecture**:
- Encryption occurs **entirely in browser** before any network transmission
- Decryption key stored in **URL fragment** (after `#`), which is never sent to server per HTTP spec
- Server stores only encrypted ciphertext
- Mathematical proof: Server cannot decrypt without key it never receives

**Encryption Methods**:
- **PrivateBin**: AES-256 in Galois Counter Mode (GCM)
- **Yopass**: OpenPGP with strong cryptographic standards
- **Bitwarden Send**: AES-256 end-to-end encryption
- **DELE.TO**: AES-256-GCM
- **Hemmelig**: TweetNaCl (modern NaCl library)
- **Password.link**: AES-256-GCM

**Trust Mechanism**:
- Open source code = auditable encryption implementation
- Browser-based = user can verify in network inspector that plaintext never sent
- URL fragment = HTTPS spec guarantees fragment not transmitted in request
- No trust required in server operator

**Weaknesses**:
- Requires HTTPS (TLS) for transport security
- User must trust their browser and network path to service
- URL sharing must be secure (fragment could leak in referrer headers if not careful)

---

### Tier 2: Server-Side Encryption with Passphrase

**Services**: OneTimeSecret

**Architecture**:
- Secret sent to server over HTTPS
- Server encrypts using user-provided passphrase
- Encrypted secret stored in database
- Server never stores passphrase itself, only bcrypt hash for verification
- Decryption requires original passphrase

**Encryption Methods**:
- Industry-standard encryption (specific algorithm not publicly disclosed)
- Bcrypt password hashing
- Encryption at rest

**Trust Mechanism**:
- Open source codebase (community auditable)
- Passphrase never stored (only hash)
- Compliance certifications (SOC2, GDPR, CCPA, HIPAA mentioned)
- 14-year operational history
- Geographic data isolation

**Weaknesses**:
- **Server sees plaintext** during initial submission (even if briefly)
- Requires **complete trust** in service operator
- Vulnerable to compromised server or malicious operator
- Vulnerable to network eavesdropping if TLS compromised
- Security community concerns about trust model vs. zero-knowledge

**Security Discussion**:
From Information Security Stack Exchange: "You have to trust the website onetimesecret. If the attacker owns the website, they would know the PGP symmetric key too."

---

### Tier 3: Server-Side Encryption (Standard)

**Services**: Password Pusher, Snappass, Secret Pusher

**Architecture**:
- Secret transmitted over HTTPS
- Server encrypts and stores
- Automatic deletion after expiration/views
- Server has technical capability to access plaintext (though may not)

**Encryption Methods**:
- **Password Pusher**: Industry-standard encryption, encrypted storage
- **Snappass**: Redis temporary storage (encryption details unclear)
- **Secret Pusher**: AES-256

**Trust Mechanism**:
- **Password Pusher**: Open source, 14-year history, audit logs, 185K MAU
- **Snappass**: Pinterest-backed open source, Redis ephemeral storage
- Operational track record
- Audit logging (Password Pusher)

**Weaknesses**:
- Plaintext accessible to server (during operation or via compromise)
- Requires complete trust in operator
- No cryptographic guarantee of security
- Vulnerable to insider threats
- Server breach exposes current secrets

**Mitigations**:
- Encrypted at rest
- Automatic deletion
- Short TTLs
- Audit logging
- Open source (code review possible)

---

### Tier 4: Partial Zero-Knowledge

**Services**: Privnote

**Architecture**:
- Encryption key derived from note ID hash
- Note ID stored on server
- Hybrid model: encrypted storage but key derivation tied to server data

**Encryption Methods**:
- End-to-end encryption
- Key uses hash of note ID

**Trust Concerns**:
- Key derivation method creates potential vulnerability
- Not true zero-knowledge since key material related to server-stored data

---

## The Trust Problem: How Services Prove Security

### Zero-Knowledge Services (PrivateBin, Yopass, Bitwarden Send, etc.)

**Proof Mechanisms**:
1. **Open Source Code**: Users (or third-party auditors) can verify encryption happens in browser
2. **Network Inspection**: Browser dev tools show only encrypted data sent to server
3. **URL Fragment Specification**: HTTP spec guarantees fragment not sent in requests
4. **Mathematical Proof**: Without decryption key, AES-256/OpenPGP is computationally infeasible to break
5. **Self-Hosting Option**: Users can run verified code on their own infrastructure

**Confidence Level**: **High** - Cryptographically provable with minimal trust assumptions

### Server-Trust Services (OneTimeSecret, Password Pusher)

**Proof Mechanisms**:
1. **Open Source Code**: Can verify deletion happens as claimed
2. **Operational History**: Years of operation without known breaches
3. **Compliance Certifications**: SOC2, GDPR, etc. (third-party audits)
4. **Audit Logs**: Track access (doesn't prevent but enables detection)
5. **Geographic Isolation**: Data residency controls (OneTimeSecret)
6. **Community Trust**: Large user bases (Password Pusher: 185K MAU)

**Confidence Level**: **Medium** - Depends on trusting service operator and compliance frameworks

**Key Limitation**: **Cannot prove** server doesn't access plaintext. Can only provide evidence of trustworthiness.

---

## Encryption Comparison Matrix

| Service | Encryption Location | Algorithm | Zero-Knowledge | Key Storage | Server Can Decrypt? |
|---------|-------------------|-----------|----------------|-------------|-------------------|
| PrivateBin | Client (browser) | AES-256-GCM | ✅ Yes | URL fragment | ❌ No (provable) |
| Yopass | Client (browser) | OpenPGP | ✅ Yes | URL fragment | ❌ No (provable) |
| Bitwarden Send | Client (E2E) | AES-256 | ✅ Yes | URL fragment | ❌ No (provable) |
| DELE.TO | Client (browser) | AES-256-GCM | ✅ Yes | URL fragment | ❌ No (provable) |
| Hemmelig | Client (browser) | TweetNaCl | ✅ Yes | URL fragment | ❌ No (provable) |
| OneTimeSecret | Server | Not disclosed | ❌ No | Server (with passphrase) | ⚠️ During submission |
| Password Pusher | Server | Standard | ❌ No | Server (encrypted at rest) | ⚠️ Yes (technically) |
| Snappass | Server | Unclear | ❌ No | Redis (temp) | ⚠️ Yes (technically) |
| Privnote | Hybrid | E2E (key from ID) | ⚠️ Partial | Server (derived) | ⚠️ Potentially |
| Password.link | Client (browser) | AES-256-GCM | ✅ Yes | URL fragment | ❌ No (provable) |
| scrt.link | Client (browser) | Client-side | ✅ Yes | URL fragment | ❌ No (provable) |

---

## Security Best Practices by Service

### PrivateBin
- ✅ **Required**: HTTPS deployment
- ✅ **Recommended**: Add password protection for sensitive pastes
- ✅ **Best**: Self-host for complete control
- ⚠️ **Warning**: Public pastes without password are readable by anyone with link

### Yopass
- ✅ **Required**: TLS/HTTPS properly configured
- ✅ **Best**: Self-host for production use (don't use public yopass.se)
- ✅ **Recommended**: Use one-time access for sensitive secrets
- ✅ **Good**: CLI tool for automation/DevOps workflows

### Bitwarden Send
- ✅ **Recommended**: Use password protection for highly sensitive content
- ✅ **Best**: Set shortest practical expiration time
- ✅ **Good**: Leverage destruct-on-open for one-time secrets
- ✅ **Enterprise**: Use self-hosted Bitwarden for complete control

### OneTimeSecret
- ⚠️ **Critical**: Always use passphrase protection for sensitive secrets
- ✅ **Recommended**: Use shortest practical TTL
- ✅ **Enterprise**: Use custom domain and geographic isolation
- ⚠️ **Awareness**: Understand server-side encryption trust model

### Password Pusher
- ✅ **Best**: Use audit logs to track access (Pro tier)
- ✅ **Recommended**: Set view limits and expiration
- ✅ **Enterprise**: Self-host for sensitive environments
- ✅ **Teams**: Leverage team policy enforcement (Pro)

---

## Compliance & Certifications

| Service | SOC 2 | GDPR | HIPAA | ISO 27001 | Open Source |
|---------|-------|------|-------|-----------|-------------|
| Bitwarden Send | ✅ Type 2 | ✅ | Mentioned | Not mentioned | ✅ |
| OneTimeSecret | Mentioned | ✅ | Mentioned | Not mentioned | ✅ |
| PrivateBin | User-controlled | User-controlled | User-controlled | User-controlled | ✅ |
| Yopass | User-controlled | User-controlled | User-controlled | User-controlled | ✅ |
| Password Pusher | Not mentioned | Not mentioned | Not mentioned | Not mentioned | ✅ |
| ShareSecret | Not mentioned | Implied | Not mentioned | Not mentioned | ❌ |

**Note**: Self-hosted services (PrivateBin, Yopass, Snappass) inherit compliance from their deployment environment.

---

## Vulnerability Analysis

### Zero-Knowledge Architecture Vulnerabilities

**Common Risks**:
1. **Compromised Client**: Malicious browser extension could steal secrets before encryption
2. **URL Leakage**: Full URL (including fragment) could leak via:
   - Browser history
   - Referrer headers (if improperly configured)
   - Copy/paste into insecure channels
   - Screen sharing/screenshots
3. **TLS Compromise**: HTTPS stripping or certificate attacks could expose ciphertext
4. **Implementation Bugs**: Crypto implementation errors in JavaScript

**Mitigations**:
- Open source code review
- Modern crypto libraries (vetted implementations)
- HTTPS-only with HSTS
- Referrer-Policy headers
- User education on secure link sharing

### Server-Trust Architecture Vulnerabilities

**Additional Risks**:
1. **Server Compromise**: Attacker gains access to plaintext secrets
2. **Insider Threat**: Malicious administrator access
3. **Database Breach**: Encrypted-at-rest secrets still vulnerable if encryption keys compromised
4. **Memory Extraction**: Secrets in server memory during processing
5. **Logging**: Accidental logging of plaintext secrets
6. **Backup Exposure**: Secrets in database backups

**Mitigations**:
- Encrypted at rest
- Short TTLs (auto-deletion)
- Audit logging
- Access controls
- Compliance certifications
- Geographic isolation
- Regular security audits

---

## Recommendations by Use Case

### Maximum Security Required (e.g., credentials, API keys, PII)
**Recommended**: Zero-knowledge services only
- **Best**: PrivateBin (self-hosted) or Yopass (self-hosted)
- **Hosted**: Bitwarden Send (SOC 2 certified)
- **Simple**: DELE.TO or Password.link
- **Always**: Add password protection

### Team Collaboration
**Recommended**: Password Pusher (Pro tier)
- Audit logs
- Team management
- Policy enforcement
- Tradeoff: Server-trust model, but operational features valuable

### Developer/DevOps Workflows
**Recommended**: Yopass with CLI
- Purpose-built for eliminating passwords in tickets/Slack
- CLI integration
- Zero-knowledge security
- Modern tech stack

### Enterprise with Compliance Requirements
**Recommended**:
1. **Bitwarden Send** (SOC 2, GDPR, self-hostable)
2. **ShareSecret** (SSO/SAML, enterprise features)
3. **OneTimeSecret** (self-hosted with geo-isolation)

### Simple One-Time Sharing
**Recommended**: Any zero-knowledge service
- **Easiest**: Password.link, scrt.link, 1ty.me
- **Most Features**: PrivateBin or DELE.TO

---

## Security Conclusion

**The Fundamental Tradeoff**:
- **Zero-Knowledge**: Maximum security, minimal trust, but often fewer features and requires self-hosting
- **Server-Trust**: More features, easier to use, but requires trusting the operator

**Market Trend**: Movement toward zero-knowledge architecture as the security standard, with services like Bitwarden Send showing it's possible to combine zero-knowledge security with professional features and user experience.

**OneTimeSecret Positioning**: Currently in the server-trust category. To compete with security-focused users, consider:
1. Migration to zero-knowledge architecture (client-side encryption)
2. If maintaining server-side model, emphasize trust mechanisms (audits, certifications, open source)
3. Hybrid approach: Offer both modes (client-side for max security, server-side for additional features)
