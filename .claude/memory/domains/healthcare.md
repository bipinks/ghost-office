# Domain Knowledge — Healthcare

> **Domain**: Healthcare / Health Tech
> Auto-loaded via `domain.lock` or `/set-domain healthcare`

## Core Business Concepts

### Patient Data
- Protected Health Information (PHI) — strict access controls
- Patient demographics, medical history, allergies, medications
- Electronic Health Records (EHR) / Electronic Medical Records (EMR)
- Patient consent management for data sharing
- Emergency access override with audit trail

### Clinical Workflows
- Patient registration and scheduling
- Clinical encounter documentation (SOAP notes)
- Order entry (labs, imaging, prescriptions)
- Results review and clinical decision support
- Referral management between providers

### Healthcare Standards
- **HL7 FHIR** — REST API standard for health data exchange
- **HL7 v2** — Legacy messaging format (ADT, ORM, ORU)
- **ICD-10** — Diagnosis coding
- **CPT** — Procedure coding
- **LOINC** — Lab observation codes
- **SNOMED CT** — Clinical terminology

---

## Modules

### 1. Patient Management
**Entities**: Patient, Encounter, Appointment, Provider, Facility
**Key Rules**:
- Unique patient identifier (MRN — Medical Record Number)
- Patient matching/deduplication (name, DOB, SSN)
- Appointment scheduling with provider availability
- Check-in/check-out workflow
- Patient portal for self-service

### 2. Clinical Documentation
**Entities**: Note, Assessment, Plan, Order, Result
**Key Rules**:
- SOAP note structure (Subjective, Objective, Assessment, Plan)
- Template-based documentation with customization
- Clinical decision support alerts (drug interactions, allergies)
- E-prescribing with pharmacy integration
- Lab/imaging order workflows

### 3. Billing & Claims
**Entities**: Claim, ChargeItem, InsurancePlan, ERA, EOB
**Key Rules**:
- Charge capture from clinical encounters
- Insurance eligibility verification (real-time 270/271)
- Claim submission (837P/837I) to clearinghouses
- ERA processing (835) for payment posting
- Patient billing for co-pays, deductibles, self-pay
- Denial management and appeals workflow

### 4. Telehealth
**Entities**: VirtualVisit, VideoSession, ConsentForm
**Key Rules**:
- HIPAA-compliant video conferencing
- Virtual waiting room
- Screen sharing for results review
- Recording with patient consent
- Interstate licensing compliance

---

## Cross-Cutting Concerns

### HIPAA Compliance (MANDATORY)
- **Access Controls**: Role-based, minimum necessary principle
- **Audit Logging**: All PHI access logged (who, what, when, why)
- **Encryption**: AES-256 at rest, TLS 1.2+ in transit
- **BAA**: Business Associate Agreements with all vendors
- **Breach Notification**: 60-day notification requirement
- **Data Retention**: Minimum 6 years (varies by state)
- **Patient Rights**: Access, amendment, accounting of disclosures

### Interoperability
- FHIR R4 API for data exchange
- Patient data portability (C-CDA documents)
- Health Information Exchange (HIE) participation
- API access for third-party apps (SMART on FHIR)

### Security (Enhanced)
- PHI encryption everywhere — no exceptions
- Background checks for all staff with PHI access
- Workstation auto-lock and session timeout
- Secure messaging (no PHI in regular email)
- Annual HIPAA training compliance tracking
- Incident response plan specific to PHI breaches
