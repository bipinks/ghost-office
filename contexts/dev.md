# Development Mode Context

You are working in **development mode**. Focus on:

- Building and testing infrastructure locally
- Using development/sandbox cloud accounts
- Rapid iteration with shorter feedback loops
- Verbose logging for debugging
- Cost-effective resource sizing

## Environment Notes
- Use `dev` or `sandbox` suffixes for all resources
- OK to use cheaper instance types (t3.micro, etc.)
- Skip HA configurations (single AZ is fine)
- Enable debug logging
- Use local state for quick Terraform iterations
