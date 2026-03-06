---
name: cloud-cost-optimization
description: Use when analyzing or reducing cloud spend. Covers FinOps practices, right-sizing recommendations, reserved instance/savings plan analysis, cost allocation tagging, unused resource cleanup, spot instance strategies, and budget alerting.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# Cloud Cost Optimization (FinOps)

## Cost Allocation Strategy
```
Tags Required:
  - Environment: dev | staging | production
  - Project: project-name
  - Team: team-name
  - CostCenter: cost-center-code
  - ManagedBy: terraform | manual | cdk

Reports:
  - Cost by team (monthly)
  - Cost by project (monthly)
  - Cost by environment (monthly)
  - Cost anomaly detection (daily)
```

## Right-Sizing Checklist
```bash
# AWS — Find underutilized EC2 instances
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --start-time $(date -d '7 days ago' --iso-8601=seconds) \
  --end-time $(date --iso-8601=seconds) \
  --period 3600 --statistics Average

# Rule: Average CPU < 20% over 7 days = over-provisioned
# Rule: Average CPU > 80% over 7 days = under-provisioned
```

## Savings Strategies
| Strategy | Savings | Commitment | Best For |
|----------|---------|------------|----------|
| Right-sizing | 10-30% | None | All workloads |
| Reserved Instances | 30-60% | 1-3 years | Steady-state |
| Savings Plans | 30-50% | 1-3 years | Flexible workloads |
| Spot Instances | 60-90% | None | Fault-tolerant |
| ARM instances | 20-40% | None | Compatible workloads |
| Auto-scaling | 20-40% | None | Variable workloads |

## Best Practices
1. **Tag everything** — Untagged resources = unattributable costs
2. **Budget alerts** — Set thresholds at 50%, 80%, 100%
3. **Anomaly detection** — Enable AWS Cost Anomaly Detection
4. **Regular reviews** — Monthly cost review meetings
5. **Dev/staging savings** — Schedule down during off-hours
6. **Storage lifecycle** — Transition to cheaper storage tiers automatically
7. **Delete waste** — Regular cleanup of unused resources
8. **FinOps culture** — Team-level cost awareness and accountability
