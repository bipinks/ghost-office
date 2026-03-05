---
name: ssl-tls-management
description: Use when setting up or renewing SSL/TLS certificates. Covers Let's Encrypt automation with certbot, ACM certificate requests, HSTS headers, OCSP stapling, mTLS for service-to-service auth, and certificate monitoring/rotation.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# SSL/TLS Management

## Let's Encrypt with Certbot
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate (Nginx)
sudo certbot --nginx -d example.com -d www.example.com --non-interactive --agree-tos -m admin@example.com

# Obtain wildcard certificate (DNS challenge)
sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  -d "*.example.com" -d example.com --non-interactive --agree-tos

# Renewal (auto-configured by certbot)
sudo certbot renew --dry-run

# Cron for renewal
echo "0 0,12 * * * root certbot renew --quiet --deploy-hook 'systemctl reload nginx'" | sudo tee /etc/cron.d/certbot
```

## ACME with Docker (Traefik)
```yaml
services:
  traefik:
    image: traefik:v3
    command:
      - "--certificatesresolvers.letsencrypt.acme.email=admin@example.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
    ports:
      - "443:443"
    volumes:
      - letsencrypt:/letsencrypt
```

## Certificate Monitoring
```bash
# Check certificate expiry
echo | openssl s_client -servername example.com -connect example.com:443 2>/dev/null | openssl x509 -noout -dates

# Prometheus blackbox exporter for SSL monitoring
modules:
  https_cert_check:
    prober: http
    http:
      preferred_ip_protocol: ip4
      fail_if_ssl: false
      fail_if_not_ssl: true
```

## Best Practices
1. **Automate renewal** — Never let certificates expire manually
2. **HSTS** — Enable with long max-age and includeSubDomains
3. **TLS 1.2+** — Disable TLS 1.0 and 1.1
4. **OCSP stapling** — Enable for performance
5. **Monitor expiry** — Alert 30 days before expiration
6. **CAA records** — Restrict which CAs can issue for your domain
7. **Certificate transparency** — Monitor CT logs for unauthorized issuance
