# Domain Knowledge — Fintech

> **Domain**: Financial Technology (Fintech)
> Auto-loaded via `domain.lock` or `/set-domain fintech`

## Core Business Concepts

### Money Movement
- Payment processing (card, bank transfer, wallet)
- Ledger-based accounting (double-entry, immutable)
- Settlement and reconciliation cycles
- Multi-currency with real-time exchange rates
- Float management and funds availability

### Regulatory Framework
- **PCI DSS** — Card data security (Level 1-4)
- **PSD2/SCA** — Strong Customer Authentication (EU)
- **KYC** — Know Your Customer identity verification
- **AML** — Anti-Money Laundering screening
- **SOX** — Financial reporting controls
- **State money transmitter licenses** (US)

### Risk Management
- Transaction fraud detection (rules + ML)
- Velocity checks (amount, frequency, geography)
- Chargeback and dispute management
- Credit risk scoring and underwriting
- Sanctions screening (OFAC, EU lists)

---

## Modules

### 1. Payments
**Entities**: Payment, Transaction, Merchant, PaymentMethod, Settlement
**Key Rules**:
- Idempotent payment creation (idempotency keys)
- Authorization -> Capture -> Settlement flow
- Partial captures and multi-capture support
- Refund processing with reason codes
- Webhook delivery for async payment events
- Retry logic with exponential backoff for network failures

### 2. Ledger & Accounting
**Entities**: Account, Entry, Transaction, Balance, Journal
**Key Rules**:
- Immutable ledger entries (append-only, never update/delete)
- Double-entry: every debit has a corresponding credit
- Real-time balance calculation from entries
- Account types: asset, liability, revenue, expense
- End-of-day reconciliation reports
- Audit trail for every balance change

### 3. Identity & KYC
**Entities**: Customer, IdentityDocument, VerificationResult, RiskScore
**Key Rules**:
- Tiered KYC (basic info -> document verify -> enhanced due diligence)
- Document verification (passport, driver's license, utility bill)
- Liveness detection for identity proofing
- Watchlist screening (PEP, sanctions, adverse media)
- Ongoing monitoring for risk changes
- Data retention per regulatory requirements

### 4. Fraud Detection
**Entities**: FraudRule, FraudAlert, Case, Decision
**Key Rules**:
- Real-time transaction scoring (sub-100ms)
- Rule engine: velocity, amount, geography, device fingerprint
- ML model integration for anomaly detection
- Manual review queue for borderline cases
- Feedback loop: confirmed fraud trains the model
- False positive rate monitoring

### 5. Lending (Optional)
**Entities**: LoanApplication, CreditDecision, Loan, Repayment, Collection
**Key Rules**:
- Application -> Underwriting -> Approval -> Disbursement -> Repayment
- Credit scoring models (bureau data + alternative data)
- Interest calculation (simple, compound, APR disclosure)
- Repayment schedules with amortization
- Late payment handling and collections workflow
- Regulatory rate caps and disclosure requirements

---

## Cross-Cutting Concerns

### Data Integrity
- Database transactions with SERIALIZABLE isolation for money movement
- Optimistic locking for concurrent balance updates
- Idempotency keys on all write operations
- Checksums for data integrity verification
- Point-in-time recovery capability

### Compliance & Audit
- Complete audit trail for all financial operations
- Regulatory reporting (SAR, CTR for large transactions)
- Data residency requirements (EU data stays in EU)
- Right to erasure with regulatory retention exceptions
- Annual compliance audits (SOC 2, PCI DSS)

### Security (Enhanced)
- Hardware Security Modules (HSM) for key management
- Tokenization for sensitive financial data
- Network segmentation (PCI cardholder data environment)
- Real-time intrusion detection
- Penetration testing (quarterly for PCI)
- Incident response plan with regulatory notification
