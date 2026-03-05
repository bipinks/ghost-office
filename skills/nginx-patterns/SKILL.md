---
name: nginx-patterns
description: Use when configuring Nginx as a reverse proxy, load balancer, or web server. Covers upstream blocks, SSL termination, caching directives, rate limiting, security headers, gzip compression, and location block patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Grep"]
---

# Nginx Patterns

## Reverse Proxy with SSL
```nginx
upstream app_backend {
    least_conn;
    server 127.0.0.1:3000 weight=3;
    server 127.0.0.1:3001 weight=2;
    server 127.0.0.1:3002 backup;
    keepalive 32;
}

server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    # SSL
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header Content-Security-Policy "default-src 'self'" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml image/svg+xml;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

    location / {
        proxy_pass http://app_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 90s;
        proxy_connect_timeout 5s;
    }

    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://app_backend;
    }

    location /static/ {
        alias /var/www/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /healthz {
        access_log off;
        return 200 "OK";
    }
}
```

## Best Practices
1. **HTTPS everywhere** — Redirect all HTTP to HTTPS
2. **Security headers** — HSTS, CSP, X-Frame-Options, etc.
3. **Rate limiting** — Protect APIs from abuse
4. **Caching** — Static assets with long expiry, dynamic with proxy cache
5. **Keepalive** — Enable upstream keepalive for performance
6. **Access logs** — Structured logging for analysis
7. **Worker tuning** — `worker_processes auto; worker_connections 1024;`
8. **Timeouts** — Set appropriate connect, read, send timeouts
