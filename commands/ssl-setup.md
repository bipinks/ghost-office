---
name: ssl-setup
description: Set up and manage SSL/TLS certificates
argument-hint: "[domain name]"
disable-model-invocation: true
---

# /ssl-setup — SSL/TLS Certificate Management

Set up SSL/TLS for $ARGUMENTS using the **infra-planner** agent with the **ssl-tls-management** skill:

1. Obtain certificate (Let's Encrypt, ACM, or custom CA)
2. Configure web server (Nginx/Apache)
3. Enable HSTS and OCSP stapling
4. Set up auto-renewal
5. Monitor certificate expiry

## Usage
```
/ssl-setup "Let's Encrypt for example.com"
/ssl-setup "wildcard certificate for *.example.com"
/ssl-setup "check certificate expiry dates"
```
