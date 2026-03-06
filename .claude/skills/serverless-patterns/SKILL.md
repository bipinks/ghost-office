---
name: serverless-patterns
description: Use when building serverless applications or event-driven architectures. Covers AWS Lambda function design, API Gateway configuration, Step Functions orchestration, DynamoDB single-table design, cold start optimization, and event source mappings.
user-invocable: false
allowed-tools: ["Read", "Write", "Grep"]
---

# Serverless Patterns

## Lambda Function Structure
```python
import json, logging, os
from aws_lambda_powertools import Logger, Tracer, Metrics
from aws_lambda_powertools.event_handler import APIGatewayRestResolver

logger = Logger()
tracer = Tracer()
metrics = Metrics()
app = APIGatewayRestResolver()

@app.get("/users/<user_id>")
@tracer.capture_method
def get_user(user_id: str):
    metrics.add_metric(name="GetUser", unit="Count", value=1)
    # Business logic here
    return {"user_id": user_id, "name": "John"}

@logger.inject_lambda_context
@tracer.capture_lambda_handler
@metrics.log_metrics
def handler(event, context):
    return app.resolve(event, context)
```

## SAM Template
```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: AWS::Serverless-2016-10-31

Globals:
  Function:
    Runtime: python3.12
    MemorySize: 256
    Timeout: 30
    Tracing: Active
    Environment:
      Variables:
        STAGE: !Ref Stage

Resources:
  ApiFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: app.handler
      CodeUri: src/
      Events:
        Api:
          Type: Api
          Properties:
            Path: /{proxy+}
            Method: ANY
      Policies:
        - DynamoDBCrudPolicy:
            TableName: !Ref DataTable
```

## Best Practices
1. **Cold start optimization** — Keep packages minimal, use provisioned concurrency for latency-sensitive
2. **Idempotency** — Design all functions to handle duplicate invocations
3. **Timeouts** — Set appropriate timeouts (not max 15 minutes)
4. **Error handling** — Use DLQ for async failures, structured error responses for sync
5. **Observability** — Use X-Ray tracing, structured logging, custom metrics
6. **Security** — Least-privilege IAM, no hardcoded secrets
7. **Cost** — Right-size memory, use ARM architecture, monitor invocations
8. **Testing** — Local testing with SAM CLI, integration tests with real services
