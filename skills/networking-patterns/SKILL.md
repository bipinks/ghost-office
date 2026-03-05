---
name: networking-patterns
description: Use when designing cloud networking architecture. Covers VPC CIDR planning, subnet strategies, DNS management with Route53/CloudFlare, CDN configuration, ALB/NLB load balancing, VPN tunnels, VPC peering, and private link patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Grep"]
---

# Networking Patterns

## VPC Design (Multi-Tier)
```
10.0.0.0/16 (VPC)
├── 10.0.0.0/20   Public Subnet AZ-a   (Load Balancers, Bastion)
├── 10.0.16.0/20  Public Subnet AZ-b
├── 10.0.32.0/20  Public Subnet AZ-c
├── 10.0.48.0/20  Private Subnet AZ-a  (Application Servers)
├── 10.0.64.0/20  Private Subnet AZ-b
├── 10.0.80.0/20  Private Subnet AZ-c
├── 10.0.96.0/20  Data Subnet AZ-a     (Databases, Caches)
├── 10.0.112.0/20 Data Subnet AZ-b
└── 10.0.128.0/20 Data Subnet AZ-c
```

## Route 53 DNS
```hcl
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# Health check with failover
resource "aws_route53_health_check" "primary" {
  fqdn              = "primary.example.com"
  port               = 443
  type               = "HTTPS"
  resource_path      = "/healthz"
  failure_threshold  = 3
  request_interval   = 30
}
```

## Load Balancer (ALB)
```hcl
resource "aws_lb" "main" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  drop_invalid_header_fields = true
  enable_deletion_protection = true
}
```

## Best Practices
1. **CIDR planning** — Plan subnets for growth, use /20 blocks minimum
2. **Multi-AZ** — Spread subnets across 3+ availability zones
3. **Private subnets** — Application and data tiers in private subnets
4. **NAT Gateway** — Use for outbound internet from private subnets
5. **VPC endpoints** — Use for AWS service access (S3, DynamoDB, ECR)
6. **Security groups** — Stateful, allow only necessary ports
7. **NACLs** — Stateless defense-in-depth layer
8. **DNS** — Use private hosted zones for internal service discovery
