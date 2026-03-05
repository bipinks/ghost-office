---
name: secrets-management
description: Use when storing, rotating, or accessing secrets and credentials. Covers HashiCorp Vault setup, AWS Secrets Manager, environment variable best practices, secret injection in CI/CD, rotation policies, and zero-trust secret access patterns.
user-invocable: false
allowed-tools: ["Read", "Write", "Bash", "Grep"]
---

# Secrets Management

## HashiCorp Vault
```bash
# Enable secrets engine
vault secrets enable -path=secret kv-v2

# Store secret
vault kv put secret/production/database url="postgresql://user:pass@db:5432/app" password="s3cret"

# Read secret
vault kv get -format=json secret/production/database

# Dynamic database credentials
vault secrets enable database
vault write database/config/postgres \
    plugin_name=postgresql-database-plugin \
    connection_url="postgresql://{{username}}:{{password}}@db:5432/app" \
    allowed_roles="app-role" \
    username="vault" \
    password="vault-pass"

vault write database/roles/app-role \
    db_name=postgres \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

## AWS Secrets Manager
```python
import boto3, json

def get_secret(secret_name, region="us-east-1"):
    client = boto3.client("secretsmanager", region_name=region)
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response["SecretString"])

# With automatic rotation
client.rotate_secret(
    SecretId="prod/database",
    RotationRules={"AutomaticallyAfterDays": 30}
)
```

## Kubernetes External Secrets
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: database-credentials
  data:
    - secretKey: url
      remoteRef:
        key: production/database
        property: url
```

## Best Practices
1. **Never in code** — No secrets in source code, env files, or config
2. **Rotate regularly** — Automate rotation every 30-90 days
3. **Principle of least privilege** — Scope access to specific secrets
4. **Audit access** — Log all secret reads and modifications
5. **Dynamic secrets** — Use short-lived credentials where possible
6. **Encryption** — Encrypt secrets at rest and in transit
7. **Emergency rotation** — Have a process for immediate credential changes
8. **Secret scanning** — Use tools like `gitleaks`, `trufflehog` in CI
