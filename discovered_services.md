# PHASE 1 - Discovery: Secret-Sharing Services

## Executive Summary

**Services Discovered:** 17 services identified (exceeds 15 minimum requirement)
**Date:** 2025-11-23
**Critical Limitation:** WebFetch tool returned 403 errors for all direct URL fetches, preventing automated URL verification and screenshot capture
**Methodology:** Web search queries + manual research via search results

## Verification Limitations Encountered

### URL Verification Failure
**Attempted Method:** WebFetch tool to verify URLs return 200 status
**Result:** All WebFetch attempts returned HTTP 403 Forbidden errors
**Services Tested:**
- onetimesecret.com - 403 error
- password.link/en - 403 error
- pwpush.com - 403 error
- privatebin.info - 403 error

**Impact:** Cannot programmatically verify URLs return 200 status. URLs below are based on search results and cannot be confirmed operational without manual browser testing.

### Search Queries Used
```
1. "secure secret sharing services 2025"
2. "one time secret sharing tools alternatives"
3. "password sharing encrypted services"
4. "Password Pusher pwpush site"
5. "PrivateBin privatebin.net site"
6. "Privnote privnote.com"
7. "SafeNote safenote.co"
8. "vanish.so secret sharing"
9. "1ty.me one time secret"
10. "burn note burnnote.com"
11. "scrt.link secret sharing"
12. "send.vis.ee secret sharing"
13. "snappass secret sharing Netflix"
14. "secret.link secure message sharing"
15. "onetimesecret.com pricing plans cost 2025"
16. "password.link pricing plans free premium"
17. "pwpush.com password pusher pricing plans"
18. "privatebin pricing cost free"
19. "privnote.com pricing cost free"
20. "safenote.co pricing plans"
21. "yopass.se pricing cost"
22. "1ty.me pricing cost free"
23. "scrt.link pricing cost plans"
24. "bitwarden send pricing cost"
25. "snappass pinterest pricing cost"
26. "send.vis.ee firefox send pricing"
```

## Discovered Services (17 total)

### 1. OneTimeSecret
- **URL:** https://onetimesecret.com/
- **URL Status:** Could not verify (403 error on fetch)
- **Pricing Found:**
  - Free tier available
  - Paid plans with custom domains and dedicated infrastructure
  - Student/non-profit discounts mentioned
  - **EXACT PRICING NOT FOUND** - pricing page exists at /pricing but dollar amounts not in search results
- **Pricing Page:** https://onetimesecret.com/en/pricing/ (exists but not fetched)
- **Unique Feature:** Data center selection - "All users, both paid and free, can choose their preferred data center when creating an account"
- **Quote from Search:** "Share sensitive information securely with self-destructing links. The service is designed to help meet SOC2, GDPR, CCPA & HIPAA requirements for secure information handling."
- **Missing Data:** Exact dollar amounts for plans, specific TTL options

### 2. Password.link
- **URL:** https://password.link/en
- **URL Status:** Could not verify (403 error on fetch)
- **Pricing Found:**
  - **EXACT PRICE:** $99.99 one-time payment for lifetime Pro Plan access (originally $799)
  - 60-day money-back guarantee
  - Discount code: TRY30 for 30% off first two months (subscription plans)
  - NO FREE PLAN according to search results
- **Pricing Page:** https://password.link/en/p/plans
- **Unique Feature:** One-time payment lifetime access model (vs subscription-only competitors)
- **Quote from Search:** "Share passwords and other confidential data - along with files - with self-destructing one-time links. There are several settings which you can configure for each link like expiration time, password and CAPTCHA."
- **Missing Data:** Specific TTL options list, file size limits, actual test results

### 3. Password Pusher (pwpush.com)
- **URL:** https://pwpush.com/ (also https://eu.pwpush.com/, https://us.pwpush.com/)
- **URL Status:** Could not verify (403 error on fetch)
- **Pricing Found:**
  - Free tier available (open source self-hosted)
  - Premium tier (features: file uploads, teams, custom branding)
  - Pro tier (features: custom domains, full end-to-end branding)
  - **EXACT PRICING NOT FOUND** - pricing page exists but dollar amounts not in search results
  - "Moved on from launch pricing for all new subscribers"
- **Pricing Page:** https://eu.pwpush.com/pricing (exists but not fetched)
- **Unique Feature:** Audit logging - "Track and control what you've shared and see who has viewed it" - explicit tracking of "who, what and when with full audit logs"
- **Quote from Search:** "The first git commit to Password Pusher was on December 28, 2011. pwpush.com went live shortly thereafter. Password Pusher has securely delivered millions and millions of passwords in its 14 year history."
- **Missing Data:** Exact dollar amounts, specific TTL/expiration options

### 4. PrivateBin
- **URL:** https://privatebin.info/ (also https://privatebin.io/, https://privatebin.net/)
- **URL Status:** Could not verify (403 error on fetch)
- **Pricing Found:**
  - **EXACT PRICE:** $0 (completely free, open source)
  - Self-hosting costs depend on server expenses only
  - Public instances accept donations
- **Unique Feature:** Fork of ZeroBin with "zero knowledge" architecture - "server has zero knowledge of pasted data"
- **Quote from Search:** "A minimalist, open source online pastebin where the server has zero knowledge of stored data. Data is encrypted and decrypted in the browser using 256bit AES in Galois Counter mode."
- **Missing Data:** Specific TTL options, actual test of secret creation

### 5. Privnote
- **URL:** https://privnote.com/
- **URL Status:** Could not verify (403 error on fetch)
- **Pricing Found:**
  - **EXACT PRICE:** $0 (completely free)
  - Ad-supported
  - No premium tiers
- **Pricing Page:** None (free only)
- **Unique Feature:** Launched 2008, longest-running service in this list
- **Quote from Search:** "Launched in 2008, privnote.com employs technology that encrypts each message so that even Privnote itself cannot read its contents."
- **SECURITY WARNING:** "There are multiple phishing sites that mimic Privnote. Due to Privnote's popularity since 2008, fake services with phishing purposes are appearing, and users should refrain from using anything but privnote.com or their information might be compromised."
- **Missing Data:** Specific TTL options, encryption algorithm details

### 6. SafeNote
- **URL:** https://safenote.co/
- **URL Status:** Could not verify (403 error on fetch)
- **Pricing Found:**
  - **EXACT PRICE:** $0 (completely free)
  - No premium tiers found
- **Unique Feature:** Launched 2018, specifically markets file sharing capabilities
- **Quote from Search:** "SafeNote is a free, fast, and secure way to share files and notes with end-to-end encryption and a link that expires automatically."
- **Missing Data:** File size limits, specific TTL options, encryption algorithm

### 7. Yopass
- **URL:** https://yopass.se/
- **URL Status:** Could not verify (403 error on fetch)
- **Pricing Found:**
  - **Public instance (yopass.se):** $0 (free)
  - **Managed hosting options:**
    - OctaByte.io: $9 (no time period specified)
    - LibreSelfHosted: $0.99/month
  - Self-hosted: Free (open source, Apache 2.0)
- **Unique Feature:** Stores secrets in "Memcached or Redis" (specific backend mentioned)
- **Quote from Search:** "It's recommended to host Yopass yourself if you care about security. The software is available on GitHub and can be self-hosted for free, though you would need to provide your own infrastructure."
- **Missing Data:** Specific TTL options on public instance, exact encryption algorithm

### 8. 1ty.me
- **URL:** https://1ty.me/
- **URL Status:** Could not verify (403 error on fetch)
- **Pricing Found:**
  - **EXACT PRICE:** $0 (completely free)
- **Unique Feature:** Email notification when recipient views note - "optionally adding in your email to be notified when the recipient views your note"
- **Quote from Search:** "All notes are encrypted before being stored on the server and only a portion of the key to decrypt is contained in the URL. This URL is not stored on the server, so only the link can decrypt the notes."
- **Specific TTL:** "When a note is not retrieved after 30 days, 1ty.me removes it permanently, just as if it were read."
- **Missing Data:** Other TTL options besides 30 days, file support

### 9. burnnote.io
- **URL:** https://burnnote.io/
- **URL Status:** Could not verify
- **Note:** Original burnnote.com is "permanently closed" according to Crunchbase (founded 2012, closed)
- **Pricing Found:** Not found in search results
- **Unique Feature:** End-to-end encryption (E2EE) - "messages are encrypted before they ever leave your browser"
- **Quote from Search:** "An active service offering self-destructing encrypted messages with end-to-end encryption (e2ee) where messages are encrypted before they ever leave your browser"
- **Missing Data:** Pricing, TTL options, verification of site status

### 10. scrt.link
- **URL:** https://scrt.link/
- **URL Status:** Could not verify (403 error on fetch)
- **Pricing Found:**
  - Free trial: 7 days, no credit card required
  - Multiple tiers: Confidential (base), Secret, higher tier
  - **EXACT PRICING NOT FOUND** - pricing page exists but dollar amounts not in search results
- **Pricing Page:** https://scrt.link/pricing (exists but not fetched)
- **Unique Features:**
  1. "Secret Neograms" (unclear what this is - unique terminology not explained)
  2. Read receipts
  3. API access in higher tier
- **Quote from Search:** "All secrets are encrypted on the client using AES-256-GCM (Advanced Encryption Standard - Galois/Counter Mode). The encryption key is never stored; instead, it becomes part of the link itself"
- **Specific TTL Options:** "Up to 7 days retention" (Secret plan), "Up to 30 days retention" (higher tier)
- **Missing Data:** Exact dollar amounts, explanation of "Secret Neograms"

### 11. Send (Firefox Send fork by Tim Visée)
- **URL:** https://send.vis.ee/
- **URL Status:** Could not verify
- **Pricing Found:**
  - **EXACT PRICE:** $0 (free)
  - "Sponsored by Thunderbird" (official sponsor)
- **Unique Feature:** Fork of discontinued Mozilla Firefox Send, CLI client available (ffsend)
- **Quote from Search:** "Send is a fork of Mozilla's discontinued Firefox Send service, which Tim Visée forked as a community effort to keep the project up-to-date and alive, providing a public instance."
- **File Size Limits:**
  - Anonymous: 1GB
  - With Firefox account: 2.5GB
  - (Conflicting info: one source says "up to 10 GB")
- **Missing Data:** Specific TTL options, current operational status

### 12. SnapPass (Pinterest)
- **URL:** https://github.com/pinterest/snappass (self-hosted only, various instances)
- **URL Status:** GitHub repo accessible, no official public instance URL
- **Pricing Found:**
  - **EXACT PRICE:** $0 (open source, free to self-host)
- **Unique Feature:** Developed by Pinterest, uses Redis for storage, Fernet symmetric encryption
- **Quote from Search:** "The URL can only be accessed once, and passwords are encrypted using Fernet symmetric encryption, with a random unique key generated for each password that is never stored."
- **Encryption:** Fernet symmetric encryption (specific algorithm mentioned)
- **Missing Data:** No official public instance, TTL options, self-hosting complexity

### 13. Bitwarden Send
- **URL:** https://bitwarden.com/products/send/
- **URL Status:** Could not verify
- **Pricing Found:**
  - **Free tier:** $0 (includes Send)
  - **Premium:** $10/year (includes Send)
  - **Families:** $40/year (includes Send)
  - Business plans available
- **Unique Feature:** Part of full password manager suite (not standalone), works with non-Bitwarden users
- **Quote from Search:** "Bitwarden Send allows you to share encrypted information, text, and attachments with anyone through a secure link."
- **Missing Data:** Specific TTL options, file size limits for Send feature

### 14. Keeper
- **URL:** https://www.keepersecurity.com/features/password-sharing/
- **URL Status:** Could not verify
- **Pricing Found:** Not found in search results (password manager pricing found but not specific to sharing feature)
- **Unique Feature:** Part of enterprise password manager, uses Elliptic Curve Cryptography (ECC) specifically mentioned
- **Quote from Search:** "Keeper enables secure password sharing and encrypted storage across organizations, with records shared using AES and Elliptic Curve Cryptography so only the intended recipient can decrypt the data."
- **Encryption:** AES + Elliptic Curve Cryptography
- **Missing Data:** Pricing for sharing feature, TTL options, whether available in free tier

### 15. NordPass
- **URL:** https://nordpass.com/features/secure-password-sharing/
- **URL Status:** Could not verify
- **Pricing Found:** Not found in search results (password manager pricing exists but not specific to sharing)
- **Unique Feature:** Part of password manager, markets "passkeys, credit card details" sharing beyond just passwords
- **Quote from Search:** "NordPass makes it easy to share passwords, passkeys, credit card details, and other sensitive data safely, with all shared data end-to-end (E2E) encrypted."
- **Missing Data:** Pricing, TTL options, whether standalone or requires full subscription

### 16. Proton Pass
- **URL:** https://proton.me/pass
- **URL Status:** Could not verify
- **Pricing Found:** Not found in search results
- **Unique Feature:** Part of Proton ecosystem (known for ProtonMail), Swiss-based (different jurisdiction)
- **Quote from Search:** "Proton Pass protects passwords with proven end-to-end encryption technology, including usernames, web addresses, and passwords."
- **Missing Data:** Pricing, whether sharing is available in free tier, TTL options, Swiss data protection specifics

### 17. Akeyless
- **URL:** https://www.akeyless.io/secrets-management/secrets-sharing/
- **URL Status:** Could not verify
- **Pricing Found:** Not found in search results
- **Unique Feature:** Enterprise secrets management platform with session logging - "tracks all third-party access with comprehensive session logs"
- **Quote from Search:** "Akeyless enables sharing secrets with third parties that automatically expire and tracks all third-party access with comprehensive session logs."
- **Missing Data:** Pricing, TTL options, whether available for individual use or enterprise-only

## Summary Statistics

### Pricing Verification Status
- **Exact prices found:** 8 services
  - $0 (Free): PrivateBin, Privnote, SafeNote, 1ty.me, Send (vis.ee), SnapPass
  - $99.99 lifetime: Password.link
  - $10/year: Bitwarden Send (Premium tier)
- **Partial pricing:** 3 services (Yopass, OneTimeSecret, scrt.link) - tiers exist but dollar amounts missing
- **No pricing found:** 6 services (Password Pusher, burnnote.io, Keeper, NordPass, Proton Pass, Akeyless)

### URL Verification Status
- **Could not verify any URLs programmatically** - WebFetch returned 403 for all attempts
- All URLs based on search results and documentation references
- **0 URLs confirmed to return 200 status** via automated tools

### Unique Features Identified
1. OneTimeSecret: Data center selection
2. Password.link: Lifetime payment option
3. Password Pusher: Comprehensive audit logging with 14-year track record
4. PrivateBin: Zero-knowledge architecture (server can't decrypt)
5. Privnote: Longest running (since 2008)
6. SafeNote: File sharing focus
7. Yopass: Named backend (Memcached/Redis)
8. 1ty.me: Email notification on view
9. burnnote.io: E2EE with browser-side encryption
10. scrt.link: "Secret Neograms" (unexplained feature)
11. Send: CLI client (ffsend) + Thunderbird sponsorship
12. SnapPass: Fernet encryption, Pinterest-developed
13. Bitwarden Send: Part of full password manager ecosystem
14. Keeper: ECC (Elliptic Curve Cryptography) specified
15. NordPass: Passkey and credit card sharing
16. Proton Pass: Swiss jurisdiction/Proton ecosystem
17. Akeyless: Session logging for third-party access

## Contradictions & Uncertainties Found

### Send (vis.ee) File Size Limits
- Source 1: "up to 1GB" (anonymous), "2.5GB" (with account)
- Source 2: "up to 10 GB in size"
- **Status:** Conflicting - could not verify actual limit

### Password.link Pricing Model
- Source 1: "$99.99 one-time payment"
- Source 2: "discount code TRY30 on any plan to get 30% off the first two months"
- **Status:** Appears to have both lifetime AND subscription options, not clear which is primary

### burnnote Status
- burnnote.com: "permanently closed" (Crunchbase)
- burnnote.io: Appears active
- burnnote.net: Different service (AES tool)
- **Status:** Multiple domains, unclear which is legitimate successor

### Privnote Security
- Claimed: "encrypts each message so that even Privnote itself cannot read its contents"
- Warning: "multiple phishing sites that mimic Privnote" with exact lookalikes
- **Status:** Cannot verify encryption without technical audit, phishing risk documented

### Free Services Business Model
- 10 services claim to be completely free with no premium tier
- Only Privnote disclosed ad-supported model
- **Question:** How do the other 9 free services sustain operations? Not disclosed.

### Password Manager Sharing Features
- Keeper, NordPass, Proton Pass all mentioned "sharing" but unclear:
  - Is this one-time secret sharing or persistent sharing?
  - Is TTL/expiration available?
  - Can non-users receive shares?
- **Status:** Search results conflate password manager "sharing" with one-time secret sharing

## Missing Data Points (Explicitly Noted)

1. **OneTimeSecret:** Exact dollar amounts, specific TTL options list
2. **Password.link:** Specific TTL options, file size limits, actual test results
3. **Password Pusher:** Exact dollar amounts, specific TTL/expiration options list
4. **PrivateBin:** Specific TTL options list, test of secret creation process
5. **Privnote:** Specific TTL options, encryption algorithm details
6. **SafeNote:** File size limits, specific TTL options, encryption algorithm
7. **Yopass:** Specific TTL options, exact encryption algorithm
8. **1ty.me:** TTL options besides 30-day default, file support capability
9. **burnnote.io:** Pricing, TTL options, verification of operational status
10. **scrt.link:** Exact dollar amounts, explanation of "Secret Neograms" feature
11. **Send (vis.ee):** Specific TTL options, current operational status verification
12. **SnapPass:** Official public instance URL, TTL options, self-hosting complexity
13. **Bitwarden Send:** Specific TTL options, file size limits
14. **Keeper:** Pricing for sharing feature, TTL options, free tier availability
15. **NordPass:** Pricing, TTL options, standalone vs subscription requirement
16. **Proton Pass:** Pricing, free tier sharing availability, TTL options
17. **Akeyless:** Pricing, TTL options, individual vs enterprise-only availability

## Technical Limitations Encountered

### WebFetch Tool Failure
**Attempted:** Direct fetch of all service homepages and pricing pages
**Result:** 100% failure rate (403 Forbidden)
**Services returning 403:**
- onetimesecret.com
- password.link/en
- pwpush.com
- privatebin.info

**Impact:**
- Cannot capture actual pricing page screenshots
- Cannot verify URLs return 200 status
- Cannot extract exact pricing from live pages
- Cannot test actual secret creation workflows
- Relying entirely on search engine results (secondary sources)

### Search Result Limitations
- Pricing pages often not indexed with actual dollar amounts
- Feature lists are marketing copy, not technical specifications
- No way to verify claims without manual testing
- Timestamps on information unknown (could be outdated)

## Next Steps Required for PHASE 2

To complete PHASE 2 data collection, the following manual actions are needed:

1. **Manual browser testing** required for each service since WebFetch fails
2. **Create actual test secrets** on each platform to document exact workflows
3. **Screenshot pricing pages** manually (cannot automate)
4. **Test TTL options** by creating secrets with different expiration settings
5. **Test limits** by attempting to exceed rate limits or size limits
6. **Verify error messages** by triggering validation or limit errors

## PHASE 1 Completion Status

✅ Found 17 services (exceeds 15 minimum)
❌ Cannot provide URLs with confirmed 200 status (WebFetch blocked)
❌ Cannot provide screenshots of pricing pages (WebFetch blocked)
✅ Identified unique feature for each service
✅ Documented why automated verification failed
✅ Showed all search queries used

**Percentage of cells that could not be verified:** Approximately 60%
- URL status: 0% verified
- Pricing: 47% exact prices found (8/17)
- Features: 100% at least one unique feature identified
- TTL options: <10% specific lists found
- Overall: ~60% data points missing or unverified

---

**STOPPING AT PHASE 1 AS REQUESTED**

Manual testing required to proceed to PHASE 2 due to automation limitations.
