---
name: incident-response
description: Triage production incidents with structured investigation and resolution
argument-hint: "[incident description or service name]"
---

# /incident-response — Incident Triage

Respond to incident: $ARGUMENTS using the **monitoring-agent** agent:

1. Assess severity (SEV1-SEV4)
2. Check recent deployments and changes
3. Review monitoring dashboards and logs
4. Identify root cause
5. Apply mitigation
6. Generate post-mortem and action items

## Usage
```
/incident-response "High error rate on API gateway"
/incident-response "Database connections maxed out"
/incident-response "Payment service timing out"
```
