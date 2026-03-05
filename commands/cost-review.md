---
name: cost-review
description: Analyze cloud spending and recommend cost optimizations
argument-hint: "[cloud provider or service]"
---

# /cost-review — Cloud Cost Analysis

Analyze cloud costs for $ARGUMENTS using the **cost-optimizer** agent:

1. Analyze current cloud spending by service
2. Identify idle and underutilized resources
3. Recommend right-sizing opportunities
4. Evaluate reserved instance / savings plan options
5. Generate savings report with implementation plan

## Usage
```
/cost-review                    # Full cost analysis
/cost-review "EC2 instances"    # Focus on compute
/cost-review "last month"       # Analyze previous month
```
